#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include "ppport.h"

#include <wurfl/wurfl.h>

#include "const-c.inc"

MODULE = Mobile::Libwurfl		PACKAGE = Mobile::Libwurfl

INCLUDE: const-xs.inc

wurfl_error
wurfl_add_patch(hwurfl, patch)
	wurfl_handle	hwurfl
	const char *	patch

wurfl_error
wurfl_add_requested_capability(hwurfl, requested_capability)
	wurfl_handle	hwurfl
	const char *	requested_capability

void
wurfl_clear_error_message(hwurfl)
	wurfl_handle	hwurfl

wurfl_handle
wurfl_create()

void
wurfl_destroy(hwurfl)
	wurfl_handle	hwurfl

void
wurfl_device_capability_enumerator_destroy(hwurfldevicecapabilityenumeratorhandle)
	wurfl_device_capability_enumerator_handle	hwurfldevicecapabilityenumeratorhandle

const char *
wurfl_device_capability_enumerator_get_name(arg0)
	wurfl_device_capability_enumerator_handle	arg0

const char *
wurfl_device_capability_enumerator_get_value(arg0)
	wurfl_device_capability_enumerator_handle	arg0

int
wurfl_device_capability_enumerator_get_value_as_bool(arg0)
	wurfl_device_capability_enumerator_handle	arg0

int
wurfl_device_capability_enumerator_get_value_as_int(arg0)
	wurfl_device_capability_enumerator_handle	arg0

int
wurfl_device_capability_enumerator_is_valid(arg0)
	wurfl_device_capability_enumerator_handle	arg0

void
wurfl_device_capability_enumerator_move_next(arg0)
	wurfl_device_capability_enumerator_handle	arg0

void
wurfl_device_destroy(arg0)
	wurfl_device_handle	arg0

const char *
wurfl_device_get_bucket_matcher_name(hwurfldevice)
	wurfl_device_handle	hwurfldevice

const char *
wurfl_device_get_capability(hwurfldevice, capability)
	wurfl_device_handle	hwurfldevice
	const char *	capability

int
wurfl_device_get_capability_as_bool(hwurfldevice, capability)
	wurfl_device_handle	hwurfldevice
	const char *	capability

int
wurfl_device_get_capability_as_int(hwurfldevice, capability)
	wurfl_device_handle	hwurfldevice
	const char *	capability

wurfl_device_capability_enumerator_handle
wurfl_device_get_capability_enumerator(hwurfldevice)
	wurfl_device_handle	hwurfldevice

const char *
wurfl_device_get_id(hwurfldevice)
	wurfl_device_handle	hwurfldevice

wurfl_match_type
wurfl_device_get_match_type(hwurfldevice)
	wurfl_device_handle	hwurfldevice

const char *
wurfl_device_get_matcher_name(hwurfldevice)
	wurfl_device_handle	hwurfldevice

const char *
wurfl_device_get_normalized_useragent(hwurfldevice)
	wurfl_device_handle	hwurfldevice

const char *
wurfl_device_get_original_useragent(hwurfldevice)
	wurfl_device_handle	hwurfldevice

const char *
wurfl_device_get_root_id(hwurfldevice)
	wurfl_device_handle	hwurfldevice

const char *
wurfl_device_get_useragent(hwurfldevice)
	wurfl_device_handle	hwurfldevice

const char *
wurfl_device_get_virtual_capability(hwurfldevice, capability)
	wurfl_device_handle	hwurfldevice
	const char *	capability

int
wurfl_device_get_virtual_capability_as_bool(hwurfldevice, capability)
	wurfl_device_handle	hwurfldevice
	const char *	capability

int
wurfl_device_get_virtual_capability_as_int(hwurfldevice, capability)
	wurfl_device_handle	hwurfldevice
	const char *	capability

wurfl_device_capability_enumerator_handle
wurfl_device_get_virtual_capability_enumerator(hwurfldevice)
	wurfl_device_handle	hwurfldevice

int
wurfl_device_has_capability(hwurfldevice, capability)
	wurfl_device_handle	hwurfldevice
	const char *	capability

int
wurfl_device_has_virtual_capability(hwurfldevice, capability)
	wurfl_device_handle	hwurfldevice
	const char *	capability

int
wurfl_device_is_actual_device_root(hwurfldevice)
	wurfl_device_handle	hwurfldevice

wurfl_device_handle
wurfl_get_device(hwurfl, deviceid)
	wurfl_handle	hwurfl
	const char *	deviceid

const char *
wurfl_get_error_message(hwurfl)
	wurfl_handle	hwurfl

int
wurfl_has_error_message(hwurfl)
	wurfl_handle	hwurfl

wurfl_error
wurfl_load(hwurfl)
	wurfl_handle	hwurfl

wurfl_device_handle
wurfl_lookup(hwurfl, header_retrieve_callback, header_retrieve_callback_data)
	wurfl_handle	hwurfl
	wurfl_header_retrieve_callback	header_retrieve_callback
	const void *	header_retrieve_callback_data

wurfl_device_handle
wurfl_lookup_useragent(hwurfl, useragent)
	wurfl_handle	hwurfl
	const char *	useragent

wurfl_error
wurfl_set_cache_provider(hwurfl, cache_provider, config)
	wurfl_handle	hwurfl
	wurfl_cache_provider	cache_provider
	const char *	config

wurfl_error
wurfl_set_engine_target(hwurfl, target)
	wurfl_handle	hwurfl
	wurfl_engine_target	target

wurfl_error
wurfl_set_root(hwurfl, root)
	wurfl_handle	hwurfl
	const char *	root
