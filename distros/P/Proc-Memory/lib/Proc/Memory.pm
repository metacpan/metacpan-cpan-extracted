use strict;
use warnings;
package Proc::Memory;

# ABSTRACT: Peek/Poke other processes' address spaces
our $VERSION = '0.009'; # VERSION

use Carp;
use Sentinel;
use Scalar::Util 'looks_like_number';
use Alien::libvas;
use Inline  'C' => 'DATA' =>
            enable => 'autowrap';
use Inline 0.56 with => 'Alien::libvas';

=pod

=encoding utf8

=head1 NAME

Proc::Memory - Peek/Poke into processes' address spaces

=head1 SYNOPSIS

    use Proc::Memory;

    my $mem = Proc::Memory->new(pid => $$);

    my $byte = $mem->peek(0x1000);
    my $u32  = $mem->read(0x1000, 4);
    $mem->poke(0x1000, 'L') = 12;


=head1 DESCRIPTION

PEEK/POKE are a BASIC programming language extension for reading and writing memory at a specified address across process boundaries. This module brings similiar capability to Perl.

Eventually, Memory searching capability will also be added.

=head1 IMPLEMENTATION

The module is a Perlish wrapper for L<Alien::libvas> and doesn't expose any extra functionality. L<libvas|http://github.com/a3f/libvas> claims support for following backends:

    • win32      - Windows API's {Read,Write}ProcessMemory
    • mach       - Mach Virtual Memory API (vm_copy) - macOS and GNU Hurd
    • process_vm - process_vm_{readv, writev} on Linux 3.2+
    • procfs     - /proc/$pid/mem on Linux and some BSDs, /proc/$pid/as on SunOS
    • ptrace     - ptrace(2), available on many Unices
    • memcpy     - Trivial implementation that doesn't supports foreign address spaces

Bug reports and contributions are welcome. :-)

=head1 METHODS AND ARGUMENTS

=over 4

=item new(pid)

Constructs a new Proc::Memory instance.

=cut

sub new {
	my $class = shift;
    my @opts = @_;
    unshift @opts, 'pid' if @_ % 2 == 1;

    my $self = {
        @opts
    };

    looks_like_number $self->{pid}
        or croak q/Pid isn't numeric/;

    $self->{vas} = xs_vas_open($self->{pid}, 0)
        or do {
            if (kill 0, $self->{pid}) {
                croak "PID doesn't exist"
            } else {
                croak "Process access permission denied"
            }
        };

	bless $self, $class;
	return $self;
}

=item peek(addr [, 'pack-string'])

Peeks at the given memory address. C<pack-string> defaults to C<'C'> (A single byte)

=cut

sub peek {
    my $self = shift;
    my $addr = shift;
    my $fmt = shift // 'C';
    $fmt eq 'C'
        or croak 'Pack strings not supported yet';

    my $buf = xs_vas_read($self->{vas}, $addr, 1);
    return $buf;
}



=item poke(addr [, 'pack-string']) = $value # or = ($a, $b)

Pokes a given memory address. If no pack-string is given, the rvalue is written as is

=cut

sub get_poke {
    carp 'Useless use of poke';
    undef;
}
sub set_poke {
    my @args = @{+shift};
    my $self   = shift @args;
    my $buf = shift;
    my $addr  = shift @args or croak 'Address must be specified';
    if (my $fmt = shift @args) {
        $buf = pack($fmt, ref($buf) eq 'ARRAY' ? @{$buf} : $buf);
    }

    my $nbytes = xs_vas_write($self->{vas}, $addr, $buf, length $buf);
    return $nbytes >= 0 ? $nbytes : undef;
}

sub poke :lvalue {
    defined wantarray or croak 'Useless use of poke';
    sentinel obj => [@_], get => \&get_poke, set => \&set_poke
}

=item read(addr, size)

Reads size bytes from given memory address.

=cut

#SV *xs_vas_read(void* vas, unsigned long src, size_t size) {
sub read {
    my $self = shift;
    my $addr = shift;
    my $size = shift;

    my $buf = xs_vas_read($self->{vas}, $addr, $size);
    return $buf;
}

=item write(addr, buf [, count])

Writes C<buf> to C<addr>

=cut

#int xs_vas_write(void* vas, unsigned long dst, SV *sv) {
sub write {
    my $self = shift;
    my $addr = shift;
    my $buf  = shift;
    my $bytes  = shift || length $buf;

    my $nbytes = xs_vas_write($self->{vas}, $addr, $buf, $bytes);
    return $nbytes >= 0 ? $nbytes : undef;
}

=item tie(addr, 'pack-string')

Returns a tied variable which can be used like any other variable.
To be implemented

=cut

=item search('pack-string')

To be implemented when libvas provides it

=cut



sub DESTROY {
    my $self = shift;
    xs_vas_close($self->{vas});
}

Inline->init();
1;

=back

=head1 GIT REPOSITORY

L<http://github.com/athreef/Proc-Memory>

=head1 SEE ALSO

L<libvas|http://github.com/a3f/libvas>
L<Alien::libvas>

=head1 AUTHOR

Ahmad Fatoum C<< <athreef@cpan.org> >>, L<http://a3f.at>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2016 Ahmad Fatoum

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

__DATA__
__C__

#include <vas.h>

void *xs_vas_open(int pid, int flags) {
    return vas_open(pid, flags);
}

SV *xs_vas_read(void* vas, unsigned long src, size_t size) {
    char *dst;
    ssize_t nbytes;

    SV *sv = newSV(0);
    Newx(dst, size, char);

    nbytes = vas_read(vas, src, dst, size);
    sv_usepvn_flags(sv, dst, nbytes, SV_SMAGIC | SV_HAS_TRAILING_NUL);

    if (nbytes < 0) {
        SvREFCNT_dec(sv);
        return newSVsv(&PL_sv_undef);
    } else
        return sv;
}

int xs_vas_write(void* vas, unsigned long dst, SV *sv, size_t size) {
    int nbytes;

    nbytes = vas_write(vas, dst, SvPV_nolen(sv), size);
    return nbytes;
}

void xs_vas_close(void* vas) {
    vas_close(vas);
}



