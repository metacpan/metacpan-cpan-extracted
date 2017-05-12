#!perl
use lib 't/lib';
use Test::Sietima;
use Path::Tiny;
use Sietima;
use Sietima::CmdLine;

subtest 'given instance' => sub {
    my $s = Sietima->new({
        return_path => 'list@example.com',
    });
    my $c = Sietima::CmdLine->new({
        sietima => $s,
    });
    is(
        $c,
        object {
            call app_spec => object {
                call name => 'sietima';
                call subcommands => hash {
                    field send => object {
                        call name => 'send';
                    };
                    etc;
                };
            };
            call runner => object {
                call cmd => $s;
            };
        },
        'spec & runner should be built',
    );
};

subtest 'built via args' => sub {
    my $c = Sietima::CmdLine->new({
        args => {
            return_path => 'list@example.com',
        },
    });
    is(
        $c,
        object {
            call sietima => object {
                call return_path => 'list@example.com';
            };
        },
        'sietima should be built',
    );
};

subtest 'built via args & traits' => sub {
    my $c = Sietima::CmdLine->new({
        traits => [ qw(ReplyTo) ],
        args => {
            return_path => 'list@example.com',
        },
    });
    DOES_ok(
        $c->sietima,
        ['Sietima::Role::ReplyTo'],
        'sietima should be built with the given trait',
    );
};

subtest 'extra spec' => sub {
    my $c = Sietima::CmdLine->new({
        extra_spec => { name => 'different' },
        args => {
            return_path => 'list@example.com',
        },
    });
    is(
        $c->app_spec,
        object {
            call name => 'different';
        },
        'spec fields should be overridden',
    );
};

done_testing;
