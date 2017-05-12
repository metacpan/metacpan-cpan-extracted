use strict;
use warnings;

use Test::More;
use Test::Exception;

use Sensu::API::Client;

SKIP: {
    skip '$ENV{SENSU_API_URL} not set', 5 unless $ENV{SENSU_API_URL};

    my $api = Sensu::API::Client->new(
        url => $ENV{SENSU_API_URL},
    );

    my $path = 'xxxx';
    my $cont = { key => 'value' };
    my $r = $api->create_stash(
        path    => $path,
        content => $cont,
    );
    is ($r->{path}, $path, 'Stash created');

    $r = $api->create_stash(
        path    => $path x 3,
        content => $cont,
        expire  => 15,
    );
    is ($r->{path}, $path x 3, 'Stash with expiration created');

    throws_ok { $api->stash() } qr/required/, 'Path is required';

    $r = $api->stash($path);
    is ($r->{key}, $cont->{key}, 'Correct payload retrieved');

    # Clean before start
    $r = $api->stashes;
    is(ref $r, 'ARRAY', 'Got an array ref');
    cmp_ok(@$r, '>=', 1, 'There is at least 1 stash');

    throws_ok { $api->delete_stash } qr/required/, 'Delete stash needs param';

    foreach my $s (@$r) {
        $api->delete_stash($s->{path});
    }
    $r = $api->stashes;
    is(@$r, 0, 'Stashes deleted');

    throws_ok { $api->create_stash(
        path => $path . $path,
        content => { key => 'value' },
        unexpected => 'shit',
    ) } qr/unexpected/i, 'Unexpected keys dies';

    throws_ok { $api->stash } qr/path required/i, 'Path required';

}

done_testing();
