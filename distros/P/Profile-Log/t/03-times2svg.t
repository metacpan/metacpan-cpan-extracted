#!/usr/bin/perl -w

use strict;
use lib "t";
use Test::More;
BEGIN {
    if (not eval "use XMLCompare qw(file_ok); 1") {
	plan skip_all => "module required for testing did not load ($@)";
    }
    else {
	plan tests => 2;
    }
}
use Set::Object qw(set);
use Scriptalicious;

# hack hack hack
$ENV{PERL5LIB} = "";
my $perl_inc = set(map { s{\n}{}; $_ } `$^X -le 'print foreach \@INC'`);
my $own_inc  = set(@INC);
$ENV{PERL5LIB} = join(":", ($own_inc - $perl_inc)->members);
$ENV{HACK_TIME} = 111275599;

# test batch mode operation
my $output = capture( -in => "t/onetime.log",
		      $^X, "bin/times2svg", "--yo" );
$output .= "\n";

pass("times2svg didn't barf");

$output =~ s{!!perl/hash:}{!perl/}g;

file_ok($output, "t/onetime.yml", "times2svg generated YML");
