# $Id: 00-version.t 315 2005-05-30 10:38:00Z olaf $

use Test::More;
use File::Spec;
use File::Find;
use ExtUtils::MakeMaker;
use strict;

eval "use Test::Pod 0.95";

my @files;
my $blib = File::Spec->catfile(qw(blib lib));
	
find( sub { push(@files, $File::Find::name) if /\.pm$/}, $blib);

plan tests => scalar @files;

foreach my $file (@files) {
	my $version = ExtUtils::MM->parse_version($file);
	isnt("$file: $version", "$file: undef", "$file has a version");
}



