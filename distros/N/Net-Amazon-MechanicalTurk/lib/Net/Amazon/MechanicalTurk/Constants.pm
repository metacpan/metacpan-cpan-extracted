package Net::Amazon::MechanicalTurk::Constants;
use strict;
use warnings;
use Exporter;

our $VERSION = '1.00';

BEGIN {
    use Exporter ();
    our (@ISA, @EXPORT, @EXPORT_OK, %EXPORT_TAGS);
 
    @ISA = qw{ Exporter };
    @EXPORT = ();
    @EXPORT_OK = qw{
        %QUALIFICATION_TYPE_IDS
        $PROP_FILENAME
        $PROP_ENVNAME
        $PROP_GLOBAL_AUTH
        $PROP_GLOBAL_DIR
        $DEFAULT_SERVICE_VERSION
        $PRODUCTION_URL
        $SANDBOX_URL
        $PRODUCTION_REQUESTER_URL
        $SANDBOX_REQUESTER_URL
        $PRODUCTION_WORKER_URL
        $SANDBOX_WORKER_URL
    };
    %EXPORT_TAGS = ( ALL => [@EXPORT_OK] );
}

our @EXPORT_OK;

our %QUALIFICATION_TYPE_IDS = (
    Worker_PercentAssignmentsSubmitted => '00000000000000000000',
    Worker_PercentAssignmentsAbandoned => '00000000000000000070',
    Worker_PercentAssignmentsReturned  => '000000000000000000E0',
    Worker_PercentAssignmentsApproved  => '000000000000000000L0',
    Worker_PercentAssignmentsRejected  => '000000000000000000S0',
    Worker_Locale                      => '00000000000000000071'
);

our $PROP_FILENAME            = "mturk.properties";
our $PROP_ENVNAME             = "MTURK_CONFIG";
our $PROP_GLOBAL_AUTH         = "auth";
our $PROP_GLOBAL_DIR          = ".aws";
our $DEFAULT_SERVICE_VERSION  = "2011-10-01";
our $PRODUCTION_URL           = "https://mechanicalturk.amazonaws.com/?Service=AWSMechanicalTurkRequester";
our $SANDBOX_URL              = "https://mechanicalturk.sandbox.amazonaws.com/?Service=AWSMechanicalTurkRequester";
our $PRODUCTION_REQUESTER_URL = "http://requester.mturk.com";
our $SANDBOX_REQUESTER_URL    = "http://requestersandbox.mturk.com";
our $PRODUCTION_WORKER_URL    = "http://www.mturk.com";
our $SANDBOX_WORKER_URL       = "http://workersandbox.mturk.com";

return 1;
