package Sys::GetRandom::FFI;

# ABSTRACT: get random bytes from the system

use v5.20;
use warnings;

use Exporter qw( import );
use FFI::Platypus 2.00;

use experimental qw( signatures );

use constant GRND_NONBLOCK => 0x0001;
use constant GRND_RANDOM   => 0x0002;

our @EXPORT_OK = qw( GRND_RANDOM GRND_NONBLOCK getrandom );

our $VERSION = 'v0.1.0';


sub getrandom( $size, $opts = 0 ) {

    state $ffi = FFI::Platypus->new(
        api => 2,
        lib => undef,    # libc
    );

    state $random = $ffi->function( getrandom => [ 'string', 'size_t', 'int' ] => 'size_t' );

    my $buffer = "\0" x $size;
    my $res    = $random->call( $buffer, $size, $opts );

    return $res != -1 ? $buffer : undef;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Sys::GetRandom::FFI - get random bytes from the system

=head1 VERSION

version v0.1.0

=head1 SYNOPSIS

  use Sys::GetRandom::FFI qw( getrandom GRND_RANDOM GRND_NONBLOCK );

  my $bytes = getrandom( $size, GRND_RANDOM | GRND_NONBLOCK );
  if ( defined($bytes) ) {
     ...
  }

=head1 DESCRIPTION

This is a proof-of-concept module for calling the L<getrandom(2)> system function via L<FFI::Platypus>.

=head1 EXPORTS

=head2 GRND_RANDOM

When this bit is set, it will read from F</dev/random> instead of F</dev/urandom>.

=head2 GRND_NONBLOCK

This will exit with C<undef> when there are no random bytes available.

=head2 getrandom

  my $bytes = getrandom( $size, $options );

This will return a scalar of up to C<$size> bytes, or C<undef> if there was an error.

It may return less than C<$size> bytes if L</GRND_RANDOM> was given as an option and there was less entropy or or if the
entropy pool has not been initialised, or if it was interrupted by a signal when C<$size> is over 256.

The C<$options> are optional.

=head1 SEE ALSO

=over 4

=item L<getrandom(2)>

=item L<Sys::GetRandom>

This is an XS module that calls L<getrandom(2)> directly.  It has a slightly different interface but is faster.

=item L<Rand::URandom>

This is a pure-Perl module that makes syscalls to L<getrandom(2)>, but falls back to reading from F</dev/urandom>.

=item L<Crypt::URandom>

This is a pure-Perl module that reads data from F</dev/urandom>. It also uses L<Win32::API> to read random bytes on
Windows.

=back

=head1 SUPPORT FOR OLDER PERL VERSIONS

This module requires Perl v5.20 or later.

Future releases may only support Perl versions released in the last ten (10) years.

=head1 SOURCE

The development version is on github at L<https://github.com/robrwo/perl-Sys-GetRandom-FFI>
and may be cloned from L<git://github.com/robrwo/perl-Sys-GetRandom-FFI.git>

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website
L<https://github.com/robrwo/perl-Sys-GetRandom-FFI/issues>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head2 Reporting Security Vulnerabilities

Security issues should not be reported on the bugtracker website. Please see F<SECURITY.md> for instructions how to
report security vulnerabilities

=head1 AUTHOR

Robert Rothenberg <rrwo@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2024 by Robert Rothenberg <rrwo@cpan.org>.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut
