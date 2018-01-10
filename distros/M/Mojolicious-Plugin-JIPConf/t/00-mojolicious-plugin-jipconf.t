#!/usr/bin/env perl

use 5.006;
use strict;
use warnings FATAL => 'all';
use Test::More;
use English qw(-no_match_vars);

plan tests => 3;

subtest 'Require some module' => sub {
    plan tests => 2;

    use_ok 'Mojolicious::Plugin::JIPConf', '0.021';
    require_ok 'Mojolicious::Plugin::JIPConf';

    diag(
        sprintf 'Testing Mojolicious::Plugin::JIPConf %s, Perl %s, %s',
            $Mojolicious::Plugin::JIPConf::VERSION,
            $PERL_VERSION,
            $EXECUTABLE_NAME,
    );
};

subtest 'has_a, is_a' => sub {
    plan tests => 2;

    isa_ok 'Mojolicious::Plugin::JIPConf', 'Mojolicious::Plugin';

    can_ok 'Mojolicious::Plugin::JIPConf', qw(register);
};

subtest 'register() and JIP::Conf API' => sub {
    plan tests => 4;

    my $p = Mojolicious::Plugin::JIPConf->new;

    eval { $p->register(undef, []) } or do {
        like $EVAL_ERROR, qr{^Not \s a \s HASH \s reference}x;
    };

    eval { $p->register(undef, {}) } or do {
        like $EVAL_ERROR, qr{^Bad \s argument \s "helper_name"}x;
    };

    eval {
        $p->register(undef, {
            helper_name      => 'helper_name',
            path_to_variable => 'path_to_variable',
            path_to_file     => undef,
        });
    }
    or do {
        like $EVAL_ERROR, qr{^Bad \s argument \s "path_to_file"}x;
    };

    eval {
        $p->register(undef, {
            helper_name      => 'helper_name',
            path_to_file     => $EXECUTABLE_NAME, # anything from file system
            path_to_variable => undef,
        });
    }
    or do {
        like $EVAL_ERROR, qr{^Bad \s argument \s "path_to_variable"}x;
    };
};

