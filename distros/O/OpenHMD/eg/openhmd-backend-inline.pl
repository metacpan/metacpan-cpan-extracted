#!/usr/bin/env perl

use strict;
use warnings;

use OpenHMD::Backend::Inline qw(:all);

my $context = ohmd_ctx_create() or die 'Failed to create context';

my $count = ohmd_ctx_probe($context);
die sprintf 'Failed to probe devices: %s', ohmd_ctx_get_error($context)
    if $count < 0;
printf "Devices: %i\n\n", $count;

my $print_gets = sub {
    my ($title, $index, $type) = @_;
    my $value = ohmd_list_gets($context, $index, $type);

    printf "    %-8s:   %s\n", $title, $value;
};

foreach my $index (0 .. $count - 1) {
    printf "Device %i\n", $index;
    $print_gets->('Vendor', $index, $OHMD_VENDOR);
    $print_gets->('Product', $index, $OHMD_PRODUCT);
    $print_gets->('Path', $index, $OHMD_PATH);
    print "\n";
}

my $device = ohmd_list_open_device($context, 0);
die sprintf 'Failed to open device: %s', ohmd_ctx_get_error($context)
    if !$device;

my $geti = sub {
    my $type = shift;
    my $buffer = pack 'i';
    my $status = ohmd_device_geti($device, $type, $buffer);
    die 'Failed to get integer: %s', ohmd_ctx_get_error($context)
        if $status != $OHMD_S_OK;
    return unpack 'i', $buffer;
};

my @resolution = (
    $geti->($OHMD_SCREEN_HORIZONTAL_RESOLUTION),
    $geti->($OHMD_SCREEN_VERTICAL_RESOLUTION),
);
printf "%-20s:   %i x %i\n", 'Resolution', @resolution;

my $print_getf = sub {
    my ($title, $size, $type) = @_;
    my $buffer = pack sprintf 'f%i', $size;
    my $status = ohmd_device_getf($device, $type, $buffer);
    die 'Failed to get float: %s', ohmd_ctx_get_error($context)
        if $status != $OHMD_S_OK;

    printf "%-20s:   %s\n", (
        $title,
        join ' ', map { sprintf '% 6f', $_ } unpack 'f*', $buffer,
    );
};

$print_getf->('Horizontal Size',  1, $OHMD_SCREEN_HORIZONTAL_SIZE);
$print_getf->('Vertical Size',    1, $OHMD_SCREEN_VERTICAL_SIZE);
$print_getf->('Lens Separation',  1, $OHMD_LENS_HORIZONTAL_SEPARATION);
$print_getf->('Lens Position',    1, $OHMD_LENS_VERTICAL_POSITION);
$print_getf->('Left Eye FoV',     1, $OHMD_LEFT_EYE_FOV);
$print_getf->('Right Eye FoV',    1, $OHMD_RIGHT_EYE_FOV);
$print_getf->('Left Eye Aspect',  1, $OHMD_LEFT_EYE_ASPECT_RATIO);
$print_getf->('Right Eye Aspect', 1, $OHMD_RIGHT_EYE_ASPECT_RATIO);
$print_getf->('Distortion K',     6, $OHMD_DISTORTION_K);
print "\n";

$print_getf->('Default IPD', 1, $OHMD_EYE_IPD);
my $buffer = pack 'f', 0.55;
my $status = ohmd_device_setf($device, $OHMD_EYE_IPD, $buffer);
die sprintf 'Failed to set value: %s', ohmd_ctx_get_error($context)
    if $status != $OHMD_S_OK;
$print_getf->('Set IPD', 1, $OHMD_EYE_IPD);
print "\n";

foreach my $tick (0 .. 10) {
    ohmd_ctx_update($context);
    $print_getf->('Rotation Quaternion', 4, $OHMD_ROTATION_QUAT);
    select undef, undef, undef, 0.1;
}

$status = ohmd_close_device($device);
die sprintf 'Failed to close device: %s', ohmd_ctx_get_error($context)
    if $status != $OHMD_S_OK;

ohmd_ctx_destroy($context);
