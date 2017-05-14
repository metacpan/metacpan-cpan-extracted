# $Id: Session.pm 18 2008-05-05 23:55:18Z jabra $
package NexposeSimpleXML::Parser::Session;
{
    use Object::InsideOut;
    use XML::LibXML;
    use NexposeSimpleXML::Parser::ScanDetails;

    my @generated : Field : Arg(generated) : All(generated);
    my @scandetails : Field : Arg(scandetails) : Get(scandetails) :
        Type(NexposeSimpleXML::Parser::ScanDetails);

    sub parse {
        my ( $self, $parser, $doc ) = @_;

        foreach my $nx ( $doc->getElementsByTagName('NeXposeSimpleXML') ) {
            my $generated
                = scalar( @{ $nx->getElementsByTagName('generated') } ) > 0
                ? @{ $nx->getElementsByTagName('generated') }[0]
                ->textContent()
                : undef;
            return NexposeSimpleXML::Parser::Session->new(
                generated   => $generated,
                scandetails => NexposeSimpleXML::Parser::ScanDetails->parse(
                    $parser, $doc
                ),
            );
        }
    }
}
1;
