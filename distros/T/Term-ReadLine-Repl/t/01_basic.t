use strict;
use warnings;

use Test::More;
use Test::Exception;

use Term::ReadLine::Repl;

# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------

my $dummy_exec = sub { 1 };

sub make_repl {
    my (%overrides) = @_;
    my %defaults = (
        name       => 'test',
        cmd_schema => { foo => { exec => $dummy_exec } },
    );
    return Term::ReadLine::Repl->new({ %defaults, %overrides });
}

# ---------------------------------------------------------------------------
# validate_args - required fields
# ---------------------------------------------------------------------------

subtest 'missing name croaks' => sub {
    throws_ok { Term::ReadLine::Repl->new({ cmd_schema => { foo => { exec => $dummy_exec } } }) }
        qr/name is a required arg/, 'croaks when name is missing';
};

subtest 'missing cmd_schema croaks' => sub {
    throws_ok { Term::ReadLine::Repl->new({ name => 'test' }) }
        qr/cmd_schema is a required arg/, 'croaks when cmd_schema is missing';
};

subtest 'cmd_schema not a hashref croaks' => sub {
    throws_ok { Term::ReadLine::Repl->new({ name => 'test', cmd_schema => 'bad' }) }
        qr/cmd_schema is NOT a hashref/, 'croaks when cmd_schema is not a hashref';
};

# ---------------------------------------------------------------------------
# validate_args - cmd_schema contents
# ---------------------------------------------------------------------------

subtest 'cmd missing exec croaks' => sub {
    throws_ok { Term::ReadLine::Repl->new({ name => 'test', cmd_schema => { foo => {} } }) }
        qr/missing exec key/, 'croaks when exec key is absent';
};

subtest 'cmd exec not a coderef croaks' => sub {
    throws_ok { Term::ReadLine::Repl->new({ name => 'test', cmd_schema => { foo => { exec => 'not_a_coderef' } } }) }
        qr/exec is NOT a coderef/, 'croaks when exec is not a coderef';
};

subtest 'cmd args not an arrayref croaks' => sub {
    throws_ok {
        Term::ReadLine::Repl->new({
            name       => 'test',
            cmd_schema => { foo => { exec => $dummy_exec, args => 'bad' } },
        })
    } qr/args is NOT a arrayref/, 'croaks when args is not an arrayref';
};

subtest 'cmd args empty arrayref croaks' => sub {
    throws_ok {
        Term::ReadLine::Repl->new({
            name       => 'test',
            cmd_schema => { foo => { exec => $dummy_exec, args => [] } },
        })
    } qr/args array is empty/, 'croaks when args arrayref is empty';
};

subtest 'cmd args contains non-hashref croaks' => sub {
    throws_ok {
        Term::ReadLine::Repl->new({
            name       => 'test',
            cmd_schema => { foo => { exec => $dummy_exec, args => ['not_a_hash'] } },
        })
    } qr/non-hashref found in args arrayref/, 'croaks when args entry is not a hashref';
};

# ---------------------------------------------------------------------------
# validate_args - get_opts
# ---------------------------------------------------------------------------

subtest 'get_opts not a coderef croaks' => sub {
    throws_ok { make_repl( get_opts => 'not_a_coderef' ) }
        qr/get_opts is NOT a coderef/, 'croaks when get_opts is not a coderef';
};

subtest 'get_opts as coderef is accepted' => sub {
    lives_ok { make_repl( get_opts => sub { 1 } ) }
        'does not croak when get_opts is a coderef';
};

# ---------------------------------------------------------------------------
# new() - valid construction
# ---------------------------------------------------------------------------

subtest 'basic construction succeeds' => sub {
    my $repl;
    lives_ok { $repl = make_repl() } 'constructs without error';
    isa_ok $repl, 'Term::ReadLine::Repl';
};

subtest 'builtin commands are added' => sub {
    my $repl = make_repl();
    ok exists $repl->{cmd_schema}{help}, 'help command added';
    ok exists $repl->{cmd_schema}{quit}, 'quit command added';
};

subtest 'default prompt is set' => sub {
    my $repl = make_repl();
    like $repl->{prompt}, qr/repl/, 'default prompt contains repl name';
};

subtest 'custom prompt is interpolated' => sub {
    my $repl = make_repl( name => 'mything', prompt => '(%s)>' );
    like $repl->{prompt}, qr/mything/, 'custom prompt contains name';
};

subtest 'passthrough defaults to 0' => sub {
    my $repl = make_repl();
    is $repl->{passthrough}, 0, 'passthrough defaults to 0';
};

# ---------------------------------------------------------------------------
# _tab_complete
# ---------------------------------------------------------------------------

my $repl = Term::ReadLine::Repl->new({
    name       => 'test',
    cmd_schema => {
        stats => {
            exec => $dummy_exec,
            args => [{ host => 'hostname', guest => 'guestname', refresh => undef }],
        },
        show => { exec => $dummy_exec },
    },
});

subtest 'tab completes command names' => sub {
    my @got = $repl->_tab_complete('st', 'st');
    ok grep { $_ eq 'stats' } @got, 'completes "st" to "stats"';
};

subtest 'tab does not complete non-matching commands' => sub {
    my @got = $repl->_tab_complete('xyz', 'xyz');
    is scalar @got, 0, 'no completions for unknown prefix';
};

subtest 'tab completes args for a known command' => sub {
    my @got = $repl->_tab_complete('', 'stats ');
    ok grep { $_ eq 'host'    } @got, 'host arg present';
    ok grep { $_ eq 'guest'   } @got, 'guest arg present';
    ok grep { $_ eq 'refresh' } @got, 'refresh arg present';
};

subtest 'tab completes partial arg name' => sub {
    my @got = $repl->_tab_complete('ho', 'stats ho');
    ok grep { $_ eq 'host' } @got, 'completes "ho" to "host"';
    ok !grep { $_ eq 'guest' } @got, 'does not include "guest"';
};

subtest 'passthrough lines are not tab completed' => sub {
    my @got = $repl->_tab_complete('st', '!st');
    is scalar @got, 0, 'no completions for passthrough input';
};

done_testing();
