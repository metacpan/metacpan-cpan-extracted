use strict;
use Test::More;
use Test::WWW::Mechanize::PSGI;
use Nephia::Core;

my $v = Nephia::Core->new(
    app => sub {    
        my $cnt = cookie('count') || 0;
        cookie(count => ++$cnt);
        [200, [], "count=$cnt"];
    },
);

my $mech = Test::WWW::Mechanize::PSGI->new(app => $v->run);

$mech->get_ok('/');
$mech->content_is( 'count=1' );
$mech->get_ok('/');
$mech->content_is( 'count=2' );

done_testing;
