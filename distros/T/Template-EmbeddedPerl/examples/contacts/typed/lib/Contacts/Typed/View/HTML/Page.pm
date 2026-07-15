package Contacts::Typed::View::HTML::Page;

use strict;
use warnings;
use Moo;

has title => (is => 'ro', required => 1);
has root => (is => 'ro', required => 1);
has parent => (is => 'ro', required => 1);

1;
