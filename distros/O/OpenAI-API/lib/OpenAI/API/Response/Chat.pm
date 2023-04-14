package OpenAI::API::Response::Chat;

use strict;
use warnings;

use Moo;
use strictures 2;
use namespace::clean;

use overload q{""} => '_as_string', fallback => 1;

extends 'OpenAI::API::Response';

has 'id' => (
    is       => 'ro',
    required => 1,
);

has 'choices' => (
    is       => 'ro',
    required => 1,
);

has 'object' => (
    is       => 'ro',
    required => 1,
);

has 'created' => (
    is       => 'ro',
    required => 1,
);

has 'usage' => (
    is       => 'ro',
    required => 1,
);

sub _as_string {
    my ($self) = @_;
    return $self->choices->[0]{message}{content};
}

1;

__END__

=head1 NAME

OpenAI::API::Response::Chat - encapsulate the response from the OpenAI
Chat API.

=head1 SYNOPSIS

This module should not be used directly. It will be used by
L<OpenAI::API::Request::Chat> to parse and encapsulate the response.

=head1 DESCRIPTION

OpenAI::API::Response::Chat extends the L<OpenAI::API::Response>
superclass and is used to encapsulate the response from the OpenAI
Chat API.

=head1 ATTRIBUTES

=head2 id

The unique identifier of the chat completion.

=head2 object

The type of the object, which is "chat.completion" for this module.

=head2 created

The timestamp when the chat completion was created.

=head2 choices

An arrayref containing the chat completion choices.

=head2 usage

A hashref containing the tokens usage information.

=head1 STRING OVERLOAD

This module uses L<overload> to provide string representation for
the response object. When the object is used as a string, it will
automatically return the content of the message in the first choice of
the C<choices> arrayref.

=head1 SEE ALSO

L<OpenAI::API::Request::Chat>, L<OpenAI::API::Response>
