#!/usr/bin/perl

$_=<<'CODE';
use strict;
use Perl::Visualize;
use Image::Magick;

sub printMessage {
  my($number) = @_;
  my($prev) = $number+1;
  $number = $number <  1 ? "No bottles" 
          : $number == 1 ? "1 bottle"
          : "$number bottles";
  $prev = $prev <  1 ? "No bottles" 
          : $prev == 1 ? "1 bottle"
          : "$prev bottles";
  print <<BOTTLES;
$prev of beer on the wall
$prev of beer on the wall
Take one down dash it to the ground
$number of beer on the wall
BOTTLES
}

sub drawWall {
  my($image, $width,$height) = @_;
  for my $y ( 0..3 ) {
    for my $x ( 0..($width/10) ) {
      my $warn = $image->Draw ( primitive=>'Rectangle',
				  points=>"@{[($x - ($y%2)*.5)*10]},
                                         @{[$height - $y*5]} 
                                         @{[($x - ($y%2)*.5)*10 + 10]},
                                         @{[ $height - $y*5 - 5]}",
				  fill=>'red' );
      warn $warn if $warn;
    }
  }
}

sub drawBottle {
  my($image, $x,$y) = @_;
  my $warn = $image->Draw ( primitive=>'Rectangle',
			      points=>"$x,$y 
                                     @{[$x+5]},@{[$y-10]}",
			      fill=>'brown');
  warn $warn if $warn;

  my $warn = $image->Draw ( primitive=>'Polygon',
     			      points=>"@{[$x+2]},@{[$y-13]} 
                                     $x,@{[$y-10]} 
                                     @{[$x+5]},@{[$y-10]} 
                                     @{[$x+3]},@{[$y-13]} 
                                     @{[$x+5]},@{[$y-10]}" );
  warn $warn if $warn;
}

sub drawBottles {
  my($bottles, $image, $width,$height) = @_;
  for my $bottle_number ( 1..$bottles ) {
    my $x = 5+(($width-10)/100) * (($bottle_number * 3) % 100);
    drawBottle $image, $x, $height - 20;
  }
}

my($width,$height) = (600,100);
my $bottles = 99;

my $image = Image::Magick->new(size=>"${width}x$height");

printMessage $bottles;

$image->ReadImage('xc:white');
drawWall($image, $width, $height);
drawBottles($bottles, $image, $width, $height);

my $warn = $image->Write('99.gif');
warn $warn if $warn;
__END__
eval $_; die $@ if $@;
s/^(my \$bottles = )(\d+)/$1.(($2+1)?$2-1:$2)/em;
m/^__END__(.*)/ms;
Perl::Visualize::paint ( '99.gif', '99.gif', "\$_=<<'CODE';\n${_}CODE".$1);
CODE
eval $_; die $@ if $@;
s/^(my \$bottles = )(\d+)/$1.(($2+1)?$2-1:$2)/em;
m/^__END__(.*)/ms;
Perl::Visualize::paint ( '99.gif', '99.gif', "\$_=<<'CODE';\n${_}CODE".$1);
