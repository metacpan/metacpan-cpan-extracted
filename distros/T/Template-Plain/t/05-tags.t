#!perl -T

use Test::More tests => 1;
use Template::Plain; 

my $textref; 
my $template = Template::Plain->new('<% foo %><%bar%><% foo%><%baz %>'); 
my @tags = $template->tags(); 
is_deeply(\@tags, ['foo', 'bar', 'foo', 'baz'], 'tags'); 


