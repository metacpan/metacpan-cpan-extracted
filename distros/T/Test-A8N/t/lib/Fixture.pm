package Fixture;

use strict;
use warnings;
use Moose;
BEGIN {
    extends 'Test::A8N::Fixture';
}
use Test::More;

sub file_exists : Test {
    my ($self, $file) = @_;
    ok -e $file, qq{File ’$file’ exists};
}

sub fixture1 : Test {
    my ($self, $file) = @_;
    pass("fixture1");
}

sub fixture2 : Test {
    my ($self, $file) = @_;
    pass "fixture2";
}

sub fixture3 : Test {
    my ($self, $file) = @_;
    pass "fixture3";
}

sub fixture4 : Test {
    my ($self, $file) = @_;
    pass "fixture4";
}

1;
