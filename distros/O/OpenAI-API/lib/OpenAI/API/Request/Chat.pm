package OpenAI::API::Request::Chat;

use strict;
use warnings;

use Carp qw/croak/;

use Moo;
use strictures 2;
use namespace::clean;

extends 'OpenAI::API::Request';

use Types::Standard qw(Any Bool Int Num Str Map ArrayRef HashRef);

has model => ( is => 'rw', isa => Str, default => 'gpt-3.5-turbo' );
has messages => ( is => 'rw', isa => ArrayRef [HashRef], default => sub { [] } );

has max_tokens        => ( is => 'rw', isa => Int, );
has temperature       => ( is => 'rw', isa => Num, );
has top_p             => ( is => 'rw', isa => Num, );
has n                 => ( is => 'rw', isa => Int, );
has stream            => ( is => 'rw', isa => Bool, );
has logprobs          => ( is => 'rw', isa => Int, );
has echo              => ( is => 'rw', isa => Bool, );
has stop              => ( is => 'rw', isa => Any, );
has presence_penalty  => ( is => 'rw', isa => Num, );
has frequency_penalty => ( is => 'rw', isa => Num, );
has logit_bias        => ( is => 'rw', isa => Map [ Int, Int ], );
has user              => ( is => 'rw', isa => Str, );

sub endpoint { 'chat/completions' }
sub method   { 'POST' }

sub add_message {
    my ( $self, $role, $content ) = @_;

    croak 'add_message() requires two parameters: role and content' if !defined $role || !defined $content;

    push @{ $self->messages }, { role => $role, content => $content };

    return $self;
}

sub send_message {
    my ( $self, $content ) = @_;

    $self->add_message( 'user', $content );

    my $res                = $self->send();
    my $assistant_response = $res->{choices}[0]{message}{content};

    $self->add_message( 'assistant', $assistant_response );

    return $res;
}

1;

__END__

=head1 NAME

OpenAI::API::Request::Chat - Request class for OpenAI API chat-based
completion

=head1 SYNOPSIS

    use OpenAI::API::Request::Chat;

    my $chat = OpenAI::API::Request::Chat->new(
        messages => [
            { role => 'system', content => 'You are a helpful assistant.' },
            { role => 'user', content => 'Who won the world series in 2020?' },
        ],
    );

    my $res     = $chat->send();                  # or: my $res = $chat->send(%args);
    my $message = $res->{choices}[0]{message};    # or: my $message = "$res";

    # continue the conversation...
    # $res = $chat->send_message('What is the capital of France?');

=head1 DESCRIPTION

This module provides a request class for interacting with the OpenAI API's
chat-based completion endpoint. It inherits from L<OpenAI::API::Request>.

=head1 ATTRIBUTES

=head2 model

ID of the model to use.

See L<Models overview|https://platform.openai.com/docs/models/overview>
for a reference of them.

=head2 messages

The messages to generate chat completions for, in the L<chat
format|https://platform.openai.com/docs/guides/chat/introduction>.

=head2 max_tokens [optional]

The maximum number of tokens to generate.

Most models have a context length of 2048 tokens (except for the newest
models, which support 4096).

=head2 temperature [optional]

What sampling temperature to use, between 0 and 2. Higher values like
0.8 will make the output more random, while lower values like 0.2 will
make it more focused and deterministic.

=head2 top_p [optional]

An alternative to sampling with temperature, called nucleus sampling.

We generally recommend altering this or C<temperature> but not both.

=head2 n [optional]

How many completions to generate for each prompt.

Use carefully and ensure that you have reasonable settings for
C<max_tokens> and C<stop>.

=head2 stop [optional]

Up to 4 sequences where the API will stop generating further tokens. The
returned text will not contain the stop sequence.

=head2 frequency_penalty [optional]

Number between -2.0 and 2.0. Positive values penalize new tokens based
on their existing frequency in the text so far.

=head2 presence_penalty [optional]

Number between -2.0 and 2.0. Positive values penalize new tokens based
on whether they appear in the text so far.

=head2 user [optional]

A unique identifier representing your end-user, which can help OpenAI
to monitor and detect abuse.

=head1 METHODS

=head2 add_message($role, $content)

This method adds a new message with the given role and content to the
messages attribute.

=head2 send_message($content)

This method adds a user message with the given content, sends the request,
and returns the response. It also adds the assistant's response to the
messages attribute.

=head1 INHERITED METHODS

This module inherits the following methods from L<OpenAI::API::Request>:

=head2 send(%args)

=head2 send_async(%args)

=head1 SEE ALSO

L<OpenAI::API::Request>, L<OpenAI::API::Config>
