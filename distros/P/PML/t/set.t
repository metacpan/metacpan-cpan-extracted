#!perl
###### Test PML set functions

use strict;
use Test;

BEGIN{plan test => 8};

use PML;

my $parser = new PML;

my @code = <DATA>;

$parser->parse(\@code);
ok(1);

my $tmp = $parser->execute;
ok(1);

ok($tmp =~ /1/);
ok($tmp =~ /2/);
ok($tmp =~ /3/);
ok($tmp =~ /4 5/);
ok($tmp =~ /7 6/);
ok($tmp !~ /8/);
__END__
# this is test PML CODE
@warning(1)

@set('a', 1)
@set('b', 2, 3)
@set('c', 4)
@append('c', 5)
@set('d', 6)
@prepend('d', 7)

@if (${a})
{
	${a}
}

@if (${b[0]})
{
	${b[0]} ${b[1]}
}

@if (${c})
{
	${c}
}

@if (${d})
{
	${d}
}

@setif('a', 8)
${a}
