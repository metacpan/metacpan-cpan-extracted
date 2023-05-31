use Test::More;
use SQL::Load;

my $sql_load = SQL::Load->new('./t/sql', "\n");

my $admins = $sql_load->load('admins');

my $select = $admins->name('select');
is($select, "SELECT id, name, create\n", 'Test if select is equal!');

my $from = $admins->name('from');
is($from, "FROM admins\n", 'Test if from is equal!');

my $where_find = $admins->name('where-find');
is($where_find, "WHERE id = ?\n", 'Test if where-find is equal!');

my $where_search = $admins->name('where-search');
is($where_search , "WHERE name LIKE ?\n", 'Test if where-search  is equal!');

my $limit_find = $admins->name('limit-find');
is($limit_find, "LIMIT 1\n", 'Test if limit-find is equal!');

my $limit_search = $admins->name('limit-search');
is($limit_search, "LIMIT ?, ?\n", 'Test if limit-search is equal!');

# mount select find
my $find = $select;
$find .= $from;
$find .= $where_find;
$find .= $limit_find;

is(
    $find,
    "SELECT id, name, create\nFROM admins\nWHERE id = ?\nLIMIT 1\n",
    'Test if the find is equal mounted!'
);

# mount select search
my $search = $select;
$search .= $from;
$search .= $where_search;
$search .= $limit_search;

is(
    $search,
    "SELECT id, name, create\nFROM admins\nWHERE name LIKE ?\nLIMIT ?, ?\n",
    'Test if the search is equal mounted!'
);

done_testing;
