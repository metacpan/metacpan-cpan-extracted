use utf8;

package Net::EGTS::Codes;
use namespace::autoclean;
use Mouse;
extends qw(Exporter);

=head1 NAME

Net::EGTS::Codes - Constants.

=cut

our @EXPORT;

# Packet types
use constant EGTS_PT_RESPONSE               => 0;
use constant EGTS_PT_APPDATA                => 1;
use constant EGTS_PT_SIGNED_APPDATA         => 2;
push @EXPORT, qw(
    EGTS_PT_RESPONSE
    EGTS_PT_APPDATA
    EGTS_PT_SIGNED_APPDATA
);

# Result codes
use constant EGTS_PC_OK                     => 0;
use constant EGTS_PC_IN_PROGRESS            => 1;
use constant EGTS_PC_UNS_PROTOCOL           => 128;
use constant EGTS_PC_DECRYPT_ERROR          => 129;
use constant EGTS_PC_PROC_DENIED            => 130;
use constant EGTS_PC_INC_HEADERFORM         => 131;
use constant EGTS_PC_INC_DATAFORM           => 132;
use constant EGTS_PC_UNS_TYPE               => 133;
use constant EGTS_PC_NOTEN_PARAMS           => 134;
use constant EGTS_PC_DBL_PROC               => 135;
use constant EGTS_PC_PROC_SRC_DENIED        => 136;
use constant EGTS_PC_HEADERCRC_ERROR        => 137;
use constant EGTS_PC_DATACRC_ERROR          => 138;
use constant EGTS_PC_INVDATALEN             => 139;
use constant EGTS_PC_ROUTE_NFOUND           => 140;
use constant EGTS_PC_ROUTE_CLOSED           => 141;
use constant EGTS_PC_ROUTE_DENIED           => 142;
use constant EGTS_PC_INVADDR                => 143;
use constant EGTS_PC_TTLEXPIRED             => 144;
use constant EGTS_PC_NO_ACK                 => 145;
use constant EGTS_PC_OBJ_NFOUND             => 146;
use constant EGTS_PC_EVNT_NFOUND            => 147;
use constant EGTS_PC_SRVC_NFOUND            => 148;
use constant EGTS_PC_SRVC_DENIED            => 149;
use constant EGTS_PC_SRVC_UNKN              => 150;
use constant EGTS_PC_AUTH_DENIED            => 151;
use constant EGTS_PC_ALREADY_EXISTS         => 152;
use constant EGTS_PC_ID_NFOUND              => 153;
use constant EGTS_PC_INC_DATETIME           => 154;
use constant EGTS_PC_IO_ERROR               => 155;
use constant EGTS_PC_NO_RES_AVAIL           => 156;
use constant EGTS_PC_MODULE_FAULT           => 157;
use constant EGTS_PC_MODULE_PWR_FLT         => 158;
use constant EGTS_PC_MODULE_PROC_FLT        => 159;
use constant EGTS_PC_MODULE_SW_FLT          => 160;
use constant EGTS_PC_MODULE_FW_FLT          => 161;
use constant EGTS_PC_MODULE_IO_FLT          => 162;
use constant EGTS_PC_MODULE_MEM_FLT         => 163;
use constant EGTS_PC_TEST_FAILED            => 164;
push @EXPORT, qw(
    EGTS_PC_OK
    EGTS_PC_IN_PROGRESS
    EGTS_PC_UNS_PROTOCOL
    EGTS_PC_DECRYPT_ERROR
    EGTS_PC_PROC_DENIED
    EGTS_PC_INC_HEADERFORM
    EGTS_PC_INC_DATAFORM
    EGTS_PC_UNS_TYPE
    EGTS_PC_NOTEN_PARAMS
    EGTS_PC_DBL_PROC
    EGTS_PC_PROC_SRC_DENIED
    EGTS_PC_HEADERCRC_ERROR
    EGTS_PC_DATACRC_ERROR
    EGTS_PC_INVDATALEN
    EGTS_PC_ROUTE_NFOUND
    EGTS_PC_ROUTE_CLOSED
    EGTS_PC_ROUTE_DENIED
    EGTS_PC_INVADDR
    EGTS_PC_TTLEXPIRED
    EGTS_PC_NO_ACK
    EGTS_PC_OBJ_NFOUND
    EGTS_PC_EVNT_NFOUND
    EGTS_PC_SRVC_NFOUND
    EGTS_PC_SRVC_DENIED
    EGTS_PC_SRVC_UNKN
    EGTS_PC_AUTH_DENIED
    EGTS_PC_ALREADY_EXISTS
    EGTS_PC_ID_NFOUND
    EGTS_PC_INC_DATETIME
    EGTS_PC_IO_ERROR
    EGTS_PC_NO_RES_AVAIL
    EGTS_PC_MODULE_FAULT
    EGTS_PC_MODULE_PWR_FLT
    EGTS_PC_MODULE_PROC_FLT
    EGTS_PC_MODULE_SW_FLT
    EGTS_PC_MODULE_FW_FLT
    EGTS_PC_MODULE_IO_FLT
    EGTS_PC_MODULE_MEM_FLT
    EGTS_PC_TEST_FAILED
);

# Service type
use constant EGTS_AUTH_SERVICE              => 1;
use constant EGTS_TELEDATA_SERVICE          => 2;
use constant EGTS_COMMANDS_SERVICE          => 3;
use constant EGTS_FIRMWARE_SERVICE          => 4;
# .. 63 reserved
use constant EGTS_USER_SERVICE              => 64;
push @EXPORT, qw(
    EGTS_AUTH_SERVICE
    EGTS_TELEDATA_SERVICE
    EGTS_COMMANDS_SERVICE
    EGTS_FIRMWARE_SERVICE

    EGTS_USER_SERVICE
);

# Service state
use constant EGTS_SST_IN_SERVICE            => 0;
use constant EGTS_SST_OUT_OF_SERVICE        => 128;
use constant EGTS_SST_DENIDED               => 129;
use constant EGTS_SST_NO_CONF               => 130;
use constant EGTS_SST_TEMP_UNAVAIL          => 131;
push @EXPORT, qw(
    EGTS_SST_IN_SERVICE
    EGTS_SST_OUT_OF_SERVICE
    EGTS_SST_DENIDED
    EGTS_SST_NO_CONF
    EGTS_SST_TEMP_UNAVAIL
);

# Source Data codes (custom names)
use constant EGTS_SRCD_TIMER                => 0;
use constant EGTS_SRCD_DISTANCE             => 1;
use constant EGTS_SRCD_ANGLE                => 2;
use constant EGTS_SRCD_RESPONSE             => 3;
#...
use constant EGTS_SRCD_EXTERNAL             => 16;
#...
use constant EGTS_SRCD_CHANGE_MODE          => 35;
push @EXPORT, qw(
    EGTS_SRCD_TIMER
    EGTS_SRCD_DISTANCE
    EGTS_SRCD_ANGLE
    EGTS_SRCD_RESPONSE

    EGTS_SRCD_EXTERNAL

    EGTS_SRCD_CHANGE_MODE
);

# Subrecord types common
use constant EGTS_SR_RECORD_RESPONSE        => 0;
# Subrecord types for EGTS_AUTH_SERVICE
use constant EGTS_SR_TERM_IDENTITY          => 1;
use constant EGTS_SR_MODULE_DATA            => 2;
use constant EGTS_SR_VEHICLE_DATA           => 3;
use constant EGTS_SR_DISPATCHER_IDENTITY    => 5;
use constant EGTS_SR_AUTH_PARAMS            => 6;
use constant EGTS_SR_AUTH_INFO              => 7;
use constant EGTS_SR_SERVICE_INFO           => 8;
use constant EGTS_SR_RESULT_CODE            => 9;
# Subrecord types for EGTS_TELEDATA_SERVICE
use constant EGTS_SR_POS_DATA               => 16;
use constant EGTS_SR_EXT_POS_DATA           => 17;
use constant EGTS_SR_AD_SENSORS_DATA        => 18;
use constant EGTS_SR_COUNTERS_DATA          => 19;
use constant EGTS_SR_STATE_DATA             => 20;
use constant EGTS_SR_LOOPIN_DATA            => 22;
use constant EGTS_SR_ABS_DIG_SENS_DATA      => 23;
use constant EGTS_SR_ABS_AN_SENS_DATA       => 24;
use constant EGTS_SR_ABS_CNTR_DATA          => 25;
use constant EGTS_SR_ABS_LOOPIN_DATA        => 26;
use constant EGTS_SR_LIQUID_LEVEL_SENSOR    => 27;
use constant EGTS_SR_PASSENGERS_COUNTERS    => 28;
push @EXPORT, qw(
    EGTS_SR_RECORD_RESPONSE

    EGTS_SR_TERM_IDENTITY
    EGTS_SR_MODULE_DATA
    EGTS_SR_VEHICLE_DATA
    EGTS_SR_DISPATCHER_IDENTITY
    EGTS_SR_AUTH_PARAMS
    EGTS_SR_AUTH_INFO
    EGTS_SR_SERVICE_INFO
    EGTS_SR_RESULT_CODE

    EGTS_SR_POS_DATA
    EGTS_SR_EXT_POS_DATA
    EGTS_SR_AD_SENSORS_DATA
    EGTS_SR_COUNTERS_DATA
    EGTS_SR_STATE_DATA
    EGTS_SR_LOOPIN_DATA
    EGTS_SR_ABS_DIG_SENS_DATA
    EGTS_SR_ABS_AN_SENS_DATA
    EGTS_SR_ABS_CNTR_DATA
    EGTS_SR_ABS_LOOPIN_DATA
    EGTS_SR_LIQUID_LEVEL_SENSOR
    EGTS_SR_PASSENGERS_COUNTERS
);

__PACKAGE__->meta->make_immutable();
