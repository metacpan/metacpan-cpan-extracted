#!/usr/bin/perl

use strict;
use warnings;

use lib qw(lib t/lib);

use Test::More qw(no_plan);

my $class = q(Module::Build::IkiWiki);

use_ok($class);

my %options = (
    module_name     =>  q(foo),
    dist_version    =>  '0.0.1',
    license         =>  q(gpl),
);

my $builder = $class->new( %options );

isa_ok($builder,$class);


