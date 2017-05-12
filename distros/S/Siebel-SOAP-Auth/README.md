# siebel-soap-auth
Moo based class to implement transparent Siebel Session Management for XML::Compile::WSDL11

Siebel::SOAP::Auth implements authentication for Oracle's Siebel inbound webservices by implementing Session Management.

Session Management is implemented by using a instance of Siebel::SOAP::Auth inside a transport_hook sub, passing to it the original request. The original request will
be modified, adding necessary authentication data to the SOAP Header. The instance of Siebel::SOAP::Auth will also try to manage the session and token expiration times and
request a new one before expiration, avoiding a new round-trip to the server for another successful request.

Session Management for calling Siebel web services great improves speed, since regular authentication takes a loot of additional steps. This class will implement the management
of requesting tokens automatically (but some tuning with the parameters might be necessary).

This class is tight coupled to XML::Compile::WSDL11 interface. By using it, it is expected that you will use everything else from XML::Compile.

This class is a Moo class and it uses also Log::Report to provide debug information if required.

Check the distribution Pod for more details.
