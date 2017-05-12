#!/usr/bin/env perl

use strict;
use warnings;

use Test::Exception;
use Test::More;

use OpenHMD::Backend::Inline qw(:all);

my ($CONTEXT, $COUNT, $DEVICE);

subtest 'functions' => sub {
    my @functions = qw(
        ohmd_close_device
        ohmd_ctx_create
        ohmd_ctx_destroy
        ohmd_ctx_get_error
        ohmd_ctx_probe
        ohmd_device_getf
        ohmd_device_geti
        ohmd_device_setf
        ohmd_list_gets
        ohmd_list_open_device
    );
    push @functions, map { '_inline_' . $_ } @functions;

    foreach my $function (@functions) {
        can_ok 'OpenHMD::Backend::Inline', $function;
    }
};

subtest 'ohmd_ctx_create' => sub {
    throws_ok { ohmd_ctx_create(1) } qr/^Too many arguments/,
        'Too many arguments';

    $CONTEXT = ohmd_ctx_create();
    cmp_ok $CONTEXT, '>', 0, 'Valid context handle';
};

subtest 'ohmd_ctx_get_error' => sub {
    throws_ok { ohmd_ctx_get_error() } qr/^Too few arguments/,
        'Too few arguments';
    throws_ok { ohmd_ctx_get_error(1, 1) } qr/^Too many arguments/,
        'Too many arguments';

    my $error = ohmd_ctx_get_error($CONTEXT);
    is $error, '', 'No error';
};

subtest 'ohmd_ctx_probe' => sub {
    throws_ok { ohmd_ctx_probe() } qr/^Too few arguments/,
        'Too few arguments';
    throws_ok { ohmd_ctx_probe(1, 1) } qr/^Too many arguments/,
        'Too many arguments';

    $COUNT = ohmd_ctx_probe($CONTEXT);
    cmp_ok $COUNT, '>=', 0, 'Valid device count';
};

subtest 'ohmd_list_gets' => sub {
    throws_ok { ohmd_list_gets() } qr/^Too few arguments/,
        'Too few arguments';
    throws_ok { ohmd_list_gets(1, 1, 1, 1) } qr/^Too many arguments/,
        'Too many arguments';
};

subtest 'ohmd_list_open_device' => sub {
    throws_ok { ohmd_list_open_device() } qr/^Too few arguments/,
        'Too few arguments';
    throws_ok { ohmd_list_open_device(1, 1, 1) } qr/^Too many arguments/,
        'Too many arguments';

    $DEVICE = ohmd_list_open_device($CONTEXT, 0);
    cmp_ok $DEVICE, '>', 0, 'Valid device handle';
};

subtest 'ohmd_device_getf' => sub {
    throws_ok { ohmd_device_getf() } qr/^Too few arguments/,
        'Too few arguments';
    throws_ok { ohmd_device_getf(1, 1, 1, 1) } qr/^Too many arguments/,
        'Too many arguments';
};

subtest 'ohmd_device_geti' => sub {
    throws_ok { ohmd_device_geti() } qr/^Too few arguments/,
        'Too few arguments';
    throws_ok { ohmd_device_geti(1, 1, 1, 1) } qr/^Too many arguments/,
        'Too many arguments';
};

subtest 'ohmd_device_setf' => sub {
    throws_ok { ohmd_device_setf() } qr/^Too few arguments/,
        'Too few arguments';
    throws_ok { ohmd_device_setf(1, 1, 1, 1) } qr/^Too many arguments/,
        'Too many arguments';
};

subtest 'ohmd_ctx_update' => sub {
    throws_ok { ohmd_ctx_update() } qr/^Too few arguments/,
        'Too few arguments';
    throws_ok { ohmd_ctx_update(1, 1) } qr/^Too many arguments/,
        'Too many arguments';
};

subtest 'ohmd_close_device' => sub {
    throws_ok { ohmd_close_device() } qr/^Too few arguments/,
        'Too few arguments';
    throws_ok { ohmd_close_device(1, 1) } qr/^Too many arguments/,
        'Too many arguments';

    my $status = ohmd_close_device($DEVICE);
    is $status, $OHMD_S_OK, 'Closed device';
};

subtest 'ohmd_ctx_destroy' => sub {
    throws_ok { ohmd_ctx_destroy() } qr/^Too few arguments/,
        'Too few arguments';
    throws_ok { ohmd_ctx_destroy(1, 1) } qr/^Too many arguments/,
        'Too many arguments';

    ohmd_ctx_destroy($CONTEXT);
};

done_testing();
