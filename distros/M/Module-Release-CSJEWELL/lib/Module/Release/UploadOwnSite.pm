package Module::Release::UploadOwnSite;

use 5.006001;
use strict;
use warnings;
use parent qw(Exporter);

our @EXPORT = qw(ownsite_upload ownsite_password);

our $VERSION = '0.101';
$VERSION = eval { return $VERSION };

=head1 NAME

Module::Release::UploadOwnSite - Upload to personal site

=head1 DESCRIPTION

The release-csjewell script will automatically load this module if it thinks that you
want to upload to your own site.

=head1 SYNOPSIS

    use Module::Release '2.00_04';

    # ...
    $release->load_mixin( 'Module::Release::UploadOwnSite' );
    $release->ownsite_password;
    # ...
    last if $release->debug;

    # ...
    $release->ownsite_upload;

=head1 INTERFACE

=over 4

=item ownsite_upload

Looks in local_name to get the name and version of the distribution file.

=cut

sub ownsite_upload {
	my $self = shift;

	my $host = $self->config->ownsite_ftp_host();
	return unless $host;

	my $user = $self->config->ownsite_ftp_user();
	return unless $user;

	my $dir = $self->config->ownsite_ftp_upload_dir();
	return unless $dir;

	my $password = $self->config->ownsite_ftp_pass();
	return unless $password;

	my $local_file = $self->local_file;

	$self->_print("Now uploading to $host\n");

	$self->ftp_upload(
		user       => $user,
		password   => $password,
		upload_dir => $dir,
		hostname   => $host,
	);

	return;
} ## end sub ownsite_upload

sub ownsite_password {
	my $self = shift;
	my $pass;

	if (   $pass = $self->config->ownsite_ftp_pass()
		|| $self->get_env_var('FTP_PASS') )
	{
		$self->config->set( 'ownsite_ftp_pass', $pass );
	}

	return;
} ## end sub ownsite_password

=back

=head1 SEE ALSO

L<Module::Release>

=head1 SOURCE AVAILABILITY

This source is on the Open Repository:

	L<http://svn.ali.as/cpan/trunk/Module-Release-CSJEWELL/>

=head1 CONFIGURATION AND ENVIRONMENT

=head2 .releaserc or releaserc file

These four entries are read from the releaserc file to configure where 
the file is uploaded:

    ownsite_ftp_host ftp.host.invalid
    ownsite_ftp_user ftpusername
    ownsite_ftp_pass ftppassword
    ownsite_ftp_upload_dir /public_html/perl

These entries set what host the file is uploaded to, the username and 
password to use, and the directory on the host to upload it to, respectively.

All entries, except the ownsite_ftp_pass one, must be in the releaserc file, 
or L</ownsite_upload> will return without uploading the file.

=head2 Environment

The FTP_PASS environment variable can be used instead of the 
"ownsite_ftp_pass" variable, so that the releaserc file does not contain a
password.

If neither the ownsite_ftp_pass releaserc entry nor the environment variable
was set, then the ownsite_password routine will request the password from the
console.

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
