package t::Module::WithDumperLong;

use Data::Dumper;

# ABSTRACT: This module does nothing but return a true value

sub test {
    print Data::Dumper::Dumper( 'test' );
}

1;
