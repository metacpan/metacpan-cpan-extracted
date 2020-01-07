use strict;
use OpenGuides;
use OpenGuides::CGI;
use OpenGuides::Test;
use Test::More;
use Wiki::Toolkit::Setup::SQLite;

eval { require DBD::SQLite; };
if ( $@ ) {
    my ($error) = $@ =~ /^(.*?)\n/;
    plan skip_all => "DBD::SQLite could not be used - no database to test with ($error)";
}

plan tests => 16;

# Clear out the database from any previous runs.
OpenGuides::Test::refresh_db();

my $config = OpenGuides::Test->make_basic_config;
$config->script_name( "wiki.cgi" );
$config->script_url( "http://example.com/" );
my $guide = OpenGuides->new( config => $config );

# Set is_admin to 1
my $cookie = OpenGuides::CGI->make_prefs_cookie(
    config                     => $config,
    is_admin => 1,
);
$ENV{HTTP_COOKIE} = $cookie;

# Put in some test data.
my $wiki = $guide->wiki;

$wiki->write_node( "Test Page", "foo", undef,
                   { category => "Alpha", locale => "Assam" } )
  or die "Couldn't write node";

run_tests( map => 0 );
run_tests( map => 1 );

sub run_tests {
  my %args = @_;
  my $map = $args{map};
  my $thing = $map ? "map" : "index";
  my %opts = ( return_tt_vars => 1 );
  $opts{format} = "map" if $map;

  my %tt_vars = $guide->show_index( %opts );
  ok( $tt_vars{not_deletable},
      "not_deletable TT var is set when showing $thing of everything" );
  ok( $tt_vars{not_editable},
      "...so is not_editable var" );
  %tt_vars = $guide->show_index( cat => "Alpha", %opts );
  ok( $tt_vars{not_deletable},
      "not_deletable TT var is set when showing $thing of category" );
  ok( $tt_vars{not_editable},
      "...so is not_editable var" );
  %tt_vars = $guide->show_index( loc => "Assam", %opts );
  ok( $tt_vars{not_deletable},
      "not_deletable TT var is set when showing $thing of locale" );
  ok( $tt_vars{not_editable},
      "...so is not_editable var" );
  %tt_vars = $guide->show_index( cat => "Alpha", loc => "Assam", %opts );
  ok( $tt_vars{not_deletable},
     "not_deletable TT var is set when showing $thing of cat and loc" );
  ok( $tt_vars{not_editable},
      "...so is not_editable var" );
}
