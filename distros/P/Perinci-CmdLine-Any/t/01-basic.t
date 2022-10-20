#!perl

use strict;
use warnings;
use Test::More 0.98;
use Test::Needs;

use Capture::Tiny 'capture_merged';
use Perinci::CmdLine::Any;

our %SPEC;

$SPEC{get_cmdline_class} = {
    v => 1.1,
    result_naked => 1,
};
sub get_cmdline_class {
    my %args = @_;
    note $args{-cmdline};
    ref($args{-cmdline});
}

sub reset_plugins {
    no warnings 'once';
    %Perinci::CmdLine::Base::Handlers = ();
}

subtest "sanity" => sub {
    my ($stdout, $stderr, $exit) = capture_merged {
        Perinci::CmdLine::Any->new(
            url => '/main/get_cmdline_class',
            pass_cmdline_object => 1,
            exit => 0,
        )->run;
    };
    like($stdout, qr/^Perinci::CmdLine::Lite\R?\z/m);
};

subtest "env" => sub {
    subtest "env set to classic" => sub {
        test_needs "Perinci::CmdLine::Classic";
        for my $val ("Perinci::CmdLine::Classic", "classic") {
            local $ENV{PERINCI_CMDLINE_ANY} = $val;
            my ($stdout, $stderr, $exit) = capture_merged {
                reset_plugins();
                Perinci::CmdLine::Any->new(
                    url => '/main/get_cmdline_class',
                    pass_cmdline_object => 1,
                    exit => 0,
                )->run;
            };
            like($stdout, qr/^Perinci::CmdLine::Classic\R\z/m, $val);
        };
    };
};

done_testing;
