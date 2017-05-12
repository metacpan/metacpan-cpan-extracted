package OpenHMD::Backend::Inline;

use strict;
use warnings;

use Carp;
use Const::Fast;

use Exporter qw(import);

use Inline (
    C       => 'DATA',
    libs    => '-lopenhmd',
);

our $VERSION = '0.001';

const our $OHMD_VENDOR  => 0;
const our $OHMD_PRODUCT => 1;
const our $OHMD_PATH    => 2;

const our $OHMD_S_OK                =>       0;
const our $OHMD_S_UNKNOWN_ERROR     =>      -1;
const our $OHMD_S_INVALID_PARAMETER =>      -2;
const our $OHMD_S_USER_RESERVED     => -16_384;

const our $OHMD_SCREEN_HORIZONTAL_RESOLUTION    =>  0;
const our $OHMD_SCREEN_VERTICAL_RESOLUTION      =>  1;

const our $OHMD_ROTATION_QUAT                   =>  1;
const our $OHMD_LEFT_EYE_GL_MODELVIEW_MATRIX    =>  2;
const our $OHMD_RIGHT_EYE_GL_MODELVIEW_MATRIX   =>  3;
const our $OHMD_LEFT_EYE_GL_PROJECTION_MATRIX   =>  4;
const our $OHMD_RIGHT_EYE_GL_PROJECTION_MATRIX  =>  5;
const our $OHMD_POSITION_VECTOR                 =>  6;
const our $OHMD_SCREEN_HORIZONTAL_SIZE          =>  7;
const our $OHMD_SCREEN_VERTICAL_SIZE            =>  8;
const our $OHMD_LENS_HORIZONTAL_SEPARATION      =>  9;
const our $OHMD_LENS_VERTICAL_POSITION          => 10;
const our $OHMD_LEFT_EYE_FOV                    => 11;
const our $OHMD_LEFT_EYE_ASPECT_RATIO           => 12;
const our $OHMD_RIGHT_EYE_FOV                   => 13;
const our $OHMD_RIGHT_EYE_ASPECT_RATIO          => 14;
const our $OHMD_EYE_IPD                         => 15;
const our $OHMD_PROJECTION_ZFAR                 => 16;
const our $OHMD_PROJECTION_ZNEAR                => 17;
const our $OHMD_DISTORTION_K                    => 18;

our %EXPORT_TAGS = (
    constants => [qw(
        $OHMD_DISTORTION_K
        $OHMD_EYE_IPD
        $OHMD_LEFT_EYE_ASPECT_RATIO
        $OHMD_LEFT_EYE_FOV
        $OHMD_LEFT_EYE_GL_MODELVIEW_MATRIX
        $OHMD_LEFT_EYE_GL_PROJECTION_MATRIX
        $OHMD_LENS_HORIZONTAL_SEPARATION
        $OHMD_LENS_VERTICAL_POSITION
        $OHMD_PATH
        $OHMD_POSITION_VECTOR
        $OHMD_PRODUCT
        $OHMD_PROJECTION_ZFAR
        $OHMD_PROJECTION_ZNEAR
        $OHMD_RIGHT_EYE_ASPECT_RATIO
        $OHMD_RIGHT_EYE_FOV
        $OHMD_RIGHT_EYE_GL_MODELVIEW_MATRIX
        $OHMD_RIGHT_EYE_GL_PROJECTION_MATRIX
        $OHMD_ROTATION_QUAT
        $OHMD_SCREEN_HORIZONTAL_RESOLUTION
        $OHMD_SCREEN_HORIZONTAL_SIZE
        $OHMD_SCREEN_VERTICAL_RESOLUTION
        $OHMD_SCREEN_VERTICAL_SIZE
        $OHMD_S_INVALID_PARAMETER
        $OHMD_S_OK
        $OHMD_S_UNKNOWN_ERROR
        $OHMD_S_USER_RESERVED
        $OHMD_VENDOR
    )],
    functions => [qw(
        ohmd_close_device
        ohmd_ctx_create
        ohmd_ctx_destroy
        ohmd_ctx_get_error
        ohmd_ctx_probe
        ohmd_ctx_update
        ohmd_device_getf
        ohmd_device_geti
        ohmd_device_setf
        ohmd_list_gets
        ohmd_list_open_device
    )],
);

do {
    my %seen;
    push @{ $EXPORT_TAGS{'all'} },
        grep { !$seen{$_}++ }
        map  { @{ $EXPORT_TAGS{$_} } }
            keys %EXPORT_TAGS;
};

Exporter::export_ok_tags('all');

sub ohmd_close_device {
    croak 'Too few arguments'  if scalar @_ < 1;
    croak 'Too many arguments' if scalar @_ > 1;

    return _inline_ohmd_close_device(@_);
}

sub ohmd_ctx_create {
    croak 'Too many arguments' if scalar @_ > 0;

    return _inline_ohmd_ctx_create();
}

sub ohmd_ctx_destroy {
    croak 'Too few arguments'  if scalar @_ < 1;
    croak 'Too many arguments' if scalar @_ > 1;

    _inline_ohmd_ctx_destroy(@_);
}

sub ohmd_ctx_get_error {
    croak 'Too few arguments'  if scalar @_ < 1;
    croak 'Too many arguments' if scalar @_ > 1;

    return _inline_ohmd_ctx_get_error(@_);
}

sub ohmd_ctx_probe {
    croak 'Too few arguments'  if scalar @_ < 1;
    croak 'Too many arguments' if scalar @_ > 1;

    return _inline_ohmd_ctx_probe(@_);
}

sub ohmd_ctx_update {
    croak 'Too few arguments'  if scalar @_ < 1;
    croak 'Too many arguments' if scalar @_ > 1;

    _inline_ohmd_ctx_update(@_);
}

sub ohmd_device_getf {
    croak 'Too few arguments'  if scalar @_ < 3;
    croak 'Too many arguments' if scalar @_ > 3;

    return _inline_ohmd_device_getf(@_);
}

sub ohmd_device_geti {
    croak 'Too few arguments'  if scalar @_ < 3;
    croak 'Too many arguments' if scalar @_ > 3;

    return _inline_ohmd_device_geti(@_);
}

sub ohmd_device_setf {
    croak 'Too few arguments'  if scalar @_ < 3;
    croak 'Too many arguments' if scalar @_ > 3;

    return _inline_ohmd_device_setf(@_);
}

sub ohmd_list_gets {
    croak 'Too few arguments'  if scalar @_ < 3;
    croak 'Too many arguments' if scalar @_ > 3;

    return _inline_ohmd_list_gets(@_);
}

sub ohmd_list_open_device {
    croak 'Too few arguments'  if scalar @_ < 2;
    croak 'Too many arguments' if scalar @_ > 2;

    return _inline_ohmd_list_open_device(@_);
}

1;

__DATA__

__C__

#include <openhmd/openhmd.h>

int _inline_ohmd_close_device(int device) {
    return ohmd_close_device(device);
}

int _inline_ohmd_ctx_create() {
    return ohmd_ctx_create();
}

void _inline_ohmd_ctx_destroy(int ctx) {
    ohmd_ctx_destroy(ctx);
}

char * _inline_ohmd_ctx_get_error(int ctx) {
    return ohmd_ctx_get_error(ctx);
}

int _inline_ohmd_ctx_probe(int ctx) {
    return ohmd_ctx_probe(ctx);
}

void _inline_ohmd_ctx_update(int ctx) {
    ohmd_ctx_update(ctx);
}

int _inline_ohmd_device_getf(int device, int type, char* out) {
    return ohmd_device_getf(device, type, out);
}

int _inline_ohmd_device_geti(int device, int type, char* out) {
    return ohmd_device_geti(device, type, out);
}

int _inline_ohmd_device_setf(int device, int type, char* in) {
    return ohmd_device_setf(device, type, in);
}

char * _inline_ohmd_list_gets(int ctx, int index, int type) {
    return ohmd_list_gets(ctx, index, type);
}

int _inline_ohmd_list_open_device(int ctx, int index) {
    return ohmd_list_open_device(ctx, index);
}
