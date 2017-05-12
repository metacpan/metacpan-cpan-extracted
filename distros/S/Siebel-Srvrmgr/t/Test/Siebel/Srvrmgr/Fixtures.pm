package Test::Siebel::Srvrmgr::Fixtures;

use warnings;
use strict;
use Scalar::Util::Numeric qw(isint);
use Exporter 'import';
use String::BOM qw(string_has_bom strip_bom_from_string);
use Carp;
use Test::More;    # for note() use
use Siebel::Srvrmgr::ListParser::Output::ListComp::Comp;
use Scalar::Util qw(blessed);
use DateTime 1.26;

our @EXPORT_OK = qw(create_ent_log data_from_file create_comp);

sub create_comp {
    my ( $start, $end );

    if (@_) {
        ( $start, $end ) = @_;
        confess "start parameter must be a DataTime instance"
          unless ( ( defined($start) ) and ( blessed($start) eq 'DateTime' ) );
        confess "start parameter must be a DataTime instance"
          unless ( ( defined($end) ) and ( blessed($end) eq 'DateTime' ) );
    }
    else {
        $start = DateTime->now( time_zone => 'America/Sao_Paulo' );
        $end = $start->clone;
        $end->add( hours => 72 );
    }
    return Siebel::Srvrmgr::ListParser::Output::ListComp::Comp->new(
        {
            alias          => 'SRProc',
            name           => 'Server Request Processor',
            ct_alias       => 'SRProc',
            cg_alias       => 'SystemAux',
            run_mode       => 'Interactive',
            disp_run_state => 'Shutdown',
            start_mode     => 'Auto',
            num_run_tasks  => 2,
            max_tasks      => 20,
            actv_mts_procs => 1,
            max_mts_procs  => 1,
            start_datetime => $start->strftime('%F %H:%M:%S'),
            end_datetime   => $end->strftime('%F %H:%M:%S'),
            status         => 'Enabled',
            incarn_no      => 0,
            desc_text      => ''
        }
    );
}

sub data_from_file {
    my $file = shift;
    confess "Don't have a defined file to read!" unless ( defined($file) );
    note("Reading file $file content to use it's data for testing");
    open( my $in, '<', $file )
      or confess "cannot read $file: $!";
    my @data;

    while (<$in>) {

        # input text files for testing are expected to have UNIX EOL character
        s/\012$//;
        push( @data, $_ );
    }

    close($in);

    if ( string_has_bom( $data[0] ) ) {
        $data[0] = strip_bom_from_string( $data[0] );
    }

    return \@data;
}

sub create_ent_log {
    my ( $grand_child_pid, $log_file ) = @_;
    confess "must receive pid parameter as an integer"
      unless ( ( defined($grand_child_pid) )
        and ( isint($grand_child_pid) == 1 ) );
    confess "must receive the log file parameter as an string"
      unless ( defined($log_file) );
    my @lines = <DATA>;
    close(DATA);
    $lines[48] =~ s/GRAND_CHILD_PID/$grand_child_pid/;
    $lines[0] =~ s/MY_LOCATION/$log_file/;
    open( my $out, '>', $log_file ) or confess "Cannot create $log_file=: $!";

    foreach my $line (@lines) {
        chomp($line);
        print $out $line, "\015\012";
    }

    close($out);
}

1;

__DATA__
2021 2015-03-05 13:15:40 0000-00-00 00:00:00 -0600 00000000 001 003f 0001 09 SiebSrvr 0 9589 -151398720 MY_LOCATION 8.1.1.11 [23030] ENU
ServerLog	ServerStartup	1	025fd5e954de5141:0	2015-03-05 13:15:40	Siebel Enterprise Applications Server is starting up

ServerLog	LstnObjCreate	1	0260131054de5141:0	2015-03-05 13:15:41	Created port 49156 for EAI Outbound Server
ServerLog	LstnObjCreate	1	0260133454de5141:0	2015-03-05 13:15:41	Created port 49157 for JMS Receiver
ServerLog	LstnObjCreate	1	0260133454de5141:0	2015-03-05 13:15:41	Created port 33526 for File System Manager
ServerLog	LstnObjCreate	1	0260133454de5141:0	2015-03-05 13:15:41	Created port 49158 for Server Request Processor
ServerLog	LstnObjCreate	1	0260133454de5141:0	2015-03-05 13:15:41	Created port 49159 for Siebel Administrator Notification Component
ServerLog	LstnObjCreate	1	0260133454de5141:0	2015-03-05 13:15:41	Created port 49160 for eLoyalty Processing Engine - Realtime - Tier
ServerLog	LstnObjCreate	1	0260133454de5141:0	2015-03-05 13:15:41	Created port 49161 for eLoyalty Processing Engine - Realtime
ServerLog	LstnObjCreate	1	0260133454de5141:0	2015-03-05 13:15:41	Created port 49162 for eLoyalty Processing Engine - Interactive
ServerLog	LstnObjCreate	1	0260133454de5141:0	2015-03-05 13:15:41	Created port 49163 for eLoyalty Processing Engine - Batch
ServerLog	LstnObjCreate	1	0260133454de5141:0	2015-03-05 13:15:41	Created port 33562 for Server Request Broker
ServerLog	LstnObjCreate	1	0260133454de5141:0	2015-03-05 13:15:41	Created port 33563 for Server Manager
ServerLog	LstnObjCreate	1	0260133454de5141:0	2015-03-05 13:15:41	Created port 33530 for Siebel Connection Broker
ServerLog	ComponentUpdate	2	0000149754f82575:0	2015-03-05 13:15:41	SRBroker	STARTING	Component is starting up.
ServerLog	ComponentUpdate	2	0000149754f82575:0	2015-03-05 13:15:41	SRBroker	INITIALIZED	Component has initialized (no spawned procs).
ServerLog	ComponentUpdate	2	0000149754f82575:0	2015-03-05 13:15:41	ServerMgr	STARTING	Component is starting up.
ServerLog	ComponentUpdate	2	0000149754f82575:0	2015-03-05 13:15:41	ServerMgr	INITIALIZED	Component has initialized (no spawned procs).
ServerLog	ComponentUpdate	2	0000149754f82575:0	2015-03-05 13:15:41	SiebSrvr	STARTING	Component is starting up.
ServerLog	ComponentUpdate	2	0000149754f82575:0	2015-03-05 13:15:41	SiebSrvr	INITIALIZED	Component has initialized (no spawned procs).
ServerLog	ComponentUpdate	2	0000149754f82575:0	2015-03-05 13:15:41	SCBroker	STARTING	Component is starting up.
ServerLog	ComponentUpdate	2	0000149754f82575:0	2015-03-05 13:15:41	SrvrSched	STARTING	Component is starting up.
ServerLog	ComponentUpdate	2	0000149754f82575:0	2015-03-05 13:15:41	SrvrSched	INITIALIZED	Component has initialized (no spawned procs).
ServerLog	ProcessCreate	1	0000149754f82575:0	2015-03-05 13:15:41	Created multithreaded server process (OS pid = 	9632	) for SRBroker
ServerLog	ProcessCreate	1	0000149754f82575:0	2015-03-05 13:15:41	Created server process (OS pid = 	9633	) for SCBroker
ServerLog	ProcessCreate	1	0000149754f82575:0	2015-03-05 13:15:41	Created server process (OS pid = 	9641	) for SCBroker
ServerLog	ComponentUpdate	2	0000149754f82575:0	2015-03-05 13:15:41	SCBroker	INITIALIZED	Component has initialized.
ServerLog	ComponentUpdate	2	0000149754f82575:0	2015-03-05 13:15:41	SRProc	STARTING	Component is starting up.
ServerLog	ComponentUpdate	2	0000149754f82575:0	2015-03-05 13:15:41	SRProc	INITIALIZED	Component has initialized (no spawned procs).
ServerLog	ComponentUpdate	2	0000149754f82575:0	2015-03-05 13:15:41	FSMSrvr	STARTING	Component is starting up.
ServerLog	ComponentUpdate	2	0000149754f82575:0	2015-03-05 13:15:41	FSMSrvr	INITIALIZED	Component has initialized (no spawned procs).
ServerLog	ComponentUpdate	2	0000149754f82575:0	2015-03-05 13:15:41	AdminNotify	STARTING	Component is starting up.
ServerLog	ComponentUpdate	2	0000149754f82575:0	2015-03-05 13:15:41	AdminNotify	INITIALIZED	Component has initialized (no spawned procs).
ServerLog	ComponentUpdate	2	0000149754f82575:0	2015-03-05 13:15:41	SvrTaskPersist	STARTING	Component is starting up.
ServerLog	ProcessCreate	1	0000149754f82575:0	2015-03-05 13:15:41	Created multithreaded server process (OS pid = 	9644	) for SRProc
ServerLog	ProcessCreate	1	0000149754f82575:0	2015-03-05 13:15:41	Created multithreaded server process (OS pid = 	9645	) for FSMSrvr
ServerLog	ProcessCreate	1	0000149754f82575:0	2015-03-05 13:15:41	Created multithreaded server process (OS pid = 	9651	) for AdminNotify
ServerLog	ProcessCreate	1	0000149754f82575:0	2015-03-05 13:15:41	Created server process (OS pid = 	9677	) for SvrTaskPersist
ServerLog	ComponentUpdate	2	0000149754f82575:0	2015-03-05 13:15:51	SvrTaskPersist	INITIALIZED	Component has initialized.
ServerLog	ComponentUpdate	2	0000149754f82575:0	2015-03-05 13:15:51	EAIObjMgr_enu	STARTING	Component is starting up.
ServerLog	ComponentUpdate	2	0000149754f82575:0	2015-03-05 13:15:51	EAIObjMgr_enu	INITIALIZED	Component has initialized (no spawned procs).
ServerLog	ComponentUpdate	2	0000149754f82575:0	2015-03-05 13:15:51	LoyEngineRealtimeTier	STARTING	Component is starting up.
ServerLog	ComponentUpdate	2	0000149754f82575:0	2015-03-05 13:15:51	LoyEngineRealtimeTier	INITIALIZED	Component has initialized (no spawned procs).
ServerLog	ComponentUpdate	2	0000149754f82575:0	2015-03-05 13:15:51	LoyEngineBatch	STARTING	Component is starting up.
ServerLog	ComponentUpdate	2	0000149754f82575:0	2015-03-05 13:15:51	LoyEngineBatch	INITIALIZED	Component has initialized (no spawned procs).
ServerLog	ComponentUpdate	2	0000149754f82575:0	2015-03-05 13:15:51	LoyEngineInteractive	STARTING	Component is starting up.
ServerLog	ComponentUpdate	2	0000149754f82575:0	2015-03-05 13:15:51	LoyEngineInteractive	INITIALIZED	Component has initialized (no spawned procs).
ServerLog	ProcessCreate	1	0000149754f82575:0	2015-03-05 13:15:51	Created server process (OS pid = 	GRAND_CHILD_PID	) for EAIObjMgr_enu
ServerLog	ServerStarted	1	0261889854de5141:0	2015-03-05 13:15:51	Siebel Application Server is ready and awaiting requests
