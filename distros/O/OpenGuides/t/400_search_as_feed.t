use strict;
use Wiki::Toolkit::Setup::SQLite;
use OpenGuides::Search;
use OpenGuides::Test;
use Test::More;

eval { require DBD::SQLite; };
if ( $@ ) {
    my ($error) = $@ =~ /^(.*?)\n/;
    plan skip_all => "DBD::SQLite could not be used - no database to test with ($error)";
}

my $have_lucy = eval { require Lucy; } ? 1 : 0;
my $have_plucene = eval { require Plucene; } ? 1 : 0;

my $num_tests = 7;

plan tests => $num_tests * 2;

SKIP: {
    skip "Plucene not installed.", $num_tests unless $have_plucene;
    run_tests();
}

SKIP: {
    skip "Lucy not installed.", $num_tests unless $have_lucy;
    run_tests( use_lucy => 1 );
}

sub run_tests {
    my %args = @_;

    # Clear out the database from any previous runs.
    OpenGuides::Test::refresh_db();

    my $config = OpenGuides::Test->make_basic_config;
    $config->script_name( "wiki.cgi" );
    $config->script_url( "http://example.com/" );

    if ( $args{use_lucy} ) {
        $config->use_lucy( 1 );
        $config->use_plucene( 0 );
    } else {
        $config->use_plucene( 1 );
    }

    my $search = OpenGuides::Search->new( config => $config );
    isa_ok( $search, "OpenGuides::Search" );

    # Pop some test data in
    my $wiki = $search->{wiki}; # white boxiness
    $wiki->write_node( "Banana", "banana" );
    $wiki->write_node( "Monkey", "banana brains" );
    $wiki->write_node( "Monkey Brains", "BRANES" );
    $wiki->write_node( "Want Pie Now", "weebl" );
    $wiki->write_node( "Punctuation", "*" );
    $wiki->write_node( "Choice", "Eenie meenie minie mo");

    # RSS search, should give 2 hits
    my $output = $search->run(
                             return_output => 1,
                             vars => { search => "banana", format => "rss" },
                           );

    like($output, qr/<rdf:RDF/, "Really was RSS");
    like($output, qr/<items>/, "Really was RSS");

    my @found = ($output =~ /(<rdf:li)/g);
    is( scalar @found, 2, "found right entries in feed" );

    
    # Atom search, should give 1 hit
    $output = $search->run(
                            return_output => 1,
                            vars => { search => "weebl", format => "atom" },
                          );
    like($output, qr/<feed/, "Really was Atom");
    like($output, qr/<entry>/, "Really was Atom");

    @found = ($output =~ /(<entry>)/g);
    is( scalar @found, 1, "found right entries in feed" );
}
