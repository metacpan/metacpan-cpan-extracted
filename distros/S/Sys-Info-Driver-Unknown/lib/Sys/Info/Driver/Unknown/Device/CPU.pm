package Sys::Info::Driver::Unknown::Device::CPU;
use strict;
use warnings;
use vars qw($VERSION $UP);
use base qw(Sys::Info::Driver::Unknown::Device::CPU::Env);

$VERSION = '0.78';

BEGIN {
    local $SIG{__DIE__};
    local $@;
    my $eok = eval {
        require Unix::Processors;
        Unix::Processors->import;
    };
    $UP = Unix::Processors->new if ! $@ && $eok;
}

sub load    {}
sub bitness {}

sub identify {
    my $self = shift;
    $self->{META_DATA} ||= [
        !$UP ? $self->SUPER::identify(@_) : map {{
            processor_id                 => $_->id, # cpu id 0,1,2,3...
            data_width                   => undef,
            address_width                => undef,
            bus_speed                    => undef,
            speed                        => $_->clock,
            name                         => $_->type,
            family                       => undef,
            manufacturer                 => undef,
            model                        => undef,
            stepping                     => undef,
            number_of_cores              => $UP->max_physical,
            number_of_logical_processors => $UP->max_online,
            L1_cache                     => undef,
            flags                        => undef,
        }} @{ $UP->processors }
    ];
    return $self->_serve_from_cache(wantarray);
}

1;

__END__

=head1 NAME

Sys::Info::Driver::Unknown::Device::CPU - Compatibility layer for unsupported platforms

=head1 SYNOPSIS

See L<Sys::Info::Device::CPU>.

=head1 DESCRIPTION

This document describes version C<0.78> of C<Sys::Info::Driver::Unknown::Device::CPU>
released on C<17 April 2011>.

L<Unix::Processors> is recommended for
unsupported platforms.

=head1 METHODS

=head2 identify

See identify in L<Sys::Info::Device::CPU>.

=head2 load

See load in L<Sys::Info::Device::CPU>.

=head2 bitness

See bitness in L<Sys::Info::Device::CPU>.

=head1 SEE ALSO

L<Sys::Info>, L<Sys::Info::CPU>, L<Unix::Processors>.

=head1 AUTHOR

Burak Gursoy <burak@cpan.org>.

=head1 COPYRIGHT

Copyright 2006 - 2011 Burak Gursoy. All rights reserved.

=head1 LICENSE

This library is free software; you can redistribute it and/or modify 
it under the same terms as Perl itself, either Perl version 5.12.3 or, 
at your option, any later version of Perl 5 you may have available.

=cut
