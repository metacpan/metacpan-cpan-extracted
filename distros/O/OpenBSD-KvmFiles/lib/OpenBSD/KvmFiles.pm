package OpenBSD::KvmFiles;

use warnings;
use strict;

=head1 NAME

OpenBSD::KvmFiles - OpenBSD kvm_getfiles.

=head1 VERSION

Version 0.02

=cut

use parent 'Exporter';
our @ISA = qw(Exporter);
our $VERSION = '0.02';
our @EXPORT = qw(KvmGetFilesAmount KvmGetFilesInfo);
require XSLoader;
XSLoader::load( 'OpenBSD::KvmFiles', $VERSION );

=head1 SYNOPSIS

Use kvm_getfiles to extract number of openend file of a process.

    use OpenBSD::KvmFiles;

    my $opened_file = KvmGetFilesAmount($pid);
    ...


# some const here to define
#define DTYPE_VNODE     1       /* file */
#define DTYPE_SOCKET    2       /* communications endpoint */
#define DTYPE_PIPE      3       /* pipe */
#define DTYPE_KQUEUE    4       /* event queue */
#define DTYPE_DMABUF    5       /* DMA buffer (for DRM) */

=head1 EXPORT

KvmGetFiles

=head1 SUBROUTINES/METHODS

=head2 KvmGetFilesAmount

Return the count of opened FD for a process or all if PID is -1

=cut

sub KvmGetFilesAmount {
    my $pid = int $_[0];
    return _fd_per_process($pid);
}

=head2 KvmGetFilesInfo

Return an array ref of opened FD for a process or all if PID = -1

[
 {
"type" => type of fd
"usecount" => referenced and use fd count
"read_bytes" => read bytes
"write_bytes" => written bytes
if type is a file (DTYPE_VNODE)
"path" =>  path of fd
 },...
]

=cut

sub KvmGetFilesInfo {
    my $pid = int $_[0];
    return _fd_info_per_process($pid);
}

=head1 AUTHOR

Dohnuts, C<< <dohnuts at no-reply.github.org> >>

=head1 BUGS

Please report any bugs or feature requests to https://github.com/systemVII/OpenBSD-KvmFiles/issues.
I will be notified, and then you'll automatically be notified of progress on your bug as I make changes.


=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc OpenBSD::KvmFiles


You can also look for information at:

=over 4

=item * github: a code repository

L<https://github.com/systemVII/OpenBSD-KvmFiles>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/OpenBSD-KvmFiles>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/OpenBSD-KvmFiles>

=item * Search CPAN

L<http://search.cpan.org/dist/OpenBSD-KvmFiles/>

=back


=head1 ACKNOWLEDGEMENTS


=head1 LICENSE AND COPYRIGHT

Copyright 2020 Dohnuts.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.


=cut

'I must not fear. Fear is the mind-killer...';
