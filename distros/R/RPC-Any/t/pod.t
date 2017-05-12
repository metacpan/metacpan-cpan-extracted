#!/usr/bin/perl

use strict;
use warnings;

use Test::More;

# We need 1.41 so that it doesn't complain about L<text|url>.
eval "use Test::Pod 1.41";
plan skip_all => "Test::Pod 1.41 required for testing POD" if $@;

all_pod_files_ok();
