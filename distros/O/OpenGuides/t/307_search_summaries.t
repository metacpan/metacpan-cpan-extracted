use strict;
use Wiki::Toolkit::Setup::SQLite;
use OpenGuides::Config;
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

my $num_tests = 2;

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

    my $config = OpenGuides::Config->new(
       vars => {
                 dbtype             => "sqlite",
                 dbname             => "t/node.db",
                 indexing_directory => "t/indexes",
                 script_name        => "wiki.cgi",
                 script_url         => "http://example.com/",
                 site_name          => "Test Site",
                 template_path      => "./templates",
               }
    );

    if ( $args{use_lucy} ) {
        $config->use_lucy( 1 );
        $config->use_plucene( 0 );
    } else {
        $config->use_plucene( 1 );
    }

    my $search = OpenGuides::Search->new( config => $config );
    isa_ok( $search, "OpenGuides::Search" );
    my $wiki = $search->wiki;
    $wiki->write_node( "Pub Crawls", "The basic premise of the pub crawl is "
        . "to visit a succession of pubs, rather than spending the entire "
        . "evening or day in a single establishment. London offers an "
        . "excellent choice of themes for your pub crawl.", undef,
        { category => "Pubs" } ) or die "Can't write node";

    my $output = $search->run(
                               return_output => 1,
                               vars          => { search => "pub" }
                             );
    SKIP: {
        skip "TODO: summaries", 1;
        like( $output, qr|<b>pub</b>|i,
              "outputs at least one bolded occurence of 'pub'" );
    } # end of SKIP
}
