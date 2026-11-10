use strict;
use warnings;
use utf8;
use Test::More;

use Smart::Options;

subtest 'get option from environment' => sub {
    $ENV{'TEST_OPT1'} = 'opt1';
    $ENV{'ENV_OPT2'}  = 'opt2';
    $ENV{'TEST_OPT3'} = 'opt3';
    my $opt = Smart::Options->new->env_prefix('TEST')->env('opt1', 'opt2');
    my $argv = $opt->parse();

    is $argv->{opt1}, 'opt1';
    ok !$argv->{opt2};
    ok !$argv->{opt3};
};

subtest 'override environment with option' => sub {
    $ENV{'TEST_OPT1'} = 'opt1';
    my $opt = Smart::Options->new->env_prefix('TEST')->env('opt1');
    my $argv = $opt->parse(qw/--opt1=option/);

    is $argv->{opt1}, 'option';
};

done_testing;
