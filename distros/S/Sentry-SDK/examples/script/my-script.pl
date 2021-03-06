#!/usr/bin/env perl
use Mojo::Base -strict, -signatures;

use Mojo::File qw(curfile);
use lib (
  curfile->dirname->child('lib')->to_string,
  curfile->dirname->sibling('../lib')->to_string
);

use MyScript;

MyScript->main();
