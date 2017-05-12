use strict;
use warnings;
use Test::More 0.88;
use Plack::Builder;
use HTTP::Request::Common;
use Plack::Test;

sub test_file {
    my ( $file, $content ) = @_;
    return eval {
        my $app = builder {
            enable "Assets", files => ["t/static/$file"];
            return sub {
                my $env = shift;
                [   200,
                    [ 'Content-type', 'text/plain' ],
                    [ map { $_ . $/ } @{ $env->{'psgix.assets'} } ]
                ];
            };
        };

        my $assets;

        my %test = (
            client => sub {
                my $cb = shift;
                {
                    my $res = $cb->( GET 'http://localhost/' );
                    is( $res->code, 200 );
                    $assets = [ split( $/, $res->content ) ];
                    is( @$assets, 1 );
                }

                {
                    my $res = $cb->( GET 'http://localhost' . $assets->[0] );
                    is( $res->code, 200 );
                    is( $res->content, $content, 'got content' );
                }
            },
            app => $app,
        );
        test_psgi %test;
        1;
    };
}

is test_file( 'js2.js' => 'js2()' ), 1, 'got file ok';

is test_file( 'no.exist' => '' ), undef, 'errored';
like $@, qr{t/static/no\.exist: }, 'died on non-existent file';

done_testing;
