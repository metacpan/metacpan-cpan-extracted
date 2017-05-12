package Sys::Sendfile;
$Sys::Sendfile::VERSION = '0.16';
# This software is copyright (c) 2008, 2009 by Leon Timmermans <leont@cpan.org>.
#
# This is free software; you can redistribute it and/or modify it under
# the same terms as perl itself.

use strict;
use warnings;

use Exporter 5.57 'import';
use XSLoader;

##no critic ProhibitAutomaticExportation
our @EXPORT = qw/sendfile/;

XSLoader::load('Sys::Sendfile', __PACKAGE__->VERSION);

1;

# ABSTRACT: Zero-copy data transfer

__END__

=pod

=head1 NAME

Sys::Sendfile - Zero-copy data transfer

=head1 VERSION

version 0.16

=head1 SYNOPSIS

 use Sys::Sendfile;
 sendfile $sink, $source, $count;

=head1 DESCRIPTION

Sys::Sendfile provides access to your operating system's C<sendfile> facility. It allows you to efficiently transfer data from one filehandle to another. Typically the source is a file on disk and the sink is a socket, and some operating systems may not even support other usage.

=head1 FUNCTIONS

=head2 sendfile $out, $in, $count, $offset

This function sends up to C<$count> B<bytes> starting from C<$offset> from C<$in> to C<$out>. If $count isn't given, it will try send all remaining bytes in $in, but on some operating systems sending only part of the bytes is a possible result. If C<$offset> isn't given, the function will get current offset of C<$in> (by calling lseek) and pass this information to underlying sendfile syscall. C<$in> and C<$out> can be a bareword, constant, scalar expression, typeglob, or a reference to a typeglob. It returns the number of bytes actually sent. On error, C<$!> is set appropriately and it returns undef. This function is exported by default.

=head1 BUGS AND LIMITATIONS

Not all operating systems support sendfile(). Currently Linux, FreeBSD, Solaris, Mac OS X (version 10.5 and up) and Windows are supported.

=head1 SEE ALSO

sendfile(2) - Your manpage on sendfile

L<IO::Sendfile> - A sendfile implementation for Linux

L<Sys::Syscall> - Another sendfile implementation for Linux

L<Sys::Sendfile::FreeBSD> - A module implementing the FreeBSD variant of sendfile 

=head1 AUTHOR

Leon Timmermans <leont@cpan.org>

=head1 CONTRIBUTORS

Kazuho Oku C<< <kazuhooku@gmail.com> >> wrote the Mac OS X code.

Yasuhiro Matsumoto C<< <mattn.jp@gmail.com> >> wrote the Win32 code.

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2008 by Leon Timmermans.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
