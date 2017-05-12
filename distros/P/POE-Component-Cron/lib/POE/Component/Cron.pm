package POE::Component::Cron;

use 5.008;

our $VERSION = 0.021;

use strict;
use warnings;

use base 'POE::Component::Schedule';
use DateTime::TimeZone;
use DateTime::Event::Cron;
use DateTime::Infinite;

sub from_cron {
    my $class = shift;
    my ( $spec, $session, $event, @args ) = @_;

    my $timezone = DateTime::TimeZone->new( name => 'local' );
    $timezone ||= DateTime::TimeZone->new( name => 'GMT' );

    $class->add(
        $session =>
          $event => DateTime::Event::Cron->from_cron($spec)->iterator(
            span => DateTime::Span->from_datetimes(
                start => DateTime->now( time_zone => $timezone ),
                end   => DateTime::Infinite::Future->new
            )
          ),
        @args,
    );
}

1;
__END__

=head1 NAME

POE::Component::Cron - Schedule POE Events using a cron spec

=head1 SYNOPSIS

    use POE::Component::Cron;

    $s1 = POE::Session->create(
        inline_states => {
            _start => sub {
               $_[KERNEL]->delay( _die_, 120 );
            }

            Tick => sub {
               print 'tick ', scalar localtime, "\n";
            },
        }
    );

    # crontab schedule the easy wa
    $sched =
      POE::Component::Cron->from_cron( '* * * * *' => $s2->ID => 'Tick' );

    # delete some schedule of events
    $sched->delete();

=head1 DESCRIPTION

This component extends POE::Component::Schedule by adding an easy way t
specify event schedules using a simple cron spec.

=head1 METHODS

=head2 from_cron

Add a schedule using a simple syntax for plain old cron spec.

    POE::Component::Cron-> from_cron('*/5 */2 * * 1' => session => event);

Accepts the cron syntax as defined by DateTime::Event::Cron which is pretty
the same as that used by common linux cron.

=head1 SEE ALSO

POE, POE::Component::Schedule perl, DateTime::Set, DateTime::Event::Cron.

=head1 AUTHOR

Chris Fedde, E<lt>cfedde@cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2008 by Chris Fedde

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.3 or,
at your option, any later version of Perl 5 you may have available.

=cut
