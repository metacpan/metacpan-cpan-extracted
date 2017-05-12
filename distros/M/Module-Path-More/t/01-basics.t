#!perl

use 5.010001;
use strict;
use warnings;

use File::Temp qw(tempdir tempfile);
use Module::Path::More qw(module_path pod_path);
use Test::Exception;
use Test::More 0.98;

subtest module_path => sub {
    ok(module_path(module=>'strict'));
    ok(module_path(module=>'strict.pm'));
    ok(module_path(module=>'Module::Path::More'));
    ok(module_path(module=>'Module/Path/More.pm'));

    like(module_path(module=>'Config', find_pm =>1, find_pod=>2, find_pmc=>0), qr/\.pm$/ , 'find .pm before .pod');
    like(module_path(module=>'Config', find_pod=>1, find_pm =>2, find_pmc=>0), qr/\.pod$/, 'find .pod before .pm');
    like(module_path(module=>'Config', find_pod=>2, find_pm =>3, find_pmc=>0, find_prefix=>1), qr/Config$/, 'find prefix before .pod/.pm');

    # XXX opt: all
    # XXX opt: abs
    # XXX opt: find_pmc

    subtest "opt: find_prefix" => sub {
        ok(!module_path(module=>'Module'));
        ok( module_path(module=>'Module', find_prefix=>1));
    };

    {
        my ($fh, $filename) = tempfile();
        my $dir = tempdir(CLEANUP => 1);

        local @INC = ($dir, @INC);

        # we're fine (don't die) when an entry in @INC doesn't exist
        {
            local $INC[0] = "$dir/1";
            lives_ok { module_path(module=>'strict') };
        }

        # we're fine (don't die) when an entry in @INC is not a dir
        {
            local $INC[0] = $filename;
            lives_ok { module_path(module=>'strict') };
        }

        # we're fine (don't die) when an entry in @INC is not readable
        {
            mkdir "$dir/2", ; chmod 0111, "$dir/2";
            local $INC[0] = "$dir/2";
            lives_ok { module_path(module=>'strict') };
        }

        # we're fine (don't die) when an entry in @INC is not accessible (-x)
        {
            mkdir "$dir/3", ; chmod 0, "$dir/3";
            local $INC[0] = ("$dir/3");
            lives_ok { module_path(module=>'strict') };
        }
    }
};

#subtest pod_path => sub {
#};

DONE_TESTING:
done_testing;
