package t::Module::Require;

use Data::Dumper;

# ABSTRACT: This module is a test module

sub test {
    my $Self = shift;

    require t::Module::Open;
    require 't/data/test.pl';
}

1;
