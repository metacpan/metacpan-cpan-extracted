# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl My-New-Module.t'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

use local::lib;
use Test::More tests => 5;
BEGIN { use_ok('XML::RSS::Parser::Lite') };

#########################

# Insert your test code below, the Test::More module is use()ed here so read
# its man page ( perldoc Test::More ) for help writing this test script.

my $xml=qq{
<?xml version="1.0" encoding="UTF-8"?>
<rss version="2.0">
    <channel>
        <title>My RSS v2.0 feed</title>
        <link>http://rss.example.com/site/index.html</link>
        <description>An example RSS v2.0 feed for tests purposes.</description>
        <item>
            <title>First item</title>
            <link>http://rss.example.com/site/index.html?item=1</link>
            <description>This is the 1st item</description>
            <pubDate>Tue, 01 Oct 2013 05:00:03 -0700</pubDate>
        </item>
        <item>
            <title>Second item</title>
            <link>http://rss.example.com/site/index.html?item=1</link>
            <description>This is the 2nd item</description>
            <pubDate>Tue, 01 Oct 2013 04:00:03 -0700</pubDate>
        </item>
        <item>
            <title>Third item</title>
            <link>http://rss.example.com/site/index.html?item=1</link>
            <description>This is the 3rd item</description>
            <pubDate>Tue, 01 Oct 2013 03:00:02 -0700</pubDate>
        </item>
    </channel>
</rss>
};

my $rp = new XML::RSS::Parser::Lite;
$rp->parse($xml);

cmp_ok( $rp->get("title") , "eq", "My RSS v2.0 feed", "Test channel title");
cmp_ok( $rp->get(0)->get("title") , "eq", "First item", "Test item title");
cmp_ok( $rp->count(), "==", "3", "Test count");
is( $rp->get("non-existent-tag"), undef, "Test non existent tag is undefined");

