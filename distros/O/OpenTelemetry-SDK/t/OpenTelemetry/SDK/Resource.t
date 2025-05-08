#!/usr/bin/env perl

use Test2::V0 -target => 'OpenTelemetry::SDK::Resource';
use Test2::Tools::OpenTelemetry;
use B 'perlstring';

require OpenTelemetry::SDK;

local %ENV;

my %default = (
    'service.name'            => DNE,
    'telemetry.sdk.name'      => 'opentelemetry',
    'telemetry.sdk.language'  => 'perl',
    'telemetry.sdk.version'   => $OpenTelemetry::SDK::VERSION,
    'process.pid'             => $$,
    'process.command'         => $0,
    'process.executable.path' => $^X,
    'process.command_args'    => T,
    'process.executable.name' => T,
    'process.runtime.name'    => 'perl',
    'process.runtime.version' => "$^V",
);

subtest New => sub {
    is CLASS->new( schema_url => 'foo', attributes => { key => 'value' } ), object {
        call schema_url => 'foo';
        call attributes => { key => 'value', %default };
    }, 'Arguments to constructor';

    subtest 'Empty environment' => sub {
        is CLASS->new, object {
            call schema_url => '';
            call attributes => \%default;
        }, 'Only default attributes';
    };

    subtest 'From environment' => sub {
        local %ENV = (
            OTEL_RESOURCE_ATTRIBUTES => 'key1=value1,key2=value2,service.name=ignored',
            OTEL_SERVICE_NAME        => 'some_service',
        );

        is CLASS->new, object {
            call schema_url => '';
            call attributes => {
                %default,
                'key1'         => 'value1',
                'key2'         => 'value2',
                'service.name' => 'some_service',
            };
        }, 'Attributes from environment';

        is CLASS->new( attributes => { 'service.name' => 'top-dog' } ), object {
            call attributes => hash {
                field 'service.name' => 'top-dog';
                etc;
            };
        }, 'Constructor service name takes precedence';
    };

    subtest 'Invalid data' => sub {
        for ("\t", "\n", "\r", ';', '"', '\\' ) {
            local %ENV = ( OTEL_RESOURCE_ATTRIBUTES => "key=$_" );
            is messages {
                is CLASS->new->attributes->{key}, U, 'Ignored';
            } => [
                [ warning => OpenTelemetry => match qr/must be percent-encoded/ ],
            ] => 'Ignored unescaped ' . perlstring($_);;
        }
    };

    subtest 'Empty resource' => sub {
        is CLASS->empty, object {
            call attributes => {};
            call schema_url => '';
        } => 'Can create empty resource';

        is CLASS->empty( schema_url => 'foo' ), object {
            call attributes => {};
            call schema_url => 'foo';
        } => 'Can set schema_url in empty resource';

        is CLASS->empty( attributes => { foo => 1 } ), object {
            call attributes => { foo => 1 };
            call schema_url => '';
        } => 'Can set attributes in empty resource';
    };
};

subtest 'Attributes are not mutable' => sub {
    my $new = CLASS->new( attributes => { ref => [ 1 ] } );
    my $data = $new->attributes;
    push @{ $data->{ref} }, 'test';

    is $new, object {
        call attributes => { %default, ref => [ 1 ] };
    }, 'Did not change';
};

subtest 'Merge' => sub {
    my $foo = CLASS->new( schema_url => 'foo', attributes => { a => 1, b => 1 } );
    my $bar = CLASS->new( schema_url => 'bar', attributes => { b => 2, c => 2 } );
    my $non = CLASS->new;

    is messages {
        is $foo->merge($bar), object {
            call schema_url => 'foo';
            call attributes => { %default, a => 1, b => 2, c => 2 };
        }, 'Prefer new but keep schema URL when mismatched';
    } => [
        [ warning => OpenTelemetry => match qr/Incompatible.*Ignoring new one/ ],
    ] => 'Logged mismatched schema URL';

    is messages {
        is $bar->merge($foo), object {
            call schema_url => 'bar';
            call attributes => { %default, a => 1, b => 1, c => 2 };
        }, 'Confirm preference';
    } => [
        [ warning => OpenTelemetry => match qr/Incompatible.*Ignoring new one/ ],
    ] => 'Logged mismatched schema URL';

    no_messages {
        is $non->merge($foo), object {
            call schema_url => 'foo';
            call attributes => { %default, a => 1, b => 1 };
        }, 'No schema URL is updated';
    };

    no_messages {
        is $foo->merge($non), object {
            call schema_url => 'foo';
            call attributes => { %default, a => 1, b => 1 };
        }, 'Existing schema URL stays if new is unset';
    };
};

done_testing;
