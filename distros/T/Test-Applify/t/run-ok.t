## -*- mode: perl; -*-

use strict;
use warnings;

use Test::More;
use Test::Applify 'applify_ok';

#
# simple and successful with no output
#
my $code = applify_ok <<'SIMPLE';
use Applify;
app {
    my $self = shift;
    return 0;
};
SIMPLE

my ($t, $app, $retval, $stdout, $stderr, $exited);

$t = new_ok('Test::Applify', [$code]);
($retval, $stdout, $stderr, $exited) = $t->run_ok();
is $exited, 0, 'successful run';
is $retval, 0, 'return value - shell return good';
is $stdout, '', 'no messages';
is $stderr, '', 'no messages';

#
# calls die with a message
#
$code = applify_ok <<'DIES';
use Applify;
option flag => verbose => 'print messages';
app {
    my ($self, @e) = @_;
    die "dies\n" unless @e;
    return 0;
};
DIES

$t = new_ok('Test::Applify', [$code]);
($retval, $stdout, $stderr, $exited) = $t->run_ok();
is $exited, 0, 'successful run';
is $retval, undef, 'return value undef';
is $stdout, "dies\n", 'dies message';
is $stderr, "dies\n", 'dies message';

#
# argv passing in run_ok
#
($retval, $stdout, $stderr, $exited) = $t->run_ok(qw{-verbose alpha});
is $exited, 0, 'successful run';
is $retval, 0, 'return value undef';
is $stdout, '', 'no dies message';
is $stderr, '', 'no dies message';

#
# stdout only
#
$code = applify_ok <<'MESSAGE';
use feature ':5.10';
use Applify;
app {
    my ($self, @e) = @_;
    say "Hello World.";
    return 0;
};
MESSAGE

$t = new_ok('Test::Applify', [$code]);
($retval, $stdout, $stderr, $exited) = $t->run_ok();
is $exited, 0, 'successful run';
is $retval, 0, 'return value == 0';
is $stdout, "Hello World.\n", 'hi message';
is $stderr, "", 'no messages';

#
# stdout and stderr
#
$code = applify_ok <<'MESSAGES';
use feature ':5.10';
use Applify;
app {
    my ($self, @e) = @_;
    say "Hello World.";
    warn "Goodbye, Cruel World.\n";
    return 0;
};
MESSAGES

$t = new_ok('Test::Applify', [$code]);
($retval, $stdout, $stderr, $exited) = $t->run_ok();
is $exited, 0, 'successful run';
is $retval, 0, 'return value == 0';
is $stdout, "Hello World.\n", 'hi message';
if ($^V lt v5.18.0) {
    # something different on 5.10 -> 5.16.3
    like $stderr, qr/^Goodbye, Cruel World.\n/, 'bye message';
} else {
    is $stderr, "Goodbye, Cruel World.\n", 'bye message';
}
#
# app block return code - goes to shell
#
$code = applify_ok <<'SHELLCODE';
use feature ':5.10';
use Applify;
app {
    my ($self, @e) = @_;
    say "Hello World.";
    warn "Goodbye, Cruel World.\n";
    return 1;
};
SHELLCODE

$t = new_ok('Test::Applify', [$code]);
($retval, $stdout, $stderr, $exited) = $t->run_ok();
is $exited, 0, 'successful run';
is $retval, 1, 'return value == 1';
is $stdout, "Hello World.\n", 'hi message';
if ($^V lt v5.18.0) {
    # something different on 5.10 -> 5.16.3
    like $stderr, qr/^Goodbye, Cruel World.\n/, 'bye message';
} else {
    is $stderr, "Goodbye, Cruel World.\n", 'bye message';
}

#
# effectively a die
#
$code = applify_ok <<'DIVIDE';
use feature ':5.10';
use Applify;

option int => denom => 'a denominator', default => 0;
app {
    my ($self) = @_;
    say "tends to infinity";
    say 1 / $self->denom;
    return 0;
};
DIVIDE

$t = new_ok('Test::Applify', [$code]);
($retval, $stdout, $stderr, $exited) = $t->run_ok();
is $exited, 0, 'unsuccessful run';
is $retval, undef, 'return value undef';
is $stdout, "tends to infinity\n", 'and beyond';
like $stderr, qr/\w+/, 'bye message'; ## Illegal division by zero - subject to i18n

# rescue
$t = new_ok('Test::Applify', [$code]);
$app = $t->app_instance(qw{-denom 1});
($retval, $stdout, $stderr, $exited) = $t->run_instance_ok($app);
is $exited, 0, 'unsuccessful run';
is $retval, 0, 'return value == 0';
is $stdout, "tends to infinity\n1\n", 'and beyond';
is $stderr, '', 'bye message';


#
# actually calls exit
#
$code = applify_ok <<'EXIT';
use feature ':5.10';
use Applify;

sub try_this {
    say "trying this";
    warn "try this - exiting\n";
    exit;
}
app {
    my ($self, @e) = @_;
    $self->try_this();
    return 0;
};
EXIT

$t = new_ok('Test::Applify', [$code]);
($retval, $stdout, $stderr, $exited) = $t->run_ok();
is $retval, 0, 'return value == 0';
is $exited, 1, 'unsuccessful run';
is $stdout, "trying this\n", 'hi message';
if ($^V lt v5.18.0) {
    # something different on 5.10 -> 5.16.3
    like $stderr, qr/^try this - exiting\n/, 'bye message';
} else {
    is $stderr, "try this - exiting\n", 'bye message';
}

#
# argv passing
#
$code = applify_ok <<'ARGV';
use feature ':5.10';
use Applify;
option flag => verbose => 'more messages';
app {
    my ($self, @e) = @_;
    say "extra: @e" if @e;
    say "verbosely: @e" if @e and $self->verbose;
    say "verbose: 1" if $self->verbose;
    return 0;
};
ARGV

$t = new_ok('Test::Applify', [$code]);
($retval, $stdout, $stderr, $exited) = $t->run_ok();
is $retval, 0, 'return value == 0';
is $exited, 0, 'successful run';
is $stdout, '', 'empty stdout';
is $stderr, '', 'empty stderr';

($retval, $stdout, $stderr, $exited) = $t->run_ok(qw{-verbose});
is $retval, 0, 'return value == 0';
is $exited, 0, 'successful run';
is $stdout, <<'STDOUT', 'empty stdout';
verbose: 1
STDOUT
is $stderr, '', 'empty stderr';

($retval, $stdout, $stderr, $exited) = $t->run_ok(qw{-verbose here});
is $retval, 0, 'return value == 0';
is $exited, 0, 'successful run';
is $stdout, <<'STDOUT', 'empty stdout';
extra: here
verbosely: here
verbose: 1
STDOUT
is $stderr, '', 'empty stderr';

($retval, $stdout, $stderr, $exited) = $t->run_ok(qw{here});
is $retval, 0, 'return value == 0';
is $exited, 0, 'successful run';
is $stdout, <<'STDOUT', 'empty stdout';
extra: here
STDOUT
is $stderr, '', 'empty stderr';

$app = $t->app_instance(qw{-verbose});
($retval, $stdout, $stderr, $exited) = $t->run_instance_ok($app);
is $retval, 0, 'return value == 0';
is $exited, 0, 'successful run';
is $stdout, <<'STDOUT', 'empty stdout';
verbose: 1
STDOUT
is $stderr, '', 'empty stderr';

($retval, $stdout, $stderr, $exited) = $t->run_instance_ok($app, 'here');
is $retval, 0, 'return value == 0';
is $exited, 0, 'successful run';
is $stdout, <<'STDOUT', 'empty stdout';
extra: here
verbosely: here
verbose: 1
STDOUT
is $stderr, '', 'empty stderr';

$app = $t->app_instance();
($retval, $stdout, $stderr, $exited) = $t->run_instance_ok($app, qw{here});
is $retval, 0, 'return value == 0';
is $exited, 0, 'successful run';
is $stdout, <<'STDOUT', 'empty stdout';
extra: here
STDOUT
is $stderr, '', 'empty stderr';



done_testing;
