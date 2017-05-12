use strict;
use Wiki::Toolkit::Setup::SQLite;
use OpenGuides::Search;
use OpenGuides::Test;
use Test::More tests => 4;

eval { require DBD::SQLite; };
if ( $@ ) {
    my ($error) = $@ =~ /^(.*?)\n/;
    plan skip_all => "DBD::SQLite could not be used - no database to test with. ($error)";
}

run_tests();

my $have_lucy = eval { require Lucy; } ? 1 : 0;

SKIP: {
    skip "Lucy not installed.", 2 unless $have_lucy;
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
    $config->search_content_munger_module( "TestMunger" );

    my $guide = OpenGuides->new( config => $config );
    my $search = OpenGuides::Search->new( config => $config );

    my %data = (
                 "No Ender" => "apple banana cherry",
                 "With Ender" => "apple banana STOP HERE cherry"
               );
    foreach my $node ( keys %data ) {
        OpenGuides::Test->write_data( guide => $guide, node => $node,
                                      content => $data{$node},
                                      return_output => 1 );
    }

    # Everything after STOP HERE should be ignored when searching.
    my %tt_vars = $search->run(
                                return_tt_vars => 1,
                                vars           => { search => "cherry" },
                              );
    my %found = map { $_->{name} => 1 } @{ $tt_vars{results} || [] };
    ok( $found{"No Ender"}, "search term found in unmunged node" );
    ok( !$found{"With Ender"}, "...and not in munged node" );
}

package TestMunger;

sub search_content_munger {
    my ( $class, $content ) = @_;
    $content =~ s/STOP\sHERE.*$//s;
    return $content;
}

1;
