package Sim;

use strict;
use warnings;
use vars qw( $AUTOLOAD );

use Sim::Dispatcher;
use Sim::Clock;

our $VERSION = '0.03';

our ($Clock, $Dispatcher);

sub AUTOLOAD {
    my $self = shift;
    my $method = $AUTOLOAD;

    $method =~ s/.*:://;
    return if $method eq 'DESTROY';

    $Clock ||= Sim::Clock->new;
    $Dispatcher ||= Sim::Dispatcher->new(clock => $Clock);
    $Dispatcher->$method(@_);
}

1;
__END__

=head1 NAME

Sim - Simulator engine for discrete events

=head1 VERSION

This document describes Sim 0.03 released on 2 June, 2007.

=head1 SYNOPSIS

    use Sim;

    Sim->schedule(
        0.2 => sub { print "Hi\n" },
        0.4 => sub {
            Sim->schedule(
                0.5 => sub { print "Wow!\n" },
                Sim->now + 0.2 => sub { print "Hello!\n" },
            );
        },
        0.5 => sub { print "now is ", Sim->now, "\n"; },
    );

    Sim->run( duration => 1.0 );  # upper-limit for simulation time

    # OR: Sim->run( fires => 15 );  # upper-limit for number of event fires

    print "now is ", Sim->now, "\n";  # now is 0.6

=head1 DESCRIPTION

Sim is a general-purpose discrete event simulator engine written in pure
Perl. It was originally developed as the run-core of a sequential/conbinational
logic circuit simulator named Tesla.

The Sim class is just a static class wrapping around a L<Sim::Dispatcher>
instance and a L<Sim::Clock> instance. I used AUTOLOAD to do the magic instead
of writing a lot of boring code. It's expected that using L<Sim::Dispatcher>
directly can be a bit faster but is certainly less convenient.

If you want to use a different clock model with vectorized time read,
say a [sec, delta], which is found in a lot of EDA simulators, then you
should use L<Sim::Dispatcher> instead of L<Sim> and define your clock class
yourself.

See L<Sim::Dispatcher> for more information.

=head1 STATIC METHODS

All the methods of L<Sim::Dispatcher> are available for this class, but
they are exposed as static methods only :)

=head1 TODO

=over

=item *

Add cookbooks for M/M/1 and M/M/m queueing problems.

=item *

Add support for vectorized timestamp (i.e. something like 3 sec + 3 * delta).

=item *

Add missing features compared to SimPy in the Python world.

=back

=head1 BUGS

There must be some serious bugs lurking somewhere; if you find one,
please consider firing off a report to
L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Sim>.

=head1 VERSION CONTROL

You can always get the latest version of the source from the following
Subversion repository:

L<http://svn.openfoundry.org/sim/>

which has anonymous access to all.

If you do want a commit bit and become a coauthor, please let me know :)

=head1 CODE COVERAGE

I use Devel::Cover to test the code coverage of the test suite:

 ---------------------------- ------ ------ ------ ------ ------ ------ ------
 File                           stmt   bran   cond    sub    pod   time  total
 ---------------------------- ------ ------ ------ ------ ------ ------ ------
 blib/lib/Sim.pm               100.0   50.0   66.7  100.0    n/a    5.7   91.7
 blib/lib/Sim/Clock.pm         100.0   83.3    n/a  100.0  100.0    9.0   97.3
 blib/lib/Sim/Dispatcher.pm     94.6   75.0  100.0  100.0  100.0   31.1   92.2
 ---------------------------- ------ ------ ------ ------ ------ ------ ------

=head1 AUTHOR

Agent Zhang E<lt>agentzh@gmail.comE<gt>

=head1 COPYRIGHT

Copyright 2006, 2007 by Agent Zhang. All rights reserved.

This library is free software; you can modify and/or modify it under the
same terms as Perl itself.

=head1 SEE ALSO

L<Sim::Dispatcher>, L<Sim::Clock>.

