# NAME

Mojo::SOAP::Client - Talk to SOAP Services mojo style

# SYNPOSYS

```perl
use Mojo::SOAP::Client;
use Mojo::File qw(curfile);
my $client = Mojo::SOAP::Client->new(
    wsdl => curfile->sibling('fancy.wsdl'),
    xsds => [ curfile->sibling('fancy.xsd')],
    port => 'FancyPort'
);

$client->call_p('getFancyInfo',{
    color => 'green'
})->then(sub { 
    my $answer = shift;
    my $trace = shift;
});
```

# DESCRIPTION

The Mojo::SOAP::Client is based on the [XML::Compile::SOAP](https://metacpan.org/pod/XML%3A%3ACompile%3A%3ASOAP)
family of packages, and especially on [XML::Compile::SOAP::Mojolicious](https://metacpan.org/pod/XML%3A%3ACompile%3A%3ASOAP%3A%3AMojolicious).

## Properties

The module provides the following properties to customize its behavior. Note that setting any properties AFTER using the `call` or `call_p` methods, will lead to undefined behavior.

### log

a pointer to a [Mojo::Log](https://metacpan.org/pod/Mojo%3A%3ALog) instance

### request\_timeout

How many seconds to wait for the soap server to respond. Defaults to 5 seconds.

### insecure

Set this to allow communication with a soap server that uses a 
self-signed or otherwhise invalid certificate.

### wsdl

Where to load the wsdl file from. At the moment this MUST be a file.

### xsds

A pointer to an array of xsd files to load for this service.

### port

If the wsdl file defines multiple ports, pick the one to use here.

### endPoint

The endPoint to talk to for reaching the SOAP service. This information
is normally encoded in the WSDL file, so you will not have to set this
explicitly.

### ca

The CA cert of the service. Only for special applications.

### cert

The client certificate to use when connecting to the soap service.

### key

The key matching the client cert.

### uaProperties

If special properties must be set on the UA you can set them here. For example a special authorization header was required, this would tbe the place to set it up.

```perl
my $client = Mojo::SOAP::Client->new(
    ...
    uaProperties => {
        header => HTTP::Headers->new(
           Authorization => 'Basic '. b64_encode("$user:$password","")
        })
    }
);
```

## Methods

The module provides the following methods.

### call\_p($operation,$params)

Call a SOAP operation with parameters and return a [Mojo::Promise](https://metacpan.org/pod/Mojo%3A%3APromise).

```perl
$client->call_p('queryUsers',{
   query => {
       detailLevels => {
           credentialDetailLevel => 'LOW',
           userDetailLevel => 'MEDIUM',
           userDetailLevel => 'LOW',
           defaultDetailLevel => 'EXCLUDE'
       },
       user => {
           loginId => 'aakeret'
       }
       numRecords => 100,
       skipRecords => 0,
   }
})->then(sub ($anwser,$trace) {
    print Dumper $answer
});
```

### call($operation,$paramHash)

The same as `call_p` but for syncronos applications. If there is a problem with the call it will raise a Mojo::SOAP::Exception which is a [Mojo::Exception](https://metacpan.org/pod/Mojo%3A%3AException) child.

# ACKNOLEDGEMENT

This is really just a very thin layer on top of Mark Overmeers great [XML::Compile::SOAP](https://metacpan.org/pod/XML%3A%3ACompile%3A%3ASOAP) module. Thanks Mark!

# AUTHOR

Tobias Oetiker, <tobi@oetiker.ch>

# COPYRIGHT

Copyright OETIKER+PARTNER AG 2019

# LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.10 or,
at your option, any later version of Perl 5 you may have available.
