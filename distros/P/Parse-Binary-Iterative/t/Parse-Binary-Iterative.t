use Test::More tests => 10;
use_ok("Parse::Binary::Iterative");

package Simple;
use base 'Parse::Binary::Iterative';
__PACKAGE__->FORMAT([
    One => "A",
    Two => "V",
    Three => "d",
]);

package IconFile;
use base 'Parse::Binary::Iterative';
__PACKAGE__->FORMAT([
Magic       => 'a2',
Type        => 'v',
Count       => 'v',
Icon        => [],
Data        => 'a*',
]);

package Icon;
use base 'Parse::Binary::Iterative';
__PACKAGE__->FORMAT([
Width       => 'C',
Height      => 'C',
ColorCount  => 'C',
Reserved    => 'C',
Planes      => 'v',
BitCount    => 'v',
ImageSize   => 'V',
ImageOffset => 'v',
]);

package main;
my $test = pack("AVd", 1,20,30.4);
my $simple = Simple->new(\$test);
is($simple->One, 1);
is($simple->Two, 20);
is($simple->Three, 30.4);
open OUT, ">t/testfile" or die $!;

$test = pack("AVd", 1,20,30.4);
print OUT $test; close OUT;
open IN, "t/testfile" or die $!;
my $simple2 = Simple->new(\*IN);
is($simple2->One, 1);
is($simple2->Two, 20);
is($simple2->Three, 30.4);
close IN;
unlink "t/testfile";

# Icons!
open IN, "t/earnest.ico" or die $!;
my $iconfile = IconFile->new(\*IN);
is($iconfile->Count,1, "File has one icon in it");
is($iconfile->Icon->Width,32, "Icon is 32 pixels across");
is($iconfile->Icon->parent,$iconfile, "Parent is set");
