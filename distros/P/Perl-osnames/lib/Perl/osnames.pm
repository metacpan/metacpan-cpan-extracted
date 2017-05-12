package Perl::osnames;

our $DATE = '2014-12-19'; # DATE
our $VERSION = '0.11'; # VERSION

use strict;
use warnings;

use Exporter qw(import);
our @EXPORT_OK = qw($data is_unix is_posix);

our $data = [map {
    chomp;
    my @f = split /\s+/, $_, 3;
    $f[1] = $f[1] eq '-' ? [] : [split /,/, $f[1]];
    \@f;
} split /^/m, <<'_'];
aix          posix,sysv,unix   IBM AIX.
amigaos      -
android      sysv,unix
bsdos        bsd,unix          BSD/OS. Originally called BSD/386, also known as BSDi.
beos         posix             See also: haiku.
bitrig       bsd,unix          An OpenBSD fork.
dgux         sysv,unix         DG/UX.
dos          -
dynixptx     sysv,unix         DYNIX/ptx.
cygwin       posix,unix        Unix-like emulation layer that runs on Windows.
darwin       bsd,posix,unix    Mac OS X. Does not currently (2013) include iOS. See also: iphoneos.
dec_osf      -                 DEC Alpha.
dragonfly    bsd,posix,unix    DragonFly BSD.
freebsd      bsd,posix,unix
gnukfreebsd  bsd,posix,unix    Debian GNU/kFreeBSD.
haiku        posix             See also: beos.
hpux         posix,sysv,unix   HP-UX.
interix      posix,unix        Optional, POSIX-compliant Unix subsystem for Windows NT. Also known as Microsoft SFU. No longer included in Windows nor supported.
irix         posix,sysv,unix
linux        posix,sysv,unix
MacOS        -                 Mac OS Classic (predates Mac OS X). See also: darwin, iphoneos.
machten      bsd,unix          MachTen, an operating system that runs virtually under Mac OS.
midnightbsd  bsd,posix,unix
minix        bsd,posix
mirbsd       bsd,posix,unix    MirOS BSD.
mpeix        -                 MPEiX.
MSWin32      -                 All Windows platforms including 95/98/ME/NT/2000/XP/CE/.NET. But does not include Cygwin (see "cygwin") or Interix (see "interix"). To get more details on which Windows you are on, use Win32::GetOSName() or Win32::GetOSVersion(). Ref: perlvar.
netbsd       bsd,posix,unix
next         unix              NeXTSTEP OS.
nto          unix              ?
openbsd      bsd,posix,unix
os390        ebcdic
os400        ebcdic
posix-bc     ebcdic
qnx          unix
riscos       -
sco          posix,sysv,unix   SCO UNIX.
solaris      posix,sysv,unix   This includes the old SunOS.
vmesa        ebcdic
vms          -
vos          -
_

# dump: display data as table
#use Data::Format::Pretty::Text qw(format_pretty);
#say format_pretty($data, {
#    table_column_formats=>[{description=>[[wrap=>{columns=>40}]]}],
#    table_column_orders=>[[qw/code summary description/]],
#});

# debug: dump data
#use Data::Dump::Color;
#dd $data;

sub is_posix {
    my $os = shift || $^O;
    for my $rec (@$data) {
        next unless $rec->[0] eq $os;
        for (@{$rec->[1]}) {
            return 1 if $_ eq 'posix';
        }
        return 0;
    }
    undef;
}

sub is_unix {
    my $os = shift || $^O;
    for my $rec (@$data) {
        next unless $rec->[0] eq $os;
        for (@{$rec->[1]}) {
            return 1 if $_ eq 'unix';
        }
        return 0;
    }
    undef;
}

1;
# ABSTRACT: List possible $^O ($OSNAME) values, with description

__END__

=pod

=encoding UTF-8

=head1 NAME

Perl::osnames - List possible $^O ($OSNAME) values, with description

=head1 VERSION

This document describes version 0.11 of Perl::osnames (from Perl distribution Perl-osnames), released on 2014-12-19.

=head1 DESCRIPTION

This package contains C<$data> which lists possible values of C<$^O> along with
description for each. It also provides some helper functions.

=head2 Tags

=over

=item * unix

Unix-like operating systems. This currently excludes beos/haiku.

=item * bsd

BSD-derived Unix operating systems.

=item * sysv

SysV-derived Unix operating systems.

=item * posix

For POSIX-compliant OSes, including fully-, mostly-, and largely-compliant ones
(source: L<http://en.wikipedia.org/wiki/POSIX>).

From what I can gather, dec_osf is not POSIX compliant, although there is a
posix package for it.

=back

=head1 VARIABLES

None are exported by default, but they are exportable.

=head2 C<$data>

An arrayref of records (arrayrefs), each structured as:

 [$name, \@tags, $description]

=head1 FUNCTIONS

None are exported by default, but they are exportable.

=head2 is_posix([ $os ]) => bool

Check whether C<$os> (defaults to C<$^O> if not specified) is POSIX (checked by
the existence of C<posix> tag on the OS's record in C<$data>). Will return 0, 1,
or undef if C<$os> is unknown.

=head2 is_unix([ $os ]) => bool

Check whether C<$os> (defaults to C<$^O> if not specified) is Unix (checked by
the existence of C<unix> tag on the OS's record in C<$data>). Will return 0, 1,
or undef if C<$os> is unknown.

=head1 SEE ALSO

L<perlvar>

L<Config>

L<Perl::OSType>, a core module. You should probably use this module instead.
Currently the difference between this module and Perl::osnames: 1) Perl::osnames
currently doesn't list beos/haiku as Unix, but POSIX; 2) Perl::osnames provides
more tags (like sysv, bsd, posix) and description.

L<Devel::Platform::Info>

The output of C<perl -V>

L<App::osnames>, the original reason for Perl::osnames. With this CLI tool you
can grep OS names by name, tag, or description, e.g. C<osnames solaris> or
C<osnames posix>.

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Perl-osnames>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Perl-osnames>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Perl-osnames>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2014 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
