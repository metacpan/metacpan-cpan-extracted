###
# Copyright (c) 2004 Matthias Hilbig <bighil@cpan.org>
# All rights reserved.
# 
# This program is free software; you may redistribute it and/or modify it
# under the same terms as Perl itself.
#

package Net::IPP::IPP;

use strict;
use warnings;

require Exporter;
our @ISA = ("Exporter");

our @EXPORT_OK;
our %EXPORT_TAGS;

BEGIN {
	
###
# register constants
# (modified standard perl constant.pm without all the checking)
#
sub registerConstants($$) {
	my $tableref = shift;
	my %constants = %{+shift};

    foreach my $name ( keys %constants ) {
        my $pkg = caller;

        no strict 'refs';
        my $full_name = "${pkg}::$name";

        my $scalar = $constants{$name};
        *$full_name = sub () { $scalar };

        $tableref->{$scalar} = $name;
    }
}

# print debug messages
use constant DEBUG => 0;

# constants used in IPP request hash as keys 
# (let no IPP attribute collide with these names)
use constant URL => "__url__";
use constant OPERATION => "__operation__";
use constant STATUS => "__status__";
use constant REQUEST_ID => "__request-id__";
use constant GROUPS => "__groups__";
use constant TYPE => "__type__";
use constant VALUE => "__value__";
use constant DATA => "__data__";
use constant VERSION => "__version__";
use constant HP_BUGFIX => "__hp-bugfix__";
use constant HTTP_CODE => "__http-code__";
use constant HTTP_MESSAGE => "__http-message__";

# IPP Version
use constant IPP_MAJOR_VERSION => 1;
use constant IPP_MINOR_VERSION => 1;

# IPP Types

our %type;
registerConstants(\%type, {
     DELETE_ATTRIBUTE => 0x16, 
     INTEGER => 0x21,
     BOOLEAN => 0x22,
     ENUM => 0x23,
     OCTET_STRING => 0x30,
     DATE_TIME => 0x31,
     RESOLUTION => 0x32,
     RANGE_OF_INTEGER => 0x33,
     BEG_COLLECTION => 0x34,
     TEXT_WITH_LANGUAGE => 0x35,
     NAME_WITH_LANGUAGE => 0x36,
     END_COLLECTION => 0x37,
     TEXT_WITHOUT_LANGUAGE => 0x41,
     NAME_WITHOUT_LANGUAGE => 0x42,
     KEYWORD => 0x44,
     URI => 0x45,
     URI_SCHEME => 0x46,
     CHARSET => 0x47,
     NATURAL_LANGUAGE => 0x48,
     MIME_MEDIA_TYPE => 0x49,
     MEMBER_ATTR_NAME => 0x4A,
});

# IPP Group tags

our %group;
registerConstants(\%group, {
	OPERATION_ATTRIBUTES => 0x01,
	JOB_ATTRIBUTES => 0x02,
	END_OF_ATTRIBUTES => 0x03,
	PRINTER_ATTRIBUTES => 0x04,
	UNSUPPORTED_ATTRIBUTES => 0x05,
	SUBSCRIPTION_ATTRIBUTES => 0x06,
	EVENT_NOTIFICATION_ATTRIBUTES => 0x07
});

# IPP Operations

our %operation;
registerConstants(\%operation, {
    IPP_PRINT_JOB => 0x0002,
    IPP_PRINT_URI => 0x0003,
    IPP_VALIDATE_JOB => 0x0004,
    IPP_CREATE_JOB => 0x0005,
    IPP_SEND_DOCUMENT => 0x0006,
    IPP_SEND_URI => 0x0007,
    IPP_CANCEL_JOB => 0x0008,
    IPP_GET_JOB_ATTRIBUTES => 0x0009,
    IPP_GET_JOBS => 0x000a,
    IPP_GET_PRINTER_ATTRIBUTES => 0x000b,
    IPP_HOLD_JOB => 0x000c,
    IPP_RELEASE_JOB => 0x000d,
    IPP_RESTART_JOB => 0x000e,

    IPP_PAUSE_PRINTER => 0x0010,
    IPP_RESUME_PRINTER => 0x0011,
    IPP_PURGE_JOBS => 0x0012,
    IPP_SET_PRINTER_ATTRIBUTES => 0x0013,
    IPP_SET_JOB_ATTRIBUTES => 0x0014,
    IPP_GET_PRINTER_SUPPORTED_VALUES => 0x0015,
    IPP_CREATE_PRINTER_SUBSCRIPTION => 0x0016,
    IPP_CREATE_JOB_SUBSCRIPTION => 0x0017,
    IPP_GET_SUBSCRIPTION_ATTRIBUTES => 0x0018,
    IPP_GET_SUBSCRIPTIONS => 0x0019,
    IPP_RENEW_SUBSCRIPTION => 0x001a,
    IPP_CANCEL_SUBSCRIPTION => 0x001b,
    IPP_GET_NOTIFICATIONS => 0x001c,
    IPP_SEND_NOTIFICATIONS => 0x001d,

    IPP_GET_PRINT_SUPPORT_FILES => 0x0021,
    IPP_ENABLE_PRINTER => 0x0022,
    IPP_DISABLE_PRINTER => 0x0023,
    IPP_PAUSE_PRINTER_AFTER_CURRENT_JOB => 0x0024,
    IPP_HOLD_NEW_JOBS => 0x0025,
    IPP_RELEASE_HELD_NEW_JOBS => 0x0026,
    IPP_DEACTIVATE_PRINTER => 0x0027,
    IPP_ACTIVATE_PRINTER => 0x0028,
    IPP_RESTART_PRINTER => 0x0029,
    IPP_SHUTDOWN_PRINTER => 0x002a,
    IPP_STARTUP_PRINTER => 0x002b,
    IPP_REPROCESS_JOB => 0x002c,
    IPP_CANCEL_CURRENT_JOB => 0x002d,
    IPP_SUSPEND_CURRENT_JOB => 0x002e,
    IPP_RESUME_JOB => 0x002f,
    IPP_PROMOTE_JOB => 0x0030,
    IPP_SCHEDULE_JOB_AFTER => 0x0031,

    # IPP private Operations start at 0x4000
    CUPS_GET_DEFAULT => 0x4001,
    CUPS_GET_PRINTERS => 0x4002,
    CUPS_ADD_PRINTER => 0x4003,
    CUPS_DELETE_PRINTER => 0x4004,
    CUPS_GET_CLASSES => 0x4005,
    CUPS_ADD_CLASS => 0x4006,
    CUPS_DELETE_CLASS => 0x4007,
    CUPS_ACCEPT_JOBS => 0x4008,
    CUPS_REJECT_JOBS => 0x4009,
    CUPS_SET_DEFAULT => 0x400a,
    CUPS_GET_DEVICES => 0x400b,
    CUPS_GET_PPDS => 0x400c,
    CUPS_MOVE_JOB => 0x400d,
    CUPS_ADD_DEVICE => 0x400e,
    CUPS_DELETE_DEVICE => 0x400f,
});

# Finishings

our %finishing;
registerConstants(\%finishing, {
  FINISHINGS_NONE => 3,
  FINISHINGS_STAPLE => 4,
  FINISHINGS_PUNCH => 5,
  FINISHINGS_COVER => 6,
  FINISHINGS_BIND => 7,
  FINISHINGS_SADDLE_STITCH => 8,
  FINISHINGS_EDGE_STITCH => 9,
  FINISHINGS_FOLD => 10,
  FINISHINGS_TRIM => 11,
  FINISHINGS_BALE => 12,
  FINISHINGS_BOOKLET_MAKER => 13,
  FINISHINGS_JOB_OFFSET => 14,
  FINISHINGS_STAPLE_TOP_LEFT => 20,
  FINISHINGS_STAPLE_BOTTOM_LEFT => 21,
  FINISHINGS_STAPLE_TOP_RIGHT => 22,
  FINISHINGS_STAPLE_BOTTOM_RIGHT => 23,
  FINISHINGS_EDGE_STITCH_LEFT => 24,
  FINISHINGS_EDGE_STITCH_TOP => 25,
  FINISHINGS_EDGE_STITCH_RIGHT => 26,
  FINISHINGS_EDGE_STITCH_BOTTOM => 27,
  FINISHINGS_STAPLE_DUAL_LEFT => 28,
  FINISHINGS_STAPLE_DUAL_TOP => 29,
  FINISHINGS_STAPLE_DUAL_RIGHT => 30,
  FINISHINGS_STAPLE_DUAL_BOTTOM => 31,
  FINISHINGS_BIND_LEFT => 50,
  FINISHINGS_BIND_TOP => 51,
  FINISHINGS_BIND_RIGHT => 52,
  FINISHINGS_BIND_BOTTOM => 53,
});

# IPP Printer state

our %printerState;
registerConstants(\%printerState, {
    STATE_IDLE=>3,
    STATE_PROCESSING => 4,
    STATE_STOPPED => 5,
});

# Job state

our %jobState;
registerConstants(\%jobState, {
    JOBSTATE_PENDING => 3,
    JOBSTATE_PENDING_HELD => 4,
    JOBSTATE_PROCESSING => 5,
    JOBSTATE_PROCESSING_STOPPED => 6,
    JOBSTATE_CANCELED => 7,
    JOBSTATE_ABORTED => 8,
    JOBSTATE_COMPLETED => 9,
});

# Orientations

our %orientation;
registerConstants(\%orientation, {
	ORIENTATION_PORTRAIT => 3,          # no rotation
	ORIENTATION_LANDSCAPE => 4,         # 90 degrees counter-clockwise
	ORIENTATION_REVERSE_LANDSCAPE => 5, # 90 degrees clockwise
	ORIENTATION_REVERSE_PORTRAIT => 6,  # 180 degrees
});

our %statusCodes = (
                 0x0000 => "successful-ok",
                 0x0001 => "successful-ok-ignored-or-substituted-attributes",
                 0x0002 => "successful-ok-conflicting-attributes",
                 0x0003 => "successful-ok-ignored-subscriptions",
                 0x0004 => "successful-ok-ignored-notifications",
                 0x0005 => "successful-ok-too-many-events",
                 0x0006 => "successful-ok-but-cancel-subscription",
		    # Client errors
                 0x0400 => "client-error-bad-request",
                 0x0401 => "client-error-forbidden",
                 0x0402 => "client-error-not-authenticated",
                 0x0403 => "client-error-not-authorized",
                 0x0404 => "client-error-not-possible",
                 0x0405 => "client-error-timeout",
                 0x0406 => "client-error-not-found",
                 0x0407 => "client-error-gone",
                 0x0408 => "client-error-request-entity-too-large",
                 0x0409 => "client-error-request-value-too-long",
                 0x040a => "client-error-document-format-not-supported",
                 0x040b => "client-error-attributes-or-values-not-supported",
                 0x040c => "client-error-uri-scheme-not-supported",
                 0x040d => "client-error-charset-not-supported",
                 0x040e => "client-error-conflicting-attributes",
                 0x040f => "client-error-compression-not-supported",
                 0x0410 => "client-error-compression-error",
                 0x0411 => "client-error-document-format-error",
                 0x0412 => "client-error-document-access-error",
                 0x0413 => "client-error-attributes-not-settable",
                 0x0414 => "client-error-ignored-all-subscriptions",
                 0x0415 => "client-error-too-many-subscriptions",
                 0x0416 => "client-error-ignored-all-notifications",
                 0x0417 => "client-error-print-support-file-not-found",
		    #Server errors
                 0x0500 => "server-error-internal-error",
                 0x0501 => "server-error-operation-not-supported",
                 0x0502 => "server-error-service-unavailable",
                 0x0503 => "server-error-version-not-supported",
                 0x0504 => "server-error-device-error",
                 0x0505 => "server-error-temporary-error",
                 0x0506 => "server-error-not-accepting-jobs",
                 0x0507 => "server-error-busy",
                 0x0508 => "server-error-job-canceled",
                 0x0509 => "server-error-multiple-document-jobs-not-supported",
                 0x050a => "server-error-printer-is-deactivated"
);

#
# All constants are subroutines, so 
# export all subroutines, except "registerConstants"
#
foreach my $keyname (keys %{Net::IPP::IPP::}) {
  if ($keyname ne "registerConstants") {
    local *key = ${Net::IPP::IPP::}{$keyname};
    push (@EXPORT_OK, $keyname) if *key{CODE};
  }
}

%EXPORT_TAGS = ( 'all' => \@EXPORT_OK );
}

1;
__END__

=head1 NAME

Net::IPP::IPP - IPP Constants

=cut
