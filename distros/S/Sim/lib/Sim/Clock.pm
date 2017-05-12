package Sim::Clock;

use Carp qw(croak carp);
use strict;
use warnings;

our $VERSION = '0.03';

sub new ($$) {
	my $class = ref $_[0] ? ref shift : shift;
	my $now = @_ ? shift : 0;
	bless {
		now => $now,
	}, $class;
}

sub now ($) {
	$_[0]->{now};
}

sub push_to ($$) {
    my ($self, $time) = @_;
	if ($time < $self->now) {
        carp "error: Can't push your time back, sir";
        return 0;
    }
    $self->{now} = $time;
    return 1;
}

sub reset ($) {
    $_[0]->{now} = 0;
}

1;
__END__

=head1 NAME

Sim::Clock - Simulation clock used by the dispatcher

=head1 VERSION

This document describes Sim::Clock 0.03 released on
2 June, 2007.

=head1 SYNOPSIS

    use Sim::Clock;
    my $clock = Sim::Clock->new(0);
    $clock->push_to(5.6);
    print $clock->now;  # 5.6
    $clock->push_to(3); # exception!
    $clock->reset();

=head1 DESCRIPTION

This class offers a simulation clock for L<Sim::Dispatcher>. Basically
you needn't create your own clock at all since L<Sim::Dispatcher> always
creates one internally and you seldom or never need more than one clock
in your simulator. But you really feel the need to do something fancy,
simulating quantum mechanics for example, here is the rope.

=head1 METHODS

=over

=item C<< $obj->new( $init_time ? ) >>

Ths is the constructor for C<Sim::Clock> objects. The C<$init_time> argument
specifies the initial time read of the clock and can be omitted.

=item C<< $obj->now() >>

Reads the current time from the clock.

=item C<< $obj->push_to($time) >>

Push the clock to the specified timestamp C<$time>, which can't be earlier than
the value obtained by the C<now> method.

=item C<< $obj->reset() >>

Resets the clock to time 0.

=back

=head1 AUTHOR

Agent Zhang E<lt>agentzh@gmail.comE<gt>

=head1 COPYRIGHT

Copyright 2006 by Agent Zhang. All rights reserved.

This library is free software; you can modify and/or
modify it under the same terms as Perl itself.

=head1 SEE ALSO

L<Sim::Dispatcher>, L<Sim>.

