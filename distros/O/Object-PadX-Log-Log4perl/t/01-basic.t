use strict;
use warnings;
use IO::Scalar;
use Test::More 0.96;

use Log::Log4perl;

my $cfg = <<OEF;
log4perl.rootLogger = TRACE, Console

log4perl.appender.Console        = Log::Log4perl::Appender::Screen
log4perl.appender.Console.stderr = 1
log4perl.appender.Console.layout = Log::Log4perl::Layout::PatternLayout
log4perl.appender.Console.layout.ConversionPattern = %p [%c] [%M] %m%n
log4perl.oneMessagePerAppender = 1
Log4perl.logger.My.Test.Child = INFO, Console
OEF

Log::Log4perl->init(\$cfg);

my $t = My::Test->new();

ok(!$t->can('debug'), "cannot call debug from Log4perl");
ok(!$t->can('log_debug'), "... nor can it call log_debug from Log4perl");

ok($t->can('log'), "But we can call log");
ok($t->can('logger'), ".. and logger");

tie *STDERR, 'IO::Scalar', \my $err;
local $SIG{__DIE__} = sub { untie *STDERR; die @_ };

$t->called_all();

$err =~ s/\r?\n/\n/gm;

my $expect = <<OEF;
TRACE [My.Test] [My::Test::called_all] trace msg
DEBUG [My.Test] [My::Test::called_all] debug msg
INFO [My.Test] [My::Test::called_all] info msg
WARN [My.Test] [My::Test::called_all] warn msg
ERROR [My.Test] [My::Test::called_all] error msg
FATAL [My.Test] [My::Test::called_all] fatal msg
INFO [SPECIAL] [My::Test::called_all] SPECIAL on info msg
OEF

is($err, $expect, "Got all the correct messages");

$err = undef;

my $t2 = My::Test::Child->new();
$t2->bar();
$t2->foo();
$t2->called_all();

$expect = <<OEF;
INFO [My.Test.Child] [My::Test::bar] bar called in parent
INFO [My.Test.Child] [My::Test::Child::bar] bar called in child
INFO [My.Test.Child] [My::Test::Child::foo] foo called in child
INFO [My.Test.Child] [My::Test::called_all] info msg
WARN [My.Test.Child] [My::Test::called_all] warn msg
ERROR [My.Test.Child] [My::Test::called_all] error msg
FATAL [My.Test.Child] [My::Test::called_all] fatal msg
INFO [SPECIAL] [My::Test::called_all] SPECIAL on info msg
OEF

is($err, $expect, "Inheritance works");

done_testing;

package My::Test;
use v5.26;
use Object::Pad;

class My::Test :does(Object::PadX::Log::Log4perl);

method bar {
    $self->log->info("bar called in parent");
}

method called_all {
    $self->log->trace("trace msg");
    $self->log->debug("debug msg");
    $self->log->info("info msg");
    $self->log->warn("warn msg");
    $self->log->error("error msg");
    $self->log->fatal("fatal msg");
    $self->log("SPECIAL")->info("SPECIAL on info msg");
}

method foo {
    $self->log->info("info msg");
}

package My::Test::Child;
use v5.26;
use Object::Pad;

class My::Test::Child :isa(My::Test);

method bar {
    $self->next::method();
    $self->log->info("bar called in child");
}

method foo {
    $self->log->info("foo called in child");
}
