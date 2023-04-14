package OpenAI::API::Response::Image::Generation;

use strict;
use warnings;

use Moo;
use strictures 2;
use namespace::clean;

extends 'OpenAI::API::Response';

has 'created' => (
    is => 'ro',
    required => 1,
);

has 'data' => (
    is => 'ro',
    required => 1,
);

1;
