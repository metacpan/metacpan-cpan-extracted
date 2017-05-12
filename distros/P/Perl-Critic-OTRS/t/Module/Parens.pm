package t::Module::Parens;

use Data::Dumper;

# ABSTRACT: This module is a test module

sub Test {
    my $Self = shift;

    $Self->Test();
    my $var = 'Test';
    $Self->$var();
}

1;
