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

plan tests => 14;

OpenGuides::Test::refresh_db();

my $config = OpenGuides::Test->make_basic_config;
my $guide = OpenGuides->new( config => $config );

# Write nodes with various lengths of websites, both http and https versions.
my %protocols = ( "http" => "", "https" => " Secure" );
foreach my $prefix ( keys %protocols ) {
  my $postfix = $protocols{$prefix};

  $guide->wiki->write_node( "South Croydon Station$postfix",
  "A sleepy main-line station in what is arguably the nicest part of Croydon.",
   undef, { website => "$prefix://example.com/" } )
     or die "Couldn't write node";
  $guide->wiki->write_node( "North Croydon Station$postfix",
  "A busy main-line station in what is arguably the furthest North part of "
  . "Croydon.", undef, { website => "$prefix://longer.example.com/asdfasdf" } )
    or die "Couldn't write node";
  $guide->wiki->write_node( "East Croydon Station$postfix",
  "A busy main-line station that actually exists.", undef,
  { website => "$prefix://www.example.com/foo" } )
    or die "Couldn't write node";
  $guide->wiki->write_node( "West Croydon Station$postfix",
  "Another main-line station that actually exists.", undef,
  { website => "$prefix://www.example.com/bar/" } )
    or die "Couldn't write node";
}

my %tt_vars;

foreach my $prefix ( keys %protocols ) {
  my $postfix = $protocols{$prefix};
  diag( "Protocol is $prefix" );

  $config->website_link_max_chars( 20 );
  %tt_vars = $guide->display_node( id => "South Croydon Station$postfix",
                                      return_tt_vars => 1 );
  is( $tt_vars{formatted_website_text}, '<a href="' . $prefix
      . '://example.com/" class="external">example.com</a>',
      uc($prefix) . " website correctly displayed when no need for truncation"
  );

  %tt_vars = $guide->display_node( id => "East Croydon Station$postfix",
                                      return_tt_vars => 1 );
  is( $tt_vars{formatted_website_text}, '<a href="' . $prefix
      . '://www.example.com/foo" class="external">example.com/foo</a>',
      uc($prefix) . " website correctly truncated when there's a leading www");

  %tt_vars = $guide->display_node( id => "West Croydon Station$postfix",
                                      return_tt_vars => 1 );
  is( $tt_vars{formatted_website_text}, '<a href="' . $prefix
      . '://www.example.com/bar/" class="external">example.com/bar/</a>',
      "Trailing slash not stripped unless it's immediately after domain name");

  %tt_vars = $guide->display_node( id => "North Croydon Station$postfix",
                                      return_tt_vars => 1 );
  is( $tt_vars{formatted_website_text}, '<a href="' . $prefix
      . '://longer.example.com/asdfasdf" class="external">'
      . 'longer.example.co...</a>',
      uc($prefix) . " website correctly truncated when much too long." );

  # Make sure website isn't truncated unnecessarily, e.g. that we don't end up
  # just replacing the final three characters with the ellipsis.  Our full URL
  # has 27 characters (not counting the http://).
  $config->website_link_max_chars( 26 );
  %tt_vars = $guide->display_node( id => "North Croydon Station$postfix",
                                   return_tt_vars => 1 );
  is( $tt_vars{formatted_website_text}, '<a href="' . $prefix
      . '://longer.example.com/asdfasdf" class="external">'
      . 'longer.example.com/asdf...</a>',
      uc($prefix) . " website truncated correctly when 1 character longer "
      . "than allowed." );

  $config->website_link_max_chars( 27 );
  %tt_vars = $guide->display_node( id => "North Croydon Station$postfix",
                                   return_tt_vars => 1 );
  is( $tt_vars{formatted_website_text}, '<a href="' . $prefix
      . '://longer.example.com/asdfasdf" class="external">'
      . 'longer.example.com/asdfasdf</a>',
      uc($prefix) . " website not truncated when exact length allowed." );

  $config->website_link_max_chars( 28 );
  %tt_vars = $guide->display_node( id => "North Croydon Station$postfix",
                                   return_tt_vars => 1 );
  is( $tt_vars{formatted_website_text}, '<a href="' . $prefix
      . '://longer.example.com/asdfasdf" class="external">'
      . 'longer.example.com/asdfasdf</a>',
      uc($prefix) . " website not truncated when 1 character shorter "
      . "than allowed." );
}
