use strict;
use warnings;
package RT::Extension::Import::CSV;

use Text::CSV_XS;
use Test::MockTime 'restore_time';

our $VERSION = '0.02';

our( $CurrentRow, $CurrentLine, $UniqueFields );

sub _column {
    ref($_[0]) ? (ref($_[0]) eq "CODE" ?
                      "code reference" :
                      "static value '${$_[0]}'")
        : "column $_[0]"
}

my %dispatch = (
    user        => '_run_users',
    ticket      => '_run_tickets',
    transaction => '_run_transactions',
    article     => '_run_articles',
);

sub run {
    my $class = shift;
    my %args  = (
        Type => undef,
        @_,
    );

    my $type = delete $args{Type} // '';
    my $method = $dispatch{$type};
    if ( $method ) {
        return $class->$method( %args );
    }
    else {
        $RT::Logger->error( "Invalid type: $type" );
        return ( 0, 0, 0 );
    }
}

sub _run_users {
    my $class = shift;
    my %args  = (
        CurrentUser => undef,
        File        => undef,
        Update      => undef,
        Insert      => undef,
        @_,
    );
    my $field2csv  = $RT::Config->Get( 'UsersImportFieldMapping' );
    my $csv2fields = {};
    push @{ $csv2fields->{ $field2csv->{$_} } }, $_ for grep { not ref $field2csv->{$_} } keys %{$field2csv};

    my ($header, @items) = $class->parse_csv( $args{File}, force => $args{Force} );
    unless (@items) {
        $RT::Logger->warning( "No items found in file $args{File}" );
        return (0, 0, 0);
    }

    $RT::Logger->debug( "Found unused column '$_'" )
        for grep {$_ ne 'U' && $_ ne '_line' && not $csv2fields->{$_}} keys %{ $items[0] };
    $RT::Logger->warning( "No column $_ found for @{$csv2fields->{$_}}" )
        for grep {not exists $items[0]->{$_} } keys %{ $csv2fields };

    $RT::Logger->debug( 'Found ' . scalar(@items) . ' record(s)' );
    my ( $created, $updated, $skipped ) = ( 0 ) x 3;
    my $row = 1; # Because of header row
    for my $item ( @items ) {
        local $CurrentRow = ++$row;
        local $CurrentLine = $item->{_line};
        $RT::Logger->debug( "Start processing" );
        next unless grep { defined $_ && /\S/ } values %{ { %$item, _line => undef } };
        my $user = RT::User->new( $args{CurrentUser} );
        my $current_user = $args{CurrentUser};

        # only insert for now, no update needed here yet.
        my %args;

        for my $field (keys %$field2csv ) {
            my $value = $class->get_value($field2csv->{$field}, $item);
            next unless defined $value and length $value;
            $value =~ s!;$!!; # email values contain extra ";"
            $args{$field} = $value;
        }

        $user->LoadByEmail( $args{EmailAddress} );
        if ( $user->id ) {
            $RT::Logger->info( "Found existing user $args{EmailAddress}, skipping" );
            $skipped++;
        }
        else {
            my $user = $class->load_or_create_user( CurrentUser => $current_user, %args );
            if ( $user ) {
                $created++;
                $RT::Logger->info( "Created user $args{EmailAddress}" );
            }
            else {
                $RT::Logger->error( "Failed to create user $args{EmailAddress}, skipping" );
                $skipped++;
            }
        }
    }
    return ( $created, $updated, $skipped );
}


sub _run_transactions {
    my $class = shift;
    my %args  = (
        CurrentUser => undef,
        File        => undef,
        Update      => undef,
        Insert      => undef,
        @_,
    );

    my $field2csv = $RT::Config->Get('TransactionsImportFieldMapping');
    my $csv2fields = {};
    push @{$csv2fields->{ $field2csv->{$_} }}, $_
        for grep { not ref $field2csv->{$_} } keys %{$field2csv};

    my ($header, @items) = $class->parse_csv( $args{File}, force => $args{Force} );
    unless ( @items ) {
        $RT::Logger->warning( "No items found in file $args{File}" );
        return ( 0, 0, 0 );
    }

    $RT::Logger->warning( "No column $_ found for @{$csv2fields->{$_}}" )
        for grep {not exists $items[0]->{$_} } keys %{ $csv2fields };

    $RT::Logger->debug( 'Found ' . scalar( @items ) . ' record(s)' );
    my ( $created, $updated, $skipped ) = ( 0 ) x 3;
    my $row = 0;
    for my $item ( @items ) {
        local $CurrentRow = ++$row;
        local $CurrentLine = $item->{_line};
        $RT::Logger->debug( "Start processing" );

        next unless grep { defined $_ && /\S/ } values %{ { %$item, _line => undef } };

        my $TicketId = $class->get_value($field2csv->{TicketID} , $item );

        my $ticket = RT::Ticket->new( $args{CurrentUser} );
        $ticket->Load( $TicketId );
        if ( !$ticket->id ) {
            $RT::Logger->error( "Failed to load ticket $TicketId, skipping" );
            $skipped++;
            next;
        }
        my $mime = MIME::Entity->build(
            Type    => $item->{ContentType} || 'text/plain',
            Charset => "UTF-8",
            Data    => [ Encode::encode( "UTF-8", $class->get_value($field2csv->{'Content'},$item) ) ],
        );
        if($class->get_value($field2csv->{'Subject'},$item)) {
            $mime->head->add( 'Subject' => Encode::encode( "UTF-8", $class->get_value($field2csv->{'Subject'},$item) ) );
        }
        # Add any attachments
        if ( $item->{$field2csv->{Attachment}} ) {
          if ( -e $item->{$field2csv->{Attachment}} ) {
              $mime->attach(
                  Path => $item->{$field2csv->{Attachment}},
                  Type => $item->{$field2csv->{AttachmentContentType}} || 'application/octet-stream',

              );
          }
          else {
              $RT::Logger->error( "Could not load attachment: $item->{$field2csv->{Attachment}}" );
          }
        }

        my $method = $class->get_value($field2csv->{'Type'}, $item);

        my ( $txn, $msg );
        if ( $method eq 'EmailRecord' ) {
            my $msgid = Encode::decode( "UTF-8", $mime->head->get('Message-ID') );
            chomp $msgid;

            my $transaction = RT::Transaction->new( $ticket->CurrentUser );
            ( $txn, $msg ) = $transaction->Create(
                Ticket         => $ticket->Id,
                Type           => $method,
                Data           => $msgid,
                MIMEObj        => $mime,
                ActivateScrips => 0
            );

            if ( $txn ) {
                $created++;
            }
            else {
                $RT::Logger->warning( "Could not record outgoing message transaction: $msg" );
            }
        }
        else {
            ( $txn, $msg ) = $ticket->$method( MIMEObj => $mime );
            if ( $txn ) {
                $created++;
            }
            else {
                $RT::Logger->error( "Failed to create transaction: $msg" );
            }
        }
        my $txn_object = RT::Transaction->new( RT->SystemUser );
        $txn_object->Load( $txn );

        for my $fieldname (keys %{ $field2csv }) {
            if ($fieldname =~ /^CF\.(.*)/) {
                my $value = $class->get_value( $field2csv->{$fieldname}, $item );
                my $cfname = $1;

                my $cf = RT::CustomField->new( $args{CurrentUser} );
                $cf->LoadByName(
                    Name          => $cfname,
                    LookupType    => RT::Transaction->CustomFieldLookupType,
                    ObjectId      => $ticket->Queue,
                    IncludeGlobal => 1,
                );
                if ( $cf->Id ) {
                    if ($cf->Type eq "DateTime") {
                        my $args = { Content => $value };
                        $value = $args->{Content};
                    } elsif ($cf->Type eq "Date") {
                        my $args = { Content => $value };
                        $cf->_CanonicalizeValueDate( $args );
                        $value = $args->{Content};
                    }

                    my @current = @{$txn_object->CustomFieldValues( $cf->id )->ItemsArrayRef};
                    next if grep {$_->Content and $_->Content eq $value} @current;

                    my ($ok, $msg) = $txn_object->AddCustomFieldValue(
                        Field => $cf->id,
                        Value => $value,
                    );
                    unless ($ok) {
                        $RT::Logger->error("Failed to set CF $cfname to $value: $msg");
                    }
                }
                else {
                    $RT::Logger->warning(
                        "Missing custom field $cfname for "._column($field2csv->{$fieldname}).", skipping");
                    next;
                }
            }
            # For now hard code the created column
            elsif ($fieldname =~ /^(Created)$/) {
                my $date = RT::Date->new( RT->SystemUser );
                my $value = $class->get_value( $field2csv->{'Created'}, $item );
                $date->Set( Format => 'unknown', Value => $value );

                ( my $ok, $msg ) = $txn_object->__Set( Field => 'Created', Value => $date->ISO );
                $RT::Logger->error( "Failed to set Created on transaction: $msg" ) unless $ok;
            }
        }
    }
    return ( $created, $updated, $skipped );
}

my %ticket_extra_fields = (
    map { $_ => 1 } qw/T status/
);

sub _run_tickets {
    my $class = shift;
    my %args  = (
        CurrentUser => undef,
        File        => undef,
        Update      => undef,
        Insert      => undef,
        InsertUpdate => undef,
        @_,
    );

    my $field2csv = $RT::Config->Get('TicketsImportFieldMapping');
    my $force = $args{Force};
    my $csv2fields = {};
    push @{$csv2fields->{ $field2csv->{$_} }}, $_
        for grep { not ref $field2csv->{$_} } keys %{$field2csv};

    # Right now, the CSV configuration *requires* setting 'Queue' to a
    # static string reference. That means each CSV file can only
    # contain tickets for a single Queue.
    #
    # In the future, we may want to extend Queue column handling so
    # that CSVs can contain tickets for different queues. That will
    # require testing each CF and CR that the row has values for to
    # make sure they are applied to the given Queue.
    unless (ref($field2csv->{'Queue'}) eq "SCALAR") {
            $RT::Logger->error( "Default Queue is not defined. Make sure Queue value is a reference to a string." );
            return (0, 0, 0);
    }

    my $default_queue = RT::Queue->new( $args{CurrentUser} );
    $default_queue->Load(${$field2csv->{Queue}});
    unless ( $default_queue->Id ) {
        RT->Logger->error( "Could not load queue: " . $field2csv->{Queue} );
    }

    if (scalar RT->Config->Get('TicketsImportUniqueCFs') && RT->Config->Get('TicketsImportTicketIdField') ) {
        RT->Logger->error( "Provided 'TicketsImportUniqueCFs' and 'TicketsImportTicketIdField' config values, can only have one." );
        return (0, 0, 0);
    }

    my @unique = ();
    # If we are updating based on existing ticket ID's then we shouldn't need to look at custom fields
    if ( !RT->Config->Get('TicketsImportTicketIdField') ) {
        @unique = RT->Config->Get('TicketsImportUniqueCFs') if RT->Config->Get('TicketsImportUniqueCFs');
    }

    if ( !scalar @unique && !RT->Config->Get('TicketsImportTicketIdField')) {
        if ( $args{Update} or $args{InsertUpdate} ) {
            $RT::Logger->error( "TicketsImportUniqueCFs or TicketsImportTicketIdField is not set and is required for updating tickets" );
            return ( 0, 0, 0 );
        }

        if ( !$args{Insert} ) {
            $RT::Logger->error( "TicketsImportUniqueCFs or TicketsImportTicketIdField is not set. Use --insert to create tickets" );
            return ( 0, 0, 0 );
        }
    }

    # Confirm we can load the configured unique CFs and save the ids for later
    my %unique_cf_objs;
    if ( scalar @unique) {
        foreach my $unique ( @unique ){
            my $unique_cf = RT::CustomField->new( $args{CurrentUser} );
            $unique_cf->LoadByName(
                Name => $unique,
                LookupType => RT::Ticket->CustomFieldLookupType,
                ObjectId => $default_queue->id,
                IncludeGlobal => 1,
            );
            unless ($unique_cf->id) {
                $RT::Logger->error( "Can't find custom field $unique for RT::Tickets" );
                return (0, 0, 0);
            }
            $unique_cf_objs{"$unique"} = $unique_cf;
        }
    }

    my %cfmap;
    my %crmap;
    for my $fieldname (keys %{ $field2csv }) {
        if ($fieldname =~ /^CF\.(.*)/) {
            my $cfname = $1;
            my $cf = RT::CustomField->new( $args{CurrentUser} );
            $cf->LoadByName(
                Name => $cfname,
                LookupType => RT::Ticket->CustomFieldLookupType,
                ObjectId => $default_queue->id,
                IncludeGlobal => 1,
            );
            if ( $cf->id ) {
                $cfmap{$cfname} = $cf;
            } else {
                $RT::Logger->warning(
                    "Missing custom field $cfname for "._column($field2csv->{$fieldname}).", skipping");
                delete $field2csv->{$fieldname};
            }
        } elsif ($fieldname =~ /^CR\.(.*)/) {
            # no-op for now
            my $crname = $1;
            my $cr     = RT::CustomRole->new( $args{CurrentUser} );
            $cr->Load( $crname );
            if ( $cr->id ) {
                $crmap{$crname} = $cr;
            }
            else {
                $RT::Logger->warning(
                    "Missing custom role $crname for " . _column( $field2csv->{$fieldname} ) . ", skipping" );
                delete $field2csv->{$fieldname};
            }
        } elsif ($fieldname =~ /^(id|Creator|LastUpdated|Created|Queue|Requestor|Cc|AdminCc|SquelchMailTo|Type|Owner|
            Subject|Priority|InitialPriority|FinalPriority|Status|TimeEstimated|TimeWorked|TimeLeft|Starts|Due|MIMEObj|
            Comment|Correspond|MemberOf|Parents|Parent|Members|Member|Children|Child|HasMember|RefersTo|ReferredToBy|
            DependsOn|DependedOnBy)$/x) {
            # no-op, these are fine
        } else {
            $RT::Logger->warning(
                "Unknown ticket field $fieldname for "._column($field2csv->{$fieldname}).", skipping");
            delete $field2csv->{$fieldname};
        }
    }

    my %tolerant_roles = map { $_ => 1 } @{ RT->Config->Get('TicketTolerantRoles') || [] };

    my ($header, @items) = $class->parse_csv( $args{File}, force => $args{Force} );
    unless (@items) {
        $RT::Logger->warning( "No items found in file $args{File}" );
        return (0, 0, 0);
    }

    $RT::Logger->debug( "Found unused column '$_'" )
        for grep { $_ ne '_line' && !$ticket_extra_fields{$_} && !$csv2fields->{$_}} keys %{ $items[0] };
    $RT::Logger->warning( "No column $_ found for @{$csv2fields->{$_}}" )
        for grep {not exists $items[0]->{$_} } keys %{ $csv2fields };

    $RT::Logger->debug( 'Found ' . scalar(@items) . ' record(s)' );
    my ( $created, $updated, $skipped ) = (0) x 3;
    my @skipped;  # Save skipped records for output to errors file

    my $row = 1; # Because of header row
    ROW:
    for my $item (@items) {
        local $CurrentRow = ++$row;
        local $CurrentLine = $item->{_line};
        $RT::Logger->debug( "Start processing" );
        next unless grep { defined $_ && /\S/ } values %{ { %$item, _line => undef } };

        my $tickets = RT::Tickets->new( $args{CurrentUser} );

        # Exclude statuses configured within ExcludeStatusesOnSearch from the loaded tickets
        my @excluded_statuses;
        @excluded_statuses = RT->Config->Get('ExcludeStatusesOnSearch')
            if RT->Config->Get('ExcludeStatusesOnSearch');

        if ( scalar @excluded_statuses ) {
            foreach my $status ( @excluded_statuses ) {
                unless ( $default_queue->LifecycleObj->IsValid( lc($status) ) ) {
                    $RT::Logger->warning( "Status '$status' is not valid. Tickets matching '$status' will not be excluded" );
                    next;
                }

                $tickets->Limit(
                    FIELD => 'Status',
                    VALUE => lc($status),
                    OPERATOR => '!=',
                    ENTRYAGGREGATOR => 'AND',
                );
            }
        }

        my $unique_fields = 'Unique field data: ';

        if ( scalar @unique ) {
            my $id_value;

            my @unique_fields_data;

            foreach my $unique ( @unique ){
                $id_value = $class->get_value( $field2csv->{"CF.$unique"}, $item ) // '';
                push @unique_fields_data, "$unique: $id_value";
                if ( length $id_value ) {
                    $tickets->_LimitCustomField(
                        CUSTOMFIELD => $unique_cf_objs{"$unique"},
                        VALUE       => $id_value,
                    );
                }
                else{
                    $tickets->_LimitCustomField(
                        CUSTOMFIELD => $unique_cf_objs{"$unique"},
                        VALUE       => undef,
                        OPERATOR    => 'IS',
                    );
                }
            }

            $unique_fields .= join( ', ', @unique_fields_data );
        }

        # set within this scope for RT::Logger->add_callback
        local $UniqueFields = $unique_fields;

        if ( RT->Config->Get('TicketsImportTicketIdField') && $args{'Update'} ) {
            my $value = $class->get_value( RT->Config->Get('TicketsImportTicketIdField'), $item );
            unless ( $value ) {
                RT->Logger->error( "Invalid \$TicketsImportTicketIdField: '".RT->Config->Get('TicketsImportTicketIdField')."' value provided, unable to find field mapping" );
                $skipped++;
                push @skipped, $item;
                next;
            }

            $tickets->Limit( FIELD => 'Id', VALUE => $value );
        }

        if ( $tickets->Count ) {
            my $ticket;

            if ( $tickets->Count > 1 ) {
                if ( RT->Config->Get('TicketsImportTicketIdField') ) {
                    my $id = $class->get_value( RT->Config->Get('TicketsImportTicketIdField'), $item );
                    $RT::Logger->warning( "Found multiple tickets IDs, for $id, skipping." );
                }
                else {
                    $RT::Logger->warning( "Found multiple tickets for CFs, skipping. $unique_fields" );
                }
                $skipped++;
                push @skipped, $item;
                next;
            }
            else {
                $ticket = $tickets->First;
                my $ticket_id = $ticket->Id;
                if ( RT->Config->Get('TicketsImportTicketIdField') ) {
                    $RT::Logger->debug( "Found existing ticket ($ticket_id)" );
                }
                else {
                    $RT::Logger->debug( "Found existing ticket ($ticket_id) for CFs. $unique_fields" );
                }
            }

            unless ( $args{Update} or $args{InsertUpdate} ) {
                if ( RT->Config->Get('TicketsImportTicketIdField') ) {
                    my $id = $class->get_value( RT->Config->Get('TicketsImportTicketIdField'), $item );
                    $RT::Logger->debug(
                        "Found existing ticket but no '--update' or '--insert-update' option, skipping. $id"
                    );
                }
                else {
                    $RT::Logger->debug(
                        "Found existing ticket but no '--update' or '--insert-update' option, skipping. $unique_fields"
                    );
                }
                $skipped++;
                push @skipped, $item;
                next;
            }


            if ( my $callback = RT->Config->Get('PreTicketChangeCallback') ) {
                my ( $ret, $msg ) = $callback->(
                    TicketObj   => $ticket,
                    Row         => $item,
                    Type        => 'Update',
                    CurrentUser => $args{CurrentUser},
                );
                if ( !$ret ) {
                    $RT::Logger->debug( "PreTicketChangeCallback returned false, skipping. " . ( $msg // '' ) );
                    $skipped++;
                    push @skipped, $item;
                    next;
                }
            }

            my $changes;
            my $invalid;
            for my $field ( keys %$field2csv ) {
                my $value = $class->get_value( $field2csv->{$field}, $item );
                unless ( defined $value and length $value ) {
                    if ( grep { $field eq $_ } @{ RT->Config->Get( 'TicketMandatoryFields' ) || [] } ) {
                        $RT::Logger->error( "Missing mandatory $field, skipping. $unique_fields" );
                        $invalid = 1;
                    }
                    else {
                        next;
                    }
                }

                if ($field =~ /^CF\.(.*)/) {
                    my $cfname = $1;

                    if ($cfmap{$cfname}->Type eq "DateTime") {
                        my $args = { Content => $value };
                        # $cfmap{$cfname}->_CanonicalizeValueDateTime( $args );
                        $value = $args->{Content};
                    } elsif ($cfmap{$cfname}->Type eq "Date") {
                        my $args = { Content => $value };
                        $cfmap{$cfname}->_CanonicalizeValueDate( $args );
                        $value = $args->{Content};
                    }

                    my @current = @{$ticket->CustomFieldValues( $cfmap{$cfname}->id )->ItemsArrayRef};
                    next if grep {$_->Content and $_->Content eq $value} @current;

                    $changes++;
                    my ($ok, $msg) = $ticket->AddCustomFieldValue(
                        Field => $cfmap{$cfname}->id,
                        Value => $value,
                    );
                    unless ($ok) {
                        $RT::Logger->error("Failed to set CF $cfname to $value: $msg");
                    }
                } elsif ($field =~ /^CR\.(.*)/) {
                    my $crname = $1;
                    # we only want to check members that are directly added to the group
                    my %members = map { $_->id => $_ }
                      @{ $ticket->RoleGroup( $crmap{$crname}->GroupType )->UserMembersObj( Recursively => 0 )->ItemsArrayRef };

                    my @values = $class->parse_email_address( $value );
                    for my $value ( @values ) {
                        my $user = $class->load_or_create_user( CurrentUser => $args{CurrentUser}, EmailAddress => $value->address );
                        if ( $user ) {
                            if ( $members{$user->id} ) {
                                delete $members{$user->id};
                            }
                            else {
                                my ( $ok, $msg )
                                  = $ticket->AddRoleMember( PrincipalId => $user->PrincipalId, Type => $crmap{$crname}->GroupType );
                                if ( $ok ) {
                                    $changes++;
                                }
                                else {
                                    $RT::Logger->error( "Failed to add $value to $field: $msg" );
                                }
                            }
                        }
                        else {
                            $RT::Logger->error( "Failed to find user with email '$value'" );
                        }
                    }
                    # delete old ones
                    for my $id ( keys %members ) {
                        next unless $ticket->RoleGroup( $crmap{$crname}->GroupType )->HasMember( $id );
                        my ( $ok, $msg ) = $ticket->DeleteRoleMember( PrincipalId => $id, Type => $crmap{$crname}->GroupType );
                        if ( $ok ) {
                            $changes++;
                        }
                        else {
                            $RT::Logger->error( "Failed to delete " . $members{$id}->Name . " from $field: $msg" );
                        }
                    }
                } elsif ($field =~ /^(?:Requestor|Cc|AdminCc)$/) {
                    my %members = map { $_->id => $_ }
                      @{ $ticket->RoleGroup( $field )->UserMembersObj( Recursively => 0 )->ItemsArrayRef };

                    my @values = $class->parse_email_address( $value );
                    for my $value ( @values ) {
                        my $user = $class->load_or_create_user( CurrentUser => $args{CurrentUser}, EmailAddress => $value->address );
                        if ( $user ) {
                            if ( $members{$user->id} ) {
                                delete $members{$user->id};
                            }
                            else {
                                my ( $ok, $msg )
                                  = $ticket->AddRoleMember( PrincipalId => $user->PrincipalId, Type => $field );
                                if ( $ok ) {
                                    $changes++;
                                }
                                else {
                                    $RT::Logger->error( "Failed to add $value to $field: $msg" );
                                }
                            }
                        }
                        else {
                            $RT::Logger->error( "Failed to find user with email '$value'" );
                        }
                    }
                    # delete old ones
                    for my $id ( keys %members ) {
                        next unless $ticket->RoleGroup( $field )->HasMember( $id );
                        my ( $ok, $msg ) = $ticket->DeleteRoleMember( PrincipalId => $id, Type => $field );
                        if ( $ok ) {
                            $changes++;
                        }
                        else {
                            $RT::Logger->error( "Failed to delete " . $members{$id}->Name . " from $field: $msg" );
                        }
                    }
                } elsif ( $ticket->_CoreAccessible->{$field}{write} ) {
                    if ($field eq "Queue") {
                        my $queue = RT::Queue->new( $args{CurrentUser} );
                        $queue->Load( $value );
                        $value = $queue->id;
                    }

                    if ( $field eq 'Owner' ) {
                        $value =~ s!;$!!;
                        my $user = $class->load_or_create_user( CurrentUser => $args{CurrentUser}, EmailAddress => $value );
                        if ( $user ) {
                            $value = $user->id;
                        }
                        else {
                            $RT::Logger->error( "Failed to find user with email '$value'" );
                        }
                    }

                    if ($ticket->$field ne $value) {
                        my $method = "Set" . $field;
                        my ($ok, $msg) = $ticket->$method( $value );
                        if ( $ok ) {
                            $changes++;
                        }
                        else {
                            $RT::Logger->error( "Failed to set $field to $value: $msg" );
                        }
                    }
                } elsif ($field =~ /^(?:Correspond|Comment)$/) {
                    my ($ok, $msg) = $ticket->$field( Content => $value );
                    if ( $ok ) {
                        $changes++;
                    }
                    else {
                        $RT::Logger->error( "Failed to $field on ticket with content $value: $msg" );
                    }
                }
            }

            if ($invalid) {
                $skipped++;
                push @skipped, $item;
                next;
            }

            if ($changes) {
                $RT::Logger->debug( "Ticket " . $ticket->id . " updated. $unique_fields" );
                $updated++;
                if ( my $callback = RT->Config->Get('PostTicketChangeCallback') ) {
                    $callback->( TicketObj => $ticket, Row => $item,
                                 Type => 'Update', CurrentUser => $args{CurrentUser} );
                }
            } else {
                $RT::Logger->debug( "Ticket " . $ticket->id . " skipped. No updates required." );
                $skipped++;
                push @skipped, $item;
            }
        }
        else {
            # No existing tickets found, consider insert
            unless ( $args{Insert} or $args{InsertUpdate} ) {
                $RT::Logger->debug(
                    "No existing tickets found and no '--insert' or '--insert-update' option, skipping. $unique_fields"
                );
                $skipped++;
                push @skipped, $item;
                next;
            }

            if ( my $callback = RT->Config->Get('PreTicketChangeCallback') ) {
                my ( $ret, $msg ) = $callback->(
                    Row         => $item,
                    Type        => 'Create',
                    CurrentUser => $args{CurrentUser},
                );
                if ( !$ret ) {
                    $RT::Logger->debug( "PreTicketChangeCallback returned false, skipping. " . ( $msg // '' ) );
                    $skipped++;
                    push @skipped, $item;
                    next;
                }
            }

            my $invalid;
            my $ticket = RT::Ticket->new( $args{CurrentUser} );
            my $current_user = $args{CurrentUser};
            my %args;

            for my $field (keys %$field2csv ) {
                my $value = $class->get_value($field2csv->{$field}, $item);
                unless ( defined $value and length $value ) {
                    if ( grep { $field eq $_ } @{ RT->Config->Get( 'TicketMandatoryFields' ) || [] } ) {
                        $RT::Logger->error( "Missing mandatory $field, skipping. $unique_fields" );
                        $invalid = 1;
                    }
                    else {
                        next;
                    }
                }

                if ($field =~ /^CF\.(.*)/) {
                    my $cfname = $1;
                    my $args = { Content => $value };
                    my ( $ret, $msg ) = $cfmap{$cfname}->_CanonicalizeValue( $args  );

                    # Date cfs return 1970-01-01 if it can't extrat dates
                    if ( $cfmap{$cfname}->Type =~ /^Date(?:Time)?$/ && $args->{Content} =~ /^1970-01-01/ ) {
                        $ret = 0;
                    }

                    # Verify select-one type CF values are one of the allowed values for that CF
                    if ( $cfmap{$cfname}->Type eq 'Select' ) {
                        my @allowed_values = @{ $cfmap{$cfname}->Values->ItemsArrayRef };
                        $ret = 0 unless grep { $_->Name eq $value } @allowed_values;
                    }

                    if ($ret) {
                        $args{ "CustomField-" . $cfmap{$cfname}->id } = $value;
                    }
                    elsif ($force) {
                        RT->Logger->error("Invalid CF $cfname value '$value', creating without it");
                    }
                    else {
                        RT->Logger->error( "Invalid CF $cfname value '$value', skipping. $unique_fields" );
                        $invalid = 1;
                    }
                } elsif ($field =~ /^CR\.(.*)/) {
                    my $crname = $1;
                    my @values = $class->parse_email_address( $value );

                    if ( !@values ) {
                        if ( $force || $tolerant_roles{$field} ) {
                            RT->Logger->error("Failed to extract email from '$value', creating without it");
                        }
                        else {
                            RT->Logger->error("Failed to extract email from '$value', skipping. $unique_fields");
                            $invalid = 1;
                        }
                    }

                    my @emails;
                    for my $value ( @values ) {
                        my $user = $class->load_or_create_user( CurrentUser => $current_user, EmailAddress => $value->address );
                        if ( $user ) {
                            push @emails, $value;
                        }
                        elsif ( $force || $tolerant_roles{$field} ) {
                            RT->Logger->error(
                                "Failed to find user with email '$value', creating without it" );
                        }
                        else {
                            RT->Logger->error( "Failed to find user with email '$value', skipping. $unique_fields" );
                            $invalid = 1;
                        }
                    }
                    $args{ $crmap{$crname}->GroupType } = join ', ', @emails;
                } elsif ($field =~ /^(?:Requestor|Cc|AdminCc)$/) {
                    my @values = $class->parse_email_address( $value );

                    if ( !@values ) {
                        if ( $force || $tolerant_roles{$field} ) {
                            RT->Logger->error("Failed to extract email from '$value', creating without it");
                        }
                        else {
                            RT->Logger->error("Failed to extract email from '$value', skipping. $unique_fields");
                            $invalid = 1;
                        }
                    }

                    my @emails;
                    for my $value ( @values ) {
                        my $user = $class->load_or_create_user( CurrentUser => $current_user, EmailAddress => $value->address );
                        if ( $user ) {
                            push @emails, $value;
                        }
                        elsif ( $force || $tolerant_roles{$field} ) {
                            RT->Logger->error(
                                "Failed to find user with email '$value', creating without it" );
                        }
                        else {
                            RT->Logger->error( "Failed to find user with email '$value', skipping. $unique_fields" );
                            $invalid = 1;
                        }
                    }
                    $args{ $field } = join ', ', @emails;
                } elsif ($field eq 'Owner' && $value) {
                    $value =~ s!;$!!;
                    my $user = $class->load_or_create_user( CurrentUser => $current_user, EmailAddress => $value );
                    if ( $user && $user->HasRight( Right => 'OwnTicket', Object => $default_queue ) ) {
                        $args{$field} = $user->id;
                    }
                    elsif ( $force || $tolerant_roles{$field} ) {
                        if ( $user ) {
                            RT->Logger->error(
                                "User with email '$value' doesn't have OwnTicket right, creating with owner as Nobody"
                            );
                        }
                        else {
                            RT->Logger->error( "Failed to find owner with email '$value', creating with owner as Nobody" );
                        }
                        delete $args{$field};
                    }
                    else {
                        if ( $user ) {
                            RT->Logger->error(
                                "User with email '$value' doesn't have OwnTicket right, skipping. $unique_fields"
                            );
                        }
                        else {
                            RT->Logger->error(
                                "Failed to find owner with email '$value', skipping. $unique_fields"
                            );
                        }
                        $invalid = 1;
                    }
                } else {
                    $args{$field} = $value;
                }

                if ( $field =~ /^(?:Correspond|Comment)$/ ) {
                    $args{'MIMEObj'} = MIME::Entity->build(
                        Type    => "text/plain",
                        Charset => "UTF-8",
                        Data    => Encode::encode("UTF-8", $value),
                    );
                }
            }

            my $status = delete( $args{Status} );
            if ( $status && !$default_queue->LifecycleObj->IsValid($status) ) {
                if ($force) {
                    RT->Logger->error("Status '$status' is not valid, creating without it");
                }
                else {
                    RT->Logger->error("Status '$status' is not valid, skipping. $unique_fields");
                    $invalid = 1;
                }
            }

            my $created_date = delete $args{Created};
            if ( $created_date ) {
                my $date = RT::Date->new( RT->SystemUser );
                $date->Set( Format => 'unknown', Value => $created_date );
                if ( !$date->Unix ) {
                    if ($force) {
                        RT->Logger->error("Created date '$created_date' is not valid, creating without it");
                    }
                    else {
                        RT->Logger->error("Created date '$created_date' is not valid, skipping. $unique_fields");
                        $invalid = 1;
                    }
                }
            }

            if ($invalid) {
                $skipped++;
                push @skipped, $item;
                next;
            }

            my ($ok, $txnobj, $msg) = $ticket->Create( %args );

            if ($ok) {
                $created++;
            } else {
                $RT::Logger->error("Failed to create ticket: $msg, skipping. $unique_fields");
                $skipped++;
                push @skipped, $item;
                next ROW;
            }

            if ($status && $status ne $ticket->Status) {
                ($ok, $msg) = $ticket->__Set(Field => 'Status', Value => $status);
                $RT::Logger->error("Failed to set Status on ticket: $msg") unless $ok
            }

            if ( $created_date ) {
                my $date = RT::Date->new( RT->SystemUser );
                $date->Set( Format => 'unknown', Value => $created_date );
                ( $ok, $msg ) = $ticket->__Set( Field => 'Created', Value => $date->ISO );
                $RT::Logger->error("Failed to set Created on ticket: $msg") unless $ok;

                my $txns = $ticket->Transactions;
                $txns->Limit( FIELD => 'Type', VALUE => 'Create' );
                if ( my $txn = $txns->First ) {
                    ( $ok, $msg ) = $txn->__Set( Field => 'Created', Value => $date->ISO );
                    $RT::Logger->error( "Failed to set Created on ticket create transaction: $msg" )
                      unless $ok;
                }
            }

            if ( my $callback = RT->Config->Get('PostTicketChangeCallback') ) {
                $callback->( TicketObj => $ticket, Row => $item,
                             Type => 'Create', CurrentUser => $args{CurrentUser} );
            }
        }
    }

    # Convert skipped hashrefs into correctly ordered arrays based on the header
    my @skipped_refs;
    foreach my $item_ref ( @skipped ){
        my @skipped_line;
        foreach my $column ( @$header ){
            next if $column eq '_line';
            push @skipped_line, $item_ref->{$column};
        }
        push @skipped_refs, \@skipped_line;
    }

    # Prepend the header line if we found any skipped items
    unshift @skipped_refs, $header if scalar @skipped;

    return ( $created, $updated, $skipped, \@skipped_refs );
}

sub get_value {
    my $class = shift;
    my ($from, $data) = @_;
    if (not ref $from) {
        return $data->{$from};
    } elsif (ref($from) eq "CODE") {
        return $from->($data);
    } else {
        return $$from;
    }
}

sub parse_csv {
    my $class = shift;
    my $file  = shift;
    my %args  = @_;

    my @rows;

    open my $fh, '<', $file or die "failed to read $file: $!";
    while (<$fh>) {
        if ( /\r\r\n/ ) {
            RT->Logger->error( "Line $. contains invalid characters" . '(\r\r\n), skipping' );
            return;
        }
    }

    my $csv = Text::CSV_XS->new(
        {
            sep_char    => ',',
            binary      => 1,
            %{ RT->Config->Get('CSVOptions') || {} },
        }
    );

    close $fh;
    open $fh, '<', $file or die "failed to read $file: $!";
    my $header = $args{header} || $csv->getline($fh);
    my @items;

    unless ( $header ){
        RT->Logger->error("Error reading header line from file $file, stopping import");
        return $header, @items;
    }

    my $previous_line = $. || 0;
    while ( my $row = $csv->getline($fh) ) {
        my $item = { _line => $previous_line + 1 };
        # get around the extra and suspicious column
        @$row = grep { !/Ticket was imported from TTP/ } @$row if @$header <= @$row;
        for ( my $i = 0 ; $i < @$header ; $i++ ) {
            if ( $header->[$i] ) {
                $item->{ $header->[$i] } = $row->[$i];
            }
        }

        push @items, $item;
        $previous_line = $.;
    }

    if ( !$csv->eof ) {
        RT->Logger->error( $csv->error_diag() );
        exit 1 unless $args{force};
    }
    close $fh;
    return $header, @items;
}

sub set_fixed_time {
    my $class = shift;
    my $value = shift;
    my $date  = RT::Date->new( RT->SystemUser );
    $date->Set( Format => 'unknown', Value => $value );
    if ( $date->Unix > 0 ) {
        Test::MockTime::set_fixed_time( $date->Unix );
    }
    else {
        $RT::Logger->warning( "Invalid datetime: $value" );
    }
}

sub load_or_create_user {
    my $class = shift;
    my %args  = @_;
    my $user  = RT::User->new( delete $args{CurrentUser} );
    $user->Load( $args{EmailAddress} );
    return $user if $user->id;
    $user->LoadByEmail( $args{EmailAddress} );
    return $user if $user->id;

    my ( $ok, $msg ) = $user->Create( Privileged => 1, Name => $args{EmailAddress}, %args );
    if ($ok) {
        return $user;
    }

    my $arg = { EmailAddress => $args{EmailAddress} };
    if ( $msg eq 'Name in use' && $user->CanonicalizeUserInfoFromExternalAuth($arg) ) {
        if ( $arg->{Name} ) {
            $user = RT::User->new( $user->CurrentUser );
            $user->Load( $arg->{Name} );
            if ( $user->id ) {
                RT->Logger->warning(
                    "Found user with same Name($arg->{Name}) but provided email address "
                    . $args{EmailAddress} . " differs from RT email address: " . $user->EmailAddress );
                my ( $ret, $msg ) = $user->SetEmailAddress( $args{EmailAddress} );
                if ($ret) {
                    RT->Logger->info( "Updated user #" . $user->Id . " EmailAddress to $args{EmailAddress}" );
                }
                else {
                    RT->Logger->warning(
                        "Couldn't update user #" . $user->Id . " EmailAddress to $args{EmailAddress}: $msg" );
                }
                return $user;
            }
        }
    }
    return undef;
}

sub _run_articles {
    my $class = shift;
    my %args  = (
        CurrentUser => undef,
        File        => undef,
        Update      => undef,
        Insert      => undef,
        @_,
    );

    my $article_class_name = $args{ArticleClass};
    my $article_class = RT::Class->new( RT->SystemUser );
    my ( $ret, $msg ) = $article_class->Load( $article_class_name );
    if ( !$ret ) {
        $RT::Logger->error("Failed to load article class $article_class_name: $msg");
        return ( 0, 0, 0 );
    }

    my $field2csv  = $RT::Config->Get('ArticlesImportFieldMapping');
    my $csv2fields = {};
    push @{ $csv2fields->{ $field2csv->{$_} } }, $_ for grep { not ref $field2csv->{$_} } keys %{$field2csv};

    my ($header, @items) = $class->parse_csv( $args{File}, force => $args{Force} );
    unless (@items) {
        $RT::Logger->warning("No items found in file $args{File}");
        return ( 0, 0, 0 );
    }

    $RT::Logger->debug("Found unused column '$_'")
        for grep { $_ ne '_line' && not $csv2fields->{$_} } keys %{ $items[0] };
    $RT::Logger->warning("No column $_ found for @{$csv2fields->{$_}}")
        for grep { not exists $items[0]->{$_} } keys %{$csv2fields};

    $RT::Logger->debug( 'Found ' . scalar(@items) . ' record(s)' );
    my ( $created, $updated, $skipped ) = (0) x 3;
    my %cf_id;
    my $update = $args{Update};

    my $row = 1; # Because of header row
    for my $item (@items) {
        local $CurrentRow = ++$row;
        local $CurrentLine = $item->{_line};
        $RT::Logger->debug("Start processing");
        next unless grep { defined $_ && /\S/ } values %{ { %$item, _line => undef } };
        my $article      = RT::Article->new( $args{CurrentUser} );
        my $current_user = $args{CurrentUser};

        # only insert for now, no update needed here yet.
        my %args;

        for my $field ( keys %$field2csv ) {
            my $value = $class->get_value( $field2csv->{$field}, $item );
            next unless defined $value and length $value;
            if ( $field =~ /^CF\.(.+)/ ) {
                my $name = $1;
                if ( !$cf_id{$name} ) {
                    my $cf = RT::CustomField->new( RT->SystemUser );
                    $cf->LoadByName(
                        Name          => $name,
                        LookupType    => RT::Article->CustomFieldLookupType,
                        ObjectId      => $article_class->id,
                        IncludeGlobal => 1,
                    );
                    if ($ret) {
                        $cf_id{$name} = $cf->id;
                    }
                    else {
                        $RT::Logger->error("Failed to load article custom field $name: $msg");
                    }
                }
                $args{"CustomField-$cf_id{$name}"} = $value;
            }
            else {
                $args{$field} = $value;
            }
        }

        $article->LoadByCols( Name => $args{Name} );
        if ( $article->id ) {
            $RT::Logger->info("Found existing article $args{Name}");
            unless ($update) {
                $RT::Logger->debug("Found existing article but without 'Update' option, skipping.");
                $skipped++;
                next;
            }

            my $changed;
            for my $field ( keys %args ) {
                if ( $field =~ /CustomField-(\d+)/ ) {
                    my $cf_id = $1;
                    if ( $article->FirstCustomFieldValue($1) ne $args{$field} ) {
                        my ( $ret, $msg ) = $article->AddCustomFieldValue(
                            Field => $cf_id,
                            Value => $args{$field},
                        );
                        if ($ret) {
                            $changed ||= 1;
                        }
                        else {
                            $RT::Logger->error("Failed to set $field to $args{$field}: $msg");
                        }
                    }
                }
                elsif ( $article->$field ne $args{$field} ) {
                    my $method = "Set$field";
                    my ( $ret, $msg ) = $article->$method( $args{$field} );
                    if ($ret) {
                        $changed ||= 1;
                    }
                    else {
                        $RT::Logger->error("Failed to set $field to $args{$field}: $msg");
                    }
                }
            }

            if ($changed) {
                $RT::Logger->debug("Updated article $args{Name} in class $article_class_name");
                $updated++;
            }
            else {
                $RT::Logger->debug("Skipped article $args{Name} in class $article_class_name");
                $skipped++;
            }
        }
        else {
            my $article = RT::Article->new($current_user);
            my ( $ret, $msg ) = $article->Create( Class => $article_class->id, %args );
            if ($ret) {
                $created++;
                $RT::Logger->info("Created article $args{Name} in class $article_class_name");
            }
            else {
                $RT::Logger->error("Failed to created article $args{Name} in class $article_class_name: $msg");
                $skipped++;
            }
        }
    }
    return ( $created, $updated, $skipped );
}


# Based on RT::EmailParser::ParseEmailAddress, and also checks external auth
# if the value is a name and RT doesn't have corresponding user

sub parse_email_address {
    my $class          = shift;
    my $address_string = shift;

    $address_string =~ s/;/,/g;

    # Some broken mailers send:  ""Vincent, Jesse"" <jesse@fsck.com>. Hate
    $address_string =~ s/\"\"(.*?)\"\"/\"$1\"/g;

    my @list = Email::Address::List->parse(
        $address_string,
        skip_comments => 1,
        skip_groups   => 1,
    );
    my $logger = sub {
        RT->Logger->error( "Unable to parse an email address from $address_string: " . shift );
    };

    my @addresses;
    foreach my $e (@list) {
        if ( $e->{'type'} eq 'mailbox' ) {
            if ( $e->{'not_ascii'} ) {
                $logger->( $e->{'value'} . " contains not ASCII values" );
                next;
            }
            push @addresses, $e->{'value'};
        }
        elsif ( $e->{'value'} =~ /^\s*([\w ]+)\s*$/ ) {
            my $name = $1;
            my $user = RT::User->new( RT->SystemUser );
            $user->Load($name);
            if ( $user->id ) {
                push @addresses, Email::Address->new( $user->Name, $user->EmailAddress );
            }
            else {
                my $args = { Name => $name };
                if ( $user->CanonicalizeUserInfoFromExternalAuth($args) ) {
                    push @addresses, Email::Address->new( $args->{EmailAddress} );
                }
                else {
                    $logger->( $e->{'value'} . " is not a valid email address and is not user name" );
                }
            }
        }
        else {
            $logger->( $e->{'value'} . " is not a valid email address" );
        }
    }

    RT::EmailParser->CleanupAddresses(@addresses);

    return @addresses;
}

=head1 NAME

RT-Extension-Import-CSV

=head1 DESCRIPTION

This extension is used to import data from a comma-separated value
(CSV) file, or any other sort of delimited file, into RT. The importer
provides functionality for importing tickets, transactions, users, and
articles.

Some common uses of this functionality include:

=over

=item Migrating data to RT from another ticketing system (JIRA, ServiceNow, etc.)

This is the most common method of dumping ticket data from another system.
Whether it be a CSV, TSV, or Excel file, this extension provides the
flexibility needed to get that data into RT.

=item Syncing data from a non-ticketing system (billing, lead generation, etc.) with RT

For example, users might create sales leads in a lead-tracking system,
then sync them to RT to create tickets for later follow up and conversation
tracking.

=item Importing user accounts from another system

In the above lead generation example, having the same users in both systems
may be convenient. Exporting users from that system and importing them into
RT reduces the amount of administrative work necessary to make that happen.

=item Importing articles from another knowledge management system (KMS)

RT allows you to include article content in comments and correspondence.
An organization may have a library of this content already available. By
exporting that content and importing it into RT, you can easily include
it on tickets without having to copy/paste from a KMS.

=back

This guide explains how to configure the import tool, and includes
examples of how to run the import with different options. The actual
import is run by L<rt-extension-import-csv> - there is no web-based
component for the import process. Please see the documentation for
L<rt-extension-import-csv> for more in-depth documentation about
the options that the importer can be run with.

=head1 RT VERSION

Works with RT 5.

=head1 INSTALLATION

=over

=item C<perl Makefile.PL>

=item C<make>

=item C<make install>

May need root permissions

=item Edit your F</opt/rt5/etc/RT_SiteConfig.pm>

Add this line:

    Plugin('RT::Extension::Import::CSV');

=item Clear your mason cache

    rm -rf /opt/rt5/var/mason_data/obj

=item Restart your webserver

=back

=head1 CONFIGURATION

The following configuration can import a three-column CSV and illustrates
the basic functionality of the CSV importer:

    Set( @TicketsImportUniqueCFs, ('Purchase Order ID') );
    Set( %TicketsImportFieldMapping,
        'Created'              => 'Ticket-Create-Date',
        'CF.Purchase Order ID' => 'PO-Number',
        'Subject'              => 'name',
    );

When creating a column mapping, the value to the left of C<=>> is
the RT field name, and to the right is the column name in the CSV
file. CSV files to be imported B<must> have a header line for the
mapping to function.

In this configuration, the custom field C<Purchase Order ID> must be
unique, and can accept accept a combination of values. To insert a row
with this config, RT must find no existing tickets, and for update RT
must only find a single matching row. If neither condition matches, the
CSV row is skipped.

=head2 Excluding Existing Tickets By Status

In the example above, when searching for an existing ticket for a PO,
it may be necessary to skip certain existing tickets involving this PO
that were previously resolved. To instruct the importer to exclude
tickets in some statuses, set the following option:

    Set( @ExcludeStatusesOnSearch, ('resolved', 'cancelled'));

=head2 Constant values

If you want to set an RT column or custom field to the same value for
all imported tickets, precede the CSV field name (right hand side of
the mapping) with a slash, like so:

    Set( %TicketsImportFieldMapping,
        'Queue'                => \'General',
        'Created'              => 'Ticket-Create-Date',
        'CF.Original TicketID' => 'TicketID',
        'Subject'              => 'name',
    );

Every imported ticket will now be added to the 'General' queue.  This
feature is particularly useful for setting the queue, but may also be
useful when importing tickets from CSV sources you don't control (and
don't want to modify each time).

=head2 Computed values (advanced)

You may also compute values during import, by passing a subroutine
reference as the value in the C<%TicketsImportFieldMapping>.  This
subroutine will be called with a hash reference of the parsed CSV
row. In the following example, the subroutine assigned to the 'Status'
field takes the value in the 'status' CSV column and replaces
underscores with spaces.

    Set( %TicketsImportFieldMapping,
        'Queue'                => \'General',
        'Created'              => 'Ticket-Create-Date',
        'CF.Original TicketID' => 'TicketID',
        'Subject'              => 'name',
        'Status'               => sub { $_[0]->{status} =~ s/_/ /gr; },
    );

Using computed columns may cause false-positive "unused column"
warnings during the import; these can be ignored.

=head2 Dates and Date Formatting

When importing tickets, the importer will automatically populate Created
for you, provided there isn't a column in the source data already
mapped to it. Other date fields must be provided in the source data.

The importer does a fairly good job at guessing the source datetime
format; if the source datetime format can't be parsed, Perl can help you
out.

If you have to munge dates, we recommend converting them to the
L<ISO|https://en.wikipedia.org/wiki/ISO_8601> datetime format
(yyyy-mm-dd hh:mm::ss and other accepted variants). For example,
if the source data has dates in C<YYYY-MM-DD> format, we can write
a function to append a default time to produce an ISO-formatted
result:

    Set( %TicketsImportFieldMapping,
        'id'               => 'Ticket No',
        'Owner'            => 'Assigned To',
        'Status'           => 'Status',
        'Subject'          => 'Title',
        'Queue'            => \'General',
        'CF.Delivery Date' => sub { return $_[0]->{ 'Delivery Date' } . ' 00:00:00'; },
    );

If you have other date columns you'd like to default to the date/time
the import was run, Perl can help out there, too:

    use POSIX qw(strftime);
    Set( %TicketsImportFieldMapping,
        'id'               => 'Ticket No',
        'Owner'            => 'Assigned To',
        'Status'           => 'Status',
        'Subject'          => 'Title',
        'Queue'            => \'General',
        'CF.Project Start' => sub { return strftime "%Y-%m-%d %H:%M:%S", localtime; }
    );

=head2 Mandatory fields

To mark some ticket fields mandatory:

    Set( @TicketMandatoryFields, 'CF.Severity' );

In this example, rows without a value for "CF.Severity" values will be
skipped.

=head2 Extra Options for Text::CSV_XS

By default, the importer is configured for a most common variety of text
files (comma-delimited, fields in double quotes). The underlying import
module (L<Text::CSV_XS>) has many options to handle a wide array of file
options, including unquoted fields, tab-delimited, byte order marking,
etc. To pass custom options to the parser, use the following config:

    Set( %CSVOptions, (
        binary      => 1,
        sep_char    => ';',
        quote_char  => '`',
        escape_char => '`',
    ) );

Available options are described in the documentation for L<Text::CSV_XS|Text::CSV_XS/"new">.

=head2 Special Columns

=over

=item Roles and Custom Roles

For RT's built-in roles (Owner, Cc, AdminCc, Requestor) and any custom
roles, the import will first assume the value provided is a user name,
and will attempt to look up a user with that name, followed by email
address. Failing that, the importer will try to create a privileged
user with the provided name.

Should a user exist with the name provided and the target RT has external
auth configured, the import will attempt to update the user with the
latest information from the auth provider.

=item Comment or Correspond

To add a comment or correspond (reply) to a ticket, you can map a CSV column
to "Comment" or "Correspond". When creating a ticket (--insert) you can use
either one and the content will be added to the Create transaction.

For more information, see the section for L<importing transations|/"IMPORTING TRANSACTIONS">.

=back

=head2 TicketsImportTicketIdField

If the CSV data contains the ids of existing RT tickets, you can set this option
to the name of the column containing the RT ticket id. The importer will then
search for that ticket id and update the ticket data with CSV values.

    Set($TicketsImportTicketIdField, 'RT ticket id');

Only one of TicketsImportTicketIdField or @TicketsImportUniqueCFs can be used
for a given CSV file. Also, this option is only valid for --update or --insert-update
modes. You cannot specify the ticket id to be created in --insert mode.

=head2 TicketTolerantRoles

By default, if a user can't be loaded for a role, like Owner, the importer
will log it and skip creating the ticket. For roles that do not require a
successfully loaded user, set this option with the role name. The importer
will then log the failed attempt to find the user, but still create the
ticket.

    Set(@TicketTolerantRoles, 'CR.Customer');

=head1 IMPORTING TRANSACTIONS

The importer can be used to import transactions for existing tickets.
This is useful for bringing the entire ticket history into RT instead
of just the most current ticket data.

=head2 TransactionsImportFieldMapping

Set the column mappings for importing transactions from a CSV file. A 'TicketID' mapping
is required for RT to add the transaction to an existing ticket. The 'TicketID' value is
mapped to the custom field 'Original Ticket ID'.

Attachments can be included by providing the file system path for an attachment.

    Set( %TransactionsImportFieldMapping,
        'Attachment'     => 'Attachment',
        'TicketID'       => 'SomeID',
        'Created'        => 'Date',
        'Type'           => 'Type',
        'Content'        => 'Content',
        'AttachmentType' => 'FileType'
    );

=head1 ADVANCED OPTIONS

=head2 Operations before Create or Update

The importer provides a callback to run operations before a ticket has been
created or updated from CSV content. To run some code before an update, add
the following to your CSV configuration file:

    Set($PreTicketChangeCallback,
        sub {
            my %args = (
                TicketObj   => undef,
                Row         => undef,
                Type        => undef,
                CurrentUser => undef,
                @_,
            );
            return 1;    # to continue processing current row
        }
    );

As shown, you receive the ticket object(only for "Update" type), the current
CSV row, and the type of update, "Create" or "Update". CurrentUser is also
passed as it may be needed to call other methods. You can run any code in
the callback.

The Row argument is a reference to a hash with the values from the CSV
file. The keys are the columns from the file and match the CSV
import configuration. The values are for the row currently being
processed.

Since the Row argument is a reference, you can modify the value
before it is processed. For example, to lower case incoming status
values, you could do this:

    if ( exists $args{'Row'}->{status} ) {
        $args{'Row'}->{status} = lc($args{'Row'}->{status});
    }

If you return a false value, the change for that row is skipped, e.g.

    return ( 0, "Obsolete data" );

Return a true value to process that row normally.

    return 1;

=head2 Operations after Create or Update

The importer provides a callback to run operations after a ticket has been
created or updated from CSV content. To run some code after an update, add
the following to your CSV configuration file:

    Set($PostTicketChangeCallback,
        sub {
            my %args = (
                TicketObj   => undef,
                Row         => undef,
                Type        => undef,
                CurrentUser => undef,
                @_,
            );
        }
    );

As shown, you receive the ticket object, the current CSV row,
and the type of update, "Create" or "Update". CurrentUser is also passed
as it may be needed to call other methods. You can run any code
in the callback. It expects no return value.

=head1 RUNNING THE IMPORT WITH A NON-DEFAULT CONFIGURATION

You can explicitly pass a configuration file to the importer. This is
often used in conjunction when specifying an import type other than
ticket. Use the C<--config> option to specify the path and filename
to the configuration file to use; C<--type> indicates the type of
import to run (article, ticket, transation, or article):

    rt-extension-csv-importer --config /path/to/config.pm --type user /path/to/user-data.csv
    rt-extension-csv-importer --config /path/to/config.pm --type ticket /path/to/ticket-data.csv
    rt-extension-csv-importer --config /path/to/config.pm --type ticket --update /path/to/ticket-data.csv
    rt-extension-csv-importer --config /path/to/config.pm --type transaction /path/to/transaction-data.csv
    rt-extension-csv-importer --config /path/to/config.pm --type article --article-class 'VM-Assessment' /path/to/article-data.csv

=head1 EXAMPLES

=head2 Import an Excel file

Create a file in Excel, choose B<File / Save as> from the menu, and select
C<CSV UTF-8 (Comma delimited) (.csv)> from the B<File Format> dropdown. Save
it to a file named F<my-excel-test.csv>. Do not change any additional
options.

Create a new file called F<ExcelImport.pm> with the following:

    Set($TicketsImportTicketIdField, 'Ticket No');

    # RT fields -> Excel columns
    Set( %TicketsImportFieldMapping,
        'id'      => 'Ticket No',
        'Owner'   => 'Assigned To',
        'Status'  => 'Status',
        'Subject' => 'Title',
        'Queue'   => \'General',
    );

    # Default Excel export options
    Set( %CSVOptions, (
        binary      => 1,
        sep_char    => ',',
        quote_char  => '',
        escape_char => '',
    ) );

Then run the import:

    /opt/rt5/local/plugins/RT-Extension-Import-CSV/bin/rt-extension-import-csv \
        --type ticket \
        --config ExcelImport.pm \
        --insert-update \
        my-excel-test.csv

=head2 Import a tab-separated value (TSV) file

To generate a sample TSV file, select B<Search / Tickets / New Search> from
your RT menu. Pick some criteria, and don't change the default display
format or column selections. Click B<Add these terms and search>. On the
resulting search result page, select the B<Feeds / Spreadsheet> option.

The following configuration (saved as F<TabImport.pm>) should match the
resulting TSV file:

    Set($TicketsImportTicketIdField, 'id');

    Set( %TicketsImportFieldMapping,
        'Queue' => \'General',
    );

    Set( %CSVOptions, (
        binary      => 1,
        sep_char    => "\t",
        quote_char  => '',
        escape_char => '',
    ) );

The double-quotes match the interpolated tab value, rather than a literal
C<\t>. Other columns automatically align with fields in RT, so no
additional mapping is required.

Importing is similar to the previous example:

    /opt/rt5/local/plugins/RT-Extension-Import-CSV/bin/rt-extension-import-csv \
        --type ticket \
        --config TabImport.pm \
        --insert-update \
        Results.tsv

=head2 Import users from another system

An example application exports users to the following file (F<users.csv>):

    Login,Name,Email,Where At
    support_user,Generic Support User,support_user@example.com,Call Center
    admin_user,Generic Admin User,admin_user@example.com,HQ
    end_user,Generic End User,end_user@example.com,Production Floor

If you wanted to import those users into RT, create a new file called
F<UserImport.pm> containing the following:

    Set( %UsersImportFieldMapping,
        'Name'            => 'Login',
        'RealName'        => 'Name',
        'EmailAddress'    => 'Email',
        'UserCF.Location' => 'Where At',
    );

    Set( %CSVOptions, (
        binary      => 1,
        sep_char    => ',',
        quote_char  => '',
        escape_char => '',
    ) );

(this assumes you have created a User Custom Field named Location)

Then run the following:

    /opt/rt5/local/plugins/RT-Extension-Import-CSV/bin/rt-extension-import-csv \
        --type user \
        --config UserImport.pm \
        --insert \
        users.csv

=head2 Importing articles

An example knowledge management system contains articles your organization
would like to include on RT tickets. The export is delivered as such:

    Title,Synopsis,Content
    "Reset Password,"How to Reset a Password","This article explains how to reset a password in detail"
    "Create User","How to Create a New User","Instructions on how to create a new user, in excruciating detail"

Since there are commas in the content, fields in this CSV need to be
quoted, so this needs to be accounted for in the import configuration.
Create F<ArticleImport.pm> with the following:

    Set( %ArticlesImportFieldMapping,
        'Name'    => 'Title',
        'Summary' => 'Synopsis',
        'Content' => 'Content',
    );

    Set( %CSVOptions, (
        binary      => 1,
        sep_char    => ',',
        quote_char  => '"',
        escape_char => '',
    ) );

You need to add C<--article-class> when running the import:

    /opt/rt5/local/plugins/RT-Extension-Import-CSV/bin/rt-extension-import-csv \
        --type article \
        --article-class General \
        --config ArticleImport.pm \
        --insert \
        articles.csv

=head2 Putting it all together: migrating from Zendesk

It's possible to migrate from Zendesk to Request Tracker using multiple
imports defined above. Starting with a Zendesk trial site as a basis, the
following steps are necessary before a migration can begin:

=over

=item Users must be exported via API

Unfortunately, Zendesk only provides an export for what RT considers to
be privileged users. To get all users, you'll need to access Zendesk's
API. See L<this forum post|https://support.zendesk.com/hc/en-us/articles/4408882924570/comments/6460643115162> for more information.

=item Tickets must be exported to CSV

Any of the default lists of tickets in Zendesk can be exported to CSV.
See the Zendesk documentation for more information.

=back

Exporting user information via the Zendesk API includes a bunch of
unnecessary values. For this import, the only columns that matter are
C<name> and C<email>.

Create a new file called F<ZendeskUsers.pm>:

    Set( %UsersImportFieldMapping,
        'Name'            => 'name',
        'RealName'        => 'name',
        'EmailAddress'    => 'email',
    );

    Set( %CSVOptions, (
       sep_char    => ',',
       quote_char  => '"',
       escape_char => '',
    ) );

Assuming the user export above produced a file named F<zendesk_users.csv>,
run the import:

    /opt/rt5/local/plugins/RT-Extension-Import-CSV/bin/rt-extension-import-csv \
        --type user \
        --config ZendeskUsers.pm \
        --insert \
        zendesk_users.csv

For tickets, create F<ZendeskTickets.pm> using the following
configuration:

    Set($TicketsImportTicketIdField, 'ID');

    Set( %TicketsImportFieldMapping,
        'Queue'          => \'General',
        'Status'         => 'Status',
        'Subject'        => 'Subject',
        'Requestor'      => 'Requester',
        'Created'        => 'Requested',
        'LastUpdated'    => 'Updated',
        'CF.Ticket Type' => 'Topic',
        'CF.Channel'     => 'Channel',
    );

    Set( %CSVOptions, (
       sep_char    => ',',
       quote_char  => '"',
       escape_char => '',
    ) );

(you'll need to create two ticket custom fields: Ticket Type and Channel)

If tickets were exported to a file named F<zendesk_tickets.csv>, the
following command will import tickets into your RT instance:

    /opt/rt5/local/plugins/RT-Extension-Import-CSV/bin/rt-extension-import-csv \
        --type ticket \
        --config ZendeskTickets.pm \
        --insert-update \
        zendesk_tickets.csv

For a production instance of Zendesk, you'll need to adjust the columns
in the ticket import configuration to match your configuration.

=head1 AUTHOR

Best Practical Solutions, LLC E<lt>modules@bestpractical.comE<gt>

=for html <p>All bugs should be reported via email to <a
href="mailto:bug-RT-Extension-Import-CSV@rt.cpan.org">bug-RT-Extension-Import-CSV@rt.cpan.org</a>
or via the web at <a
href="http://rt.cpan.org/Public/Dist/Display.html?Name=RT-Extension-Import-CSV">rt.cpan.org</a>.</p>

=for text
    All bugs should be reported via email to
        bug-RT-Extension-Import-CSV@rt.cpan.org
    or via the web at
        http://rt.cpan.org/Public/Dist/Display.html?Name=RT-Extension-Import-CSV

=head1 LICENSE AND COPYRIGHT

This software is Copyright (c) 2024 by Best Practical LLC

This is free software, licensed under:

  The GNU General Public License, Version 2, June 1991

=cut

1;
