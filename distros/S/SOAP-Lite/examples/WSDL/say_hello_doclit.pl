 use SOAP::Lite +trace;
 my $soap = SOAP::Lite->new( proxy => 'http://localhost:80/helloworld.pl');

 $soap->on_action( sub { "urn:HelloWorld#sayHello" });
 $soap->autotype(0)->readable(1);
 $soap->default_ns('urn:HelloWorld');

 my $som = $soap->call("sayHello",
    SOAP::Data->name('name')->value( 'Kutter' ),
    SOAP::Data->name('givenName')->value('Martin'),
);

 die $som->fault->{ faultstring } if ($som->fault);
 print $som->result, "\n";
