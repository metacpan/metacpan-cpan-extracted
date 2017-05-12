#!perl -T

use Test::More tests => 3;
use Template::Plain; 

# Test that we create the template object with a small template passed as an argument. 
my $template = new_ok('Template::Plain' => [ 'Hello <% world %>!' ]); 

# Test that we filled the template and it worked as expected.  
my $textref; 
$textref = $template->fill({world => 'there'});
ok ($$textref eq 'Hello there!', "fill()");

$textref = $template->fill({world => 'perl'});
ok ($$textref eq 'Hello perl!', "fill() again");

