#!perl

use strict;
use warnings;
use Test::More 0.98;

use File::Slurper qw(write_text);
use File::Temp qw(tempfile tempdir);
use Module::List::More qw(list_modules);

my $tempdir = tempdir(CLEANUP => !$ENV{DEBUG});
diag "tempdir=$tempdir" if $ENV{DEBUG};

mkdir      "$tempdir/lib1";
mkdir      "$tempdir/lib1/Mod1";
write_text "$tempdir/lib1/Mod1.pm", "package Mod1;\nour \$VERSION = '0.01'; 1;\n";
mkdir      "$tempdir/lib1/Mod2";
write_text "$tempdir/lib1/Mod2.pm", "";
write_text "$tempdir/lib1/Mod2/Sub1.pm", "";
write_text "$tempdir/lib1/Mod2/Sub2.pm", "";

mkdir      "$tempdir/lib2";
write_text "$tempdir/lib2/Mod1.pm", "package Mod1;\nour \$VERSION = '0.02'; 1;\n";
mkdir      "$tempdir/lib2/Mod3";
write_text "$tempdir/lib2/Mod3/Sub1.pm", "";
mkdir      "$tempdir/lib2/Mod3/Sub2";
write_text "$tempdir/lib2/Mod3/Sub2/SubSub1.pm", "";

subtest "all" => sub {

    diag explain ''; # trigger loading of Data::Dumper before we modify @INC
    require ExtUtils::MakeMaker; # ditto
    # load optional prereqs
    eval {
        require String::Wildcard::Bash; # ditto
    };

    local @INC = ("$tempdir/lib1", "$tempdir/lib2");
    my $res;

    subtest "opt:list_modules=1" => sub {
        $res = list_modules('', {list_modules=>1});
        is_deeply($res, {
            'Mod1'=>undef,
            'Mod2'=>undef,
        }) or diag explain $res;

        # opt:return_path=1
        $res = list_modules('', {list_modules=>1, return_path=>1});
        is_deeply($res, {
            'Mod1'=>{module_path=>"$tempdir/lib1/Mod1.pm"},
            'Mod2'=>{module_path=>"$tempdir/lib1/Mod2.pm"},
        }) or diag explain $res;

        # opt:recurse=1
        $res = list_modules('', {list_modules=>1, recurse=>1, return_path=>1});
        is_deeply($res, {
            'Mod1'=>{module_path=>"$tempdir/lib1/Mod1.pm"},
            'Mod2'=>{module_path=>"$tempdir/lib1/Mod2.pm"},
            'Mod2::Sub1'=>{module_path=>"$tempdir/lib1/Mod2/Sub1.pm"},
            'Mod2::Sub2'=>{module_path=>"$tempdir/lib1/Mod2/Sub2.pm"},
            'Mod3::Sub1'=>{module_path=>"$tempdir/lib2/Mod3/Sub1.pm"},
            'Mod3::Sub2::SubSub1'=>{module_path=>"$tempdir/lib2/Mod3/Sub2/SubSub1.pm"},
        }) or diag explain $res;

        # opt:wildcard=1
        subtest "opt:wildcard=1" => sub {
            plan skip_all => "String::Wildcard::Bash not available"
                unless $INC{"String/Wildcard/Bash.pm"};

            $res = list_modules('Mod[23]*', {list_modules=>1, return_path=>1, wildcard=>1});
            is_deeply($res, {'Mod2'=>{module_path=>"$tempdir/lib1/Mod2.pm"}}) or diag explain $res;
            $res = list_modules('Mod[23]*::*', {list_modules=>1, return_path=>1, wildcard=>1});
            is_deeply($res, {
                'Mod2::Sub1'=>{module_path=>"$tempdir/lib1/Mod2/Sub1.pm"},
                'Mod2::Sub2'=>{module_path=>"$tempdir/lib1/Mod2/Sub2.pm"},
                'Mod3::Sub1'=>{module_path=>"$tempdir/lib2/Mod3/Sub1.pm"},
            }) or diag explain $res;
            $res = list_modules('*::Sub1', {list_modules=>1, return_path=>1, wildcard=>1});
            is_deeply($res, {
                'Mod2::Sub1'=>{module_path=>"$tempdir/lib1/Mod2/Sub1.pm"},
                'Mod3::Sub1'=>{module_path=>"$tempdir/lib2/Mod3/Sub1.pm"},
            }) or diag explain $res;
            $res = list_modules('**Sub1', {list_modules=>1, return_path=>1, wildcard=>1});
            is_deeply($res, {
                'Mod2::Sub1'=>{module_path=>"$tempdir/lib1/Mod2/Sub1.pm"},
                'Mod3::Sub1'=>{module_path=>"$tempdir/lib2/Mod3/Sub1.pm"},
                'Mod3::Sub2::SubSub1'=>{module_path=>"$tempdir/lib2/Mod3/Sub2/SubSub1.pm"},
            }) or diag explain $res;
            # recurse=>1 does not change the fact that we match wildcard against full module name
            $res = list_modules('*Sub1', {list_modules=>1, return_path=>1, wildcard=>1, recurse=>1});
            is_deeply($res, {})
                or diag explain $res;
            # recurse=>1 does not change the fact that we match wildcard against full module name
            $res = list_modules('*::*Sub1', {list_modules=>1, return_path=>1, wildcard=>1, recurse=>1});
            is_deeply($res, {
                'Mod2::Sub1'=>{module_path=>"$tempdir/lib1/Mod2/Sub1.pm"},
                'Mod3::Sub1'=>{module_path=>"$tempdir/lib2/Mod3/Sub1.pm"},
            }) or diag explain $res;
        };

        # opt:return_library_path
        $res = list_modules('', {list_modules=>1, return_path=>1, return_library_path=>1});
        is_deeply($res, {
            'Mod1'=>{module_path=>"$tempdir/lib1/Mod1.pm", library_path=>"$tempdir/lib1"},
            'Mod2'=>{module_path=>"$tempdir/lib1/Mod2.pm", library_path=>"$tempdir/lib1"},
        }) or diag explain $res;

        # opt:return_library_path (+ opt:all)
        $res = list_modules('', {list_modules=>1, return_path=>1, return_library_path=>1, all=>1});
        is_deeply($res, {
            'Mod1'=>{module_path=>["$tempdir/lib1/Mod1.pm", "$tempdir/lib2/Mod1.pm"], library_path=>["$tempdir/lib1", "$tempdir/lib2"]},
            'Mod2'=>{module_path=>["$tempdir/lib1/Mod2.pm"], library_path=>["$tempdir/lib1"]},
        }) or diag explain $res;

        # opt:return_version (+ opt:all)
        $res = list_modules('', {list_modules=>1, return_path=>1, return_version=>1, all=>1});
        is_deeply($res, {
            'Mod1'=>{module_path=>["$tempdir/lib1/Mod1.pm", "$tempdir/lib2/Mod1.pm"], module_version=>['0.01', '0.02']},
            'Mod2'=>{module_path=>["$tempdir/lib1/Mod2.pm"], module_version=>[undef]},
        }) or diag explain $res;
    };

    subtest "opt:list_prefixes=1" => sub {
        $res = list_modules('', {list_prefixes=>1});
        is_deeply($res, {
            'Mod1::'=>undef,
            'Mod2::'=>undef,
            'Mod3::'=>undef,
        }) or diag explain $res;

        # opt:return_path=>1
        $res = list_modules('', {list_prefixes=>1, return_path=>1});
        is_deeply($res, {
            'Mod1::'=>{prefix_paths=>["$tempdir/lib1/Mod1/"]},
            'Mod2::'=>{prefix_paths=>["$tempdir/lib1/Mod2/"]},
            'Mod3::'=>{prefix_paths=>["$tempdir/lib2/Mod3/"]},
        }) or diag explain $res;

        # opt:recurse=1
        $res = list_modules('', {list_prefixes=>1, return_path=>1, recurse=>1});
        is_deeply($res, {
            'Mod1::'=>{prefix_paths=>["$tempdir/lib1/Mod1/"]},
            'Mod2::'=>{prefix_paths=>["$tempdir/lib1/Mod2/"]},
            'Mod3::'=>{prefix_paths=>["$tempdir/lib2/Mod3/"]},
            'Mod3::Sub2::'=>{prefix_paths=>["$tempdir/lib2/Mod3/Sub2/"]},
        }) or diag explain $res;

        # opt:wildcard=1
        subtest "opt:wildcard=1" => sub {
            plan skip_all => "String::Wildcard::Bash not available"
                unless $INC{"String/Wildcard/Bash.pm"};

            $res = list_modules('Mod[23]*', {list_prefixes=>1, return_path=>1, wildcard=>1});
            is_deeply($res, {
                'Mod2::'=>{prefix_paths=>["$tempdir/lib1/Mod2/"]},
                'Mod3::'=>{prefix_paths=>["$tempdir/lib2/Mod3/"]},
            }) or diag explain $res;
            $res = list_modules('Mod[23]*::', {list_prefixes=>1, return_path=>1, wildcard=>1});
            is_deeply($res, {
                'Mod2::'=>{prefix_paths=>["$tempdir/lib1/Mod2/"]},
                'Mod3::'=>{prefix_paths=>["$tempdir/lib2/Mod3/"]},
            }) or diag explain $res;

            # XXX test wildcard+recurse
        };
    };

    # XXX test opt:list_pod

    # XXX test opt:list_modules + opt:list_prefixes

    # XXX test opt:all
};

done_testing;
