package OpenAI::API::Response::Model::Retrieve;

use strict;
use warnings;

use Moo;
use strictures 2;
use namespace::clean;

extends 'OpenAI::API::Response';

has 'id' => (
    is       => 'ro',
    required => 1,
);

has 'object' => (
    is       => 'ro',
    required => 1,
);

has 'owned_by' => (
    is       => 'ro',
    required => 1,
);

has 'permission' => (
    is       => 'ro',
    required => 1,
);

has 'created' => (
    is       => 'ro',
    required => 0,
);

has 'parent' => (
    is       => 'ro',
    required => 0,
);

has 'root' => (
    is       => 'ro',
    required => 0,
);

1;
