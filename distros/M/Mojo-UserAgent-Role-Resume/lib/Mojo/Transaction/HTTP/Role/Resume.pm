package Mojo::Transaction::HTTP::Role::Resume;

use strict;
use warnings;

use Mojo::Base -role;

has _RESUME_original_arguments => undef;

has RESUME_previous_attempt => undef;

1;
