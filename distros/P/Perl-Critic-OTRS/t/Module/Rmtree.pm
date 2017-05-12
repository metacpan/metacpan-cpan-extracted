package t::Module::Rmtree;

use Data::Dumper;
use File::Path qw(rmtree);

# ABSTRACT: This module is a test module

sub test {
    my $Self = shift;

    rmtree '/tmp/otrs';
    rmtree( '/tmp/otrs' );
    File::Path::rmtree( '/tmp/otrs' );
}

1;
