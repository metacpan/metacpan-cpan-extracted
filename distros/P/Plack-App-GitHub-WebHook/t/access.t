use strict;
use warnings;
use Test::More;
use HTTP::Message::PSGI;
use HTTP::Request::Common;
use HTTP::Response;

use Plack::App::GitHub::WebHook;

my ($app, $code);
sub call {
    my ($url, $payload, %psgi) = @_;
    my $env = req_to_psgi( POST $url, Content => $payload);
    $env->{$_} = $psgi{$_} for keys %psgi;
    $app->to_app->($env)->[0]
}

{
    foreach (undef, 'github') {
        $app = Plack::App::GitHub::WebHook->new;
        $code = call( '/', '{ }', REMOTE_ADDR => '1.1.1.1' );
        is $code, 403, 'Forbidden';

        $code = call( '/', '{ }', REMOTE_ADDR => '204.232.175.65' );
        is $code, 202, 'Accepted';
    }
    
    $app = Plack::App::GitHub::WebHook->new( 
        access => [ 
            allow => 'github', 
            allow => '1.1.1.1',
            deny => 'all',
        ]
    );
    
    $code = call( '/', '{ }', REMOTE_ADDR => '204.232.175.65' );
    is $code, 202, 'Accepted';

    $code = call( '/', '{ }', REMOTE_ADDR => '1.1.1.1' );
    is $code, 202, 'Accepted';

    $code = call( '/', '{ }', REMOTE_ADDR => '1.1.1.2' );
    is $code, 403, 'Forbidden';
    
    foreach ([], 'all') {
        $app = Plack::App::GitHub::WebHook->new( access => $_ );
        $code = call( '/', '{ }', REMOTE_ADDR => '1.1.1.1' );
        is $code, 202, 'access all';
    }
}

{
    $app->events(['pull']);
    $code = call( '/', '{ }' );
    is $code, 400, 'wrong event type';

    $code = call( '/', '{ }', HTTP_X_GITHUB_EVENT => 'pull' );
    is $code, 202, 'checked event type';

    $app->access([ deny => 'all' ]);
    $code = call( '/', '{ }', REMOTE_ADDR => '204.232.175.65' );
    is $code, 403, 'Forbidden';
}

done_testing;
