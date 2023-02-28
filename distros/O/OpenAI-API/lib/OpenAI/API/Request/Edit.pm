package OpenAI::API::Request::Edit;

use strict;
use warnings;

use Moo;
use strictures 2;
use namespace::clean;
use Types::Standard qw(Bool Str Num Int Map);

has model       => ( is => 'rw', isa => Str, required => 1, );
has instruction => ( is => 'rw', isa => Str, required => 1, );

has input       => ( is => 'rw', isa => Str, );
has temperature => ( is => 'rw', isa => Num, );
has top_p       => ( is => 'rw', isa => Num, );
has n           => ( is => 'rw', isa => Int, );

1;
