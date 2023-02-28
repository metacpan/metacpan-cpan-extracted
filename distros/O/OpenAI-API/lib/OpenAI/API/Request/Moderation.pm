package OpenAI::API::Request::Moderation;

use strict;
use warnings;

use Moo;
use strictures 2;
use namespace::clean;
use Types::Standard qw(Bool Str Num Int Map);

has input => ( is => 'rw', isa => Str, required => 1, );

has model => ( is => 'rw', isa => Str, );

1;
