#!perl
use strict;
use warnings;
use Test2::V1;
use Test2::Tools::Basic qw(skip_all done_testing);

BEGIN {
	eval {
		require Test::EOL;
		Test::EOL->import;
		1;
	} or skip_all 'Test::EOL is required for author tests';
}

my @files = qw(
    Makefile.PL
    bin/oapi-perl-gen
    cpanfile
    lib/Modern/OpenAPI/Generator.pm
    lib/Modern/OpenAPI/Generator/CLI.pm
    lib/Modern/OpenAPI/Generator/CodeGen/Auth.pm
    lib/Modern/OpenAPI/Generator/CodeGen/Client.pm
    lib/Modern/OpenAPI/Generator/CodeGen/ClientModels.pm
    lib/Modern/OpenAPI/Generator/CodeGen/Docs.pm
    lib/Modern/OpenAPI/Generator/CodeGen/Server.pm
    lib/Modern/OpenAPI/Generator/CodeGen/StubData.pm
    lib/Modern/OpenAPI/Generator/CodeGen/Tests.pm
    lib/Modern/OpenAPI/Generator/Spec.pm
    lib/Modern/OpenAPI/Generator/Writer.pm
    prepare4release.json
    t/01-load.t
    t/02-generate.t
    t/03-cli-flags.t
    t/04-local-test.t
    t/05-models-without-client.t
    t/06-pod.t
    xt/author/pod-coverage.t
    xt/author/pod.t);

eol_unix_ok($_) for @files;

done_testing;
