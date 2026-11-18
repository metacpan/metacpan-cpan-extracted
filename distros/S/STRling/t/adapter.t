use 5.010;
use strict;
use warnings;
use utf8;
use File::Spec;
use FindBin qw($Bin);
use Test::More;
use lib 'lib';

use STRling qw(load_native source_compile_request simply_builder_request date_time email ip url uuid);
use STRling::StrictJSON ();

my $request = source_compile_request('literal "hello"');
is($request->{contract_version}, '1.0.0', 'canonical request contract');
is($request->{input}{document}{frontend}{id}, 'strling.semantic', 'canonical frontend');
is($request->{input}{document}{frontend}{dialect_version}, '1.0.0', 'independent frontend dialect');
is($request->{input}{document}{content}{media_type}, 'text/x-strling-semantic', 'semantic media type');
is(email('root')->{arguments}{helper_id}, 'stdlib.email', 'lexical helper identity');
ok(exists(uuid('root')->{arguments}{parameters}{version}), 'optional parameter remains explicit');

my $essential_path = File::Spec->catfile(
    $Bin, '..', '..', '..', 'spec', 'stdlib', 'essential_5.json'
);
open my $essential_file, '<', $essential_path
    or die "cannot read $essential_path: $!";
local $/;
my $essential_fixture = STRling::StrictJSON::decode_object(<$essential_file>);
close $essential_file;
my %essential_steps = (
    dateTime => date_time('date-time'),
    email => email('email'),
    ip => ip('ip'),
    url => url('url'),
    uuid => uuid('uuid'),
);
is_deeply(
    [sort keys %essential_steps],
    [sort keys %{$essential_fixture->{patterns}}],
    'stdlib helpers consume the canonical Essential fixture',
);
for my $name (sort keys %essential_steps) {
    my $helper_id = $name eq 'dateTime' ? 'date_time' : $name;
    is(
        $essential_steps{$name}{arguments}{helper_id},
        "stdlib.$helper_id",
        "$name preserves canonical helper identity",
    );
}

my $decoded = STRling::StrictJSON::decode_object('{"a":1,"b":[true,null]}');
is($decoded->{a}, 1, 'strict JSON decodes');
eval { STRling::StrictJSON::decode_object('{"a":1,"a":2}') };
like($@, qr/duplicate property/, 'duplicate property rejected');

my $decoder = bless {}, 'STRling::NativeClient';
eval {
    $decoder->_decode_response(
        '{"interop_protocol_version":"1.0.0","status":"error","error":{"code":7,"path":"$"}}'
    );
};
isa_ok($@, 'STRling::NativeAdapterError', 'numeric protocol error code fails closed');

eval { load_native('libstrling_interop.so') };
isa_ok($@, 'STRling::NativeAdapterError', 'relative path fails closed');

if (my $path = $ENV{STRLING_DYNAMIC_PROBE}) {
    my $client = load_native($path);
    my $expected = { unicode => '雪' };
    my $results = {
        describe => $client->describe(),
        compile => $client->compile(source_compile_request('literal "雪"')),
        'target_profile.inspect' => $client->inspect_target_profile({ contract_version => '1.0.0' }),
        'simply.compile' => $client->simply_compile(simply_builder_request([email('root')], 'root')),
    };
    is_deeply($results->{describe}, $expected, 'describe preserves canonical Unicode result');
    is_deeply($results->{compile}, $expected, 'compile preserves canonical Unicode result');
    is_deeply($results->{'target_profile.inspect'}, $expected, 'profile result preserved');
    is_deeply($results->{'simply.compile'}, $expected, 'Simply result preserved');
    if (my $evidence_dir = $ENV{STRLING_DYNAMIC_EVIDENCE_DIR}) {
        my $evidence_path = File::Spec->catfile($evidence_dir, 'perl.json');
        open my $evidence_file, '>:raw', $evidence_path
            or die "cannot write $evidence_path: $!";
        print {$evidence_file} STRling::StrictJSON::encode($results);
        close $evidence_file or die "cannot close $evidence_path: $!";
    }
    $client->close();
    ok($client->is_closed(), 'client closes');
    $client->close();
    eval { $client->describe() };
    isa_ok($@, 'STRling::NativeAdapterError', 'closed client fails');
} else {
    pass('certification probe unavailable');
}

for my $name (qw(STRLING_DYNAMIC_ABI_PROBE STRLING_DYNAMIC_OVERSIZE_PROBE STRLING_DYNAMIC_DUPLICATE_PROBE STRLING_DYNAMIC_INVALID_UTF8_PROBE STRLING_DYNAMIC_RELEASE_FAILURE_PROBE)) {
    next unless my $path = $ENV{$name};
    eval { load_native($path)->describe() };
    isa_ok($@, 'STRling::NativeAdapterError', "$name fails closed");
}

done_testing();
