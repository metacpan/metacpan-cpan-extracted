package OpenAI::API::Response;

use Moo;

1;

__END__


=head1 NAME

OpenAI::API::Response - base class for OpenAI API responses.

=head1 SYNOPSIS

This module should not be used directly. Instead, you should use a
subclass for specific response types, such as OpenAI::API::Response::Chat.

    use OpenAI::API::Request::Chat;

    my $request  = OpenAI::API::Request::Chat->new(...);
    my $response = $request->send();

    # You should be using OpenAI::API::Response::Chat or other subclasses directly, not OpenAI::API::Response.

=head1 DESCRIPTION

The C<OpenAI::API::Response> module provides a generic representation for
responses received from the OpenAI API. This module should not be used
directly. Instead, you should use subclasses for specific response types.
