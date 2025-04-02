package Net::RDAP::Server::Response;
# ABSTRACT: An RDAP response object.
use base qw(HTTP::Response);
use JSON::XS;
use vars qw($JSON);
use strict;
use warnings;

$JSON = JSON::XS->new->utf8->canonical->pretty->convert_blessed;


sub new {
    my ($package, $request, $server, @args) = @_;
    my $self = $package->SUPER::new(@args);
    bless($self, $package);

    $self->{_request} = $request;
    $self->{_server} = $server;

    $self->header('content-type' => 'application/rdap+json');
    $self->header('access-control-allow-origin' => '*');

    return $self;
}


sub request { shift->{_request} }


sub server { shift->{_server} }


sub ok {
    $_[0]->code(200);
    $_[0]->message(q{OK});
}


sub error {
    my ($self, $code, $message) = @_;

    $self->code($code);
    $self->message($message);
    $self->content({
        errorCode   => $code,
        title       => $message,
    });
}


sub content {
    my $self = shift;

    if (0 == scalar(@_)) {
        return $self->SUPER::content;

    } else {
        my $content = shift;
        return $self->SUPER::content($JSON->encode($content));

    }
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Net::RDAP::Server::Response - An RDAP response object.

=head1 VERSION

version 0.04

=head1 DESCRIPTION

L<Net::RDAP::Server::Response> represents a response to an RDAP query. Request
handlers that are invoked by L<Net::RDAP::Server> will be passed an object of
this type as their argument. They can then manipulate the object as needed to
produce the desired response.

L<Net::RDAP::Server::Response> extends L<HTTP::Response>.

=head1 ADDITIONAL METHODS

=head2 C<request()>

This method returns the corresponding L<Net::RDAP::Server::Request> object.

=head2 C<server()>

This method returns the L<Net::RDAP::Server> object that is handling the
request.

=head2 C<ok()>

This sets the HTTP status code of the response to C<200>, and also sets an
appropriate status message.

=head2 error($code, $message)

This sets the HTTP status code of the response to C<$code> and the status
message to C<$message>. The body of the response will also be set to an
appropriate RDAP error (see
L<Section 6 of RFC 9083|https://datatracker.ietf.org/doc/html/rfc9083#section-6>).

=head1 OVERRIDDEN METHODS

=head2 content()

This method works just like the parent method, except that the setter form
accepts a hashref that is encoded to JSON. This means that request handlers
never need to deal with JSON directly.

=head1 AUTHOR

Gavin Brown <gavin.brown@fastmail.uk>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2024 by Gavin Brown.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
