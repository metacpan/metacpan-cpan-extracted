use strict;
use Wiki::Toolkit::Setup::SQLite;
use OpenGuides::Config;
use OpenGuides;
use OpenGuides::Template;
use OpenGuides::Test;
use Test::More;

eval { require DBD::SQLite; };
if ( $@ ) {
    my ($error) = $@ =~ /^(.*?)\n/;
    plan skip_all => "DBD::SQLite could not be used - no database to test with ($error)";
}

plan tests => 3;

# Clear out the database from any previous runs.
    OpenGuides::Test::refresh_db();


my $config = OpenGuides::Test->make_basic_config;
my $guide = OpenGuides->new( config => $config );

OpenGuides::Test->write_data(
                              guide => $guide,
                              node  => "A Node",
);

# Test that we can list all versions of a node that only has one version.
eval { $guide->list_all_versions( id => "A Node", return_output => 1 ); };
is( $@, "", "->list_all_versions doesn't croak when only one version" );

# Test that node with only one version doesn't display diff link.
my $output = $guide->display_node( id => "A Node", return_output => 1 );
unlike( $output, qr|<a href=".*">diff</a>|,
        "no diff link displayed on node with only one version" );
unlike( $output, qr|<a href=".*">View current version.</a>|i,
        "...nor view current version link" );
