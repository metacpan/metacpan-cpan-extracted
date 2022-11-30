use Test::More;
use SQL::Load::Util qw/
    name_list
    parse
    remove_extension
    trim
/;

my $name_list_1 = name_list('find-by-username');
for my $name (@$name_list_1) {
    like(
        $name, 
        qr/(find-by-username|find_by_username|FindByUsername)/, 
        'Test name (' . $name . ') is equal'
    );
}

my $name_list_2 = name_list('get_all_users');
for my $name (@$name_list_2) {
    like(
        $name, 
        qr/(get-all-users|get_all_users|GetAllUsers)/, 
        'Test name (' . $name . ') is equal'
    );
}

my $name_list_3 = name_list('DeleteByUsername');
for my $name (@$name_list_3) {
    like(
        $name, 
        qr/(delete-by-username|delete_by_username|DeleteByUsername)/, 
        'Test name (' . $name . ') is equal'
    );
}

my $sql_1 = q{
-- # foo
SELECT * FROM foo;

-- [bar]
SELECT * FROM bar;

-- (baz)
SELECT * FROM baz;
};

my %parse_1 = (parse($sql_1));

for my $name (keys %parse_1) {
    my $value = $parse_1{$name};

    like($name, qr/(foo|bar|baz)/, 'Test name ' . $name . ' from parse');
    like($value, qr/SELECT \* FROM (foo|bar|baz);/, 'Test value ' . $name . ' from parse');
}

my $sql_2 = q{
SELECT * FROM foo;

SELECT * FROM bar;

SELECT * FROM baz;
};

my %parse_2 = (parse($sql_2));

for my $number (keys %parse_2) {
    my $value = $parse_2{$number};
    
    like($number, qr/(1|2|3)/, 'Test name ' . $number . ' from parse');
    like($value, qr/SELECT \* FROM (foo|bar|baz);/, 'Test value ' . $number . ' from parse');
}

my $sql_3 = q{
SELECT 
    id,
    name,
    email
FROM 
    users
WHERE
    id = ?
LIMIT 
    1;
};

my %parse_3 = (parse($sql_3));
is($parse_3{1}, trim($sql_3), 'Test if default is same sql');

my $remove_extension_1 = remove_extension('path/users.sql');
is($remove_extension_1, 'path/users', 'Test removed extension from file name (path/users.sql)');

my $remove_extension_2 = remove_extension('articles.SQL');
is($remove_extension_2, 'articles', 'Test removed extension from file name (articles.SQL)');

my $remove_extension_3 = remove_extension('contacts.Sql');
is($remove_extension_3, 'contacts', 'Test removed extension from file name (contacts.Sql)');

my $trim_1 = trim('  foo   ');
is($trim_1, 'foo', 'Test remove spaces at start and end');

my $trim_2 = trim('  bar');
is($trim_2, 'bar', 'Test remove spaces at start');

my $trim_3 = trim('baz   ');
is($trim_3, 'baz', 'Test remove spaces at end');

done_testing;
