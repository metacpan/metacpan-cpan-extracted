#!perl
use strict;
use warnings;
use Test::More;

plan skip_all => "author tests" unless $ENV{AUTHOR_TESTING};

# Ensure a recent version of Test::Pod::Coverage
plan skip_all => "Test::Pod::Coverage 1.08 required for testing POD coverage"
    unless eval "use Test::Pod::Coverage 1.08; 1";

# Test::Pod::Coverage doesn't require a minimum Pod::Coverage version,
# but older versions don't recognize some common documentation styles
plan skip_all => "Pod::Coverage 0.18 required for testing POD coverage"
    unless eval "use Pod::Coverage 0.18; 1";

all_pod_coverage_ok({
    also_private => [
        qr/^BUILD(?:ARGS)?$/,   # Moose internal methods
        qr/^config_for_\w+$/,   # RackMan::Format::Nagios internal methods
        qw< val >,              # RackMan::Config proxy method
        qw< LOCAL_CONFIG_FILE >,# RackMan::Config constant
        qw< AF_INET6 >,         # RackMan::Device constant
        qr/^DEFAULT_\w+$/,      # common case of default values

        # RackMan::Device::* and RackMan::Format::* constants
        qw< CONFIG_SECTION HW_ROLES SERIAL_SPEED >,

        # RackMan::Device::PDU::APC_RackPDU constants
        qw< CONFIG_FILENAME CONFIG_SECTION DIFF_CONTEXT EMPTY_VALUE
            INTERFACE_NAME PDU_RESTART_OID >,

        # RackMan::Format::* internal methods
        qr/^cacti_\w+$/,
    ],
});
