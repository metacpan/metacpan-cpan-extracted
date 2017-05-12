#!perl -T

use Test::More tests => 2;
use Template::Plain; 

my $textref; 

# Test Changing the delimiters with one arg. 
my $template = Template::Plain->new('XXX[% placeholder %]XXX'); 
$template->delimiters( ['[%', '%]'] ); 
$textref = $template->fill({ placeholder => '0123456789' });
ok ($$textref eq "XXX0123456789XXX", 'delimiters: one arg');

# Test Changing the delimiters with two args. 
my $template_2 = Template::Plain->new('XXX[: placeholder :]XXX'); 
$template_2->delimiters('[:', ':]'); 
$textref = $template_2->fill({ placeholder => '0123456789' });
ok ($$textref eq "XXX0123456789XXX", 'delimiters: two arg');


