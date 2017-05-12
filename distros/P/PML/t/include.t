#!perl
###### Test PML include function

use strict;
use Test;

BEGIN{plan test => 3};

use PML;

my $parser = new PML;

my @code = <DATA>;

$parser->parse(\@code);
ok(1);

my $tmp = $parser->execute;
ok(1);

# now check for 1 2
if ($tmp =~ /1/ and $tmp =~ /2/)
{
	ok(1);
}
else
{
	ok(0);
}

__END__
# this is test PML CODE
1

@include("t/include.pmlh")
