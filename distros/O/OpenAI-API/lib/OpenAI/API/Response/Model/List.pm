package OpenAI::API::Response::Model::List;

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

has 'object' => (
    is => 'ro',
    required => 1,
);

1;
