
use strict;
use warnings;
use Test::More tests => 3;

BEGIN {
  use_ok('Package::Subroutine');
}

package T::Base;

Package::Subroutine->mixin('Package::Subroutine');

package T::Plus;
@T::Plus::ISA = qw(Package::Subroutine);

package main;

my @expect  = sort qw/ import mixin export exporter version install
    isdefined findsubs export_to_caller export_to findmethods
    VERSION can isa /;

if(UNIVERSAL->can('DOES')) {
    unshift(@expect,'DOES');
}

my @have = sort Package::Subroutine->findmethods('T::Base');

is_deeply(\@have,\@expect,'methods found');

my @have2 = sort Package::Subroutine->findmethods('T::Plus');

is_deeply(\@have2,\@expect,'methods found');
