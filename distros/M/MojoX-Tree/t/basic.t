use Mojo::Base -strict;
use Test::More;
use Mojolicious::Lite;
use Test::Mojo;
use Mojo::Util qw(dumper);
use FindBin;
use lib "$FindBin::Bin/../lib/";
use MojoX::Mysql;
use MojoX::Tree;

my %config = (
	user=>'root',
	password=>undef,
	server=>[
		{dsn=>'database=test;host=localhost;port=3306;mysql_connect_timeout=5;', type=>'master'},
		{dsn=>'database=test;host=localhost;port=3306;mysql_connect_timeout=5;', type=>'slave'},
		{dsn=>'database=test;host=localhost;port=3306;mysql_connect_timeout=5;', id=>1, type=>'master'},
		{dsn=>'database=test;host=localhost;port=3306;mysql_connect_timeout=5;', id=>1, type=>'slave'},
		{dsn=>'database=test;host=localhost;port=3306;mysql_connect_timeout=5;', id=>2, type=>'master'},
		{dsn=>'database=test;host=localhost;port=3306;mysql_connect_timeout=5;', id=>2, type=>'slave'},
	]
);
$config{'user'} = 'root' if(defined $ENV{'USER'} && $ENV{'USER'} eq 'travis');

my $mysql = MojoX::Mysql->new(%config);
my $tree = MojoX::Tree->new(mysql=>$mysql, table=>'tree', length=>10, column=>{id=>'tree_id', name=>'name', path=>'path', level=>'level', parent_id=>'parent_id'});

# Удаляем таблицу
$mysql->do("DROP TABLE IF EXISTS `tree`;");

my $sql = qq/
	CREATE TABLE `tree` (
		`tree_id` int(14) unsigned NOT NULL AUTO_INCREMENT,
		`name` varchar(255) NOT NULL,
		`path` mediumtext NOT NULL,
		`level` int(14) unsigned NOT NULL,
		`parent_id` int(14) unsigned NULL,
		PRIMARY KEY (`tree_id`),
		KEY `path` (`path`(30))
	) ENGINE=InnoDB DEFAULT CHARSET=utf8;
/;
$mysql->do($sql); # создаем таблицу

eval{ $tree->add() };
like($@, qr/invalid name/, 'invalid name');

eval{ $tree->add('test',12345) };
like($@, qr/invalid id/, 'invalid id');

my $id = $tree->add('test');
ok($id == 1,'check id');

my $result = $tree->get_id($id);
ok($result->{'level'} == 1, 'level');
ok($result->{'name'} eq 'test', 'name');
ok($result->{'path'} eq '0000000001', 'path');
ok($result->{'tree_id'} == 1, 'tree_id');
ok(ref $result->{'children'} eq 'Mojo::Collection', 'children');
ok(ref $result->{'parent'} eq 'Mojo::Collection', 'parent');

note('sub');
$id = $tree->add('тест',$id);
$result = $tree->get_id($id);
ok($result->{'path'} eq '00000000010000000002', 'path');
ok($result->{'parent_id'} == 1, 'parent_id');
ok($result->{'tree_id'} == 2, 'tree_id');
ok($result->{'name'} eq 'тест', 'name');
ok(ref $result->{'parent'} eq 'Mojo::Collection', 'parent');
ok($result->{'parent'}->size == 1, 'parent size');

$result = $tree->get_id(1);
ok($result->{'children'}->size == 1, 'children size');

$result = $tree->delete(1);
ok($result == 2, 'delete');

eval{ $tree->get_id(1) };
like($@, qr/invalid id/, 'invalid id');

note('move');
my $id1 = $tree->add('root1');
my $id2 = $tree->add('root2');
my $id3 = $tree->add('root3',$id2);

eval{ $tree->move($id1,$id1) };
like($@, qr/Impossible to transfer to itself or children/, 'Impossible to transfer to itself or children');

eval{ $tree->move($id3,$id2) };
like($@, qr/Impossible to transfer to itself or children/, 'Impossible to transfer to itself or children');

$tree->move($id2,$id1);
$result = $tree->get_id($id1);
ok(ref $result->{'children'} eq 'Mojo::Collection', 'children');
ok($result->{'children'}->size == 2, 'children size');

$mysql->db->commit;

done_testing();


