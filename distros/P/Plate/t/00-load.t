#!perl -T
use 5.020;
use warnings;
use Test::More tests => 2;

use_ok 'Plate' or BAIL_OUT;
diag "Testing Plate $Plate::VERSION, Perl $], $^X";

if ($ENV{AUTHOR_TESTING}) {
    require Devel::Cover::DB;
    my $db = new Devel::Cover::DB db => 'cover_db';
    $db->delete if $db->is_valid;
}

package ChinaPlate 1 {
    @ChinaPlate::ISA = 'Plate';

    sub _set_inherited {
        $_[0]{inherited} = $_[1];
    }
}

my $plate = ChinaPlate->new(inherited => 'yes');
is $$plate{inherited}, 'yes', 'Custom settings can be inherited from subclasses';
