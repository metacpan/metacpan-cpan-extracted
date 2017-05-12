package Module::Release::OpenRepository;

use 5.006001;
use strict;
use warnings;
use parent qw(Exporter);

our @EXPORT = qw(open_upload);

our $VERSION = '0.101';
$VERSION = eval { return $VERSION };

=head1 NAME

Module::Release::OpenRepository - Import release into the Open Repository.

=head1 DESCRIPTION

The release-csjewell script will automatically load this module if it thinks that you
want to upload to the Open Repository at http://svn.ali.as/.

=head1 SYNOPSIS

    use Module::Release '2.00_04';

    # ...
    $release->load_mixin( 'Module::Release::OpenRepository' );
    # ...
    last if $release->debug;

    # ...
	$release->open_upload;

=head1 INTERFACE

=over 4

=item open_upload

Looks in local_name to get the name and version of the distribution file.

=cut

sub open_upload {
	my $self = shift;

	my $no_upload = $self->config->openrepository_noupload || 0;
	return if $no_upload;

	my $local_file  = $self->local_file;
	my $remote_file = "http://svn.ali.as/cpan/releases/$local_file";
	my $bot_name    = $self->config->upload_bot_name
	  || 'Module::Release::OpenRepository';
	my ( $release, $version ) =
	  $self->local_file =~ m/([\w-]+)-([\d_\.]+).tar.gz/msx;
	$release =~ s/-/::/gms;
	my $message = "[$bot_name] Importing upload file for $release $version";

	$self->_print("Committing release file to OpenRepository.\n");
	$self->_debug("Commit Message: $message\n");
	$self->run(qq(svn import $local_file $remote_file -m "$message" 2>&1));

	return;
} ## end sub open_upload

=back

=head1 SEE ALSO

L<Module::Release>

=head1 SOURCE AVAILABILITY

This source is on the Open Repository:

    L<http://svn.ali.as/cpan/trunk/Module-Release-CSJEWELL/>

=head1 CONFIGURATION AND ENVIRONMENT

=head2 .releaserc or releaserc file

These two entries are read from the releaserc file to configure whether 
the file is imported into the repository or not, and what bot :

    openrepository_noupload 1
	upload_bot_name CSJewell_bot

If openrepository_noupload is true, importing the distribution file will
be skipped.

upload_bot_name will default to "Module::Release::OpenRepository" if not 
set, and will be used along with the distribution name and version to create 
the commit message.

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
