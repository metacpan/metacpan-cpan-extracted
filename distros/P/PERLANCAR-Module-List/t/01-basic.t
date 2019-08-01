#!perl

use strict;
use warnings;
use Test::More 0.98;

use File::Slurper qw(write_text);
use File::Temp qw(tempfile tempdir);
use PERLANCAR::Module::List;

my $tempdir = tempdir(CLEANUP => !$ENV{DEBUG});
diag "tempdir=$tempdir" if $ENV{DEBUG};

mkdir      "$tempdir/lib1";
mkdir      "$tempdir/lib1/Mod1";
write_text "$tempdir/lib1/Mod1.pm", "";
mkdir      "$tempdir/lib1/Mod2";
write_text "$tempdir/lib1/Mod2.pm", "";
write_text "$tempdir/lib1/Mod2/Sub1.pm", "";
write_text "$tempdir/lib1/Mod2/Sub2.pm", "";

mkdir      "$tempdir/lib2";
write_text "$tempdir/lib2/Mod1.pm", "";
mkdir      "$tempdir/lib2/Mod3";
write_text "$tempdir/lib2/Mod3/Sub1.pm", "";
mkdir      "$tempdir/lib2/Mod3/Sub2";
write_text "$tempdir/lib2/Mod3/Sub2/SubSub1.pm", "";

subtest "all" => sub {

    diag explain ''; # trigger loading of Data::Dumper before we modify @INC
    eval { require String::Wildcard::Bash }; # ditto

    local @INC = ("$tempdir/lib1", "$tempdir/lib2");
    my $res;

    subtest "opt:list_modules=1" => sub {
        $res = PERLANCAR::Module::List::list_modules('', {list_modules=>1});
        is_deeply($res, {'Mod1'=>undef, 'Mod2'=>undef})
            or diag explain $res;

        # opt:recurse=1
        $res = PERLANCAR::Module::List::list_modules('', {list_modules=>1, recurse=>1});
        is_deeply($res, {'Mod1'=>undef, 'Mod2'=>undef, 'Mod2::Sub1'=>undef, 'Mod2::Sub2'=>undef, 'Mod3::Sub1'=>undef, 'Mod3::Sub2::SubSub1'=>undef})
            or diag explain $res;

        # opt:wildcard=1
        subtest "opt:wildcard=1" => sub {
            plan skip_all => "String::Wildcard::Bash not available"
                unless $INC{"String/Wildcard/Bash.pm"};

            $res = PERLANCAR::Module::List::list_modules('Mod[23]*', {list_modules=>1, wildcard=>1});
            is_deeply($res, {'Mod2'=>undef})
                or diag explain $res;
            $res = PERLANCAR::Module::List::list_modules('Mod[23]*::*', {list_modules=>1, wildcard=>1});
            is_deeply($res, {'Mod2::Sub1'=>undef, 'Mod2::Sub2'=>undef, 'Mod3::Sub1'=>undef})
                or diag explain $res;
            $res = PERLANCAR::Module::List::list_modules('*::Sub1', {list_modules=>1, wildcard=>1});
            is_deeply($res, {'Mod2::Sub1'=>undef, 'Mod3::Sub1'=>undef})
                or diag explain $res;
            $res = PERLANCAR::Module::List::list_modules('**Sub1', {list_modules=>1, wildcard=>1});
            is_deeply($res, {'Mod2::Sub1'=>undef, 'Mod3::Sub1'=>undef, 'Mod3::Sub2::SubSub1'=>undef})
                or diag explain $res;
            # recurse=>1 does not change the fact that we match wildcard against full module name
            $res = PERLANCAR::Module::List::list_modules('*Sub1', {list_modules=>1, wildcard=>1, recurse=>1});
            is_deeply($res, {})
                or diag explain $res;
            # recurse=>1 does not change the fact that we match wildcard against full module name
            $res = PERLANCAR::Module::List::list_modules('*::*Sub1', {list_modules=>1, wildcard=>1, recurse=>1});
            is_deeply($res, {'Mod2::Sub1'=>undef, 'Mod3::Sub1'=>undef})
                or diag explain $res;
        };
    };

    subtest "opt:list_prefixes=1" => sub {
        $res = PERLANCAR::Module::List::list_modules('', {list_prefixes=>1});
        is_deeply($res, {'Mod1::'=>undef, 'Mod2::'=>undef, 'Mod3::'=>undef})
            or diag explain $res;

        # opt:recurse=1
        $res = PERLANCAR::Module::List::list_modules('', {list_prefixes=>1, recurse=>1});
        is_deeply($res, {'Mod1::'=>undef, 'Mod2::'=>undef, 'Mod3::'=>undef, 'Mod3::Sub2::'=>undef})
            or diag explain $res;

        # opt:wildcard=1
        subtest "opt:wildcard=1" => sub {
            plan skip_all => "String::Wildcard::Bash not available"
                unless $INC{"String/Wildcard/Bash.pm"};

            $res = PERLANCAR::Module::List::list_modules('Mod[23]*', {list_prefixes=>1, wildcard=>1});
            is_deeply($res, {'Mod2::'=>undef, 'Mod3::'=>undef})
                or diag explain $res;
            $res = PERLANCAR::Module::List::list_modules('Mod[23]*::', {list_prefixes=>1, wildcard=>1});
            is_deeply($res, {'Mod2::'=>undef, 'Mod3::'=>undef})
                or diag explain $res;

            # XXX test wildcard+recurse
        };
    };

    # XXX test opt:list_modules + opt:list_prefixes

    # XXX test opt:return_path

    # XXX test opt:all
};

done_testing;
