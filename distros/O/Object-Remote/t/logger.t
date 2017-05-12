use strictures 1;
use Test::More;
use Sys::Hostname;

$ENV{OBJECT_REMOTE_TEST_LOGGER} = 1;

use Object::Remote::Logging qw(:log router arg_levels);
use Object::Remote::Logging::Logger;
require 't/lib/ORFeedbackLogger.pm';

my $level_names = [qw(test1 test2 test3 test4 test5)];
my $logger = Object::Remote::Logging::Logger->new(
  level_names => $level_names, min_level => 'test1'
);

isa_ok($logger, 'Object::Remote::Logging::Logger');
is($logger->max_level, 'test5', 'Logger sets max_level correctly');
is($logger->format, '%l: %s', 'Default format is correct');
foreach(@$level_names) {
  is($logger->_level_active->{$_}, 1, "Level $_ is active");
}

$logger = Object::Remote::Logging::Logger->new(
  level_names => $level_names, min_level => 'test3'
);

foreach(qw(test1 test2)) {
  is($logger->_level_active->{$_}, 0, "Level $_ is inactive");
}

foreach(qw(test3 test4 test5)) {
  is($logger->_level_active->{$_}, 1, "Level $_ is active");
}

is(render_log("%%")->[0], "%\n", "Percent renders correctly");
is(render_log("%n")->[0], "\n", "New line renders correctly");
is(render_log("%p")->[0], "main\n", "Package renders correctly");
ok(defined render_log("%t")->[0], "There was a time value");
is(render_log("%r")->[0], "local\n", "Remote info renders correctly");
is(render_log("%s")->[0], "Test message\n", "Log message renders correctly");
is(render_log("%l")->[0], "info\n", "Log level renders correctly");
is(render_log("%c")->[0], "Object::Remote::Logging\n", "Log controller renders correctly");
is(render_log("%p")->[0], "main\n", "Log generating package renders correctly");
is(render_log("%m")->[0], "render_log\n", "Log generating method renders correctly");
is(render_log("%f")->[0], __FILE__ . "\n", "Log generating filename renders correctly");
my $ret = render_log("%i");
is($ret->[0], $ret->[1] . "\n", "Log generating line number renders correctly");
is(render_log("%h")->[0], hostname() . "\n", "Log generating hostname renders correctly");
is(render_log("%P")->[0], "$$\n", "Log generating process id renders correctly");

done_testing;

sub render_log {
  my ($format)= @_;
  $logger = ORFeedbackLogger->new(
    format => $format, level_names => arg_levels(), min_level => 'info');
  my $selector= sub { $logger };
  router->connect($selector, 1);
  log_info { "Test message" };
  return [$logger->feedback_output, __LINE__ - 1];
}
