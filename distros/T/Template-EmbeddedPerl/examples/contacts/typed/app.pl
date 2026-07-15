#!/usr/bin/env perl

use strict;
use warnings;

use FindBin;
use File::Spec;

use lib File::Spec->catdir($FindBin::Bin, qw(.. .. .. lib));
use lib File::Spec->catdir($FindBin::Bin, 'lib');

use Contacts::Typed::App;

print Contacts::Typed::App->new(root => $FindBin::Bin)->render;
