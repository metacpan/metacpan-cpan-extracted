package RT::Action::EscalationDates;

use 5.010;
use strict;
use warnings;

use base qw(RT::Action);
use Date::Manip::Date;

our $VERSION = '0.4';


=head1 NAME

C<RT::Action::EscalationDates> - Set start and due time based on escalation
settings


=head1 DESCRIPTION

This RT Action sets start and due time based on escalation settings. It provides
handling business hours defined in RT site configuration file.


=head1 INSTALLATION

This action based on the following modules:

    RT >= 4.0.0
    Date::Manip >= 6.25

It is provided by the RT Extension RT::Extension::EscalationDates so it will be
installed automatically.


=head1 CONFIGURATION

Configuration is done by RT::Extension::EscalationDates.


=head1 AUTHOR

Benjamin Heisig, E<lt>bheisig@synetics.deE<gt>


=head1 SUPPORT AND DOCUMENTATION

You can find documentation for this module with the C<perldoc> command.

    perldoc RT::Extension::EscalationDates

You can also look for information at:

=over 4

=item * Search CPAN

L<http://search.cpan.org/dist/RT-Extension-EscalationDates/>

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=RT-Extension-EscalationDates>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/RT-Extension-EscalationDates>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/RT-Extension-EscalationDates>

=back


=head1 BUGS

Please report any bugs or feature requests to the L<author|/"AUTHOR">.


=head1 COPYRIGHT AND LICENSE

Copyright 2011 synetics GmbH, E<lt>http://i-doit.org/E<gt>

This program is free software; you can redistribute it and/or modify it under
the same terms as Perl itself.

Request Tracker (RT) is Copyright Best Practical Solutions, LLC.


=head1 SEE ALSO

    RT
    Date::Manip
    RT::Extension::EscalationDates


=head1 API


=head2 Prepare

Before the action may be L<commited|/"Commit"> preparation is needed: Has RT
already been configured for this action? Has the needed custom field been
created yet?


=cut

sub Prepare {
    my $self = shift;

    my $ticket = $self->TicketObj;

    ## Check configured priorities:
    ## TODO This could throw 2 warnings:
    ## 'Odd number of elements in hash assignment…' and
    ## 'Use of uninitialized value in list assignment…'
    my %priorities = RT->Config->Get('EscalateTicketsByPriority');
    ## TODO Does not work:
    unless (%priorities) {
        $RT::Logger->error(
            'Config: Information about escalating tickets by priority not set.'
        );
        return 0;
    }

    ## Check configured default priority:
    my $defaultPriority = RT->Config->Get('DefaultPriority');
    unless ($defaultPriority) {
        $RT::Logger->error('Config: Default priority not set.');
        return 0;
    }

    ## Validate default priority:
    if (!exists $priorities{$defaultPriority}) {
        $RT::Logger->error('Config: Default priority is not valid.');
        return 0;
    }

    ## Check configured Date::Manip:
    ## TODO This could throw 2 warnings:
    ## 'Odd number of elements in hash assignment…' and
    ## 'Use of uninitialized value in list assignment…'
    my %dateConfig = RT->Config->Get('DateManipConfig');
    ## TODO Does not work:
    unless (%dateConfig) {
        $RT::Logger->error('Config: Date::Manip\'s configuration not set.');
        return 0;
    }

    ## Check custom field:
    my $cfPriority = RT->Config->Get('PriorityField');
    unless ($cfPriority) {
        $RT::Logger->error('Config: Priority field is not set.');
        return 0;
    }

    ## Validate custom field:
    my $cf = RT::CustomField->new($RT::SystemUser);
    $cf->LoadByNameAndQueue(Name => $cfPriority, Queue => '0');
    unless($cf->id) {
        $RT::Logger->error(
            'Custom field "' . $cfPriority . '" is unknown. Have you created it yet?'
        );
        return 0;
    }

    return 1;
}


=head2 Commit

After preparation this method commits the action.


=cut

sub Commit {
    my $self = shift;

    my $ticket = $self->TicketObj;
    my $starts = $ticket->Starts;
    my $due = $ticket->Due;
    my $cfPriority = RT->Config->Get('PriorityField');
    my $priority = $ticket->FirstCustomFieldValue($cfPriority);

    ## Set default priority:
    unless ($priority) {
        $priority = RT->Config->Get('DefaultPriority');

        $RT::Logger->notice('Set priority: ' . $priority);

        my $cf = RT::CustomField->new($RT::SystemUser);
        $cf->LoadByNameAndQueue(Name => $cfPriority, Queue => $ticket->Queue);
        unless ($cf->id) {
            $cf->LoadByNameAndQueue(Name => $cfPriority, Queue => 0);
        }
        my ($val, $msg) = $ticket->AddCustomFieldValue(Field => $cf, Value => $priority);
        unless ($val) {
            $RT::Logger->error('Could not set priority: ' . $msg);
            return 0;
        }
    }

    $RT::Logger->info('Priority: ' . $priority);

    my $date = new Date::Manip::Date;

    ## MySQL date time format:
    my $format = '%Y-%m-%d %T';

    ## Destinated default time to start is (simply) now:
    my $now  = 'now';

    ## UNIX timestamp 0:
    my $notSet = '1970-01-01 00:00:00';

    my $RTTimezone = 'UTC';

    ## Look at start date:
    if ($starts eq $notSet) {
        $date->parse($now);
        $starts = $date->printf($format);

        ## Convert to UTC time:
        $date->convert($RTTimezone);
        my $startsUTC = $date->printf($format);

        $RT::Logger->notice('Set start date: ' . $starts . ' (UTC: ' . $startsUTC . ')');

        ## Set start date:
        my ($val, $msg) = $ticket->SetStarts($startsUTC);
        unless ($val) {
            $RT::Logger->error('Could not set start date: ' . $msg);
            return 0;
        }
    } else {
        $RT::Logger->info('Start date: ' . $starts);
    }

    ## Look at due date:
    if ($due eq $notSet) {
        ## Fetch when ticket should be escalated by priority:
        my %priorities = RT->Config->Get('EscalateTicketsByPriority');

        ## Validate priority:
        if (!exists $priorities{$priority}) {
            $RT::Logger->error('Unconfigured priority found: ' . $priority);
            return 0;
        }

        my $deltaStr = $priorities{$priority};

        ## Configure Date::Manip:
        my %dateConfig = RT->Config->Get('DateManipConfig');
        $date->config(%dateConfig);

        ## Compute date delta and format result:
        my $delta = $date->new_delta();
        $date->parse($starts);
        $delta->parse($deltaStr);
        my $calc = $date->calc($delta);
        $due = $calc->printf($format);

        ## Convert to UTC time:
        $calc->convert($RTTimezone);
        my $dueUTC = $calc->printf($format);

        $RT::Logger->notice('Set due date: ' . $due . ' (UTC: ' . $dueUTC . ')');

        ## Set due date:
        my ($val, $msg) = $ticket->SetDue($dueUTC);
        unless ($val) {
            $RT::Logger->error('Could not set due date: ' . $msg);
            return 0;
        }
    } else {
      $RT::Logger->info('Due date: ' . $due);
    }

    return 1;
}

1;