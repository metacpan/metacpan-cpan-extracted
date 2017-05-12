use strict;
use warnings;
use File::Spec;
use Test::More;
use Cwd;

my $current_dir;
BEGIN { $current_dir = getcwd }

use Project::Libs lib_dirs => [qw(extlib)];

subtest 'find_inc' => sub {
    for my $path (map {
        File::Spec->catfile($FindBin::Bin, $_)
    } qw(modules/Plack/lib modules/Devel-KYTProf/lib extlib lib)) {
        ok grep { $path eq $_ } @INC;
    }

    done_testing;
};

subtest 'current_dir' => sub {
    is $current_dir, getcwd;
};

done_testing;
