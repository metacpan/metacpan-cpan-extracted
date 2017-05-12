#!perl

use strict;
use warnings;
use Test::More tests => 13;

use FindBin qw($Bin);
use File::Spec;

my $file = File::Spec->join($Bin, 'util', 'extra');

unlink $file;

open my $null, '<', File::Spec->devnull() or die "Cannot open devnull: $!";

my $in;

ok open($in, '<:creat :excl', $file), "open with :creat and :excl -> success";

is_deeply [$null->get_layers], [$in->get_layers], "has correct layers";

close $in;

ok -e $file, "created";

ok !open($in, '<:creat :excl', $file), "open with :creat and :excl -> fail";

unlink $file;

ok open($in, '<:excl :creat', $file), "open with :excl and :creat -> success";
close $in;

ok -e $file, "created";

ok !open($in, '<:excl :creat', $file), "open with :excl and :creat -> fail";

unlink $file;

{
local $TODO = 'changed in 5.14.0' if $] >= 5.014;
ok open($in, '<:creat :excl :utf8', $file), "open with :utf8, :creat and :excl -> success";
ok -e $file, "created";
like join(' ', $in->get_layers()), qr/utf8/, "to utf8 mode";

ok open($in, '<:creat :flock :utf8', $file), "open with :utf8, :flock and :creat -> success";
like join(' ', $in->get_layers()), qr/utf8/, "to utf8 mode";
close $in;
}

ok unlink($file), "(cleanup)";
