#!perl -T

use Test::More tests => 1;
use Template::Plain; 

my $textref; 
my $template = Template::Plain->new('XXX<% placeholder %>XXX'); 
$template->fill({ placeholder => '<% placeholder %><% placeholder %>' }, 1);
$textref = $template->fill({ placeholder => '0123456789' });
ok ($$textref eq "XXX01234567890123456789XXX", 'recursive fill');


