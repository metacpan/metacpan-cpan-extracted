# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl Object-Collection.t'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

#use Test::More 'no_plan';    #tests => 'noplan';
use Test::More tests =>17 ;
use Data::Dumper;
BEGIN { 
    use_ok('Objects::Collection::HashUnion');
    use_ok('Objects::Collection::ActiveRecord');
    }
my %hash_1 = ( 1 => 1, 3 => 3 );
my %hash1;
tie %hash1, 'Objects::Collection::ActiveRecord', hash => \%hash_1;
my %hash2 = ( 2 => 2, 3 => 3 );
my %hashu;
tie %hashu, 'Objects::Collection::HashUnion', \%hash1, \%hash2;
is_deeply( [ keys %hashu ], [ '1', '2', '3' ], "Check keys" );
$hashu{4} = 4;
ok( exists $hashu{4}, "check exists key:4" );
ok( !exists $hashu{5}, "check not exists key:5" );
is_deeply(
    \%hash1,
    {
        '1' => 1,
        '3' => 3,
    },
    "check orig first hash after write  new key"
);
is_deeply(
    \%hash2,
    {
        '4' => 4,
        '3' => 3,
        '2' => 2
    },
    "check write new key"
);
is_deeply(
    \%hashu,
    {
        '1' => 1,
        '2' => 2,
        '3' => 3,
        '4' => 4
    },
    "Check union hash after write key"
);
ok(!$hashu{_changed}, "check changed flag before modify first hash");

$hashu{3} = 4;

is_deeply(
    \%hashu,
    {
        '1' => 1,
        '2' => 2,
        '3' => 4,
        '4' => 4
    },
    "check set dublicated key in hashes"
);
delete $hashu{3};

is_deeply \%hash1,
  {
    '1' => 1,
    '3' => 4
  },
  "delete: check first hash";
is_deeply \%hash2,
  {
    '4' => 4,
    '2' => 2
  },
  "delete: check last hash";
is_deeply \%hashu,
  {
    '1' => 1,
    '2' => 2,
    '3' => 4,
    '4' => 4
  },
  "delete: check union hash";

%hashu = ();

is_deeply  \%hash1, {
                        '1' => 1,
                        '3' => 4
                      }, "clean: check first";
is_deeply  \%hash2, {}, "clean check second hash";
          is_deeply  \%hashu,{
                        '1' => 1,
                        '3' => 4
                      },"clean: check union hash";
ok($hashu{_changed}, "check changed flag after save");

# Insert your test code below, the Test::More module is use()ed here so read
# its man page ( perldoc Test::More ) for help writing this test script.

