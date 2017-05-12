#  -*- perl -*-

use strict;
use warnings;

use Test::More tests => 2;

use Scriptalicious;

$ENV{PERL5LIB} = join ":", "lib", split ":", ($ENV{PERL5LIB} || "");

SKIP: {
    eval 'use YAML';
    if ( $@ ) {
	skip "YAML not installed",1;
    }
    my $output = capture($^X, "t/dump.pl");
    is($output, "Hello: world", "YAML anydump");
}

$ENV{PERL5LIB} = join ":", "t/missing", split ":", ($ENV{PERL5LIB} || "");
delete $ENV{PERL5OPT};

my $output = capture($^X, "t/dump.pl");
is($output, q{$x = {
       'Hello' => 'world'
     };}, "Data::Dumper anydump");
