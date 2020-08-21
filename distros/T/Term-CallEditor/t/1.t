#!perl

use strict;
use warnings;

use Test::More 'no_plan';

BEGIN {
    use_ok('Term::CallEditor') || print "Bail out!\n";
}

diag("Testing Term::CallEditor $Term::CallEditor::VERSION, Perl $], $^X");

# this is exported by default; modern me would not export things
# by default
ok(defined &solicit, 'have solicit function');

# need to blank these out, *and* to set a suitable DEFAULT_EDITOR that
# the version 1.00 code always falls back to
undef $ENV{VISUAL};
undef $ENV{EDITOR};

my $timeout = 5;

# NOTE these assume that the environment provides true(1) and false(1)
# and that those programs do not fail if given a command line arguments
check(
    env    => { EDITOR         => 'false' },
    params => { DEFAULT_EDITOR => 'false', skip_interative => 1 },
    input  => 'x',
    ret    => undef,
    errstr => qr/external editor failed/
);
check(
    env    => { VISUAL         => 'false' },
    params => { DEFAULT_EDITOR => 'false', skip_interative => 1 },
    input  => 'x',
    ret    => undef,
    errstr => qr/external editor failed/
);
check(
    params => { DEFAULT_EDITOR => 'false', skip_interative => 1 },
    input  => 'x',
    ret    => undef,
    errstr => qr/external editor failed/
);
# this should be "could not launch" if "false blah blah" is being looked
# for in PATH
check(
    env    => { VISUAL         => 'false blah blah' },
    params => { DEFAULT_EDITOR => 'false', skip_interative => 1 },
    input  => 'x',
    ret    => undef,
    errstr => qr/external editor failed/
);
my $num = int rand 9999999;
check(
    params => { DEFAULT_EDITOR => "/var/empty/$0-$$-$num", skip_interative => 1 },
    input  => 'x',
    ret    => undef,
    errstr => qr/could not launch program/
);
check(
    params => { DEFAULT_EDITOR => 'true', skip_interative => 1 },
    # in theory true(1) should not edit the file?
    input  => $$,
    ret    => $$,
    errstr => qr/^$/
);
check(
    params =>
      { DEFAULT_EDITOR => 'true', binmode_layer => ':utf8', skip_interative => 1 },
    input    => "\x{8ACB}",
    ret      => "\x{8ACB}",
    errstr   => qr/^$/,
    utf_read => 1,
);

sub check {
    my (%p) = @_;
    my $ret;
    # timeout is in the event a real editor gets called and then wedges,
    # though vim(1) usually needs to be killed off manually :/
    eval {
        local @ENV{ keys %{ $p{env} } } = values %{ $p{env} };
        local $SIG{ALRM} = sub { die("timeout\n") };
        alarm($timeout);
        $ret = solicit($p{input}, $p{params});
        alarm(0);
    };
    die "timeout?? $@" if $@;
    if (defined $ret) {
        binmode $ret, ':utf8' if $p{utf_read};
        $ret = do { local $/; readline $ret };
    }
    # tests relative to the caller so the test failures don't point at
    # lines of this function
    local $Test::Builder::Level = $Test::Builder::Level + 1;
    is($ret, $p{ret});
    like($Term::CallEditor::errstr, $p{errstr}) if exists $p{errstr};
}

diag "for an interactive test, run\n  env PERL5LIB=blib/lib eg/solicit foo\n";
