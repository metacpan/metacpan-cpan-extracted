#!/usr/bin/perl

package Something;

use v5.12;
use strict;
use warnings;

use Moo;
use namespace::clean;

with 'MooX::Role::CloneSet';

has name => (
	is => 'ro',
);

has color => (
	is => 'ro',
);

1;
