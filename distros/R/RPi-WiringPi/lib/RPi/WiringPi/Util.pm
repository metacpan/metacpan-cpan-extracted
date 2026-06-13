package RPi::WiringPi::Util;

use strict;
use warnings;

use base 'Exporter';

use parent 'WiringPi::API';
use Carp qw(croak);
use Data::Dumper;
use Digest::MD5 qw(md5_hex);
use RPi::Const qw(:all);
use Time::HiRes qw(time);

our $VERSION = '3.1802';

sub checksum {
    return md5_hex($$ . time() . rand());
}
sub dump_signal_handlers {
    my ($self) = @_;
    print Dumper $self->_signal_handlers;
}
sub pin_map {
    my ($self, $scheme) = @_;

    $scheme = $self->pin_scheme if ! defined $scheme;

    return {} if $scheme == RPI_MODE_UNINIT;

    if (defined $self->{pin_map_cache}{$scheme}) {
        return $self->{pin_map_cache}{$scheme};
    }

    my %map;

    for (0..63){
        my $pin;
        if ($scheme == RPI_MODE_WPI) {
            $pin = $self->phys_to_wpi($_);
        }
        elsif ($scheme == RPI_MODE_GPIO){
            $pin = $self->phys_to_gpio($_);
        }
        $map{$_} = $pin;
    }

    $self->{pin_map_cache}{$scheme} = \%map;

    return \%map;
}
sub signal_handlers {
    my ($self) = @_;
    return $self->_signal_handlers;
}
sub uuid {
    my ($self) = @_;
    return $self->{uuid};
}

sub _vim{1;};

1;

__END__

=head1 NAME

RPi::WiringPi::Util - Utility methods outside of Pi hardware functionality

=head1 DESCRIPTION

This module contains various utilities for L<RPi::WiringPi> that don't
necessarily fit anywhere else. It is a base class, and is not designed to be
used independently.

=head1 METHODS

=head2 checksum

Returns a randomly generated 32-byte hexidecimal MD5 checksum. We use this
internally to generate a UUID for each Pi object.

=head2 pin_map($scheme)

Returns a hash reference in the following format:

    $map => {
        phys_pin_num => pin_num,
        ...
    };

If no scheme is in place or one isn't sent in, return will be an empty hash
reference.

Parameters:

    $scheme

Optional: By default, we'll check if you've already run a setup routine, and
if so, we'll use the scheme currently in use. If one is not in use and no
C<$scheme> has been sent in, we'll return an empty hash reference, otherwise
if a scheme is sent in, the return will be:

For C<'wiringPi'> scheme:

    $map = {
        phys_pin_num => wiringPi_pin_num,
        ....
    };

For C<'GPIO'> scheme:

    $map = {
        phys_pin_num => gpio_pin_num,
        ...
    };

=head2 uuid

Returns the Pi object's 32-byte hexidecimal unique identifier.

=head2 signal_handlers

Returns a hash reference of the currently set signal handlers.

=head2 dump_signal_handlers

Prints, using L<Data::Dumper>, the structure holding the class' signal handling
data.

=head1 AUTHOR

Steve Bertrand, E<lt>steveb@cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2016-2026 by Steve Bertrand

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.18.2 or,
at your option, any later version of Perl 5 you may have available.
