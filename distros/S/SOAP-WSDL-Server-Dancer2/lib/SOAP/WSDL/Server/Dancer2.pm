package SOAP::WSDL::Server::Dancer2;

# ABSTRACT: Dancer2 for SOAP::WSDL Server

use Carp;
use Dancer2::Plugin;
use Class::Load 'load_class';

our $VERSION = '0.01';

register soap_wsdl_server => sub {
    my ($dsl, @args) = plugin_args(@_);
    my %args = @args % 2 ? %{$args[0]} : @args;

    # Perl module with the SOAP method implementation
    my $dispatch_to = $args{dispatch_to} or do {
        $dsl->error('dispatch_to is required.');
        $dsl->status(500);
        return;
    };
    load_class($dispatch_to);

    # Perl module with the SOAP::WSDL server implementation
    my $soap_service = $args{soap_service} or do {
        $dsl->error('soap_service is required.');
        $dsl->status(500);
        return;
    };
    load_class($soap_service);

    # if no transport class was specified, use this package's
    # Transport class with its handle() method
    my $transport_class = $args{transport_class} || __PACKAGE__ . '::Transport';
    load_class($transport_class);

    my $server = $soap_service->new({
            dispatch_to => $dispatch_to,         # methods
            transport_class => $transport_class, # handle() class
    });

    my $response_msg = $server->handle($dsl->request, $dsl->app);
    if (defined $response_msg && $response_msg =~ /^\d{3}$/) {
        $dsl->error("Dispatcher returned HTTP $response_msg");
        $dsl->status($response_msg);
        return;
    }

    if ($response_msg) {
        $dsl->content_type('text/xml; charset="utf-8"');
        $dsl->response->content($response_msg);
        return;
    } else {
        $dsl->error("No response returned from dispatcher");
        $dsl->status(500);
        return;
    }
};

register_plugin;

1;
__END__

=pod

=encoding UTF-8

=head1 NAME

SOAP::WSDL::Server::Dancer2 - Dancer2 for SOAP::WSDL Server

=head1 SYNOPSIS

    use Dancer2;
    use SOAP::WSDL::Server::Dancer2;

    post '/payment_validation' => sub {
        soap_wsdl_server(
            dispatch_to => 'HelloWorld::Impl',
            soap_service => 'HelloWorld::Server::XXX::XXXServicePort',
        );
    };

=head1 DESCRIPTION

A module copied from L<SOAP::WSDL::Server::Plack> but for Dancer2

=head1 AUTHOR

Fayland Lam E<lt>fayland@gmail.comE<gt>

=head1 COPYRIGHT

Copyright 2016- Fayland Lam

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 SEE ALSO

L<SOAP::WSDL::Server::Plack>, L<SOAP::WSDL>
