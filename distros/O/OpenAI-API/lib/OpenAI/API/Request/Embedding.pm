package OpenAI::API::Request::Embedding;

use strict;
use warnings;

use Moo;
use strictures 2;
use namespace::clean;
use Types::Standard qw(Bool Str Num Int Map);

has model => ( is => 'rw', isa => Str, required => 1, );
has input => ( is => 'rw', isa => Str, required => 1, );

has user => ( is => 'rw', isa => Str, );

1;
