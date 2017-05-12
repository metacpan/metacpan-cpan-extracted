use strict;
use warnings;
use utf8;
use lib 't/lib';

use Test::More;
use Puncheur::Runner;

subtest 'no parse_options' => sub {
    my $runner = Puncheur::Runner->new(TestPuncheur => {
        port   => 9876,
        server => 'TTT',
    });

    isa_ok $runner, 'Puncheur::Runner';
    isa_ok $runner->{runner}, 'Plack::Runner';
    is     $runner->{runner}{server}, 'TTT';
    is     $runner->{app}, 'TestPuncheur';
    is     $runner->{app_options}{port}, 9876;
};

subtest 'no parse_options with ARGV' => sub {
    local @ARGV = qw/-p 6666 -s SSS/;
    my $runner = Puncheur::Runner->new(TestPuncheur => {
        port => 9876,
        server => 'TTT',
    });

    isa_ok $runner, 'Puncheur::Runner';
    isa_ok $runner->{runner}, 'Plack::Runner';
    is     $runner->{runner}{server}, 'SSS';
    is     $runner->{app}, 'TestPuncheur';
    is     $runner->{app_options}{port}, 6666;
};


subtest 'parse_options' => sub {
    my $runner = Puncheur::Runner->new(TestPuncheur2 => {
        port   => 9876,
        server => 'TTT',
    });

    isa_ok $runner, 'Puncheur::Runner';
    isa_ok $runner->{runner}, 'Plack::Runner';
    is     $runner->{runner}{server}, 'TTT';
    is     $runner->{app}, 'TestPuncheur2';
};



subtest 'parse_options with ARGV' => sub {
    local @ARGV = qw/-p 6666 -s SSS/;
    my $runner = Puncheur::Runner->new(TestPuncheur2 => {
        port   => 9876,
        server => 'TTT',
    });

    isa_ok $runner, 'Puncheur::Runner';
    isa_ok $runner->{runner}, 'Plack::Runner';
    is     $runner->{runner}{server}, 'TTT';
    is     $runner->{app}, 'TestPuncheur2';
};

done_testing;
