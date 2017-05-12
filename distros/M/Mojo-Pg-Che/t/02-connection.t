use Mojo::Base -strict;

use Test::More;
use Mojo::Pg::Che;
use Scalar::Util 'refaddr';

my $class = 'Mojo::Pg::Che';
my $db_class = 'Mojo::Pg::Che::Database';
#~ my $mojo_db_class = 'Mojo::Pg::Database';
my $dbi_db_class = 'DBI::db';

plan skip_all => 'set env TEST_PG="DBI:Pg:dbname=<...>/<pg_user>/<passwd>" to enable this test' unless $ENV{TEST_PG};

my ($dsn, $user, $pw) = split m|[/]|, $ENV{TEST_PG};

# 1
my $pg1 = $class->connect($dsn, $user, $pw, {pg_enable_utf8 => 1,});
# 2
my $pg2 = $class->new->dsn($dsn)->username($user)->password($pw);
# 3
#~ my $pg3 = $class->new('postgresql://guest@/test');

isa_ok($pg1, $class);
isa_ok($pg2, $class);
#~ isa_ok($pg3, $class);

isa_ok($pg1->db, $db_class);
isa_ok($pg2->db, $db_class);
#~ isa_ok($pg3->db, $db_class);

#~ isa_ok($pg1->db, $mojo_db_class);
#~ isa_ok($pg2->db, $mojo_db_class);
#~ isa_ok($pg3->db, $mojo_db_class);

isa_ok($pg1->db->dbh, $dbi_db_class);
isa_ok($pg2->db->dbh, $dbi_db_class);
#~ isa_ok($pg3->db->dbh, $dbi_db_class);

cmp_ok(refaddr($pg1->db->dbh), '!=', refaddr($pg2->db->dbh),);

cmp_ok(refaddr($pg1), '==', refaddr($pg1->db->pg),);
cmp_ok(refaddr($pg2), '==', refaddr($pg2->db->pg),);
#~ cmp_ok(refaddr($pg3), '==', refaddr($pg3->db->pg),);



is($pg1->options->{pg_enable_utf8}, 1, 'options pg');
is($pg1->db->dbh->{pg_enable_utf8}, 1, 'options dbh');


# Invalid connection string
#~ eval { Mojo::Pg->new('http://localhost:3000/test') };
#~ like $@, qr/Invalid PostgreSQL connection string/, 'right error';

done_testing();
