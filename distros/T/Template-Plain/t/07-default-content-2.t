#!perl -T

use Test::More tests => 1;
use Template::Plain; 

# Default content read from DATA filehandle. Need to be careful of newlines. 
my $textref; 
$textref = Template::Plain->fill({ foo => 'BAR' });
ok($$textref eq "XXXBARXXX\n", 'calling fill as class method'); 

__DATA__
XXX<% foo %>XXX
