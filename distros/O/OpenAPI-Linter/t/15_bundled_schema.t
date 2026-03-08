#!/usr/bin/env perl

use strict;
use warnings;

use Test::More;
use File::Spec;
use JSON qw(decode_json);
use File::Basename qw(dirname);

my $share_dir = File::Spec->rel2abs(
    File::Spec->catdir( dirname(__FILE__), File::Spec->updir, 'share' )
);

use_ok 'OpenAPI::Linter';

# Bundled files exist and are valid JSON
for my $file (qw( openapi-3.0.json openapi-3.1.json )) {
    my $path = File::Spec->catfile( $share_dir, $file );

    ok -f $path, "share/$file exists";

    my $raw = do {
        local $/;
        open my $fh, '<:encoding(UTF-8)', $path or die "Cannot open $path: $!";
        <$fh>;
    };

    my $parsed = eval { decode_json($raw) };
    ok !$@,                    "share/$file is valid JSON";
    is ref($parsed), 'HASH',   "share/$file is a JSON object";
}

# Linter constructs without hitting the network (schema from share/)
my %base = ( info => { title => 'Test', version => '1.0.0' }, paths => {} );

for my $ver ( '3.1.0', '3.0.3' ) {
    my $spec   = { openapi => $ver, %base };
    my $linter = eval { OpenAPI::Linter->new( spec => $spec ) };

    ok !$@,     "Linter constructs with bundled schema (OpenAPI $ver)";
    ok $linter, "Linter object defined (OpenAPI $ver)";

    my @errs = grep { $_->{level} eq 'ERROR' }
               eval { $linter->validate_schema };
    ok !$@,            "validate_schema does not die (OpenAPI $ver)";
    is @errs, 0,       "No schema ERRORs for minimal valid $ver spec"
        or diag explain \@errs;
}

# MANIFEST includes both schema files (only checked in a git checkout)
SKIP: {
    skip 'Not in a git checkout', 2
        unless -f File::Spec->catfile( File::Spec->updir, 'MANIFEST' );

    my $manifest = do {
        local $/;
        my $p = File::Spec->catfile( File::Spec->updir, 'MANIFEST' );
        open my $fh, '<', $p or die $!;
        <$fh>;
    };

    like $manifest, qr{share/openapi-3\.0\.json}, 'MANIFEST lists openapi-3.0.json';
    like $manifest, qr{share/openapi-3\.1\.json}, 'MANIFEST lists openapi-3.1.json';
}

done_testing;
