#!/usr/bin/perl

use strict;
use warnings;
use Test::More tests => 1;

use Beta;
use Alpha;

#print Beta::Member->meta->perl_class_definition, "\n",
#      Alpha::Member->meta->perl_class_definition, "\n";

ok( Alpha::Member->can( 'friends' ), 'Alpha::Member has friends method' );
