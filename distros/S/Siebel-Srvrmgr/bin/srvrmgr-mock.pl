#!perl
use warnings;
use strict;
use Hash::Util qw(lock_keys);
use YAML::XS 0.62 qw(Load);
use Getopt::Std;

our $VERSION = '0.29'; # VERSION

my $CRLF = "\015\012";

# replacing "/<OPTION>" with "-<OPTION> as is understood by getopts
for ( my $i = 0 ; $i <= scalar(@ARGV) ; $i++ ) {
    $ARGV[$i] =~ s#^/([bgeupsliok])$#-$1# if ( defined( $ARGV[$i] ) );
}

my %opts;
getopts( 'bg:e:u:p:s:l:i:o:k:', \%opts );
$SIG{INT} = sub { die "\nDisconnecting...\n" };

# detects batch mode
if ( ( ( exists( $opts{b} ) ) and $opts{b} ) ) {

    unless (( ( exists( $opts{i} ) ) and ( defined( $opts{i} ) ) )
        and ( ( exists( $opts{o} ) ) and ( defined( $opts{o} ) ) ) )
    {
        die 'Batch modes requires definition of /i and /o parameters';
    }

    batch( init() );
}
else {

    unless ( exists( $opts{p} ) ) {
        print 'Password: ';
        my $pass = <STDIN>;
        chomp($pass);
    }

    interactive( init() );
}

sub batch {
    my $data_ref = shift;
    open( my $in, '<', $opts{i} )
      or die( 'Cannot read ' . $opts{i} . ': ' . $! );
    open( my $out, '>', $opts{o} )
      or die( 'Cannot create ' . $opts{o} . ': ' . $! );

    put_text( $out, hello() );

    while (<$in>) {
        chomp();
        put_text( $out, "srvrmgr> $_\n" );
        process_cmd( $out, $data_ref, $_ );
    }
    close($out);
    close($in);
}

sub init {
    my $raw;
    {
        local $/ = undef;
        $raw = <DATA>;
        close(DATA);
    }
    my $data_ref = Load($raw);
    lock_keys( %{$data_ref} );
    return $data_ref;
}

sub process_cmd {
    my ( $handle, $data_ref, $cmd ) = @_;

  SWITCH: {
        if ( $cmd =~ /^list\sblockme$/ ) {

 # do nothing to get a deadlock when reading STDOUT with Siebel::Srvrmgr::Daemon
            sleep(20);
            put_text(
                $handle,
                [
                    $CRLF, 'yada yada yada',
                    $CRLF, $CRLF, '1 row returned.',
                    $CRLF, $CRLF
                ]
            );
            last SWITCH;

        }

        if ( $cmd =~ /^list\scomp\stype$/ ) {
            put_text( $handle, $data_ref->{list_comp_types} );
            last SWITCH;
        }

        # must be case insensitive because of test from the export_comps.pl
        if ( $cmd =~
            /^list\sparams\sfor\s(server\s\w+\s)?comp(onent)?\ssrproc$/i )
        {
            put_text( $handle, $data_ref->{list_params_for_srproc} );
            last SWITCH;
        }

        if (
            $cmd =~ /list\stasks\sfor\sserver\ssiebfoobar\scomponent\ssrproc$/ )
        {
            put_text( $handle,
                $data_ref->{list_tasks_for_server_siebfoobar_component_srproc}
            );
            last SWITCH;
        }

        if ( $cmd =~ /^list\stasks$/ ) {
            put_text( $handle, $data_ref->{list_tasks} );
            last SWITCH;
        }

        if ( $cmd =~ /^list\sparams$/ ) {
            put_text( $handle, $data_ref->{list_params} );
            last SWITCH;
        }

        if ( $cmd =~ /^list\scomp\sdef$/ ) {
            put_text( $handle, $data_ref->{list_comp_def_srproc} );
            last SWITCH;
        }

        if ( $cmd =~ /^list\scomp$/ ) {
            put_text( $handle, $data_ref->{list_comp} );
            last SWITCH;
        }

        if ( $cmd =~ /^list\sservers?$/ ) {
            put_text( $handle, $data_ref->{list_servers} );
            last SWITCH;
        }

        if ( $cmd eq 'load preferences' ) {
            put_text(
                $handle,
                [
'File: C:\\Siebel\\8.0\\web client\\BIN\\.Siebel_svrmgr.pref',
                    $CRLF,
                    $CRLF
                ]
            );
            last SWITCH;
        }

        if ( $cmd eq 'exit' ) {
            put_text( $handle, [ $CRLF, 'Disconnecting...', $CRLF ] );
            exit(0);
        }

        if ('') {
            put_text( $handle, $CRLF );
            last SWITCH;
        }

        if ( $cmd =~ /^list\scomplexquery$/ ) {
            put_text( \*STDERR,
                [ 'oh god, not today... let me stay in bed mommy!', $CRLF ] );
            put_text( $handle, $CRLF );  # must have the prompt in the next line
            last SWITCH;
        }

        if ( $cmd =~ /^list\sfrag$/ ) {
            put_text( \*STDERR,
                [ 'SBL-ADM-02043: where is this frag server?', $CRLF ] );
            put_text( $handle, $CRLF );
            last SWITCH;
        }

        if ( $cmd eq 'help' ) {
            put_text(
                $handle,
                [
                    'Available commands are:',     $CRLF,
                    'load preferences',            $CRLF,
                    'list servers',                $CRLF,
                    'list comp',                   $CRLF,
                    'list comp def',               $CRLF,
                    'list comp type',              $CRLF,
                    'list blockme',                $CRLF,
                    'list params',                 $CRLF,
                    'list params for comp srproc', $CRLF,
                    'list complexquery',           $CRLF,
                    'list frag',                   $CRLF,
                    'exit',                        $CRLF
                ]
            );
            last SWITCH;
        }
        else {
#TODO: check out how the srvrmgr exact print invalid command messages to replicate here
            put_text( $handle,
                [ 'Invalid command or syntax. See online help', $CRLF, $CRLF ]
            );
            last SWITCH;
        }
    }

}

sub interactive {
    my $data_ref = shift;
    put_text( \*STDOUT, hello() );

    while (1) {
        put_text( \*STDOUT, 'srvrmgr> ' );
        my $cmd = <STDIN>;
        chomp($cmd);
        process_cmd( \*STDOUT, $data_ref, $cmd );
    }

}

# to avoid buffering
# expects an array reference OR a scalar to print
# :WORKAROUND:29/05/2013 13:06:15:: had to use array data structure to avoid issues with large sets of
# data to be printed by syswrite (buffer was not being large enough)
sub put_text {
    my ( $handle, $data ) = @_;
    warn "invalid output to print" unless ( defined($data) );

    if ( ref($data) eq 'ARRAY' ) {
        foreach my $line ( @{$data} ) {
            my $ret = syswrite( $handle, $line );
            die "Fatal error trying to print command output: $!"
              unless ( defined($ret) );
        }
    }
    else {
        my $ret = syswrite( $handle, $data );
        die "Fatal error trying to print command output: $!"
          unless ( defined($ret) );
    }
    return 1;
}

sub hello {

# :WORKAROUND:14-12-2015 10:00:47:: fix the "egg and chicken" problem because Dist::Zilla did not yet installed srvrmgr-mock to generate a version for it
    my $version = $main::VERSION || 'unknown (run dzil!)';
    return <<"BLOCK";
Siebel Enterprise Applications Siebel Server Manager, Version 8.0.0.7 [20426] LANG_INDEPENDENT
Ahn... well, not exactly.
This is Server Manager Simulator, Version $version [1234] RAMO_NES
Copyright (c) 2012 Siebel Monitoring Tools. Released under GNU GPL version 3.
See https://github.com/glasswalk3r/siebel-monitoring-tools for more details.

Type "help" for list of commands, "help <topic>" for detailed help

Connected to 1 server(s) out of a total of 1 server(s) in the enterprise

BLOCK

}

__DATA__
---
list_comp:
- "\n"
- |
  SV_NAME     CC_ALIAS               CC_NAME                                       CT_ALIAS         CG_ALIAS       CC_RUNMODE   CP_DISP_RUN_STATE  CP_STARTMODE  CP_NUM_RUN_TASKS  CP_MAX_TASKS  CP_ACTV_MTS_PROCS  CP_MAX_MTS_PROCS  CP_START_TIME        CP_END_TIME          CP_STATUS  CC_INCARN_NO  CC_DESC_TEXT
- |
  ----------  ---------------------  --------------------------------------------  ---------------  -------------  -----------  -----------------  ------------  ----------------  ------------  -----------------  ----------------  -------------------  -------------------  ---------  ------------  ------------
- |
  siebfoobar  AsgnSrvr               Assignment Manager                            AsgnSrvr         AsgnMgmt       Batch        Online             Auto          0                 20            1                  1                 2016-09-19 13:11:39                       Enabled
- |
  siebfoobar  AsgnBatch              Batch Assignment                              AsgnBatch        AsgnMgmt       Batch        Online             Auto          0                 20                                                 2016-09-19 13:11:39                       Enabled
- |
  siebfoobar  CommConfigMgr          Communications Configuration Manager          BusSvcMgr        CommMgmt       Batch        Online             Auto          0                 20            1                  1                 2016-09-19 13:11:39                       Enabled
- |
  siebfoobar  CommInboundProcessor   Communications Inbound Processor              BusSvcMgr        CommMgmt       Batch        Online             Auto          0                 50            1                  1                 2016-09-19 13:11:39                       Enabled
- |
  siebfoobar  CommInboundRcvr        Communications Inbound Receiver               CommInboundRcvr  CommMgmt       Batch        Online             Auto          0                 21            1                  1                 2016-09-19 13:11:39                       Enabled
- |
  siebfoobar  CommOutboundMgr        Communications Outbound Manager               BusSvcMgr        CommMgmt       Batch        Online             Auto          0                 150           1                  3                 2016-09-19 13:11:39                       Enabled
- |
  siebfoobar  CommSessionMgr         Communications Session Manager                CommSessionMgr   CommMgmt       Batch        Online             Auto          0                 20            1                  1                 2016-09-19 13:11:39                       Enabled
- |
  siebfoobar  EAIObjMgr_enu          EAI Object Manager (ENU)                      EAIObjMgr        EAI            Interactive  Online             Auto          0                 240           5                  6                 2016-09-19 13:11:39                       Enabled
- |
  siebfoobar  EAIObjMgrXXXXX_enu     EAI Object Manager (ENU)                      EAIObjMgr        EAI            Interactive  Online             Auto          0                 240           5                  6                 2016-09-19 13:11:39                       Enabled
- |
  siebfoobar  InfraEAIOutbound       EAI Outbound Server                           BusSvcMgr        EAI            Batch        Online             Auto          0                 20            1                  1                 2016-09-19 13:11:39                       Enabled
- |
  siebfoobar  MailMgr                Email Manager                                 MailMgr          CommMgmt       Background   Online             Auto          0                 20                                                 2016-09-19 13:11:39                       Enabled
- |
  siebfoobar  EIM                    Enterprise Integration Mgr                    EIM              EAI            Batch        Online             Auto          0                 5                                                  2016-09-19 13:11:39                       Enabled
- |
  siebfoobar  FSMSrvr                File System Manager                           FSMSrvr          SystemAux      Batch        Online             Auto          0                 20            1                  1                 2016-09-19 13:11:34                       Enabled
- |
  siebfoobar  JMSReceiver            JMS Receiver                                  EAIJMSRcvr       EAI            Batch        Shutdown           Manual        0                 20            0                  1                                      2016-09-19 13:11:39  Enabled
- |
  siebfoobar  MqSeriesAMIRcvr        MQSeries AMI Receiver                         EAIRcvr          EAI            Background   Shutdown           Manual        0                 20                                                                      2016-09-19 13:11:39  Enabled
- |
  siebfoobar  MqSeriesSrvRcvr        MQSeries Server Receiver                      EAIRcvr          EAI            Background   Shutdown           Manual        0                 20                                                                      2016-09-19 13:11:39  Enabled
- |
  siebfoobar  MSMQRcvr               MSMQ Receiver                                 EAIRcvr          EAI            Background   Shutdown           Manual        0                 20                                                                      2016-09-19 13:11:39  Enabled
- |
  siebfoobar  PageMgr                Page Manager                                  PageMgr          CommMgmt       Background   Shutdown           Manual        0                 20                                                                      2016-09-19 13:11:39  Enabled
- |
  siebfoobar  SMQReceiver            SMQ Receiver                                  EAIRcvr          EAI            Background   Shutdown           Manual        0                 20                                                                      2016-09-19 13:11:39  Enabled
- |
  siebfoobar  ServerMgr              Server Manager                                ServerMgr        System         Interactive  Running            Auto          4                 20                                                 2016-09-19 13:11:34                       Enabled
- |
  siebfoobar  SRBroker               Server Request Broker                         ReqBroker        System         Interactive  Running            Auto          49                100           1                  1                 2016-09-19 13:11:34                       Enabled
- |
  siebfoobar  SRProc                 Server Request Processor                      SRProc           SystemAux      Interactive  Running            Auto          2                 20            1                  1                 2016-09-19 13:11:34                       Enabled
- |
  siebfoobar  SvrTblCleanup          Server Tables Cleanup                         BusSvcMgr        SystemAux      Background   Shutdown           Manual        0                 1                                                                       2016-09-19 13:11:34  Enabled
- |
  siebfoobar  SvrTaskPersist         Server Task Persistance                       BusSvcMgr        SystemAux      Background   Running            Auto          1                 1                                                  2016-09-19 13:11:34                       Enabled
- |
  siebfoobar  AdminNotify            Siebel Administrator Notification Component   AdminNotify      SystemAux      Batch        Online             Auto          0                 10            1                  1                 2016-09-19 13:11:34                       Enabled
- |
  siebfoobar  SCBroker               Siebel Connection Broker                      SCBroker         System         Background   Running            Auto          2                 2                                                  2016-09-19 13:11:34                       Enabled
- |
  siebfoobar  SmartAnswer            Smart Answer Manager                          BusSvcMgr        CommMgmt       Batch        Shutdown           Manual        0                 20            0                  1                                      2016-09-19 13:11:39  Enabled
- |
  siebfoobar  LoyEngineBatch         eLoyalty Processing Engine - Batch            BusSvcMgr        LoyaltyEngine  Batch        Shutdown           Manual        0                 60            0                  3                                      2016-09-19 13:11:39  Enabled
- |
  siebfoobar  LoyEngineInteractive   eLoyalty Processing Engine - Interactive      BusSvcMgr        LoyaltyEngine  Batch        Shutdown           Manual        0                 20            0                  1                                      2016-09-19 13:11:39  Enabled
- |
  siebfoobar  LoyEngineRealtime      eLoyalty Processing Engine - Realtime         BusSvcMgr        LoyaltyEngine  Batch        Online             Auto          0                 20            1                  1                 2016-09-19 13:11:39                       Enabled
- |
  siebfoobar  LoyEngineRealtimeTier  eLoyalty Processing Engine - Realtime - Tier  BusSvcMgr        LoyaltyEngine  Batch        Online             Auto          0                 50            1                  1                 2016-09-19 13:11:39                       Enabled
- "\n"
- "31 rows returned.\n"
- "\n"
list_comp_def:
- "\n"
- "CC_NAME                                                                       CT_NAME
  \                                                                      CC_RUNMODE
  \                      CC_ALIAS                          CC_DISP_ENABLE_ST                                              CC_DESC_TEXT
  \                                                                                                                                                                                                                                                CG_NAME
  \                                                                      CG_ALIAS
  \                        CC_INCARN_NO             \n"
- "----------------------------------------------------------------------------  ----------------------------------------------------------------------------
  \ -------------------------------  --------------------------------  -------------------------------------------------------------
  \ --------------------------------------------------------------------------------------------------------------------
  \ ----------------------------------------------------------------------------  -------------------------------
  \ -----------------------  \n"
- "Application Deployment Manager Batch Processor                                Business
  Service Manager                                                      Batch                            ADMBatchProc
  \                     Active                                                         Exports
  data items in batch                                                                                                                                                                                                                                  Application
  Deployment Manager                                                ADM                              0
  \                       \n"
- "Application Deployment Manager Object Manager (ENU)                           Application
  Object Manager                                                    Interactive                      ADMObjMgr_enu
  \                    Active                                                         Siebel
  Object Manager for deployment of application customizations                                                                                                                                                                                           Application
  Deployment Manager                                                ADM                              0
  \                       \n"
- "Application Deployment Manager Object Manager (PTB)                           Application
  Object Manager                                                    Interactive                      ADMObjMgr_ptb
  \                    Active                                                         Siebel
  Object Manager for deployment of application customizations                                                                                                                                                                                           Application
  Deployment Manager                                                ADM                              0
  \                       \n"
- "Application Deployment Manager Processor                                      Business
  Service Manager                                                      Batch                            ADMProc
  \                          Active                                                         Processes
  Data Deployment                                                                                                                                                                                                                                    Application
  Deployment Manager                                                ADM                              0
  \                       \n"
- "Appointment Booking Engine                                                    Business
  Service Manager                                                      Batch                            ApptBook
  \                         Active                                                         Book
  appointments                                                                                                                                                                                                                                            Field
  Service                                                                 FieldSvc
  \                        0                        \n"
- "Assignment Manager                                                            Assignment
  Manager                                                            Batch                            AsgnSrvr
  \                         Active                                                         Assigns
  positions and employees to objects                                                                                                                                                                                                                   Assignment
  Management                                                         AsgnMgmt                         0
  \                       \n"
- "Batch Assignment                                                              Batch
  Assignment                                                              Batch                            AsgnBatch
  \                        Active                                                         Batch
  assigns positions and employees to objects                                                                                                                                                                                                             Assignment
  Management                                                         AsgnMgmt                         0
  \                       \n"
- "BatchSync                                                                     Business
  Service Manager                                                      Batch                            BatchSync
  \                        Active                                                         Handheld
  Batch Synchronization                                                                                                                                                                                                                               Handheld
  Synchronization                                                      HandheldSync
  \                    0                        \n"
- "Business Integration Batch Manager                                            Business
  Service Manager                                                      Batch                            BusIntBatchMgr
  \                   Active                                                         Manages
  Business Integration dataflows in batch mode                                                                                                                                                                                                         Enterprise
  Application Integration                                            EAI                              0
  \                       \n"
- "Business Integration Manager                                                  Business
  Service Manager                                                      Batch                            BusIntMgr
  \                        Active                                                         Executes
  Business Integration dataflows                                                                                                                                                                                                                      Enterprise
  Application Integration                                            EAI                              0
  \                       \n"
- "Call Center Object Manager (ENU)                                              Application
  Object Manager                                                    Interactive                      SCCObjMgr_enu
  \                    Active                                                         Siebel
  Call Center Object Manager                                                                                                                                                                                                                            Siebel
  Call Center                                                            CallCenter
  \                      0                        \n"
- "Call Center Object Manager (PTB)                                              Application
  Object Manager                                                    Interactive                      SCCObjMgr_ptb
  \                    Active                                                         Siebel
  Call Center Object Manager                                                                                                                                                                                                                            Siebel
  Call Center                                                            CallCenter
  \                      0                        \n"
- "Communications Configuration Manager                                          Business
  Service Manager                                                      Batch                            CommConfigMgr
  \                    Active                                                         Download
  and cache communications configuration                                                                                                                                                                                                              Communications
  Management                                                     CommMgmt                         0
  \                       \n"
- "Communications Inbound Processor                                              Business
  Service Manager                                                      Batch                            CommInboundProcessor
  \             Active                                                         Processes
  queued communication events                                                                                                                                                                                                                        Communications
  Management                                                     CommMgmt                         0
  \                       \n"
- "Communications Inbound Receiver                                               Communications
  Inbound Receiver                                               Batch                            CommInboundRcvr
  \                  Active                                                         Queues
  inbound communication events                                                                                                                                                                                                                          Communications
  Management                                                     CommMgmt                         0
  \                       \n"
- "Communications Outbound Manager                                               Business
  Service Manager                                                      Batch                            CommOutboundMgr
  \                  Active                                                         Sends
  messages to recipients associated with business object instances                                                                                                                                                                                       Communications
  Management                                                     CommMgmt                         0
  \                       \n"
- "Communications Session Manager                                                Communications
  Session Manager                                                Batch                            CommSessionMgr
  \                   Active                                                         Interact
  with end user for utilizing communications channels                                                                                                                                                                                                 Communications
  Management                                                     CommMgmt                         0
  \                       \n"
- "Content Project Publish                                                       Business
  Service Manager                                                      Batch                            ContProjPub
  \                      Active                                                         Publish
  a content project                                                                                                                                                                                                                                    Content
  Center                                                                ContCtr                          0
  \                       \n"
- "Content Project Start                                                         Business
  Service Manager                                                      Batch                            ContProjStart
  \                    Active                                                         Start
  a content project                                                                                                                                                                                                                                      Content
  Center                                                                ContCtr                          0
  \                       \n"
- "Core Reference Application Object Manager (ENU)                               Application
  Object Manager                                                    Interactive                      CRAObjMgr_enu
  \                    Active                                                         Siebel
  Core Reference Application Object Manager                                                                                                                                                                                                             Siebel
  Core Reference Application                                             CRA                              0
  \                       \n"
- "Core Reference Application Object Manager (PTB)                               Application
  Object Manager                                                    Interactive                      CRAObjMgr_ptb
  \                    Active                                                         Siebel
  Core Reference Application Object Manager                                                                                                                                                                                                             Siebel
  Core Reference Application                                             CRA                              0
  \                       \n"
- "Custom Application Object Manager (ENU)                                       Custom
  Application Object Manager                                             Interactive
  \                     CustomAppObjMgr_enu               Inactive                                                       Siebel
  Custom Application Object Manager                                                                                                                                                                                                                     Enterprise
  Application Integration                                            EAI                              0
  \                       \n"
- "Custom Application Object Manager (PTB)                                       Custom
  Application Object Manager                                             Interactive
  \                     CustomAppObjMgr_ptb               Inactive                                                       Siebel
  Custom Application Object Manager                                                                                                                                                                                                                     Enterprise
  Application Integration                                            EAI                              0
  \                       \n"
- "D&B Update Mgr (D&B)                                                          Batch
  Real-Time Integration                                                   Batch                            DNBUpMgrDNB
  \                      Active                                                         Updates
  D&B tables with subscription data                                                                                                                                                                                                                    Dun
  and Bradstreet                                                            DandB
  \                           0                        \n"
- "D&B Update Mgr (Multi-task)                                                   Business
  Service Manager                                                      Batch                            DNBUpMgrMultiTask
  \                Active                                                         Updates
  D&B or Siebel tables with subscription data in multiple tasks                                                                                                                                                                                        Dun
  and Bradstreet                                                            DandB
  \                           0                        \n"
- "D&B Update Mgr (Siebel)                                                       Batch
  Real-Time Integration                                                   Batch                            DNBUpMgrSieb
  \                     Active                                                         Updates
  Siebel tables subscription data                                                                                                                                                                                                                      Dun
  and Bradstreet                                                            DandB
  \                           0                        \n"
- "Data Quality Manager                                                          Data
  Quality Manager                                                          Batch                            DQMgr
  \                            Active                                                         Cleanses
  data and de-duplicates records                                                                                                                                                                                                                      Data
  Quality                                                                  DataQual
  \                        0                        \n"
- "Database Extract                                                              Database
  Extract                                                              Batch                            DbXtract
  \                         Active                                                         Extracts
  visible data for a Siebel Remote or Replication Manager client                                                                                                                                                                                      Siebel
  Remote                                                                 Remote                           0
  \                       \n"
- "DCommerce Alerts                                                              DCommerce
  Alerts                                                              Background                       DCommerceAlerts
  \                  Active                                                         Background
  process that manages DCommerce alerts                                                                                                                                                                                                             DCommerce
  \                                                                    DCommerce                        0
  \                       \n"
- "DCommerce Automatic Auction Close                                             DCommerce
  Automatic Auction Close                                             Background                       DCommerceAutoClose
  \               Active                                                         Background
  process that detects and closes auctions                                                                                                                                                                                                          DCommerce
  \                                                                    DCommerce                        0
  \                       \n"
- "Document Server                                                               Business
  Service Manager                                                      Batch                            DocServer
  \                        Active                                                         Generates
  Documents                                                                                                                                                                                                                                          Siebel
  eDocuments                                                             eDocuments
  \                      0                        \n"
- "Dynamic Commerce                                                              Business
  Service Manager                                                      Batch                            DynamicCommerce
  \                  Active                                                         Dynamic
  Commerce master services                                                                                                                                                                                                                             DCommerce
  \                                                                    DCommerce                        0
  \                       \n"
- "EAI Object Manager (ENU)                                                      EAI
  Object Manager                                                            Interactive
  \                     EAIObjMgr_enu                     Active                                                         Siebel
  EAI Object Manager                                                                                                                                                                                                                                    Enterprise
  Application Integration                                            EAI                              0
  \                       \n"
- "EAI Object Manager (PTB)                                                      EAI
  Object Manager                                                            Interactive
  \                     EAIObjMgr_ptb                     Active                                                         Siebel
  EAI Object Manager                                                                                                                                                                                                                                    Enterprise
  Application Integration                                            EAI                              0
  \                       \n"
- "eAuto Business Rule Execution Component                                       Business
  Service Manager                                                      Batch                            eAutoBusRuleExecSvc
  \              Active                                                         Executes
  Business Rules                                                                                                                                                                                                                                      Siebel
  eAutomotive                                                            eAutomotive
  \                     0                        \n"
- "eAutomotive Object Manager (ENU)                                              Application
  Object Manager                                                    Interactive                      eautoObjMgr_enu
  \                  Active                                                         Siebel
  eAutomotive Object Manager                                                                                                                                                                                                                            Siebel
  eAutomotive                                                            eAutomotive
  \                     0                        \n"
- "eAutomotive Object Manager (PTB)                                              Application
  Object Manager                                                    Interactive                      eautoObjMgr_ptb
  \                  Active                                                         Siebel
  eAutomotive Object Manager                                                                                                                                                                                                                            Siebel
  eAutomotive                                                            eAutomotive
  \                     0                        \n"
- "eChannel CG Object Manager (ENU)                                              Application
  Object Manager                                                    Interactive                      eChannelCGObjMgr_enu
  \             Active                                                         Siebel
  eChannel CG Object Manager                                                                                                                                                                                                                            Siebel
  eConsumerSector                                                        eConsumer
  \                       0                        \n"
- "eChannel CG Object Manager (PTB)                                              Application
  Object Manager                                                    Interactive                      eChannelCGObjMgr_ptb
  \             Active                                                         Siebel
  eChannel CG Object Manager                                                                                                                                                                                                                            Siebel
  eConsumerSector                                                        eConsumer
  \                       0                        \n"
- "eChannel Object Manager (ENU)                                                 Application
  Object Manager                                                    Interactive                      eChannelObjMgr_enu
  \               Active                                                         Siebel
  eChannel Object Manager                                                                                                                                                                                                                               Siebel
  eChannel                                                               eChannel
  \                        0                        \n"
- "eChannel Object Manager (PTB)                                                 Application
  Object Manager                                                    Interactive                      eChannelObjMgr_ptb
  \               Active                                                         Siebel
  eChannel Object Manager                                                                                                                                                                                                                               Siebel
  eChannel                                                               eChannel
  \                        0                        \n"
- "eChannel Power Communications Object Manager (ENU)                            Application
  Object Manager                                                    Interactive                      eChannelCMEObjMgr_enu
  \            Active                                                         Siebel
  eChannel Power Communications Object Manager                                                                                                                                                                                                          Siebel
  CME                                                                    Communications
  \                  0                        \n"
- "eChannel Power Communications Object Manager (PTB)                            Application
  Object Manager                                                    Interactive                      eChannelCMEObjMgr_ptb
  \            Active                                                         Siebel
  eChannel Power Communications Object Manager                                                                                                                                                                                                          Siebel
  CME                                                                    Communications
  \                  0                        \n"
- "eClinical Object Manager (ENU)                                                Application
  Object Manager                                                    Interactive                      eClinicalObjMgr_enu
  \              Active                                                         Siebel
  eClinical Object Manager                                                                                                                                                                                                                              Siebel
  Life Sciences                                                          LifeSciences
  \                    0                        \n"
- "eClinical Object Manager (PTB)                                                Application
  Object Manager                                                    Interactive                      eClinicalObjMgr_ptb
  \              Active                                                         Siebel
  eClinical Object Manager                                                                                                                                                                                                                              Siebel
  Life Sciences                                                          LifeSciences
  \                    0                        \n"
- "eCommunications for Wireless Object Manager (ENU)                             Application
  Object Manager                                                    Interactive                      eCommWirelessObjMgr_enu
  \          Inactive                                                       Siebel
  eCommunications for Wireless Object Manager                                                                                                                                                                                                           Siebel
  CME                                                                    Communications
  \                  0                        \n"
- "eCommunications for Wireless Object Manager (PTB)                             Application
  Object Manager                                                    Interactive                      eCommWirelessObjMgr_ptb
  \          Inactive                                                       Siebel
  eCommunications for Wireless Object Manager                                                                                                                                                                                                           Siebel
  CME                                                                    Communications
  \                  0                        \n"
- "eCommunications Object Manager (ENU)                                          Application
  Object Manager                                                    Interactive                      eCommunicationsObjMgr_enu
  \        Active                                                         Siebel eCommunications
  Object Manager                                                                                                                                                                                                                        Siebel
  CME                                                                    Communications
  \                  0                        \n"
- "eCommunications Object Manager (PTB)                                          Application
  Object Manager                                                    Interactive                      eCommunicationsObjMgr_ptb
  \        Active                                                         Siebel eCommunications
  Object Manager                                                                                                                                                                                                                        Siebel
  CME                                                                    Communications
  \                  0                        \n"
- "eCommunications Object Manager Adm (PTB)                                      Application
  Object Manager                                                    Interactive                      eCommunicationsObjMgrAdm_ptb
  \     Inactive                                                       Siebel eCommunications
  Object Manager                                                                                                                                                                                                                        Siebel
  CME                                                                    Communications
  \                  0                        \n"
- "eConsumer Object Manager (ENU)                                                Application
  Object Manager                                                    Interactive                      eConsumerObjMgr_enu
  \              Active                                                         Siebel
  eConsumer Object Manager                                                                                                                                                                                                                              Siebel
  eConsumerSector                                                        eConsumer
  \                       0                        \n"
- "eConsumer Object Manager (PTB)                                                Application
  Object Manager                                                    Interactive                      eConsumerObjMgr_ptb
  \              Active                                                         Siebel
  eConsumer Object Manager                                                                                                                                                                                                                              Siebel
  eConsumerSector                                                        eConsumer
  \                       0                        \n"
- "eConsumerPharma Object Manager (ENU)                                          Application
  Object Manager                                                    Interactive                      eConsumerPharmaObjMgr_enu
  \        Active                                                         Siebel eConsumerPharmaObjMgr
  Object Manager                                                                                                                                                                                                                  Siebel
  Life Sciences                                                          LifeSciences
  \                    0                        \n"
- "eConsumerPharma Object Manager (PTB)                                          Application
  Object Manager                                                    Interactive                      eConsumerPharmaObjMgr_ptb
  \        Active                                                         Siebel eConsumerPharmaObjMgr
  Object Manager                                                                                                                                                                                                                  Siebel
  Life Sciences                                                          LifeSciences
  \                    0                        \n"
- "eConsumerSector Object Manager (ENU)                                          Application
  Object Manager                                                    Interactive                      eConsumerSectorObjMgr_enu
  \        Active                                                         Siebel eConsumerSector
  Object Manager                                                                                                                                                                                                                        Siebel
  eConsumerSector                                                        eConsumer
  \                       0                        \n"
- "eConsumerSector Object Manager (PTB)                                          Application
  Object Manager                                                    Interactive                      eConsumerSectorObjMgr_ptb
  \        Active                                                         Siebel eConsumerSector
  Object Manager                                                                                                                                                                                                                        Siebel
  eConsumerSector                                                        eConsumer
  \                       0                        \n"
- "eCustomer Object Manager (ENU)                                                Application
  Object Manager                                                    Interactive                      eCustomerObjMgr_enu
  \              Active                                                         Siebel
  eCustomer Object Manager                                                                                                                                                                                                                              Siebel
  ISS                                                                    ISS                              0
  \                       \n"
- "eCustomer Object Manager (PTB)                                                Application
  Object Manager                                                    Interactive                      eCustomerObjMgr_ptb
  \              Active                                                         Siebel
  eCustomer Object Manager                                                                                                                                                                                                                              Siebel
  ISS                                                                    ISS                              0
  \                       \n"
- "eCustomer Power Communications Object Manager (ENU)                           Application
  Object Manager                                                    Interactive                      eCustomerCMEObjMgr_enu
  \           Inactive                                                       Siebel
  eCustomer Power Communications Object Manager                                                                                                                                                                                                         Siebel
  CME                                                                    Communications
  \                  0                        \n"
- "eCustomer Power Communications Object Manager (PTB)                           Application
  Object Manager                                                    Interactive                      eCustomerCMEObjMgr_ptb
  \           Inactive                                                       Siebel
  eCustomer Power Communications Object Manager                                                                                                                                                                                                         Siebel
  CME                                                                    Communications
  \                  0                        \n"
- "eDealer Object Manager (ENU)                                                  Application
  Object Manager                                                    Interactive                      edealerObjMgr_enu
  \                Active                                                         Siebel
  eDealer Object Manager                                                                                                                                                                                                                                Siebel
  eAutomotive                                                            eAutomotive
  \                     0                        \n"
- "eDealer Object Manager (PTB)                                                  Application
  Object Manager                                                    Interactive                      edealerObjMgr_ptb
  \                Active                                                         Siebel
  eDealer Object Manager                                                                                                                                                                                                                                Siebel
  eAutomotive                                                            eAutomotive
  \                     0                        \n"
- "eDealerscw Object Manager (ENU)                                               Application
  Object Manager                                                    Interactive                      edealerscwObjMgr_enu
  \             Active                                                         Siebel
  eDealerscw Object Manager                                                                                                                                                                                                                             Siebel
  eAutomotive                                                            eAutomotive
  \                     0                        \n"
- "eDealerscw Object Manager (PTB)                                               Application
  Object Manager                                                    Interactive                      edealerscwObjMgr_ptb
  \             Active                                                         Siebel
  eDealerscw Object Manager                                                                                                                                                                                                                             Siebel
  eAutomotive                                                            eAutomotive
  \                     0                        \n"
- "eEnergy Object Manager (ENU)                                                  Application
  Object Manager                                                    Interactive                      eEnergyObjMgr_enu
  \                Inactive                                                       Siebel
  eEnergy Object Manager                                                                                                                                                                                                                                Siebel
  CME                                                                    Communications
  \                  0                        \n"
- "eEnergy Object Manager (PTB)                                                  Application
  Object Manager                                                    Interactive                      eEnergyObjMgr_ptb
  \                Inactive                                                       Siebel
  eEnergy Object Manager                                                                                                                                                                                                                                Siebel
  CME                                                                    Communications
  \                  0                        \n"
- "eEvents Object Manager (ENU)                                                  Application
  Object Manager                                                    Interactive                      eEventsObjMgr_enu
  \                Active                                                         Siebel
  eEvents Object Manager                                                                                                                                                                                                                                Marketing
  Object Manager                                                      MktgOM                           0
  \                       \n"
- "eEvents Object Manager (PTB)                                                  Application
  Object Manager                                                    Interactive                      eEventsObjMgr_ptb
  \                Active                                                         Siebel
  eEvents Object Manager                                                                                                                                                                                                                                Marketing
  Object Manager                                                      MktgOM                           0
  \                       \n"
- "eHospitality Object Manager (ENU)                                             Application
  Object Manager                                                    Interactive                      eHospitalityObjMgr_enu
  \           Active                                                         Siebel
  eHospitality Object Manager                                                                                                                                                                                                                           Siebel
  eHospitality                                                           Hospitality
  \                     0                        \n"
- "eHospitality Object Manager (PTB)                                             Application
  Object Manager                                                    Interactive                      eHospitalityObjMgr_ptb
  \           Active                                                         Siebel
  eHospitality Object Manager                                                                                                                                                                                                                           Siebel
  eHospitality                                                           Hospitality
  \                     0                        \n"
- "eLoyalty Processing Engine - Batch                                            Business
  Service Manager                                                      Batch                            LoyEngineBatch
  \                   Active                                                         Processes
  Loyalty Transactions, Tiers etc. in the background.                                                                                                                                                                                                Siebel
  Loyalty Engine                                                         LoyaltyEngine
  \                   0                        \n"
- "eLoyalty Processing Engine - Interactive                                      Business
  Service Manager                                                      Batch                            LoyEngineInteractive
  \             Active                                                         Process
  Loyalty Transactions for Retail POS.                                                                                                                                                                                                                 Siebel
  Loyalty Engine                                                         LoyaltyEngine
  \                   0                        \n"
- "eLoyalty Processing Engine - Realtime                                         Business
  Service Manager                                                      Batch                            LoyEngineRealtime
  \                Active                                                         Processes
  Loyalty Transactions, Tiers etc. submitted by users.                                                                                                                                                                                               Siebel
  Loyalty Engine                                                         LoyaltyEngine
  \                   0                        \n"
- "Email Manager                                                                 E-mail
  Manager                                                                Background
  \                      MailMgr                           Active                                                         Sends
  individual email responses                                                                                                                                                                                                                             Communications
  Management                                                     CommMgmt                         0
  \                       \n"
- "eMarketing Object Manager (ENU)                                               Application
  Object Manager                                                    Interactive                      eMarketObjMgr_enu
  \                Active                                                         Siebel
  eMarketing Object Manager                                                                                                                                                                                                                             Marketing
  Object Manager                                                      MktgOM                           0
  \                       \n"
- "eMarketing Object Manager (PTB)                                               Application
  Object Manager                                                    Interactive                      eMarketObjMgr_ptb
  \                Active                                                         Siebel
  eMarketing Object Manager                                                                                                                                                                                                                             Marketing
  Object Manager                                                      MktgOM                           0
  \                       \n"
- "eMedia Object Manager (ENU)                                                   Application
  Object Manager                                                    Interactive                      eMediaObjMgr_enu
  \                 Inactive                                                       Siebel
  eMedia Object Manager                                                                                                                                                                                                                                 Siebel
  CME                                                                    Communications
  \                  0                        \n"
- "eMedia Object Manager (PTB)                                                   Application
  Object Manager                                                    Interactive                      eMediaObjMgr_ptb
  \                 Inactive                                                       Siebel
  eMedia Object Manager                                                                                                                                                                                                                                 Siebel
  CME                                                                    Communications
  \                  0                        \n"
- "eMedical Object Manager (ENU)                                                 Application
  Object Manager                                                    Interactive                      eMedicalObjMgr_enu
  \               Active                                                         Siebel
  eMedical Object Manager                                                                                                                                                                                                                               Siebel
  Life Sciences                                                          LifeSciences
  \                    0                        \n"
- "eMedical Object Manager (PTB)                                                 Application
  Object Manager                                                    Interactive                      eMedicalObjMgr_ptb
  \               Active                                                         Siebel
  eMedical Object Manager                                                                                                                                                                                                                               Siebel
  Life Sciences                                                          LifeSciences
  \                    0                        \n"
- "Employee Relationship Management Administration Object Manager (ENU)          Application
  Object Manager                                                    Interactive                      ERMAdminObjMgr_enu
  \               Active                                                         Siebel
  Employee Relationship Management Administration Object Manager                                                                                                                                                                                        Siebel
  Employee Relationship Management                                       ERM                              0
  \                       \n"
- "Employee Relationship Management Administration Object Manager (PTB)          Application
  Object Manager                                                    Interactive                      ERMAdminObjMgr_ptb
  \               Active                                                         Siebel
  Employee Relationship Management Administration Object Manager                                                                                                                                                                                        Siebel
  Employee Relationship Management                                       ERM                              0
  \                       \n"
- "Employee Relationship Management Embedded Object Manager (ENU)                Application
  Object Manager                                                    Interactive                      ERMEmbObjMgr_enu
  \                 Active                                                         Siebel
  Employee Relationship Management Embedded Object Manager                                                                                                                                                                                              Siebel
  Employee Relationship Management                                       ERM                              0
  \                       \n"
- "Employee Relationship Management Embedded Object Manager (PTB)                Application
  Object Manager                                                    Interactive                      ERMEmbObjMgr_ptb
  \                 Active                                                         Siebel
  Employee Relationship Management Embedded Object Manager                                                                                                                                                                                              Siebel
  Employee Relationship Management                                       ERM                              0
  \                       \n"
- "Employee Relationship Management Object Manager (ENU)                         Application
  Object Manager                                                    Interactive                      ERMObjMgr_enu
  \                    Active                                                         Siebel
  Employee Relationship Management Object Manager                                                                                                                                                                                                       Siebel
  Employee Relationship Management                                       ERM                              0
  \                       \n"
- "Employee Relationship Management Object Manager (PTB)                         Application
  Object Manager                                                    Interactive                      ERMObjMgr_ptb
  \                    Active                                                         Siebel
  Employee Relationship Management Object Manager                                                                                                                                                                                                       Siebel
  Employee Relationship Management                                       ERM                              0
  \                       \n"
- "Enterprise Integration Mgr                                                    Enterprise
  Integration Mgr                                                    Batch                            EIM
  \                              Active                                                         Integrates
  enterprise data to and from other systems                                                                                                                                                                                                         Enterprise
  Application Integration                                            EAI                              0
  \                       \n"
- "eOil Gas & Chemicals  Object Manager (ENU)                                    Application
  Object Manager                                                    Interactive                      eEnergyOGCObjMgr_enu
  \             Inactive                                                       Siebel
  eOil Gas & Chemicals  Object Manager                                                                                                                                                                                                                  Siebel
  CME                                                                    Communications
  \                  0                        \n"
- "eOil Gas & Chemicals  Object Manager (PTB)                                    Application
  Object Manager                                                    Interactive                      eEnergyOGCObjMgr_ptb
  \             Inactive                                                       Siebel
  eOil Gas & Chemicals  Object Manager                                                                                                                                                                                                                  Siebel
  CME                                                                    Communications
  \                  0                        \n"
- "ePharma Object Manager (ENU)                                                  Application
  Object Manager                                                    Interactive                      ePharmaObjMgr_enu
  \                Active                                                         Siebel
  ePharma Object Manager                                                                                                                                                                                                                                Siebel
  Life Sciences                                                          LifeSciences
  \                    0                        \n"
- "ePharma Object Manager (PTB)                                                  Application
  Object Manager                                                    Interactive                      ePharmaObjMgr_ptb
  \                Active                                                         Siebel
  ePharma Object Manager                                                                                                                                                                                                                                Siebel
  Life Sciences                                                          LifeSciences
  \                    0                        \n"
- "eProfessionalPharma Object Manager (ENU)                                      Application
  Object Manager                                                    Interactive                      eProfessionalPharmaObjMgr_enu
  \    Active                                                         Siebel eProfessionalPharmaObjMgr
  Object Manager                                                                                                                                                                                                              Siebel
  Life Sciences                                                          LifeSciences
  \                    0                        \n"
- "eProfessionalPharma Object Manager (PTB)                                      Application
  Object Manager                                                    Interactive                      eProfessionalPharmaObjMgr_ptb
  \    Active                                                         Siebel eProfessionalPharmaObjMgr
  Object Manager                                                                                                                                                                                                              Siebel
  Life Sciences                                                          LifeSciences
  \                    0                        \n"
- "eRetail Object Manager (ENU)                                                  Application
  Object Manager                                                    Interactive                      eRetailObjMgr_enu
  \                Active                                                         Siebel
  eRetail Object Manager                                                                                                                                                                                                                                Siebel
  eConsumerSector                                                        eConsumer
  \                       0                        \n"
- "eRetail Object Manager (PTB)                                                  Application
  Object Manager                                                    Interactive                      eRetailObjMgr_ptb
  \                Active                                                         Siebel
  eRetail Object Manager                                                                                                                                                                                                                                Siebel
  eConsumerSector                                                        eConsumer
  \                       0                        \n"
- "ERM Compensation Planning Service                                             Business
  Service Manager                                                      Batch                            ERMCompPlanSvc
  \                   Active                                                         ERM
  Compensation Planning Services.                                                                                                                                                                                                                          Siebel
  Employee Relationship Management                                       ERM                              0
  \                       \n"
- "eSales Object Manager (ENU)                                                   Application
  Object Manager                                                    Interactive                      eSalesObjMgr_enu
  \                 Active                                                         Siebel
  eSales Object Manager                                                                                                                                                                                                                                 Siebel
  ISS                                                                    ISS                              0
  \                       \n"
- "eSales Object Manager (PTB)                                                   Application
  Object Manager                                                    Interactive                      eSalesObjMgr_ptb
  \                 Active                                                         Siebel
  eSales Object Manager                                                                                                                                                                                                                                 Siebel
  ISS                                                                    ISS                              0
  \                       \n"
- "eSales Power Communications Object Manager (ENU)                              Application
  Object Manager                                                    Interactive                      eSalesCMEObjMgr_enu
  \              Inactive                                                       Siebel
  eSales Power Communications Object Manager                                                                                                                                                                                                            Siebel
  CME                                                                    Communications
  \                  0                        \n"
- "eSales Power Communications Object Manager (PTB)                              Application
  Object Manager                                                    Interactive                      eSalesCMEObjMgr_ptb
  \              Inactive                                                       Siebel
  eSales Power Communications Object Manager                                                                                                                                                                                                            Siebel
  CME                                                                    Communications
  \                  0                        \n"
- "eService Object Manager (ENU)                                                 Application
  Object Manager                                                    Interactive                      eServiceObjMgr_enu
  \               Active                                                         Siebel
  eService Object Manager                                                                                                                                                                                                                               Siebel
  Call Center                                                            CallCenter
  \                      0                        \n"
- "eService Object Manager (PTB)                                                 Application
  Object Manager                                                    Interactive                      eServiceObjMgr_ptb
  \               Active                                                         Siebel
  eService Object Manager                                                                                                                                                                                                                               Siebel
  Call Center                                                            CallCenter
  \                      0                        \n"
- "eSitesClinical Object Manager (ENU)                                           Application
  Object Manager                                                    Interactive                      eSitesClinicalObjMgr_enu
  \         Active                                                         Siebel
  eSitesClinical Object Manager                                                                                                                                                                                                                         Siebel
  Life Sciences                                                          LifeSciences
  \                    0                        \n"
- "eSitesClinical Object Manager (PTB)                                           Application
  Object Manager                                                    Interactive                      eSitesClinicalObjMgr_ptb
  \         Active                                                         Siebel
  eSitesClinical Object Manager                                                                                                                                                                                                                         Siebel
  Life Sciences                                                          LifeSciences
  \                    0                        \n"
- "eTraining Object Manager (ENU)                                                Application
  Object Manager                                                    Interactive                      eTrainingObjMgr_enu
  \              Active                                                         Siebel
  eTraining Object Manager                                                                                                                                                                                                                              Siebel
  Employee Relationship Management                                       ERM                              0
  \                       \n"
- "eTraining Object Manager (PTB)                                                Application
  Object Manager                                                    Interactive                      eTrainingObjMgr_ptb
  \              Active                                                         Siebel
  eTraining Object Manager                                                                                                                                                                                                                              Siebel
  Employee Relationship Management                                       ERM                              0
  \                       \n"
- "Field Service Cycle Counting Engine                                           Business
  Service Manager                                                      Batch                            FSCyccnt
  \                         Active                                                         Field
  Service Cycle Counting Engine                                                                                                                                                                                                                          Field
  Service                                                                 FieldSvc
  \                        0                        \n"
- "Field Service Mobile Inventory Transaction Engine                             Business
  Service Manager                                                      Batch                            FSInvTxn
  \                         Active                                                         Field
  Service Mobile Inventory Transaction Engine                                                                                                                                                                                                            Field
  Service                                                                 FieldSvc
  \                        0                        \n"
- "Field Service Object Manager (ENU)                                            Application
  Object Manager                                                    Interactive                      SFSObjMgr_enu
  \                    Active                                                         Siebel
  Field Service Object Manager                                                                                                                                                                                                                          Field
  Service                                                                 FieldSvc
  \                        0                        \n"
- "Field Service Object Manager (PTB)                                            Application
  Object Manager                                                    Interactive                      SFSObjMgr_ptb
  \                    Active                                                         Siebel
  Field Service Object Manager                                                                                                                                                                                                                          Field
  Service                                                                 FieldSvc
  \                        0                        \n"
- "Field Service Replenishment Engine                                            Business
  Service Manager                                                      Batch                            FSRepl
  \                           Active                                                         Replenishes
  inventory locations                                                                                                                                                                                                                              Field
  Service                                                                 FieldSvc
  \                        0                        \n"
- "File System Manager                                                           File
  System Manager                                                           Batch                            FSMSrvr
  \                          Active                                                         The
  file system manager component                                                                                                                                                                                                                            Auxiliary
  System Management                                                   SystemAux                        0
  \                       \n"
- "Financial eCustomer Object Manager (ENU)                                      Application
  Object Manager                                                    Interactive                      FINSeCustomerObjMgr_enu
  \          Active                                                         Financial
  eCustomer Object Manager                                                                                                                                                                                                                           Siebel
  Financial Services                                                     Fins                             0
  \                       \n"
- "Financial eCustomer Object Manager (PTB)                                      Application
  Object Manager                                                    Interactive                      FINSeCustomerObjMgr_ptb
  \          Active                                                         Financial
  eCustomer Object Manager                                                                                                                                                                                                                           Siebel
  Financial Services                                                     Fins                             0
  \                       \n"
- "FINS Customer Relationship Console Object Manager (ENU)                       Application
  Object Manager                                                    Interactive                      FINSConsoleObjMgr_enu
  \            Active                                                         Siebel
  Customer Relationship Console Object Manager                                                                                                                                                                                                          Siebel
  Financial Services                                                     Fins                             0
  \                       \n"
- "FINS Customer Relationship Console Object Manager (PTB)                       Application
  Object Manager                                                    Interactive                      FINSConsoleObjMgr_ptb
  \            Active                                                         Siebel
  Customer Relationship Console Object Manager                                                                                                                                                                                                          Siebel
  Financial Services                                                     Fins                             0
  \                       \n"
- "FINS eBanking Object Manager (ENU)                                            Application
  Object Manager                                                    Interactive                      FINSeBankingObjMgr_enu
  \           Active                                                         Siebel
  FINS eBanking Object Manager                                                                                                                                                                                                                          Siebel
  Financial Services                                                     Fins                             0
  \                       \n"
- "FINS eBanking Object Manager (PTB)                                            Application
  Object Manager                                                    Interactive                      FINSeBankingObjMgr_ptb
  \           Active                                                         Siebel
  FINS eBanking Object Manager                                                                                                                                                                                                                          Siebel
  Financial Services                                                     Fins                             0
  \                       \n"
- "FINS eBrokerage Object Manager (ENU)                                          Application
  Object Manager                                                    Interactive                      FINSeBrokerageObjMgr_enu
  \         Active                                                         Siebel
  FINS eBrokerage Object Manager                                                                                                                                                                                                                        Siebel
  Financial Services                                                     Fins                             0
  \                       \n"
- "FINS eBrokerage Object Manager (PTB)                                          Application
  Object Manager                                                    Interactive                      FINSeBrokerageObjMgr_ptb
  \         Active                                                         Siebel
  FINS eBrokerage Object Manager                                                                                                                                                                                                                        Siebel
  Financial Services                                                     Fins                             0
  \                       \n"
- "FINS eChannel Object Manager (ENU)                                            Application
  Object Manager                                                    Interactive                      FINSeChannelObjMgr_enu
  \           Active                                                         Siebel
  FINS eChannel Object Manager                                                                                                                                                                                                                          Siebel
  Financial Services                                                     Fins                             0
  \                       \n"
- "FINS eChannel Object Manager (PTB)                                            Application
  Object Manager                                                    Interactive                      FINSeChannelObjMgr_ptb
  \           Active                                                         Siebel
  FINS eChannel Object Manager                                                                                                                                                                                                                          Siebel
  Financial Services                                                     Fins                             0
  \                       \n"
- "FINS eEnrollment Object Manager (ENU)                                         Application
  Object Manager                                                    Interactive                      FINSeEnrollmentObjMgr_enu
  \        Active                                                         Siebel FINS
  eEnrollment Object Manager                                                                                                                                                                                                                       Siebel
  Financial Services                                                     Fins                             0
  \                       \n"
- "FINS eEnrollment Object Manager (PTB)                                         Application
  Object Manager                                                    Interactive                      FINSeEnrollmentObjMgr_ptb
  \        Active                                                         Siebel FINS
  eEnrollment Object Manager                                                                                                                                                                                                                       Siebel
  Financial Services                                                     Fins                             0
  \                       \n"
- "FINS eSales Object Manager (ENU)                                              Application
  Object Manager                                                    Interactive                      FINSeSalesObjMgr_enu
  \             Active                                                         Siebel
  FINS eSales Object Manager                                                                                                                                                                                                                            Siebel
  Financial Services                                                     Fins                             0
  \                       \n"
- "FINS eSales Object Manager (PTB)                                              Application
  Object Manager                                                    Interactive                      FINSeSalesObjMgr_ptb
  \             Active                                                         Siebel
  FINS eSales Object Manager                                                                                                                                                                                                                            Siebel
  Financial Services                                                     Fins                             0
  \                       \n"
- "FINS Object Manager (ENU)                                                     Application
  Object Manager                                                    Interactive                      FINSObjMgr_enu
  \                   Active                                                         Siebel
  Financial Services Object Manager                                                                                                                                                                                                                     Siebel
  Financial Services                                                     Fins                             0
  \                       \n"
- "FINS Object Manager (PTB)                                                     Application
  Object Manager                                                    Interactive                      FINSObjMgr_ptb
  \                   Active                                                         Siebel
  Financial Services Object Manager                                                                                                                                                                                                                     Siebel
  Financial Services                                                     Fins                             0
  \                       \n"
- "Forecast Service Manager                                                      Business
  Service Manager                                                      Batch                            FcstSvcMgr
  \                       Active                                                         Execute
  Forecast Operations                                                                                                                                                                                                                                  Forecast
  Service Management                                                   FcstSvc                          0
  \                       \n"
- "Generate New Database                                                         Generate
  New Database                                                         Batch                            GenNewDb
  \                         Active                                                         Generates
  the Siebel Remote local database template                                                                                                                                                                                                          Siebel
  Remote                                                                 Remote                           0
  \                       \n"
- "Generate Triggers                                                             Generate
  Triggers                                                             Batch                            GenTrig
  \                          Active                                                         Generates
  triggers for Workflow Manager and Assignment Manager                                                                                                                                                                                               Workflow
  Management                                                           Workflow                         0
  \                       \n"
- "HA Upgrade MQSeries Server Receiver                                           Enterprise
  Application Integration Receiver                                   Background                       HAUpgradeMqRcvr
  \                  Active                                                         Pre-configured
  receiver for HA Upgrade in-bound MQSeries server messages                                                                                                                                                                                     Siebel
  To Siebel Connector                                                    S2S                              0
  \                       \n"
- "Handheld eCG Sales CE Synchronization Object Manager (ENU)                    Application
  Object Manager                                                    Interactive                      CGCEObjMgr_enu
  \                   Active                                                         Handheld
  eCG Sales CE Synchronization Object Manager                                                                                                                                                                                                         Handheld
  Synchronization SIA                                                  HandheldSyncSIS
  \                 0                        \n"
- "Handheld eCG Sales CE Synchronization Object Manager (PTB)                    Application
  Object Manager                                                    Interactive                      CGCEObjMgr_ptb
  \                   Active                                                         Handheld
  eCG Sales CE Synchronization Object Manager                                                                                                                                                                                                         Handheld
  Synchronization SIA                                                  HandheldSyncSIS
  \                 0                        \n"
- "Handheld ePharma CE Synchronization Object Manager (ENU)                      Application
  Object Manager                                                    Interactive                      ePharmaCEObjMgr_enu
  \              Active                                                         Handheld
  ePharma CE Synchronization Object Manager                                                                                                                                                                                                           Handheld
  Synchronization SIA                                                  HandheldSyncSIS
  \                 0                        \n"
- "Handheld ePharma CE Synchronization Object Manager (PTB)                      Application
  Object Manager                                                    Interactive                      ePharmaCEObjMgr_ptb
  \              Active                                                         Handheld
  ePharma CE Synchronization Object Manager                                                                                                                                                                                                           Handheld
  Synchronization SIA                                                  HandheldSyncSIS
  \                 0                        \n"
- "Handheld Medical CE Synchronization Object Manager (ENU)                      Application
  Object Manager                                                    Interactive                      MedicalCEObjMgr_enu
  \              Active                                                         Handheld
  Medical CE Synchronization Object Manager                                                                                                                                                                                                           Handheld
  Synchronization SIA                                                  HandheldSyncSIS
  \                 0                        \n"
- "Handheld Medical CE Synchronization Object Manager (PTB)                      Application
  Object Manager                                                    Interactive                      MedicalCEObjMgr_ptb
  \              Active                                                         Handheld
  Medical CE Synchronization Object Manager                                                                                                                                                                                                           Handheld
  Synchronization SIA                                                  HandheldSyncSIS
  \                 0                        \n"
- "Handheld Sales CE (ENU)                                                       Application
  Object Manager                                                    Interactive                      SalesCEObjMgr_enu
  \                Active                                                         Handheld
  Sales CE Object Manager                                                                                                                                                                                                                             Handheld
  Synchronization                                                      HandheldSync
  \                    0                        \n"
- "Handheld Sales CE (PTB)                                                       Application
  Object Manager                                                    Interactive                      SalesCEObjMgr_ptb
  \                Active                                                         Handheld
  Sales CE Object Manager                                                                                                                                                                                                                             Handheld
  Synchronization                                                      HandheldSync
  \                    0                        \n"
- "Handheld SIA Sales Synchronization Object Manager (ENU)                       Application
  Object Manager                                                    Interactive                      SIASalesCEObjMgr_enu
  \             Active                                                         Handheld
  SIA Sales Synchronization Object Manager                                                                                                                                                                                                            Handheld
  Synchronization SIA                                                  HandheldSyncSIS
  \                 0                        \n"
- "Handheld SIA Sales Synchronization Object Manager (PTB)                       Application
  Object Manager                                                    Interactive                      SIASalesCEObjMgr_ptb
  \             Active                                                         Handheld
  SIA Sales Synchronization Object Manager                                                                                                                                                                                                            Handheld
  Synchronization SIA                                                  HandheldSyncSIS
  \                 0                        \n"
- "Handheld SIA Service Synchronization Object Manager (ENU)                     Application
  Object Manager                                                    Interactive                      SIAServiceCEObjMgr_enu
  \           Active                                                         Handheld
  SIA Service Synchronization Object Manager                                                                                                                                                                                                          Handheld
  Synchronization SIA                                                  HandheldSyncSIS
  \                 0                        \n"
- "Handheld SIA Service Synchronization Object Manager (PTB)                     Application
  Object Manager                                                    Interactive                      SIAServiceCEObjMgr_ptb
  \           Active                                                         Handheld
  SIA Service Synchronization Object Manager                                                                                                                                                                                                          Handheld
  Synchronization SIA                                                  HandheldSyncSIS
  \                 0                        \n"
- "Hospitality Quote Generation                                                  Business
  Service Manager                                                      Batch                            HospitalityQuoteGen
  \              Active                                                         Generates
  Hospitality quotes asynchronously                                                                                                                                                                                                                  Siebel
  eHospitality                                                           Hospitality
  \                     0                        \n"
- "HTIM Object Manager (ENU)                                                     Application
  Object Manager                                                    Interactive                      htimObjMgr_enu
  \                   Active                                                         Siebel
  HTIM Object Manager                                                                                                                                                                                                                                   Siebel
  High Tech Industrial Manufacturing                                     HTIM                             0
  \                       \n"
- "HTIM Object Manager (PTB)                                                     Application
  Object Manager                                                    Interactive                      htimObjMgr_ptb
  \                   Active                                                         Siebel
  HTIM Object Manager                                                                                                                                                                                                                                   Siebel
  High Tech Industrial Manufacturing                                     HTIM                             0
  \                       \n"
- "HTIM PRM Object Manager (ENU)                                                 Application
  Object Manager                                                    Interactive                      htimprmObjMgr_enu
  \                Active                                                         Siebel
  HTIM PRM Object Manager                                                                                                                                                                                                                               Siebel
  High Tech Industrial Manufacturing                                     HTIM                             0
  \                       \n"
- "HTIM PRM Object Manager (PTB)                                                 Application
  Object Manager                                                    Interactive                      htimprmObjMgr_ptb
  \                Active                                                         Siebel
  HTIM PRM Object Manager                                                                                                                                                                                                                               Siebel
  High Tech Industrial Manufacturing                                     HTIM                             0
  \                       \n"
- "ICM Calc Engine                                                               Incentive
  Compensation Mgr                                                    Batch                            ICMCalcEngine
  \                    Active                                                         Incentive
  Compensation - Compensation Calculation                                                                                                                                                                                                            Incentive
  Compensation                                                        IComp                            0
  \                       \n"
- "ICM CalcWkbk Import                                                           Incentive
  Compensation Mgr                                                    Batch                            ICMCalcImport
  \                    Active                                                         Incentive
  Compensation - Transaction to Calculation Workbook processor                                                                                                                                                                                       Incentive
  Compensation                                                        IComp                            0
  \                       \n"
- "ICM Container Calculation                                                     Incentive
  Compensation Mgr                                                    Batch                            ICMContainerCalc
  \                 Active                                                         Incentive
  Compensation - Container Calculation                                                                                                                                                                                                               Incentive
  Compensation                                                        IComp                            0
  \                       \n"
- "ICM Container Recalculation                                                   Incentive
  Compensation Mgr                                                    Batch                            ICMContainerRetro
  \                Active                                                         Incentive
  Compensation - Container Recalculation                                                                                                                                                                                                             Incentive
  Compensation                                                        IComp                            0
  \                       \n"
- "ICM Order Import                                                              Incentive
  Compensation Mgr                                                    Batch                            ICMOrderImport
  \                   Active                                                         Incentive
  Compensation - Order to Transaction Workbook processor                                                                                                                                                                                             Incentive
  Compensation                                                        IComp                            0
  \                       \n"
- "ICM Quota Import                                                              Incentive
  Compensation Mgr                                                    Batch                            ICMQuotaImport
  \                   Active                                                         Incentive
  Compensation - Plan Quota Import                                                                                                                                                                                                                   Incentive
  Compensation                                                        IComp                            0
  \                       \n"
- "Incentive Compensation Credit Assignment DB Operations Bus Svc                Business
  Service Manager                                                      Batch                            ICompCreditAsgnDB
  \                Active                                                         Incentive
  Compensation Credit Assignment DB Operations Bus Svc                                                                                                                                                                                               Sales
  Credit Assignment                                                       CreditAsgn
  \                      0                        \n"
- "Incentive Compensation Credit Assignment Engine                               IComp
  Credit Assignment Engine                                                Batch                            ICompCreditAsgn
  \                  Active                                                         Calculates
  Credit Assignments for Incentive Compensation                                                                                                                                                                                                     Sales
  Credit Assignment                                                       CreditAsgn
  \                      0                        \n"
- "Incentive Compensation Credit Rules to AM Rules Update Mgr                    Batch
  Real-Time Integration                                                   Batch                            ICompCreditUpMgr
  \                 Active                                                         Updates
  and Creates AM Rules using RTI                                                                                                                                                                                                                       Sales
  Credit Assignment                                                       CreditAsgn
  \                      0                        \n"
- "Incentive Compensation Mgr                                                    Incentive
  Compensation Mgr                                                    Batch                            ICompMgr
  \                         Active                                                         Calculates
  Incentive Compensations                                                                                                                                                                                                                           Incentive
  Compensation                                                        IComp                            0
  \                       \n"
- "Incentive Compensation Rule Manager Business Svc                              Business
  Service Manager                                                      Batch                            ICompRuleMgrSvc
  \                  Active                                                         Converts
  Sales Crediting Rules into AM Rules for each Hierarchy                                                                                                                                                                                              Sales
  Credit Assignment                                                       CreditAsgn
  \                      0                        \n"
- "Insurance eService Object Manager (ENU)                                       Application
  Object Manager                                                    Interactive                      INSeServiceObjMgr_enu
  \            Active                                                         Insurance
  eService Object Manager                                                                                                                                                                                                                            Siebel
  Financial Services                                                     Fins                             0
  \                       \n"
- "Insurance eService Object Manager (PTB)                                       Application
  Object Manager                                                    Interactive                      INSeServiceObjMgr_ptb
  \            Active                                                         Insurance
  eService Object Manager                                                                                                                                                                                                                            Siebel
  Financial Services                                                     Fins                             0
  \                       \n"
- "JMS Receiver                                                                  Enterprise
  Application Integration Receiver                                   Background                       JMSReceiver
  \                      Active                                                         Pre-configured
  receiver for inbound JMS messages                                                                                                                                                                                                             Enterprise
  Application Integration                                            EAI                              0
  \                       \n"
- "List Import Service Manager                                                   Business
  Service Manager                                                      Batch                            ListImportSvcMgr
  \                 Active                                                         Loads
  files for list manager(OM Based)                                                                                                                                                                                                                       Marketing
  Server                                                              MktgSrv                          0
  \                       \n"
- "Loyalty eMember Object Manager (ENU)                                          Application
  Object Manager                                                    Interactive                      eloyaltyObjMgr_enu
  \               Active                                                         Siebel
  Loyalty eMember Object Manager                                                                                                                                                                                                                        Siebel
  Loyalty                                                                Loyalty                          0
  \                       \n"
- "Loyalty eMember Object Manager (PTB)                                          Application
  Object Manager                                                    Interactive                      eloyaltyObjMgr_ptb
  \               Active                                                         Siebel
  Loyalty eMember Object Manager                                                                                                                                                                                                                        Siebel
  Loyalty                                                                Loyalty                          0
  \                       \n"
- "Loyalty Object Manager (ENU)                                                  Application
  Object Manager                                                    Interactive                      loyaltyObjMgr_enu
  \                Active                                                         Siebel
  Loyalty Object Manager                                                                                                                                                                                                                                Siebel
  Loyalty                                                                Loyalty                          0
  \                       \n"
- "Loyalty Object Manager (PTB)                                                  Application
  Object Manager                                                    Interactive                      loyaltyObjMgr_ptb
  \                Active                                                         Siebel
  Loyalty Object Manager                                                                                                                                                                                                                                Siebel
  Loyalty                                                                Loyalty                          0
  \                       \n"
- "Loyalty Partner Portal Object Manager (ENU)                                   Application
  Object Manager                                                    Interactive                      loyaltyscwObjMgr_enu
  \             Active                                                         Siebel
  Loyalty Partner Portal Object Manager                                                                                                                                                                                                                 Siebel
  Loyalty                                                                Loyalty                          0
  \                       \n"
- "Loyalty Partner Portal Object Manager (PTB)                                   Application
  Object Manager                                                    Interactive                      loyaltyscwObjMgr_ptb
  \             Active                                                         Siebel
  Loyalty Partner Portal Object Manager                                                                                                                                                                                                                 Siebel
  Loyalty                                                                Loyalty                          0
  \                       \n"
- "Marketing Object Manager (ENU)                                                Application
  Object Manager                                                    Interactive                      SMObjMgr_enu
  \                     Active                                                         Siebel
  Marketing Object Manager                                                                                                                                                                                                                              Marketing
  Object Manager                                                      MktgOM                           0
  \                       \n"
- "Marketing Object Manager (PTB)                                                Application
  Object Manager                                                    Interactive                      SMObjMgr_ptb
  \                     Active                                                         Siebel
  Marketing Object Manager                                                                                                                                                                                                                              Marketing
  Object Manager                                                      MktgOM                           0
  \                       \n"
- "MQSeries AMI Receiver                                                         Enterprise
  Application Integration Receiver                                   Background                       MqSeriesAMIRcvr
  \                  Inactive                                                       Pre-configured
  receiver for in-bound MQSeries AMI messages                                                                                                                                                                                                   Enterprise
  Application Integration                                            EAI                              0
  \                       \n"
- "MQSeries Server Receiver                                                      Enterprise
  Application Integration Receiver                                   Background                       MqSeriesSrvRcvr
  \                  Inactive                                                       Pre-configured
  receiver for in-bound MQSeries server messages                                                                                                                                                                                                Enterprise
  Application Integration                                            EAI                              0
  \                       \n"
- "MSMQ Receiver                                                                 Enterprise
  Application Integration Receiver                                   Background                       MSMQRcvr
  \                         Inactive                                                       Pre-configured
  receiver for in-bound MSMQ server messages                                                                                                                                                                                                    Enterprise
  Application Integration                                            EAI                              0
  \                       \n"
- "Optimization Engine                                                           Business
  Service Manager                                                      Batch                            Optimizer
  \                        Active                                                         Optimize
  vehicle routing                                                                                                                                                                                                                                     Field
  Service                                                                 FieldSvc
  \                        0                        \n"
- "Oracle Receiver                                                               Enterprise
  Application Integration Connector Receiver                         Background                       ORCLRcvr
  \                         Active                                                         Pre-configured
  receiver for in-bound Oracle                                                                                                                                                                                                                  Oracle
  Connector                                                              ORCL                             0
  \                       \n"
- "Page Manager                                                                  Page
  Manager                                                                  Background
  \                      PageMgr                           Active                                                         Sends
  outbound pages                                                                                                                                                                                                                                         Communications
  Management                                                     CommMgmt                         0
  \                       \n"
- "Parallel Database Extract                                                     Database
  Extract                                                              Batch                            PDbXtract
  \                        Active                                                         Extracts
  visible data for a Siebel Remote or Replication Manager client                                                                                                                                                                                      Siebel
  Remote                                                                 Remote                           0
  \                       \n"
- "Partner Manager Object Manager (ENU)                                          Application
  Object Manager                                                    Interactive                      PManagerObjMgr_enu
  \               Active                                                         Siebel
  Partner Manager Object Manager                                                                                                                                                                                                                        Siebel
  eChannel                                                               eChannel
  \                        0                        \n"
- "Partner Manager Object Manager (PTB)                                          Application
  Object Manager                                                    Interactive                      PManagerObjMgr_ptb
  \               Active                                                         Siebel
  Partner Manager Object Manager                                                                                                                                                                                                                        Siebel
  eChannel                                                               eChannel
  \                        0                        \n"
- "PIMSI Dispatcher                                                              Business
  Service Manager                                                      Batch                            PIMSIDispatcher
  \                  Active                                                         Executes
  real-time Business Processes                                                                                                                                                                                                                        PIM
  Server Integration Management                                             PIMSI
  \                           0                        \n"
- "PIMSI Engine                                                                  Business
  Service Manager                                                      Batch                            PIMSIEng
  \                         Active                                                         Executes
  real-time Business Processes                                                                                                                                                                                                                        PIM
  Server Integration Management                                             PIMSI
  \                           0                        \n"
- "Preventive Maintenance Engine                                                 Business
  Service Manager                                                      Batch                            FSPrevMnt
  \                        Active                                                         Generates
  SRs and activities for preventive maintenanance                                                                                                                                                                                                    Field
  Service                                                                 FieldSvc
  \                        0                        \n"
- "Public Sector eService Object Manager (ENU)                                   Application
  Object Manager                                                    Interactive                      PSeServiceObjMgr_enu
  \             Active                                                         Siebel
  Public Sector eService Object Manager                                                                                                                                                                                                                 Siebel
  Public Sector                                                          PublicSector
  \                    0                        \n"
- "Public Sector eService Object Manager (PTB)                                   Application
  Object Manager                                                    Interactive                      PSeServiceObjMgr_ptb
  \             Active                                                         Siebel
  Public Sector eService Object Manager                                                                                                                                                                                                                 Siebel
  Public Sector                                                          PublicSector
  \                    0                        \n"
- "Public Sector Object Manager (ENU)                                            Application
  Object Manager                                                    Interactive                      PSCcObjMgr_enu
  \                   Active                                                         Siebel
  Public Sector Object Manager                                                                                                                                                                                                                          Siebel
  Public Sector                                                          PublicSector
  \                    0                        \n"
- "Public Sector Object Manager (PTB)                                            Application
  Object Manager                                                    Interactive                      PSCcObjMgr_ptb
  \                   Active                                                         Siebel
  Public Sector Object Manager                                                                                                                                                                                                                          Siebel
  Public Sector                                                          PublicSector
  \                    0                        \n"
- "Real Time Sync Data Extractor                                                 Business
  Service Manager                                                      Batch                            RTSExtractor
  \                     Active                                                         Extracts
  data for RTS messages                                                                                                                                                                                                                               MWC
  Real Time Sync                                                            RTSRemote
  \                       0                        \n"
- "Real Time Sync Message Sender                                                 Business
  Service Manager                                                      Batch                            RTSSender
  \                        Active                                                         Sends
  RTS messages via SMQ                                                                                                                                                                                                                                   MWC
  Real Time Sync                                                            RTSRemote
  \                       0                        \n"
- "Real Time Sync Transaction Applier                                            Business
  Service Manager                                                      Batch                            RTSQApplier
  \                      Active                                                         Apply
  inbound transactions uploaded from Mobile Clients                                                                                                                                                                                                      MWC
  Real Time Sync                                                            RTSRemote
  \                       0                        \n"
- "Real Time Sync Transaction Dispatcher                                         RTS
  Transaction Dispatcher                                                    Background
  \                      RTSDispatcher                     Active                                                         Dispatch
  Critial Transactions to the Mobile Client                                                                                                                                                                                                           MWC
  Real Time Sync                                                            RTSRemote
  \                       0                        \n"
- "Replication Agent                                                             Replication
  Agent                                                             Background                       RepAgent
  \                         Active                                                         Synchronizes
  a Replication Manager regional database                                                                                                                                                                                                         Siebel
  Remote                                                                 Remote                           0
  \                       \n"
- "RTI Batch                                                                     Batch
  Real-Time Integration                                                   Batch                            RTIBatch
  \                         Active                                                         Executes
  SQL's in batch                                                                                                                                                                                                                                      Siebel
  RTI                                                                    RTI                              0
  \                       \n"
- "Sales Hierarchy Service Manager                                               Business
  Service Manager                                                      Batch                            SalesHierSvcMgr
  \                  Active                                                         Execute
  Sales Hierarchy Service Operations                                                                                                                                                                                                                   Sales
  Hierarchy Service                                                       SalesHierSvc
  \                    0                        \n"
- "Sales Object Manager (ENU)                                                    Application
  Object Manager                                                    Interactive                      SSEObjMgr_enu
  \                    Active                                                         Siebel
  Sales Object Manager                                                                                                                                                                                                                                  Siebel
  Sales                                                                  Sales                            0
  \                       \n"
- "Sales Object Manager (PTB)                                                    Application
  Object Manager                                                    Interactive                      SSEObjMgr_ptb
  \                    Active                                                         Siebel
  Sales Object Manager                                                                                                                                                                                                                                  Siebel
  Sales                                                                  Sales                            0
  \                       \n"
- "SAP BAPI tRFC Receiver                                                        Enterprise
  Application Integration Connector Receiver                         Background                       BAPIRcvr
  \                         Active                                                         Pre-configured
  receiver for in-bound SAP IDOCs and tRFC calls                                                                                                                                                                                                SAP
  Connector                                                                 SAP                              0
  \                       \n"
- "SAP IDOC AMI Receiver for MQ Series                                           Enterprise
  Application Integration Receiver                                   Background                       SAPIdocAMIMqRcvr
  \                 Active                                                         Pre-configured
  receiver for in-bound SAP IDOCs via AMI MQSeries                                                                                                                                                                                              SAP
  Connector                                                                 SAP                              0
  \                       \n"
- "SAP IDOC Receiver for MQ Series                                               Enterprise
  Application Integration Receiver                                   Background                       SAPIdocMqRcvr
  \                    Active                                                         Pre-configured
  receiver for in-bound SAP IDOCs via MQSeries                                                                                                                                                                                                  SAP
  Connector                                                                 SAP                              0
  \                       \n"
- "SAP Process Transaction                                                       Enterprise
  Application Integration Connector Receiver                         Background                       SAPProcessTrans
  \                  Active                                                         Pre-configured
  Service to reprocess transactions into Siebel from EAI Queue                                                                                                                                                                                  SAP
  Connector                                                                 SAP                              0
  \                       \n"
- "SAP Send Transaction                                                          Enterprise
  Application Integration Connector Receiver                         Background                       SAPSendTrans
  \                     Active                                                         Pre-configured
  service resends transactions from the EAI Queue                                                                                                                                                                                               SAP
  Connector                                                                 SAP                              0
  \                       \n"
- "Search Data Processor                                                         Business
  Service Manager                                                      Batch                            SearchDataProcessor
  \              Active                                                         Prcoesses
  Search data and builds index                                                                                                                                                                                                                       Search
  Processing                                                             Search                           0
  \                       \n"
- "Search Incremental Index Processor                                            Business
  Service Manager                                                      Batch                            SearchIncrementalIndexProcessor
  \  Active                                                         Prcoesses Search
  data and updates/builds index incrementally                                                                                                                                                                                                 Search
  Processing                                                             Search                           0
  \                       \n"
- "FOO Asset PEFIN REFIN Canceled Monitor                                        Workflow
  Monitor Agent                                                        Background
  \                      FOOAssetPERCMon                   Active                                                                                                                                                                                                                                                                                                                      Workflow
  Management                                                           Workflow                         0
  \                       \n"
- "FOO Workflow Monitor Agent Asset                                              Workflow
  Monitor Agent                                                        Background
  \                      FOOWorkMonAsset                   Active                                                                                                                                                                                                                                                                                                                      Workflow
  Management                                                           Workflow                         0
  \                       \n"
- "FOO Workflow Monitor Agent Order Item                                         Workflow
  Monitor Agent                                                        Background
  \                      FOOWorkMonOrderItem               Active                                                                                                                                                                                                                                                                                                                      Workflow
  Management                                                           Workflow                         0
  \                       \n"
- "Server Manager                                                                Server
  Manager                                                                Interactive
  \                     ServerMgr                         Active                                                         Administers
  the Siebel Server                                                                                                                                                                                                                                System
  Management                                                             System                           0
  \                       \n"
- "Server Request Broker                                                         Server
  Request Broker                                                         Interactive
  \                     SRBroker                          Active                                                         Route
  requests and asynchronous notification among clients and components                                                                                                                                                                                    System
  Management                                                             System                           0
  \                       \n"
- "Server Request Processor                                                      Server
  Request Processor (SRP)                                                Interactive
  \                     SRProc                            Active                                                         Server
  Request scheduler and request/notification store and forward processor                                                                                                                                                                                Auxiliary
  System Management                                                   SystemAux                        0
  \                       \n"
- "Server Tables Cleanup                                                         Business
  Service Manager                                                      Background
  \                      SvrTblCleanup                     Active                                                         Deletes
  completed and expired Server Request records                                                                                                                                                                                                         Auxiliary
  System Management                                                   SystemAux                        0
  \                       \n"
- "Server Task Persistance                                                       Business
  Service Manager                                                      Background
  \                      SvrTaskPersist                    Active                                                         Persists
  all the tasks created by the siebel server                                                                                                                                                                                                          Auxiliary
  System Management                                                   SystemAux                        0
  \                       \n"
- "Service Order Fulfillment Engine                                              Business
  Service Manager                                                      Batch                            FSFulfill
  \                        Active                                                         Fulfill
  pending Service Orders                                                                                                                                                                                                                               Field
  Service                                                                 FieldSvc
  \                        0                        \n"
- "Service Order Part Locator Engine                                             Business
  Service Manager                                                      Batch                            FSLocate
  \                         Active                                                         Locate
  pending Service Orders                                                                                                                                                                                                                                Field
  Service                                                                 FieldSvc
  \                        0                        \n"
- "SIA Marketing Object Manager (ENU)                                            Application
  Object Manager                                                    Interactive                      sismeObjMgr_enu
  \                  Active                                                         Siebel
  Industry Marketing Object Manager                                                                                                                                                                                                                     Siebel
  Industry Marketing                                                     SISME                            0
  \                       \n"
- "SIA Marketing Object Manager (PTB)                                            Application
  Object Manager                                                    Interactive                      sismeObjMgr_ptb
  \                  Active                                                         Siebel
  Industry Marketing Object Manager                                                                                                                                                                                                                     Siebel
  Industry Marketing                                                     SISME                            0
  \                       \n"
- "Siebel Administrator Notification Component                                   Siebel
  Administrator Notification Component                                   Batch                            AdminNotify
  \                      Active                                                         To
  notify the administrator in case problems are detected with Siebel server and running
  components                                                                                                                                                          Auxiliary
  System Management                                                   SystemAux                        0
  \                       \n"
- "Siebel Connection Broker                                                      Siebel
  Connection Broker                                                      Background
  \                      SCBroker                          Active                                                         Route
  and load balance connections to components                                                                                                                                                                                                             System
  Management                                                             System                           0
  \                       \n"
- "Siebel eChannel Wireless (ENU)                                                Application
  Object Manager                                                    Interactive                      WirelesseChannelObjMgr_enu
  \       Active                                                         Siebel eChannel
  Wireless Object Manager                                                                                                                                                                                                                      Siebel
  Wireless                                                               Wireless
  \                        0                        \n"
- "Siebel eChannel Wireless (PTB)                                                Application
  Object Manager                                                    Interactive                      WirelesseChannelObjMgr_ptb
  \       Active                                                         Siebel eChannel
  Wireless Object Manager                                                                                                                                                                                                                      Siebel
  Wireless                                                               Wireless
  \                        0                        \n"
- "Siebel Mobile Connector Object Manager (ENU)                                  Application
  Object Manager                                                    Interactive                      SMCObjMgr_enu
  \                    Active                                                         Siebel
  Mobile Connector Object Manager                                                                                                                                                                                                                       Siebel
  Sales                                                                  Sales                            0
  \                       \n"
- "Siebel Mobile Connector Object Manager (PTB)                                  Application
  Object Manager                                                    Interactive                      SMCObjMgr_ptb
  \                    Active                                                         Siebel
  Mobile Connector Object Manager                                                                                                                                                                                                                       Siebel
  Sales                                                                  Sales                            0
  \                       \n"
- "Siebel Product Configuration Object Manager (ENU)                             Application
  Object Manager                                                    Interactive                      eProdCfgObjMgr_enu
  \               Active                                                         Configuration
  server for complex products                                                                                                                                                                                                                    Siebel
  ISS                                                                    ISS                              0
  \                       \n"
- "Siebel Product Configuration Object Manager (PTB)                             Application
  Object Manager                                                    Interactive                      eProdCfgObjMgr_ptb
  \               Active                                                         Configuration
  server for complex products                                                                                                                                                                                                                    Siebel
  ISS                                                                    ISS                              0
  \                       \n"
- "Siebel Sales Wireless (ENU)                                                   Application
  Object Manager                                                    Interactive                      WirelessSalesObjMgr_enu
  \          Active                                                         Siebel
  Sales Wireless Object Manager                                                                                                                                                                                                                         Siebel
  Wireless                                                               Wireless
  \                        0                        \n"
- "Siebel Sales Wireless (PTB)                                                   Application
  Object Manager                                                    Interactive                      WirelessSalesObjMgr_ptb
  \          Active                                                         Siebel
  Sales Wireless Object Manager                                                                                                                                                                                                                         Siebel
  Wireless                                                               Wireless
  \                        0                        \n"
- "Siebel Self Service Wireless (ENU)                                            Application
  Object Manager                                                    Interactive                      WirelesseServiceObjMgr_enu
  \       Active                                                         Siebel Self
  Service Wireless Object Manager                                                                                                                                                                                                                  Siebel
  Wireless                                                               Wireless
  \                        0                        \n"
- "Siebel Self Service Wireless (PTB)                                            Application
  Object Manager                                                    Interactive                      WirelesseServiceObjMgr_ptb
  \       Active                                                         Siebel Self
  Service Wireless Object Manager                                                                                                                                                                                                                  Siebel
  Wireless                                                               Wireless
  \                        0                        \n"
- "Siebel Server                                                                 Siebel
  Server                                                                 Background
  \                      SiebSrvr                          Active                                                         Siebel
  Server root process and network listener                                                                                                                                                                                                              System
  Management                                                             System                           0
  \                       \n"
- "Siebel Server Scheduler                                                       Siebel
  Server Scheduler                                                       Background
  \                      SrvrSched                         Active                                                         Schedules
  Siebel Server job execution                                                                                                                                                                                                                        System
  Management                                                             System                           0
  \                       \n"
- "Siebel Service Handheld 7.5 (ENU)                                             Application
  Object Manager                                                    Interactive                      ServiceCEObjMgr_enu
  \              Active                                                         siebel
  Service Handheld 7.5                                                                                                                                                                                                                                  Handheld
  Synchronization                                                      HandheldSync
  \                    0                        \n"
- "Siebel Service Handheld 7.5 (PTB)                                             Application
  Object Manager                                                    Interactive                      ServiceCEObjMgr_ptb
  \              Active                                                         siebel
  Service Handheld 7.5                                                                                                                                                                                                                                  Handheld
  Synchronization                                                      HandheldSync
  \                    0                        \n"
- "Siebel Service Wireless (ENU)                                                 Application
  Object Manager                                                    Interactive                      WirelessServiceObjMgr_enu
  \        Active                                                         Siebel Service
  Wireless Object Manager                                                                                                                                                                                                                       Siebel
  Wireless                                                               Wireless
  \                        0                        \n"
- "Siebel Service Wireless (PTB)                                                 Application
  Object Manager                                                    Interactive                      WirelessServiceObjMgr_ptb
  \        Active                                                         Siebel Service
  Wireless Object Manager                                                                                                                                                                                                                       Siebel
  Wireless                                                               Wireless
  \                        0                        \n"
- "Siebel to Siebel MQSeries Receiver                                            Enterprise
  Application Integration Receiver                                   Background                       S2SMqRcvr
  \                        Active                                                         Pre-configured
  receiver for Siebel to Siebel in-bound MQSeries server messages                                                                                                                                                                               Siebel
  To Siebel Connector                                                    S2S                              0
  \                       \n"
- "Siebel to Siebel MSMQ Receiver                                                Enterprise
  Application Integration Receiver                                   Background                       S2SMSMQRcvr
  \                      Active                                                         Pre-configured
  receiver for Siebel to Siebel in-bound MSMQ server messages                                                                                                                                                                                   Siebel
  To Siebel Connector                                                    S2S                              0
  \                       \n"
- "Smart Answer Manager                                                          Business
  Service Manager                                                      Batch                            SmartAnswer
  \                      Active                                                         Categorize
  Text Message                                                                                                                                                                                                                                      Communications
  Management                                                     CommMgmt                         0
  \                       \n"
- "SMQ Receiver                                                                  Enterprise
  Application Integration Receiver                                   Background                       SMQReceiver
  \                      Inactive                                                       Pre-configured
  receiver for in-bound SMQ messages                                                                                                                                                                                                            Enterprise
  Application Integration                                            EAI                              0
  \                       \n"
- "Synchronization Manager                                                       Synchronization
  Manager                                                       Interactive                      SynchMgr
  \                         Active                                                         Manages
  Siebel Remote and Replication Manager synch sessions                                                                                                                                                                                                 Siebel
  Remote                                                                 Remote                           0
  \                       \n"
- "Task Log Cleanup                                                              Business
  Service Manager                                                      Background
  \                      TaskLogCleanup                    Active                                                         Task
  Log Cleanup Business Service                                                                                                                                                                                                                            Task
  UI                                                                       TaskUI
  \                          0                        \n"
- "Transaction Merger                                                            Transaction
  Merger                                                            Background                       TxnMerge
  \                         Active                                                         Merges
  transactions from Siebel Remote and Replication Manager clients                                                                                                                                                                                       Siebel
  Remote                                                                 Remote                           0
  \                       \n"
- "Transaction Processor                                                         Transaction
  Processor                                                         Background                       TxnProc
  \                          Active                                                         Prepares
  the transaction log for the Transaction Router                                                                                                                                                                                                      Siebel
  Remote                                                                 Remote                           0
  \                       \n"
- "Transaction Router                                                            Transaction
  Router                                                            Background                       TxnRoute
  \                         Active                                                         Routes
  visible transactions to Siebel Remote and Replication Manager clients                                                                                                                                                                                 Siebel
  Remote                                                                 Remote                           0
  \                       \n"
- "UCM Batch Manager                                                             Business
  Service Manager                                                      Batch                            UCMBatchProcess
  \                  Active                                                         UCM
  Batch Manager in the background.                                                                                                                                                                                                                         Siebel
  Universal Customer Master                                              UCM                              0
  \                       \n"
- "UCM Batch Publish Subscribe                                                   Business
  Service Manager                                                      Batch                            UCMBatchPubSub
  \                   Active                                                         UCM
  Daily Batch Publish Subscribe in the background.                                                                                                                                                                                                         Siebel
  Universal Customer Master                                              UCM                              0
  \                       \n"
- "UCM Object Manager (ENU)                                                      Application
  Object Manager                                                    Interactive                      UCMObjMgr_enu
  \                    Active                                                         Siebel
  Universal Customer Master Object Manager                                                                                                                                                                                                              Siebel
  Universal Customer Master                                              UCM                              0
  \                       \n"
- "UCM Object Manager (PTB)                                                      Application
  Object Manager                                                    Interactive                      UCMObjMgr_ptb
  \                    Active                                                         Siebel
  Universal Customer Master Object Manager                                                                                                                                                                                                              Siebel
  Universal Customer Master                                              UCM                              0
  \                       \n"
- "Upgrade Kit Builder                                                           Business
  Service Manager                                                      Batch                            UpgKitBldr
  \                       Active                                                         Creates
  the Upgrade Kit based on information collected by the Kit Wizard UI                                                                                                                                                                                  Siebel
  Anywhere                                                               SiebAnywhere
  \                    0                        \n"
- "Workflow Action Agent                                                         Workflow
  Action Agent                                                         Background
  \                      WorkActn                          Active                                                         Executes
  Workflow Manager actions                                                                                                                                                                                                                            Workflow
  Management                                                           Workflow                         0
  \                       \n"
- "Workflow Monitor Agent                                                        Workflow
  Monitor Agent                                                        Background
  \                      WorkMon                           Active                                                         Monitors
  Workflow Manager events                                                                                                                                                                                                                             Workflow
  Management                                                           Workflow                         0
  \                       \n"
- "Workflow Monitor Agent SWI                                                    Workflow
  Monitor Agent                                                        Background
  \                      WorkMonSWI                        Active                                                                                                                                                                                                                                                                                                                      Workflow
  Management                                                           Workflow                         0
  \                       \n"
- "Workflow Process Batch Manager                                                Business
  Service Manager                                                      Batch                            WfProcBatchMgr
  \                   Active                                                         Executes
  Business Processes in batch                                                                                                                                                                                                                         Workflow
  Management                                                           Workflow                         0
  \                       \n"
- "Workflow Process Manager                                                      Business
  Service Manager                                                      Batch                            WfProcMgr
  \                        Active                                                         Executes
  real-time Business Processes                                                                                                                                                                                                                        Workflow
  Management                                                           Workflow                         0
  \                       \n"
- "Workflow Recovery Manager                                                     Business
  Service Manager                                                      Batch                            WfRecvMgr
  \                        Active                                                         Recovers
  interrupted Business Processes due to server failures                                                                                                                                                                                               Workflow
  Management                                                           Workflow                         0
  \                       \n"
- "XMLP Report Server                                                            Business
  Service Manager                                                      Batch                            XMLPReportServer
  \                 Active                                                         Generates
  Reports                                                                                                                                                                                                                                            XMLP
  Report                                                                   XMLPReport
  \                      0                        \n"
- "\n"
- "255 rows returned.\n"
list_comp_def_srproc:
- "\n"
- "CC_NAME                                                                       CT_NAME
  \                                                                      CC_RUNMODE
  \                      CC_ALIAS                         CC_DISP_ENABLE_ST                                              CC_DESC_TEXT
  \                                                                                                                                                                                                                                                CG_NAME
  \                                                                      CG_ALIAS
  \                        CC_INCARN_NO             \n"
- "----------------------------------------------------------------------------  ----------------------------------------------------------------------------
  \ -------------------------------  -------------------------------  -------------------------------------------------------------
  \ --------------------------------------------------------------------------------------------------------------------
  \ ----------------------------------------------------------------------------  -------------------------------
  \ -----------------------  \n"
- "Server Request Processor                                                      Server
  Request Processor (SRP)                                                Interactive
  \                     SRProc                           Active                                                         Server
  Request scheduler and request/notification store and forward processor                                                                                                                                                                                Auxiliary
  System Management                                                   SystemAux                        0
  \                       \n"
- "\n"
- "1 row returned.\n"
- "\n"
list_comp_types:
- "\n"
- "CT_NAME                                                                       CT_RUNMODE
  \                      CT_ALIAS                                                       CT_DESC_TEXT
  \                                                                                                                                                                                                                                                \n"
- "----------------------------------------------------------------------------  -------------------------------
  \ -------------------------------------------------------------  --------------------------------------------------------------------------------------------------------------------
  \ \n"
- "ABO Bulk Request GoToView Svc                                                 Batch
  \                           ABO Bulk Request GoToView Svc                                  ABO
  Bulk Request GoToView Svc Service                                                                                                                                                                                                                        \n"
- "ABO Bulk Request GoToView Svc                                                 Background
  \                      ABO Bulk Request GoToView Svc                                  ABO
  Bulk Request GoToView Svc Service                                                                                                                                                                                                                        \n"
- "ABO Bulk Request Import Service                                               Batch
  \                           ABO Bulk Request Import Service                                ABO
  Bulk Request Import Service Service                                                                                                                                                                                                                      \n"
- "ABO Bulk Request Import Service                                               Background
  \                      ABO Bulk Request Import Service                                ABO
  Bulk Request Import Service Service                                                                                                                                                                                                                      \n"
- "ABO Bulk Request Processing Service                                           Batch
  \                           ABO Bulk Request Processing Service                            ABO
  Bulk Request Processing Service Service                                                                                                                                                                                                                  \n"
- "ABO Bulk Request Processing Service                                           Background
  \                      ABO Bulk Request Processing Service                            ABO
  Bulk Request Processing Service Service                                                                                                                                                                                                                  \n"
- "ABO Bulk Request Validation Service                                           Batch
  \                           ABO Bulk Request Validation Service                            ABO
  Bulk Request Validation Service Service                                                                                                                                                                                                                  \n"
- "ABO Bulk Request Validation Service                                           Background
  \                      ABO Bulk Request Validation Service                            ABO
  Bulk Request Validation Service Service                                                                                                                                                                                                                  \n"
- "ADM Service                                                                   Batch
  \                           ADM Service                                                    ADM
  Service Service                                                                                                                                                                                                                                          \n"
- "ADM Service                                                                   Background
  \                      ADM Service                                                    ADM
  Service Service                                                                                                                                                                                                                                          \n"
- "Siebel Administrator Notification Component                                   Batch
  \                           AdminNotify                                                    Component
  used for administrator notification                                                                                                                                                                                                                \n"
- "Analytic Adaptor Manager                                                      Batch
  \                           Analytic Adaptor Manager                                       Analytic
  Adaptor Manager Service                                                                                                                                                                                                                             \n"
- "Analytic Adaptor Manager                                                      Background
  \                      Analytic Adaptor Manager                                       Analytic
  Adaptor Manager Service                                                                                                                                                                                                                             \n"
- "Application Object Manager                                                    Interactive
  \                     AppObjMgr                                                      Object
  manager component type for thin-client and web-client applications                                                                                                                                                                                    \n"
- "Appointment Booking Service                                                   Batch
  \                           Appointment Booking Service                                    Appointment
  Booking Service Service                                                                                                                                                                                                                          \n"
- "Appointment Booking Service                                                   Background
  \                      Appointment Booking Service                                    Appointment
  Booking Service Service                                                                                                                                                                                                                          \n"
- "Batch Assignment                                                              Batch
  \                           AsgnBatch                                                      Batch
  assigns positions and employees to objects                                                                                                                                                                                                             \n"
- "Assignment Manager                                                            Batch
  \                           AsgnSrvr                                                       Assigns
  positions and employees to objects                                                                                                                                                                                                                   \n"
- "Business Service Manager                                                      Batch
  \                           BusSvcMgr                                                      Business
  Service Manager component                                                                                                                                                                                                                           \n"
- "Business Service Manager                                                      Background
  \                      BusSvcMgr                                                      Business
  Service Manager component                                                                                                                                                                                                                           \n"
- "CG Payment Business Service                                                   Batch
  \                           CG Payment Business Service                                    CG
  Payment Business Service Service                                                                                                                                                                                                                          \n"
- "CG Payment Business Service                                                   Background
  \                      CG Payment Business Service                                    CG
  Payment Business Service Service                                                                                                                                                                                                                          \n"
- "CG SVP Business Service                                                       Batch
  \                           CG SVP Business Service                                        CG
  SVP Business Service Service                                                                                                                                                                                                                              \n"
- "CG SVP Business Service                                                       Background
  \                      CG SVP Business Service                                        CG
  SVP Business Service Service                                                                                                                                                                                                                              \n"
- "CS Fund Business Service                                                      Batch
  \                           CS Fund Business Service                                       CS
  Fund Business Service Service                                                                                                                                                                                                                             \n"
- "CS Fund Business Service                                                      Background
  \                      CS Fund Business Service                                       CS
  Fund Business Service Service                                                                                                                                                                                                                             \n"
- "Categorization Manager                                                        Batch
  \                           Categorization Manager                                         Categorization
  Manager Service                                                                                                                                                                                                                               \n"
- "Categorization Manager                                                        Background
  \                      Categorization Manager                                         Categorization
  Manager Service                                                                                                                                                                                                                               \n"
- "CheckDup                                                                      Batch
  \                           CheckDup                                                       CheckDup
  Service                                                                                                                                                                                                                                             \n"
- "CheckDup                                                                      Background
  \                      CheckDup                                                       CheckDup
  Service                                                                                                                                                                                                                                             \n"
- "Communications Inbound Receiver                                               Batch
  \                           CommInboundRcvr                                                Loads
  response groups to receive and queue inbound events                                                                                                                                                                                                    \n"
- "Communications Session Manager                                                Batch
  \                           CommSessionMgr                                                 Interact
  with end user for utilizing communications channels                                                                                                                                                                                                 \n"
- "Communication Server Configuration                                            Batch
  \                           Communication Server Configuration                             Communication
  Server Configuration Service                                                                                                                                                                                                                   \n"
- "Communication Server Configuration                                            Background
  \                      Communication Server Configuration                             Communication
  Server Configuration Service                                                                                                                                                                                                                   \n"
- "Communications Inbound Processor                                              Batch
  \                           Communications Inbound Processor                               Communications
  Inbound Processor Service                                                                                                                                                                                                                     \n"
- "Communications Inbound Processor                                              Background
  \                      Communications Inbound Processor                               Communications
  Inbound Processor Service                                                                                                                                                                                                                     \n"
- "Complete Activity                                                             Batch
  \                           Complete Activity                                              Complete
  Activity Service                                                                                                                                                                                                                                    \n"
- "Complete Activity                                                             Background
  \                      Complete Activity                                              Complete
  Activity Service                                                                                                                                                                                                                                    \n"
- "Content Project                                                               Batch
  \                           Content Project                                                Content
  Project Service                                                                                                                                                                                                                                      \n"
- "Content Project                                                               Background
  \                      Content Project                                                Content
  Project Service                                                                                                                                                                                                                                      \n"
- "Contracts Accumulator Service                                                 Batch
  \                           Contracts Accumulator Service                                  Contracts
  Accumulator Service Service                                                                                                                                                                                                                        \n"
- "Contracts Accumulator Service                                                 Background
  \                      Contracts Accumulator Service                                  Contracts
  Accumulator Service Service                                                                                                                                                                                                                        \n"
- "Contracts Evaluator Service                                                   Batch
  \                           Contracts Evaluator Service                                    Contracts
  Evaluator Service Service                                                                                                                                                                                                                          \n"
- "Contracts Evaluator Service                                                   Background
  \                      Contracts Evaluator Service                                    Contracts
  Evaluator Service Service                                                                                                                                                                                                                          \n"
- "Contracts Resolver Service                                                    Batch
  \                           Contracts Resolver Service                                     Contracts
  Resolver Service Service                                                                                                                                                                                                                           \n"
- "Contracts Resolver Service                                                    Background
  \                      Contracts Resolver Service                                     Contracts
  Resolver Service Service                                                                                                                                                                                                                           \n"
- "Crediting Engine DB Operations                                                Batch
  \                           Crediting Engine DB Operations                                 Crediting
  Engine DB Operations Service                                                                                                                                                                                                                       \n"
- "Crediting Engine DB Operations                                                Background
  \                      Crediting Engine DB Operations                                 Crediting
  Engine DB Operations Service                                                                                                                                                                                                                       \n"
- "Custom Application Object Manager                                             Interactive
  \                     CustomAppObjMgr                                                Object
  manager component type for thin-client Custom UI applications                                                                                                                                                                                         \n"
- "DCommerce Alerts                                                              Background
  \                      DCommerce Alerts                                               Background
  process that manages DCommerce alerts                                                                                                                                                                                                             \n"
- "DCommerce Automatic Auction Close                                             Background
  \                      DCommerce Automatic Auction Close                              Background
  process that detects and closes auctions                                                                                                                                                                                                          \n"
- "DNB Update                                                                    Batch
  \                           DNB Update                                                     DNB
  Update Service                                                                                                                                                                                                                                           \n"
- "DNB Update                                                                    Background
  \                      DNB Update                                                     DNB
  Update Service                                                                                                                                                                                                                                           \n"
- "Data Cleansing                                                                Batch
  \                           Data Cleansing                                                 Data
  Cleansing Service                                                                                                                                                                                                                                       \n"
- "Data Cleansing                                                                Background
  \                      Data Cleansing                                                 Data
  Cleansing Service                                                                                                                                                                                                                                       \n"
- "Database Extract                                                              Batch
  \                           DbXtract                                                       Extracts
  visible data for a Siebel Remote client                                                                                                                                                                                                             \n"
- "DeDuplication                                                                 Batch
  \                           DeDuplication                                                  DeDuplication
  Service                                                                                                                                                                                                                                        \n"
- "DeDuplication                                                                 Background
  \                      DeDuplication                                                  DeDuplication
  Service                                                                                                                                                                                                                                        \n"
- "Document Driver                                                               Batch
  \                           Document Driver                                                Document
  Driver Service                                                                                                                                                                                                                                      \n"
- "Document Driver                                                               Background
  \                      Document Driver                                                Document
  Driver Service                                                                                                                                                                                                                                      \n"
- "Data Quality Manager                                                          Batch
  \                           Dqmgr                                                          Cleanse
  data and de-duplicate records                                                                                                                                                                                                                        \n"
- "DynamicCommerce                                                               Batch
  \                           DynamicCommerce                                                DynamicCommerce
  Service                                                                                                                                                                                                                                      \n"
- "DynamicCommerce                                                               Background
  \                      DynamicCommerce                                                DynamicCommerce
  Service                                                                                                                                                                                                                                      \n"
- "EAI Business Integration Manager                                              Batch
  \                           EAI Business Integration Manager                               EAI
  Business Integration Manager Service                                                                                                                                                                                                                     \n"
- "EAI Business Integration Manager                                              Background
  \                      EAI Business Integration Manager                               EAI
  Business Integration Manager Service                                                                                                                                                                                                                     \n"
- "EAI Outbound Service                                                          Batch
  \                           EAI Outbound Service                                           EAI
  Outbound Service Service                                                                                                                                                                                                                                 \n"
- "EAI Outbound Service                                                          Background
  \                      EAI Outbound Service                                           EAI
  Outbound Service Service                                                                                                                                                                                                                                 \n"
- "Enterprise Application Integration Connector Receiver                         Background
  \                      EAIDeprecatedRcvr                                              Deprecated
  receiver for in-bound EAI transactions used by connectors                                                                                                                                                                                         \n"
- "EAILOVService                                                                 Batch
  \                           EAILOVService                                                  EAILOVService
  Service                                                                                                                                                                                                                                        \n"
- "EAILOVService                                                                 Background
  \                      EAILOVService                                                  EAILOVService
  Service                                                                                                                                                                                                                                        \n"
- "EAI Object Manager                                                            Interactive
  \                     EAIObjMgr                                                      Object
  manager component type for thin-client EAI applications                                                                                                                                                                                               \n"
- "Enterprise Application Integration Receiver                                   Background
  \                      EAIRcvr                                                        Generic
  receiver for in-bound EAI transactions                                                                                                                                                                                                               \n"
- "Enterprise Integration Mgr                                                    Batch
  \                           EIM                                                            Integrates
  enterprise data to and from other systems                                                                                                                                                                                                         \n"
- "ERM Compensation Planning Service                                             Batch
  \                           ERM Compensation Planning Service                              ERM
  Compensation Planning Service Service                                                                                                                                                                                                                    \n"
- "ERM Compensation Planning Service                                             Background
  \                      ERM Compensation Planning Service                              ERM
  Compensation Planning Service Service                                                                                                                                                                                                                    \n"
- "Excel Importer Exporter                                                       Batch
  \                           Excel Importer Exporter                                        Excel
  Importer Exporter Service                                                                                                                                                                                                                              \n"
- "Excel Importer Exporter                                                       Background
  \                      Excel Importer Exporter                                        Excel
  Importer Exporter Service                                                                                                                                                                                                                              \n"
- "FINS Workflow UI Utilities                                                    Batch
  \                           FINS Workflow UI Utilities                                     FINS
  Workflow UI Utilities Service                                                                                                                                                                                                                           \n"
- "FINS Workflow UI Utilities                                                    Background
  \                      FINS Workflow UI Utilities                                     FINS
  Workflow UI Utilities Service                                                                                                                                                                                                                           \n"
- "FS Cycle Counting                                                             Batch
  \                           FS Cycle Counting                                              FS
  Cycle Counting Service                                                                                                                                                                                                                                    \n"
- "FS Cycle Counting                                                             Background
  \                      FS Cycle Counting                                              FS
  Cycle Counting Service                                                                                                                                                                                                                                    \n"
- "FS Fulfillment Service                                                        Batch
  \                           FS Fulfillment Service                                         FS
  Fulfillment Service Service                                                                                                                                                                                                                               \n"
- "FS Fulfillment Service                                                        Background
  \                      FS Fulfillment Service                                         FS
  Fulfillment Service Service                                                                                                                                                                                                                               \n"
- "FS Mobile Inventory Transaction                                               Batch
  \                           FS Mobile Inventory Transaction                                FS
  Mobile Inventory Transaction Service                                                                                                                                                                                                                      \n"
- "FS Mobile Inventory Transaction                                               Background
  \                      FS Mobile Inventory Transaction                                FS
  Mobile Inventory Transaction Service                                                                                                                                                                                                                      \n"
- "FS Part Locator Service                                                       Batch
  \                           FS Part Locator Service                                        FS
  Part Locator Service Service                                                                                                                                                                                                                              \n"
- "FS Part Locator Service                                                       Background
  \                      FS Part Locator Service                                        FS
  Part Locator Service Service                                                                                                                                                                                                                              \n"
- "FS Preventive Maintenance                                                     Batch
  \                           FS Preventive Maintenance                                      FS
  Preventive Maintenance Service                                                                                                                                                                                                                            \n"
- "FS Preventive Maintenance                                                     Background
  \                      FS Preventive Maintenance                                      FS
  Preventive Maintenance Service                                                                                                                                                                                                                            \n"
- "FS Replenish                                                                  Batch
  \                           FS Replenish                                                   FS
  Replenish Service                                                                                                                                                                                                                                         \n"
- "FS Replenish                                                                  Background
  \                      FS Replenish                                                   FS
  Replenish Service                                                                                                                                                                                                                                         \n"
- "File System Manager                                                           Batch
  \                           FSMSrvr                                                        The
  file system manager component                                                                                                                                                                                                                            \n"
- "Forecast 2000 Internal Service                                                Batch
  \                           Forecast 2000 Internal Service                                 Forecast
  2000 Internal Service Service                                                                                                                                                                                                                       \n"
- "Forecast 2000 Internal Service                                                Background
  \                      Forecast 2000 Internal Service                                 Forecast
  2000 Internal Service Service                                                                                                                                                                                                                       \n"
- "Generate New Database                                                         Batch
  \                           GenNewDb                                                       Generates
  a new Sybase SQL Anywhere database template file for Siebel Remote                                                                                                                                                                                 \n"
- "Generate Triggers                                                             Batch
  \                           GenTrig                                                        Generates
  triggers for Workflow Manager and Assignment Manager                                                                                                                                                                                               \n"
- "HTIM MDF Period Ending Service                                                Batch
  \                           HTIM MDF Period Ending Service                                 HTIM
  MDF Period Ending Service Service                                                                                                                                                                                                                       \n"
- "HTIM MDF Period Ending Service                                                Background
  \                      HTIM MDF Period Ending Service                                 HTIM
  MDF Period Ending Service Service                                                                                                                                                                                                                       \n"
- "Handheld Batch Synchronization                                                Batch
  \                           Handheld Batch Synchronization                                 Handheld
  Batch Synchronization Service                                                                                                                                                                                                                       \n"
- "Handheld Batch Synchronization                                                Background
  \                      Handheld Batch Synchronization                                 Handheld
  Batch Synchronization Service                                                                                                                                                                                                                       \n"
- "Handheld Synchronization Agent                                                Batch
  \                           Handheld Synchronization Agent                                 Handheld
  Synchronization Agent Service                                                                                                                                                                                                                       \n"
- "Handheld Synchronization Agent                                                Background
  \                      Handheld Synchronization Agent                                 Handheld
  Synchronization Agent Service                                                                                                                                                                                                                       \n"
- "Handheld Synchronization                                                      Batch
  \                           Handheld Synchronization                                       Handheld
  Synchronization Service                                                                                                                                                                                                                             \n"
- "Handheld Synchronization                                                      Background
  \                      Handheld Synchronization                                       Handheld
  Synchronization Service                                                                                                                                                                                                                             \n"
- "IC Quota Import Service                                                       Batch
  \                           IC Quota Import Service                                        IC
  Quota Import Service Service                                                                                                                                                                                                                              \n"
- "IC Quota Import Service                                                       Background
  \                      IC Quota Import Service                                        IC
  Quota Import Service Service                                                                                                                                                                                                                              \n"
- "IComp Credit Assignment Engine                                                Batch
  \                           ICompCreditAsgn                                                Assigns
  credit allocation based on crediting rules                                                                                                                                                                                                           \n"
- "Incentive Compensation Mgr                                                    Batch
  \                           ICompMgr                                                       Calculates
  Incentive Compensations                                                                                                                                                                                                                           \n"
- "SRM Tester for key-based routing                                              Batch
  \                           KRSrmTst                                                       Server
  Request Manager Test Component for key-based routing                                                                                                                                                                                                  \n"
- "LOY Interactive Processing Engine                                             Batch
  \                           LOY Interactive Processing Engine                              LOY
  Interactive Processing Engine Service                                                                                                                                                                                                                    \n"
- "LOY Interactive Processing Engine                                             Background
  \                      LOY Interactive Processing Engine                              LOY
  Interactive Processing Engine Service                                                                                                                                                                                                                    \n"
- "LOY Processing Engine                                                         Batch
  \                           LOY Processing Engine                                          LOY
  Processing Engine Service                                                                                                                                                                                                                                \n"
- "LOY Processing Engine                                                         Background
  \                      LOY Processing Engine                                          LOY
  Processing Engine Service                                                                                                                                                                                                                                \n"
- "LS Data Rollup                                                                Batch
  \                           LS Data Rollup                                                 LS
  Data Rollup Service                                                                                                                                                                                                                                       \n"
- "LS Data Rollup                                                                Background
  \                      LS Data Rollup                                                 LS
  Data Rollup Service                                                                                                                                                                                                                                       \n"
- "LS MC MarketingComplianceExpenseAllocation                                    Batch
  \                           LS MC MarketingComplianceExpenseAllocation                     LS
  MC MarketingComplianceExpenseAllocation Service                                                                                                                                                                                                           \n"
- "LS MC MarketingComplianceExpenseAllocation                                    Background
  \                      LS MC MarketingComplianceExpenseAllocation                     LS
  MC MarketingComplianceExpenseAllocation Service                                                                                                                                                                                                           \n"
- "LS Pharma Account GanttChart Utility Service                                  Batch
  \                           LS Pharma Account GanttChart Utility Service                   LS
  Pharma Account GanttChart Utility Service Service                                                                                                                                                                                                         \n"
- "LS Pharma Account GanttChart Utility Service                                  Background
  \                      LS Pharma Account GanttChart Utility Service                   LS
  Pharma Account GanttChart Utility Service Service                                                                                                                                                                                                         \n"
- "LS Pharma Contact GanttChart Utility Service                                  Batch
  \                           LS Pharma Contact GanttChart Utility Service                   LS
  Pharma Contact GanttChart Utility Service Service                                                                                                                                                                                                         \n"
- "LS Pharma Contact GanttChart Utility Service                                  Background
  \                      LS Pharma Contact GanttChart Utility Service                   LS
  Pharma Contact GanttChart Utility Service Service                                                                                                                                                                                                         \n"
- "LS Pharma GanttChart Utility Service                                          Batch
  \                           LS Pharma GanttChart Utility Service                           LS
  Pharma GanttChart Utility Service Service                                                                                                                                                                                                                 \n"
- "LS Pharma GanttChart Utility Service                                          Background
  \                      LS Pharma GanttChart Utility Service                           LS
  Pharma GanttChart Utility Service Service                                                                                                                                                                                                                 \n"
- "Lead Processing Service                                                       Batch
  \                           Lead Processing Service                                        Lead
  Processing Service Service                                                                                                                                                                                                                              \n"
- "Lead Processing Service                                                       Background
  \                      Lead Processing Service                                        Lead
  Processing Service Service                                                                                                                                                                                                                              \n"
- "List Import                                                                   Batch
  \                           List Import                                                    List
  Import Service                                                                                                                                                                                                                                          \n"
- "List Import                                                                   Background
  \                      List Import                                                    List
  Import Service                                                                                                                                                                                                                                          \n"
- "List                                                                          Batch
  \                           List                                                           List
  Service                                                                                                                                                                                                                                                 \n"
- "List                                                                          Background
  \                      List                                                           List
  Service                                                                                                                                                                                                                                                 \n"
- "List Manager                                                                  Batch
  \                           ListMgr                                                        Loads
  outside files for list manager                                                                                                                                                                                                                         \n"
- "E-mail Manager                                                                Background
  \                      MailMgr                                                        Sends
  e-mail initiated by Workflow Manager                                                                                                                                                                                                                   \n"
- "Message Board Maintenance Service                                             Batch
  \                           Message Board Maintenance Service                              Message
  Board Maintenance Service Service                                                                                                                                                                                                                    \n"
- "Message Board Maintenance Service                                             Background
  \                      Message Board Maintenance Service                              Message
  Board Maintenance Service Service                                                                                                                                                                                                                    \n"
- "OM Benchmark Test                                                             Batch
  \                           OM Benchmark Test                                              OM
  Benchmark Test Service                                                                                                                                                                                                                                    \n"
- "OM Benchmark Test                                                             Background
  \                      OM Benchmark Test                                              OM
  Benchmark Test Service                                                                                                                                                                                                                                    \n"
- "OM Regression Test                                                            Batch
  \                           OM Regression Test                                             OM
  Regression Test Service                                                                                                                                                                                                                                   \n"
- "OM Regression Test                                                            Background
  \                      OM Regression Test                                             OM
  Regression Test Service                                                                                                                                                                                                                                   \n"
- "OM Remote Regression Test                                                     Batch
  \                           OM Remote Regression Test                                      OM
  Remote Regression Test Service                                                                                                                                                                                                                            \n"
- "OM Remote Regression Test                                                     Background
  \                      OM Remote Regression Test                                      OM
  Remote Regression Test Service                                                                                                                                                                                                                            \n"
- "Optimizer Service                                                             Batch
  \                           Optimizer Service                                              Optimizer
  Service Service                                                                                                                                                                                                                                    \n"
- "Optimizer Service                                                             Background
  \                      Optimizer Service                                              Optimizer
  Service Service                                                                                                                                                                                                                                    \n"
- "Outbound Communications Manager                                               Batch
  \                           Outbound Communications Manager                                Outbound
  Communications Manager Service                                                                                                                                                                                                                      \n"
- "Outbound Communications Manager                                               Background
  \                      Outbound Communications Manager                                Outbound
  Communications Manager Service                                                                                                                                                                                                                      \n"
- "PIMSI Engine Service                                                          Batch
  \                           PIMSI Engine Service                                           PIMSI
  Engine Service Service                                                                                                                                                                                                                                 \n"
- "PIMSI Engine Service                                                          Background
  \                      PIMSI Engine Service                                           PIMSI
  Engine Service Service                                                                                                                                                                                                                                 \n"
- "Page Manager                                                                  Background
  \                      PageMgr                                                        Sends
  pages initiated by Workflow Manager and Siebel Client                                                                                                                                                                                                  \n"
- "Perf MQReceive Processor                                                      Batch
  \                           Perf MQReceive Processor                                       Perf
  MQReceive Processor Service                                                                                                                                                                                                                             \n"
- "Perf MQReceive Processor                                                      Background
  \                      Perf MQReceive Processor                                       Perf
  MQReceive Processor Service                                                                                                                                                                                                                             \n"
- "Quick Fill Service                                                            Batch
  \                           Quick Fill Service                                             Quick
  Fill Service Service                                                                                                                                                                                                                                   \n"
- "Quick Fill Service                                                            Background
  \                      Quick Fill Service                                             Quick
  Fill Service Service                                                                                                                                                                                                                                   \n"
- "Batch Real-Time Integration                                                   Batch
  \                           RTIBatch                                                       Batch
  for Real-Time integration with BackOffice (ERP) Systems                                                                                                                                                                                                \n"
- "RTS Extractor Service                                                         Batch
  \                           RTS Extractor Service                                          RTS
  Extractor Service Service                                                                                                                                                                                                                                \n"
- "RTS Extractor Service                                                         Background
  \                      RTS Extractor Service                                          RTS
  Extractor Service Service                                                                                                                                                                                                                                \n"
- "RTS Message Apply Service                                                     Batch
  \                           RTS Message Apply Service                                      RTS
  Message Apply Service Service                                                                                                                                                                                                                            \n"
- "RTS Message Apply Service                                                     Background
  \                      RTS Message Apply Service                                      RTS
  Message Apply Service Service                                                                                                                                                                                                                            \n"
- "RTS Sender Service                                                            Batch
  \                           RTS Sender Service                                             RTS
  Sender Service Service                                                                                                                                                                                                                                   \n"
- "RTS Sender Service                                                            Background
  \                      RTS Sender Service                                             RTS
  Sender Service Service                                                                                                                                                                                                                                   \n"
- "RTS Subscription Service                                                      Batch
  \                           RTS Subscription Service                                       RTS
  Subscription Service Service                                                                                                                                                                                                                             \n"
- "RTS Subscription Service                                                      Background
  \                      RTS Subscription Service                                       RTS
  Subscription Service Service                                                                                                                                                                                                                             \n"
- "RTS Transaction Dispatch Service                                              Batch
  \                           RTS Transaction Dispatch Service                               RTS
  Transaction Dispatch Service Service                                                                                                                                                                                                                     \n"
- "RTS Transaction Dispatch Service                                              Background
  \                      RTS Transaction Dispatch Service                               RTS
  Transaction Dispatch Service Service                                                                                                                                                                                                                     \n"
- "RTS Transaction Dispatcher                                                    Background
  \                      RTSDispatcher                                                  Dispatches
  the transactions to the RTS channel                                                                                                                                                                                                               \n"
- "Replication Agent                                                             Background
  \                      RepAgent                                                       Synchronizes
  a Siebel Remote regional database with HQ                                                                                                                                                                                                       \n"
- "Report Business Service                                                       Batch
  \                           Report Business Service                                        Report
  Business Service Service                                                                                                                                                                                                                              \n"
- "Report Business Service                                                       Background
  \                      Report Business Service                                        Report
  Business Service Service                                                                                                                                                                                                                              \n"
- "Server Request Broker                                                         Interactive
  \                     ReqBroker                                                      Route
  requests and asynchronous notification among clients and components                                                                                                                                                                                    \n"
- "Response                                                                      Batch
  \                           Response                                                       Response
  Service                                                                                                                                                                                                                                             \n"
- "Response                                                                      Background
  \                      Response                                                       Response
  Service                                                                                                                                                                                                                                             \n"
- "Row Set Transformation Toolkit                                                Batch
  \                           Row Set Transformation Toolkit                                 Row
  Set Transformation Toolkit Service                                                                                                                                                                                                                       \n"
- "Row Set Transformation Toolkit                                                Background
  \                      Row Set Transformation Toolkit                                 Row
  Set Transformation Toolkit Service                                                                                                                                                                                                                       \n"
- "Rule Manager Service                                                          Batch
  \                           Rule Manager Service                                           Rule
  Manager Service Service                                                                                                                                                                                                                                 \n"
- "Rule Manager Service                                                          Background
  \                      Rule Manager Service                                           Rule
  Manager Service Service                                                                                                                                                                                                                                 \n"
- "Rule Runtime Administration                                                   Batch
  \                           Rule Runtime Administration                                    Rule
  Runtime Administration Service                                                                                                                                                                                                                          \n"
- "Rule Runtime Administration                                                   Background
  \                      Rule Runtime Administration                                    Rule
  Runtime Administration Service                                                                                                                                                                                                                          \n"
- "Siebel Connection Broker                                                      Background
  \                      SCBroker                                                       Route
  and load balance connections to components                                                                                                                                                                                                             \n"
- "SCF Message Facility Test Component                                           Batch
  \                           SCFMsgFacTest                                                  Component
  used for testing the SCF Message Facility                                                                                                                                                                                                          \n"
- "SCF Message Facility Test Component                                           Background
  \                      SCFMsgFacTest                                                  Component
  used for testing the SCF Message Facility                                                                                                                                                                                                          \n"
- "SHM Function Service                                                          Batch
  \                           SHM Function Service                                           SHM
  Function Service Service                                                                                                                                                                                                                                 \n"
- "SHM Function Service                                                          Background
  \                      SHM Function Service                                           SHM
  Function Service Service                                                                                                                                                                                                                                 \n"
- "SIA CS ADL Business Service                                                   Batch
  \                           SIA CS ADL Business Service                                    SIA
  CS ADL Business Service Service                                                                                                                                                                                                                          \n"
- "SIA CS ADL Business Service                                                   Background
  \                      SIA CS ADL Business Service                                    SIA
  CS ADL Business Service Service                                                                                                                                                                                                                          \n"
- "SIA CS ADL Delete Business Service                                            Batch
  \                           SIA CS ADL Delete Business Service                             SIA
  CS ADL Delete Business Service Service                                                                                                                                                                                                                   \n"
- "SIA CS ADL Delete Business Service                                            Background
  \                      SIA CS ADL Delete Business Service                             SIA
  CS ADL Delete Business Service Service                                                                                                                                                                                                                   \n"
- "SIS Test Component                                                            Batch
  \                           SISTst                                                         SIS
  Test Component use for testing shared memory instance                                                                                                                                                                                                    \n"
- "SIS Test Component                                                            Interactive
  \                     SISTst                                                         SIS
  Test Component use for testing shared memory instance                                                                                                                                                                                                    \n"
- "SIS Test Component                                                            Background
  \                      SISTst                                                         SIS
  Test Component use for testing shared memory instance                                                                                                                                                                                                    \n"
- "SMQ Message Service                                                           Batch
  \                           SMQ Message Service                                            SMQ
  Message Service Service                                                                                                                                                                                                                                  \n"
- "SMQ Message Service                                                           Background
  \                      SMQ Message Service                                            SMQ
  Message Service Service                                                                                                                                                                                                                                  \n"
- "SMQ Transport Service                                                         Batch
  \                           SMQ Transport Service                                          SMQ
  Transport Service Service                                                                                                                                                                                                                                \n"
- "SMQ Transport Service                                                         Background
  \                      SMQ Transport Service                                          SMQ
  Transport Service Service                                                                                                                                                                                                                                \n"
- "Server Request Processor (SRP)                                                Interactive
  \                     SRProc                                                         Store
  requests/notifications into database and forward them to components/clients                                                                                                                                                                            \n"
- "Sales Hierarchy Service                                                       Batch
  \                           Sales Hierarchy Service                                        Sales
  Hierarchy Service Service                                                                                                                                                                                                                              \n"
- "Sales Hierarchy Service                                                       Background
  \                      Sales Hierarchy Service                                        Sales
  Hierarchy Service Service                                                                                                                                                                                                                              \n"
- "Search Data Processor                                                         Batch
  \                           Search Data Processor                                          Search
  Data Processor Service                                                                                                                                                                                                                                \n"
- "Search Data Processor                                                         Background
  \                      Search Data Processor                                          Search
  Data Processor Service                                                                                                                                                                                                                                \n"
- "Search External Service                                                       Batch
  \                           Search External Service                                        Search
  External Service Service                                                                                                                                                                                                                              \n"
- "Search External Service                                                       Background
  \                      Search External Service                                        Search
  External Service Service                                                                                                                                                                                                                              \n"
- "Search Solution Service                                                       Batch
  \                           Search Solution Service                                        Search
  Solution Service Service                                                                                                                                                                                                                              \n"
- "Search Solution Service                                                       Background
  \                      Search Solution Service                                        Search
  Solution Service Service                                                                                                                                                                                                                              \n"
- "Server Manager                                                                Interactive
  \                     ServerMgr                                                      Administration
  of Siebel Servers within the Enterprise                                                                                                                                                                                                       \n"
- "Signal Modify Service                                                         Batch
  \                           Signal Modify Service                                          Signal
  Modify Service Service                                                                                                                                                                                                                                \n"
- "Signal Modify Service                                                         Background
  \                      Signal Modify Service                                          Signal
  Modify Service Service                                                                                                                                                                                                                                \n"
- "Smart Answer Client                                                           Batch
  \                           Smart Answer Client                                            Smart
  Answer Client Service                                                                                                                                                                                                                                  \n"
- "Smart Answer Client                                                           Background
  \                      Smart Answer Client                                            Smart
  Answer Client Service                                                                                                                                                                                                                                  \n"
- "Smart Script Execution Cleanup                                                Batch
  \                           Smart Script Execution Cleanup                                 Smart
  Script Execution Cleanup Service                                                                                                                                                                                                                       \n"
- "Smart Script Execution Cleanup                                                Background
  \                      Smart Script Execution Cleanup                                 Smart
  Script Execution Cleanup Service                                                                                                                                                                                                                       \n"
- "Source Code Lookup                                                            Batch
  \                           Source Code Lookup                                             Source
  Code Lookup Service                                                                                                                                                                                                                                   \n"
- "Source Code Lookup                                                            Background
  \                      Source Code Lookup                                             Source
  Code Lookup Service                                                                                                                                                                                                                                   \n"
- "SrchFileSrvr                                                                  Batch
  \                           SrchFileSrvr                                                   SrchFileSrvr
  Service                                                                                                                                                                                                                                         \n"
- "SrchFileSrvr                                                                  Background
  \                      SrchFileSrvr                                                   SrchFileSrvr
  Service                                                                                                                                                                                                                                         \n"
- "SRM Tester 1                                                                  Batch
  \                           SrmTst1                                                        Server
  Request Manager Test Component 1                                                                                                                                                                                                                      \n"
- "SRM Tester 2                                                                  Batch
  \                           SrmTst2                                                        Server
  Request Manager Test Component 2                                                                                                                                                                                                                      \n"
- "SRM Tester 3                                                                  Batch
  \                           SrmTst3                                                        Server
  Request Manager Test Component 3                                                                                                                                                                                                                      \n"
- "SRM Tester 4                                                                  Batch
  \                           SrmTst4                                                        Server
  Request Manager Test Component 4                                                                                                                                                                                                                      \n"
- "Synchronization Manager                                                       Interactive
  \                     SynchMgr                                                       Services
  Siebel Remote synchronization clients                                                                                                                                                                                                               \n"
- "TNT SHM Event Template Copy Service                                           Batch
  \                           TNT SHM Event Template Copy Service                            TNT
  SHM Event Template Copy Service Service                                                                                                                                                                                                                  \n"
- "TNT SHM Event Template Copy Service                                           Background
  \                      TNT SHM Event Template Copy Service                            TNT
  SHM Event Template Copy Service Service                                                                                                                                                                                                                  \n"
- "TNT SHM Quote Service                                                         Batch
  \                           TNT SHM Quote Service                                          TNT
  SHM Quote Service Service                                                                                                                                                                                                                                \n"
- "TNT SHM Quote Service                                                         Background
  \                      TNT SHM Quote Service                                          TNT
  SHM Quote Service Service                                                                                                                                                                                                                                \n"
- "TNT SHM Revenue Service                                                       Batch
  \                           TNT SHM Revenue Service                                        TNT
  SHM Revenue Service Service                                                                                                                                                                                                                              \n"
- "TNT SHM Revenue Service                                                       Background
  \                      TNT SHM Revenue Service                                        TNT
  SHM Revenue Service Service                                                                                                                                                                                                                              \n"
- "Target List Service                                                           Batch
  \                           Target List Service                                            Target
  List Service Service                                                                                                                                                                                                                                  \n"
- "Target List Service                                                           Background
  \                      Target List Service                                            Target
  List Service Service                                                                                                                                                                                                                                  \n"
- "Task Log Cleanup Service                                                      Batch
  \                           Task Log Cleanup Service                                       Task
  Log Cleanup Service Service                                                                                                                                                                                                                             \n"
- "Task Log Cleanup Service                                                      Background
  \                      Task Log Cleanup Service                                       Task
  Log Cleanup Service Service                                                                                                                                                                                                                             \n"
- "Test Utilities                                                                Batch
  \                           Test Utilities                                                 Test
  Utilities Service                                                                                                                                                                                                                                       \n"
- "Test Utilities                                                                Background
  \                      Test Utilities                                                 Test
  Utilities Service                                                                                                                                                                                                                                       \n"
- "Test Data Access                                                              Batch
  \                           TestDataAccess                                                 Component
  used for testing SCF data access layer.                                                                                                                                                                                                            \n"
- "Test Data Access                                                              Background
  \                      TestDataAccess                                                 Component
  used for testing SCF data access layer.                                                                                                                                                                                                            \n"
- "Test SCF Data Access Performance                                              Batch
  \                           TestDataAccessPerf                                             Component
  used for testing SCF data access layer performance.                                                                                                                                                                                                \n"
- "Test SCF Event Facility                                                       Batch
  \                           TestEventFacility                                              Component
  used for testing SCF event facility and its performance.                                                                                                                                                                                           \n"
- "Request MT Test Server                                                        Batch
  \                           TestMTReq                                                      Component
  used for testing Multi-threaded Request Mode Server                                                                                                                                                                                                \n"
- "Multithreaded Test Server                                                     Batch
  \                           TestMTSrvr                                                     Component
  used for testing Multithreaded Server                                                                                                                                                                                                              \n"
- "Multithreaded Test Server                                                     Interactive
  \                     TestMTSrvr                                                     Component
  used for testing Multithreaded Server                                                                                                                                                                                                              \n"
- "Request Test Server                                                           Batch
  \                           TestReq                                                        Component
  used for testing Request Mode Server                                                                                                                                                                                                               \n"
- "Test SCF Facilities                                                           Batch
  \                           TestScfFacilities                                              Component
  used for testing new SCF facilities.                                                                                                                                                                                                               \n"
- "Test SCF Facilities                                                           Background
  \                      TestScfFacilities                                              Component
  used for testing new SCF facilities.                                                                                                                                                                                                               \n"
- "Session Test Server                                                           Interactive
  \                     TestSess                                                       Component
  used for testing Session Mode Server                                                                                                                                                                                                               \n"
- "Test Server                                                                   Batch
  \                           TestSrvr                                                       Component
  used for testing Client Administration                                                                                                                                                                                                             \n"
- "Test Server                                                                   Background
  \                      TestSrvr                                                       Component
  used for testing Client Administration                                                                                                                                                                                                             \n"
- "Transaction Merger                                                            Background
  \                      TxnMerge                                                       Merges
  transactions from Siebel Remote clients                                                                                                                                                                                                               \n"
- "Transaction Processor                                                         Background
  \                      TxnProc                                                        Prepares
  the transaction log for the Transaction Router                                                                                                                                                                                                      \n"
- "Transaction Router                                                            Background
  \                      TxnRoute                                                       Routes
  visible transactions to Siebel Remote clients                                                                                                                                                                                                         \n"
- "UDA Service                                                                   Batch
  \                           UDA Service                                                    UDA
  Service Service                                                                                                                                                                                                                                          \n"
- "UDA Service                                                                   Background
  \                      UDA Service                                                    UDA
  Service Service                                                                                                                                                                                                                                          \n"
- "Universal Data Cleansing Service                                              Batch
  \                           Universal Data Cleansing Service                               Universal
  Data Cleansing Service Service                                                                                                                                                                                                                     \n"
- "Universal Data Cleansing Service                                              Background
  \                      Universal Data Cleansing Service                               Universal
  Data Cleansing Service Service                                                                                                                                                                                                                     \n"
- "UoM Conversion Business Service                                               Batch
  \                           UoM Conversion Business Service                                UoM
  Conversion Business Service Service                                                                                                                                                                                                                      \n"
- "UoM Conversion Business Service                                               Background
  \                      UoM Conversion Business Service                                UoM
  Conversion Business Service Service                                                                                                                                                                                                                      \n"
- "Update Manager                                                                Batch
  \                           UpdateMgr                                                      Server
  component that will update DNB and List Management                                                                                                                                                                                                    \n"
- "Upgrade Kit Wizard OMSV                                                       Batch
  \                           Upgrade Kit Wizard OMSV                                        Upgrade
  Kit Wizard OMSV Service                                                                                                                                                                                                                              \n"
- "Upgrade Kit Wizard OMSV                                                       Background
  \                      Upgrade Kit Wizard OMSV                                        Upgrade
  Kit Wizard OMSV Service                                                                                                                                                                                                                              \n"
- "Workflow Action Agent                                                         Background
  \                      WorkActn                                                       Executes
  actions for pre-defined events                                                                                                                                                                                                                      \n"
- "Workflow Monitor Agent                                                        Background
  \                      WorkMon                                                        Monitors
  the database for pre-defined events                                                                                                                                                                                                                 \n"
- "Workflow Process Manager                                                      Batch
  \                           Workflow Process Manager                                       Workflow
  Process Manager Service                                                                                                                                                                                                                             \n"
- "Workflow Process Manager                                                      Background
  \                      Workflow Process Manager                                       Workflow
  Process Manager Service                                                                                                                                                                                                                             \n"
- "Workflow Recovery Manager                                                     Batch
  \                           Workflow Recovery Manager                                      Workflow
  Recovery Manager Service                                                                                                                                                                                                                            \n"
- "Workflow Recovery Manager                                                     Background
  \                      Workflow Recovery Manager                                      Workflow
  Recovery Manager Service                                                                                                                                                                                                                            \n"
- "XMLP Driver Service                                                           Batch
  \                           XMLP Driver Service                                            XMLP
  Driver Service Service                                                                                                                                                                                                                                  \n"
- "XMLP Driver Service                                                           Background
  \                      XMLP Driver Service                                            XMLP
  Driver Service Service                                                                                                                                                                                                                                  \n"
- "eAuto VDS Accessorization Utility Service                                     Batch
  \                           eAuto VDS Accessorization Utility Service                      eAuto
  VDS Accessorization Utility Service Service                                                                                                                                                                                                            \n"
- "eAuto VDS Accessorization Utility Service                                     Background
  \                      eAuto VDS Accessorization Utility Service                      eAuto
  VDS Accessorization Utility Service Service                                                                                                                                                                                                            \n"
- "\n"
- "262 rows returned.\n"
- "\n"
list_params:
- "\n"
- "PA_ALIAS                               PA_VALUE                                                                                 PA_DATATYPE
  \ PA_SCOPE   PA_SUBSYSTEM                                   PA_SETLEVEL       PA_DISP_SETLEVEL
  \     PA  PA  PA  PA  PA_NAME                                                                                                                                                                  \n"
- "-------------------------------------  ---------------------------------------------------------------------------------------
  \ -----------  ---------  ---------------------------------------------  ----------------
  \ --------------------  --  --  --  --  --------------------------------------------------------------------------------------------------------------------
  \ \n"
- "16KTblSpace                                                                                                                     String
  \      Subsystem  Database Access                                Never set         Never
  set             Y   N   N   N   16K Tablespace Name                                                                                                                                                      \n"
- "32KTblSpace                                                                                                                     String
  \      Subsystem  Database Access                                Never set         Never
  set             Y   N   N   N   32K Tablespace Name                                                                                                                                                      \n"
- "ActivityId                                                                                                                      String
  \      Subsystem  Communications Outbound Manager                Never set         Never
  set             N   N   N   N   Activity Id                                                                                                                                                              \n"
- "ActuateReportCastDomain                                                                                                         String
  \      Subsystem  Infrastructure Actuate Reports Subsystem       Never set         Never
  set             Y   N   N   N   Actuate Report Cast Domain                                                                                                                                               \n"
- "ActuateReportCastLang                  LANG_INDEPENDENT                                                                         String
  \      Subsystem  Infrastructure Actuate Reports Subsystem       Server level      Server
  level set      Y   N   N   N   Actuate Server Report Cast Language                                                                                                                                      \n"
- "ActuateReportPollWait                  30                                                                                       Integer
  \     Subsystem  Infrastructure Actuate Reports Subsystem       Server level      Server
  level set      Y   N   N   N   Actuate Server Poll Wait Limit                                                                                                                                           \n"
- "ActuateRequestPollInterval             10,0,0,10                                                                                String
  \      Subsystem  Infrastructure Actuate Reports Subsystem       Default value     Default
  value         Y   N   N   N   Actuate Request Status Poll Interval                                                                                                                                     \n"
- "ActuateRoxDir                          /Siebel Reports/                                                                         String
  \      Subsystem  Infrastructure Actuate Reports Subsystem       Server level      Server
  level set      Y   N   N   N   Actuate Server Rox Directory                                                                                                                                             \n"
- "AddToCartAutoQuote                     TRUE                                                                                     String
  \      Subsystem  Infrastructure Shopping Service Subsystem      Default value     Default
  value         Y   N   N   N   AddToCartAutoQuote                                                                                                                                                       \n"
- "AddToCartGotoView                      NONE                                                                                     String
  \      Subsystem  Infrastructure Shopping Service Subsystem      Default value     Default
  value         Y   N   N   N   AddToCartGotoView                                                                                                                                                        \n"
- "AddressList                                                                                                                     String
  \      Subsystem  Communications Outbound Manager                Never set         Never
  set             N   N   N   N   Address List                                                                                                                                                             \n"
- "AnonymousQuote                         FALSE                                                                                    String
  \      Subsystem  Infrastructure Shopping Service Subsystem      Default value     Default
  value         Y   N   N   N   AnonymousQuote                                                                                                                                                           \n"
- "AppendOrigMsg                                                                                                                   String
  \      Subsystem  Communications Outbound Manager                Never set         Never
  set             N   N   N   N   Append Original Message                                                                                                                                                  \n"
- "AssetBasedOrderingEnabled              False                                                                                    Boolean
  \     Subsystem  Object Manager                                 Default value     Default
  value         Y   N   N   N   Order Management - Enable Asset Based Ordering                                                                                                                           \n"
- "AttachFileList                                                                                                                  String
  \      Subsystem  Communications Outbound Manager                Never set         Never
  set             N   N   N   N   Attachment File List                                                                                                                                                     \n"
- "AttachNameList                                                                                                                  String
  \      Subsystem  Communications Outbound Manager                Never set         Never
  set             N   N   N   N   Attachment Name List                                                                                                                                                     \n"
- "AutoQuoteDefaultOwner                  TRUE                                                                                     String
  \      Subsystem  Infrastructure Shopping Service Subsystem      Default value     Default
  value         Y   N   N   N   AutoQuoteDefaultOwner                                                                                                                                                    \n"
- "AutoRestart                            True                                                                                     Boolean
  \     Subsystem  Process Management                             Default value     Default
  value         Y   N   N   N   Auto Restart                                                                                                                                                             \n"
- "AutoStart                              True                                                                                     Boolean
  \     Server                                                    Default value     Default
  value         Y   N   N   N   Auto Startup Mode                                                                                                                                                        \n"
- "BizRuleUseLIC                          False                                                                                    Boolean
  \     Subsystem  Rules Engine                                   Default value     Default
  value         Y   N   N   N   Use LIC for Business Rules                                                                                                                                               \n"
- "BusObjCacheSize                        0                                                                                        Integer
  \     Subsystem  EAI                                            Never set         Never
  set             Y   N   N   N   Business Object Cache Size                                                                                                                                               \n"
- "BusinessServiceQueryAccessList                                                                                                  String
  \      Subsystem  Object Manager                                 Never set         Never
  set             N   N   N   N   Business Service Query Access List                                                                                                                                       \n"
- "CACertFileName                                                                                                                  String
  \      Subsystem  Networking                                     Never set         Never
  set             N   N   Y   N   CA certificate file name                                                                                                                                                 \n"
- "CFGAccessDir                           \\sea\\access                                                                              String
  \      Subsystem  Infrastructure Objmgr configuration subsystem  Default value     Default
  value         Y   N   N   N   Application Access Directory                                                                                                                                             \n"
- "CFGClientRootDir                       /app/siebel/siebsrvr                                                                     String
  \      Subsystem  Infrastructure Objmgr configuration subsystem  Server level      Server
  level set      Y   N   N   N   Application Client Rootdir                                                                                                                                               \n"
- "CFGCorbaDLL                                                                                                                     String
  \      Subsystem  Infrastructure Objmgr configuration subsystem  Never set         Never
  set             Y   N   N   N   Application Corba DLL                                                                                                                                                    \n"
- "CFGCorrespODBCDatasource               Siebel Reports: Access                                                                   String
  \      Subsystem  Infrastructure Objmgr configuration subsystem  Default value     Default
  value         Y   N   N   N   Application Correspondence ODBC datasource                                                                                                                               \n"
- "CFGDatasource                          ServerDataSrc                                                                            String
  \      Subsystem  Infrastructure Objmgr configuration subsystem  Default value     Default
  value         Y   N   N   N   Application Datasource                                                                                                                                                   \n"
- "CFGDocumentIntegrator                  Microsoft Office                                                                         String
  \      Subsystem  Infrastructure Objmgr configuration subsystem  Default value     Default
  value         Y   N   N   N   Application Document Integrator                                                                                                                                          \n"
- "CFGEnableBizRule                       True                                                                                     Boolean
  \     Subsystem  Infrastructure Objmgr configuration subsystem  Default value     Default
  value         Y   N   N   N   Enable Business Rule modules                                                                                                                                             \n"
- "CFGEnableMsgBrdcstCache                False                                                                                    Boolean
  \     Subsystem  Infrastructure Objmgr configuration subsystem  Default value     Default
  value         Y   N   N   N   Application Enable Message Broadcast Cache                                                                                                                               \n"
- "CFGEnableOLEAutomation                 False                                                                                    Boolean
  \     Subsystem  Infrastructure Objmgr configuration subsystem  Server level      Server
  level set      Y   N   N   N   Application OLE Automated Flag                                                                                                                                           \n"
- "CFGEnableScripting                     True                                                                                     Boolean
  \     Subsystem  Infrastructure Objmgr configuration subsystem  Default value     Default
  value         Y   N   N   N   Application Scripting Enabled                                                                                                                                            \n"
- "CFGEnableTrainingQueue                 False                                                                                    Boolean
  \     Subsystem  Infrastructure Objmgr configuration subsystem  Default value     Default
  value         Y   N   N   N   Application Enable Training Queue                                                                                                                                        \n"
- "CFGJTCHelpURL                                                                                                                   String
  \      Subsystem  Infrastructure Objmgr configuration subsystem  Never set         Never
  set             Y   N   N   N   Application JTC HELP URL                                                                                                                                                 \n"
- "CFGJseCorbaConnector                                                                                                            String
  \      Subsystem  Infrastructure Objmgr configuration subsystem  Never set         Never
  set             Y   N   N   N   Application JSE Corba Connector Dll                                                                                                                                      \n"
- "CFGMsgBrdcstCacheSize                  100                                                                                      Integer
  \     Subsystem  Infrastructure Objmgr configuration subsystem  Default value     Default
  value         Y   N   N   N   Application Message Broadcast Cache Size                                                                                                                                 \n"
- "CFGOLEAutomationDLL                    libsscfole.so                                                                            String
  \      Subsystem  Infrastructure Objmgr configuration subsystem  Server level      Server
  level set      Y   N   N   N   Application OLE Automation DLL                                                                                                                                           \n"
- "CFGReportsDir                                                                                                                   String
  \      Subsystem  Infrastructure Objmgr configuration subsystem  Never set         Never
  set             Y   N   N   N   Application Reports Directory                                                                                                                                            \n"
- "CFGScriptingDLL                        sscfjs.so                                                                                String
  \      Subsystem  Infrastructure Objmgr configuration subsystem  Server level      Server
  level set      Y   N   N   N   Application Scripting Dll                                                                                                                                                \n"
- "CFGServerODBCDatasource                                                                                                         String
  \      Subsystem  Infrastructure Objmgr configuration subsystem  Never set         Never
  set             Y   N   N   N   Application Server ODBC datasource                                                                                                                                       \n"
- "CFGSharedModeUsersDir                  /app/siebel/gtwysrvr/fs/userpref                                                         String
  \      Subsystem  Infrastructure Objmgr configuration subsystem  Enterprise level
  \ Enterprise level set  Y   N   N   N   Application Shared Mode users directory
  \                                                                                                                                 \n"
- "CFGShowMessageBar                      User Enable                                                                              String
  \      Subsystem  Infrastructure Objmgr configuration subsystem  Default value     Default
  value         Y   N   N   N   Application Message Bar Flag                                                                                                                                             \n"
- "CFGTempDir                             /app/siebel/siebsrvr/temp                                                                String
  \      Subsystem  Infrastructure Objmgr configuration subsystem  Server level      Server
  level set      Y   N   N   N   Application Client Tempdir                                                                                                                                               \n"
- "CacheCategoryId                        False                                                                                    Boolean
  \     Subsystem  Categorization Manager                         Default value     Default
  value         N   N   N   N   Cache Category ID                                                                                                                                                        \n"
- "CacheStatsEnabled                      False                                                                                    Boolean
  \     Subsystem  Object Manager                                 Default value     Default
  value         N   N   N   N   Cache Statistics Enabled                                                                                                                                                 \n"
- "CatMgrType                             Master                                                                                   String
  \      Subsystem  Categorization Manager                         Default value     Default
  value         N   N   N   N   Categorization Manager Type                                                                                                                                              \n"
- "CertFileName                                                                                                                    String
  \      Subsystem  Networking                                     Never set         Never
  set             N   N   Y   N   Certificate file name                                                                                                                                                    \n"
- "Charset                                                                                                                         String
  \      Subsystem  Communications Outbound Manager                Never set         Never
  set             N   N   N   N   Charset                                                                                                                                                                  \n"
- "CheckErrorLeaks                        False                                                                                    Boolean
  \     Subsystem  Infrastructure Core                            Default value     Default
  value         Y   N   N   N   Check Error Leaks                                                                                                                                                        \n"
- "CheckIfCandidateActive                 False                                                                                    Boolean
  \     Subsystem  Assignment Subsystem                           Default value     Default
  value         Y   N   N   N   Check If CandidateActive                                                                                                                                                 \n"
- "ChildRecipSearchSpec                                                                                                            String
  \      Subsystem  Communications Outbound Manager                Never set         Never
  set             N   N   N   N   Child Recipient Search Spec                                                                                                                                              \n"
- "CommProfile                                                                                                                     String
  \      Subsystem  Communications Outbound Manager                Never set         Never
  set             N   N   N   N   Communication Profile                                                                                                                                                    \n"
- "CommProfileOverride                                                                                                             String
  \      Subsystem  Communications Outbound Manager                Never set         Never
  set             N   N   N   N   Comm Profile Override                                                                                                                                                    \n"
- "CommRequestId                                                                                                                   String
  \      Subsystem  Communications Outbound Manager                Never set         Never
  set             N   N   N   N   Comm Request Id                                                                                                                                                          \n"
- "CommRequestParentId                                                                                                             String
  \      Subsystem  Communications Outbound Manager                Never set         Never
  set             N   N   N   N   Request Parent Id                                                                                                                                                        \n"
- "CommType                               TCPIP                                                                                    String
  \      Subsystem  Networking                                     Default value     Default
  value         Y   N   N   N   Communication Transport                                                                                                                                                  \n"
- "Comments                                                                                                                        String
  \      Subsystem  Communications Outbound Manager                Never set         Never
  set             N   N   N   N   Comm Request Comments                                                                                                                                                    \n"
- "CommentsLogToDBSrvr                    True                                                                                     Boolean
  \     Subsystem  Object Manager                                 Default value     Default
  value         N   N   N   N   Comments logged to DB Server                                                                                                                                             \n"
- "CompPriorityTime                       300                                                                                      Integer
  \     Server                                                    Default value     Default
  value         N   N   Y   N   Component Priority Level Timeout                                                                                                                                         \n"
- "Compress                               NONE                                                                                     String
  \      Subsystem  Networking                                     Default value     Default
  value         Y   N   N   N   Compression Type                                                                                                                                                         \n"
- "CompressedFileDownload                 True                                                                                     Boolean
  \     Subsystem  Object Manager                                 Default value     Default
  value         Y   N   N   N   Compressed File Download                                                                                                                                                 \n"
- "ConfigFile                             siebel.cfg                                                                               String
  \      Subsystem  Object Manager                                 Default value     Default
  value         N   N   Y   N   OM - Configuration File                                                                                                                                                  \n"
- "Connect                                SBL_DEV_DSN                                                                              String
  \      Subsystem  Database Access                                Enterprise level
  \ Enterprise level set  Y   N   N   N   ODBC Data Source                                                                                                                                                         \n"
- "CopyCandSpecData                       No                                                                                       String
  \      Subsystem  Assignment Subsystem                           Default value     Default
  value         Y   N   N   N   Copy Candidate Specific Data                                                                                                                                             \n"
- "CopyPersonSpecData                     No                                                                                       String
  \      Subsystem  Assignment Subsystem                           Default value     Default
  value         Y   N   N   N   Copy Person Specific Data                                                                                                                                                \n"
- "Crypt                                  NONE                                                                                     String
  \      Subsystem  Networking                                     Default value     Default
  value         Y   N   N   N   Encryption Type                                                                                                                                                          \n"
- "DB2DisableAutoCommit                   Y                                                                                        String
  \      Subsystem  Database Access                                Default value     Default
  value         Y   N   N   N   Disable Autocommit                                                                                                                                                       \n"
- "DB2DisableMinMemMode                                                                                                            String
  \      Subsystem  Database Access                                Never set         Never
  set             Y   N   N   N   Disable DB2 CLI MinMemMode                                                                                                                                               \n"
- "DBRollbackSeg                                                                                                                   String
  \      Subsystem  Database Access                                Never set         Never
  set             Y   N   N   N   DataBase Rollback Segment Name                                                                                                                                           \n"
- "DDDSN                                                                                                                           String
  \      Subsystem  Data Dictionary Manager                        Never set         Never
  set             N   N   N   N   ODBC DSN                                                                                                                                                                 \n"
- "DDPWD                                                                                                                           String
  \      Subsystem  Data Dictionary Manager                        Never set         Never
  set             N   N   N   N   Database PWD                                                                                                                                                             \n"
- "DDTABLEID                                                                                                                       String
  \      Subsystem  Data Dictionary Manager                        Never set         Never
  set             N   N   N   N   TABLEID                                                                                                                                                                  \n"
- "DDTABLENAME                                                                                                                     String
  \      Subsystem  Data Dictionary Manager                        Never set         Never
  set             N   N   N   N   Database TABLENAME                                                                                                                                                       \n"
- "DDTABLEOWNER                                                                                                                    String
  \      Subsystem  Data Dictionary Manager                        Never set         Never
  set             N   N   N   N   Database TABLEOWNER                                                                                                                                                      \n"
- "DDUID                                                                                                                           String
  \      Subsystem  Data Dictionary Manager                        Never set         Never
  set             N   N   N   N   Database UID                                                                                                                                                             \n"
- "DSChartImageFormat                                                                                                              String
  \      Subsystem  Datasources Subsystem                          Never set         Never
  set             Y   N   N   N   Chart Image Format                                                                                                                                                       \n"
- "DSChartServer                                                                                                                   String
  \      Subsystem  Datasources Subsystem                          Never set         Never
  set             Y   N   N   N   Chart Server                                                                                                                                                             \n"
- "DSUseNativeDbConnPooling               False                                                                                    Boolean
  \     Subsystem  Datasources Subsystem                          Default value     Default
  value         N   Y   N   Y   Enable or Disable the DB Native Connection Pooling
  \                                                                                                                      \n"
- "DataCleansingType                      Vendor1                                                                                  String
  \      Subsystem  Infrastructure Datacleansing subsystem         Enterprise level
  \ Enterprise level set  Y   N   N   N   Data Cleansing Type                                                                                                                                                      \n"
- "DataSource                             ServerDataSrc                                                                            String
  \      Subsystem  Object Manager                                 Default value     Default
  value         Y   N   N   N   OM - Data Source                                                                                                                                                         \n"
- "DeDupTypeType                          None                                                                                     String
  \      Subsystem  Infrastructure DeDuplication subsystem         Enterprise level
  \ Enterprise level set  Y   N   N   N   DeDuplication Data Type                                                                                                                                                  \n"
- "DefaultAdminAddress                                                                                                             String
  \      Subsystem  SMTP subsystem                                 Never set         Never
  set             Y   N   N   N   Default Administrator Address                                                                                                                                            \n"
- "DefaultAnalyticsWebServer              Default Analytics Web Server                                                             String
  \      Subsystem  Marketing Server Subsystem                     Default value     Default
  value         Y   N   N   N   Default Analytics Web Server                                                                                                                                             \n"
- "DefaultFromAddress                                                                                                              String
  \      Subsystem  SMTP subsystem                                 Never set         Never
  set             Y   N   N   N   Default From Address                                                                                                                                                     \n"
- "DefaultLeadListFormat                  /shared/Marketing/Example List Formats/Galena
  - Analytics Data Load - Leads example      String       Subsystem  Marketing Server
  Subsystem                     Default value     Default value         Y   N   N
  \  N   Default Lead List Format                                                                                                                                                 \n"
- "DefaultResponseListFormat              /shared/Marketing/Example List Formats/Galena
  - Analytics Data Load - Responses example  String       Subsystem  Marketing Server
  Subsystem                     Default value     Default value         Y   N   N
  \  N   Default Response List Format                                                                                                                                             \n"
- "DefinedComponent                                                                                                                String
  \      Subsystem  Communications Outbound Manager                Never set         Never
  set             N   N   N   N   Defined Component                                                                                                                                                        \n"
- "DisableNotification                    False                                                                                    Boolean
  \     Subsystem  Infrastructure Notification                    Default value     Default
  value         N   N   N   N   Disable Notification                                                                                                                                                     \n"
- "DocumentServerName                                                                                                              String
  \      Subsystem  eDoc Sub System                                Never set         Never
  set             N   N   N   N   Document Server Name                                                                                                                                                     \n"
- "DynCandParam                                                                                                                    String
  \      Subsystem  Assignment Subsystem                           Never set         Never
  set             Y   N   N   N   Dynamic Candidate Parameters                                                                                                                                             \n"
- "EAIOutboundWaitTime                    30                                                                                       Integer
  \     Subsystem  Infrastructure EAI Outbound Subsystem          Default value     Default
  value         Y   N   N   N   EAI Outbound Wait Time Limit                                                                                                                                             \n"
- "EAISSLCertFile                                                                                                                  String
  \      Subsystem  Infrastructure EAI Outbound Subsystem          Never set         Never
  set             N   N   Y   N   EAI SSL Cert File                                                                                                                                                        \n"
- "EAISSLEnabled                          False                                                                                    Boolean
  \     Subsystem  Infrastructure EAI Outbound Subsystem          Default value     Default
  value         N   N   Y   N   EAI SSL Enabled                                                                                                                                                          \n"
- "EAISSLHostVerification                 True                                                                                     Boolean
  \     Subsystem  Infrastructure EAI Outbound Subsystem          Default value     Default
  value         N   N   Y   N   EAI SSL Host Name Verification                                                                                                                                           \n"
- "EAISSLKeyFile                                                                                                                   String
  \      Subsystem  Infrastructure EAI Outbound Subsystem          Never set         Never
  set             N   N   Y   N   EAI SSL Key File                                                                                                                                                         \n"
- "EAISSLTrustStore                                                                                                                String
  \      Subsystem  Infrastructure EAI Outbound Subsystem          Never set         Never
  set             N   N   Y   N   EAI SSL Trust Store                                                                                                                                                      \n"
- "EAISSLTrustStorePass                   ********                                                                                 String
  \      Subsystem  Infrastructure EAI Outbound Subsystem          Never set         Never
  set             N   N   Y   N   EAI SSL Trust Store Password                                                                                                                                             \n"
- "EligibilityDisplayMode                 1                                                                                        Integer
  \     Subsystem  PSP Engine                                     Default value     Default
  value         Y   N   N   N   Eligibility Display Mode                                                                                                                                                 \n"
- "EmailDebugLevel                        0                                                                                        Integer
  \     Subsystem  Email Client Subsystem                         Never set         Never
  set             Y   N   N   N   Email Client Debug Level                                                                                                                                                 \n"
- "EmailDefaultClient                     Siebel Mail Client                                                                       String
  \      Subsystem  Email Client Subsystem                         Default value     Default
  value         Y   N   N   N   Default Email Client                                                                                                                                                     \n"
- "EmailExtMailClientAttDir                                                                                                        String
  \      Subsystem  Email Client Subsystem                         Never set         Never
  set             Y   N   N   N   Email Temporary Attachment Location                                                                                                                                      \n"
- "EmailLotusForm                                                                                                                  String
  \      Subsystem  Email Client Subsystem                         Never set         Never
  set             Y   N   N   N   Siebel/Lotus Form                                                                                                                                                        \n"
- "EmailOutlookForm                                                                                                                String
  \      Subsystem  Email Client Subsystem                         Never set         Never
  set             Y   N   N   N   Siebel/Outlook Form                                                                                                                                                      \n"
- "EmailPersonalizationFormat             Default Merge Fields                                                                     String
  \      Subsystem  Marketing Server Subsystem                     Default value     Default
  value         Y   N   N   N   Email Personalization Format                                                                                                                                             \n"
- "EnableAssetBasedOrdering               FALSE                                                                                    String
  \      Subsystem  OrderManagement                                Default value     Default
  value         Y   N   N   N   Enable Asset Based Ordering                                                                                                                                              \n"
- "EnableEAIMemoryMetrics                 False                                                                                    Boolean
  \     Subsystem  EAI                                            Default value     Default
  value         Y   N   N   N   Enable Memory Metrics for EAI                                                                                                                                            \n"
- "EnableEventHistory                     True                                                                                     Boolean
  \     Subsystem  Infrastructure Core                            Default value     Default
  value         N   N   N   N   Enable Event History Facility                                                                                                                                            \n"
- "EnableNewOutboundDispatcher            N                                                                                        String
  \      Subsystem  EAI                                            Default value     Default
  value         Y   N   N   N   Enable New Outbound Dispatcher                                                                                                                                           \n"
- "EnablePrePickCompatibility             False                                                                                    Boolean
  \     Subsystem  OrderManagement                                Default value     Default
  value         N   N   N   N   Enable Pre Pick Compatibility                                                                                                                                            \n"
- "EnableServiceArgTracing                False                                                                                    Boolean
  \     Subsystem  EAI                                            Default value     Default
  value         Y   N   N   N   Enable Business Service Argument Tracing                                                                                                                                 \n"
- "EnableTransferCart                     FALSE                                                                                    String
  \      Subsystem  Infrastructure Shopping Service Subsystem      Default value     Default
  value         Y   N   N   N   EnableTransferCart                                                                                                                                                       \n"
- "EnableVirtualHosts                     False                                                                                    Boolean
  \     Subsystem  Client Uses Session Manager                    Default value     Default
  value         N   N   Y   N   Enable internal load balancing                                                                                                                                           \n"
- "EngineID                                                                                                                        String
  \      Subsystem  PIMSI Engine                                   Never set         Never
  set             N   Y   N   Y   Engine Id                                                                                                                                                                \n"
- "ErrorBufferSize                        1000                                                                                     Integer
  \     Server                                                    Default value     Default
  value         N   N   Y   N   Size of Error Buffer                                                                                                                                                     \n"
- "EventSleepTime                         30                                                                                       Integer
  \     Subsystem  Infrastructure Core                            Default value     Default
  value         Y   N   N   N   Event History Sleep Time                                                                                                                                                 \n"
- "ExtDBODBCDataSource                                                                                                             String
  \      Subsystem  External DB Subsystem                          Never set         Never
  set             Y   N   N   N   External DB ODBC Data Source                                                                                                                                             \n"
- "ExtDBPassword                          ********                                                                                 String
  \      Subsystem  External DB Subsystem                          Never set         Never
  set             Y   N   N   N   External DB Password                                                                                                                                                     \n"
- "ExtDBTableOwner                                                                                                                 String
  \      Subsystem  External DB Subsystem                          Never set         Never
  set             Y   N   N   N   External DB Table Owner                                                                                                                                                  \n"
- "ExtDBUserName                                                                                                                   String
  \      Subsystem  External DB Subsystem                          Never set         Never
  set             Y   N   N   N   External DB User Name                                                                                                                                                    \n"
- "FDRAppendFile                          False                                                                                    Boolean
  \     Subsystem  (FDR) Flight Data Recorder                     Default value     Default
  value         N   N   N   N   FDR Periodic Dump and Append                                                                                                                                             \n"
- "FDRBufferSize                          5000000                                                                                  Integer
  \     Subsystem  (FDR) Flight Data Recorder                     Default value     Default
  value         N   Y   N   Y   FDR Buffer Size                                                                                                                                                          \n"
- "FileSystem                             /app/siebel/gtwysrvr/fs                                                                  String
  \      Subsystem  Infrastructure Core                            Enterprise level
  \ Enterprise level set  Y   N   N   N   Siebel File System                                                                                                                                                       \n"
- "ForwardFlag                                                                                                                     String
  \      Subsystem  Communications Outbound Manager                Never set         Never
  set             N   N   N   N   Forward Flag                                                                                                                                                             \n"
- "HTTPKeepAlive                          0                                                                                        Integer
  \     Subsystem  Networking                                     Default value     Default
  value         Y   N   N   N   Server http keepalive time                                                                                                                                               \n"
- "Host                                   siebfoobar                                                                               String
  \      Server                                                    Server level      Server
  level set      N   N   Y   N   Host Name                                                                                                                                                                \n"
- "ISSCtxtNumSignals                      150                                                                                      Integer
  \     Subsystem  Object Manager                                 Default value     Default
  value         Y   N   N   N   ISS Context - Maximum number of signal objects cached
  in memory                                                                                                          \n"
- "ISSCtxtNumVarMaps                      100                                                                                      Integer
  \     Subsystem  Object Manager                                 Default value     Default
  value         Y   N   N   N   ISS Context - Maximum number of variable map objects
  cached in memory                                                                                                    \n"
- "ISSCtxtSignalSnapshot                  True                                                                                     Boolean
  \     Subsystem  Object Manager                                 Default value     Default
  value         Y   N   N   N   ISS Context - Collect and use snapshots of ISS Context
  signal metadata                                                                                                   \n"
- "ISSCtxtVarMapSnapshot                  True                                                                                     Boolean
  \     Subsystem  Object Manager                                 Default value     Default
  value         Y   N   N   N   ISS Context - Collect and use snapshots of ISS Context
  variable maps                                                                                                     \n"
- "IdxSpace                                                                                                                        String
  \      Subsystem  Database Access                                Never set         Never
  set             Y   N   N   N   Indexspace Name                                                                                                                                                          \n"
- "ImportBatchSize                        1000                                                                                     Integer
  \     Subsystem  Marketing Server Subsystem                     Default value     Default
  value         Y   N   N   N   Import Batch Size                                                                                                                                                        \n"
- "Industries                                                                                                                      String
  \      Subsystem  Vertical                                       Never set         Never
  set             Y   N   N   N   OM - Industries                                                                                                                                                          \n"
- "JVMsubsys                              JAVA                                                                                     String
  \      Subsystem  EAI                                            Default value     Default
  value         Y   N   N   N   JVM Subsystem Name                                                                                                                                                       \n"
- "KBName                                 KB                                                                                       String
  \      Subsystem  Categorization Manager                         Default value     Default
  value         N   N   N   N   Knowledge Base Name                                                                                                                                                      \n"
- "KBWriteInterval                        100                                                                                      Integer
  \     Subsystem  Categorization Manager                         Default value     Default
  value         N   N   N   N   KB Write Back Interval                                                                                                                                                   \n"
- "KeepSuccessMessage                     False                                                                                    Boolean
  \     Subsystem  Communications Outbound Manager                Never set         Never
  set             N   N   N   N   Keep Successful Tracking Message                                                                                                                                         \n"
- "KeyFileName                                                                                                                     String
  \      Subsystem  Networking                                     Never set         Never
  set             N   N   Y   N   Private key file name                                                                                                                                                    \n"
- "KeyFilePassword                        ********                                                                                 String
  \      Subsystem  Networking                                     Never set         Never
  set             N   N   Y   N   Private key file password                                                                                                                                                \n"
- "LOYEngineMemberSync                    Y                                                                                        String
  \      Subsystem  LoyEngineBatch                                 Default value     Default
  value         Y   N   N   N   LOY - Engine Member Synchronization                                                                                                                                      \n"
- "LOYEngineNumberOfRuns                  -1                                                                                       Integer
  \     Subsystem  LoyEngineBatch                                 Default value     Default
  value         Y   N   N   N   LOY - Engine Number of Runs                                                                                                                                              \n"
- "LOYEngineNumberofTasks                 0                                                                                        Integer
  \     Subsystem  LoyEngineBatch                                 Default value     Default
  value         Y   N   N   N   LOY - Engine Number of Tasks                                                                                                                                             \n"
- "LOYEngineQueueObjects                  Transaction:500,Bucket:200                                                               String
  \      Subsystem  LoyEngineBatch                                 Default value     Default
  value         Y   N   N   N   LOY - Engine Queue Objects                                                                                                                                               \n"
- "LOYEngineSearchSpec                                                                                                             String
  \      Subsystem  LoyEngineBatch                                 Never set         Never
  set             Y   N   N   N   LOY - Engine Search Specification                                                                                                                                        \n"
- "LOYEngineSleepTime                     5                                                                                        Integer
  \     Subsystem  LoyEngineBatch                                 Default value     Default
  value         Y   N   N   N   LOY - Engine Sleep Time (secs.)                                                                                                                                          \n"
- "LOYIPNumOfObjPerTask                   30                                                                                       Integer
  \     Subsystem  LoyEngineInteractive                           Default value     Default
  value         Y   N   N   N   LOY - Interactive Number of Objects in Task                                                                                                                              \n"
- "LOYIPParaMemberTxn                     Y                                                                                        String
  \      Subsystem  LoyEngineInteractive                           Default value     Default
  value         Y   N   N   N   LOY - Interactive Parallel Member Trasnactions                                                                                                                           \n"
- "LOYIPSleepTime                         5                                                                                        Integer
  \     Subsystem  LoyEngineInteractive                           Default value     Default
  value         Y   N   N   N   LOY - Interactive Task Sleep Time (secs.)                                                                                                                                \n"
- "Lang                                   enu                                                                                      String
  \      Subsystem  Infrastructure Core                            Server level      Server
  level set      Y   N   N   N   Language Code                                                                                                                                                            \n"
- "ListenOneIPAddress                     False                                                                                    Boolean
  \     Server                                                    Default value     Default
  value         N   N   Y   N   Listen One IP Address                                                                                                                                                    \n"
- "LoadAtStart                            True                                                                                     Boolean
  \     Subsystem  Categorization Manager                         Default value     Default
  value         N   N   N   N   Load KB at Startup                                                                                                                                                       \n"
- "LocaleCode                                                                                                                      String
  \      Subsystem  Object Manager                                 Never set         Never
  set             N   Y   N   Y   Locale Code                                                                                                                                                              \n"
- "LogArchive                             2                                                                                        Integer
  \     Subsystem  Event Logging                                  Server level      Server
  level set      Y   N   N   N   Log Archive Keep                                                                                                                                                         \n"
- "LogArchiveDir                                                                                                                   String
  \      Subsystem  Event Logging                                  Never set         Never
  set             Y   N   N   N   Log Archive Directory                                                                                                                                                    \n"
- "LogDir                                 /app/siebel/siebsrvr/enterprises/SBL_DEV/siebfoobar/log
  \                                 String       Subsystem  Event Logging                                  Server
  level      Server level set      N   N   N   N   Log directory                                                                                                                                                            \n"
- "LogFlushFreq                           0                                                                                        Integer
  \     Subsystem  Event Logging                                  Default value     Default
  value         N   N   N   N   Number of lines after which to flush the log file
  \                                                                                                                       \n"
- "LogMaxSegments                         0                                                                                        Integer
  \     Subsystem  Event Logging                                  Default value     Default
  value         N   N   N   N   Maximum number of log file segments                                                                                                                                      \n"
- "LogSegmentSize                         0                                                                                        Integer
  \     Subsystem  Event Logging                                  Default value     Default
  value         N   N   N   N   Log file segment size in KB                                                                                                                                              \n"
- "LogTimestamp                           True                                                                                     Boolean
  \     Subsystem  Event Logging                                  Default value     Default
  value         N   N   N   N   Log Print Timestamp                                                                                                                                                      \n"
- "LogUseErrorBuffer                      False                                                                                    Boolean
  \     Subsystem  Event Logging                                  Default value     Default
  value         Y   N   N   N   Use Error Buffer                                                                                                                                                         \n"
- "LogUseSharedFile                       False                                                                                    Boolean
  \     Subsystem  Event Logging                                  Default value     Default
  value         Y   N   N   N   Use Shared Log File                                                                                                                                                      \n"
- "LoginDomain                            INTERNAL                                                                                 String
  \      Subsystem  Object Manager                                 Default value     Default
  value         Y   N   N   N   OM - Login Domain                                                                                                                                                        \n"
- "LongTblSpace                                                                                                                    String
  \      Subsystem  Database Access                                Never set         Never
  set             Y   N   N   N   Long Tablespace Name                                                                                                                                                     \n"
- "MarketingFileSystem                    /app/siebel/gtwysrvr/fs                                                                  String
  \      Subsystem  Marketing Server Subsystem                     Enterprise level
  \ Enterprise level set  Y   N   N   N   Marketing File System                                                                                                                                                    \n"
- "MarketingFileSystemForCommOutboundMgr                                                                                           String
  \      Subsystem  Marketing Server Subsystem                     Never set         Never
  set             Y   N   N   N   Marketing File System for Communications Outbound
  Manager                                                                                                                \n"
- "MarketingWorkflowProcessManager                                                                                                 String
  \      Subsystem  Marketing Server Subsystem                     Never set         Never
  set             Y   N   N   N   Marketing Workflow Process Manager                                                                                                                                       \n"
- "MarketingWorkflowServer                                                                                                         String
  \      Subsystem  Marketing Server Subsystem                     Never set         Never
  set             Y   N   N   N   Marketing Workflow Server                                                                                                                                                \n"
- "MaxNumCat                              4                                                                                        Integer
  \     Subsystem  Categorization Manager                         Default value     Default
  value         N   N   N   N   Maximum Number of Categories                                                                                                                                             \n"
- "MaxSharedDbConns                       -1                                                                                       Integer
  \     Subsystem  Object Manager                                 Default value     Default
  value         N   N   Y   N   DB Multiplex - Max Number of Shared DB Connections
  \                                                                                                                      \n"
- "MaxTaskHistory                         20                                                                                       Integer
  \     Subsystem  Process Management                             Default value     Default
  value         N   N   Y   N   Maximum Historic Tasks                                                                                                                                                   \n"
- "MaxThreads                             20                                                                                       Integer
  \     Subsystem  Communications Inbound Processor               Default value     Default
  value         Y   N   N   N   Max Threads                                                                                                                                                              \n"
- "MaximumPageSize                        100                                                                                      Integer
  \     Subsystem  EAI                                            Default value     Default
  value         Y   N   N   N   Maximum Page Size                                                                                                                                                        \n"
- "MemoryBasedRecycle                     False                                                                                    Boolean
  \     Subsystem  Multi-Threading                                Default value     Default
  value         Y   N   N   N   Memory usage based multithread shell recycling                                                                                                                           \n"
- "MemoryLimit                            1500                                                                                     Integer
  \     Subsystem  Multi-Threading                                Default value     Default
  value         Y   N   N   N   Process VM usage lower limit                                                                                                                                             \n"
- "MemoryLimitPercent                     20                                                                                       Integer
  \     Subsystem  Multi-Threading                                Default value     Default
  value         Y   N   N   N   Process VM usage upper limit                                                                                                                                             \n"
- "MessageObjectId                                                                                                                 String
  \      Subsystem  Communications Outbound Manager                Never set         Never
  set             N   N   N   N   Message Tracking Object Id                                                                                                                                               \n"
- "MessageTracking                        False                                                                                    Boolean
  \     Subsystem  Communications Outbound Manager                Never set         Never
  set             N   N   N   N   Message Tracking                                                                                                                                                         \n"
- "MessageType                                                                                                                     String
  \      Subsystem  Communications Outbound Manager                Never set         Never
  set             N   N   N   N   Message Tracking Type                                                                                                                                                    \n"
- "MinSharedDbConns                       -1                                                                                       Integer
  \     Subsystem  Object Manager                                 Default value     Default
  value         N   N   Y   N   DB Multiplex - Min Number of Shared DB Connections
  \                                                                                                                      \n"
- "MinTrxDbConns                          -1                                                                                       Integer
  \     Subsystem  Object Manager                                 Default value     Default
  value         N   N   Y   N   DB Multiplex - Min Number of Dedicated DB Connections
  \                                                                                                                   \n"
- "MinUpTime                              60                                                                                       Integer
  \     Subsystem  Process Management                             Default value     Default
  value         Y   N   N   N   Minimum Up Time                                                                                                                                                          \n"
- "ModelCacheMax                          10                                                                                       Integer
  \     Subsystem  Object Manager                                 Default value     Default
  value         Y   N   N   N   OM - Model Cache Maximum                                                                                                                                                 \n"
- "MsgBccList                                                                                                                      String
  \      Subsystem  Communications Outbound Manager                Never set         Never
  set             N   N   N   N   Message Bcc List                                                                                                                                                         \n"
- "MsgBody                                                                                                                         String
  \      Subsystem  Communications Outbound Manager                Never set         Never
  set             N   N   N   N   Message Body                                                                                                                                                             \n"
- "MsgCcList                                                                                                                       String
  \      Subsystem  Communications Outbound Manager                Never set         Never
  set             N   N   N   N   Message Cc List                                                                                                                                                          \n"
- "MsgClientAddInCacheRefreshInterval     4320                                                                                     Integer
  \     Subsystem  Messaging Client Subsystem                     Default value     Default
  value         Y   N   N   N   Messaging Client AddIn Cache Refresh Interval                                                                                                                            \n"
- "MsgClientAddInCommModule               EAI                                                                                      String
  \      Subsystem  Messaging Client Subsystem                     Default value     Default
  value         Y   N   N   N   Messaging Client AddIn Communication Module                                                                                                                              \n"
- "MsgClientAddInEAIUrl                                                                                                            String
  \      Subsystem  Messaging Client Subsystem                     Never set         Never
  set             Y   N   N   N   Messaging Client AddIn EAI Url                                                                                                                                           \n"
- "MsgClientAddInLinkHistory              30                                                                                       Integer
  \     Subsystem  Messaging Client Subsystem                     Default value     Default
  value         Y   N   N   N   Messaging Client AddIn Link History                                                                                                                                      \n"
- "MsgFrom                                                                                                                         String
  \      Subsystem  Communications Outbound Manager                Never set         Never
  set             N   N   N   N   Message From                                                                                                                                                             \n"
- "MsgHTMLBody                                                                                                                     String
  \      Subsystem  Communications Outbound Manager                Never set         Never
  set             N   N   N   N   Message HTML Body                                                                                                                                                        \n"
- "MsgReplyToAddressList                                                                                                           String
  \      Subsystem  Communications Outbound Manager                Never set         Never
  set             N   N   N   N   MessageReplyAddress  List                                                                                                                                                \n"
- "MsgSubject                                                                                                                      String
  \      Subsystem  Communications Outbound Manager                Never set         Never
  set             N   N   N   N   Message Subject                                                                                                                                                          \n"
- "MsgToList                                                                                                                       String
  \      Subsystem  Communications Outbound Manager                Never set         Never
  set             N   N   N   N   Message To List                                                                                                                                                          \n"
- "MssqlOptimizeCursorFlg                 False                                                                                    Boolean
  \     Subsystem  Database Access                                Default value     Default
  value         N   Y   N   Y   MSSQL Optimize Cursor Flag                                                                                                                                               \n"
- "MuteIdleState                          False                                                                                    Boolean
  \     Subsystem  Infrastructure Core                            Never set         Never
  set             Y   N   N   N   Mute Idle State                                                                                                                                                          \n"
- "NotifyHandler                          AdminEmailAlert                                                                          String
  \      Subsystem  Infrastructure Notification                    Server level      Server
  level set      N   N   N   N   Notification Handler                                                                                                                                                     \n"
- "NotifyOnTaskExit                       0                                                                                        Integer
  \     Subsystem  Infrastructure Notification                    Default value     Default
  value         N   N   N   N   Notification Action on Task Exit                                                                                                                                         \n"
- "NotifyTimeOut                          100                                                                                      Integer
  \     Subsystem  Infrastructure Notification                    Default value     Default
  value         N   N   N   N   Time to wait for doing notification                                                                                                                                      \n"
- "NumRecipients                                                                                                                   String
  \      Subsystem  Communications Outbound Manager                Never set         Never
  set             N   N   N   N   Number Of Recipients                                                                                                                                                     \n"
- "NumRestart                             10                                                                                       Integer
  \     Subsystem  Process Management                             Default value     Default
  value         Y   N   N   N   Numbers of Restarts                                                                                                                                                      \n"
- "NumRetries                             10000                                                                                    Integer
  \     Subsystem  Recovery                                       Default value     Default
  value         Y   N   N   N   Number of Retries                                                                                                                                                        \n"
- "NumTasks                                                                                                                        String
  \      Subsystem  Communications Outbound Manager                Never set         Never
  set             N   N   N   N   Number Of Tasks                                                                                                                                                          \n"
- "ORCLBatchSize                          0                                                                                        Integer
  \     Subsystem  External DB Subsystem                          Never set         Never
  set             Y   N   N   N   ORCL Batch Size                                                                                                                                                          \n"
- "ORCLGroupSize                          0                                                                                        Integer
  \     Subsystem  External DB Subsystem                          Never set         Never
  set             Y   N   N   N   ORCL Group Size                                                                                                                                                          \n"
- "ORCLQueueName                                                                                                                   String
  \      Subsystem  External DB Subsystem                          Never set         Never
  set             Y   N   N   N   ORCL Queue Name                                                                                                                                                          \n"
- "OrderCartBC                            Order Entry - Orders                                                                     String
  \      Subsystem  Infrastructure Shopping Service Subsystem      Default value     Default
  value         Y   N   N   N   OrderCartBC                                                                                                                                                              \n"
- "OrderCartView                          Order Entry - Line Items View (Sales)                                                    String
  \      Subsystem  Infrastructure Shopping Service Subsystem      Default value     Default
  value         Y   N   N   N   OrderCartView                                                                                                                                                            \n"
- "OrigMsgFile                                                                                                                     String
  \      Subsystem  Communications Outbound Manager                Never set         Never
  set             N   N   N   N   Original Message File                                                                                                                                                    \n"
- "PSPCacheMaxItemCntLevel1               10000                                                                                    Integer
  \     Subsystem  PSP Engine                                     Default value     Default
  value         Y   N   N   N   PSP Level 1 Cache Max Item Count                                                                                                                                         \n"
- "PSPCacheMaxItemCntLevel2               10000                                                                                    Integer
  \     Subsystem  PSP Engine                                     Default value     Default
  value         Y   N   N   N   PSP Level 2 Cache Max Item Count                                                                                                                                         \n"
- "PackageNameList                                                                                                                 String
  \      Subsystem  Communications Outbound Manager                Never set         Never
  set             N   N   N   N   Comm Template Name List                                                                                                                                                  \n"
- "ParametricSearchResultsView            Parametric Search Results View                                                           String
  \      Subsystem  Infrastructure Shopping Service Subsystem      Default value     Default
  value         Y   N   N   N   ParametricSearchResultsView                                                                                                                                              \n"
- "Password                               ********                                                                                 String
  \      Subsystem  Database Access                                Enterprise level
  \ Enterprise level set  Y   N   N   N   Password                                                                                                                                                                 \n"
- "PeerAuth                               False                                                                                    Boolean
  \     Subsystem  Networking                                     Default value     Default
  value         N   N   Y   N   Peer Authentication                                                                                                                                                      \n"
- "PeerCertValidation                     False                                                                                    Boolean
  \     Subsystem  Networking                                     Default value     Default
  value         N   N   Y   N   Validate peer certificate                                                                                                                                                \n"
- "PersistentShoppingCart                 FALSE                                                                                    String
  \      Subsystem  Infrastructure Shopping Service Subsystem      Default value     Default
  value         Y   N   N   N   PersistentShoppingCart                                                                                                                                                   \n"
- "PostAddToCartLogic                                                                                                              String
  \      Subsystem  Infrastructure Shopping Service Subsystem      Never set         Never
  set             Y   N   N   N   PostAddToCartLogic                                                                                                                                                       \n"
- "PreloadJVM                             False                                                                                    Boolean
  \     Subsystem  Object Manager                                 Default value     Default
  value         N   Y   N   Y   OM - Preload Java VM                                                                                                                                                     \n"
- "PreloadSRF                             False                                                                                    Boolean
  \     Subsystem  Object Manager                                 Default value     Default
  value         N   N   Y   N   OM - Preload SRF Data                                                                                                                                                    \n"
- "PriceListCacheLifeTime                 -1                                                                                       Integer
  \     Subsystem  Infrastructure Pricingcache subsystem          Default value     Default
  value         Y   N   N   N   Price List Cache Life Time                                                                                                                                               \n"
- "PriceListItemCacheLifeTime             -1                                                                                       Integer
  \     Subsystem  Infrastructure Pricingcache subsystem          Default value     Default
  value         Y   N   N   N   Price List Item Cache Life Time                                                                                                                                          \n"
- "PricerMappingCacheSize                 100                                                                                      Integer
  \     Subsystem  Infrastructure Pricingcache subsystem          Default value     Default
  value         Y   N   N   N   Pricer Mapping Cache Size                                                                                                                                                \n"
- "PricerPriceItemCacheSize               100                                                                                      Integer
  \     Subsystem  Infrastructure Pricingcache subsystem          Default value     Default
  value         Y   N   N   N   Price Item Cache Size                                                                                                                                                    \n"
- "PricerPriceListCacheSize               20                                                                                       Integer
  \     Subsystem  Infrastructure Pricingcache subsystem          Default value     Default
  value         Y   N   N   N   Price List Cache Size                                                                                                                                                    \n"
- "PricerPriceModelCacheSize              50                                                                                       Integer
  \     Subsystem  Infrastructure Pricingcache subsystem          Default value     Default
  value         Y   N   N   N   Price Model Cache Size                                                                                                                                                   \n"
- "PricerVolDisCacheSize                  50                                                                                       Integer
  \     Subsystem  Infrastructure Pricingcache subsystem          Default value     Default
  value         Y   N   N   N   Price Volume discount Cache Size                                                                                                                                         \n"
- "ProcessMode                            Remote                                                                                   String
  \      Subsystem  Communications Outbound Manager                Default value     Default
  value         N   N   N   N   Process Mode                                                                                                                                                             \n"
- "ProductDetailView                      NONE                                                                                     String
  \      Subsystem  Infrastructure Shopping Service Subsystem      Default value     Default
  value         Y   N   N   N   ProductDetailView                                                                                                                                                        \n"
- "ProposalReportTimeoutInSecond          1800                                                                                     Integer
  \     Subsystem  eDoc Sub System                                Default value     Default
  value         N   N   N   N   ProposalReportTimeoutInSecond                                                                                                                                            \n"
- "ProxyEmployee                                                                                                                   String
  \      Subsystem  Object Manager                                 Never set         Never
  set             Y   N   N   N   OM - Proxy Employee                                                                                                                                                      \n"
- "QuoteCartBC                            Quote                                                                                    String
  \      Subsystem  Infrastructure Shopping Service Subsystem      Default value     Default
  value         Y   N   N   N   QuoteCartBC                                                                                                                                                              \n"
- "QuoteCartView                          Quote Detail View                                                                        String
  \      Subsystem  Infrastructure Shopping Service Subsystem      Default value     Default
  value         Y   N   N   N   QuoteCartView                                                                                                                                                            \n"
- "RTSSleepTime                           30                                                                                       Integer
  \     Subsystem  RTS Sub System                                 Default value     Default
  value         Y   N   N   N   RTS Sleep Time                                                                                                                                                           \n"
- "RecipSearchSpec                                                                                                                 String
  \      Subsystem  Communications Outbound Manager                Never set         Never
  set             N   N   N   N   Recipient Search Spec                                                                                                                                                    \n"
- "RecipientBusComp                                                                                                                String
  \      Subsystem  Communications Outbound Manager                Never set         Never
  set             N   N   N   N   Recipient Business Component                                                                                                                                             \n"
- "RecipientGroup                                                                                                                  String
  \      Subsystem  Communications Outbound Manager                Never set         Never
  set             N   N   N   N   Recipient Group                                                                                                                                                          \n"
- "RecycleFactor                          0                                                                                        Integer
  \     Subsystem  Multi-Threading                                Default value     Default
  value         N   N   Y   N   Recycle Factor                                                                                                                                                           \n"
- "RegularAsgn                            True                                                                                     Boolean
  \     Subsystem  Assignment Subsystem                           Default value     Default
  value         Y   N   N   N   Regular Assignment                                                                                                                                                       \n"
- "Repository                             Siebel Repository                                                                        String
  \      Subsystem  Database Access                                Default value     Default
  value         Y   N   N   N   Siebel Repository                                                                                                                                                        \n"
- "RequestBodyTemplate                                                                                                             String
  \      Subsystem  Communications Outbound Manager                Never set         Never
  set             N   N   N   N   Request Body Template                                                                                                                                                    \n"
- "RequestDefaultMedium                                                                                                            String
  \      Subsystem  Communications Outbound Manager                Never set         Never
  set             N   N   N   N   Request Default Medium                                                                                                                                                   \n"
- "RequestLanguageCode                                                                                                             String
  \      Subsystem  Communications Outbound Manager                Never set         Never
  set             N   N   N   N   Language Code                                                                                                                                                            \n"
- "RequestLocaleCode                                                                                                               String
  \      Subsystem  Communications Outbound Manager                Never set         Never
  set             N   N   N   N   Locale Code                                                                                                                                                              \n"
- "RequestName                                                                                                                     String
  \      Subsystem  Communications Outbound Manager                Never set         Never
  set             N   N   N   N   Request Name                                                                                                                                                             \n"
- "RequestSendFlag                        N                                                                                        String
  \      Subsystem  Communications Outbound Manager                Default value     Default
  value         N   N   N   N   Request Send Flag                                                                                                                                                        \n"
- "RequestSubjectTemplate                                                                                                          String
  \      Subsystem  Communications Outbound Manager                Never set         Never
  set             N   N   N   N   Request Subject Template                                                                                                                                                 \n"
- "RequestTimeZone                                                                                                                 String
  \      Subsystem  Communications Outbound Manager                Never set         Never
  set             N   N   N   N   Request Time Zone                                                                                                                                                        \n"
- "ResourceAccessControl                  True                                                                                     Boolean
  \     Subsystem  Object Manager                                 Default value     Default
  value         N   N   Y   N   OM - Enable Resource Access Control                                                                                                                                      \n"
- "ResourceLanguage                                                                                                                String
  \      Subsystem  Object Manager                                 Never set         Never
  set             Y   N   N   N   OM - Resource Language Code                                                                                                                                              \n"
- "RestrictPrimaryJoin                    False                                                                                    Boolean
  \     Subsystem  Datasources Subsystem                          Default value     Default
  value         Y   N   N   N   Restrict Primary Join                                                                                                                                                    \n"
- "RetryInterval                          5                                                                                        Integer
  \     Subsystem  Recovery                                       Default value     Default
  value         Y   N   N   N   Retry Interval                                                                                                                                                           \n"
- "RetryUpTime                            600                                                                                      Integer
  \     Subsystem  Recovery                                       Default value     Default
  value         Y   N   N   N   Retry Up Time                                                                                                                                                            \n"
- "RootDir                                /app/siebel/siebsrvr                                                                     String
  \      Server                                                    Server level      Server
  level set      N   N   Y   N   Siebel Root Directory                                                                                                                                                    \n"
- "RptMode                                None                                                                                     String
  \      Subsystem  Assignment Subsystem                           Default value     Default
  value         Y   N   N   N   Reporting Mode                                                                                                                                                           \n"
- "RtdApplicationName                                                                                                              String
  \      Subsystem  Marketing Server Subsystem                     Never set         Never
  set             Y   N   N   N   RTD Application Name                                                                                                                                                     \n"
- "RtdSessionCookieName                   JSESSIONID                                                                               String
  \      Subsystem  Marketing Server Subsystem                     Default value     Default
  value         Y   N   N   N   RTD Session Cookie Name                                                                                                                                                  \n"
- "RtdSoapURL                             http://CHANGE_ME/rtis/sdwp                                                               String
  \      Subsystem  Marketing Server Subsystem                     Default value     Default
  value         Y   N   N   N   RTD SOAP URL                                                                                                                                                             \n"
- "RtdWebServiceTimeout                   3000                                                                                     Integer
  \     Subsystem  Marketing Server Subsystem                     Default value     Default
  value         Y   N   N   N   RTD WebService Timeout                                                                                                                                                   \n"
- "SAPBAPIDispatchMethod                                                                                                           String
  \      Subsystem  SAP                                            Never set         Never
  set             Y   N   N   N   SAP BAPI Dispatch Method Name                                                                                                                                            \n"
- "SAPBAPIDispatchService                                                                                                          String
  \      Subsystem  SAP                                            Never set         Never
  set             Y   N   N   N   SAP BAPI Dispatch Service Name                                                                                                                                           \n"
- "SAPCodepage                                                                                                                     String
  \      Subsystem  SAP                                            Never set         Never
  set             Y   N   N   N   SAP Codepage                                                                                                                                                             \n"
- "SAPIDOCDispatchMethod                                                                                                           String
  \      Subsystem  SAP                                            Never set         Never
  set             Y   N   N   N   SAPIDOC Dispatch Method Name                                                                                                                                             \n"
- "SAPIDOCDispatchService                                                                                                          String
  \      Subsystem  SAP                                            Never set         Never
  set             Y   N   N   N   SAP IDOC Dispatch Service Name                                                                                                                                           \n"
- "SAPIdocAllowedObjects                                                                                                           String
  \      Subsystem  SAP                                            Never set         Never
  set             Y   N   N   N   SAP IDOC Allowed Objects                                                                                                                                                 \n"
- "SAPIgnoreCharSetConvErrors             False                                                                                    String
  \      Subsystem  SAP                                            Default value     Default
  value         Y   N   N   N   SAP Ignore Char Set Conversion Errors                                                                                                                                    \n"
- "SAPInitialSystemCodepage                                                                                                        String
  \      Subsystem  SAP                                            Never set         Never
  set             Y   N   N   N   SAP Initial System Codepage                                                                                                                                              \n"
- "SAPMqLink                              False                                                                                    Boolean
  \     Subsystem  SAP                                            Never set         Never
  set             Y   N   N   N   SAP MQSeries Link                                                                                                                                                        \n"
- "SAPReceiverPrtnrNum                    DFLT_PRTNR                                                                               String
  \      Subsystem  SAP                                            Default value     Default
  value         Y   N   N   N   SAP Receiver Partner Number                                                                                                                                              \n"
- "SAPReceiverPrtnrType                   LS                                                                                       String
  \      Subsystem  SAP                                            Default value     Default
  value         Y   N   N   N   SAP Receiver Partner Type                                                                                                                                                \n"
- "SAPReceiverReconnectTime               0                                                                                        String
  \      Subsystem  SAP                                            Default value     Default
  value         Y   N   N   N   SAP Receiver Reconnect Time                                                                                                                                              \n"
- "SAPRfcConnectString                                                                                                             String
  \      Subsystem  SAP                                            Never set         Never
  set             Y   N   N   N   SAP RFC Connect String                                                                                                                                                   \n"
- "SAPRfcDestEntry                                                                                                                 String
  \      Subsystem  SAP                                            Never set         Never
  set             Y   N   N   N   SAP RFC Destination Entry                                                                                                                                                \n"
- "SAPRfcPassword                         ********                                                                                 String
  \      Subsystem  SAP                                            Never set         Never
  set             Y   N   N   N   SAP RFC Password                                                                                                                                                         \n"
- "SAPRfcTrace                            False                                                                                    Boolean
  \     Subsystem  SAP                                            Never set         Never
  set             Y   N   N   N   SAP RFC Trace                                                                                                                                                            \n"
- "SAPRfcUserName                                                                                                                  String
  \      Subsystem  SAP                                            Never set         Never
  set             Y   N   N   N   SAP RFC User Name                                                                                                                                                        \n"
- "SAPSenderPrtnrNum                                                                                                               String
  \      Subsystem  SAP                                            Never set         Never
  set             Y   N   N   N   SAP Sender Partner Number                                                                                                                                                \n"
- "SAPSenderPrtnrType                     LS                                                                                       String
  \      Subsystem  SAP                                            Default value     Default
  value         Y   N   N   N   SAP Sender Partner Type                                                                                                                                                  \n"
- "SAPSiebelWaitTime                                                                                                               String
  \      Subsystem  SAP                                            Never set         Never
  set             Y   N   N   N   SAP Siebel Wait Time                                                                                                                                                     \n"
- "SAPSleepTime                                                                                                                    String
  \      Subsystem  SAP                                            Never set         Never
  set             Y   N   N   N   SAP Sleep Time                                                                                                                                                           \n"
- "SAPTransactionMode                                                                                                              String
  \      Subsystem  SAP                                            Never set         Never
  set             Y   N   N   N   SAP Transaction Mode                                                                                                                                                     \n"
- "SAPWaitTime                                                                                                                     String
  \      Subsystem  SAP                                            Never set         Never
  set             Y   N   N   N   SAP Wait Time                                                                                                                                                            \n"
- "SAPWakeupCount                                                                                                                  String
  \      Subsystem  SAP                                            Never set         Never
  set             Y   N   N   N   SAP Wakeup Count                                                                                                                                                         \n"
- "SAPWakeupTime                                                                                                                   String
  \      Subsystem  SAP                                            Never set         Never
  set             Y   N   N   N   SAP Wakeup Time                                                                                                                                                          \n"
- "SAPWriteXML                                                                                                                     String
  \      Subsystem  SAP                                            Never set         Never
  set             Y   N   N   N   SAP Write XML Mode                                                                                                                                                       \n"
- "SAPXMLQueueCleanup                                                                                                              String
  \      Subsystem  SAP                                            Never set         Never
  set             Y   N   N   N   SAP XML Queue Cleanup Flag                                                                                                                                               \n"
- "SAPXMLQueueName                                                                                                                 String
  \      Subsystem  SAP                                            Never set         Never
  set             Y   N   N   N   SAP XML Queue Name                                                                                                                                                       \n"
- "SAPXMLQueueService                                                                                                              String
  \      Subsystem  SAP                                            Never set         Never
  set             Y   N   N   N   SAP XML Queue Service Name                                                                                                                                               \n"
- "SAPtRFCService                                                                                                                  String
  \      Subsystem  SAP                                            Never set         Never
  set             Y   N   N   N   SAP tRFC Service Name                                                                                                                                                    \n"
- "SARMBufferSize                         5000000                                                                                  Integer
  \     Subsystem  (SARM) Response Measurement                    Default value     Default
  value         N   N   N   N   SARM Buffer Size                                                                                                                                                         \n"
- "SARMClientLevel                        0                                                                                        Integer
  \     Subsystem  (SARM) Response Measurement                    Default value     Default
  value         N   N   N   N   Sarm Client Granularity Level                                                                                                                                            \n"
- "SARMFileSize                           15000000                                                                                 Integer
  \     Subsystem  (SARM) Response Measurement                    Default value     Default
  value         N   N   N   N   SARM Data File Size                                                                                                                                                      \n"
- "SARMLevel                              0                                                                                        Integer
  \     Subsystem  (SARM) Response Measurement                    Default value     Default
  value         N   N   N   N   SARM Granularity Level                                                                                                                                                   \n"
- "SARMLogDirectory                                                                                                                String
  \      Subsystem  (SARM) Response Measurement                    Never set         Never
  set             N   N   N   N   Sarm Log Directory                                                                                                                                                       \n"
- "SARMMaxFiles                           4                                                                                        Integer
  \     Subsystem  (SARM) Response Measurement                    Default value     Default
  value         N   N   N   N   SARM Max Number of files                                                                                                                                                 \n"
- "SARMPeriod                             3                                                                                        Integer
  \     Subsystem  (SARM) Response Measurement                    Default value     Default
  value         N   N   N   N   SARM Period                                                                                                                                                              \n"
- "SARMThreshold                          0                                                                                        Integer
  \     Subsystem  (SARM) Response Measurement                    Default value     Default
  value         N   N   N   N   Sarm Threshold                                                                                                                                                           \n"
- "SARMUsers                                                                                                                       String
  \      Subsystem  (SARM) Response Measurement                    Never set         Never
  set             N   N   N   N   Sarm Users                                                                                                                                                               \n"
- "SMTPServer                                                                                                                      String
  \      Subsystem  SMTP subsystem                                 Never set         Never
  set             Y   N   N   N   SMTP Server Name                                                                                                                                                         \n"
- "SMTPServerPort                         25                                                                                       Integer
  \     Subsystem  SMTP subsystem                                 Default value     Default
  value         Y   N   N   N   SMTP Server Port                                                                                                                                                         \n"
- "SRB ReqId                              0                                                                                        String
  \      Subsystem  Infrastructure Core                            Default value     Default
  value         Y   N   N   N   SRB RequestId                                                                                                                                                            \n"
- "SSLHello                               False                                                                                    Boolean
  \     Subsystem  Networking                                     Default value     Default
  value         Y   N   N   N   SSL Encrypted SISNAPI HELLO                                                                                                                                              \n"
- "SavePreferences                        True                                                                                     Boolean
  \     Subsystem  Object Manager                                 Default value     Default
  value         N   N   Y   N   OM - Save Preferences                                                                                                                                                    \n"
- "SearchDefName                                                                                                                   String
  \      Subsystem  Object Manager                                 Never set         Never
  set             Y   N   N   N   Search - Definition Name                                                                                                                                                 \n"
- "SearchEngine                           Fulcrum                                                                                  String
  \      Subsystem  Object Manager                                 Default value     Default
  value         Y   N   N   N   Search - Engine Name                                                                                                                                                     \n"
- "SearchInstallDir                                                                                                                String
  \      Subsystem  Object Manager                                 Never set         Never
  set             Y   N   N   N   Search - Install Directory                                                                                                                                               \n"
- "SearchRemoteServer                     FALSE                                                                                    String
  \      Subsystem  Object Manager                                 Default value     Default
  value         Y   N   N   N   Search - Remote Server                                                                                                                                                   \n"
- "SearchRemoteServerPath                                                                                                          String
  \      Subsystem  Object Manager                                 Never set         Never
  set             Y   N   N   N   Search - Remote Server Path                                                                                                                                              \n"
- "SecAdptMode                            DB                                                                                       String
  \      Subsystem  Security Manager                               Enterprise level
  \ Enterprise level set  N   Y   N   Y   Security Adapter Mode                                                                                                                                                    \n"
- "SecAdptName                            DBSecAdpt                                                                                String
  \      Subsystem  Security Manager                               Enterprise level
  \ Enterprise level set  N   Y   N   Y   Security Adapter Name                                                                                                                                                    \n"
- "Server                                                                                                                          String
  \      Server                                                    Never set         Never
  set             Y   N   N   N   Siebel Server Name                                                                                                                                                       \n"
- "ServerDesc                             Siebel Server Profile siebfoobar                                                         String
  \      Server                                                    Server level      Server
  level set      Y   N   N   N   Server Description                                                                                                                                                       \n"
- "ServerHostAddress                                                                                                               String
  \      Server                                                    Never set         Never
  set             N   N   Y   N   Server Host Address                                                                                                                                                      \n"
- "ServerSessionBusSvc                                                                                                             String
  \      Subsystem  Object Manager                                 Never set         Never
  set             N   Y   N   Y   Server Session Business Service                                                                                                                                          \n"
- "ServerSessionBusSvcContext                                                                                                      String
  \      Subsystem  Object Manager                                 Never set         Never
  set             N   N   N   N   Server Session Business Service Context                                                                                                                                  \n"
- "ServerSessionBusSvcMethod                                                                                                       String
  \      Subsystem  Object Manager                                 Never set         Never
  set             N   Y   N   Y   Server Session Business Service Method                                                                                                                                   \n"
- "ServerSessionLoopSleepTime             -1                                                                                       Integer
  \     Subsystem  Object Manager                                 Default value     Default
  value         N   N   N   N   Server Session Loop Sleep Time                                                                                                                                           \n"
- "ShoppingCartView                       Current Quote View (eSales)                                                              String
  \      Subsystem  Infrastructure Shopping Service Subsystem      Default value     Default
  value         Y   N   N   N   ShoppingCartView                                                                                                                                                         \n"
- "ShutdownTime                           60                                                                                       Integer
  \     Server                                                    Default value     Default
  value         Y   N   N   N   Server Shutdown Wait Time                                                                                                                                                \n"
- "SleepTime                              60                                                                                       Integer
  \     Subsystem  Infrastructure Core                            Default value     Default
  value         Y   N   N   N   Sleep Time                                                                                                                                                               \n"
- "SmqAlwaysAuthenticate                  False                                                                                    Boolean
  \     Subsystem  SMQ Transport Subsystem                        Default value     Default
  value         Y   N   N   N   SMQ Always Authenticate                                                                                                                                                  \n"
- "SmqCompression                         GZIP                                                                                     String
  \      Subsystem  SMQ Transport Subsystem                        Default value     Default
  value         Y   N   N   N   SMQ Compression Algorithm                                                                                                                                                \n"
- "SmqEncryption                          RC4                                                                                      String
  \      Subsystem  SMQ Transport Subsystem                        Default value     Default
  value         Y   N   N   N   SMQ Encryption Algorithm                                                                                                                                                 \n"
- "SourceBusObj                                                                                                                    String
  \      Subsystem  Communications Outbound Manager                Never set         Never
  set             N   N   N   N   Source Business Object                                                                                                                                                   \n"
- "SourceIdList                                                                                                                    String
  \      Subsystem  Communications Outbound Manager                Never set         Never
  set             N   N   N   N   Source Id List                                                                                                                                                           \n"
- "StageAllocationThreshold               0                                                                                        Integer
  \     Subsystem  Marketing Server Subsystem                     Never set         Never
  set             Y   N   N   N   Stage Allocation Threshold                                                                                                                                               \n"
- "TableGroupFile                                                                                                                  String
  \      Subsystem  Database Access                                Never set         Never
  set             Y   N   N   N   Table Groupings File                                                                                                                                                     \n"
- "TableOwnPass                           ********                                                                                 String
  \      Subsystem  Database Access                                Never set         Never
  set             Y   N   N   N   Table Owner Password                                                                                                                                                     \n"
- "TableOwner                             SIEBEL                                                                                   String
  \      Subsystem  Database Access                                Enterprise level
  \ Enterprise level set  Y   N   N   N   Table Owner                                                                                                                                                              \n"
- "TaskRecipMin                                                                                                                    String
  \      Subsystem  Communications Outbound Manager                Never set         Never
  set             N   N   N   N   Task Recipient Minimum                                                                                                                                                   \n"
- "TaskStartDate                                                                                                                   String
  \      Subsystem  Communications Outbound Manager                Never set         Never
  set             N   N   N   N   Task Start Date                                                                                                                                                          \n"
- "TblSpace                                                                                                                        String
  \      Subsystem  Database Access                                Never set         Never
  set             Y   N   N   N   Tablespace Name                                                                                                                                                          \n"
- "TestAddress                                                                                                                     String
  \      Subsystem  Communications Outbound Manager                Never set         Never
  set             N   N   N   N   Test Address                                                                                                                                                             \n"
- "TestExecutableSearchPath                                                                                                        String
  \      Subsystem  Testing Subsystem                              Never set         Never
  set             Y   N   N   N   Test Exectuable Search Path                                                                                                                                              \n"
- "TestExecuteMethodName                                                                                                           String
  \      Subsystem  Testing Subsystem                              Never set         Never
  set             Y   N   N   N   Test Execute Method Name                                                                                                                                                 \n"
- "TestExecuteServiceName                                                                                                          String
  \      Subsystem  Testing Subsystem                              Never set         Never
  set             Y   N   N   N   Test Execute Service Name                                                                                                                                                \n"
- "TestInputDataSearchPath                                                                                                         String
  \      Subsystem  Testing Subsystem                              Never set         Never
  set             Y   N   N   N   Test Input Data Search Path                                                                                                                                              \n"
- "TestResultsSearchPath                                                                                                           String
  \      Subsystem  Testing Subsystem                              Never set         Never
  set             Y   N   N   N   Test Results Search Path                                                                                                                                                 \n"
- "TestScriptSearchPath                                                                                                            String
  \      Subsystem  Testing Subsystem                              Never set         Never
  set             Y   N   N   N   Test Script Search Path                                                                                                                                                  \n"
- "TestSuiteFileName                                                                                                               String
  \      Subsystem  Testing Subsystem                              Never set         Never
  set             Y   N   N   N   Test Suite File Name                                                                                                                                                     \n"
- "TestSuiteTestName                                                                                                               String
  \      Subsystem  Testing Subsystem                              Never set         Never
  set             Y   N   N   N   Test Suite Test Name                                                                                                                                                     \n"
- "TestSuiteWriteResults                  True                                                                                     Boolean
  \     Subsystem  Testing Subsystem                              Default value     Default
  value         Y   N   N   N   Test Suite Write Results                                                                                                                                                 \n"
- "UCMBatchObjectType                     Contact                                                                                  String
  \      Subsystem  Universal Customer Master Subsystem            Default value     Default
  value         N   N   N   N   UCM Batch Object Type                                                                                                                                                    \n"
- "UCMBatchSize                           10                                                                                       Integer
  \     Subsystem  Universal Customer Master Subsystem            Default value     Default
  value         N   N   N   N   UCM Batch Size                                                                                                                                                           \n"
- "UCMCDMCleanseFlag                      False                                                                                    Boolean
  \     Subsystem  Universal Customer Master Subsystem            Default value     Default
  value         N   N   N   N   UCM Data Management Cleanse Flag                                                                                                                                         \n"
- "UCMCDMExactMatchFlag                   False                                                                                    Boolean
  \     Subsystem  Universal Customer Master Subsystem            Default value     Default
  value         N   N   N   N   UCM Data Management Exact Match Flag                                                                                                                                     \n"
- "UCMCDMMatchFlag                        False                                                                                    Boolean
  \     Subsystem  Universal Customer Master Subsystem            Default value     Default
  value         N   N   N   N   UCM Data Management Match Flag                                                                                                                                           \n"
- "UCMPubSubFlag                          False                                                                                    Boolean
  \     Subsystem  Universal Customer Master Subsystem            Default value     Default
  value         N   N   N   N   UCM Publish/Subscribe Flag                                                                                                                                               \n"
- "UCMSearchSpec                                                                                                                   String
  \      Subsystem  Universal Customer Master Subsystem            Never set         Never
  set             N   N   N   N   UCM Search Specification                                                                                                                                                 \n"
- "UCMSleepTime                           60                                                                                       Integer
  \     Subsystem  Universal Customer Master Subsystem            Default value     Default
  value         N   N   N   N   UCM Sleep Time                                                                                                                                                           \n"
- "UCMSortSpec                                                                                                                     String
  \      Subsystem  Universal Customer Master Subsystem            Never set         Never
  set             N   N   N   N   UCM Sort Specification                                                                                                                                                   \n"
- "UCMSurvivorshipEngineFlag              False                                                                                    Boolean
  \     Subsystem  Universal Customer Master Subsystem            Default value     Default
  value         N   N   N   N   UCM Survivorship Engine Flag                                                                                                                                             \n"
- "UpdateInterval                         1440                                                                                     Integer
  \     Subsystem  Categorization Manager                         Default value     Default
  value         N   N   N   N   KB Update Interval                                                                                                                                                       \n"
- "UpgComponent                           Siebel HQ Server                                                                         String
  \      Server                                                    Default value     Default
  value         Y   N   N   N   Upgrade Component                                                                                                                                                        \n"
- "UpperThreshold                         100                                                                                      Integer
  \     Subsystem  Multi-Threading                                Default value     Default
  value         N   N   Y   N   Local load balancing upper threshold                                                                                                                                     \n"
- "UseKeyVal                              None                                                                                     String
  \      Subsystem  Assignment Subsystem                           Default value     Default
  value         Y   N   N   N   Use Key Value                                                                                                                                                            \n"
- "Username                               SADMIN                                                                                   String
  \      Subsystem  Database Access                                Enterprise level
  \ Enterprise level set  Y   N   N   N   User Name                                                                                                                                                                \n"
- "UsernameBCField                                                                                                                 String
  \      Subsystem  Object Manager                                 Never set         Never
  set             Y   N   N   N   OM - Username BC Field                                                                                                                                                   \n"
- "VersionCheck                           False                                                                                    Boolean
  \     Server                                                    Default value     Default
  value         Y   N   N   N   Version Check                                                                                                                                                            \n"
- "Vertical                               sia                                                                                      String
  \      Subsystem  Vertical                                       Enterprise level
  \ Enterprise level set  Y   N   N   N   OM - Vertical                                                                                                                                                            \n"
- "VirtualHostsFile                                                                                                                String
  \      Subsystem  Client Uses Session Manager                    Never set         Never
  set             N   N   Y   N   Session manager load balancing configuration file
  \                                                                                                                       \n"
- "WaveBatchSize                          10000                                                                                    Integer
  \     Subsystem  Marketing Server Subsystem                     Default value     Default
  value         Y   N   N   N   Wave Batch Size                                                                                                                                                          \n"
- "WebCollabEnable                        False                                                                                    Boolean
  \     Subsystem  Web Collaboration Subsystem                    Default value     Default
  value         Y   N   N   N   Web Collab Enable                                                                                                                                                        \n"
- "WebCollabEnableSimulation              False                                                                                    Boolean
  \     Subsystem  Web Collaboration Subsystem                    Default value     Default
  value         Y   N   N   N   Web Collab Enable Simulation                                                                                                                                             \n"
- "WebCollabLangCodeMap                   PIXION_LANGCODE_MAP                                                                      String
  \      Subsystem  Web Collaboration Subsystem                    Default value     Default
  value         Y   N   N   N   Web Collab Language Code Map                                                                                                                                             \n"
- "WebCollabLogFile                       WebCollab.log                                                                            String
  \      Subsystem  Web Collaboration Subsystem                    Default value     Default
  value         Y   N   N   N   Web Collab Log File                                                                                                                                                      \n"
- "WebCollabLogLevel                      0                                                                                        Integer
  \     Subsystem  Web Collaboration Subsystem                    Default value     Default
  value         Y   N   N   N   Web Collab Log Level                                                                                                                                                     \n"
- "WebCollabServer                        CHANGE_ME                                                                                String
  \      Subsystem  Web Collaboration Subsystem                    Default value     Default
  value         Y   N   N   N   Web Collab Server                                                                                                                                                        \n"
- "WebCollabType                          Siebel eCollaboration                                                                    String
  \      Subsystem  Web Collaboration Subsystem                    Default value     Default
  value         Y   N   N   N   Web Collab Package                                                                                                                                                       \n"
- "WebCollabUseSiebelSessionId            True                                                                                     Boolean
  \     Subsystem  Web Collaboration Subsystem                    Default value     Default
  value         Y   N   N   N   Web Collab Using Siebel Session Id                                                                                                                                       \n"
- "WebCollabUseSiebelUQ                   True                                                                                     Boolean
  \     Subsystem  Web Collaboration Subsystem                    Default value     Default
  value         Y   N   N   N   Web Collab Using Siebel UQ                                                                                                                                               \n"
- "WebServer                                                                                                                       String
  \      Subsystem  Communications Outbound Manager                Never set         Never
  set             N   N   N   N   Web Server                                                                                                                                                               \n"
- "XMLPReportDataDir                      /xmlp/data/                                                                              String
  \      Subsystem  Infrastructure XMLP Reports Subsystem          Default value     Default
  value         Y   N   N   N   XMLP Report Data.cfg Dir                                                                                                                                                 \n"
- "XMLPReportOutputDir                    /xmlp/reports/                                                                           String
  \      Subsystem  Infrastructure XMLP Reports Subsystem          Default value     Default
  value         Y   N   N   N   XMLP Report Output.cfg Dir                                                                                                                                               \n"
- "XMLPReportWaitTime                     10                                                                                       Integer
  \     Subsystem  Infrastructure XMLP Reports Subsystem          Default value     Default
  value         Y   N   N   N   XMLP Report Wait Time Limit                                                                                                                                              \n"
- "XMLPReportXdoDir                       /xmlp/templates/                                                                         String
  \      Subsystem  Infrastructure XMLP Reports Subsystem          Default value     Default
  value         Y   N   N   N   XMLP Report xdo.cfg Dir                                                                                                                                                  \n"
- "eProdCfgAttrSnapshotFlg                True                                                                                     Boolean
  \     Subsystem  Object Manager                                 Default value     Default
  value         Y   N   N   N   Product Configurator - Collect and Use the snapshots
  of the ISS_ATTR_DEF ObWhether or not to check the synchronization between Cfg Cache
  and DB Record For ISS_ATTR_DEF  \n"
- "eProdCfgAutoMatchInstance              False                                                                                    Boolean
  \     Subsystem  Object Manager                                 Default value     Default
  value         Y   N   N   N   Product Configurator - Auto match quote on reconfigure
  \                                                                                                                  \n"
- "eProdCfgCacheFS                                                                                                                 String
  \      Subsystem  Object Manager                                 Never set         Never
  set             Y   N   N   N   Product Configurator - FS location                                                                                                                                       \n"
- "eProdCfgCheckSelfContainded            True                                                                                     Boolean
  \     Subsystem  Object Manager                                 Default value     Default
  value         Y   N   N   N   Product Configurator - Check if Complex Product is
  Self-containded                                                                                                       \n"
- "eProdCfgClassSnapshotFlg               True                                                                                     Boolean
  \     Subsystem  Object Manager                                 Default value     Default
  value         Y   N   N   N   Product Configurator - Collect and Use the snapshots
  of  ISS_CLASS_DEF Ob                                                                                                \n"
- "eProdCfgKeepAliveTime                  900                                                                                      Integer
  \     Subsystem  Object Manager                                 Default value     Default
  value         Y   N   N   N   Product Configurator - Keep Alive Time of Idle Session
  \                                                                                                                  \n"
- "eProdCfgMaxNumbOfWorkerReuses          10                                                                                       Integer
  \     Subsystem  Object Manager                                 Default value     Default
  value         Y   N   N   N   Product Configurator - Number of Reuse for each Worker
  \                                                                                                                  \n"
- "eProdCfgNumOfCachedAttrs               100                                                                                      Integer
  \     Subsystem  Object Manager                                 Default value     Default
  value         Y   N   N   N   Product Configurator - Number of Attribute Definitions
  Cached in Memory                                                                                                  \n"
- "eProdCfgNumOfCachedClasses             100                                                                                      Integer
  \     Subsystem  Object Manager                                 Default value     Default
  value         Y   N   N   N   Product Configurator - Number of Class Definitions
  Cached in Memory                                                                                                      \n"
- "eProdCfgNumOfCachedObjects             1000                                                                                     Integer
  \     Subsystem  Object Manager                                 Default value     Default
  value         Y   N   N   N   Product Configurator - Number of Objects Cached in
  Memory                                                                                                                \n"
- "eProdCfgNumOfCachedProdInfo            1000                                                                                     Integer
  \     Subsystem  Object Manager                                 Default value     Default
  value         Y   N   N   N   Product Configurator - Number of ProdIfo Objects Cached
  in Memory                                                                                                        \n"
- "eProdCfgNumOfCachedProducts            1000                                                                                     Integer
  \     Subsystem  Object Manager                                 Default value     Default
  value         Y   N   N   N   Product Configurator - Number of Product Definitions
  Cached in Memory                                                                                                    \n"
- "eProdCfgNumbOfCachedCatalogs           10                                                                                       Integer
  \     Subsystem  Object Manager                                 Default value     Default
  value         Y   N   N   N   Product Configurator - Number of Catalogs Cached in
  Memory                                                                                                               \n"
- "eProdCfgNumbOfCachedFactories          10                                                                                       Integer
  \     Subsystem  Object Manager                                 Default value     Default
  value         Y   N   N   N   Product Configurator - Number of Factories Cached
  in Memory                                                                                                              \n"
- "eProdCfgNumbOfCachedWorkers            50                                                                                       Integer
  \     Subsystem  Object Manager                                 Default value     Default
  value         Y   N   N   N   Product Configurator - Number of Workers Cached in
  Memory                                                                                                                \n"
- "eProdCfgProdSnapshotFlg                True                                                                                     Boolean
  \     Subsystem  Object Manager                                 Default value     Default
  value         Y   N   N   N   Product Configurator - Collect and Use the snapshots
  of  ISS_PROD_DEF Ob                                                                                                 \n"
- "eProdCfgRemote                         False                                                                                    Boolean
  \     Subsystem  Object Manager                                 Default value     Default
  value         Y   N   N   N   Product Configurator - Use Remote Service                                                                                                                                \n"
- "eProdCfgServer                                                                                                                  String
  \      Subsystem  Object Manager                                 Never set         Never
  set             Y   N   N   N   Product Configurator - Remote Server Name                                                                                                                                \n"
- "eProdCfgSnapshotFlg                    True                                                                                     Boolean
  \     Subsystem  Object Manager                                 Default value     Default
  value         Y   N   N   N   Product Configurator - Collect and Use the snapshots
  of the Cfg Objects                                                                                                  \n"
- "eProdCfgTimeOut                        20                                                                                       Integer
  \     Subsystem  Object Manager                                 Default value     Default
  value         Y   N   N   N   Product Configurator - Time Out of Connection                                                                                                                            \n"
- "eProdCfgTryBypassIlog                  True                                                                                     Boolean
  \     Subsystem  Object Manager                                 Default value     Default
  value         Y   N   N   N   Product Configurator - Try to  Restore Quote witout
  Ilog                                                                                                                 \n"
- "eProdCfgWorkerMemReleaseFlg            False                                                                                    Boolean
  \     Subsystem  Object Manager                                 Default value     Default
  value         Y   N   N   N   Product Configurator - Release Worker Memory at the
  end of session                                                                                                       \n"
- "\n"
- "398 rows returned.\n"
- "\n"
list_params_for_srproc:
- "\n"
- "PA_ALIAS                 PA_VALUE                                                                        PA_DATATYPE
  \ PA_SCOPE   PA_SUBSYSTEM                 PA_SETLEVEL       PA_DISP_SETLEVEL                PA_EFF_NEXT_TASK
  \ PA_EFF_CMP_RSTRT  PA_EFF_SRVR_RSTRT  PA_REQ_COMP_RCFG  PA_NAME                                         \n"
- "-----------------------  ------------------------------------------------------------------------------
  \ -----------  ---------  ---------------------------  ----------------  ------------------------------
  \ ----------------  ----------------  -----------------  ----------------  ----------------------------------------------
  \ \n"
- "CACertFileName                                                                                           String
  \      Subsystem  Networking                   Never set         Never set                       N
  \                N                 Y                  N                 CA certificate
  file name                        \n"
- "CertFileName                                                                                             String
  \      Subsystem  Networking                   Never set         Never set                       N
  \                N                 Y                  N                 Certificate
  file name                           \n"
- "ConnIdleTime             -1                                                                              Integer
  \     Subsystem  Networking                   Default value     Default value                   Y
  \                N                 N                  N                 SISNAPI
  connection maximum idle time            \n"
- "Connect                  SBA_80_DSN                                                                      String
  \      Subsystem  Database Access              Enterprise level  Enterprise level
  set            Y                 N                 N                  N                 ODBC
  Data Source                                \n"
- "DisableNotification      False                                                                           Boolean
  \     Subsystem  Infrastructure Notification  Default value     Default value                   N
  \                N                 N                  N                 Disable
  Notification                            \n"
- "EnableDbSessCorrelation  False                                                                           Boolean
  \     Subsystem  Database Access              Default value     Default value                   Y
  \                N                 N                  N                 Enable Database
  Session Correlation             \n"
- "EnableHousekeeping       False                                                                           Boolean
  \     Component                               Default value     Default value                   N
  \                N                 N                  N                 Enable Various
  Housekeeping Tasks               \n"
- "EnableUsageTracking      False                                                                           Boolean
  \     Subsystem  Usage Tracking               Default value     Default value                   N
  \                N                 N                  N                 UsageTracking
  Enabled                           \n"
- "FDRAppendFile            False                                                                           Boolean
  \     Subsystem  (FDR) Flight Data Recorder   Default value     Default value                   N
  \                N                 N                  N                 FDR Periodic
  Dump and Append                    \n"
- "FDRBufferSize            5000000                                                                         Integer
  \     Subsystem  (FDR) Flight Data Recorder   Default value     Default value                   N
  \                Y                 N                  Y                 FDR Buffer
  Size                                 \n"
- "KeyFileName                                                                                              String
  \      Subsystem  Networking                   Never set         Never set                       N
  \                N                 Y                  N                 Private
  key file name                           \n"
- "KeyFilePassword          ********                                                                        String
  \      Subsystem  Networking                   Never set         Never set                       N
  \                N                 Y                  N                 Private
  key file password                       \n"
- "Lang                     enu                                                                             String
  \      Subsystem  Infrastructure Core          Server level      Server level set
  \               Y                 N                 N                  N                 Language
  Code                                   \n"
- "LogArchiveDir                                                                                            String
  \      Subsystem  Event Logging                Never set         Never set                       Y
  \                N                 N                  N                 Log Archive
  Directory                           \n"
- "LogDir                   /opt/oracle/app/product/8.0.0/siebel_1/siebsrvr/enterprises/SBA_80/siebel1/log
  \ String       Subsystem  Event Logging                Server level      Server
  level set                N                 N                 N                  N
  \                Log directory                                   \n"
- "LogFileDir               c:\\temp                                                                         String
  \      Subsystem  Usage Tracking               Default value     Default value                   N
  \                N                 N                  N                 UsageTracking
  LogFile Dir                       \n"
- "LogFileEncoding          ASCII                                                                           String
  \      Subsystem  Usage Tracking               Default value     Default value                   N
  \                N                 N                  N                 UsageTracking
  LogFile Encoding                  \n"
- "LogFileFormat            XML                                                                             String
  \      Subsystem  Usage Tracking               Default value     Default value                   N
  \                N                 N                  N                 UsageTracking
  LogFile Format                    \n"
- "LogFilePeriod            Hourly                                                                          String
  \      Subsystem  Usage Tracking               Default value     Default value                   N
  \                N                 N                  N                 UsageTracking
  LogFile Period                    \n"
- "LogMaxSegments           100                                                                             Integer
  \     Subsystem  Event Logging                Compdef level     Component definition
  level set  N                 N                 N                  N                 Maximum
  number of log file segments             \n"
- "LogSegmentSize           100                                                                             Integer
  \     Subsystem  Event Logging                Compdef level     Component definition
  level set  N                 N                 N                  N                 Log
  file segment size in KB                     \n"
- "MaxMTServers             1                                                                               Integer
  \     Subsystem  Multi-Threading              Compdef level     Component definition
  level set  N                 N                 Y                  N                 Maximum
  MT Servers                              \n"
- "MaxTasks                 20                                                                              Integer
  \     Subsystem  Process Management           Compdef level     Component definition
  level set  N                 N                 Y                  N                 Maximum
  Tasks                                   \n"
- "MemoryBasedRecycle       False                                                                           Boolean
  \     Subsystem  Multi-Threading              Default value     Default value                   Y
  \                N                 N                  N                 Memory usage
  based multithread shell recycling  \n"
- "MemoryLimit              1500                                                                            Integer
  \     Subsystem  Multi-Threading              Default value     Default value                   Y
  \                N                 N                  N                 Process
  VM usage lower limit                    \n"
- "MemoryLimitPercent       20                                                                              Integer
  \     Subsystem  Multi-Threading              Default value     Default value                   Y
  \                N                 N                  N                 Process
  VM usage upper limit                    \n"
- "MinMTServers             1                                                                               Integer
  \     Subsystem  Multi-Threading              Compdef level     Component definition
  level set  N                 N                 Y                  N                 Minimum
  MT Servers                              \n"
- "NotifyHandler            AdminEmailAlert                                                                 String
  \      Subsystem  Infrastructure Notification  Server level      Server level set
  \               N                 N                 N                  N                 Notification
  Handler                            \n"
- "NotifyTimeOut            100                                                                             Integer
  \     Subsystem  Infrastructure Notification  Default value     Default value                   N
  \                N                 N                  N                 Time to
  wait for doing notification             \n"
- "NumRetries               10000                                                                           Integer
  \     Subsystem  Recovery                     Default value     Default value                   Y
  \                N                 N                  N                 Number of
  Retries                               \n"
- "Password                 ********                                                                        String
  \      Subsystem  Database Access              Enterprise level  Enterprise level
  set            Y                 N                 N                  N                 Password
  \                                       \n"
- "PeerAuth                 False                                                                           Boolean
  \     Subsystem  Networking                   Default value     Default value                   N
  \                N                 Y                  N                 Peer Authentication
  \                            \n"
- "PeerCertValidation       False                                                                           Boolean
  \     Subsystem  Networking                   Default value     Default value                   N
  \                N                 Y                  N                 Validate
  peer certificate                       \n"
- "Repository               Siebel Repository                                                               String
  \      Subsystem  Database Access              Default value     Default value                   Y
  \                N                 N                  N                 Siebel Repository
  \                              \n"
- "RetryInterval            5                                                                               Integer
  \     Subsystem  Recovery                     Default value     Default value                   Y
  \                N                 N                  N                 Retry Interval
  \                                 \n"
- "RetryUpTime              600                                                                             Integer
  \     Subsystem  Recovery                     Default value     Default value                   Y
  \                N                 N                  N                 Retry Up
  Time                                   \n"
- "SARMLevel                0                                                                               Integer
  \     Subsystem  (SARM) Response Measurement  Default value     Default value                   N
  \                N                 N                  N                 SARM Granularity
  Level                          \n"
- "SRB ReqId                0                                                                               String
  \      Subsystem  Infrastructure Core          Default value     Default value                   Y
  \                N                 N                  N                 SRB RequestId
  \                                  \n"
- "SessionCacheSize         100                                                                             Integer
  \     Subsystem  Usage Tracking               Default value     Default value                   N
  \                N                 N                  N                 UsageTracking
  Session Cache Size                \n"
- "TableOwnPass             ********                                                                        String
  \      Subsystem  Database Access              Never set         Never set                       Y
  \                N                 N                  N                 Table Owner
  Password                            \n"
- "TableOwner               SIEBEL                                                                          String
  \      Subsystem  Database Access              Enterprise level  Enterprise level
  set            Y                 N                 N                  N                 Table
  Owner                                     \n"
- "TblSpace                                                                                                 String
  \      Subsystem  Database Access              Never set         Never set                       Y
  \                N                 N                  N                 Tablespace
  Name                                 \n"
- "UserList                                                                                                 String
  \      Subsystem  Event Logging                Never set         Never set                       N
  \                N                 N                  N                 List of
  users                                   \n"
- "Username                 SADMIN                                                                          String
  \      Subsystem  Database Access              Enterprise level  Enterprise level
  set            Y                 N                 N                  N                 User
  Name                                       \n"
- "\n"
- "44 rows returned.\n"
list_servers:
- "\n"
- "SBLSRVR_NAME  SBLSRVR_GROUP_NAME  HOST_NAME   INSTALL_DIR           SBLMGR_PID
  \ SV_DISP_STATE  SBLSRVR_STATE  START_TIME           END_TIME  SBLSRVR_STATUS                    \n"
- "------------  ------------------  ----------  --------------------  ----------
  \ -------------  -------------  -------------------  --------  --------------------------------
  \ \n"
- "siebfoobar                        siebfoobar  /app/siebel/siebsrvr  20452       Running
  \       Running        2013-04-22 15:32:25            8.1.1.7 [21238] LANG_INDEPENDENT
  \ \n"
- "\n"
- "1 row returned.\n"
- "\n"
list_tasks:
- "\n"
- "SV_NAME  CC_ALIAS        TK_TASKID  TK_PID  TK_DISP_RUNSTATE   \n"
- "----------  --------------  ---------  ------  -----------------  \n"
- "siebfoobar  ServerMgr       16777218   6974    Running            \n"
- "siebfoobar  ServerMgr       15728642   6963    Completed          \n"
- "siebfoobar  ServerMgr       14680066   6948    Completed          \n"
- "siebfoobar  ServerMgr       13631490   6932    Completed          \n"
- "siebfoobar  ServerMgr       12582914   6918    Completed          \n"
- "siebfoobar  ServerMgr       11534338   6910    Exited with error  \n"
- "siebfoobar  SvrTblCleanup   8388610    3294    Running            \n"
- "siebfoobar  SvrTaskPersist  7340034    3257    Running            \n"
- "siebfoobar  SRProc          5242887    3258    Running            \n"
- "siebfoobar  SRProc          5242885    3258    Running            \n"
- "siebfoobar  SCBroker        3145730    3226    Running            \n"
- "siebfoobar  SRBroker        2097167    3225    Running            \n"
- "siebfoobar  SRBroker        2097166    3225    Running            \n"
- "siebfoobar  SRBroker        2097165    3225    Running            \n"
- "siebfoobar  SRBroker        2097164    3225    Running            \n"
- "siebfoobar  SRBroker        2097161    3225    Running            \n"
- "siebfoobar  SRBroker        2097160    3225    Running            \n"
- "siebfoobar  SRBroker        2097159    3225    Running            \n"
- "siebfoobar  SRBroker        2097158    3225    Running            \n"
- "siebfoobar  SRBroker        2097157    3225    Running            \n"
- "\n"
- "20 rows returned.\n"
- "\n"
list_tasks_for_server_siebfoobar_component_srproc:
- "\n"
- "SV_NAME  CC_ALIAS        TK_TASKID  TK_PID  TK_DISP_RUNSTATE   \n"
- "----------  --------------  ---------  ------  -----------------  \n"
- "siebfoobar  SRProc          5242887    3258    Running            \n"
- "siebfoobar  SRProc          5242885    3258    Running            \n"
- "\n"
- "20 rows returned.\n"
load_preferences:
- |
  File: C:\Siebel\8.1\Client\BIN\.Siebel_svrmgr.pref
- "\n"
