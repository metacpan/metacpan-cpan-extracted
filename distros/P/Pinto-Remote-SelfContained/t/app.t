#!perl

use v5.10;
use strict;
use warnings;

use Test::Deep qw(all cmp_deeply re);
use Test::More;
use Test::Warnings qw(had_no_warnings :no_end_test);

use Path::Tiny qw(path);
use lib path(__FILE__)->sibling('lib')->stringify;

use T::Exit;
BEGIN { *CORE::GLOBAL::exit = sub { T::Exit->throw($_[0] // 0) } }

use Capture::Tiny qw(capture);
use Pinto::Remote::SelfContained::App;
use Pinto::Remote::SelfContained::Types qw(SingleBodyPart);

sub parse {
    my (@argv) = @_;
    my ($err, %ret);
    my ($stdout, $stderr) = capture {
        eval { %ret = Pinto::Remote::SelfContained::App->parse_from_argv(\@argv); 1 }
            or $err = $@;
    };
    return $stdout, $stderr, \%ret, $err;
}

sub parse_ok {
    my ($argv, $expected, $desc) = @_;
    my @got = parse(@$argv);
    local $Test::Builder::Level = $Test::Builder::Level + 1;
    cmp_deeply(\@got, $expected, $desc) or diag(explain(\@got));
}

subtest 'global --help', sub {
    parse_ok(
        [],
        [re(qr/^Available commands:\n+ +[a-z]+:/), '', {}, T::Exit->new(0)],
        'list commands with no command-line args',
    );

    parse_ok(
        [qw(--root http://example.com)],
        [re(qr/^Available commands:\n+ +[a-z]+:/), '', {}, T::Exit->new(0)],
        'list commands with global options',
    );

    parse_ok(
        [qw(--help)],
        [re(qr/^Available commands:\n+ +[a-z]+:/), '', {}, T::Exit->new(0)],
        'list commands with --help global',
    );

    parse_ok(
        [qw(--help -u fred)],
        [re(qr/^Available commands:\n+ +[a-z]+:/), '', {}, T::Exit->new(0)],
        'list commands with --help and other global option',
    );

    parse_ok(
        [qw(commands)],
        [re(qr/^Available commands:\n+ +[a-z]+:/), '', {}, T::Exit->new(0)],
        'list commands with commands subcommand',
    );

    parse_ok(
        [qw(xyzzyx)],
        [re(qr/^Available commands:\n+ +[a-z]+:/), '', {}, T::Exit->new(2)],
        'list commands when given invalid command',
    );
};

subtest 'help subcommand', sub {
    my $commands = Pinto::Remote::SelfContained::App->command_info;
    parse_ok(
        [qw(help)],
        [re(qr/^.* help \[.* - \Q$commands->{help}{summary}\E/), '', {}, T::Exit->new(0)],
        'basic help command',
    );
    parse_ok(
        [qw(help props)],
        [all(
            re(qr/^.* help \[.* - \Q$commands->{help}{summary}\E\n\n    Global options:/),
            re(qr/\n.* props \[.* - \Q$commands->{props}{summary}\E/),
         ), '', {}, T::Exit->new(0)],
        'basic help command',
    );
};

subtest 'missing global options', sub {
    my $commands = Pinto::Remote::SelfContained::App->command_info;
    parse_ok(
        [qw(nop -u fred)],
        ['', '', {}, re(qr/^Required options not found: --root\n\n.* nop \[.* - \Q$commands->{nop}{summary}\E/)],
        'nop with missing -r option',
    );
};

subtest 'basic parsing', sub {
    my $commands = Pinto::Remote::SelfContained::App->command_info;
    parse_ok(
        [qw(nop -r http://example.com -u fred)],
        ['', '', { action_name => 'nop', root => 'http://example.com', username => 'fred', args => {} }, undef],
        'nop with global options',
    );
    parse_ok(
        [qw(-r http://example.com -u fred nop --sleep 10)],
        ['', '', { action_name => 'nop', root => 'http://example.com', username => 'fred', args => { sleep => 10 } }, undef],
        'nop with global and local options',
    );
    {
        local $ENV{PINTO_USERNAME} = 'barney';
        parse_ok(
            [qw(-r http://example.com nop)],
            ['', '', { action_name => 'nop', root => 'http://example.com', args => {} }, undef],
            'nop with username taken from env',
        );
        my $remote_instance = do {
            my $app = Pinto::Remote::SelfContained::App->new_from_argv([qw(nop -r http://example.com)]);
            $app->make_remote_instance;
        };
        is($remote_instance->username, 'barney', 'username is correctly defaulted');
    }
    parse_ok(
        [qw(-r http://example.com -u fred copy ffrroomm ttoo)],
        [
            '', '',
            {
                action_name => 'copy',
                root => 'http://example.com',
                username => 'fred',
                args => { 
                    stack => 'ffrroomm',
                    to_stack => 'ttoo',
                 },
             },
             undef,
         ],
        'copy with options supplied as arguments',
    );
    parse_ok(
        [qw(-r http://example.com -u fred cp ffrroomm ttoo)],
        [
            '', '',
            {
                action_name => 'copy',
                root => 'http://example.com',
                username => 'fred',
                args => { 
                    stack => 'ffrroomm',
                    to_stack => 'ttoo',
                 },
             },
             undef,
         ],
        'cp alias with options supplied as arguments',
    );
    (my $copy_usage = $commands->{copy}{usage_desc}) =~ s/.*%o//;
    parse_ok(
        [qw(-r http://example.com -u fred copy)],
        ['', '', {}, re(qr/^Not enough arguments\n\n.* copy \[.*\Q$copy_usage\E/)],
        'copy with too few arguments',
    );
    parse_ok(
        [qw(-r http://example.com -u fred copy ffrroomm ttoo superfluous)],
        ['', '', {}, re(qr/^Too many arguments\n\n.* copy \[.*\Q$copy_usage\E/)],
        'copy with too many arguments',
    );
};

subtest 'parse list command', sub {
    my $command = Pinto::Remote::SelfContained::App->command_info->{list};
    parse_ok(
        [qw(-r http://example.com -u fred list)],
        ['', '', { action_name => 'list', root => 'http://example.com', username => 'fred', args => {} }, undef],
        'list with no options',
    );
    parse_ok(
        [qw(-r http://example.com -u fred list dev)],
        ['', '', { action_name => 'list', root => 'http://example.com', username => 'fred', args => { stack => 'dev' } }, undef],
        'list with argument',
    );
    parse_ok(
        [qw(-r http://example.com -u fred list -s dev)],
        ['', '', { action_name => 'list', root => 'http://example.com', username => 'fred', args => { stack => 'dev' } }, undef],
        'list with -s option',
    );
    (my $usage = $command->{usage_desc}) =~ s/.*%o//;
    parse_ok(
        [qw(list -r http://example.com -u fred -s stackfromopt stackfromarg)],
        ['', '', {}, re(qr/^Stack supplied as both option and argument\n\n.* list \[.*\Q$usage\E/)],
        'list with argument and -s option',
    );
};

subtest 'parse command with many arguments', sub {
    (my $usage = Pinto::Remote::SelfContained::App->command_info->{look}{usage_desc}) =~ s/.*%o//;;
    parse_ok(
        [qw(-r http://example.com -u fred look)],
        ['', '', {}, re(qr/^Need at least one targets argument\n\n.* look \[.*\Q$usage\E/)],
        'look with no arguments',
    );
    parse_ok(
        [qw(-r http://example.com -u fred look fooarchive)],
        [
            '', '',
            {
                action_name => 'look',
                root => 'http://example.com',
                username => 'fred',
                args => { targets => ['fooarchive'] },
            },
            undef,
        ],
        'look with one argument',
    );
    parse_ok(
        [qw(-r http://example.com -u fred look fooarchive bararchive)],
        [
            '', '',
            {
                action_name => 'look',
                root => 'http://example.com',
                username => 'fred',
                args => { targets => ['fooarchive', 'bararchive'] },
            },
            undef,
        ],
        'look with two arguments',
    );
    parse_ok(
        [qw(-r http://example.com -u fred delete)],
        [
            '', '',
            {
                action_name => 'delete',
                root => 'http://example.com',
                username => 'fred',
                args => {},
            },
            undef,
        ],
        'delete with no arguments',
    );
    parse_ok(
        [qw(-r http://example.com -u fred delete fooarchive)],
        [
            '', '',
            {
                action_name => 'delete',
                root => 'http://example.com',
                username => 'fred',
                args => { targets => ['fooarchive'] },
            },
            undef,
        ],
        'delete with one argument',
    );
    parse_ok(
        [qw(-r http://example.com -u fred delete fooarchive bararchive)],
        [
            '', '',
            {
                action_name => 'delete',
                root => 'http://example.com',
                username => 'fred',
                args => { targets => ['fooarchive', 'bararchive'] },
            },
            undef,
        ],
        'delete with two arguments',
    );
};

subtest 'parse diff command', sub {
    (my $usage = Pinto::Remote::SelfContained::App->command_info->{diff}{usage_desc}) =~ s/.*%o//;;
    parse_ok(
        [qw(-r http://example.com -u fred diff)],
        ['', '', {}, re(qr/^You must specify at least one argument\n\n.* diff \[.*\Q$usage\E/)],
        'diff with no arguments',
    );
    parse_ok(
        [qw(-r http://example.com -u fred diff a b c)],
        ['', '', {}, re(qr/^You must specify at most two arguments\n\n.* diff \[.*\Q$usage\E/)],
        'diff with three arguments',
    );
    parse_ok(
        [qw(-r http://example.com -u fred diff b)],
        [
            '', '',
            {
                action_name => 'diff',
                root => 'http://example.com',
                username => 'fred',
                args => { right => 'b' },
            },
            undef,
        ],
        'diff with one argument',
    );
    parse_ok(
        [qw(-r http://example.com -u fred diff a b)],
        [
            '', '',
            {
                action_name => 'diff',
                root => 'http://example.com',
                username => 'fred',
                args => { left => 'a', right => 'b' },
            },
            undef,
        ],
        'diff with two arguments',
    );
};

subtest 'parse add command', sub {
    (my $usage = Pinto::Remote::SelfContained::App->command_info->{add}{usage_desc}) =~ s/.*%o//;;
    parse_ok(
        [qw(-r http://example.com -u fred add)],
        ['', '', {}, re(qr/^Need exactly one archive\n\n.* add \[.*\Q$usage\E/)],
        'add with no arguments',
    );
    parse_ok(
        [qw(-r http://example.com -u fred add Foo-0.01.tar.gz Bar-0.01.tar.gz)],
        ['', '', {}, re(qr/^Need exactly one archive\n\n.* add \[.*\Q$usage\E/)],
        'add with two arguments',
    );
    parse_ok(
        [qw(-r http://example.com -u fred add Foo-0.01.tar.gz)],
        [
            '', '',
            {
                action_name => 'add',
                root => 'http://example.com',
                username => 'fred',
                args => {
                    archives => [{
                        name => 'archives',
                        filename => 'Foo-0.01.tar.gz',
                        type => 'application/x-tar',
                        encoding => 'gzip',
                    }],
                },
            },
            undef,
        ],
        'add with one argument',
    );
    ok(
        SingleBodyPart->check([{
            name => 'archives',
            filename => 'Foo-0.01.tar.gz',
            type => 'application/x-tar',
            encoding => 'gzip',
        }]),
        'archive part is valid',
    );
};

subtest 'parse default command', sub {
    (my $usage = Pinto::Remote::SelfContained::App->command_info->{default}{usage_desc}) =~ s/.*%o//;;
    parse_ok(
        [qw(-r http://example.com -u fred default)],
        ['', '', {}, re(qr/^You must specify either a stack or --none\n\n.* default \[.*\Q$usage\E/)],
        'default with no arguments',
    );
    parse_ok(
        [qw(-r http://example.com -u fred default -s dev --none)],
        ['', '', {}, re(qr/^You cannot specify both a stack and --none\n\n.* default \[.*\Q$usage\E/)],
        'default with both stack and --none',
    );
    parse_ok(
        [qw(default --none -r http://example.com -u fred)],
        [
            '', '',
            {
                action_name => 'default',
                root => 'http://example.com',
                username => 'fred',
                args => { none => 1 },
            },
            undef,
        ],
        'default with --none option',
    );
    parse_ok(
        [qw(default dev -r http://example.com -u fred)],
        [
            '', '',
            {
                action_name => 'default',
                root => 'http://example.com',
                username => 'fred',
                args => { stack => 'dev' },
            },
            undef,
        ],
        'default with stack argument',
    );
};

subtest 'parse install command', sub {
    (my $usage = Pinto::Remote::SelfContained::App->command_info->{install}{usage_desc}) =~ s/.*%o//;;
    parse_ok(
        [qw(-r http://example.com -u fred install)],
        [
            '', '',
            {
                action_name => 'install',
                root => 'http://example.com',
                username => 'fred',
                args => { targets => [] },
            },
            undef,
        ],
        'install with no arguments',
    );
    parse_ok(
        [qw(-r http://example.com -u fred install Types::Standard Moo)],
        [
            '', '',
            {
                action_name => 'install',
                root => 'http://example.com',
                username => 'fred',
                args => { targets => ['Types::Standard', 'Moo'] },
            },
            undef,
        ],
        'install with two arguments',
    );
    parse_ok(
        [qw(-r http://example.com -u fred install --local-lib=lib Types::Standard)],
        [
            '', '',
            {
                action_name => 'install',
                root => 'http://example.com',
                username => 'fred',
                args => {
                    cpanm_options => { 'local-lib' => 'lib' },
                    targets => ['Types::Standard'],
                },
            },
            undef,
        ],
        'install with --local-lib and a target',
    );
    parse_ok(
        [qw(-r http://example.com -u fred install --local-lib=lib --cpanm-options --notest Types::Standard)],
        [
            '', '',
            {
                action_name => 'install',
                root => 'http://example.com',
                username => 'fred',
                args => {
                    cpanm_options => {
                        'notest' => undef,
                        'local-lib' => 'lib',
                    },
                    targets => ['Types::Standard'],
                },
            },
            undef,
        ],
        'install with --local-lib and --cpanm-options and a target',
    );
};

had_no_warnings();
done_testing();
