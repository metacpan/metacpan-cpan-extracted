#!perl -wT
use strict;
use warnings;
use Test::More;


plan tests => 6;

use_ok("RackMan::Config");


my $path = "t/files/mock.conf";

open my $fh, ">", $path or die "error: can't write '$path': $!\n";
print {$fh} "[general]\n",
            "answer = 42\n",
            "path = /unspeakable/gods/%name%\n";
close $fh;

my $config = eval { RackMan::Config->new(-file => $path) };
is $@, "", "RackMan::Config->new(-file => '$path')";
isa_ok $config, "RackMan::Config", 'check that $config';

is $config->val(general => "answer"), 42,
    '$config->val(general => "answer") == 42';

is $config->val(general => "path"), "/unspeakable/gods/unknown",
    '$config->val(general => "path") = "/unspeakable/gods/unknown"';

# pass in a mock RackMan::Device object
{
    package RackMan::Device;
    $INC{"RackMan/Device.pm"} = 1;
    sub new { bless {} }
    sub object_name { "Hastur" }
}
$config->set_current_rackobject(RackMan::Device->new);

is $config->val(general => "path"), "/unspeakable/gods/Hastur",
    '$config->val(general => "path") = "/unspeakable/gods/Hastur"';

unlink $path;
