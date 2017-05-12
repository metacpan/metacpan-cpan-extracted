use strict;
use Wiki::Toolkit::Setup::SQLite;
use OpenGuides;
use OpenGuides::Test;
use Test::More;

eval { require DBD::SQLite; };

if ( $@ ) {
    my ($error) = $@ =~ /^(.*?)\n/;
    plan skip_all => "DBD::SQLite could not be used - no database to test with ($error)";
}

eval { require Test::HTML::Content; };
my $thc = $@ ? 0 : 1;

plan tests => 4;

OpenGuides::Test::refresh_db();

my $config = OpenGuides::Test->make_basic_config;
$config->script_name( "mywiki.cgi" );
$config->script_url( "http://example.com/" );
my $guide = OpenGuides->new( config => $config );

$guide->wiki->write_node( "South Croydon Station", "A sleepy main-line station in what is arguably the nicest part of Croydon.", undef, { comment => "<myfaketag>" } ) or die "Can't write node";
my %data = $guide->wiki->retrieve_node( "South Croydon Station" );
$guide->wiki->write_node( "South Croydon Station", "A sleepy mainline station in what is arguably the nicest part of Croydon.", $data{checksum}, { comment => "<myfaketag>" } ) or die "Can't write node";

my $output = $guide->display_node(
                                   id => "South Croydon Station",
                                   version => 1,
                                   return_output => 1,
                                   noheaders => 1,
                                 );
like( $output, qr'South_Croydon_Station',
      "node param escaped properly in links in historic view" );
unlike( $output, qr'South%20Croydon%20Station',
        "...in all links" );
SKIP: {
    skip "Test::HTML::Content not available", 2 unless $thc;
    Test::HTML::Content::tag_ok(
        $output, "span", { class => "current_version_title_link" },
        "historical version has link to current version near title" );
    Test::HTML::Content::link_ok( $output,
        "mywiki.cgi?South_Croydon_Station",
        "...and the link is correct" );
}
