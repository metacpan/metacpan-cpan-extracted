#!perl

use strict;
use warnings;

use Test::More;

eval "use File::Spec; use Cwd;";
if ($@){
	plan skip_all => "File::Spec and Cwd required to run tests";
}else{
	plan tests => 67;
}


#use lib ('../');

use Parse::WebCounter;

#BEGIN { use_ok('Parse::WebCounter') };

my $pwd = cwd();
my $dir = File::Spec->catdir($pwd, 't');

my $cpa = new Parse::WebCounter(PATTERN => "$dir/id/a");
my $cpad = new Parse::WebCounter(PATTERN => "$dir/id/a", MODE => "DIGITS");
my $cpb = new Parse::WebCounter(PATTERN => "$dir/id/b");

my $UNKNOWN = "_";

ok(1,"We are up and running");

my @alist = qw/12 1409 156676 361 363 4664 71 89187/;
my @blist = qw/17595 697 695/;

#check working ones
for my $number (@alist){
	my $file = "$dir/data/a$number.gif";
	ok($cpa->readImage(loadImage($file)) eq $number, "Checking a$number");
}
for my $number (@alist){
	my $file = "$dir/data/a$number.gif";
	ok($cpad->readImage(loadImage($file)) eq $number, "Checking a$number (with digits)");
}
for my $number (@blist){
	my $file = "$dir/data/b$number.gif";
	ok($cpb->readImage(loadImage($file)) eq $number, "Checking b$number");
}
#now deliberatly break it by using the wrong reference images

for my $number (@alist){
	my $file = "$dir/data/a$number.gif";
	ok($cpb->readImage(loadImage($file)) eq killNumber($number), "Checking broken a$number");
}
for my $number (@blist){
	my $file = "$dir/data/b$number.gif";
	ok($cpad->readImage(loadImage($file)) eq killNumber($number), "Checking broken a$number (with digits)");
}
for my $number (@blist){
	my $file = "$dir/data/b$number.gif";
	ok($cpa->readImage(loadImage($file)) eq killNumber($number), "Checking broken b$number");
}

# try breaking with an alternatice UNKNOWNCHAR
$cpa = new Parse::WebCounter(PATTERN => "$dir/id/a", UNKNOWNCHAR => ".");
$cpad = new Parse::WebCounter(PATTERN => "$dir/id/a", MODE => "DIGITS", UNKNOWNCHAR => ".");
$cpb = new Parse::WebCounter(PATTERN => "$dir/id/b", UNKNOWNCHAR => ".");

$UNKNOWN = ".";

for my $number (@alist){
	my $file = "$dir/data/a$number.gif";
	ok($cpb->readImage(loadImage($file)) eq killNumber($number), "Checking altchar broken a$number");
}
for my $number (@blist){
	my $file = "$dir/data/b$number.gif";
	ok($cpad->readImage(loadImage($file)) eq killNumber($number), "Checking altchar broken a$number (with digits)");
}
for my $number (@blist){
	my $file = "$dir/data/b$number.gif";
	ok($cpa->readImage(loadImage($file)) eq killNumber($number), "Checking altchar broken b$number");
}

## checking reversed strip order

$cpa = new Parse::WebCounter(PATTERN => "$dir/id/a", STRIPORDER=>"0987654321");
$cpad = new Parse::WebCounter(PATTERN => "$dir/id/a", MODE => "DIGITS", STRIPORDER=>"0987654321");
$cpb = new Parse::WebCounter(PATTERN => "$dir/id/b", STRIPORDER=>"0987654321");

for my $number (@alist){
	my $file = "$dir/data/a$number.gif";
	ok($cpa->readImage(loadImage($file)) eq reverseNumber($number), "Checking reverse a$number");
}
for my $number (@alist){
	my $file = "$dir/data/a$number.gif";
	ok($cpad->readImage(loadImage($file)) eq $number, "Checking reverse a$number (with digits)");
}
for my $number (@blist){
	my $file = "$dir/data/b$number.gif";
	ok($cpb->readImage(loadImage($file)) eq reverseNumber($number), "Checking reverse b$number");
}


################################################
sub loadImage{
	my $filename = shift;
	my $image = GD::Image->new($filename) || return 0;
	return $image;
}

sub killNumber{
	my $number = shift;
	$number  = $UNKNOWN x ($number =~ tr/0-9//);
	return $number;
}
sub reverseNumber{
	my $number = shift;
	$number =~ tr/1234567890/0987654321/;
	return $number;
}

#SKIP: {
#	skip "Need to support relative", 1;
#	ok($ff->get("hello","./d1") eq "testd1", "Overide key relative");
#};
