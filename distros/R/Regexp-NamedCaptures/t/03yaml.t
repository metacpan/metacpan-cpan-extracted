#!perl
use Test::More tests => 1;
BEGIN {
    eval {
	require YAML;
	YAML->import('LoadFile');
    };
}

SKIP: {
    skip "YAML isn't installed", 1
        if not defined &LoadFile;

    my $ok = eval { LoadFile("META.yml") };
    my $err = $@;
    ok( $ok, "Parsed META.yml" );
    diag($err) if $err;
}
