#!perl
###### Test PML functions that are in the middle of a sentance

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

ok($tmp =~ /it\s+worked/);
__END__
@macro('GO')
{worked}

it @GO() yeah
