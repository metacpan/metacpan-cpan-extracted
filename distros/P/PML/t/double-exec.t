#!perl
###### Test executing PML Twice

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

# now check for not 1 and 2
if ($tmp =~ /This is a test/)
{
	ok(1);
}
else
{
	ok(0);
}

$tmp = $parser->execute({test => 'no'});
ok(1);

if ($tmp =~ /no/)
{
	ok(1);
}
else
{
	ok(0);
}

__END__
# this is test PML CODE
@setif("test", "This is a test")

${test}
