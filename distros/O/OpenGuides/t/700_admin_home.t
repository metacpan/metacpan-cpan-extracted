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

plan tests => 12;

    OpenGuides::Test::refresh_db();

my $config = OpenGuides::Test->make_basic_config;
$config->script_name( "wiki.cgi" );
$config->script_url( "http://example.com/" );
my $guide = OpenGuides->new( config => $config );
isa_ok( $guide, "OpenGuides" );
my $wiki = $guide->wiki;
isa_ok( $wiki, "Wiki::Toolkit" );



# Add 3 different pages, one of which with two versions
OpenGuides::Test->write_data(
     guide         => $guide,
     node          => "Test Page",
     categories    => "Alpha",
     return_output => 1  );
OpenGuides::Test->write_data(
      guide        => $guide,
      node         =>  "Test Page 2",
      categories    => "Alpha",
      return_output => 1  );
OpenGuides::Test->write_data(
      guide      => $guide,
      node       =>  "Locale Bar",
      categories  => "Locales",
      return_output => 1  );
OpenGuides::Test->write_data(
      guide      => $guide,
      node       =>  "Locale Bar",
      categories  => "Locales",
     return_output => 1  );


# Test the tt vars
my %ttvars = eval {
       $guide->display_admin_interface( return_tt_vars=> 1 );
};
is( $@, "", "->display_admin_interface doesn't die" );

is( scalar @{$ttvars{'nodes'}}, 2, "Right number of nodes" );
is( scalar @{$ttvars{'locales'}}, 1, "Right number of locales" );
is( scalar @{$ttvars{'categories'}}, 2, "Right number of categories" );

my @node_names = map { $_->{name}; } @{$ttvars{nodes}};
is_deeply( [ sort @node_names ], [ "Test Page", "Test Page 2" ],
           "Right nodes" );
is( $ttvars{'locales'}->[0]->{name}, "Bar", "Right locale, right name" );

# Test the normal, HTML version
my $output = eval {
    $guide->display_admin_interface( return_output=>1 );
};
is( $@, "", "->display_admin_interface doesn't die" );

like( $output, qr|Site Administration|, "Right page" );
like( $output, qr|Test Page|, "Has nodes" );
like( $output, qr|Bar|, "Has locales" );
