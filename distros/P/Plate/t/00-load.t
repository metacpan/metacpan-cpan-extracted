#!perl -T
use 5.020;
use warnings;
use Test::More tests => 1;

use_ok 'Plate' or BAIL_OUT;
diag "Testing Plate $Plate::VERSION, Perl $], $^X";

if ($ENV{AUTHOR_TESTING}) {
    require Devel::Cover::DB;
    my $db = new Devel::Cover::DB db => 'cover_db';
    $db->delete if $db->is_valid;
}
