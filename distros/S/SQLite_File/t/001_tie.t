# -*-perl-*-
BEGIN {
    use lib '../lib';
    use Test::More tests => 62;
    @AnyDBM_File::ISA = qw( SQLite_File );
    use_ok('DBD::SQLite');
    use_ok('AnyDBM_File');
}

use vars qw( $DB_HASH $DB_TREE $DB_RECNO &R_DUP &R_CURSOR &O_CREAT &O_RDWR &O_RDONLY);
use AnyDBM_File::Importer qw(:bdb);
my ($key, $value);
my %db;
my $flags = O_CREAT | O_RDWR;
ok tie( %db, 'AnyDBM_File', 'my.db', $flags, 0666, $DB_HASH, 0), "tie";
ok $db{'butcher'} = 1, "set";
ok $db{'baker'} = 2, "set";
ok $db{'candlestick maker'} = 3, "set";
ok $db{'ooh, isnt this a very very very very very very very very very very long key, my goodness gracious me'} = 4, "set";
ok $a = $db{'baker'}, "access";
is($a, 2, "value correct");
ok exists $db{'baker'}, "exists";
ok delete $db{'baker'}, "delete";
ok !exists $db{'baker'}, "delete deletes";
ok my @k = keys %db, "iterate (keys)";
is_deeply( [ sort @k ] , ['butcher','candlestick maker', 'ooh, isnt this a very very very very very very very very very very long key, my goodness gracious me'] , "all keys retrieved");
my $f = 1;
while (my ($id, $val) = each %db) {
    1;
    $f *= $val;
}
is($f, 12, "iterate (each)");
ok $db{'baker'} = 10, "replace";
is($db{'baker'}, 10, "correct replace");

my $file = (tied %db)->file;
ok ( -e $file, "now you see it" );
untie %db;
ok ( ! -e $file, "now you don't");

tie( %db, 'AnyDBM_File', 'my.db', $flags, 0666, undef, 1);
ok ( -e 'my.db', "now you see it" );
untie %db;
ok ( -e 'my.db', "now you still see it");
ok ( !(tied %db), "but tied obj is gone" );

ok ( unlink('my.db'), "now you don't");

# test dup functions
$DB_BTREE->{flags} = R_DUP;
ok $db = tie( %db, 'AnyDBM_File', undef, $flags, 0666, $DB_BTREE), "DB_BTREE";

ok (@db{('A', 'B', 'B', 'B', 'C')} = (1, 2, 2, 3, 4), "set dup hash");

$key = 'B';
$value = 3;
is ($db->find_dup($key,$value), 0, "find_dup");

ok (!$db->seq($key, $value, R_CURSOR), "seq checks cursor");
is ($key, 'B', "find_dup sets cursor (key)");
is ($value, '2', "find_dup sets cursor (value)");
ok my $d = $db->get_dup('B');
is($d, 3, "get_dup (scalar)");
ok my @d = $db->get_dup('B');
is(@d, 3, "get_dup (array)");
ok my %d = $db->get_dup('B',1);
is($d{'2'},2,"get_dup (hash 1)");
is($d{'3'},1,"get_dup (hash 2)");
undef $db;
untie %db;

# test user-supplied collation via $DB_BTREE->{'compare'}
$DB_BTREE->{'compare'} = sub { my ($a, $b) = @_; -( $a cmp $b ) };
ok $db = tie( %db, 'AnyDBM_File', undef, $flags, 0666, $DB_BTREE), "tie w/reverse collation";
@db{qw( a b c d e f )} = (1,2,3,4,5,6);
my @rev;
$db->seq($key, $value, R_FIRST);
push @rev, $value;
while (!$db->seq($key, $value, R_NEXT)) {
    push @rev, $value;
}
is_deeply(\@rev, [6,5,4,3,2,1], "reverse collation correct");
undef $db;
untie %db;

# test filter hooks
$db = tie( %db, 'AnyDBM_File', undef, $flags, 0666, $DB_BTREE);

$db->filter_store_key( sub { $_ = uc; } );
$db->filter_store_value( sub  { $_ *= 2 } );
@db{qw( a b c d e f )} = (1,2,3,4,5,6);
is_deeply( [sort keys %db], [qw(A B C D E F)] );
$db->filter_fetch_value( sub { $_ *= 2 } );
is_deeply( [sort {$a <=> $b} values %db], [qw( 4 8 12 16 20 24 )] );
$db->filter_fetch_key( sub { $_ = lc; } );
is_deeply( [sort keys %db], [qw(a b c d e f)] );

undef $db;
untie %db;



ok tie( @db, 'AnyDBM_File', undef, $flags, 0666, $DB_RECNO), "tied array";
my $aro = tied @db;

ok @db = qw( a b c d ), "set";
is_deeply( \@db, [qw(a b c d)], "correct set");
is( scalar @db, 4, "scalar size");
is( $#db, 3, "last elt index");
ok $db[2] = 'm', "replace";
is ($db[2], 'm', "replace correct");

# array functions

ok push(@db, 'e'), "push one";
is ($db[-1], 'e', "correct end");
ok unshift(@db, 'Z'), "unshift one";
is ($db[0], 'Z', "correct begin");
is( scalar @db, 6, "correct scalar length");

ok push(@db, 'f', 'g', 'h'), "push some";
is ($db[7],'g',"correct set");
ok unshift(@db, 'X', 'Y'), "unshift some";
is ($db[1], 'Y',"correct set");

pop @db for (1..3);
is ($db[-1], 'e', "pop some");
shift @db for (1..3);
is ($db[0], 'a', "shift some");
ok( my @rem = splice(@db, 1, 2, 'x', 'y', 'z'),"splice" );
is_deeply( \@rem, ['b','m'], "splice remove correct");
is_deeply( \@db, ['a','x','y','z','d','e'], "splice insert correct");
undef $aro;
untie(@db);

1;
