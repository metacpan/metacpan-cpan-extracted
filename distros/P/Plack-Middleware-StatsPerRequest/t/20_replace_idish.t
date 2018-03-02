use strict;
use warnings;
use FindBin;
use Test::More;

use Plack::Middleware::StatsPerRequest;

my @unchanged =
    qw(/ /index.html /foo /some/path /some/path/12345.html /api/v1/resource /perl/2018_02_plack_middleware_stats_per_request.html /some/affe);

my @changed = (
    [   qw(/averylongpaththatdoesnotreallymakesenseaverylongpaththatdoesnotreallymakesense /:long)
    ],
    [   qw(/averylongpaththatdoesnotreallymakesenseaverylongpaththatdoesnotreallymakesense/ /:long/)
    ],
    [   qw(/averylongpaththatdoesnotreallymakesenseaverylongpaththatdoesnotreallymakesense/foo /:long/foo)
    ],
    [qw(/commit/ca525030037e5a6496c8f29cb2f1daf5a5896d69 /commit/:sha1)],
    [qw(/thing/109200da-4085-412a-9958-54a3dd8385b9 /thing/:uuid)],
    [   qw(/image/8b/62/8b62bd3c4a95eb68259721822b7baea4d5cf86bb.jpg /image/:hexpath/:sha1.jpg)
    ],
    [   qw(/image/b8/8ff/440/b88ff440-823d-11e4-843e-be5cc84539f9.jpg /image/:hexpath/:uuid.jpg)
    ],
    [qw(/some/deadbeef /some/:hex)],
    [qw(/item/234234/edit /item/:int/edit)],
    [qw(/ip/300x230/image.png /ip/:imgdim/image.png)],
    [qw(/mail/affe001@xaxos.mail /mail/:msgid)],
    [qw(/mail/affe001@xaxos.mail/view /mail/:msgid/view)],
    [qw(/some/path/123456.html /some/path/:int.html)],
    [qw(/some/path/thing-123456.html /some/path/thing-:int.html)],
);

subtest 'paths not changed' => sub {
    foreach my $path (@unchanged) {
        is( Plack::Middleware::StatsPerRequest::replace_idish($path),
            $path, "not changed $path" );
    }
};

subtest 'changed paths' => sub {
    foreach my $t (@changed) {
        is( Plack::Middleware::StatsPerRequest::replace_idish( $t->[0] ),
            $t->[1], sprintf( 'changed %s to %s', @$t ) );
    }
};

done_testing;
