use strict;
use OpenGuides;
use OpenGuides::Test;
use Test::More;
use Wiki::Toolkit::Setup::SQLite;

eval { require DBD::SQLite; };
if ( $@ ) {
    my ($error) = $@ =~ /^(.*?)\n/;
    plan skip_all => "DBD::SQLite could not be used - no database to test with ($error)";
}

eval { require Test::HTML::Content; };
if ( $@ ) {
    plan skip_all => "Test::HTML::Content not installed";
}

plan tests => 6;

# Clear out the database from any previous runs.
OpenGuides::Test::refresh_db();

my $config = OpenGuides::Test->make_basic_config;
my $guide = OpenGuides->new( config => $config );
my $wiki = $guide->wiki;

my $q = OpenGuides::Test->make_cgi_object(
    content => "I am some content.",
    summary => "I am a summary.",
    node_image => "http://example.com/image.png",
    node_image_copyright => "PhotoKake",
    node_image_licence => "http://example.com/licence",
    node_image_url => "http://example.com/info",
);

# Get a checksum for a "blank" node.
my %node_data = $wiki->retrieve_node( "Clapham Junction Station" );
$q->param( -name => "checksum", -value => $node_data{checksum} );

my $output = $guide->preview_edit(
                                   id            => "Clapham Junction Station",
                                   cgi_obj       => $q,
                                   return_output => 1,
                                 );

# Strip Content-Type header to stop Test::HTML::Content getting confused.
$output =~ s/^Content-Type.*[\r\n]+//m;

my $warned;
eval {
       local $SIG{__WARN__} = sub { $warned = 1; };
       Test::HTML::Content::text_ok( $output, "I am a summary.",
                                     "Summary shows up in preview." );
};
ok( !$warned, "...and HTML seems to be valid" );
Test::HTML::Content::tag_ok( $output, "img",
    { src => "http://example.com/image.png" },
    "Image URL shows up too" );
like( $output, qr|&copy;\s+PhotoKake|, "...so does image copyright holder" );
Test::HTML::Content::link_ok( $output, "http://example.com/licence",
    "...and we link to the licence" );
Test::HTML::Content::link_ok( $output, "http://example.com/info",
    "...and we link to the info page" );
