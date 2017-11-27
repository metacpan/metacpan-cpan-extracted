use strict;
use warnings;
use FindBin;
use lib "$FindBin::Bin/../../";
use t::scan::Util;

test(<<'TEST'); # SPROUT/HTML-DOM-0.056/lib/HTML/DOM.pm
sub base {
	my $doc = shift;
	if(
	 my $base_elem = $doc->look_down(_tag => 'base', href => qr)(?:\)))
	){
		return ''.$base_elem->attr('href');
	}
	else {
		no warnings 'uninitialized';
		''.base{$$doc{_HTML_DOM_response}||return$doc->URL}
	}
}
TEST

test(<<'TEST'); # SPROUT/WWW-Scripter-0.031/lib/WWW/Scripter.pm
 if(!CORE::length $name and my $doc = document $self) {
  if(my $base_elem = $doc->look_down(_tag => 'base', target => qr)(?:\)))){
   $name = $base_elem->attr('target');
  }
 }
TEST

test(<<'TEST'); # SPROUT/WWW-Scripter-0.031/lib/WWW/Scripter.pm
 if(!CORE::length $name and my $doc = document $self) {
  if(my $base_elem = $doc->look_down(_tag => 'base', target => qr)(?:\)))){
   $name = $base_elem->attr('target');
  }
 }
TEST

done_testing;
