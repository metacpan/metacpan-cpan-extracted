package ClientTest;

use strict;
use warnings;

use Test::More;

use Net::Curl::Easy qw(:constants);

use MyServer;

use constant _paths => qw( foo bar biggie baz qux quux );

our $TEST_COUNT = 2 * _paths();

sub run {
    my ($promiser, $port) = @_;

    my @promises = map {
        my $path = $_;
        my $easy = Net::Curl::Easy->new();
        $easy->setopt( CURLOPT_URL() => "http://127.0.0.1:$port/$path" );

        # $easy->setopt( CURLOPT_VERBOSE() => 1 );

        $_ = q<> for @{$easy}{ qw(_head _body) };
        $easy->setopt( CURLOPT_HEADERDATA() => \$easy->{'_head'} );
        $easy->setopt( CURLOPT_FILE() => \$easy->{'_body'} );

        $promiser->add_handle($easy)->then( sub {
            my ($easy) = shift;

            like($easy->{'_head'}, qr<\A$MyServer::HEAD_START>, "headers: $path" );

            if ($path eq 'biggie') {
                is( $easy->{'_body'}, $MyServer::BIGGIE, "payload: $path" );
            }
            else {
                is( $easy->{'_body'}, "/$path", "payload: $path" );
            }
        }, sub { warn "REJECT $path: @_\n" } );
    } _paths();

    my $promise_class = (ref $promises[0]);

    my $is_mojo = $promise_class->isa('Mojo::Promise');

    return $promise_class->all( $is_mojo ? @promises : \@promises );
}

1;
