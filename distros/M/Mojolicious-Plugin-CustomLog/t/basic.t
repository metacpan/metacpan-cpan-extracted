use Mojo::Base -strict;

use lib "../lib";

use Test::More;
use Mojolicious::Lite;
use Test::Mojo;

# enable log in test mode
# you don't need this in app mode
$ENV{MOJO_LOG_LEVEL} = "debug";

plugin 'CustomLog' => {
        "path" => {
            "test"  => "test",
            "check" => "error"
        },
        "helper" => "mylog",
        "alias"  => "Global"
    };

get '/' => sub {
    my $c = shift;
    $c->app->mylog->debug('test', "test log");
    $Global::CLog->error('check', "error log");
    $c->render(text => 'Hello Mojo!');
};

my $t = Test::Mojo->new;
$t->get_ok('/')->status_is(200)->content_is('Hello Mojo!');


my ($second, $minute, $hour, $day, $month, $year, $weekday, $yesterday, $is_dst) = localtime;
my $date = sprintf("%04d%02d%02d", $year + 1900, $month + 1, $day);

my $file = "test_development.log.$date";
open FILE, "<t/$file" or die "Can not open file $file";
my $log = <FILE>;
chomp($log);

ok($log =~ "test log", "check log content");
ok($log =~ "\[debug\]", "check log mode");

`rm t/$file`;


$file = "error_development.log.$date";
open FILE, "<t/$file" or die "Can not open file $file";
$log = <FILE>;
chomp($log);

ok($log =~ "error log", "check log content");
ok($log =~ "\[error\]", "check log mode");

`rm t/$file`;



done_testing();
