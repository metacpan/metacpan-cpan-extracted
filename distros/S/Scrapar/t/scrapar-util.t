use strict;
use Test::More tests => 10;
use utf8;
#use Test::More 'no_plan';
use Data::Dumper;

BEGIN { use_ok('Scrapar::Util') }

sub test_find_email {
  my %Tests = (
	       #   'Hahah!  Use "@".+*@[132.205.7.51] and watch them cringe!'
	       #       => '"@".+*@[132.205.7.51]',
	       'What about "@"@foo.com?' => '"@"@foo.com',
	       'Eli the Beared <*@qz.to>' => '*@qz.to',
	       #	'"@"+*@[132.205.7.51]'    => '+*@[132.205.7.51]',
	       'somelongusername@aol.com' => 'somelongusername@aol.com',
	       '%2Fjoe@123.com' => '%2Fjoe@123.com',
	       'joe@123.com?subject=hello.' => 'joe@123.com',
	      );

  while (my($text, $expect) = each %Tests) {
    my $found = Scrapar::Util::find_email($text);
    is $found => $expect;
  }
}

sub test_find_links {
  my $text = q[  'url' => '<a href="/redirect?url=http%3A%2F%2Fwww%2Ebeckautomation%2Ecom%2F">http://www.beckautomation.com/</a>' ];

#  print Dumper Scrapar::Util::find_links($text);
}

sub test_escape_uri {
  my $url = 'http%3A%2F%2Fwww%2Ebeckautomation%2Ecom%2F';
  is Scrapar::Util::escape_uri($url), 'http://www.beckautomation.com/';
}

sub test_html_query {
  my $html = '<html><body><a href="/">Link</a></body></html>';
  my @result = Scrapar::Util::html_query($html, 'body');
  is $result[0]->as_text, 'Link';

  # test wantarray().
  is Scrapar::Util::html_query($html, 'body')->[0]->as_text, 'Link';
}

sub test_decode_html_entities {
  my $html = '<a href="/intl/zh-TW/privacy.html">&#x96B1;&#x79C1;&#x6B0A;&#x653F;&#x7B56;</a>';
  like Scrapar::Util::decode_html_entities($html), qr[隱私權政策];
}

test_find_email();
test_find_links();
test_escape_uri();
test_html_query();
test_decode_html_entities();
