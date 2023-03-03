package OpenAI::API::Request::Chat;

use strict;
use warnings;

use Moo;
use strictures 2;
use namespace::clean;
use Types::Standard qw(Bool Str Num Int Map ArrayRef HashRef);

has model    => ( is => 'rw', isa => Str, required => 1, default => 'gpt-3.5-turbo' );
has messages => ( is => 'rw', isa => ArrayRef[HashRef], required => 1, );

has max_tokens        => ( is => 'rw', isa => Int, );
has temperature       => ( is => 'rw', isa => Num, );
has top_p             => ( is => 'rw', isa => Num, );
has n                 => ( is => 'rw', isa => Int, );
has stream            => ( is => 'rw', isa => Bool, );
has logprobs          => ( is => 'rw', isa => Int, );
has echo              => ( is => 'rw', isa => Bool, );
has stop              => ( is => 'rw', isa => Str, );
has presence_penalty  => ( is => 'rw', isa => Num, );
has frequency_penalty => ( is => 'rw', isa => Num, );
has logit_bias        => ( is => 'rw', isa => Map [ Int, Int ], );
has user              => ( is => 'rw', isa => Str, );

1;

__END__

=head1 NAME

OpenAI::API::Request::Chat - chat endpoint

=head1 DESCRIPTION

Given a chat conversation, the model will return a chat completion response.

=head1 METHODS

=head2 new()

=over 4

=item * model

ID of the model to use.

See L<Models overview|https://platform.openai.com/docs/models/overview>
for a reference of them.

=item * messages

The messages to generate chat completions for, in the chat format.

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

=head1 SEE ALSO

OpenAI API Documentation: L<Chat|https://platform.openai.com/docs/api-reference/chat>
