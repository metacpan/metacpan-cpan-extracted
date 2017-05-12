#!perl -T

use Test::More tests => 3;
use Template::Plain; 

# Test that we create the template object with a small template passed as an argument. 
my $template = Template::Plain->new( 'XXX<% placeholder %>XXX' ); 

# Fill with an array ref. 
my $textref; 
$textref = $template->fill({ placeholder => ['foo', 'bar', 'baz'] });
ok ($$textref eq "XXXfoo\nbar\nbazXXX", 'fill() with an arrayref');

# Change the list separator
$template->list_separator(':');
$textref = $template->fill({ placeholder => ['qux', 'baz', 'bar'] });
ok ($$textref eq 'XXXqux:baz:barXXX', 'list_separator()');


# Fill with a code ref. 
sub qux { return "qux quxx quxxx" } 
$textref = $template->fill({ placeholder => \&qux });
ok ($$textref eq 'XXXqux quxx quxxxXXX', 'fill() with a coderef');

