use strict;
use warnings;

use Test::More tests => 8;
use Test::Exception;
use Plack::Test;
use Plack::Builder;
use Data::Dump qw();
use HTTP::Request::Common qw(GET);
use Scalar::Util qw(refaddr);

my $module = 'Plack::Middleware::Debug::Timed::Logger';
use_ok($module);
new_ok($module);

lives_ok(sub {
           builder {
             enable 'Timed::Logger';
             enable 'Debug', panels => ['Timed::Logger'];
             return sub { [200, ['Content-Type' => 'text/plain'], ['Hello!']] }
           };
         }, 'No errors wrapping the application'
        );

ok(my $app = builder {
  enable 'Timed::Logger';
  enable 'Debug', panels => ['Timed::Logger'];
  return sub {
    my $env = shift;
    my $logger = Plack::Middleware::Timed::Logger->get_logger_from_env($env);
    my $entry = $logger->start('test');
    $logger->finish($entry, {type => "get", path => 'resource str', id => 'id str', response => 'response str'});
    return [200, ['Content-Type' => 'text/html'], ['<html><body></body></html>']];
  }
}, 'Got test application wrapped with middleware');

test_psgi($app, sub {
            my $cb = shift;
            my $content = $cb->(GET '/')->content;
            like($content, qr|<h3>test:</h3>|, 'got type header');
            like($content, qr|<th>Type</th>\s*<th>Service</th>|, 'got table header');
            like($content, qr|<td>get</td>\s*<td>id str</td>\s*<td>resource str</td>\s*<td>\d+\.\d+</td>\s*<td><pre>response str</pre></td>\s*<td><pre>\(undef\)</pre></td>|, 'got log entry');
            like($content, qr|<th\s+colspan="6">Elapsed total:\s*\d+\.\d+\s*s</th>|, 'got total entry');
          });
