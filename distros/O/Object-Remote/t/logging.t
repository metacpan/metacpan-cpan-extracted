use strictures 1;
use Test::More;

$ENV{OBJECT_REMOTE_TEST_LOGGER} = 1;

BEGIN {
  use Object::Remote::Logging qw( :log :dlog router arg_levels );
  is($Object::Remote::Logging::DID_INIT, 1, 'using logging class initializes it');
}

my $router = router();
isa_ok($router, 'Object::Remote::Logging::Router');
is($router, router(), 'Router object is a singleton');

my $levels = arg_levels();
is(ref($levels), 'ARRAY', 'arg_levels returns array reference');
is_deeply(
  $levels, [qw( trace debug verbose info warn error fatal )],
  'arg_levels has correct names'
);

#adds some noise into the string that's not significant just to be more thorough
my $selections_string = "Acme::Matt::Daemon \t  *\t\t-Acme::POE::Knee";
my %parsed_selections = Object::Remote::Logging::_parse_selections($selections_string);
my $selections_match = { '*' => 1, 'Acme::Matt::Daemon' => 1, 'Acme::POE::Knee' => 0 };
is_deeply(\%parsed_selections, $selections_match, 'Selections parsed successfully' );

require 't/lib/ORFeedbackLogger.pm';
my $logger = ORFeedbackLogger->new(level_names => $levels, min_level => 'trace');
isa_ok($logger, 'ORFeedbackLogger');
$router->connect($logger);

$logger->reset;
log_info { "The quick brown fox jumped" };
is($logger->feedback_output, "info: The quick brown fox jumped\n", 'log_info works');

$logger->reset;
Dlog_verbose { "over the lazy dog's $_" } 'back';
is($logger->feedback_output, "verbose: over the lazy dog's \"back\"\n", 'Dlog_verbose works');

done_testing;