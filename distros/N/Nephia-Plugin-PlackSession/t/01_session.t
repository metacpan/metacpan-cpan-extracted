use strict;
use Test::More;
use Test::Requires 'Test::WWW::Mechanize::PSGI', 'Plack::Session';
use Plack::Builder;
use Plack::Middleware::Session;

{
    package MyApp;
    use Nephia plugins => [qw/ PlackSession /];

    app {
        my $cnt = session->get('count') || 0;
        session->set(count => ++$cnt);
        [200, [], "count=$cnt"];
    };
}

my $app = builder {
    enable 'Plack::Middleware::Session';
    MyApp->run();
};

my $mech = Test::WWW::Mechanize::PSGI->new(app => $app);

$mech->get_ok('/');
$mech->content_is( 'count=1' );
$mech->get_ok('/');
$mech->content_is( 'count=2' );

done_testing;
