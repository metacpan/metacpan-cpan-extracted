package OpenAI::API::Response::File::Retrieve;

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

has 'bytes' => (
    is       => 'ro',
    required => 1,
);

has 'created_at' => (
    is       => 'ro',
    required => 1,
);

has 'filename' => (
    is       => 'ro',
    required => 1,
);

has 'purpose' => (
    is       => 'ro',
    required => 1,
);

1;
