 use SOAP::Lite +trace;
 my $soap = SOAP::Lite->new( proxy => 'http://localhost:81/soap-wsdl-test/helloworld.pl');
 $soap->default_ns('urn:HelloWorld');
 my $som = $soap->call('sayHello',
    SOAP::Data->name('namre')->value('Kutter'),
    SOAP::Data->name('givenName')->value('Martin')
 );
 die $som->faultstring if ($som->fault);
 print $som->result, "\n";
