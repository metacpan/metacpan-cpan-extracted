package t::Module::WithDumper;

use Data::Dumper;

# ABSTRACT: This module does nothing but return a true value

sub test {
    print Dumper 'test';
}

1;
