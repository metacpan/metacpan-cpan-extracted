package MyTest;

use Moo;
extends 'Exporter';

our @EXPORT_OK = qw{ check_endpoint };

use Test::Most;
use Sub::Override;

use HTTP::Message;

use JSON qw{ from_json };

my $override = Sub::Override->new;

sub check_endpoint {
    my ( $object, @tests ) = @_;

    foreach my $test (@tests) {
        subtest 'Calling ' . $test->{name} => sub {
            _call_subtest( $object, $test );
        };
    }
}

sub _call_subtest {
    my ( $object, $test ) = @_;

    ## Overwriting LWP::UserAgent::request()
    ## to verify request and fake the response
    my $request;
    $override->replace(
        'LWP::UserAgent::request' => sub {
            ( undef, $request ) = @_;

            ## Discard fake response
            return HTTP::Response->new( 200, 'OK', HTTP::Headers->new, '{}' );
        },
    );

    my $call = $test->{name};
    my $res  = $object->$call( @{ $test->{args} } );

    ## Request method
    is( $request->method, $test->{method}, 'Checking HTTP method' );

    ## Request URI
    is( $request->uri . '', $test->{uri}, 'Checking URI', );

    ## Request data
    if ( $request->content ) {
        my $data = from_json $request->content;
        my ($request_data) = grep { ref $_ eq 'HASH' } @{ $test->{args} };
        is_deeply( $data, $request_data, 'Checking data' );
    }

    $override->restore('LWP::UserAgent::request');
}

1;

