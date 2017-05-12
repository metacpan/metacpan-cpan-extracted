package Module::Release::PermissionFix;

use 5.006001;
use strict;
use warnings;
use parent qw(Exporter);
use Archive::Tar;
use Carp qw(croak);

our @EXPORT = qw(fix_permission);

our $VERSION = '0.101';
$VERSION = eval { return $VERSION };

=head1 NAME

Module::Release::PermissionFix - Fixes the permissions on .tar.gz files.

=head1 DESCRIPTION

The release-csjewell script will automatically load this module in order 
to make sure that the permissions on the file uploaded are correct and 
PAUSE will be able to index it.

The reason for this module is that .tar files created on Windows often have
permissions that are insane on Unix systems. PAUSE checks for those, and will
not index them.

=head1 SYNOPSIS

    use Module::Release '2.00_04';

    # ...
    $release->dist; # Needs to be after the last execution of this line.
    # ...
    $release->load_mixin( 'Module::Release::PermissionFix' );
    $release->fix_permission();

=head1 INTERFACE

=over 4

=item fix_permission

Fixes the permissions on the distribution file (0444 becomes 0664, and 
0555 becomes 0755).

=cut

sub fix_permission {
	my $self = shift;

	local $Archive::Tar::DO_NOT_USE_PREFIX = 1;

	my $dist = $self->local_file;

	##no critic (ProhibitMagicNumbers ProhibitLeadingZeros)

	my $fixes;
	my $tar = Archive::Tar->new;
	$tar->read($dist);
	my @files = $tar->get_files;
	foreach my $file (@files) {
		my $fixedmode = my $mode = $file->mode;
		my $filetype = q{};
		if ( $file->is_file ) {
			$filetype = 'file';
			if ( substr( ${ $file->get_content_by_ref }, 0, 2 ) eq q{#!} ) {
				$fixedmode = 0775;
			} else {
				$fixedmode = 0664;
			}
		} elsif ( $file->is_dir ) {
			$filetype  = 'dir';
			$fixedmode = 0775;
		} else {
			next;
		}
		next if $mode eq $fixedmode;
		$file->mode($fixedmode);
		$fixes++;
		$self->_debug( sprintf "Change mode %03o to %03o for %s '%s'\n",
			$mode, $fixedmode, $filetype, $file->name );
	} ## end foreach my $file (@files)

	if ($fixes) {
		rename $dist, "$dist.bak"
		  or croak "Cannot rename file '$dist' to '$dist.bak': $!";
		$tar->write( $dist, 9 );
		$self->_print("Permissions fixed: $dist.\n");
	} else {
		$self->_print("Permissions didn't need fixed: $dist.\n");
	}

	return;
} ## end sub fix_permission


=back

=head1 SEE ALSO

L<Module::Release>

=head1 SOURCE AVAILABILITY

This source is on the Open Repository:

	L<http://svn.ali.as/cpan/trunk/Module-Release-CSJEWELL/>

=head1 AUTHOR

Curtis Jewell, C<< <csjewell@cpan.org> >>

=head1 LICENSE AND COPYRIGHT

Copyright (c) 2009, Curtis Jewell C<< <csjewell@cpan.org> >>. All rights reserved.

This module is free software; you can redistribute it and/or
modify it under the same terms as Perl itself, either version
5.8.1 or any later version. See L<perlartistic> and L<perlgpl>.

The full text of the license can be found in the
LICENSE file included with this module.

=head1 DISCLAIMER OF WARRANTY

BECAUSE THIS SOFTWARE IS LICENSED FREE OF CHARGE, THERE IS NO WARRANTY
FOR THE SOFTWARE, TO THE EXTENT PERMITTED BY APPLICABLE LAW. EXCEPT WHEN
OTHERWISE STATED IN WRITING THE COPYRIGHT HOLDERS AND/OR OTHER PARTIES
PROVIDE THE SOFTWARE "AS IS" WITHOUT WARRANTY OF ANY KIND, EITHER
EXPRESSED OR IMPLIED, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE. THE
ENTIRE RISK AS TO THE QUALITY AND PERFORMANCE OF THE SOFTWARE IS WITH
YOU. SHOULD THE SOFTWARE PROVE DEFECTIVE, YOU ASSUME THE COST OF ALL
NECESSARY SERVICING, REPAIR, OR CORRECTION.

IN NO EVENT UNLESS REQUIRED BY APPLICABLE LAW OR AGREED TO IN WRITING
WILL ANY COPYRIGHT HOLDER, OR ANY OTHER PARTY WHO MAY MODIFY AND/OR
REDISTRIBUTE THE SOFTWARE AS PERMITTED BY THE ABOVE LICENCE, BE
LIABLE TO YOU FOR DAMAGES, INCLUDING ANY GENERAL, SPECIAL, INCIDENTAL,
OR CONSEQUENTIAL DAMAGES ARISING OUT OF THE USE OR INABILITY TO USE
THE SOFTWARE (INCLUDING BUT NOT LIMITED TO LOSS OF DATA OR DATA BEING
RENDERED INACCURATE OR LOSSES SUSTAINED BY YOU OR THIRD PARTIES OR A
FAILURE OF THE SOFTWARE TO OPERATE WITH ANY OTHER SOFTWARE), EVEN IF
SUCH HOLDER OR OTHER PARTY HAS BEEN ADVISED OF THE POSSIBILITY OF
SUCH DAMAGES.

=cut

1;
