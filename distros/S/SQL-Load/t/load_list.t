use Test::More;
use SQL::Load;

my $sql_load = SQL::Load->new('./t/sql');

my $list = $sql_load->load('list');

like(
    $list->at(1),
    qr/CREATE TABLE users [^;]+;/,
    'Test if at 1 return sql create table users'
);

like(
    $list->at(2),
    qr/CREATE TABLE articles [^;]+;/,
    'Test if at 2 return sql create table articles'
);

like(
    $list->at(3),
    qr/INSERT INTO users [^;]+;/,
    'Test if at 3 return sql insert into users'
);

like(
    $list->at(4),
    qr/INSERT INTO articles [^;]+;/,
    'Test if at 4 return sql insert into articles'
);

like(
    $list->first,
    qr/CREATE TABLE users [^;]+;/,
    'Test if first return sql create table users'
);

like(
    $list->last,
    qr/INSERT INTO articles [^;]+;/,
    'Test if last return sql insert into articles'
);

###

like(
    $sql_load->load('list#1'),
    qr/CREATE TABLE users [^;]+;/,
    'Test if at 1 return sql create table users using method load with file#at'
);

like(
    $sql_load->load('list#2'),
    qr/CREATE TABLE articles [^;]+;/,
    'Test if at 2 return sql create table articles using method load with file#at'
);

like(
    $sql_load->load('list#3'),
    qr/INSERT INTO users [^;]+;/,
    'Test if at 3 return sql insert into users using method load with file#at'
);

like(
    $sql_load->load('list#4'),
    qr/INSERT INTO articles [^;]+;/,
    'Test if at 4 return sql insert into articles using method load with file#at'
);

my $num = 1;
while (my $sql = $list->next) {
    is(
        $sql,
        $list->at($num),
        'Test if method next is equl at ' . $num
    );    
    
    $num++;
}

is(
    $list->next,
    undef,
    'Test if method next return undef after loop'
); 

done_testing;
