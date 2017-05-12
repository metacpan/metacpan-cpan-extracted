package Net::FRN::Const;
use strict;
use base 'Exporter';

use vars qw(@EXPORT_OK @EXPORT);

@EXPORT_OK = qw(
    FRN_PROTO_VERSION
    FRN_TYPE_PC_ONLY
    FRN_TYPE_CROSSLINK
    FRN_TYPE_PARROT

    FRN_MESSAGE_BROADCAST
    FRN_MESSAGE_PRIVATE

    FRN_STATUS_ONLINE
    FRN_STATUS_AWAY
    FRN_STATUS_NA

    FRN_MUTE_OFF
    FRN_MUTE_ON
    
    FRN_RESULT_OK
    FRN_RESULT_NOK
    FRN_RESULT_WRONG
);

@EXPORT = @EXPORT_OK;

use constant FRN_PROTO_VERSION  => 2010002;

use constant FRN_TYPE_PC_ONLY   => 'PC Only';
use constant FRN_TYPE_CROSSLINK => 'Crosslink';
use constant FRN_TYPE_PARROT    => 'Parrot';

use constant FRN_MESSAGE_BROADCAST => 'A';
use constant FRN_MESSAGE_PRIVATE   => 'P';

use constant FRN_STATUS_ONLINE => 0;
use constant FRN_STATUS_AWAY   => 1;
use constant FRN_STATUS_NA     => 2;

use constant FRN_MUTE_OFF => 0;
use constant FRN_MUTE_ON  => 1;

use constant FRN_RESULT_OK    => 'OK';
use constant FRN_RESULT_NOK   => 'NOK';
use constant FRN_RESULT_WRONG => 'WRONG';

1;
