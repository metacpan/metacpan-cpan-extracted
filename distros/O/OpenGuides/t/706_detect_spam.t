use strict;

use OpenGuides;
use OpenGuides::Test;
use Test::More;
use Wiki::Toolkit::Setup::SQLite;

eval { require DBD::SQLite; };
if ( $@ ) {
    my ($error) = $@ =~ /^(.*?)\n/;
    plan skip_all => "DBD::SQLite could not be used - no database to test with. ($error)";
}

plan tests => 2;

# Clear out the database from any previous runs.
    OpenGuides::Test::refresh_db();

# Set up a guide which uses a spam detector module.
my $config = OpenGuides::Test->make_basic_config;
$config->spam_detector_module( "OpenGuides::Local::SpamDetector" );
my $guide = OpenGuides->new( config => $config );

# Try to write something that isn't spam.
my $q = OpenGuides::Test->make_cgi_object( content => "puppies" );
my $output = $guide->commit_node(
                                  id            => "Puppies",
                                  cgi_obj       => $q,
                                  return_output => 1,
                                );
ok( $guide->wiki->node_exists( "Puppies" ), "can write non-spam node" );

# Try to write something that is.
$q = OpenGuides::Test->make_cgi_object( content => "kittens" );
$output = $guide->commit_node(
                               id            => "Kittens",
                               cgi_obj       => $q,
                               return_output => 1,
                             );
ok( !$guide->wiki->node_exists( "Kittens" ), "can't write spammy node" );

package OpenGuides::Local::SpamDetector;

sub looks_like_spam {
    my ( $class, %args ) = @_;
    if ( $args{content} =~ /kittens/i ) {
        return 1;
    }
    return 0;
}
