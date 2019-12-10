<div>
    ![](https://github.com/oposs/mojolicious-plugin-soap-server/workflows/Unit%20Tests/badge.svg?branch=master)
</div>

# NAME

Mojolicious::Plugin::SOAP::Server - implement a SOAP service

# SYNOPSIS

```perl
use Mojolicious::Lite;
use Mojo::File 'curfile';

plugin 'SOAP::Server' => {
   wsdl => curfile->sibling('nameservice.wsdl'),
   xsds => [curfile->sibling('nameservice.xsd')],
   controller => SoapCtrl->new(x => '1'),
   endPoint => '/SOAP'
};

app->start;

package SoapCtrl;

use Mojo::Base -base,-signatures;

has 'x' => 2;

sub getCountries ($self,$server,$params,$controller) {
   return {
       country => [qw(Switzerland Germany), $self->x]
   };
}

sub getNamesInCountry ($self,$server,$params,$controller) {
   my $name = $params->{parameters}{country};
   $controller->log->debug("Test Message");
   if ($name eq 'Die') {
       die {
           status => 401,
           text => 'Unauthorized'
       };
   }
   return {
       name => [qw(A B C),$name]
   };
}
```

# DESCRIPTION

The [Mojolicious::Plugin::SOAP::Server](https://metacpan.org/pod/Mojolicious%3A%3APlugin%3A%3ASOAP%3A%3AServer) is a thin wrapper around [XML::Compile::SOAP::Daemon](https://metacpan.org/pod/XML%3A%3ACompile%3A%3ASOAP%3A%3ADaemon) which makes it pretty simple to implement SOAP services in perl.

The plugin supports the following configuration options:

- wsdl

    A wsdl filename with definitions for the services provided

- xsds

    An array pointer with xsd files for the data types used in the wsdl.

- controller

    A mojo Object whose methods match the service names defined in the wsdl file.

    ```perl
    sub methodName ($self,$server,$params,$controller) {
    ```

    see example folder for inspiration.

- default\_cb

    A default callback to be called if the requested method does not exist in the controller.

- endPoint

    Where to 'mount' the SOAP service.

# ACKNOWLEDGEMENT

This is really just a very thin layer on top of Mark Overmeers great [XML::Compile::SOAP::Daemon](https://metacpan.org/pod/XML%3A%3ACompile%3A%3ASOAP%3A%3ADaemon) module. Thanks Mark!

# AUTHOR

Tobias Oetiker, <tobi@oetiker.ch>

# COPYRIGHT

Copyright OETIKER+PARTNER AG 2019

# LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.10 or,
at your option, any later version of Perl 5 you may have available.
