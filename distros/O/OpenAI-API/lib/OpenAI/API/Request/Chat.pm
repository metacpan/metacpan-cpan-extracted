package OpenAI::API::Request::Chat;

use strict;
use warnings;

use Moo;
use strictures 2;
use namespace::clean;

extends 'OpenAI::API::Request';

use Types::Standard qw(Any Bool Int Num Str Map ArrayRef HashRef);

has model    => ( is => 'rw', isa => Str, required => 1, default => 'gpt-3.5-turbo' );
has messages => ( is => 'rw', isa => ArrayRef[HashRef], required => 1, );

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

1;

__END__

=head1 NAME

OpenAI::API::Request::Chat - chat endpoint

=head1 SYNOPSIS

    use OpenAI::API::Request::Chat;

    my $request = OpenAI::API::Request::Chat->new(
        model    => "gpt-3.5-turbo",
        messages => [
            { "role" => "system",    "content" => "You are a helpful assistant." },
            { "role" => "user",      "content" => "Who won the world series in 2020?" },
            { "role" => "assistant", "content" => "The Los Angeles Dodgers won the World Series in 2020." },
            { "role" => "user",      "content" => "Where was it played?" }
        ],
        max_tokens  => 20,
        temperature => 0,
    );

    my $res = $request->send();    # or: $request->send( http_response => 1 );

    my $message = $res->{choices}[0]{message};

=head1 DESCRIPTION

Given a chat conversation, the model will return a chat completion
response (similar to ChatGPT).

=head1 METHODS

=head2 new()

=over 4

=item * model

ID of the model to use.

See L<Models overview|https://platform.openai.com/docs/models/overview>
for a reference of them.

=item * messages

The messages to generate chat completions for, in the L<chat
format|https://platform.openai.com/docs/guides/chat/introduction>.

=item * max_tokens [optional]

The maximum number of tokens to generate.

Most models have a context length of 2048 tokens (except for the newest
models, which support 4096.

=item * temperature [optional]

What sampling temperature to use, between 0 and 2. Higher values like
0.8 will make the output more random, while lower values like 0.2 will
make it more focused and deterministic.

=item * top_p [optional]

An alternative to sampling with temperature, called nucleus sampling.

We generally recommend altering this or C<temperature> but not both.

=item * n [optional]

How many completions to generate for each prompt.

Use carefully and ensure that you have reasonable settings for
C<max_tokens> and C<stop>.

=item * stop [optional]

Up to 4 sequences where the API will stop generating further tokens. The
returned text will not contain the stop sequence.

=item * frequency_penalty [optional]

Number between -2.0 and 2.0. Positive values penalize new tokens based
on their existing frequency in the text so far.

=item * presence_penalty [optional]

Number between -2.0 and 2.0. Positive values penalize new tokens based
on whether they appear in the text so far.

=item * user [optional]

A unique identifier representing your end-user, which can help OpenAI
to monitor and detect abuse.

=back

=head2 send()

Sends the request and returns a data structured similar to the one
documented in the API reference.

=head2 send_async()

Send a request asynchronously. Returns a L<Promises> promise that will
be resolved with the decoded JSON response. See L<OpenAI::API::Request>
for an example.

=head1 SEE ALSO

OpenAI API Reference: L<Chat|https://platform.openai.com/docs/api-reference/chat>
