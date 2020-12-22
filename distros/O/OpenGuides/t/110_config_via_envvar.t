use strict;
use warnings;
BEGIN {
  # a default config option
  $ENV{OPENGUIDES_CONFIG_SITE_NAME} = 'my test site';
  # a non default config option
  $ENV{OPENGUIDES_CONFIG_CONTACT_EMAIL} = 'testsite@example.com';
}

use Test::More;
use OpenGuides;
use OpenGuides::Test;

plan tests => 2;
my $config = OpenGuides::Test->make_basic_config;
my $guide = OpenGuides->new(config => $config);

my $output = $guide->display_about(return_output => 1,
                                format        => "opensearch"
                               );

like( $output, qr|OpenSearchDescription.*<Tags>my test site</Tags>.*|ms,
    "OpenSearch about text is displayed, including the site name which overrides a default config value with an environment variable");
like( $output, qr|OpenSearchDescription.*<Contact>testsite\@example.com</Contact>|ms,
    "OpenSearch about text is displayed, including the contact email from environment variables which does not have a default value");
