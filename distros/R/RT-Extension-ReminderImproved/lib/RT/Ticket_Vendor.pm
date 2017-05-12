use strict;
use warnings;
no warnings qw(redefine);

package RT::Ticket;

our %LINKTYPEMAP = (
    MemberOf => { Type => 'MemberOf',
                  Mode => 'Target', },
    Parents => { Type => 'MemberOf',
         Mode => 'Target', },
    Members => { Type => 'MemberOf',
                 Mode => 'Base', },
    Children => { Type => 'MemberOf',
          Mode => 'Base', },
    HasMember => { Type => 'MemberOf',
                   Mode => 'Base', },
    RefersTo => { Type => 'RefersTo',
                  Mode => 'Target', },
    ReferredToBy => { Type => 'RefersTo',
                      Mode => 'Base', },
    DependsOn => { Type => 'DependsOn',
                   Mode => 'Target', },
    DependedOnBy => { Type => 'DependsOn',
                      Mode => 'Base', },
    MergedInto => { Type => 'MergedInto',
                   Mode => 'Target', },

);

our %LINKDIRMAP = (
    MemberOf => { Base => 'MemberOf',
                  Target => 'HasMember', },
    RefersTo => { Base => 'RefersTo',
                Target => 'ReferredToBy', },
    DependsOn => { Base => 'DependsOn',
                   Target => 'DependedOnBy', },
    MergedInto => { Base => 'MergedInto',
                   Target => 'MergedInto', },

);

sub Create {
    my $self = shift;

    my %args = (
        id                 => undef,
        EffectiveId        => undef,
        Queue              => undef,
        Requestor          => undef,
        Cc                 => undef,
        AdminCc            => undef,
        SquelchMailTo      => undef,
        Type               => 'ticket',
        Owner              => undef,
        Subject            => '',
        InitialPriority    => undef,
        FinalPriority      => undef,
        Priority           => undef,
        Status             => 'new',
        TimeWorked         => "0",
        TimeLeft           => 0,
        TimeEstimated      => 0,
        Due                => undef,
        Starts             => undef,
        Started            => undef,
        Resolved           => undef,
        MIMEObj            => undef,
        _RecordTransaction => 1,
        DryRun             => 0,
        @_
    );

    my ($ErrStr, @non_fatal_errors);

    my $QueueObj = RT::Queue->new( $RT::SystemUser );
    if ( ref $args{'Queue'} eq 'RT::Queue' ) {
        $QueueObj->Load( $args{'Queue'}->Id );
    }
    elsif ( $args{'Queue'} ) {
        $QueueObj->Load( $args{'Queue'} );
    }
    else {
        $RT::Logger->debug("'". ( $args{'Queue'} ||''). "' not a recognised queue object." );
    }

    #Can't create a ticket without a queue.
    unless ( $QueueObj->Id ) {
        $RT::Logger->debug("$self No queue given for ticket creation.");
        return ( 0, 0, $self->loc('Could not create ticket. Queue not set') );
    }


    #Now that we have a queue, Check the ACLS
    unless (
        $self->CurrentUser->HasRight(
            Right  => 'CreateTicket',
            Object => $QueueObj
        )
      )
    {
        return (
            0, 0,
            $self->loc( "No permission to create tickets in the queue '[_1]'", $QueueObj->Name));
    }

    unless ( $QueueObj->IsValidStatus( $args{'Status'} ) ) {
        return ( 0, 0, $self->loc('Invalid value for status') );
    }

    #Since we have a queue, we can set queue defaults

    #Initial Priority
    # If there's no queue default initial priority and it's not set, set it to 0
    $args{'InitialPriority'} = $QueueObj->InitialPriority || 0
        unless defined $args{'InitialPriority'};

    #Final priority
    # If there's no queue default final priority and it's not set, set it to 0
    $args{'FinalPriority'} = $QueueObj->FinalPriority || 0
        unless defined $args{'FinalPriority'};

    # Priority may have changed from InitialPriority, for the case
    # where we're importing tickets (eg, from an older RT version.)
    $args{'Priority'} = $args{'InitialPriority'}
        unless defined $args{'Priority'};

    # {{{ Dates
    #TODO we should see what sort of due date we're getting, rather +
    # than assuming it's in ISO format.

    #Set the due date. if we didn't get fed one, use the queue default due in
    my $Due = new RT::Date( $self->CurrentUser );
    if ( defined $args{'Due'} ) {
        $Due->Set( Format => 'ISO', Value => $args{'Due'} );
    }
    elsif ( my $due_in = $QueueObj->DefaultDueIn ) {
        $Due->SetToNow;
        $Due->AddDays( $due_in );
    }

    my $Starts = new RT::Date( $self->CurrentUser );
    if ( defined $args{'Starts'} ) {
        $Starts->Set( Format => 'ISO', Value => $args{'Starts'} );
    }

    my $Started = new RT::Date( $self->CurrentUser );
    if ( defined $args{'Started'} ) {
        $Started->Set( Format => 'ISO', Value => $args{'Started'} );
    }
    elsif ( $args{'Status'} ne 'new' ) {
        $Started->SetToNow;
    }

    my $Resolved = new RT::Date( $self->CurrentUser );
    if ( defined $args{'Resolved'} ) {
        $Resolved->Set( Format => 'ISO', Value => $args{'Resolved'} );
    }

    #If the status is an inactive status, set the resolved date
    elsif ( $QueueObj->IsInactiveStatus( $args{'Status'} ) )
    {
        $RT::Logger->debug( "Got a ". $args{'Status'}
            ."(inactive) ticket with undefined resolved date. Setting to now."
        );
        $Resolved->SetToNow;
    }

    # }}}

    # {{{ Dealing with time fields

    $args{'TimeEstimated'} = 0 unless defined $args{'TimeEstimated'};
    $args{'TimeWorked'}    = 0 unless defined $args{'TimeWorked'};
    $args{'TimeLeft'}      = 0 unless defined $args{'TimeLeft'};

    # }}}

    # {{{ Deal with setting the owner

    my $Owner;
    if ( ref( $args{'Owner'} ) eq 'RT::User' ) {
        if ( $args{'Owner'}->id ) {
            $Owner = $args{'Owner'};
        } else {
            $RT::Logger->error('passed not loaded owner object');
            push @non_fatal_errors, $self->loc("Invalid owner object");
            $Owner = undef;
        }
    }

    #If we've been handed something else, try to load the user.
    elsif ( $args{'Owner'} ) {
        $Owner = RT::User->new( $self->CurrentUser );
        $Owner->Load( $args{'Owner'} );
        $Owner->LoadByEmail( $args{'Owner'} )
            unless $Owner->Id;
        unless ( $Owner->Id ) {
            push @non_fatal_errors,
                $self->loc("Owner could not be set.") . " "
              . $self->loc( "User '[_1]' could not be found.", $args{'Owner'} );
            $Owner = undef;
        }
    }

    #If we have a proposed owner and they don't have the right
    #to own a ticket, scream about it and make them not the owner
   
    my $DeferOwner;  
    if ( $Owner && $Owner->Id != $RT::Nobody->Id 
        && !$Owner->HasRight( Object => $QueueObj, Right  => 'OwnTicket' ) )
    {
        $DeferOwner = $Owner;
        $Owner = undef;
        $RT::Logger->debug('going to deffer setting owner');

    }

    #If we haven't been handed a valid owner, make it nobody.
    unless ( defined($Owner) && $Owner->Id ) {
        $Owner = new RT::User( $self->CurrentUser );
        $Owner->Load( $RT::Nobody->Id );
    }

    # }}}

# We attempt to load or create each of the people who might have a role for this ticket
# _outside_ the transaction, so we don't get into ticket creation races
    foreach my $type ( "Cc", "AdminCc", "Requestor" ) {
        $args{ $type } = [ $args{ $type } ] unless ref $args{ $type };
        foreach my $watcher ( splice @{ $args{$type} } ) {
            next unless $watcher;
            if ( $watcher =~ /^\d+$/ ) {
                push @{ $args{$type} }, $watcher;
            } else {
                my @addresses = RT::EmailParser->ParseEmailAddress( $watcher );
                foreach my $address( @addresses ) {
                    my $user = RT::User->new( $RT::SystemUser );
                    my ($uid, $msg) = $user->LoadOrCreateByEmail( $address );
                    unless ( $uid ) {
                        push @non_fatal_errors,
                            $self->loc("Couldn't load or create user: [_1]", $msg);
                    } else {
                        push @{ $args{$type} }, $user->id;
                    }
                }
            }
        }
    }

    $RT::Handle->BeginTransaction();

    my %params = (
        Queue           => $QueueObj->Id,
        Owner           => $Owner->Id,
        Subject         => $args{'Subject'},
        InitialPriority => $args{'InitialPriority'},
        FinalPriority   => $args{'FinalPriority'},
        Priority        => $args{'Priority'},
        Status          => $args{'Status'},
        TimeWorked      => $args{'TimeWorked'},
        TimeEstimated   => $args{'TimeEstimated'},
        TimeLeft        => $args{'TimeLeft'},
        Type            => $args{'Type'},
        Starts          => $Starts->ISO,
        Started         => $Started->ISO,
        Resolved        => $Resolved->ISO,
        Due             => $Due->ISO
    );

# Parameters passed in during an import that we probably don't want to touch, otherwise
    foreach my $attr qw(id Creator Created LastUpdated LastUpdatedBy) {
        $params{$attr} = $args{$attr} if $args{$attr};
    }

    # Delete null integer parameters
    foreach my $attr
        qw(TimeWorked TimeLeft TimeEstimated InitialPriority FinalPriority)
    {
        delete $params{$attr}
          unless ( exists $params{$attr} && $params{$attr} );
    }

    # Delete the time worked if we're counting it in the transaction
    delete $params{'TimeWorked'} if $args{'_RecordTransaction'};

    my ($id,$ticket_message) = $self->SUPER::Create( %params );
    unless ($id) {
        $RT::Logger->crit( "Couldn't create a ticket: " . $ticket_message );
        $RT::Handle->Rollback();
        return ( 0, 0,
            $self->loc("Ticket could not be created due to an internal error")
        );
    }

    #Set the ticket's effective ID now that we've created it.
    my ( $val, $msg ) = $self->__Set(
        Field => 'EffectiveId',
        Value => ( $args{'EffectiveId'} || $id )
    );
    unless ( $val ) {
        $RT::Logger->crit("Couldn't set EffectiveId: $msg");
        $RT::Handle->Rollback;
        return ( 0, 0,
            $self->loc("Ticket could not be created due to an internal error")
        );
    }

    my $create_groups_ret = $self->_CreateTicketGroups();
    unless ($create_groups_ret) {
        $RT::Logger->crit( "Couldn't create ticket groups for ticket "
              . $self->Id
              . ". aborting Ticket creation." );
        $RT::Handle->Rollback();
        return ( 0, 0,
            $self->loc("Ticket could not be created due to an internal error")
        );
    }

    # Set the owner in the Groups table
    # We denormalize it into the Ticket table too because doing otherwise would
    # kill performance, bigtime. It gets kept in lockstep thanks to the magic of transactionalization
    $self->OwnerGroup->_AddMember(
        PrincipalId       => $Owner->PrincipalId,
        InsideTransaction => 1
    ) unless $DeferOwner;



    # {{{ Deal with setting up watchers

    foreach my $type ( "Cc", "AdminCc", "Requestor" ) {
        # we know it's an array ref
        foreach my $watcher ( @{ $args{$type} } ) {

            # Note that we're using AddWatcher, rather than _AddWatcher, as we
            # actually _want_ that ACL check. Otherwise, random ticket creators
            # could make themselves adminccs and maybe get ticket rights. that would
            # be poor
            my $method = $type eq 'AdminCc'? 'AddWatcher': '_AddWatcher';

            my ($val, $msg) = $self->$method(
                Type   => $type,
                PrincipalId => $watcher,
                Silent => 1,
            );
            push @non_fatal_errors, $self->loc("Couldn't set [_1] watcher: [_2]", $type, $msg)
                unless $val;
        }
    } 

    if ($args{'SquelchMailTo'}) {
       my @squelch = ref( $args{'SquelchMailTo'} ) ? @{ $args{'SquelchMailTo'} }
        : $args{'SquelchMailTo'};
        $self->_SquelchMailTo( @squelch );
    }


    # }}}

    # {{{ Add all the custom fields

    foreach my $arg ( keys %args ) {
        next unless $arg =~ /^CustomField-(\d+)$/i;
        my $cfid = $1;

        foreach my $value (
            UNIVERSAL::isa( $args{$arg} => 'ARRAY' ) ? @{ $args{$arg} } : ( $args{$arg} ) )
        {
            next unless defined $value && length $value;

            # Allow passing in uploaded LargeContent etc by hash reference
            my ($status, $msg) = $self->_AddCustomFieldValue(
                (UNIVERSAL::isa( $value => 'HASH' )
                    ? %$value
                    : (Value => $value)
                ),
                Field             => $cfid,
                RecordTransaction => 0,
            );
            push @non_fatal_errors, $msg unless $status;
        }
    }

    # }}}

    # {{{ Deal with setting up links

    # TODO: Adding link may fire scrips on other end and those scrips
    # could create transactions on this ticket before 'Create' transaction.
    #
    # We should implement different schema: record 'Create' transaction,
    # create links and only then fire create transaction's scrips.
    #
    # Ideal variant: add all links without firing scrips, record create
    # transaction and only then fire scrips on the other ends of links.
    #
    # //RUZ

    foreach my $type ( keys %LINKTYPEMAP ) {
        next unless ( defined $args{$type} );
        foreach my $link (
            ref( $args{$type} ) ? @{ $args{$type} } : ( $args{$type} ) )
        {
            # Check rights on the other end of the link if we must
            # then run _AddLink that doesn't check for ACLs
            if ( RT->Config->Get( 'StrictLinkACL' ) ) {
                my ($val, $msg, $obj) = $self->__GetTicketFromURI( URI => $link );
                unless ( $val ) {
                    push @non_fatal_errors, $msg;
                    next;
                }
                if ( $obj && !$obj->CurrentUserHasRight('ModifyTicket') ) {
                    push @non_fatal_errors, $self->loc('Linking. Permission denied');
                    next;
                }
            }
            
            my ( $wval, $wmsg ) = $self->_AddLink(
                Type                          => $LINKTYPEMAP{$type}->{'Type'},
                $LINKTYPEMAP{$type}->{'Mode'} => $link,
                Silent                        => !$args{'_RecordTransaction'} || $self->Type eq 'reminder',
                'Silent'. ( $LINKTYPEMAP{$type}->{'Mode'} eq 'Base'? 'Target': 'Base' )
                                              => 1,
            );

            push @non_fatal_errors, $wmsg unless ($wval);
        }
    }

    # }}}
    # Now that we've created the ticket and set up its metadata, we can actually go and check OwnTicket on the ticket itself. 
    # This might be different than before in cases where extensions like RTIR are doing clever things with RT's ACL system
    if (  $DeferOwner ) { 
            if (!$DeferOwner->HasRight( Object => $self, Right  => 'OwnTicket')) {
    
            $RT::Logger->warning( "User " . $DeferOwner->Name . "(" . $DeferOwner->id 
                . ") was proposed as a ticket owner but has no rights to own "
                . "tickets in " . $QueueObj->Name );
            push @non_fatal_errors, $self->loc(
                "Owner '[_1]' does not have rights to own this ticket.",
                $DeferOwner->Name
            );
        } else {
            $Owner = $DeferOwner;
            $self->__Set(Field => 'Owner', Value => $Owner->id);

        }
        $self->OwnerGroup->_AddMember(
            PrincipalId       => $Owner->PrincipalId,
            InsideTransaction => 1
        );
    }

    if ( $args{'_RecordTransaction'} ) {

        # {{{ Add a transaction for the create
        my ( $Trans, $Msg, $TransObj ) = $self->_NewTransaction(
            Type         => "Create",
            TimeTaken    => $args{'TimeWorked'},
            MIMEObj      => $args{'MIMEObj'},
            CommitScrips => !$args{'DryRun'},
        );

        if ( $self->Id && $Trans ) {

            $TransObj->UpdateCustomFields(ARGSRef => \%args);

            $RT::Logger->info( "Ticket " . $self->Id . " created in queue '" . $QueueObj->Name . "' by " . $self->CurrentUser->Name );
            $ErrStr = $self->loc( "Ticket [_1] created in queue '[_2]'", $self->Id, $QueueObj->Name );
            $ErrStr = join( "\n", $ErrStr, @non_fatal_errors );
        }
        else {
            $RT::Handle->Rollback();

            $ErrStr = join( "\n", $ErrStr, @non_fatal_errors );
            $RT::Logger->error("Ticket couldn't be created: $ErrStr");
            return ( 0, 0, $self->loc( "Ticket could not be created due to an internal error"));
        }

        if ( $args{'DryRun'} ) {
            $RT::Handle->Rollback();
            return ($self->id, $TransObj, $ErrStr);
        }
        $RT::Handle->Commit();
        return ( $self->Id, $TransObj->Id, $ErrStr );

        # }}}
    }
    else {

        # Not going to record a transaction
        $RT::Handle->Commit();
        $ErrStr = $self->loc( "Ticket [_1] created in queue '[_2]'", $self->Id, $QueueObj->Name );
        $ErrStr = join( "\n", $ErrStr, @non_fatal_errors );
        return ( $self->Id, 0, $ErrStr );

    }
}

1;
