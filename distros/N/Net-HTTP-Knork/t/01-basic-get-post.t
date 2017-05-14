use strict;
use warnings;
use Test::More;
use Test::LWP::UserAgent;
use Test::Deep;
use Net::HTTP::Knork;
use Net::HTTP::Knork::Response;
use URI;
use URI::QueryParam;
use FindBin qw($Bin);
my $tua = Test::LWP::UserAgent->new;
$tua->map_response(
    sub {
        my $req = shift;
        my $uri_path = $req->uri->path;
        if ( $req->method eq 'GET' ) {
            return ( $uri_path eq '/show/foo' );
        }
        if ( $req->method eq 'POST' ) {
            if ( $uri_path eq '/add' ) {
                my $content_decoded;
                my $content = $req->content;
                my $uri = URI->new("","http");
                $uri->query($content);
                foreach my $k ($uri->query_param) { 
                    $content_decoded->{$k} = $uri->query_param($k);
                } 
                return eq_deeply($content_decoded, { titi => 'toto', tutu => 'plop' });
            }
        }
    },
    Net::HTTP::Knork::Response->new('200','OK')
);
my $client = Net::HTTP::Knork->new(
    spore_rx => "$Bin/../share/config/specs/spore_validation.rx",
    spec     => 't/fixtures/api.json',
    client   => $tua
);


my $resp = $client->get_user_info( { user => 'foo' } );
is( $resp->code, '200', 'our user is correctly set to foo' );
$resp =
  $client->add_user( { 'titi' => 'toto', 'tutu' => 'plop' } );
is( $resp->code, '200', 'our parameters are correctly set' );

my $hash_arg = $client->get_user_info( user => 'foo' );
is( $hash_arg->code, '200', 'can pass in a hash instead of a ref' );
$resp =
  $client->add_user(  'titi' => 'toto', 'tutu' => 'plop'  );
is( $resp->code, '200', 'can pass in a hash for payload as well' );
done_testing();
