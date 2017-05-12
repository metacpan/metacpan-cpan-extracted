use strict;
use warnings;

use Test::More tests => 2;
use Abstract::Meta::Class ':all';

my $class;

BEGIN {
    $class = 'Persistence::Attribute::AMCAdapter';
    use_ok($class);
}

my $attr = Persistence::Attribute::AMCAdapter->new(column_name => 'ename', attribute => (has '$.name'));
isa_ok($attr, 'Persistence::Attribute');

