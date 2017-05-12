#!perl -T

use Test::More tests => 1;
use Template::Plain; 

# Default content read from DATA filehandle. Need to be careful of newlines. 
my $textref; 
my $template = Template::Plain->new();
$textref = $template->fill({ foo => 'BAR' });
ok($$textref eq "XXXBARXXX\n", 'Ctor with no args.'); 

__DATA__
XXX<% foo %>XXX
