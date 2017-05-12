#
# $Id: Util.pm,v 2.2 2005/07/16 03:21:35 ehood Exp $

package SGML::DTDParse::Util;

use strict;
use vars qw($VERSION $CVS @ISA @EXPORT_OK %EXPORT_TAGS);
use Exporter;

$VERSION = do { my @r=(q$Revision: 2.2 $=~/\d+/g); sprintf "%d."."%03d"x$#r,@r };
$CVS = '$Id: Util.pm,v 2.2 2005/07/16 03:21:35 ehood Exp $ ';

@ISA = qw(Exporter);
@EXPORT_OK = qw(
    entify
);
%EXPORT_TAGS = (
    ALL => qw(
	entify
    ),
);

#############################################################################

sub entify {
    my $str = shift;
    return undef  unless defined($str);
    $str =~ s/([&<>"])/sprintf("&#x%X;",ord($1))/ge;
    $str;
}

#############################################################################
1;

__END__

=head1 NAME

SGML::DTDParse::Util - DTDParse utility routines.

=head1 SYNOPSIS

  use SGML::DTDParse::Util;

  use SGML::DTDParse::Util qw(:ALL);

=head1 DESCRIPTION

B<SGML::DTDParse::Util> provides utility routines for DTDParse
modules and scripts.

=head1 ROUTINES

By default, no routines are exported into the user's namespace.
If importing is desired, individual routines can be specified in the
C<use> statement or the special tag C<:ALL> can be specified to import
all routines.

=over 4

=item entify

  $xml_str = entify($str);

Replace special characters with entity references.  The characters
converted are C<E<lt>>, C<E<gt>>, C<&>, and C<"> (double-quote).

=back

=head1 SEE ALSO

See L<SGML::DTDParse|SGML::DTDParse> for an overview of the DTDParse package.

=head1 AVAILABILITY

E<lt>I<http://dtdparse.sourceforge.net/>E<gt>

=head1 AUTHORS

Earl Hood, E<lt>earl@earlhood.comE<gt>.

=head1 COPYRIGHT AND LICENSE

See L<SGML::DTDParse|SGML::DTDParse> for copyright and license information.

