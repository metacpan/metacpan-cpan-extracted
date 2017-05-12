#!/usr/bin/env perl

use Modern::Perl;

use utf8;
use open ':encoding(utf8)';

use Test::More;
use Plack::Test::Agent;
use Plack::Request;

my $app = sub
{
    my $res  = Plack::Request->new( shift );

    my $want = $res->param( 'want' );
    my $have = $res->param( 'have' );
    my $desc = $res->param( 'desc' );

    my ($code, $output) = ( $want eq $have )
                        ? ( 200, 'ok'      )
                        : ( 412, 'not ok'  );

    $output .= ' - ' . $desc if $desc;
    return [ $code, [ 'Content-Type' => 'text/plain' ], [ $output ] ];
};

my $bare_agent   = Plack::Test::Agent->new( app    => $app );
my $server_agent = Plack::Test::Agent->new( app    => $app,
                                            server => 'HTTP::Server::PSGI' );
run_tests_with_agent( $bare_agent );
run_tests_with_agent( $server_agent );

sub run_tests_with_agent
{
    my $agent = shift;
    my $res   = $agent->get( '/?have=foo;want=foo' );
    ok $res->is_success, 'Request should succeed when values match';
    is $res->decoded_content, 'ok', '... with descriptive success message';

    $res    = $agent->get( '/?have=10;want=20' );
    ok ! $res->is_success, 'Request should fail when values do not match';
    is $res->decoded_content, 'not ok', '... with descriptive error';

    my $uri = URI->new( '/' );
    $uri->query_form( have => 'cow', want => 'cow', desc => 'Cow Comparison' );
    $res    = $agent->get( $uri );

    ok $res->is_success, 'Request should succeed when values do';
    is $res->decoded_content, 'ok - Cow Comparison',
        '... including description when provided';
    is $res->content_type, 'text/plain', '... with plain text content';
    is $res->content_charset, 'US-ASCII', '... in ASCII';

    $res    = $agent->post( '/', [ have => 'cow', want => 'pig', desc => 'æ' ] );
    ok ! $res->is_success, 'Request should fail given different values';
    is $res->decoded_content, "not ok - \x{00E6}",
        '... including description when provided';
    is $res->content_type, 'text/plain', '... with plain text content';
    is $res->content_charset, 'UTF-8', '... in ASCII';
}

done_testing;
