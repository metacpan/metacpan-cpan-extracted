#!/usr/bin/perl

package Something::Mutable;

use v5.12;
use strict;
use warnings;

use Moo;
use namespace::clean;

extends 'Something';

has name => (
	is => 'rw',
);

1;
