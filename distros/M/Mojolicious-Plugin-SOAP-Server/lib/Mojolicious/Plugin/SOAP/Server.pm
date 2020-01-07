package Mojolicious::Plugin::SOAP::Server;

=pod

=begin markdown

![](https://github.com/oposs/mojolicious-plugin-soap-server/workflows/Unit%20Tests/badge.svg?branch=master)

=end markdown

=head1 NAME

Mojolicious::Plugin::SOAP::Server - implement a SOAP service

=head1 SYNOPSIS

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

=head1 DESCRIPTION

The L<Mojolicious::Plugin::SOAP::Server> is a thin wrapper around L<XML::Compile::SOAP::Daemon> which makes it pretty simple to implement SOAP services in perl.

The plugin supports the following configuration options:

=over

=item wsdl

A wsdl filename with definitions for the services provided

=item xsds

An array pointer with xsd files for the data types used in the wsdl.

=item controller

A mojo Object whose methods match the service names defined in the wsdl file.

 sub methodName ($self,$server,$params,$controller) {

see example folder for inspiration.

=item default_cb

A default callback to be called if the requested method does not exist in the controller.

=item endPoint

Where to 'mount' the SOAP service.

=back

=cut

use Mojo::Base 'Mojolicious::Plugin', -signatures;

use XML::Compile::WSDL11;
use XML::Compile::SOAP11;
use XML::Compile::SOAP12;
use XML::Compile::SOAP::Daemon::CGI;
use Mojo::Util qw(dumper);
our $VERSION = '0.1.4';
use Carp qw(carp croak);

has wsdl => sub ($self) {
    XML::Compile::WSDL11->new;
};

has daemon => sub ($self) {
   XML::Compile::SOAP::Daemon::CGI->new; 
};

# do not depend on LWP
use constant { 
    RC_OK                 => 200,
    RC_METHOD_NOT_ALLOWED => 405,
    RC_NOT_ACCEPTABLE     => 406,
};

sub register ($self,$app,$conf={}) {
    my $log = $app->log;
    my $wsdl = XML::Compile::WSDL11->new($conf->{wsdl});
    $wsdl->importDefinitions(
        $conf->{xsds} 
    ) if $conf->{xsds};

    my $controller = $conf->{controller};
    for my $op ($wsdl->operations()){
        my $code;
        my $method = $op->name;
        if ($controller->can($method)){
            $app->log->debug(__PACKAGE__ . " Register handler for $method");
            $code = $op->compileHandler(
                callback => sub {
                    my ($ctrl,$param,$c) = @_;
                    my $ret = eval {
                        local $ENV{__DIE__};
                        $controller->$method(@_);
                    };
                    if ($@) {
                        if (ref $@ eq 'HASH') {
                            $c->log->error("$method - $@->{status} $@->{text}");
                            return {
                                _RETURN_CODE => $@->{status},
                                _RETURN_TEXT => $@->{text},
                            }
                        }
                        $log->error("$method - $@");
                        return {
                            _RETURN_CODE => 500,
                            _RETURN_TEXT => 'Internal Error'
                        }
                    }
                    return $ret;
                }
            );
        }
        else {
            $app->log->debug(__PACKAGE__ . " Adding stub handler $method");
            $code = $op->compileHandler(
                callback => $conf->{default_cb} || sub {
                    warn "No handler for $method";
                    return {
                        _RETURN_CODE => 404,
                        _RETURN_TEXT => 'No handler found',
                    };
                }
            );
        }
        $self->daemon->addHandler($op->name,$op,$code);
    }
    my $r = $app->routes;
    $app->types->type(
        soapxml => 'text/xml; charset="utf-8"'
    );
    $r->any($conf->{endPoint})
    ->to(cb => sub ($c) {
        if ( $c->req->method !~ /^(M-)?POST$/ ) {
            return $c->render(
                status => RC_METHOD_NOT_ALLOWED . " Expected POST",
                text => 'SOAP wants you to POST!'
            );
        }
        my $format = 'txt';
        my $body = $c->req->body;
        my ($rc,$msg,$xml) = $self->daemon->process(
            \$body,
            $c,
            $c->req->headers->header('soapaction')
        );
        my $bytes = $xml;
        my $err;
        if(UNIVERSAL::isa($bytes, 'XML::LibXML::Document')) {
            $bytes = $bytes->toString($rc == RC_OK ? 0 : 1);
            $format = 'soapxml';
        }
        else {
            $err = $bytes;
        }
        if (not $bytes) {
            $bytes = "[$rc] $err";
        }
    
        $c->render(
            status => $rc,
            format => $format,
            data => $bytes,
        );
    });
}

1;

=head1 ACKNOWLEDGEMENT

This is really just a very thin layer on top of Mark Overmeers great L<XML::Compile::SOAP::Daemon> module. Thanks Mark!

=head1 AUTHOR

S<Tobias Oetiker, E<lt>tobi@oetiker.chE<gt>>

=head1 COPYRIGHT

Copyright OETIKER+PARTNER AG 2019

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.10 or,
at your option, any later version of Perl 5 you may have available.

=cut