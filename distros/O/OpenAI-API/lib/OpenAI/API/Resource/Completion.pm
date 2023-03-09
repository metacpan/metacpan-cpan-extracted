package OpenAI::API::Resource::Completion;

use strict;
use warnings;

use Moo;
use strictures 2;
use namespace::clean;
use Types::Standard qw(Any Bool Int Map Num Str);

has model  => ( is => 'rw', isa => Str, required => 1, );
has prompt => ( is => 'rw', isa => Str, required => 1, );

has suffix            => ( is => 'rw', isa => Str, );
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
has best_of           => ( is => 'rw', isa => Int, );
has logit_bias        => ( is => 'rw', isa => Map [ Int, Int ], );
has user              => ( is => 'rw', isa => Str, );

sub endpoint { 'completions' }

1;

__END__

=head1 NAME

OpenAI::API::Resource::Completion - completions endpoint

=head1 DESCRIPTION

Given a prompt, the model will return one or more predicted completions.

=head1 METHODS

=head2 new()

=over 4

=item * model

ID of the model to use.

See L<Models overview|https://platform.openai.com/docs/models/overview>
for a reference of them.

=item * prompt

The prompt for the text generation.

=item * suffix [optional]

The suffix that comes after a completion of inserted text.

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

=item * best_of [optional]

Generates best_of completions server-side and returns the "best" (the
one with the highest log probability per token).

Use carefully and ensure that you have reasonable settings for
C<max_tokens> and C<stop>.

=back

=head1 SEE ALSO

OpenAI API Documentation: L<Completions|https://platform.openai.com/docs/api-reference/completions>
