use strict;
use warnings;

use lib "lib";
use lib "t/testapp/lib";

use Test::More;
use Plack::Builder;
use Plack::Test;
use HTTP::Request;
use HTTP::Request::Common;

$ENV{DANCER_CONFDIR} = 't/testapp';
$ENV{DANCER_ENVIRONMENT} = 'no_login';
require Strehler::Admin;
require Strehler::RSS;
require t::testapp::lib::TestSupport;

TestSupport::reset_database();

my $admin_app = Strehler::Admin->to_app;
my $rss_app = Strehler::RSS->to_app;
my $channel = undef;
my $site = "http://localhost";

my $rss1 = q{<\\?xml version="1.0" encoding="UTF-8"\\?>

<rss version="2.0"
 xmlns:atom="http://www.w3.org/2005/Atom"
 xmlns:blogChannel="http://backend.userland.com/blogChannelModule"
 xmlns:content="http://purl.org/rss/1.0/modules/content/"
 xmlns:dcterms="http://purl.org/dc/terms/"
 xmlns:geo="http://www.w3.org/2003/01/geo/wgs84_pos#"
>

<channel>
<title>Test RSS</title>
<link>http://test.test</link>
<description>Test channel</description>
<language>it</language>
<generator>Strehler::RSS .*</generator>

<item>
<title>test 2</title>
<link>http://test.test/page/2-test-2</link>
<guid isPermaLink="true">http://test.test/page/2-test-2</guid>
<content:encoded>test article 2</content:encoded>
</item>
<item>
<title>test 1</title>
<link>http://test.test/page/1-test-1</link>
<guid isPermaLink="true">http://test.test/page/1-test-1</guid>
<content:encoded>test article 1</content:encoded>
</item>
</channel>
</rss>};

my $rss2 = q{<\\?xml version="1.0" encoding="UTF-8"\\?>

<rss version="2.0"
 xmlns:atom="http://www.w3.org/2005/Atom"
 xmlns:blogChannel="http://backend.userland.com/blogChannelModule"
 xmlns:content="http://purl.org/rss/1.0/modules/content/"
 xmlns:dcterms="http://purl.org/dc/terms/"
 xmlns:geo="http://www.w3.org/2003/01/geo/wgs84_pos#"
>

<channel>
<title>Test RSS</title>
<link>http://test.test</link>
<description>Test channel</description>
<language>it</language>
<generator>Strehler::RSS .*</generator>

<item>
<title>test 3</title>
<link>http://test.test/page/3-test-3</link>
<guid isPermaLink="true">http://test.test/page/3-test-3</guid>
<content:encoded>Test article 3</content:encoded>
</item>
<item>
<title>test 2</title>
<link>http://test.test/page/2-test-2</link>
<guid isPermaLink="true">http://test.test/page/2-test-2</guid>
<content:encoded>test article 2</content:encoded>
</item>
<item>
<title>test 1</title>
<link>http://test.test/page/1-test-1</link>
<guid isPermaLink="true">http://test.test/page/1-test-1</guid>
<content:encoded>test article 1</content:encoded>
</item>
</channel>
</rss>};

test_psgi $admin_app, sub {
    my $cb = shift;
    
    #LIST
    my $r = $cb->(GET '/admin/rsschannel/list');
    is($r->code, 200, "RSS page correctly accessed");
    #ADD        

    $r = $cb->(POST "/admin/rsschannel/add",
                    'Content_Type' => 'form-data',
                    'Content' =>  [
                        'link' => "http://test.test",
                        'entity_type' => 'article',
                        'category-name' => 'dummy',
                        'category' => 1,
                        'titlefield-select' => 'title',
                        'title_field' => 'title',
                        'descriptionfield-select' => 'text',
                        'description_field' => 'text',
                        'linkfield-select' => 'slug',
                        'link_field' => 'slug',
                        'link_template' => 'http://test.test/page/%%',
                        'order_by' => 'id',
                        'title_it' => "Test RSS",
                        'description_it' => "Test channel",
                        'strehl-action' => 'submit-publish' ]);

    is($r->code, 302, "Add - RSS submitted, navigation redirected to list (submit-publish)");
    my $channels = Strehler::Element::RSS::RSSChannel->get_list({ 'ext' => 1});
    $channel = $channels->{'to_view'}->[0];


};

test_psgi $rss_app, sub {
    my $cb = shift;
    my $link_to_rss = '/rss/it/' . $channel->{'slug'} . ".xml";
    my $r = $cb->(GET $link_to_rss);
    like($r->content, qr/$rss1/, "RSS generated at $link_to_rss OK");
};

test_psgi $admin_app, sub {
    my $cb = shift;
    
    #EDIT
    my $r = $cb->(POST "/admin/rsschannel/add",
                    'Content_Type' => 'form-data',
                    'Content' =>  [
                        'link' => "http://test.test",
                        'entity_type' => 'article',
                        'category-name' => 'dummy',
                        'category' => 1,
                        'deep' => 1,
                        'titlefield-select' => 'title',
                        'title_field' => 'title',
                        'descriptionfield-select' => 'text',
                        'description_field' => 'text',
                        'linkfield-select' => 'slug',
                        'link_field' => 'slug',
                        'link_template' => 'http://test.test/page/%%',
                        'order_by' => 'id',
                        'title_it' => "Test RSS",
                        'description_it' => "Test channel",
                        'strehl-action' => 'submit-publish' ]);

    is($r->code, 302, "Edit - RSS submitted, navigation redirected to list (submit-publish)");
    my $channels = Strehler::Element::RSS::RSSChannel->get_list({ 'ext' => 1});
    $channel = $channels->{'to_view'}->[0];
};

test_psgi $rss_app, sub {
    my $cb = shift;
    my $link_to_rss = '/rss/it/' . $channel->{'slug'} . ".xml";
    my $r = $cb->(GET $link_to_rss);
    my $retrieved_link = Strehler::Element::RSS::RSSChannel->get_link('article', 'dummy', 'it');
    is($retrieved_link, $link_to_rss, "Link retrieving method works");
    like($r->content, qr/$rss2/, "RSS changed, deep flagged OK");
};

test_psgi $admin_app, sub {
    my $cb = shift;
    #DELETE
    my $r = $cb->(POST "/admin/rsschannel/delete/" . $channel->{'id'});
    my $rss_object = Strehler::Element::RSS::RSSChannel->new($channel->{'id'});
    ok(! $rss_object->exists(), "RSS correctly deleted");
};
done_testing();
