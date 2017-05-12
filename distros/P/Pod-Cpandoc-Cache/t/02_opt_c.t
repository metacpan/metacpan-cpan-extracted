use Test::More;
use strict;
use warnings;
use Pod::Cpandoc::Cache;
use File::Spec::Functions qw(catfile catdir);
use Capture::Tiny qw/ capture /;
use Cwd();
use File::Temp qw/ tempdir /;

$ENV{POD_CPANDOC_CACHE_ROOT} = tempdir( CLEANUP => 1 );

subtest '-c option' => sub {
    local @ARGV = ('-c','Acme::No');
    my ($stdout, $stderr, $exit)  = capture {
        Pod::Cpandoc::Cache->new->run();
    };
    diag ("$stderr, $exit");

    ok( -f catfile($ENV{POD_CPANDOC_CACHE_ROOT}, 'Acme', 'No.txt'), '-f cache_path'  );
};

done_testing;
