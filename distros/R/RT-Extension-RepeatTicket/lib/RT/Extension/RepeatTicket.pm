use warnings;
use strict;

package RT::Extension::RepeatTicket;

our $VERSION = "2.00";

use RT::Interface::Web;
use DateTime;
use RT::Date;
use List::MoreUtils qw/after/;
use DateTime::Event::ICal;

RT->AddStyleSheets('repeat-ticket.css')
    if $RT::StaticPath;

my $old_create_ticket = \&HTML::Mason::Commands::CreateTicket;
{
    no warnings 'redefine';

    *HTML::Mason::Commands::CreateTicket = sub {
        my %args = @_;
        my ( $ticket, @actions ) = $old_create_ticket->(@_);
        if ( $ticket && $args{'repeat-enabled'} ) {
            my ($attr, $message) = SetRepeatAttribute(
                $ticket,
                'tickets'     => [ $ticket->id ],
                'last-ticket' => $ticket->id,
                map { $_ => $args{$_} } grep { /^repeat/ } keys %args
            );
            if ( $attr ) {
                Run($attr);
            }
            else {
                push @actions, $message;
            }
        }
        return ( $ticket, @actions );
    };
}

sub SetRepeatAttribute {
    my $ticket = shift;
    return 0 unless $ticket;
    my %args        = @_;
    my %repeat_args = (
        'repeat-enabled'              => undef,
        'repeat-details-weekly-weeks' => undef,
        %args
    );

    # Drop unrelated params from inline edit, UpdateContent is from core,
    # SubmitRecurrence is the submit button.
    delete $repeat_args{$_} for qw/UpdateContent SubmitRecurrence/;

    my ($valid, $message) = ValidateArgs(\%repeat_args);

    if ( not $valid ){
        $message = "Recurrence not updated: " . $message;
        return (undef, $message);
    }

    my ($old_attr) = $ticket->Attributes->Named('RepeatTicketSettings');
    my %old;
    %old = %{ $old_attr->Content } if $old_attr;

    my $content = { %old, %repeat_args };

    $ticket->SetAttribute(
        Name    => 'RepeatTicketSettings',
        Content => $content,
    );

    ProcessTransactions($ticket, \%old, \%repeat_args) if $old_attr;
    if ( $content->{'repeat-enabled'} ) {
        $ticket->AddCustomFieldValue(
            Field => 'Original Ticket',
            Value => $ticket->id,
        );
    }
    else {
        $ticket->DeleteCustomFieldValue(
            Field => 'Original Ticket',
            Value => $ticket->id,
        );
    }

    my ($attr) = $ticket->Attributes->Named('RepeatTicketSettings');

    return ( $attr, $ticket->loc('Recurrence updated') );    # loc
}

sub ProcessTransactions {
    my $ticket = shift;
    my $old_ref = shift;
    my $new_ref = shift;

    foreach my $key (keys %$old_ref){

        # Keys should be the same since they are coming
        # from the same form, but just in case.
        next unless exists $new_ref->{$key};

        {
        # We know some values will be uninitialized
        no warnings 'uninitialized';

        # temp values to avoid changing the source hashes
        my $old = $old_ref->{$key};
        my $new = $new_ref->{$key};

        $old = join ',', @$old if ref $old eq 'ARRAY';
        $new = join ',', @$new if ref $new eq 'ARRAY';

        if ( $old ne $new ){

            # Add a transaction
            my ( $Trans, $Msg, $TransObj ) = $ticket->_NewTransaction(
               Type         => "Set",
               Field        => $key,
               OldValue     => $old,
               NewValue     => $new,
               CommitScrips => 0,
               ActivateScrips => 0,
            );
        }
        }
    }
    return;
}

sub ValidateArgs {
    my $args_ref = shift;
    my $result = 1;
    my $message;

    # If recur every X weeks is selected, a weekday is required
    if ( $args_ref->{'repeat-type'} eq 'weekly'
         and $args_ref->{'repeat-details-weekly-week'} ){

        my $weeks = $args_ref->{'repeat-details-weekly-weeks'};
        unless ( defined $weeks ) {
            $message .= 'No weekday selected for weekly recurrence';
            $result = 0;
        }
    }

    return ( $result, $message );
}

use RT::Ticket;

sub Run {
    my $attr    = shift;
    my $content = $attr->Content;
    return unless $content->{'repeat-enabled'};

    my $checkday = shift
      || DateTime->today( time_zone => RT->Config->Get('Timezone') );
    my @ids = Repeat( $attr, $checkday );
    push @ids,
      MaybeRepeatMore($attr);    # create more to meet the coexistent number
    return @ids;
}

sub Repeat {
    my $attr      = shift;
    my @checkdays = @_;
    my @ids;

    my $content = $attr->Content;
    return unless $content->{'repeat-enabled'};

    my $repeat_ticket = $attr->Object;

    my $tickets_needed = TicketsToMeetCoexistentNumber($attr);
    return unless $tickets_needed;

    for my $checkday (@checkdays) {
        # Adjust by lead time
        my $original_date = $checkday->clone();
        $checkday = $checkday->add( days => $content->{'repeat-lead-time'} )
          if defined $content->{'repeat-lead-time'};
        $RT::Logger->debug( 'Checking date ' . $original_date ->ymd .
                            ' with adjusted lead time date ' . $checkday->ymd );

        if ( $content->{'repeat-start-date'} ) {
            my $date = RT::Date->new( RT->SystemUser );
            $date->Set(
                Format => 'unknown',
                Value  => $content->{'repeat-start-date'},
            );
            if ( $checkday->ymd le $date->Date ) {
                $RT::Logger->debug('Not yet at start date' . $date->Date);
                next;
            }
        }

        if ( $content->{'repeat-end'} && $content->{'repeat-end'} eq 'number' )
        {
            if ( $content->{'repeat-end-number'} <=
                $content->{'repeat-occurrences'} )
            {
                $RT::Logger->debug('Failed repeat-end-number check');
                last;
            }
        }

        if ( $content->{'repeat-end'} && $content->{'repeat-end'} eq 'date' ) {
            my $date = RT::Date->new( RT->SystemUser );
            $date->Set(
                Format => 'unknown',
                Value  => $content->{'repeat-end-date'},
            );

            if ( $original_date->ymd gt $date->Date ) {
                $RT::Logger->debug('Failed repeat-end-date check '
                  . 'running with date: ' . $original_date->ymd
                  . ' and end date: ' . $date->Date );
                next;
            }
        }

        my $last_ticket = RT::Ticket->new( RT->SystemUser );
        $last_ticket->Load( $content->{'last-ticket'} );

        my $last_due;
        if ( $last_ticket->DueObj->Unix ) {
            $last_due = DateTime->from_epoch(
                epoch     => $last_ticket->DueObj->Unix,
                time_zone => RT->Config->Get('Timezone'),
            );
            $last_due->truncate( to => 'day' );
        }

        my $last_created = DateTime->from_epoch(
            epoch     => $last_ticket->CreatedObj->Unix,
            time_zone => RT->Config->Get('Timezone'),
        );
        $last_created->truncate( to => 'day' );
        next unless $last_created->ymd lt $checkday->ymd;

        my $set;
        if ( $content->{'repeat-type'} eq 'daily' ) {
            if ( $content->{'repeat-details-daily'} eq 'day' ) {
                my $span = $content->{'repeat-details-daily-day'} || 1;
                $set = DateTime::Event::ICal->recur(
                    dtstart => $last_due || $last_created,
                    freq => 'daily',
                    interval => $span,
                );
                next unless $set->contains($checkday);
            }
            elsif ( $content->{'repeat-details-daily'} eq 'weekday' ) {
                $set = DateTime::Event::ICal->recur(
                    dtstart => $last_due || $last_created,
                    freq => 'daily',
                    byday => [ 'mo', 'tu', 'we', 'th', 'fr' ],
                );
                next unless $set->contains($checkday);
            }
            elsif ( $content->{'repeat-details-daily'} eq 'complete' ) {
                unless ( CheckCompleteStatus($last_ticket) ) {
                    $RT::Logger->debug('Failed complete status check');
                    last;
                }

                unless (
                    CheckCompleteDate(
                        $original_date, $last_ticket, 'day',
                        $content->{'repeat-details-daily-complete'}
                    )
                  )
                {
                    $RT::Logger->debug('Failed complete date check');
                    next;
                }
            }

        }
        elsif ( $content->{'repeat-type'} eq 'weekly' ) {
            if ( $content->{'repeat-details-weekly'} eq 'week' ) {
                my $span = $content->{'repeat-details-weekly-week'} || 1;
                my $date = $checkday->clone;

                my $weeks = $content->{'repeat-details-weekly-weeks'};
                unless ( defined $weeks ) {
                    $RT::Logger->debug('Failed weeks defined check');
                    next;
                }

                $weeks = [$weeks] unless ref $weeks;

                $set = DateTime::Event::ICal->recur(
                    dtstart => $last_due || $last_created,
                    freq => 'weekly',
                    interval => $span,
                    byday    => $weeks,
                );

                next unless $set->contains($checkday);

            }
            elsif ( $content->{'repeat-details-weekly'} eq 'complete' ) {
                unless ( CheckCompleteStatus($last_ticket) ) {
                    $RT::Logger->debug('Failed complete status check');
                    last;
                }

                unless (
                    CheckCompleteDate(
                        $original_date, $last_ticket, 'week',
                        $content->{'repeat-details-weekly-complete'}
                    )
                  )
                {
                    $RT::Logger->debug('Failed complete date check');
                    next;
                }
            }
        }
        elsif ( $content->{'repeat-type'} eq 'monthly' ) {
            if ( $content->{'repeat-details-monthly'} eq 'day' ) {
                my $day  = $content->{'repeat-details-monthly-day-day'}   || 1;
                my $span = $content->{'repeat-details-monthly-day-month'} || 1;

                $set = DateTime::Event::ICal->recur(
                    dtstart => $last_due || $last_created,
                    freq => 'monthly',
                    interval   => $span,
                    bymonthday => $day,
                );

                next unless $set->contains($checkday);
            }
            elsif ( $content->{'repeat-details-monthly'} eq 'week' ) {
                my $day = $content->{'repeat-details-monthly-week-week'}
                  || 'mo';
                my $span = $content->{'repeat-details-monthly-week-month'} || 1;
                my $number = $content->{'repeat-details-monthly-week-number'}
                  || 1;

                $set = DateTime::Event::ICal->recur(
                    dtstart => $last_due || $last_created,
                    freq => 'monthly',
                    interval => $span,
                    byday    => $number . $day,
                );

                next unless $set->contains($checkday);
            }
            elsif ( $content->{'repeat-details-monthly'} eq 'complete' ) {
                unless ( CheckCompleteStatus($last_ticket) ) {
                    $RT::Logger->debug('Failed complete status check');
                    last;
                }

                unless (
                    CheckCompleteDate(
                        $original_date, $last_ticket, 'month',
                        $content->{'repeat-details-monthly-complete'}
                    )
                  )
                {
                    $RT::Logger->debug('Failed complete date check');
                    next;
                }
            }
        }
        elsif ( $content->{'repeat-type'} eq 'yearly' ) {
            if ( $content->{'repeat-details-yearly'} eq 'day' ) {
                my $day   = $content->{'repeat-details-yearly-day-day'}   || 1;
                my $month = $content->{'repeat-details-yearly-day-month'} || 1;
                $set = DateTime::Event::ICal->recur(
                    dtstart => $last_due || $last_created,
                    freq    => 'yearly',
                    bymonth => $month,
                    bymonthday => $day,
                );

                next unless $set->contains($checkday);
            }
            elsif ( $content->{'repeat-details-yearly'} eq 'week' ) {
                my $month = $content->{'repeat-details-yearly-week-month'} || 1;
                my $day = $content->{'repeat-details-yearly-week-week'} || 'mo';
                my $number = $content->{'repeat-details-yearly-week-number'}
                  || 1;
                $set = DateTime::Event::ICal->recur(
                    dtstart => $last_due || $last_created,
                    freq    => 'yearly',
                    bymonth => $month,
                    byday   => $number . $day,
                );

                next unless $set->contains($checkday);
            }
            elsif ( $content->{'repeat-details-yearly'} eq 'complete' ) {
                unless ( CheckCompleteStatus($last_ticket) ) {
                    $RT::Logger->debug('Failed complete status check');
                    last;
                }

                unless (
                    CheckCompleteDate(
                        $original_date, $last_ticket, 'year',
                        $content->{'repeat-details-yearly-complete'}
                    )
                  )
                {
                    $RT::Logger->debug('Failed complete date check');
                    next;
                }
            }
        }

        # use RT::Date to work around the timezone issue
        my $starts = RT::Date->new( RT->SystemUser );
        $starts->Set( Format => 'unknown', Value => $original_date->ymd );

        my $due;
        if ($set) {
            $due = RT::Date->new( RT->SystemUser );
            $due->Set( Format => 'unknown', Value => $checkday );
        }

        my ( $id, $txn, $msg ) = _RepeatTicket(
            $repeat_ticket,
            Starts => $starts->ISO,
            $due
            ? ( Due => $due->ISO )
            : (),
        );

        if ($id) {
            $RT::Logger->info(
                "Repeated ticket " . $repeat_ticket->id . ": $id" );
            $content->{'repeat-occurrences'}++;
            $content->{'last-ticket'} = $id;
            push @{ $content->{'tickets'} }, $id;
            push @ids, $id;
        }
        else {
            $RT::Logger->error( "Failed to repeat ticket for "
                  . $repeat_ticket->id
                  . ": $msg" );
            next;
        }
    }

    $attr->SetContent($content);
    return @ids;
}

sub TicketsToMeetCoexistentNumber {
    my $attr    = shift;
    my $content = $attr->Content;

    my $co_number = $content->{'repeat-coexistent-number'};
    $co_number = RT->Config->Get('RepeatTicketCoexistentNumber')
      unless defined $co_number && length $co_number;  # respect 0 but ''
    return unless $co_number;

    my $tickets = GetActiveTickets($content) || 0;
    return $co_number - @$tickets;
}

sub GetActiveTickets {
    my $content = shift;

    my $tickets_ref = $content->{tickets} || [];
    @$tickets_ref = grep {
        my $t = RT::Ticket->new( RT->SystemUser );
        $t->Load($_);
        my $lifecycle = $t->QueueObj->can('LifecycleObj') ? $t->QueueObj->LifecycleObj : $t->QueueObj->Lifecycle;
        !$lifecycle->IsInactive( $t->Status );
    } @$tickets_ref;

    return $tickets_ref;
}

my $mason;
sub _RepeatTicket {
    my $repeat_ticket = shift;
    return unless $repeat_ticket;

    my %args = @_;
    my $cf   = RT::CustomField->new( RT->SystemUser );
    $cf->Load('Original Ticket');

    my $repeat = {
        Queue           => $repeat_ticket->Queue,
        Requestor       => join( ',', $repeat_ticket->RequestorAddresses ),
        Cc              => join( ',', $repeat_ticket->CcAddresses ),
        AdminCc         => join( ',', $repeat_ticket->AdminCcAddresses ),
        InitialPriority => $repeat_ticket->Priority,
        'CustomField-' . $cf->id => $repeat_ticket->id,
    };

    $repeat->{$_} = $repeat_ticket->$_()
      for qw/Owner FinalPriority TimeEstimated Subject/;

    my $members = $repeat_ticket->Members;
    my ( @members, @members_of, @refers, @refers_by, @depends, @depends_by );
    my $refers         = $repeat_ticket->RefersTo;
    my $get_link_value = sub {
        my ( $link, $type ) = @_;
        my $uri_method   = $type . 'URI';
        my $local_method = 'Local' . $type;
        my $uri          = $link->$uri_method;
        return
          if $uri->IsLocal
              and $uri->Object
              and $uri->Object->isa('RT::Ticket')
              and $uri->Object->Type eq 'reminder';

        return $link->$local_method || $uri->URI;
    };
    while ( my $refer = $refers->Next ) {
        my $refer_value = $get_link_value->( $refer, 'Target' );
        push @refers, $refer_value if defined $refer_value;
    }
    $repeat->{RefersTo} = $repeat->{'new-RefersTo'} = join ' ', @refers;

    my $refers_by = $repeat_ticket->ReferredToBy;
    while ( my $refer_by = $refers_by->Next ) {
        my $refer_by_value = $get_link_value->( $refer_by, 'Base' );
        push @refers_by, $refer_by_value if defined $refer_by_value;
    }
    $repeat->{ReferredToBy} = $repeat->{'RefersTo-new'} = join ' ', @refers_by;

    my $cfs = $repeat_ticket->QueueObj->TicketCustomFields();
    while ( my $cf = $cfs->Next ) {
        next if $cf->Name eq 'Original Ticket';
        my $cf_id     = $cf->id;
        my $cf_values = $repeat_ticket->CustomFieldValues( $cf->id );
        my @cf_values;
        while ( my $cf_value = $cf_values->Next ) {
            push @cf_values, $cf_value->Content;
        }
        $repeat->{"CustomField-$cf_id"} = \@cf_values;
    }

    $repeat->{Status} = 'new';

    for ( keys %$repeat ) {
        $args{$_} = $repeat->{$_} if not defined $args{$_};
    }

    my $txns = $repeat_ticket->Transactions;
    $txns->Limit( FIELD => 'Type', VALUE => 'Create' );
    $txns->OrderBy( FIELD => 'id', ORDER => 'ASC' );
    $txns->RowsPerPage(1);
    my $txn  = $txns->First;
    my $atts = RT::Attachments->new( RT->SystemUser );
    $atts->OrderBy( FIELD => 'id', ORDER => 'ASC' );
    $atts->Limit( FIELD => 'TransactionId', VALUE => $txn->id );
    $atts->Limit( FIELD => 'Parent',        VALUE => 0 );
    my $top = $atts->First;

    # XXX no idea why this doesn't work:
    # $args{MIMEObj} = $top->ContentAsMIME( Children => 1 ) );

    my $parser = RT::EmailParser->new( RT->SystemUser );
    $args{MIMEObj} =
      $parser->ParseMIMEEntityFromScalar(
        $top->ContentAsMIME( Children => 1 )->as_string );

    my $ticket = RT::Ticket->new( $repeat_ticket->CurrentUser );
    my ($new_id, $new_txn, $new_msg) = $ticket->Create(%args);

    if ($new_id){
        # Update subject if custom format defined
        my $subject_format = RT->Config->Get('RepeatTicketSubjectFormat');
        if ($subject_format) {
            # append original subject if the new one doesn't include it.
            if ( $subject_format !~ /__Subject__/ ) {
                $subject_format .= ' __Subject__';
            }

            my $subject = $subject_format;
            unless ( $mason ) {
                require File::Temp;
                require RT::Interface::Web::Handler;
                my $data_dir = File::Temp::tempdir(CLEANUP => 1);
                $mason = HTML::Mason::Interp->new(
                    RT::Interface::Web::Handler->DefaultHandlerArgs,
                    autohandler_name => '', # disable forced login and more
                    data_dir => $data_dir,
                );
                $mason->set_escape( h => \&RT::Interface::Web::EscapeUTF8 );
                $mason->set_escape( u => \&RT::Interface::Web::EscapeURI  );
            }
            $subject =~ s!__(.*?)__!$mason->exec(
                                                 "/Elements/ColumnMap",
                                                 Class => 'RT__Ticket',
                                                 Name  => $1,
                                                 Attr  => 'value'
                                                )->($ticket);!eg;
            $ticket->SetSubject($subject);
        }
    }

    return ($new_id, $new_txn, $new_msg);
}

sub MaybeRepeatMore {
    my $attr    = shift;
    my $content = $attr->Content;
    my $tickets_needed = TicketsToMeetCoexistentNumber($attr);

    my $last_ticket = RT::Ticket->new( RT->SystemUser );
    $last_ticket->Load( $content->{'last-ticket'} );

    my $last_due;
    if ( $last_ticket->DueObj->Unix ) {
        $last_due = DateTime->from_epoch(
            epoch     => $last_ticket->DueObj->Unix,
            time_zone => RT->Config->Get('Timezone'),
        );
        $last_due->truncate( to => 'day' );
    }

    my $last_created = DateTime->from_epoch(
        epoch     => $last_ticket->CreatedObj->Unix,
        time_zone => RT->Config->Get('Timezone'),
    );
    $last_created->truncate( to => 'day' );

    $content->{tickets} = GetActiveTickets($content);
    $attr->SetContent($content);

    my @ids;
    if ( $tickets_needed ) {
        my $set;
        if ( $content->{'repeat-type'} eq 'daily' ) {
            if ( $content->{'repeat-details-daily'} eq 'day' ) {
                $set = DateTime::Event::ICal->recur(
                    dtstart  => $last_due || $last_created,
                    freq     => 'daily',
                    interval => $content->{'repeat-details-daily-day'} || 1,
                );
            }
            elsif ( $content->{'repeat-details-daily'} eq 'weekday' ) {
                $set = DateTime::Event::ICal->recur(
                    dtstart  => $last_due || $last_created,
                    freq    => 'daily',
                    byday   => [ 'mo', 'tu', 'we', 'th', 'fr' ],
                );
            }
        }
        elsif ( $content->{'repeat-type'} eq 'weekly' ) {
            if ( $content->{'repeat-details-weekly'} eq 'week' ) {
                my $weeks = $content->{'repeat-details-weekly-weeks'};
                if ( defined $weeks ) {
                    $set = DateTime::Event::ICal->recur(
                        dtstart  => $last_due || $last_created,
                        freq     => 'weekly',
                        interval => $content->{'repeat-details-weekly-week'}
                          || 1,
                        byday => ref $weeks ? $weeks : [$weeks],
                    );
                }
                else {
                    $RT::Logger->error('No weeks defined');
                }
            }
        }
        elsif ( $content->{'repeat-type'} eq 'monthly' ) {
            if ( $content->{'repeat-details-monthly'} eq 'day' ) {
                $set = DateTime::Event::ICal->recur(
                    dtstart  => $last_due || $last_created,
                    freq     => 'monthly',
                    interval => $content->{'repeat-details-monthly-day-month'}
                      || 1,
                    bymonthday => $content->{'repeat-details-monthly-day-day'}
                      || 1,
                );
            }
            elsif ( $content->{'repeat-details-monthly'} eq 'week' ) {
                my $number = $content->{'repeat-details-monthly-week-number'}
                  || 1;
                my $day = $content->{'repeat-details-monthly-week-week'}
                  || 'mo';

                $set = DateTime::Event::ICal->recur(
                    dtstart  => $last_due || $last_created,
                    freq     => 'monthly',
                    interval => $content->{'repeat-details-monthly-week-month'}
                      || 1,
                    byday => $number . $day,
                );
            }
        }
        elsif ( $content->{'repeat-type'} eq 'yearly' ) {
            if ( $content->{'repeat-details-yearly'} eq 'day' ) {
                $set = DateTime::Event::ICal->recur(
                    dtstart  => $last_due || $last_created,
                    freq    => 'yearly',
                    bymonth => $content->{'repeat-details-yearly-day-month'}
                      || 1,
                    bymonthday => $content->{'repeat-details-yearly-day-day'}
                      || 1,
                );
            }
            elsif ( $content->{'repeat-details-yearly'} eq 'week' ) {
                my $number = $content->{'repeat-details-yearly-week-number'}
                  || 1;
                my $day = $content->{'repeat-details-yearly-week-week'} || 'mo';

                $set = DateTime::Event::ICal->recur(
                    dtstart  => $last_due || $last_created,
                    freq    => 'yearly',
                    bymonth => $content->{'repeat-details-yearly-week-month'}
                      || 1,
                    byday => $number . $day,
                );
            }
        }

        if ($set) {
            my @dates;
            my $iter = $set->iterator;
            while ( my $dt = $iter->next ) {
                next if $dt == $last_created;

                push @dates, $dt;
                last if @dates >= $tickets_needed;
            }

            for my $date (@dates) {
                push @ids, Repeat( $attr, @dates );
            }
        }
    }
    return @ids;
}

sub CheckCompleteStatus {
    my $ticket = shift;
    my $lifecycle =
        $ticket->QueueObj->can('LifecycleObj') ? $ticket->QueueObj->LifecycleObj : $ticket->QueueObj->Lifecycle;
    return 1 if $lifecycle->IsInactive( $ticket->Status );
    return 0;
}

sub CheckCompleteDate {
    my $checkday = shift;
    my $ticket   = shift;
    my $type     = shift || 'day';
    my $span     = shift;
    $span = 1 unless defined $span;

    my $resolved = $ticket->ResolvedObj;
    my $date     = $checkday->clone;
    if ($span) {
        $date->subtract( "${type}s" => $span );
    }

    return 0
      if $resolved->Date( Timezone => 'user' ) gt $date->ymd;


    return 1;
}

1;
__END__

=head1 NAME

RT::Extension::RepeatTicket - Repeat tickets based on schedule

=head1 DESCRIPTION

The RepeatTicket extension allows you to set up recurring tickets so
new tickets are automatically created based on a schedule. The new tickets
are populated with the subject and initial content of the original ticket
in the recurrence.

After you activate the plugin by adding it to your RT_SiteConfig.pm file,
all tickets will have a Recurrence tab on the create and edit pages. To
set up a repeating ticket, click the checkbox to "Enable Recurrence"
and fill out the schedule for the new tickets.

New tickets are created when you initially save the recurrence, if new
tickets are needed, and when your daily cron job runs the rt-repeat-ticket
script.

=head1 RT VERSION

Works with RT 5.0. Check out 1.* versions if you are still using RT 4.

=head1 INSTALLATION

=over

=item C<perl Makefile.PL>

=item C<make>

=item C<make install>

May need root permissions

=item C<make initdb>

Only run this the first time you install this module.

If you run this twice, you may end up with duplicate data
in your database.

If you are upgrading this module, check for upgrading instructions
in case changes need to be made to your database.

=item C<patch RT>

Apply for 5.0.0:

    patch -p1 -d /opt/rt5 < patches/0001-Fix-radio-checkbox-inputs-for-click-panel-behavior-o.patch

=item Edit your F</opt/rt5/etc/RT_SiteConfig.pm>

Add this line:

    Plugin('RT::Extension::RepeatTicket');

=item Clear your mason cache

    rm -rf /opt/rt5/var/mason_data/obj

=item Add F<bin/rt-repeat-ticket> to the daily cron job.

=item Restart your webserver

=back

=head1 CONFIGURATION

=head2 C<$RepeatTicketCoexistentNumber>

The C<$RepeatTicketCoexistentNumber>
determines how many tickets can be in an active status for a
recurrence at any time. A value of 1 means one ticket at a time can be active.
New tickets will not be created until the current active ticket is
resolved or set to some other inactive status. You can also set this
value per recurrence, overriding this config value.
The extension default is 1 ticket.

=head2 C<$RepeatTicketLeadTime>

The C<$RepeatTicketLeadTime> becomes the ticket Starts value and sets how far
in advance of a ticket's Due date you want the ticket to be created. This
essentially is how long you want to give people to work on the ticket.

For example, if you create a weekly recurrence scheduled on Mondays
and set the lead time to 7 days, each Monday a ticket will be created
with the Starts date set to that Monday and a Due date of the following
Monday.

The value you set in RT_SiteConfig.pm becomes the system default, but you can
set this value on each ticket as well. The extension default is 14 days.

=head2 C<$RepeatTicketSubjectFormat>

By default, repeated tickets will have the same subject as the original
ticket. You can modify this subject by setting a format with the
C<$RepeatTicketSubjectFormat> option. This option accepts formats in the
same form as formats for RT searches. The placeholders take values from
the repeated ticket, not the original ticket, so you can use the format
to help differentiate the subjects in repeated tickets.

For example, if you wanted to put the due date in the subject, you could
set the format to:

    Set($RepeatTicketSubjectFormat, '__Due__ __Subject__');

You'll want to use values that you don't expect to change since the subject
won't change if the ticket value (e.g., Due) is changed.

Since this uses RT formats, you can create a custom format by creating
a new RT ColumnMap. You can see the available formats by looking at
the columns available in the Display Columns portlet on the RT ticket
search page.

=head2 rt-repeat-ticket

The rt-repeat-ticket utility evaluates all of your repeating tickets and creates
any new tickets that are needed. With no parameters, it runs for "today" each
day. You can also pass a --date value in the form YYYY-MM-DD to run the script
for a specific day.

    bin/rt-repeat-ticket --date 2012-07-25

This can be handy if your cron job doesn't run for some reason and you want to make
sure no repeating tickets have been missed. Just go back and run the script for
the days you missed. You can also pass dates in the future which might be handy if
you want to experiment with recurrences in a test environment.

=head1 USAGE

=head2 Initial Tickets

The initial ticket you create for a recurrence stores the schedule and other
details for the recurrence.
If you need to change the recurrence in the future, to make it more frequent or
less frequent or anything else, make the changes on the original ticket.
To help you find this initial ticket, which may have been resolved long
ago, a custom field is created on each ticket
in the recurrence with link called "Original Ticket."

When setting up the recurrence, you can use the original ticket as an actual work
ticket. When doing this, you'll need to set the Starts and Due dates when you
create the ticket. Scheduled tickets created subsequently will set these values
based on the recurrence. Resolving the original ticket does not cancel the
recurrence.

=head2 Start Value

You can set a Start date for a new recurrence. If you don't, it defaults to the
day you create the recurrence.

=head2 Cancelling Recurrences

You can cancel or end a recurrence in two ways:

=over

=item *

Go to the original ticket in the recurrence and uncheck the Enable Recurrence
checkbox.

=item *

Set ending conditions on the recurrence with either a set number of recurrences
or an end date.

=back

=head2 Recursive Recurrences

Creating recurrences on recurrences isn't supported and may do strange things.

=head1 FAQ

=over

=item I'm not seeing new recurrences. Why not?

A few things to check:

=over

=item *

Do you have rt-repeat-tickets scheduled in cron? Is it running?

=item *

Do you have previous tickets still in an active state? Resolve those tickets
or increase the concurrent active tickets value.

=item *

Is it the right day? Remember to subtract the lead time value to determine
the day new tickets should be created.

=item *

If you set a start date and another criteria like day of the week, the new
ticket will be created on the first time that day of the week occurs
after the start date you set (if the start date isn't on that
day of the week).

=back

=item I want to enable the repeat function only on some queues

To do this, insetad of applying the "Original Ticket" custom field globally,
you can apply it to the chosen queues and that's it.

=item some users can't see or use this feature successfully.

Make sure those users have "SeeCustomField" and "ModifyCusotmField" rights
granted for "Original Ticket" custom field.

=back

=head1 METHODS

=head2 Run( RT::Attribute $attr, DateTime $checkday )

Repeat the ticket if C<$checkday> meets the repeat settings.
It also tries to repeat more to meet config C<RepeatTicketCoexistentNumber>.

Return ids of new created tickets.

=head2 Repeat ( RT::Attribute $attr, DateTime $checkday_1, DateTime $checkday_2, ... )

Repeat the ticket for the check days that meet repeat settings.

Return ids of new created tickets.

=head2 MaybeRepeatMore ( RT::Attribute $attr )

Try to repeat more tickets to meet the coexistent ticket number.

Return ids of new created tickets.

=head2 SetRepeatAttribute ( RT::Ticket $ticket, %args )

Save %args to the ticket's "RepeatTicketSettings" attribute.

Return ( RT::Attribute, UPDATE MESSAGE )

=head1 AUTHOR

Best Practical Solutions, LLC E<lt>modules@bestpractical.comE<gt>

=head1 BUGS

All bugs should be reported via email to

    L<bug-RT-Extension-RepeatTicket@rt.cpan.org|mailto:bug-RT-Extension-RepeatTicket@rt.cpan.org>

or via the web at

    L<rt.cpan.org|http://rt.cpan.org/Public/Dist/Display.html?Name=RT-Extension-RepeatTicket>.

=head1 LICENSE AND COPYRIGHT

This software is Copyright (c) 2014-2020 by Best Practical Solutions

This is free software, licensed under:

  The GNU General Public License, Version 2, June 1991

=cut
