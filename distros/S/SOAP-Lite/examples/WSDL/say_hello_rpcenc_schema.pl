use SOAP::Lite;
my $soap = SOAP::Lite->service("file:say_hello_rpcenc.wsdl");
eval { my $result = $soap->sayHello('Kutter', 'Martin'); };
if ($@) {
    die $@;
}

print $som->result();
