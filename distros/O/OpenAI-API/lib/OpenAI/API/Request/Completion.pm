package OpenAI::API::Request::Completion;

use strict;
use warnings;

use Moo;
use strictures 2;
use namespace::clean;
use Types::Standard qw(Bool Str Num Int Map);

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
has stop              => ( is => 'rw', isa => Str, );
has presence_penalty  => ( is => 'rw', isa => Num, );
has frequency_penalty => ( is => 'rw', isa => Num, );
has best_of           => ( is => 'rw', isa => Int, );
has logit_bias        => ( is => 'rw', isa => Map [ Int, Int ], );
has user              => ( is => 'rw', isa => Str, );

1;
