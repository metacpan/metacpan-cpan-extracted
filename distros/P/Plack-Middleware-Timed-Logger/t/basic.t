use strict;
use warnings;

use Test::More tests => 15;
use Test::Exception;
use Test::Easy;
use Plack::Test;
use Plack::Builder;
use Data::Dump qw();
use HTTP::Request::Common qw(GET);
use Scalar::Util qw(refaddr);

my $module = 'Plack::Middleware::Timed::Logger';
use_ok($module);
new_ok($module);

lives_ok(sub {
           builder {
             enable 'Timed::Logger';
             return sub { [200, ['Content-Type' => 'text/plain'], ['Hello!']] }
           };
         }, 'No errors wrapping the application'
        );

is(Plack::Middleware::Timed::Logger::PSGI_KEY(), 'plack.middleware.timed.logger',
   'Got the expected PSGI_KEY constant');

ok(my $app = $module->wrap(
  sub {
    my $env = shift;
    my $log = $env->{Plack::Middleware::Timed::Logger::PSGI_KEY()};
    my %tests = (
      key_exists => ($log ? 1 : 0),
      refaddr => refaddr($log),
      isa => ref($log),
     );

    return [200, [], [Data::Dump::dump(%tests)]];
  }), 'Got test application wrapped with middleware');

test_psgi($app, sub {
            my $cb = shift;
            my $last_refaddr;
            foreach my $pass (0..1) {
              my %data = eval($cb->(GET '/')->content);
              ok($data{key_exists}, "got PSGI_KEY (pass: $pass)");
              is($data{isa}, 'Timed::Logger', "Correct default querylog instance (pass: $pass)");
              ok($data{key_exists}, "got refaddr (pass: $pass)");
              if($last_refaddr) {
                isnt($last_refaddr, $data{refaddr}, "Verify we get a new querylog each time (pass: $pass)");
              } else {
                $last_refaddr = $data{refaddr};
              }
            }
          });

{
  my $env = {};
  my $logger = Plack::Middleware::Timed::Logger->get_logger_from_env($env);
  isa_ok($logger, 'Timed::Logger');
  deep_ok($env, { Plack::Middleware::Timed::Logger::PSGI_KEY() => $logger }, 'got environment updated');

  my $logger_again = Plack::Middleware::Timed::Logger->get_logger_from_env($env);
  is($logger_again, $logger, 'got same logger');
}
