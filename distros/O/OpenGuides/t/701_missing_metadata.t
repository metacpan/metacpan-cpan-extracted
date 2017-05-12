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

plan tests => 29;
OpenGuides::Test::refresh_db();

my $config = OpenGuides::Test->make_basic_config;
$config->script_name( "wiki.cgi" );
$config->script_url( "http://example.com/" );
my $guide = OpenGuides->new( config => $config );
isa_ok( $guide, "OpenGuides" );
my $wiki = $guide->wiki;
isa_ok( $wiki, "Wiki::Toolkit" );

# Add four different pages, one of which has two versions, and one of which
# is a redirect.  The redirect should not show up on any "missing metadata"
# searches, regardless of the condition of the page it points to.
$wiki->write_node( "Test Page", "foo", undef,
                   { category => "Alpha", latitude => "" } )
  or die "Couldn't write node";
$wiki->write_node( "Test Page 2", "foo2", undef,
                   { category => "Alpha", latitude => "22.22" } )
  or die "Couldn't write node";
$wiki->write_node( "Test Page 3", "foo33", undef,
                   { category => "Alpha" } )
  or die "Couldn't write node";
$wiki->write_node( "Category Foo", "foo", undef,
                   { category => "Categories", latitude => "-8.77" } )
  or die "Couldn't write category";
$wiki->write_node( "Locale Bar", "foo", undef,
                   { category => "Locales", latitude => "8.22" } )
  or die "Couldn't write locale";
my %data = $wiki->retrieve_node( "Locale Bar" );
$wiki->write_node( "Locale Bar", "foo version 2", $data{checksum},
                   { category => "Locales", latitude => "8.88" } )
  or die "Couldn't write locale for the 2nd time";
OpenGuides::Test->write_data(
                              guide => $guide,
                              node  => "Redirect Test",
                              content => "#REDIRECT [[Test Page]]",
                              return_output => 1,
                            );

# Try without search parameters
my %ttvars = eval {
       $guide->show_missing_metadata( return_tt_vars=> 1 );
};
my @nodes;
is( $@, "", "->show_missing_metadata doesn't die" );

is( scalar @{$ttvars{'nodes'}}, 0, "No nodes when no search params" );
is( $ttvars{'done_search'}, 0, "Didn't search" );


# Now try searching for those without lat
%ttvars = eval {
       $guide->show_missing_metadata(
                                metadata_type => 'latitude',
                                return_tt_vars => 1
        );
};

@nodes = sort {$a->{'name'} cmp $b->{'name'}} @{$ttvars{'nodes'}};
is( scalar @nodes, 2, "Two without / with empty lat" );
is( $ttvars{'done_search'}, 1, "Did search" );
is( $nodes[0]->{'name'}, "Test Page", "Right nodes" );
is( $nodes[1]->{'name'}, "Test Page 3", "Right nodes" );


# Now try searching for those without lat=22.22
%ttvars = eval {
       $guide->show_missing_metadata(
                                metadata_type => 'latitude',
                                metadata_value => '22.22',
                                return_tt_vars => 1
        );
};

@nodes = sort {$a->{'name'} cmp $b->{'name'}} @{$ttvars{'nodes'}};
is( scalar @nodes, 4, "Four without that lat" );
is( $ttvars{'done_search'}, 1, "Did search" );
is( $nodes[0]->{'name'}, "Category Foo", "Right nodes" );
is( $nodes[1]->{'name'}, "Locale Bar", "Right nodes" );
is( $nodes[2]->{'name'}, "Test Page", "Right nodes" );
is( $nodes[3]->{'name'}, "Test Page 3", "Right nodes" );

# Make sure they're returned in alphabetical order.
my @nodenames = map { $_->{name} } @{$ttvars{nodes}};
is_deeply( \@nodenames,
           [ "Category Foo", "Locale Bar", "Test Page", "Test Page 3" ],
           "Nodes are returned in alphabetical order" );

# Try again, but exclude locale and category
%ttvars = eval {
       $guide->show_missing_metadata(
                                metadata_type => 'latitude',
                                metadata_value => '22.22',
                                exclude_locales => 1,
                                exclude_categories => 2,
                                return_tt_vars => 1
        );
};

@nodes = sort {$a->{'name'} cmp $b->{'name'}} @{$ttvars{'nodes'}};
is( scalar @nodes, 2, "Two without that lat" );
is( $ttvars{'done_search'}, 1, "Did search" );
is( $nodes[0]->{'name'}, "Test Page", "Right nodes" );
is( $nodes[1]->{'name'}, "Test Page 3", "Right nodes" );


# Test the normal, HTML version
my $output = eval {
    $guide->show_missing_metadata( return_output=>1,
                                   noheaders => 1);
};
is( $@, "",
    "->show_missing_metadata doesn't die when called with no metadata_type" );

like( $output, qr|Missing Metadata|, "Right page" );
like( $output, qr|Metadata Type|, "Has prompts" );
unlike( $output, qr|<h3>Pages</h3>|, "Didn't search" );
like( $output, qr|Telephone Number|, "...correct labels in the dropdown" );

$output = eval {
    $guide->show_missing_metadata( return_output => 1,
                                   metadata_type => "latitude",
                                   noheaders => 1);
};
is( $@, "", "->show_missing_metadata doesn't die when called with "
            . "metadata_type 'latitude'" );
like( $output, qr|<h3>Pages</h3>|, "searched" );
like( $output, qr|Test Page|, "had node" );

SKIP: {
    skip "Test::HTML::Content not available", 1 unless $thc;
    Test::HTML::Content::tag_ok(
        $output, "option", { value => "latitude", selected => "1" },
        "...latitude is selected in the dropdown" );
}
