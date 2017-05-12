use strict;
use warnings;

use Test::More;
use OpenGuides;
use OpenGuides::Test;

plan tests => 3;

my $config = OpenGuides::Test->make_basic_config;
$config->site_name('My site');
$config->contact_email('me@example.com');
my $guide = OpenGuides->new(config => $config);

my $output = $guide->display_about(return_output => 1);

like( $output, qr|My site</a></h1>.*<h2>is powered by|ms,
    "HTML about text is displayed, including the site name" );

$output = $guide->display_about(return_output => 1,
                                format        => "opensearch"
                               );

like( $output, qr|OpenSearchDescription.*<Tags>My site</Tags>.*<Contact>me\@example.com</Contact>|ms,
    "OpenSearch about text is displayed, including the site name and contact");

$output = $guide->display_about(return_output => 1,
                                format        => "rdf"
                               );

like( $output, qr|<Project rdf:ID="OpenGuides">|ms,
    "RDF about text is displayed");
