#!perl

use strict;
use warnings;
use Test::More tests => 18;
use File::Temp qw(tempdir);

use No::Worries::File qw(*);

our($dir, $path, $str, $len, $tmp, $fh);

$dir = tempdir(CLEANUP => 1);
$path = "$dir/tst";

# empty

$str = "";
$len = length($str);

file_write($path, data => $str);
is(-s $path, $len, "write empty");
$tmp = file_read($path);
is($tmp, $str, "read empty");

# non-empty

$str = "Test with '\x{c3}\x{a9}' char"; # Latin small letter e with acute, UTF-8 encoded
$len = length($str);

file_write($path, data => $str);
is(-s $path, $len, "write plain");
file_write($path, data => $str, binary => "true");
is(-s $path, $len, "write binary");
file_write($path, data => $str, binmode => ":raw");
is(-s $path, $len, "write :raw");

$tmp = file_read($path);
is($tmp, $str, "read plain");
$tmp = file_read($path, binary => "true");
is($tmp, $str, "read binary");
$tmp = file_read($path, binmode => ":raw");
is($tmp, $str, "read :raw");

SKIP : {
    skip(":utf8 handles are deprecated in Perl $^V", 2)
        if $] >= 5.024;
    $tmp = file_read($path, binmode => ":encoding(utf8)");
    is(length($tmp), $len-1, "read utf8");
    file_write($path, data => $tmp, binmode => ":encoding(utf8)");
    is(-s $path, $len, "write utf8");
}

# error

unlink($path) or die;
eval { file_read($path) };
like($@, qr/cannot open/, "no such file");

# by ref

$str = "abc=def\n";
$len = length($str);

file_write($path, data => \$str);
$tmp = file_read($path);
is($tmp, $str, "write by ref + read");
$tmp = "";
file_read($path, data => \$tmp);
is($tmp, $str, "write by ref + read by ref");

$tmp = "with constant too!";
file_write($path, data => \$tmp);
is(-s $path, 18, "write by const ref");

# by sub

$str = "abc=def\n";
$len = length($str);
$tmp = $str;

file_write($path, data => sub {
    my $chunk = substr($tmp, 0, 3);
    substr($tmp, 0, 3) = "";
    return($chunk);
});
$tmp = file_read($path);
is($tmp, $str, "write by sub + read");
$tmp = "";
file_read($path, data => sub {
    $tmp .= $_[0];
});
is($tmp, $str, "write by sub + read by sub");

# handle option

$str = "yet another string...";
unlink($path) or die;

open($fh, ">", $path) or die;
file_write($path . "-", handle => $fh, data => $str);
is(-s $path, length($str), "write by handle");

open($fh, "<", $path) or die;
$tmp = file_read($path . "-", handle => $fh);
is($tmp, $str, "read by handle");
