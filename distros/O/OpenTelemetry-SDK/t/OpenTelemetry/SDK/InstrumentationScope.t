#!/usr/bin/env perl

use Test2::V0 -target => 'OpenTelemetry::SDK::InstrumentationScope';
use Test2::Tools::OpenTelemetry;

is CLASS->new( name => 'foo' ), object {
    call name      => 'foo';
    call version   => '';
    call to_string => '[foo:]';
}, 'Default version';

is CLASS->new( name => 'foo', version => '0.1' ), object {
    call name      => 'foo';
    call version   => '0.1';
    call to_string => '[foo:0.1]';
}, 'Explicit version';

is CLASS->new( name => 'foo', version => undef ), object {
    call to_string => '[foo:]';
}, 'Explicit undefined version';

subtest 'Undefined name' => sub {
    is messages {
        is CLASS->new( name => undef ), object {
            call name      => '';
            call version   => '';
            call to_string => '[:]';
        }, 'Explicit undefined name';
    } => [
        [
            warning => 'OpenTelemetry',
            'Created an instrumentation scope with an undefined or empty name',
        ],
    ], 'Warned about undefined name';
};

subtest 'Empty name' => sub {
    is messages {
        is CLASS->new( name => '' ), object {
            call to_string => '[:]';
        }, 'Explicit undefined name';
    } => [
        [
            warning => 'OpenTelemetry',
            'Created an instrumentation scope with an undefined or empty name',
        ],
    ], 'Warned about undefined name';

    like messages {
        is CLASS->new( name => '', version => 123 ), object {
            call to_string => '[:]';
        }, 'Dropped version if name is invalid';
    } => [ [] ];
};

like dies { CLASS->new },
    qr/Required parameter 'name' is missing/,
    'Name is required';

done_testing;
