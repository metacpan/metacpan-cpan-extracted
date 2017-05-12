#!/usr/bin/env perl -w
use strict;
use Test::More tests => 3;

use Railsish::View::Helpers::TextHelper;

is pluralize(1, "person"), "person";
is pluralize(10, "person"), "people";
is pluralize(42, "person", "users"), "users";





