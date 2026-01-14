##########################################################################
## All portions of this code are copyright (c) 2003,2004 nethype GmbH   ##
##########################################################################
## Using, reading, modifying or copying this code requires a LICENSE    ##
## from nethype GmbH, Franz-Werfel-Str. 11, 74078 Heilbronn,            ##
## Germany. If you happen to have questions, feel free to contact us at ##
## license@nethype.de.                                                  ##
##########################################################################

=head1 NAME

PApp::Preprocessor - preprocess source like "pxml"

=head1 SYNOPSIS

 use PApp::Preprocessor;

 :><html><title><?localtime:></title><:...

=head1 DESCRIPTION

Importing this module preprocesses perl source files using C<pxml2pcode>
(see L<PApp::PCode>), using a source filter.

Preprocessing is only one part of papp processing - C<%S>, translations
and others need to be imported/initialized seperately.

After C<use PApp::Preprocessor>, the source is still in perl mode, but can
be switched to literal text mode using :>, and switched back to perl using
<:.

=over 4

=cut

package PApp::Preprocessor;

$VERSION = 2.4;

use PApp::PCode ();
use PApp::Util ();

sub import {
   PApp::Util::filter_add PApp::Util::filter_simple {
      $_ = PApp::PCode::pcode2perl PApp::PCode::pxml2pcode "<:$_";
   };
}

1;

=back

=head1 SEE ALSO

L<PApp::PCode>.

=head1 AUTHOR

 Marc Lehmann <schmorp@schmorp.de>
 http://home.schmorp.de/

=cut

