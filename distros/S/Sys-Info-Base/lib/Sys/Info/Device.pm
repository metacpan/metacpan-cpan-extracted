package Sys::Info::Device;
use strict;
use warnings;
use vars qw( $VERSION );
use constant SUPPORTED => qw( CPU BIOS );
use Carp qw( croak );
use base qw( Sys::Info::Base );
use Sys::Info::Constants qw( OSID );

$VERSION = '0.7804';

BEGIN {
    MK_ACCESSORS: {
        no strict qw(refs);
        foreach my $device ( SUPPORTED ) {
            *{ '_device_' . lc $device } = sub {
                my $self = shift;
                return  Sys::Info::Base->load_module(
                            'Sys::Info::Device::' . $device
                        )->new(@_);
            }
        }
    }
}

sub new {
    my($class, @args) = @_;
    my $device = shift @args or croak 'Device ID is missing';
    my $self   = {};
    bless $self, $class;

    my $method = '_device_' . lc $device;
    croak "Bogus device ID: $device" if ! $self->can( $method );
    return $self->$method( @args ? @args : () );
}

sub _device_available {
    my $self  = shift;
    my $class = ref $self || $self;
    my @buf;
    local $@;
    local $SIG{__DIE__};

    foreach my $test ( SUPPORTED ) {
        my $eok = eval { $class->new( $test ); 1; };
        next if $@ || ! $eok;
        push @buf, $test;
    }

    return @buf;
}

1;

__END__

=head1 NAME

Sys::Info::Device - Information about devices

=head1 SYNOPSIS

    use Sys::Info;
    my $info      = Sys::Info->new;
    my $device    = $info->device( $device_id );
    my @available = $info->device('available');

or

    use Sys::Info::Device;
    my $device    = Sys::Info::Device->new( $device_id );
    my @available = Sys::Info::Device->new('available');

=head1 DESCRIPTION

This document describes version C<0.7804> of C<Sys::Info::Device>
released on C<21 January 2015>.

This is an interface to the available devices such as the C<CPU>.

=head1 METHODS

=head2 new DEVICE_ID

Returns an object to the related device or dies if C<DEVICE_ID> is
bogus or false.

If C<DEVICE_ID> has the value of C<available>, then the names of the
available devices will be returned.

=head1 SEE ALSO

L<Sys::Info::Device::CPU>, L<Sys::Info>.

=head1 AUTHOR

Burak Gursoy <burak@cpan.org>.

=head1 COPYRIGHT

Copyright 2006 - 2015 Burak Gursoy. All rights reserved.

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.16.2 or,
at your option, any later version of Perl 5 you may have available.
=cut
