# $Id: Session.pm 142 2009-10-16 19:13:45Z jabra $
package Nikto::Parser::Session;
{
    our $VERSION = '0.01';
    $VERSION = eval $VERSION;

    use Object::InsideOut;
    use XML::LibXML;
    use Nikto::Parser::ScanDetails;

    my @options : Field : Arg(options) : All(options);
    my @version : Field : Arg(version) : All(version);
    my @nxmlversion : Field : Arg(nxmlversion) : All(nxmlversion);
    my @scandetails : Field : Arg(scandetails) : Get(scandetails) :
        Type(Nikto::Parser::ScanDetails);

    sub parse {
        my ( $self, $parser, $doc ) = @_;

        foreach my $niktoscan ( $doc->getElementsByTagName('niktoscan') ) {
            return Nikto::Parser::Session->new(
                options     => $niktoscan->getAttribute('options'),
                version     => $niktoscan->getAttribute('version'),
                nxmlversion => $niktoscan->getAttribute('nxmlversion'),
                scandetails =>
                    Nikto::Parser::ScanDetails->parse( $parser, $doc ),
            );
        }
    }

}
1;
