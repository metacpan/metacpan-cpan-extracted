# RT::Condition::NotStartedInBusinessHours
#
# Copyright 2012 synetics GmbH, http://i-doit.org/
#
# This program is free software; you can redistribute it and/or modify it under
# the same terms as Perl itself.
#
# Request Tracker (RT) is Copyright Best Practical Solutions, LLC.

package RT::Condition::NotStartedInBusinessHours;

use 5.010;
use strict;
use warnings;

require RT::Condition;

use Date::Manip;

use vars qw/@ISA/;
@ISA = qw(RT::Condition);

our $VERSION = '0.3';


=head1 NAME

RT::Condition::NotStartedInBusinessHours - Check for unstarted tickets within
business hours


=head1 DESCRIPTION

This RT condition will check for tickets which are not started within business
hours.


=head1 SYNOPSIS


=head2 CLI

    rt-crontool
        --search RT::Search::ModuleName
        --search-arg 'The Search Argument'
        --condition RT::Condition::NotStartedInBusinessHours
        --condition-arg 'The Condition Argument'
        --action RT::Action:ActionModule
        --template 'Template Name or ID'


=head1 INSTALLATION

This condition based on the following modules:

    RT >= 4.0.0
    Date::Manip >= 6.34

To install this condition run the following commands:

    perl Makefile.PL
    make
    make test
    make install

or place this script under

    $RT_HOME/local/lib/RT/Condition/

where C<$RT_HOME> is the path to your RT installation, for example C</opt/rt4>.

You may additionally make this condition available in RT's web UI as a Scrip
Condition:

    make initdb

Another way to install the latest release is via CPAN:

    cpan RT::Condition::NotStartedInBusinessHours
    $RT_HOME/sbin/rt-setup-database --action insert --datafile /opt/rt4/local/plugins/RT-Condition-NotStartedInBusinessHours/etc/initialdata

The second command is equivalent to C<make initdb>, but is unfortunately not executed automatically.


=head1 CONFIGURATION


=head2 RT SITE CONFIGURATION

To enabled this condition edit the RT site configuration located under
C<$RT_HOME/etc/RT_SiteConfig.pm>:

    Set(@Plugins,qw(RT::Condition::NotStartedInBusinessHours));

To change the standard behavior of Date::Manip you may add to the site
configuration:

    Set(%DateManipConfig, (
        'WorkDayBeg', '9:00',
        'WorkDayEnd', '17:00', 
        #'WorkDay24Hr', '0',
        'WorkWeekBeg', '1',
        'WorkWeekEnd', '5'
    ));

For more information see L<http://search.cpan.org/~sbeck/Date-Manip-6.34/lib/Date/Manip/Config.pod#BUSINESS_CONFIGURATION_VARIABLES>.


=head2 CONDITION ARGUMENT

This condition needs exactly 1 argument to work.

    --condition RT::Condition::NotStartedInBusinessHours 
    --condition-arg 1

C<1> is the time in hours for escalation.


=head2 EXAMPLE CRON JOB

    rt-crontool 
        --search RT::Search::FromSQL 
        --search-arg "Queue = 'General' AND ( Status = 'new' ) AND Owner = 'Nobody'" 
        --condition RT::Condition::NotStartedInBusinessHours 
        --condition-arg 1 
        --action RT::Action::RecordComment 
        --template 'Unowned tickets'


=head1 AUTHOR

Benjamin Heisig, E<lt>bheisig@synetics.deE<gt>


=head1 SUPPORT AND DOCUMENTATION

You can find documentation for this module with the C<perldoc> command.

    perldoc RT::Condition::NotStartedInBusinessHours

You can also look for information at:

=over 4

=item B<Search CPAN>

L<http://search.cpan.org/dist/RT-Condition-NotStartedInBusinessHours/>

=item B<RT: CPAN's request tracker>

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=RT-Condition-NotStartedInBusinessHours>

=item B<AnnoCPAN: Annotated CPAN documentation>

L<http://annocpan.org/dist/RT-Condition-NotStartedInBusinessHours>

=item B<CPAN Ratings>

L<http://cpanratings.perl.org/d/RT-Condition-NotStartedInBusinessHours>

=item B<Repository>

L<https://github.com/bheisig/rt-condition-notstartedinbusinesshours>

=back


=head1 BUGS

Please report any bugs or feature requests to the L<author|/"AUTHOR">.


=head1 ACKNOWLEDGEMENTS

This script is a fork from L<RT::Condition::UntouchedInBusinessHours> written by
Torsten Brumm.


=head1 COPYRIGHT AND LICENSE

Copyright 2012 synetics GmbH, E<lt>http://i-doit.org/E<gt>

This program is free software; you can redistribute it and/or modify it under
the same terms as Perl itself.

Request Tracker (RT) is Copyright Best Practical Solutions, LLC.


=head1 SEE ALSO

    RT
    Date::Manip


=cut


sub IsApplicable {
    my $self = shift;

    ## Fetch ticket information:
    my $ticketObj = $self->TicketObj;
    my $tickid = $ticketObj->Id;

    ## Calculate starts time (independent from system user's language and date format settings):
    my $startsObj = new Date::Manip::Date;
    $startsObj->parse($ticketObj->StartsObj->Get(Format => 'RFC2616'));
    $startsObj->convert(RT->Config->Get('Timezone'));
    my $format = '%Y-%m-%d %T %z';
    my $starts = $startsObj->printf($format);

    my $date = new Date::Manip::Date;

    ## Set Date::Manip's configuration from RT's site configuration:
    my %dateConfig = RT->Config->Get('DateManipConfig');
    # @todo check wether setting exists
    $date->config(%dateConfig);

    ## Compute escalation date:
    my $delta = $date->new_delta();
    $date->parse($starts);
    my $hours = $self->Argument;
    my $businessHours = "in $hours business hours";
    $delta->parse($businessHours);
    my $escalationDate = $date->calc($delta);

    ## Compute actual time:
    my $now = $date->new_date;
    $now->parse('now');

    ## Compare booth times:
    my $cmp = $escalationDate->cmp($now);

    ## Make a decision:
    if ($cmp <= 0) {
        return 1;
    }

    return undef;
}

eval "require RT::Condition::NotStartedInBusinessHours_Vendor";
die $@ if ($@ && $@ !~ qr{^Can't locate RT/Condition/NotStartedInBusinessHours_Vendor.pm});
eval "require RT::Condition::NotStartedInBusinessHours_Local";
die $@ if ($@ && $@ !~ qr{^Can't locate RT/Condition/NotStartedInBusinessHours_Local.pm});

1;
