package Term::YAP;
$Term::YAP::VERSION = '0.07';
use strict;
use warnings;

=head1 NAME

Term::YAP - show pulsed progress bar in terminal

=cut

use Types::Standard 1.000005 qw(Str Int Bool Num);
use Time::HiRes 1.9726 qw(usleep time);
use Moo 2.000002;
use namespace::clean 0.26;

=head1 SYNOPSIS

    use Term::YAP;
    my $yap = Term::YAP->new( { name => 'Checking', rotate => 0, time => 1 } );
    $yap->start(); # start the pulse
    # do something between
    $yap->stop() # stop it

=head1 DESCRIPTION

Term::YAP is a L<Moo> based class to implement a "pulse" bar in a terminal. A pulse bar doesn't actually keep track of progress from any task being executed
but at least shows that the program is working instead of nothing for the end user.

This is the parent class and some methods were not implemented, you probably want to look for subclasses to get an implementation.

This module started as a shamelessly copy from L<Term::Pulse>, nowadays it keeps the same features but with a different implementation.

=head1 EXPORT

Nothing.

=head1 ATTRIBUTES

All attributes are optional and have their respective default values.

=head2 name

A simple message displayed before the pulse. The default value is 'Working'.

=cut

has name =>
  ( is => 'ro', isa => Str, default => 'Working', reader => 'get_name' );

=head2 rotatable

Boolean. Rotates the pulse if set to true. It is false by default.

=cut

has rotatable =>
  ( is => 'ro', isa => Bool, default => 0, reader => 'is_rotatable' );

=head2 time

Boolean. Display the elapsed time if set to 1. Turn off by default.

=cut

has time => ( is => 'ro', isa => Bool, default => 0, reader => 'show_time' );

=head2 size

Set the pulse size. The default value is 16.

=cut

has size => ( is => 'ro', isa => Int, default => 16, reader => 'get_size' );

=head2 start_time

The time (Unix Epoch) that the pulse bar started in seconds.

This attribute is "private".

=cut

has start_time => (
    is     => 'rw',
    isa    => Num,
    reader => '_get_start',
    writer => '_set_start',
);

=head2 usleep

The microseconds elapsed that each pulse has between each other. The default value is 200000.

This attribute is "private".

=cut

has usleep =>
  ( is => 'ro', isa => Num, reader => '_get_usleep', default => 200000 );

=head2 running

Boolean. If true, the pulse was started, false otherwise.

=cut

has running => (
    is      => 'ro',
    isa     => Bool,
    reader  => 'is_running',
    writer  => '_set_running',
    default => 0
);

=head2 debug

Boolean. If true, additional messages (which you mangle output) will by printed.

Defaults to false.

=cut

has debug => (
    is      => 'rw',
    isa     => Bool,
    reader  => 'is_debug',
    writer  => 'set_debug',
    default => 0
);

=head1 METHODS

=head2 is_running

Getter for C<running> attribute.

=head2 BUILD

Install handlers for signals C<INT> and C<__DIE__>.

=cut

sub BUILD {

    my $self = shift;

    $SIG{INT}     = sub { $self->stop };
    $SIG{__DIE__} = sub { $self->stop };

}

=head2 get_name

Returns the value of the name attribute.

=head2 is_rotatable

Returns the value of rotatable attribute.

=head2 show_time

Returns the value of time attribute.

=head2 get_size

Returns the value of size attribute.

=head2 start

Starts the pulse. Returns the value of C<running> attribute.

=head2 is_debug

Returns the value set of C<debug> attribute.

=head2 set_debug

Setter for the C<debug> attribute.

=cut

sub start {

    my $self = shift;
    return $self->is_running();

}

sub _is_enough {

    die '_is_enough() method must be overrided by subclasses of Term::YAP';

}

sub _keep_pulsing {

    my $self = shift;

    my @mark = qw(- \ | / - \ | /);
    $| = 1;

    my $name   = $self->get_name();
    my $rotate = $self->is_rotatable();
    my $size   = $self->get_size();
    my $time   = $self->show_time();
    my $start  = time();
    $self->_set_start($start);

  INFINITE: while (1) {

        # forward
        foreach my $index ( 1 .. $size ) {

            my $mark = $rotate ? $mark[ $index % 8 ] : q{=};
            printf "$name...[%s%s%s]", q{ } x ( $index - 1 ), $mark,
              q{ } x ( $size - $index );
            printf " (%f sec elapsed)", ( time - $start ) if $time;
            printf "\r";
            last INFINITE if ( $self->_is_enough() );
            $self->_sleep();
        }

        # backward
        foreach my $index ( 1 .. $size ) {

            my $mark = $rotate ? $mark[ ( $index % 8 ) * -1 ] : q{=};
            printf "$name...[%s%s%s]", q{ } x ( $size - $index ), $mark,
              q{ } x ( $index - 1 );
            printf " (%f sec elapsed)", ( time - $start ) if $time;
            printf "\r";
            last INFINITE if ( $self->_is_enough() );
            $self->_sleep();

        }

    }

    return ( time() - $self->_get_start() );

}

=head2 stop

Stop the pulse and return elapsed time.

=cut

sub stop {
    return shift->_report;
}

sub _report {
    my $self   = shift;
    my $name   = $self->get_name();
    my $length = length($name);

    if ( $length > 0 ) {
        printf "$name%sDone%s\n", q{.} x ( 35 - $length ), q{ } x 43;
        return 1;
    }
    else {
        warn "cannot print progress without positive length for '$name'";
        return 0;
    }
}

sub _sleep {
    my $self = shift;
    usleep( $self->_get_usleep() );
}

=head1 SEE ALSO

=over

=item *

L<Term::Pulse>

=item *

L<Moo>

=back

=head1 AUTHOR

Alceu Rodrigues de Freitas Junior, E<lt>arfreitas@cpan.orgE<gt>

L<Term::Pulse> was originally created by Yen-Liang Chen, E<lt>alec at cpan.comE<gt>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2015 of Alceu Rodrigues de Freitas Junior, E<lt>arfreitas@cpan.orgE<gt>

This file is part of Term-YAP distribution.

Term-YAP is free software: you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation, either version 3 of the License, or
(at your option) any later version.

Term-YAP is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with Term-YAP. If not, see <http://www.gnu.org/licenses/>.

=cut

1;
