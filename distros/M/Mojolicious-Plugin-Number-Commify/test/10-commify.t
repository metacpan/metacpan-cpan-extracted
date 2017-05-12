use Mojo::Base -strict;
use Test::More;

use Mojolicious;
use Mojolicious::Plugin::Number::Commify;

my $app = Mojolicious->new;
$app->secrets(['x']) if $Mojolicious::VERSION > 4.63;
my $plugin = Mojolicious::Plugin::Number::Commify->new;

# English
$plugin->register($app => {});

is $app->commify(0), '0', 'no comma';
is $app->commify(123), '123', 'no comma';
is $app->commify(1234), '1,234', 'first comma';
is $app->commify('50000000000000000000000000000000'),
    '50,000,000,000,000,000,000,000,000,000,000', 'what-if.xkcd.com/96/';

#is $app->commify(1234567.1234567), '1,234,567.1234567',
#    'unfortunately it ignores everything post-point';

# some non-English, but not Indian, etc
$plugin->register($app => {separator => '.'});

is $app->commify(0), '0', 'no separator';
is $app->commify(123), '123', 'no separator';
isnt $app->commify(1234), '1,234', 'no comma';
is $app->commify(1234), '1.234', 'first separator';
is $app->commify(12345), '12.345', '10k';
is $app->commify(123456), '123.456', '100k';
is $app->commify(1234567), '1.234.567', 'second separator';

done_testing();
