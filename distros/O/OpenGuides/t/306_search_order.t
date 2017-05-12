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

my $num_tests = 9;

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

    # Write some data.
    my $wiki = $search->{wiki};
    $wiki->write_node( "Parks", "A page about parks." )
        or die "Can't write node";
    $wiki->write_node( "Wandsworth Common", "A common.", undef,
                       { category => "Parks" } )
        or die "Can't write node";
    $wiki->write_node( "Kake", "I like walking in parks." )
        or die "Can't write node";

    my %tt_vars = $search->run(
                                return_tt_vars => 1,
                                vars           => { search => "parks" },
                              );
    foreach my $result ( @{ $tt_vars{results} || [] } ) {
        print "# $result->{name} scores $result->{score}\n";
    }
    my %scores = map { $_->{name} => $_->{score} } @{$tt_vars{results} || []};
    ok( $scores{Kake} < $scores{'Wandsworth Common'},
        "content match scores less than category match" );
    ok( $scores{'Wandsworth Common'} < $scores{Parks},
        "title match scores more than category match" );

    # Now test locales.
    $wiki->write_node( "Hammersmith", "A page about Hammersmith." )
        or die "Can't write node";
    $wiki->write_node( "The Gate", "A restaurant.", undef,
                       { locale => "Hammersmith" } )
        or die "Can't write node";
    $wiki->write_node( "Kake Pugh", "I live in Hammersmith." )
        or die "Can't write node";

    %tt_vars = $search->run(
                             return_tt_vars => 1,
                             vars           => { search => "hammersmith" },
                           );
    foreach my $result ( @{ $tt_vars{results} || [] } ) {
        print "# $result->{name} scores $result->{score}\n";
    }
    %scores = map { $_->{name} => $_->{score} } @{$tt_vars{results} || []};
    ok( $scores{'Kake Pugh'} < $scores{'The Gate'},
        "content match scores less than locale match" );
    ok( $scores{'The Gate'} < $scores{Hammersmith},
        "locale match scores less than title match" );

    # Check that two words in the title beats one in the title and
    # one in the content.
    $wiki->write_node( "Putney Tandoori", "Indian food" )
      or die "Couldn't write node";
    $wiki->write_node( "Putney", "There is a tandoori restaurant here" )
      or die "Couldn't write node";

    %tt_vars = $search->run(
                             return_tt_vars => 1,
                             vars           => { search => "putney tandoori" },
                           );
    foreach my $result ( @{ $tt_vars{results} || [] } ) {
        print "# $result->{name} scores $result->{score}\n";
    }
    %scores = map { $_->{name} => $_->{score} } @{$tt_vars{results} || []};
    ok( $scores{Putney} < $scores{'Putney Tandoori'},
       "two words in title beats one in title and one in content" );

    SKIP: {
       skip "Word proximity not yet taken into account", 1;
        # Check that in an AND match words closer together get higher priority.
        $wiki->write_node( "Spitalfields Market",
                           "Mango juice from the Indian stall" )
          or die "Can't write node";
        $wiki->write_node( "Borough Market",
                           "dried mango and real apple juice" )
          or die "Can't write node";

        %tt_vars = $search->run(
                                 return_tt_vars => 1,
                                 vars           => { search => "mango juice" },
                               );
        foreach my $result ( @{ $tt_vars{results} || [] } ) {
            print "# $result->{name} scores $result->{score}\n";
        }
        %scores = map { $_->{name} => $_->{score} } @{$tt_vars{results} || []};
        ok( $scores{'Borough Market'} < $scores{'Spitalfields Market'},
            "words closer together gives higher score" );
    } # end of SKIP

    # Check that the number of occurrences of the search term is significant.

    $wiki->write_node( "Pub Crawls", "The basic premise of the pub crawl is to visit a succession of pubs, rather than spending the entire evening or day in a single establishment. London offers an excellent choice of themes for your pub crawl.", undef, { category => "Pubs" } ) or die "Can't write node";
    $wiki->write_node( "The Pub", "A pub.  Here are some more words to make the content as long as that of the other node, to give a fairer test.", undef, { category => "Pubs" } ) or die "Can't write node";

    %tt_vars = $search->run(
                             return_tt_vars => 1,
                             vars           => { search => "pub" }
                           );
    foreach my $result ( @{ $tt_vars{results} || [] } ) {
        print "# $result->{name} scores $result->{score}\n";
    }
    is( $tt_vars{results}[0]{name}, "Pub Crawls",
        "node with two mentions of search term comes top" );
    ok( $tt_vars{results}[0]{score} > $tt_vars{results}[1]{score},
        "...with a score strictly greater than node with one mention" );
}
