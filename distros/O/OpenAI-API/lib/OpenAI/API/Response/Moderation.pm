package OpenAI::API::Response::Moderation;

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

has 'model' => (
    is       => 'ro',
    required => 1,
);

has 'results' => (
    is       => 'ro',
    required => 1,
);

1;
