package Foo;
use strict;
use warnings;
use utf8;
use parent qw/Exporter/;

use File::Spec::Functions qw/catfile/;
use Module::Functions;

our @EXPORT = get_public_functions();

sub foo { '5963' }

1;

