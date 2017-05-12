use strict;
use Wiki::Toolkit::Setup::SQLite;
use File::Temp qw( tempfile );
use OpenGuides;
use OpenGuides::Test;
use Test::More;

eval { require DBD::SQLite; };
if ( $@ ) {
    my ($error) = $@ =~ /^(.*?)\n/;
    plan skip_all => "DBD::SQLite could not be used - no database to test with ($error)";
}

plan tests => 4;

# Clear out the database from any previous runs.
    OpenGuides::Test::refresh_db();

my $config = OpenGuides::Test->make_basic_config;
my $guide = OpenGuides->new( config => $config );

# Print some RSS to a temporary file, and use a 'file://' URL to save faff.
my ($fh, $filename) = tempfile( UNLINK => 1 );
while ( my $line = <DATA> ) {
    print $fh $line;
}
close $fh;
my $url = 'file://' . $filename;

OpenGuides::Test->write_data(
                               guide   => $guide,
                               node    => "Crabtree Tavern",
                               content => '@RSS ' . $url,
                             );
OpenGuides::Test->write_data(
                               guide   => $guide,
                               node    => "Crabtree Tavern",
                               content => '@RSS ' . $url,
                             );
my $output = eval {
    $guide->display_diffs(
                           id            => "Crabtree Tavern",
                           version       => 1,
                           other_version => 2,
                           return_output => 1,
                         );
};
is( $@, "",
    "->display_diffs doesn't die when called on a node with RSS feeds in" );

OpenGuides::Test->write_data(
                               guide   => $guide,
                               node    => "Calthorpe Arms",
                               content => '@INDEX_LIST [[Category Foo]]',
                             );
OpenGuides::Test->write_data(
                               guide   => $guide,
                               node    => "Calthorpe Arms",
                               content => '@INDEX_LIST [[Category Foo]]',
                             );
$output = eval {
    $guide->display_diffs(
                           id            => "Calthorpe Arms",
                           version       => 1,
                           other_version => 2,
                           return_output => 1,
                         );
};
is( $@, "",
    "...or on a node with INDEX_LIST in" );

OpenGuides::Test->write_data(
                               guide   => $guide,
                               node    => "Penderel's Oak",
                               content => '@INDEX_LINK [[Category Foo]]',
                             );
OpenGuides::Test->write_data(
                               guide   => $guide,
                               node    => "Penderel's Oak",
                               content => '@INDEX_LINK [[Category Foo]]',
                             );
$output = eval {
    $guide->display_diffs(
                           id            => "Penderel's Oak",
                           version       => 1,
                           other_version => 2,
                           return_output => 1,
                         );
};
is( $@, "",
    "...or on a node with INDEX_LINK in" );
like( $output, qr|view all pages in category foo|i,
      "...and index link is correct" );


__DATA__
<?xml version="1.0" encoding="UTF-8"?>

<rdf:RDF
 xmlns:rdf="http://www.w3.org/1999/02/22-rdf-syntax-ns#"
 xmlns="http://purl.org/rss/1.0/"
 xmlns:taxo="http://purl.org/rss/1.0/modules/taxonomy/"
 xmlns:dc="http://purl.org/dc/elements/1.1/"
 xmlns:syn="http://purl.org/rss/1.0/modules/syndication/"
 xmlns:wiki="http://purl.org/rss/1.0/modules/wiki/"
 xmlns:admin="http://webns.net/mvcb/"
>

<channel rdf:about="http://london.randomness.org.uk/kakemirror/?RecentChanges">
<title>The Open Guide to London - Kake's Mirror</title>
<link>http://london.randomness.org.uk/kakemirror/?RecentChanges</link>
<description></description>
<dc:date>2004-12-14T12:59:42</dc:date>
<wiki:interwiki></wiki:interwiki>
<items>
 <rdf:Seq>
  <rdf:li rdf:resource="http://london.randomness.org.uk/kakemirror/?id=Buckingham_Arms%2C_SW1H_9EU;version=9" />
  <rdf:li rdf:resource="http://london.randomness.org.uk/kakemirror/?id=Buckingham_Arms%2C_SW1H_9EU;version=8" />
  <rdf:li rdf:resource="http://london.randomness.org.uk/kakemirror/?id=Star_Tavern%2C_SW1X_8HT;version=14" />
  <rdf:li rdf:resource="http://london.randomness.org.uk/kakemirror/?id=Star_Tavern%2C_SW1X_8HT;version=13" />
  <rdf:li rdf:resource="http://london.randomness.org.uk/kakemirror/?id=Star_Tavern%2C_SW1X_8HT;version=12" />
 </rdf:Seq>
</items>
</channel>

<item rdf:about="http://london.randomness.org.uk/kakemirror/?id=Buckingham_Arms%2C_SW1H_9EU;version=9">
<title>Buckingham Arms, SW1H 9EU</title>
<link>http://london.randomness.org.uk/kakemirror/?id=Buckingham_Arms%2C_SW1H_9EU;version=9</link>
<description>extraneous : [bob]</description>
<dc:date>2004-12-12T13:25:27</dc:date>
<dc:contributor>bob</dc:contributor>
<wiki:history></wiki:history>
<wiki:importance>minor</wiki:importance>
<wiki:version>9</wiki:version>
<wiki:status>updated</wiki:status>
<wiki:diff></wiki:diff>
</item>

<item rdf:about="http://london.randomness.org.uk/kakemirror/?id=Buckingham_Arms%2C_SW1H_9EU;version=8">
<title>Buckingham Arms, SW1H 9EU</title>
<link>http://london.randomness.org.uk/kakemirror/?id=Buckingham_Arms%2C_SW1H_9EU;version=8</link>
<description> [Martin]</description>
<dc:date>2004-12-11T14:05:38</dc:date>
<dc:contributor>Martin</dc:contributor>
<wiki:history></wiki:history>
<wiki:importance>major</wiki:importance>
<wiki:version>8</wiki:version>
<wiki:status>updated</wiki:status>
<wiki:diff></wiki:diff>
</item>

<item rdf:about="http://london.randomness.org.uk/kakemirror/?id=Star_Tavern%2C_SW1X_8HT;version=14">
<title>Star Tavern, SW1X 8HT</title>
<link>http://london.randomness.org.uk/kakemirror/?id=Star_Tavern%2C_SW1X_8HT;version=14</link>
<description>De-bobbed the bob bits. [Kake]</description>
<dc:date>2004-12-10T14:29:13</dc:date>
<dc:contributor>Kake</dc:contributor>
<wiki:history></wiki:history>
<wiki:importance>minor</wiki:importance>
<wiki:version>14</wiki:version>
<wiki:status>updated</wiki:status>
<wiki:diff></wiki:diff>
</item>

<item rdf:about="http://london.randomness.org.uk/kakemirror/?id=Star_Tavern%2C_SW1X_8HT;version=13">
<title>Star Tavern, SW1X 8HT</title>
<link>http://london.randomness.org.uk/kakemirror/?id=Star_Tavern%2C_SW1X_8HT;version=13</link>
<description>More comments. [Kake]</description>
<dc:date>2004-12-10T14:27:41</dc:date>
<dc:contributor>Kake</dc:contributor>
<wiki:history></wiki:history>
<wiki:importance>major</wiki:importance>
<wiki:version>13</wiki:version>
<wiki:status>updated</wiki:status>
<wiki:diff></wiki:diff>
</item>

<item rdf:about="http://london.randomness.org.uk/kakemirror/?id=Star_Tavern%2C_SW1X_8HT;version=12">
<title>Star Tavern, SW1X 8HT</title>
<link>http://london.randomness.org.uk/kakemirror/?id=Star_Tavern%2C_SW1X_8HT;version=12</link>
<description>updated [bob]</description>
<dc:date>2004-12-10T14:18:51</dc:date>
<dc:contributor>bob</dc:contributor>
<wiki:history></wiki:history>
<wiki:importance>minor</wiki:importance>
<wiki:version>12</wiki:version>
<wiki:status>updated</wiki:status>
<wiki:diff></wiki:diff>
</item>

</rdf:RDF>
