use strict;
use warnings;

use Test::More tests => 7;
#use Test::More "no_plan";

use FindBin;
use File::Spec;
use lib File::Spec->catfile($FindBin::Bin, 'lib');


use RSSycklr;

ok( my $rsklr = RSSycklr->new(),
    "New RSSyclr");

ok( $rsklr->add_feeds([{ uri => "http://dd.pangyre.org/dd.atom" }]),
    "add_feeds" );

ok( $rsklr->add_feeds([{ uri => "http://opendevil.org/d/dd/feed/atom" }]),
    "add_feeds" );

ok( $rsklr->config->{hours_back} = 200,
    "Setting hours_back through config" );

SKIP: {
    skip "Set TEST_HTTP to run live tests which are frankly not worth running yet", 3
        unless $ENV{TEST_HTTP};

    my $output = "";
    ok( $rsklr->process($rsklr->template, { rssycklr => $rsklr }, \$output),
        "process()" );
    ok( my $as_string = $rsklr->as_string(),
        "as_string()" );
    is( $output, $as_string,
        "Manually processed and as_string are the same" );
}

exit 0;
