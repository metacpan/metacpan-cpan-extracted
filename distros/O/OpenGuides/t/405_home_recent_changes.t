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

plan tests => 15;

my ( $config, $guide, $wiki );

# Clear out the database from any previous runs.
    OpenGuides::Test::refresh_db();

# Write some data to show up in recent changes.
$config = OpenGuides::Test->make_basic_config;
$guide = OpenGuides->new( config => $config );
OpenGuides::Test->write_data(
                              guide    => $guide,
                              node     => "Red Lion",
                              content  => "A pub.",
                              username => "Kake",
                              comment  => "I edited it.",
                            );

# First test that recent changes show up on the front page by default.
$config = OpenGuides::Test->make_basic_config;
$guide = OpenGuides->new( config => $config );

my $output = $guide->display_node(
                                   id            => $config->home_name,
                                   return_output => 1,
                                 );
like( $output, qr/Red Lion/,
      "recent changes show up on home page by default" );
like( $output, qr/I edited it\./, "...including comments" );
like( $output, qr/Kake/, "...and usernames" );
like( $output, qr/Edit this page/, "...edit this page link is there too" );

# And that they show up when we explicitly ask for them.
$config = OpenGuides::Test->make_basic_config;
$config->recent_changes_on_home_page( 1 );
$guide = OpenGuides->new( config => $config );

$output = $guide->display_node(
                                   id            => $config->home_name,
                                   return_output => 1,
                                 );
like( $output, qr/Red Lion/,
      "recent changes show up on home page when we ask for them" );
like( $output, qr/I edited it\./, "...including comments" );
like( $output, qr/Kake/, "...and usernames" );
like( $output, qr/Edit this page/, "...edit this page link is there too" );

OpenGuides::Test->write_data(
                              guide    => $guide,
                              node     => "Red Lion",
                              content  => "A nice pub.",
                              username => "Earle",
                              comment  => "I also edited it. For fun, here are two links: [[A Page]], and the same link [[A Page|again]].",
                            );

# Reload page.
$output = $guide->display_node(
                                   id            => $config->home_name,
                                   return_output => 1,
                                 );

like( $output, qr{<a href="\?A Page">A Page</a>}, "...simple wiki links appear in Recent Changes" );
like( $output, qr{<a href="\?A Page">again</a>},  "...titled wiki links appear in Recent Changes" );


# And that they don't show up if we don't want them.  Turn off the navbar
# too, since we want to make sure the edit page link shows up regardless (it
# normally appears in the recent changes box).
$config = OpenGuides::Test->make_basic_config;
$config->recent_changes_on_home_page( 0 );
$config->navbar_on_home_page( 0 );
$guide = OpenGuides->new( config => $config );

$output = $guide->display_node(
                                   id            => $config->home_name,
                                   return_output => 1,
                                 );
unlike( $output, qr/Red Lion/,
      "recent changes don't show up on home page if we turn them off" );
unlike( $output, qr/I edited it\./, "...comments not shown either" );
unlike( $output, qr/Kake/, "...nor usernames" );
unlike( $output, qr/Ten most.*recent changes/, "...heading not shown either" );
like( $output, qr/Edit this page/, "...edit this page link is there though" );

