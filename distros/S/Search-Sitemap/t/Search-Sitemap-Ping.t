#!perl
use strict; use warnings;
use Test::Mock::LWP::UserAgent;
use Test::Most tests => 51;
use ok( 'Search::Sitemap::Ping' );

BEGIN {
    $Mock_ua->set_isa( 'LWP::UserAgent' );
    $Mock_ua->set_always( get => HTTP::Response->new );
}

my @engines = qw( Ask Google Live Yahoo );

my $baseurl = "http://www.example.com";

my $ping;
ok( $ping = Search::Sitemap::Ping->new( "$baseurl/sitemap.xml" ) );
isa_ok( $ping => 'Search::Sitemap::Ping' );

{
    my $engine_check = sub { isa_ok( shift, 'Search::Sitemap::Pinger' ) };
    my @progress = (
        [ 0,   4, 0, 0, 0 ],
        [ 25,  4, 1, 1, 0 ],
        [ 50,  4, 2, 2, 0 ],
        [ 75,  4, 3, 3, 0 ],
        [ 100, 4, 4, 4, 0 ],
    );
    my $progress_check = sub {
        my @ck = @{ shift( @progress ) };
        cmp_ok( shift, '==', $ck[0], "progress at 0%" );
        cmp_ok( shift, '==', $ck[1], "total ok" );
        cmp_ok( shift, '==', $ck[2], "attempt ok" );
        cmp_ok( shift, '==', $ck[3], "success ok" );
        cmp_ok( shift, '==', $ck[4], "failure ok" );
    };
    my @callback_stack = (
        [ 'before_submit' ],
        [ 'progress', $progress_check ],
        ( map {
            [ 'before_engine', $engine_check ],
            [ 'progress', $progress_check ],
            [ 'after_engine', $engine_check ],
        } @engines ),
        [ 'after_submit' ],
    );
    my @callbacks = qw(
        before_submit after_submit
        before_engine after_engine
        success failure progress
    );
    for my $x ( @callbacks ) {
        $ping->add_trigger( $x => sub {
            my @stack = @{ shift( @callback_stack ) || [] };
            my $self = shift;
            is( $x, shift( @stack ), "correct trigger fired" );
            while ( @stack ) {
                shift( @stack )->( @_ );
            }
        } );
    }
}

$ping->submit;
