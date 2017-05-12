package SOAP::WSDL::Server::Dancer2::Transport;

# ABSTRACT: Dancer2 Server Transport for SOAP::WSDL

use Carp;
use Try::Tiny;
use HTTP::Request;

# As SOAP::WSDL::Server is a Class::Std::Fast inside-out class we can't
# reliable inherit from it without using Class::Std::Fast too. Instead
# of inheritance we use a delegate pattern
use SOAP::WSDL::Server;

use Moo;
use namespace::clean;

has 'action_map_ref' => (
    is => 'rw'
);

has 'class_resolver' => (
    is => 'rw',
);

has 'dispatch_to' => (
    is => 'rw',
);

# private server instance for delegate
# Carry SOAP::WSDL::Server instance to delegate to
has '_soap_wsdl_server' => (
    is => 'lazy',
    handles => [qw(
            get_action_map_ref
            set_action_map_ref
            get_class_resolver
            set_class_resolver
            get_dispatch_to
            set_dispatch_to
    )],
);
sub _build__soap_wsdl_server {
    my $self = shift;
    return SOAP::WSDL::Server->new({
        action_map_ref => $self->action_map_ref,
        class_resolver => $self->class_resolver,
        dispatch_to => $self->dispatch_to,
    });
}

sub handle {
    my ($self, $req, $app) = @_;

    my $length = $req->headers->header('Content-Length');
    if (! $length) {
        $app->log(error => "No Content-Length provided");
        # TODO maybe throw instead of returning a HTTP code?
        return 411; # Length required
    }

    my $content = $req->body;
    if ($length != length($content)) {
        $app->log(error => sprintf(
                            "Read length mismatch; read [%d] bytes but received [%d] bytes",
                            length($content), $length));
        return 500;
    }

    # Shamelessly copied (with mild tweaks) from SOAP::WSDL::Server::Mod_Perl2
    # which was as shamelessly copied from SOAP::WSDL::Server::CGI which was
    # as shamelessly copied from SOAP::Transport::HTTP...
    my $request = HTTP::Request->new(
        $req->method() => $req->uri(),
        $req->headers->clone(),
        $content
    );
            #HTTP::Headers->new( SOAPAction => $req->headers->header('SOAPAction') ),

    my $response_message;
    try {
        #$response_message = $self->SUPER::handle($request);
        $response_message = $self->_soap_wsdl_server->handle($request);
    } catch {
        my $exception = $_;
        $app->log(error => "Failed to handle request: $exception");
        return 500;
    };

    return $response_message;
};

1;