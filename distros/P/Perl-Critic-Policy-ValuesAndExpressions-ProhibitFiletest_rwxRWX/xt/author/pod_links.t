package main;

use 5.006001;

use strict;
use warnings;

use Test::More 0.88;	# Because of done_testing();

eval {
    require Test::Pod::LinkCheck::Lite;
    1;
} or plan skip_all => 'Unable to load Test::Pod::LinkCheck::Lite';

Test::Pod::LinkCheck::Lite->new(
    # TODO - drop when published to GitHub
    ignore_url		=> qr< \A https://github.com/ >smx,
)->all_pod_files_ok(
    # qw{ blib eg },
    qw{ blib },
);

done_testing;

1;

# ex: set textwidth=72 :
