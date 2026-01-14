##########################################################################
## All portions of this code are copyright (c) 2003,2004 nethype GmbH   ##
##########################################################################
## Using, reading, modifying or copying this code requires a LICENSE    ##
## from nethype GmbH, Franz-Werfel-Str. 11, 74078 Heilbronn,            ##
## Germany. If you happen to have questions, feel free to contact us at ##
## license@nethype.de.                                                  ##
##########################################################################

=head1 NAME

PApp::XBox - papp execution environment for perl files

=head1 SYNOPSIS

 use PApp::XBox qw(domain=translation-domain);

=head1 DESCRIPTION

Unlike the real XBox, this module makes working anti-aliasing a reality!

Seriously, sometimes you want the normal PApp execution environment
in normal Perl modules. More often, you

=over 4

=cut

package PApp::XBox;

$VERSION = 2.4;

use PApp::PCode ();
use PApp::Util ();

1;

=back

=head1 SEE ALSO

L<PApp>.

=head1 AUTHOR

 Marc Lehmann <schmorp@schmorp.de>
 http://home.schmorp.de/

=cut

