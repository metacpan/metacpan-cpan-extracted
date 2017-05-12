package Module::Release::Twitter;

use 5.008001;
use strict;
use warnings;
use parent qw(Exporter);
use Net::Twitter 3.04006;
use English qw( -no_match_vars );

our @EXPORT = qw(twit_upload twit_password);

our $VERSION = '0.101';
$VERSION = eval { return $VERSION };

=head1 NAME

Module::Release::Twitter - Twitter the module upload

=head1 DESCRIPTION

The release-csjewell script will automatically load this module if it 
thinks that you want to announce your module on Twitter.

=head1 SYNOPSIS

    use Module::Release '2.00_04';

    # ...
    $release->load_mixin( 'Module::Release::Twitter' );
    $release->twit_password;
    # ...
    last if $release->debug;

    # ...
    $release->twit_upload;

=head1 INTERFACE

=over 4

=item twit_upload

Announces your upload to the Twitter account specified.

=cut

sub twit_upload {
	my $self = shift;

	my $local_file = $self->local_file;
	my $twit_user  = $self->config->twit_user();
	return unless $twit_user;

	my $twit_password = $self->config->twit_pass();

	my $string = "Uploaded $local_file to CPAN - "
	  . 'find it on your local mirror in a few hours! #perl';

	$self->_print("Twitter: $string\n");

	$self->_debug("Twitter: User: $twit_user Password: $twit_password\n");
	$self->_debug("Net::Twitter: Version: $Net::Twitter::VERSION\n");

	my $twit = Net::Twitter->new(
		traits   => [qw(API::REST)],
		username => $twit_user,
		password => $twit_password,
	);

	eval { $twit->update($string) };
	if ($EVAL_ERROR) {
		$self->_print("Could not Twitter because: $EVAL_ERROR\n");
	}

	return;
} ## end sub twit_upload

=item twit_upload

Retrieves the password for the Twitter account specified.

=cut

sub twit_password {
	my $self = shift;
	my $pass;

	if (   $pass = $self->config->twit_pass()
		|| $self->get_env_var('TWITTER_PASS') )
	{
		$self->config->set( 'twit_pass', $pass );
	}

	return;
} ## end sub twit_password

=back

=head1 SEE ALSO

L<Module::Release>

=head1 SOURCE AVAILABILITY

This source is on the Open Repository:

	L<http://svn.ali.as/cpan/trunk/Module-Release-CSJEWELL/>

=head1 CONFIGURATION AND ENVIRONMENT

=head2 .releaserc or releaserc file

These two entries are read from the releaserc file to configure what 
Twitter user announces uploading the file:

    twit_user username
    twit_pass password

These entries set the username and password to use on twitter.com.

The twit_user entry must be in the releaserc file, or L</twit_upload> 
will return without announcing the uploading of the file.

=head2 Environment

The TWITTER_PASS environment variable can be used instead of the 
"twit_pass" variable, so that the releaserc file does not contain a
password.

If neither the twit_pass releaserc entry nor the environment variable
was set, then the twit_password routine will request the password from the
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
