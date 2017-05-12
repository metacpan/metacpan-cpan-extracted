#   Copyright Infomation
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# Author : Dr. Ahmed Amin Elsheshtawy, Ph.D.
# Website: https://github.com/mewsoft/Nile, http://www.mewsoft.com
# Email  : mewsoft@cpan.org, support@mewsoft.com
# Copyrights (c) 2014-2015 Mewsoft Corp. All rights reserved.
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
package Nile::Timer;

our $VERSION = '0.55';
our $AUTHORITY = 'cpan:MEWSOFT';

=pod

=encoding utf8

=head1 NAME

Nile::Timer - Timer to clock operations.

=head1 SYNOPSIS
    
    # start the timer
    $app->timer->start;
    
    # do some operations...
    
    # get time elapsed since start called
    say $app->timer->lap;

    # do some other operations...

    # get time elapsed since last lap called
    say $app->timer->lap;

    # get another timer object, timer automatically starts
    my $timer = $app->timer->new;
    say $timer->lap;
    #...
    say $timer->lap;
    #...
    say $timer->total;

    # get total time elapsed since start
    say $app->timer->total;

=head1 DESCRIPTION

Nile::Timer - Timer to clock operations.

=cut

use Nile::Base;
use Time::HiRes qw(gettimeofday tv_interval);
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
sub BUILD {
    my ($self, $args) = @_;
    $self->start;
}
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
=head2 start()
    
    # start the timer from now
    $app->timer->start;

Starts the timer. Timer starts by default when the application is started.

=cut

sub start {
    my ($self) = @_;
    my $now = [gettimeofday()];
    $self->start_time($now);
    $self->lap_start_time($now);
}
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
=head2 lap()
    
    say $app->timer->lap;

Returns the time period since the last lap or from the start if not called before.

=cut

sub lap {
    my ($self) = @_;
    Time::HiRes::usleep 10000;
    my $now = [gettimeofday()];
    my $lap = tv_interval($self->lap_start_time, $now);
    $self->lap_start_time([gettimeofday()]);
    return sprintf("%0f", $lap);
}
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
=head2 total()
    
    # get total time since start called
    say $app->timer->total;

Returns the total time since the last start.

=cut

sub total {
    my ($self) = @_;
    my $now = [gettimeofday()];
    my $lap = tv_interval($self->start_time, $now);
    return sprintf("%0f", $lap);
}
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
=head2 start_time()
    
    say $app->timer->start_time;

Returns the last start time.

=cut

has 'start_time' => (
      is      => 'rw',
  );


=head2 lap_start_time()
    
    say $app->timer->lap_start_time;

Returns the last lap start time.

=cut

has 'lap_start_time' => (
      is      => 'rw',
  );
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
=head2 time()
    
    say $app->timer->time;

Returns the current time.

=cut

sub time {
    my ($self) = @_;
    return [gettimeofday()];
}
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

=pod

=head1 Bugs

This project is available on github at L<https://github.com/mewsoft/Nile>.

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Nile>.

=head1 SOURCE

Source repository is at L<https://github.com/mewsoft/Nile>.

=head1 SEE ALSO

See L<Nile> for details about the complete framework.

=head1 AUTHOR

Ahmed Amin Elsheshtawy,  احمد امين الششتاوى <mewsoft@cpan.org>
Website: http://www.mewsoft.com

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2014-2015 by Dr. Ahmed Amin Elsheshtawy احمد امين الششتاوى mewsoft@cpan.org, support@mewsoft.com,
L<https://github.com/mewsoft/Nile>, L<http://www.mewsoft.com>

This library is free software; you can redistribute it and/or modify it under the same terms as Perl itself.

=cut

1;
