package Net::Amazon::S3::ACL::XMLHelper;

use warnings;
use strict;

use XML::LibXML;
use XML::LibXML::XPathContext;

use Exporter;
our @ISA       = qw( Exporter );
our @EXPORT_OK = qw( xpc );

our $Parser;

# Copied and adapted from Net::Amazon::S3
sub xpc {
   my ($content) = @_;

   my $parser = $Parser || XML::LibXML->new();
   my $doc = $parser->parse_string($content);
   my $xpc = XML::LibXML::XPathContext->new($doc);
   $xpc->registerNs('s3', 'http://s3.amazonaws.com/doc/2006-03-01/');

   return $xpc;
} ## end sub xpc

1;    # Magic true value required at end of module
__END__

=head1 NAME

Net::Amazon::S3::ACL::XMLHelper - XML-parsing helper functions

=head1 SYNOPSIS

   use Net::Amazon::S3::ACL::XMLHelper qw( xpc );

   my $xml; # populate with some XML
   my $xpc = xpc($xml); # returns a XML::LibXML::XPathContext object, with
                        # namespace 'http://s3.amazonaws.com/doc/2006-03-01/'
                        # registered as 's3'.


=head1 DESCRIPTION

This module only provides the L</xpc> helper function that is used by different modules
in this distribution. The implementation has been liberally taken from
L<Net::Amazon::S3>.

=head1 INTERFACE 

No function is exported by default.

=over

=item B<< xpc >>

   my $xpc = xpc( $some_xml );

Accepts a valid XML document as input, and returns a XML::LibXML::XPathContext object
back.

=back

The above function will allocate a L<XML::LibXML> object each time; if this is too much
waste for you, you can set a global L<XML::LibXML> object that will be used instead:

=over

=item B<< $Net::Amazon::S3::ACL::XMLHelper::Parser >>

   $Net::Amazon::S3::ACL::XMLHelper::Parser = XML::LibXML->new();

From when you set some value for this package variable, it will be used to perform
parsing operations. The interface must comply with that of L<XML::LibXML>.

=back

=head1 DEPENDENCIES

L<XML::LibXML> and L<XML::LibXML::XPathContext>.

=head1 AUTHORS

Original implementation taken from L<Net::Amazon::S3>; the function has been presumably
implemented by Leon Brocard <acme [at] astray [dot] com> or some other collaborator
of the original module.

Implementation adaptation and module packaging
by Flavio Poletti C<< <flavio [at] polettix [dot] it> >>

=head1 LICENCE AND COPYRIGHT

Copyright (c) 2008, Flavio Poletti C<< <flavio [at] polettix [dot] it> >>. All rights reserved.

This module is free software; you can redistribute it and/or
modify it under the same terms as Perl 5.8.x itself. See L<perlartistic>
and L<perlgpl>.

Questo modulo è software libero: potete ridistribuirlo e/o
modificarlo negli stessi termini di Perl 5.8.x stesso. Vedete anche
L<perlartistic> e L<perlgpl>.


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

=head1 NEGAZIONE DELLA GARANZIA

Poiché questo software viene dato con una licenza gratuita, non
c'è alcuna garanzia associata ad esso, ai fini e per quanto permesso
dalle leggi applicabili. A meno di quanto possa essere specificato
altrove, il proprietario e detentore del copyright fornisce questo
software "così com'è" senza garanzia di alcun tipo, sia essa espressa
o implicita, includendo fra l'altro (senza però limitarsi a questo)
eventuali garanzie implicite di commerciabilità e adeguatezza per
uno scopo particolare. L'intero rischio riguardo alla qualità ed
alle prestazioni di questo software rimane a voi. Se il software
dovesse dimostrarsi difettoso, vi assumete tutte le responsabilità
ed i costi per tutti i necessari servizi, riparazioni o correzioni.

In nessun caso, a meno che ciò non sia richiesto dalle leggi vigenti
o sia regolato da un accordo scritto, alcuno dei detentori del diritto
di copyright, o qualunque altra parte che possa modificare, o redistribuire
questo software così come consentito dalla licenza di cui sopra, potrà
essere considerato responsabile nei vostri confronti per danni, ivi
inclusi danni generali, speciali, incidentali o conseguenziali, derivanti
dall'utilizzo o dall'incapacità di utilizzo di questo software. Ciò
include, a puro titolo di esempio e senza limitarsi ad essi, la perdita
di dati, l'alterazione involontaria o indesiderata di dati, le perdite
sostenute da voi o da terze parti o un fallimento del software ad
operare con un qualsivoglia altro software. Tale negazione di garanzia
rimane in essere anche se i dententori del copyright, o qualsiasi altra
parte, è stata avvisata della possibilità di tali danneggiamenti.

Se decidete di utilizzare questo software, lo fate a vostro rischio
e pericolo. Se pensate che i termini di questa negazione di garanzia
non si confacciano alle vostre esigenze, o al vostro modo di
considerare un software, o ancora al modo in cui avete sempre trattato
software di terze parti, non usatelo. Se lo usate, accettate espressamente
questa negazione di garanzia e la piena responsabilità per qualsiasi
tipo di danno, di qualsiasi natura, possa derivarne.

=head1 SEE ALSO

L<Net::Amazon::S3> and L<Net::Amazon::S3::ACL>.

=cut
