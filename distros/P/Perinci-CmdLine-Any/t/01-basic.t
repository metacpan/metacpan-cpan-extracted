#!perl

use strict;
use warnings;
use Capture::Tiny 'capture';
use Test::More 0.98;
use Test::Needs;

use Perinci::CmdLine::Any;

our %SPEC;

$SPEC{get_cmdline_class} = {
    v => 1.1,
    result_naked => 1,
};
sub get_cmdline_class {
    my %args = @_;
    ref($args{-cmdline});
}

subtest "sanity" => sub {
    my ($stdout, $stderr, $exit) = capture {
        Perinci::CmdLine::Any->new(
            url => '/main/get_cmdline_class',
            pass_cmdline_object => 1,
            exit => 0,
        )->run;
    };
    is($stdout, "Perinci::CmdLine::Lite\n");
};

subtest "env" => sub {
    subtest "env set to classic" => sub {
        test_needs "Perinci::CmdLine::Classic";
        for my $val ("Perinci::CmdLine::Classic", "classic") {
            local $ENV{PERINCI_CMDLINE_ANY} = $val;
            my ($stdout, $stderr, $exit) = capture {
                Perinci::CmdLine::Any->new(
                    url => '/main/get_cmdline_class',
                    pass_cmdline_object => 1,
                    exit => 0,
                )->run;
            };
            is($stdout, "Perinci::CmdLine::Classic\n", $val);
        };
    };
};

done_testing;
