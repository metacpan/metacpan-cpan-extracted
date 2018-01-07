use strict;
use warnings;

use Test::More;
use Path::Tiny;
use Mojolicious::Command::nopaste::Service::perlbot;

my $obj = Mojolicious::Command::nopaste::Service::perlbot->new();

$obj->text("CPAN Testing 1.0");
$obj->name("Automated");
$obj->language("text");
$obj->desc("Congrats you found a test paste");

ok(defined($obj), "Creates fine");

my $url = $obj->paste();

ok($url =~ /perl\.bot/, "URL contains expected result");

done_testing;
