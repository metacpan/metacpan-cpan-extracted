#!/usr/bin/perl

# Ensure that a class having a DESTROY method does not interfere
# Ensure objects with the same ref still get different IDs.

use strict;
use warnings;

use Test::More;

{
    package My::Class;
    use Object::ID;

    sub new {
        my $class = shift;
        my $ref   = shift;

        bless $ref, $class;
    }

    my $Destroyed;
    sub destroy_called {
        return $Destroyed;
    }

    sub DESTROY {
        $Destroyed++;
    }
}


{
    my %ids;
    for(1..3) {
        my $obj = new_ok "My::Class", [{}];
        $ids{$obj->object_id}++;
    }

    is keys %ids, 3, "got different IDs for each object" or diag explain \%ids;
    is( My::Class->destroy_called, 3, "all three objects destroyed" );
}

done_testing();
