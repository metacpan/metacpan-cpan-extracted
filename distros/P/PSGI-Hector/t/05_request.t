use strict;
use warnings;
use Test::More;
plan(tests => 5);
use lib qw(../lib lib);
use PSGI::Hector::Request;

my $env = {
	QUERY_STRING => "multiple[]=a&multiple[]=b&single=c"
};

my $request = PSGI::Hector::Request->new($env);
#1
isa_ok($request, "PSGI::Hector::Request");

my $parameters = $request->getParameters();
#2
isa_ok($parameters, "HASH");

my $multiple = $parameters->{'multiple[]'};
#3
isa_ok($multiple, "ARRAY");

#4
is($multiple->[0], 'a');

my $single = $parameters->{'single'};
#5
is($single, 'c');
