#!perl

use strict;
use warnings;
use Test::More;

eval "use File::Spec; use Cwd;";
if ($@){
	plan skip_all => "File::Spec and Cwd required to run tests";
}else{
	plan tests => 25;
}

#use GD qw();

#use lib ('../');
use Parse::WebCounter;

#BEGIN { use_ok('Parse::WebCounter') };

my $pwd = cwd();
my $dir = File::Spec->catdir($pwd, 't');

my $cpa = new Parse::WebCounter(PATTERN => "$dir/id/a");
my $cpad = new Parse::WebCounter(PATTERN => "$dir/id/a", MODE => "DIGITS");
my $cpb = new Parse::WebCounter(PATTERN => "$dir/id/b");

ok(1,"We are up and running");

#check working ones
ok($cpa->readImage(loadImage("$dir/id/a/strip.gif")) eq "1234567890", "a strip->strip");
ok($cpad->readImage(loadImage("$dir/id/a/strip.gif")) eq "1234567890", "a strip->digit");
ok($cpb->readImage(loadImage("$dir/id/b/strip.gif")) eq "1234567890", "b strip->strip");


for (my $number=0; $number <= 9; $number++ ){
	my $file = "$dir/id/a/$number.gif";
	ok($cpa->readImage(loadImage($file)) eq $number, "a$number digit->strip");
}
for (my $number=0; $number <= 9; $number++ ){
	my $file = "$dir/id/a/$number.gif";
	ok($cpad->readImage(loadImage($file)) eq $number, "a$number digit->digit");
}

#now deliberatly break it by using the wrong reference images

ok($cpa->readImage(loadImage("$dir/id/b/strip.gif")) eq "__________", "a-b missmatch strip->strip");

sub loadImage{
	my $filename = shift;
	my $image = GD::Image->new($filename) || return 0;
	return $image;
}


#SKIP: {
#	skip "Need to support relative", 1;
#	ok($ff->get("hello","./d1") eq "testd1", "Overide key relative");
#};
