package Mojo::SOAP::Client;

=head1 NAME

Mojo::SOAP::Client - Talk to SOAP Services mojo style

=head1 SYNPOSYS

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

=head1 DESCRIPTION

The Mojo::SOAP::Client is based on the L<XML::Compile::SOAP>
family of packages, and especially on L<XML::Compile::SOAP::Mojolicious>.

=cut

use Mojo::Base -base, -signatures;

use Mojo::Promise;
use XML::Compile::WSDL11;      # use WSDL version 1.1
use XML::Compile::SOAP11;      # use SOAP version 1.1
use XML::Compile::SOAP12;
use XML::Compile::Transport::SOAPHTTP_MojoUA;
use HTTP::Headers;
use File::Basename qw(dirname);
use Mojo::Util qw(b64_encode dumper);
use Mojo::Log;
use Carp;

our $VERSION = '0.1.4';

=head2 Properties

The module provides the following properties to customize its behavior. Note that setting any properties AFTER using the C<call> or C<call_p> methods, will lead to undefined behavior.

=head3 log

a pointer to a L<Mojo::Log> instance

=cut

has log => sub ($self) {
    Mojo::Log->new;
};

=head3 request_timeout

How many seconds to wait for the soap server to respond. Defaults to 5 seconds.

=cut

has request_timeout => 5;

=head3 insecure

Set this to allow communication with a soap server that uses a 
self-signed or otherwhise invalid certificate.

=cut

has insecure => 0;

=head3 wsdl

Where to load the wsdl file from. At the moment this MUST be a file.

=cut

has 'wsdl' => sub ($self) {
    croak "path to wsdl spec file must be provided in wsdl property";
};

=head3 xsds

A pointer to an array of xsd files to load for this service.

=cut

has 'xsds' => sub ($self) {
    [];
};

=head3 port

If the wsdl file defines multiple ports, pick the one to use here.

=cut

has 'port';

=head3 endPoint

The endPoint to talk to for reaching the SOAP service. This information
is normally encoded in the WSDL file, so you will not have to set this
explicitly.

=cut


has 'endPoint' => sub ($self) {
    $self->wsdlCompiler->endPoint(
        $self->port ? ( port => $self->port) : ()
    );
};

=head3 ca

The CA cert of the service. Only for special applications.

=cut

has 'ca';

=head3 cert

The client certificate to use when connecting to the soap service.

=cut 

has 'cert';

=head3 key

The key matching the client cert.

=cut

has 'key';


has wsdlCompiler => sub ($self) {
    my $wc = XML::Compile::WSDL11->new($self->wsdl);
    for my $xsd ( @{$self->xsds}) {
        $wc->importDefinitions($xsd)
    }
    return $wc;
};

has httpUa => sub ($self) {
    XML::Compile::Transport::SOAPHTTP_MojoUA->new(
        address => $self->endPoint,
        ua_start_callback => sub ($ua,$tx) {
            $ua->ca($self->ca)
                if $self->ca;
            $ua->cert($self->cert)
                if $self->cert;
            $ua->key($self->key)
                if $self->key;
            $ua->request_timeout($self->request_timeout)
                if $self->request_timeout;
            $ua->insecure($self->insecure)
                if $self->insecure;
        },
    );
};

=head3 uaProperties

If special properties must be set on the UA you can set them here. For example a special authorization header was required, this would tbe the place to set it up.

  my $client = Mojo::SOAP::Client->new(
      ...
      uaProperties => {
          header => HTTP::Headers->new(
             Authorization => 'Basic '. b64_encode("$user:$password","")
          })
      }
  );

=cut

has uaProperties => sub {
    {}
};

has transport => sub ($self) {
    $self->httpUa->compileClient(
        %{$self->uaProperties}
    );
};

has clients => sub ($self) {
    return {};
};

=head2 Methods

The module provides the following methods.

=head3 call_p($operation,$params)

Call a SOAP operation with parameters and return a L<Mojo::Promise>.

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

=cut

sub call_p ($self,$operation,$params={}) {
    my $clients = $self->clients;
    my $call = $clients->{$operation} //= $self->wsdlCompiler->compileClient(
        operation => $operation,
        transport => $self->transport,
        async => 1,
        # oddly repetitive, the port is mentioned in the endPoint
        # selection as well as here ... 
        ( $self->port ? ( port => $self->port ) : () ),
    );
    $self->log->debug(__PACKAGE__ . " $operation called");
    return Mojo::Promise->new(sub ($resolve,$reject) {
        $call->(
            %$params,
            _callback => sub ($answer,$trace,@rest) {
                my $res = $trace->response;
                my $client_warning =
                    $res->headers->header('client-warning');
                return $reject->($client_warning)
                    if $client_warning;
                if (not $res->is_success) {
                    if (my $f = $answer->{Fault}){
                        $self->log->error(__PACKAGE__ . " $operation - ".$f->{_NAME} .": ". $f->{faultstring});
                        return $reject->($f->{faultstring});
                    }
                    return $reject->($self->endPoint.' - '.$res->code.' '.$res->message)
                }
                # $self->log->debug(__PACKAGE__ . " $operation completed - ".dumper($answer));
                return $resolve->($answer,$trace);
            }
        );
    });
}

=head3 call($operation,$paramHash)

The same as C<call_p> but for syncronos applications. If there is a problem with the call it will raise a Mojo::SOAP::Exception which is a L<Mojo::Exception> child.

=cut

sub call ($self,$operation,$params) {
    my ($ret,$err);
    $self->call_p($operation,$params)
        ->then(sub { $ret = shift })
        ->catch(sub { $err = shift })
        ->wait;
    Mojo::SOAP::Exception->throw($err) if $err;
    return $ret;
}

package Mojo::SOAP::Exception {
  use Mojo::Base 'Mojo::Exception';
}

1;

=head1 ACKNOLEDGEMENT

This is really just a very thin layer on top of Mark Overmeers great L<XML::Compile::SOAP> module. Thanks Mark!

=head1 AUTHOR

S<Tobias Oetiker, E<lt>tobi@oetiker.chE<gt>>

=head1 COPYRIGHT

Copyright OETIKER+PARTNER AG 2019

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.10 or,
at your option, any later version of Perl 5 you may have available.
