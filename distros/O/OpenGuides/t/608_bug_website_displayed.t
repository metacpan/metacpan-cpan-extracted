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

plan tests => 7;

OpenGuides::Test::refresh_db();

my $config = OpenGuides::Test->make_basic_config;
my $guide = OpenGuides->new( config => $config );

$guide->wiki->write_node( "South Croydon Station", "A sleepy main-line station in what is arguably the nicest part of Croydon.", undef, { website => "http://example.com/" } ) or die "Couldn't write node";
$guide->wiki->write_node( "North Croydon Station", "A busy main-line station in what is arguably the furthest North part of Croydon.", undef, { website => "http://longer.example.com/asdfasdf" } ) or die "Couldn't write node";
$guide->wiki->write_node( "East Croydon Station",
  "A busy main-line station that actually exists.", undef,
  { website => "http://www.example.com/foo" } )
    or die "Couldn't write node";
$guide->wiki->write_node( "West Croydon Station",
  "Another main-line station that actually exists.", undef,
  { website => "http://www.example.com/bar/" } )
    or die "Couldn't write node";

$config->website_link_max_chars( 20 );
my %tt_vars = $guide->display_node( id => "South Croydon Station",
                                    return_tt_vars => 1 );
is( $tt_vars{formatted_website_text},
    '<a href="http://example.com/" class="external">example.com</a>',
    "Website correctly displayed when no need for truncation," );

%tt_vars = $guide->display_node( id => "East Croydon Station",
                                    return_tt_vars => 1 );
is( $tt_vars{formatted_website_text},
    '<a href="http://www.example.com/foo" class="external">example.com/foo</a>',
    "Website correctly truncated when there's a leading www" );

%tt_vars = $guide->display_node( id => "West Croydon Station",
                                    return_tt_vars => 1 );
is( $tt_vars{formatted_website_text},
    '<a href="http://www.example.com/bar/" class="external">example.com/bar/</a>',
    "Trailing slash not stripped unless it's immediately after domain name" );

%tt_vars = $guide->display_node( id => "North Croydon Station",
                                    return_tt_vars => 1 );
is( $tt_vars{formatted_website_text},
    '<a href="http://longer.example.com/asdfasdf" class="external">longer.example.co...</a>',
    "Website correctly truncated when much too long." );

# Make sure website isn't truncated unnecessarily, e.g. that we don't end up
# just replacing the final three characters with the ellipsis.  Our full URL
# has 27 characters (not counting the http://).
$config->website_link_max_chars( 26 );
%tt_vars = $guide->display_node( id => "North Croydon Station",
                                 return_tt_vars => 1 );
is( $tt_vars{formatted_website_text},
 '<a href="http://longer.example.com/asdfasdf" class="external">longer.example.com/asdf...</a>',
    "Website truncated correctly when 1 character longer than allowed." );

$config->website_link_max_chars( 27 );
%tt_vars = $guide->display_node( id => "North Croydon Station",
                                 return_tt_vars => 1 );
is( $tt_vars{formatted_website_text},
'<a href="http://longer.example.com/asdfasdf" class="external">longer.example.com/asdfasdf</a>',
    "Website not truncated when exact length allowed." );

$config->website_link_max_chars( 28 );
%tt_vars = $guide->display_node( id => "North Croydon Station",
                                 return_tt_vars => 1 );
is( $tt_vars{formatted_website_text},
'<a href="http://longer.example.com/asdfasdf" class="external">longer.example.com/asdfasdf</a>',
    "Website not truncated when 1 character shorter than allowed." );
