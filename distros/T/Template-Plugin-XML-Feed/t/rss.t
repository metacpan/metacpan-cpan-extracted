use strict;
use lib qw( lib ../lib );
use Template;
use Template::Test;
use Cwd qw( abs_path );

eval "use XML::Feed";
skip_all('XML::Feed') if $@;

# account for script being run in distribution root or 't' directory
my $file = abs_path( -d 't' ? 't/xml' : 'xml' );
$file .= '/example.rdf';   

local *RSS;
open RSS, $file or die "Can't open $file: $!";
my $data = join "" => <RSS>;
close RSS;

test_expect(\*DATA, undef, { 'newsfile' => $file, 'newsdata' => \$data });

__END__
-- test --
[% USE news = XML.Feed(newsfile) -%]
[% FOREACH item = news.entries -%]
* [% item.title %]
  [% item.link  %]

[% END %]

-- expect --
* I Read the News Today
  http://oh.boy.com/

* I am the Walrus
  http://goo.goo.ga.joob.org/

-- test --
[% USE news = XML.Feed(newsfile) -%]
[% news.title %]
[% news.link %]

-- expect --
Template Toolkit XML::Feed Plugin
http://search.cpan.org/dist/Template-Plugin-XML-Feed

-- test --
[% USE news = XML.Feed(newsfile) -%]
[% news.rss.image.title %]
[% news.rss.image.url %]

-- expect --
Test Image
http://www.myorg.org/images/test.png

-- test --
[% USE news = XML.Feed(newsdata) -%]
[% FOREACH item = news.items -%]
* [% item.title %]
  [% item.link  %]

[% END %]

-- expect --
* I Read the News Today
  http://oh.boy.com/

* I am the Walrus
  http://goo.goo.ga.joob.org/

-- test --
[% USE news = XML.Feed(newsdata) -%]
[% news.title %]
[% news.link %]

-- expect --
Template Toolkit XML::Feed Plugin
http://search.cpan.org/dist/Template-Plugin-XML-Feed

-- test --
[% USE news = XML.Feed(newsdata) -%]
[% news.rss.image.title %]
[% news.rss.image.url %]

-- expect --
Test Image
http://www.myorg.org/images/test.png



