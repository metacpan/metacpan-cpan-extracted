package OpenAI::API::Response::Embedding;

use strict;
use warnings;

use Moo;
use strictures 2;
use namespace::clean;

extends 'OpenAI::API::Response';

has 'data' => (
    is => 'ro',
    required => 1,
);

has 'model' => (
    is => 'ro',
    required => 1,
);

has 'object' => (
    is       => 'ro',
    required => 1,
);

has 'usage' => (
    is       => 'ro',
    required => 1,
);

1;
