use strict;
use warnings;

use lib qw(lib t/lib);
use Test::More tests => 3;
use MyElements::sayHello;

my $xml = <<'EOT';
<SOAP-ENV:Envelope xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xmlns:SOAP-ENV="http://schemas.xmlsoap.org/soap/envelope/" >
    <SOAP-ENV:Body>
        <sayHelloResponse xmlns="urn:HelloWorld">
            <sayHelloResult>Hello Adam</sayHelloResult>
        </sayHelloResponse>
    </SOAP-ENV:Body>
</SOAP-ENV:Envelope>
EOT

use_ok('SOAP::WSDL::Expat::MessageParser_XS');
use MyTypemaps::HelloWorld;
my $xs_parser = SOAP::WSDL::Expat::MessageParser_XS->new({
    class_resolver => 'MyTypemaps::HelloWorld',
});
my $result = $xs_parser->parse_string($xml);

is "$result", '<sayHelloResponse xmlns="urn:HelloWorld"><sayHelloResult>Hello Adam</sayHelloResult></sayHelloResponse>';
is $result->get_sayHelloResult(), 'Hello Adam';


__END__

cmpthese( 500, {
#        XML_Simple => sub {
#            push @result, XMLin($xml); 
#        },
        wsdl => sub {
            push @result, $wsdl_parser->parse_string($xml);
        },
        wsdl_xs => sub  {
            push @results,  $parser->parse_string($xml);
        },
        libxml_dom => sub {
            push @result, $libxml->parse_string($xml);
        },
        libxml_dom2hash => \&libxml_test,         
});

print $parser->parse_string($xml)->_DUMP;
#print $parser->parse_string($xml)->get_test->_DUMP;
@results = ();
