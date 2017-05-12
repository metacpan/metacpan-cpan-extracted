#!perl -T

use strict;
use warnings;

use Test::More tests => 4;
use MySQL::Workbench::DBIC;
use FindBin;

my $bin         = $FindBin::Bin;
my $file        = $bin . '/test.xml';

my $foo = MySQL::Workbench::DBIC->new(
    file                => $file,
    belongs_to_prefix   => 'test1',
    has_many_prefix     => 'test2',
    many_to_many_prefix => 'test3',
    has_one_prefix      => 'test4',
);

is( $foo->belongs_to_prefix,   'test1', 'belongs_to'   );
is( $foo->has_many_prefix,     'test2', 'has_many'     );
is( $foo->many_to_many_prefix, 'test3', 'many_to_many' );
is( $foo->has_one_prefix,      'test4', 'has_one'      );
