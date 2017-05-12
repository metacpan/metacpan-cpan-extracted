#!perl -w
use strict;
use Test::More tests => 1;
use SQL::Type::Guess;

my @data= (
{
    fool => 1,
    when => '20140401',
    greeting => 'Hello',
    value => '1.05'
},
{
    fool => 0,
    when => '20140402',
    greeting => 'World',
    value => '99.05'
},
{
    fool => 0,
    when => '20140402',
    greeting => 'World',
    value => '9.005'
},
);

my $g= SQL::Type::Guess->new();
$g->guess( @data );

is $g->as_sql( table => 'test' ), <<'SQL', 'Synopsis';
create table test (
    "fool" decimal(1,0),
    "greeting" varchar(5),
    "value" decimal(5,3),
    "when" date
)
SQL
