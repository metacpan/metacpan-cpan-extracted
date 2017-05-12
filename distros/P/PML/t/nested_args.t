#!perl
###### Test if PML chokes on nested args

use strict;
use Test;

BEGIN{plan test => 5};

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

__END__
# this is test PML CODE

@if (@perl{1})
{
	1
}

@if (@perl{"2"})
{
	2
}

# now a really crazy looking one!

@if
(
	@perl
	{
		my $x;
		$x = "{"; #}
		$x = '@';
		$x = '$';
		$x = 3;
		return $x;
	}
)
{
	3
}
