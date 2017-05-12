use strict;
use warnings;
use Test::More tests => 7;
#use Test::More "no_plan";

use FindBin;
use File::Spec;
use lib File::Spec->catfile($FindBin::Bin, 'lib');

use XML::Feed;
use YAML;
use Text::Wrap;
use Encode;

use_ok("RSSycklr");
ok( my $rsklr = RSSycklr->new(),
    "New RSSyclr");

can_ok($rsklr, qw( xml_parser feeds truncater ));

ok( $rsklr->add_feeds([{ uri => "http://dd.pangyre.org/dd.atom" }]),
    "add_feeds" );

ok( $rsklr->add_feeds([{ uri => "http://opendevil.org/d/dd/feed/atom" }]),
    "add_feeds" );

my $yaml = Dump(config_data());

ok( $rsklr->load_config($yaml),
    "load_config()" );

SKIP: {
    skip "Set TEST_HTTP to run live tests which are frankly not worth running yet", 1
        unless $ENV{TEST_HTTP};

    ok( $rsklr->feeds,
        "feeds()" );

    for my $feed ( $rsklr->feeds() )
        {

            diag( Encode::encode_utf8( $feed->title ) ) if $ENV{TEST_VERBOSE};

            for my $entry ( $feed->entries )
                {
                    diag( "\t" . Encode::encode_utf8($entry->title) ) if $ENV{TEST_VERBOSE};
                    diag( wrap("\t","\t",Encode::encode_utf8($entry->lede)) )
                        if $entry->lede and $ENV{TEST_VERBOSE};
                }
            diag( "" ) if $ENV{TEST_VERBOSE};
        }
}

exit 0;

sub config_data {
    {
        max_feeds => 1,
        max_entries => 100, # THIS DOES NOTHING YET
        'hours_back' => '30',
        'max_display' => '3',
        'excerpt_length' => '110',
        'feeds' => [
                        {
                   'max_display' => '5',
                   'uri' => 'http://green.yahoo.com/rss/blogs/all'
                  },
                  {
                   'uri' => 'http://feeds.feedburner.com/grist/gristfeed'
                  },
                  {
                   'title_only' => '1',
                   'uri' => 'http://green.yahoo.com/rss/featured'
                  },
                  {
                   'uri' => 'http://feeds.feedburner.com/greenlivingarticles'
                  },
                  {
                   'excerpt_length' => '300',
                   'max_display' => '1',
                   'uri' => 'http://feeds.feedburner.com/TheGreenGuide'
                  },
                  {
                   'uri' => 'http://www.hugg.com/rss.xml'
                  },
                  {
                   'uri' => 'http://www.ecosherpa.com/feed/'
                  },
                  {
                   'uri' => 'http://www.groovygreen.com/groove/?feed=atom'
                  },
                  {
                   'title_only' => '1',
                   'uri' => 'http://blog.epa.gov/blog/feed/'
                  },
                  {
                   'uri' => 'http://green.yahoo.com/rss/news'
                  },
                  {
                   'title_only' => '1',
                   'max_display' => '25',
                   'uri' => 'http://news.google.com/news?rls=en-us&oe=UTF-8&um=1&tab=wn&hl=en&q=Environmental&ie=UTF-8&output=atom'
                  }
                 ],
             };
    ;
}

__END__

#diag("*******" . Dump(XML::Feed->parse(URI->new("http://dd.pangyre.org/atom.xml"))));

#ok( my $test_feed = XML::Feed->parse(URI->new("http://dd.pangyre.org/dd.atom")),
#    "Manually creating an XML::Feed.");

#is_deeply( $rsklr->feeds(), [ $test_feed ],
#           "feeds() returns correct feeds." );

# diag Dump($rsklr);

# diag( $rsklr->truncate("<p>Oh, hai. I'm about this long.</p>", 10) );
