package t::Module::CoreFunc;

use Data::Dumper;
use File::Path qw(rmtree);

# ABSTRACT: This module is a test module

sub test {
    my $Self = shift;

    my @array = qw(this is a test);
    print @array;
    print 'string';
    print scalar @array;
    CORE::print( 'test' );
    CORE::print 'test';

    die 'test';
    CORE::die 'test';
    die 1;

    exit(0);
    CORE::exit(1);
    CORE::exit 255;
}

1;
