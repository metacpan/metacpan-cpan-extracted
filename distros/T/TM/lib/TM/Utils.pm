package TM::Utils;

sub xmlify_hash {
    my $hash = shift;

    use XML::LibXML::SAX::Builder;
    my $builder = new XML::LibXML::SAX::Builder;
    use TM::Utils::TreeWalker;
    my $walker  = new TM::Utils::TreeWalker (Handler => $builder);
    $walker->walk ($hash);

    return $builder->result()->toString;
}

sub is_xml {
    my $s = shift;
    use XML::LibXML;
    my $parser = XML::LibXML->new();

    eval {
	my $doc = $parser->parse_string ($s);
    }; $@ ? 0 : 1;
}

our $VERSION  = '1.04';
our $REVISION = '$Id: Utils.pm,v 1.5 2006/11/13 08:02:33 rho Exp $';


1;
