use strict;
use Cwd;
use OpenGuides;
use OpenGuides::Test;
use Test::More;

eval { require DBD::SQLite; };
if ( $@ ) {
    my ($error) = $@ =~ /^(.*?)\n/;
    plan skip_all => "DBD::SQLite could not be used - no database to test with. ($error)";
}

eval { require Test::HTML::Content; };
if ( $@ ) {
    plan skip_all => "Test::HTML::Content not installed";
    exit 0;
}

plan tests => 2;

my $config = OpenGuides::Test->make_basic_config;
$config->custom_template_path( cwd . "/t/templates/tmp/" );
my $guide = OpenGuides->new( config => $config );
my $wiki = $guide->wiki;

# Clear out the database from any previous runs.
    OpenGuides::Test::refresh_db();

# Make sure the tmp directory exists
eval {
    mkdir cwd . "/t/templates/tmp";
};

# Make sure we don't die if there's no custom header template.
eval {
    unlink cwd . "/t/templates/tmp/custom_header.tt";
};
eval {
    $guide->display_node( id => $config->home_name, return_output => 1 );
};
ok( !$@, "node display OK if no custom header template" );

# Write a custom template to add stuff to header.
open( FILE, ">", cwd . "/t/templates/tmp/custom_header.tt" )
  or die $!;
print FILE <<EOF;
<meta name="foo" content="bar" />
EOF
close FILE or die $!;

# Check that the custom template was picked up.
my $output = $guide->display_node(
                                   id            => $config->home_name,
                                   return_output => 1,
                                   noheaders     => 1,
                                 );
$output =~ s/^Content-Type.*[\r\n]+//m;
Test::HTML::Content::tag_ok( $output, "meta", { name => "foo" },
                             "custom template included in header" );
