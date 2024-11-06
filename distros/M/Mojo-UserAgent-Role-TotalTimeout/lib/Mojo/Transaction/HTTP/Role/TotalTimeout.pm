package Mojo::Transaction::HTTP::Role::TotalTimeout;

use strict;
use warnings;

use Mojo::Base -role;

our $VERSION = "v0.0.1";

has __TotalTimeout__absolute_end_time => 0;

1;
