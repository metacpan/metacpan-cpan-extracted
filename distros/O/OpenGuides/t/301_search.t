use strict;
use Wiki::Toolkit::Setup::SQLite;
use OpenGuides::Search;
use OpenGuides::Test;
use Test::More tests => 36;

eval { require DBD::SQLite; };
if ( $@ ) {
    my ($error) = $@ =~ /^(.*?)\n/;
    plan skip_all => "DBD::SQLite could not be used - no database to test with. ($error)";
}

run_tests();

my $have_lucy = eval { require Lucy; } ? 1 : 0;

SKIP: {
    skip "Lucy not installed.", 18 unless $have_lucy;
    run_tests( use_lucy => 1 );
}

sub run_tests {
    my %args = @_;

    # Clear out the database.
    OpenGuides::Test::refresh_db();

    my $config = OpenGuides::Test->make_basic_config;
    if ( $args{use_lucy} ) {
        $config->use_lucy( 1 );
        $config->use_plucene( 0 );
    } else {
        # Plucene is recommended over Search::InvertedIndex.
        eval { require Wiki::Toolkit::Search::Plucene; };
        if ( $@ ) { $config->use_plucene( 0 ) };
    }

    $config->script_name( "wiki.cgi" );
    $config->script_url( "http://example.com/" );

    my $guide = OpenGuides->new( config => $config );
    my $search = OpenGuides::Search->new( config => $config );

    isa_ok( $search, "OpenGuides::Search" );

    my $output = $search->run( return_output => 1 );
    unlike( $output, qr/no items matched/i,
            "doesn't output 'no items matched' if no terms supplied" );
    unlike( $output, qr/action=edit/,
            "doesn't offer edit link" );

    my %tt_vars = $search->run(
                                return_tt_vars => 1,
                                vars           => { search => "banana" },
                              );
    is( $tt_vars{first_num}, 0, "first_num set to 0 when no hits" );
    is( scalar @{ $tt_vars{results} }, 0, "...and results array empty" );

    $output = $search->run(
                            return_output => 1,
                            vars          => { search => "banana" }
                           );
    like( $output, qr/no items matched/i,
          "outputs 'no items matched' if term not found" );
    unlike( $output, qr/matches found, showing/i,
            "doesn't output 'matches found, showing' if term not found" );

    # Pop some data in and search again.
    my %data = (
                 "Banana" => "banana",
                 "Monkey" => "banana brains",
                 "Monkey Brains" => "BRANES",
                 "Want Pie Now" => "weebl",
                 "Punctuation" => "*",
                 "Choice" => "Eenie meenie minie mo"
               );
    foreach my $node ( keys %data ) {
        OpenGuides::Test->write_data( guide => $guide, node => $node,
                                      content => $data{$node},
                                      return_output => 1 );
    }

    # Test with two hits first - simpler.
    %tt_vars = $search->run(
                             return_tt_vars => 1,
                             vars           => { search => "banana" },
                           );
    my @found = map { $_->{name} } @{ $tt_vars{results} || [] };
    is( scalar @found, 2, "search finds single word twice" );
    is_deeply( [ sort @found ], [ "Banana", "Monkey" ],
               "...in the right places" );
    print "# Banana found in $_\n" foreach @found;

    # Make sure that $output matches too - we're testing the template here.
    $output =  $search->run(
                             return_output => 1,
                             vars           => { search => "banana" },
                           );
    like( $output, qr/<a href="http:\/\/example.com\/wiki.cgi\?Banana">/,
          "...and link is included in template output" );

    # One hit in body only should show result list.
    $output = $search->run(
                            return_output => 1,
                            vars          => { search => "weebl" },
                          );
    unlike( $output, qr/Status: 302/,
            "no redirect if match only in body");

    # One hit in title should redirect to that page.
    $output = $search->run(
                            return_output => 1,
                            vars          => { search => "want pie now" },
                          );
    like( $output, qr/Status: 302/,
          "prints redirect on single hit and match in title" );
    # Old versions of CGI.pm mistakenly print location: instead of Location:
    like( $output,
          qr/[lL]ocation: http:\/\/example.com\/wiki.cgi\?Want_Pie_Now/,
          "...and node name munged correctly in URL" );

    # Test the AND search
    %tt_vars = $search->run(
                            return_tt_vars => 1,
                            vars           => { search => "monkey banana" },
                           );
    @found = map { $_->{name} } @{ $tt_vars{results} || [] };
    is_deeply( \@found, [ "Monkey" ], "AND search returns right results" );

    # Test the OR search
    %tt_vars = $search->run(
                             return_tt_vars => 1,
                             vars           => { search => "brains, pie" },
                           );
    @found = sort map { $_->{name} } @{ $tt_vars{results} || [] };
    is_deeply( \@found, [ "Monkey", "Monkey Brains", "Want Pie Now" ],
               "OR search returns right results" );
    print "# Found in $_\n" foreach @found;

    SKIP: {
        skip "NOT search not done yet", 1;
    # Test the NOT search
    %tt_vars = $search->run(
                             return_tt_vars => 1,
                             vars           => { search => "banana -monkey" },
                           );
    @found = sort map { $_->{name} } @{ $tt_vars{results} || [] };
    is_deeply( \@found, [ "Banana" ], "NOT search returns right results" );
    } # end of SKIP

    # Test the phrase search
    $output = $search->run(
                            return_output => 1,
                            vars          => { search => '"monkey brains"' },
                           );
    like( $output,
          qr/[lL]ocation: http:\/\/example.com\/wiki.cgi\?Monkey_Brains/,
          "phrase search returns right results and redirects to page"
        );

    #####
    ##### Test numbering when we have more than a page of results.
    #####

    foreach my $i ( 1 .. 30 ) {
        OpenGuides::Test->write_data( guide => $guide, node => "Node $i",
                                      content => "wombat",
                                      return_output => 1 );
    }
    $output = $search->run(
                            return_output => 1,
                            vars          => {
                                               search => "wombat",
                                               next   => 20,
                                             },
                          );
    like( $output, qr/ol start="21"/,
          "second page of results starts with right numbering" );
}
