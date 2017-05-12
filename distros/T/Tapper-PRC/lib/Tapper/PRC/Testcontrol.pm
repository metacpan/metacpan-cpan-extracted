package Tapper::PRC::Testcontrol;
our $AUTHORITY = 'cpan:TAPPER';
$Tapper::PRC::Testcontrol::VERSION = '5.0.2';
use 5.010;
use warnings;
use strict;

use IPC::Open3;
use File::Copy;
use File::Temp qw/tempdir/;
use Moose;
use YAML 'LoadFile';
use File::Basename 'dirname';
use English '-no_match_vars';
use IO::Handle;
use File::Basename qw/basename dirname/;

use Tapper::Remote::Config;
# ABSTRACT: Control running test programs

extends 'Tapper::PRC';

our $MAXREAD = 1024;  # read that much in one read



sub capture_handler_tap
{
        my ($self, $filename) = @_;
        my $content;
        open my $fh, '<', $filename or die "Can not open $filename to send captured report";
        { local $/; $content = <$fh> }
        close $fh;
        return $content;
}


sub send_output
{
        my ($self, $captured_output, $testprogram) = @_;

        # add missing minimum Tapper meta information
        my $headerlines = "";
        $headerlines .= "# Tapper-suite-name: ".basename($testprogram->{program})."\n" unless $captured_output =~ /\# Tapper-suite-name:/;
        $headerlines .= "# Tapper-machine-name: ".$self->cfg->{hostname}."\n"          unless $captured_output =~ /\# Tapper-machine-name:/;
        $headerlines .= "# Tapper-reportgroup-testrun: ".$self->cfg->{test_run}."\n"   unless $captured_output =~ /\# Tapper-reportgroup-testrun:/;

        $captured_output =~ s/^(1\.\.\d+\n)/$1$headerlines/m;

        my ($error, $message) = $self->tap_report_away($captured_output);

        return $message if $error;
        return 0;

}


sub send_attachements {

    my ( $self ) = @_;

    my ( $b_error, $s_message ) = $self->tap_report_away(
          "TAP version 13\n"
        . "1..1\n"
        . "# Tapper-suite-name: PRC" . ( $self->cfg->{guest_number} || 0 ) . "-Attachments\n"
        . "# Tapper-machine-name: " . $self->cfg->{hostname} . "\n"
        . "# Tapper-reportgroup-testrun: " . $self->cfg->{test_run} . "\n"
        . "ok - Test attachments\n"
    );

    return ( 1, $s_message ) if $b_error;

    $self->upload_files( $s_message );

    return ( 0, q## );

}


sub upload_files
{

    my ( $or_self, $i_reportid ) = @_;

    my $s_host = $or_self->cfg->{report_server};
    my $i_port = $or_self->cfg->{report_api_port};
    my $s_path = $ENV{TAPPER_OUTPUT_PATH};

    return 0 unless -d $s_path;

    my @a_files = `find $s_path -type f`;

    $or_self->log->debug( @a_files );

    foreach my $s_file( @a_files ) {

        chomp $s_file;

        my $s_reportfile =  $s_file;
           $s_reportfile =~ s|^$s_path/*||;
           $s_reportfile =~ s|^./||;
           $s_reportfile =~ s|[^A-Za-z0-9_-]|_|g;

        my $or_server = IO::Socket::INET->new(
            PeerAddr => $s_host,
            PeerPort => $i_port,
        );

        return "Cannot open remote receiver $s_host:$i_port" if not $or_server;

        open( my $fh_file, "<", $s_file ) or do{$or_self->log->warn("Can't open $s_file:$!"); $or_server->close();next;};
        $or_server->print("#! upload $i_reportid $s_reportfile plain\n");
        while ( my $line = <$fh_file> ) {
                $or_server->print($line);
        }
        close($fh_file);
        $or_server->close();

    }

    return 0;

}


sub get_appendix {
        my($self, $output)  = @_;
        my $appendix = '';
        if (-e "$output.stdout" or -e "$output.stderr") {
                my $basename = basename($output);
                my $dirname  = dirname ($output);
                my @files  = <$dirname/$basename-*.stdout>;

                no warnings 'uninitialized';
                my @appendizes = sort map { my ($append) = m/(\d+)\D*$/; $append} @files;
                $appendix = sprintf("-%03d",shift(@appendizes) + 1);
        }
        return $appendix;
}


sub kill_process
{
    my ($pid) = @_;

    # allow testprogram to react on SIGTERM, then do SIGKILL
    kill ('SIGTERM', $pid);
    waitpid $pid, 0;
    my $grace_period = $ENV{HARNESS_ACTIVE} ? 0 : 2;
    while ( $grace_period > 0 and (kill 0, $pid) ) {
        $grace_period--;
        sleep 1;
    }
    if (kill 0, $pid) {
        kill 'SIGKILL', $pid;
        waitpid $pid, 0;
    }
}


sub get_process_tree
{
  my ($pid) = @_;

  return () unless $pid && $pid > 1;

  require Proc::Killfam;
  require Proc::ProcessTable;
  return Proc::Killfam::get_pids(Proc::ProcessTable->new->table, $pid);
}


sub kill_process_tree
{
    my ($pid) = @_;

    return unless $pid > 1;

    my @pids = get_process_tree($pid);
    kill_process($_) foreach ($pid, @pids);
    if (@pids) { kill_process_tree($_) foreach @pids }
}


sub testprogram_execute
{
        my ($self, $test_program) = @_;

        my $program  =  $test_program->{program};
        my $chdir    =  $test_program->{chdir};
        my $progpath =  $self->cfg->{paths}{testprog_path};
        my $output   =  $program;
           $output   =~ s|[^A-Za-z0-9_-]|_|g;
           $output   =  $test_program->{out_dir}.$output;


        if ($program !~ m(^/)) {
                $ENV{PATH} = "$progpath:$ENV{PATH}";
                $program = qx(which $program);
                chomp $program;
        }

        # try to catch non executables early
        if (-e $program) {
                if (not -x $program) {
                        system ("chmod", "ugo+x", $program);
                        return("tried to execute $program which is not an execuable and can not set exec flag") if not -x $program;
                }

                return("tried to execute $program which is a directory") if -d $program;
                return("tried to execute $program which is a special file (FIFO, socket, device, ..)") unless -f $program or -l $program;
        }

        foreach my $file (@{$test_program->{upload_before} || [] }) {

                my $target_name =~ s|[^A-Za-z0-9_-]|_|g;
                   $target_name = $test_program->{out_dir}.'/before/'.$target_name;
                File::Copy::copy($file, $target_name);

        }

        $self->log->info("Try to execute test suite $program");

        my $appendix = $self->get_appendix($output);
        pipe (my $read, my $write);
        return ("Can't open pipe:$!") if not (defined $read and defined $write);

        my $pid=fork();
        return( "fork failed: $!" ) if not defined($pid);

        if ($pid == 0) {        # hello child
                close $read;

                %ENV = (%ENV, %{$test_program->{environment} || {} });
                open (STDOUT, ">", "$output$appendix.stdout") or syswrite($write, "Can't open output file $output$appendix.stdout: $!"),exit 1;
                open (STDERR, ">", "$output$appendix.stderr") or syswrite($write, "Can't open output file $output$appendix.stderr: $!"),exit 1;
                if ($chdir) {
                        if (-d $chdir) {
                                chdir $chdir;
                        } elsif ($chdir eq "AUTO" and $program =~ m,^/, ) {
                                chdir dirname($program);
                        }
                }
                exec ($program, @{$test_program->{argv} || []}) or syswrite($write,"$!\n");
                close $write;
                exit -1;
        } else {

                # hello parent
                close $write;

                my $killed;
                local $SIG{ALRM} = sub {
                    $killed = 1;
                    kill_process_tree ($pid);
                };

                alarm ($test_program->{timeout} || 0);
                waitpid($pid,0);
                my $retval = $?;
                alarm(0);

                foreach my $file (@{$test_program->{upload_after} || [] }) {
                        my $target_name =~ s|[^A-Za-z0-9_-]|_|g;
                        $target_name = $test_program->{out_dir}.'/after/'.$target_name;
                        File::Copy::copy($file, $target_name);
                }
                if ($test_program->{capture}) {
                        my $captured_output;
                        if ( $test_program->{capture} eq 'tap' ) {
                                eval { $captured_output = $self->capture_handler_tap("$output$appendix.stdout")};
                                return $@ if $@;
                        }
                        elsif ( $test_program->{capture} eq 'tap-stderr' ) {
                            eval { $captured_output = $self->capture_handler_tap("$output$appendix.stderr")};
                            return $@ if $@;
                        }
                        else               {
                            return "Can not handle captured output, unknown capture type '$test_program->{capture}'. Valid types are (tap)";
                        }
                        my ( $b_error, $error_msg ) =  $self->send_output($captured_output, $test_program);
                        return $error_msg if $b_error;
                }

                return "Killed $program after $test_program->{timeout} seconds" if $killed;
                if ( $retval ) {
                        my $error;
                        sysread($read,$error, $MAXREAD);
                        $error =~ s/[\r\n]//g;
                        return("Executing $program failed:$error");
                }
        }
        return 0;
}


sub guest_start
{
        my ($self) = @_;
        my ($error, $retval);
 GUEST:
        for (my $i=0; $i<=$#{$self->cfg->{guests}}; $i++) {
                my $guest = $self->cfg->{guests}->[$i];
                if ($guest->{exec}){
                        my $startscript = $guest->{exec};
                        $self->log->info("Try to start virtualisation guest with $startscript");
                        if (not -s $startscript) {
                                $self->mcp_send({prc_number => ($i+1), state => 'error-guest',
                                                 error => qq(Startscript "$startscript" is empty or does not exist at all)});
                                next GUEST;
                        } else {
                                # just try to set it executable always
                                if (not -x $startscript) {
                                        unless (system ("chmod", "ugo+x", $startscript) == 0) {
                                                $self->mcp_send({prc_number => ($i+1), state => 'error-guest',
                                                                 error =>
                                                                 return qq(Unable to set executable bit on "$startscript": $!)
                                                                });
                                                next GUEST;
                                        }
                                }
                        }
                        if (not system($startscript) == 0 ) {
                                $retval = qq(Can't start virtualisation guest using startscript "$startscript");
                                $self->mcp_send({prc_number => ($i+1), state => 'error-guest',
                                                 error => $retval});
                                next GUEST;
                        }
                } elsif ($guest->{svm}){
                        my $xm = `which xm`; chomp $xm;
                        $self->log->info("Try load Xen guest described in ",$guest->{svm});
                        ($error, $retval) =  $self->log_and_exec($xm, 'create', $guest->{svm});
                        if ($error) {
                                $self->mcp_send({prc_number => ($i+1), state => 'error-guest',
                                                 error      => $retval});
                                next GUEST;
                        }
                } elsif ($guest->{xen}) {
                        $self->log->info("Try load Xen guest described in ",$guest->{xen});

                        my $guest_file = $guest->{xen};
                        if ($guest_file =~ m/^(.+)\.(?:xl|svm)$/) {
                            $guest_file = $1;
                        }

                        my $xm = `which xm`; chomp $xm;
                        my $xl = `which xl`; chomp $xl;

                        if ( -e $xl ) {
                                ($error, $retval) =  $self->log_and_exec($xl, 'create', $guest_file.".xl");
                                if ($error) {
                                        $self->mcp_send({prc_number => ($i+1), state => 'error-guest',
                                                         error      => $retval});
                                        next GUEST;
                                }
                        } elsif ( -e $xm ) {
                                ($error, $retval) =  $self->log_and_exec($xm, 'create', $guest_file.".svm");
                                if ($error) {
                                        $self->mcp_send({prc_number => ($i+1), state => 'error-guest',
                                                         error      => $retval});
                                        next GUEST;
                                }
                        } else {
                                $retval =  "Can not find both xm and xl.";
                                $self->mcp_send({prc_number => ($i+1), state => 'error-guest',
                                                 error      => $retval});
                                next GUEST;
                        }
                }
                $self->mcp_send({prc_number => ($i+1), state => 'start-guest'});
        }
        return 0;
}

        
sub create_log
{
        my ($self) = @_;
        my $testrun = $self->cfg->{test_run};
        my $outdir  = $self->cfg->{paths}{output_dir}."/$testrun/test/";
        my ($error, $retval);

        for (my $i = 0; $i <= $#{$self->cfg->{guests}}; $i++) {
                # guest count starts with 1, arrays start with 0
                my $guest_number=$i+1;

                # every guest gets its own subdirectory
                my $guestoutdir="$outdir/guest-$guest_number/";

                $error = $self->makedir($guestoutdir);
                return $error if $error;

                $self->log_and_exec("touch $guestoutdir/console");
                $self->log_and_exec("chmod 666 $guestoutdir/console");
                ($error, $retval) = $self->log_and_exec("ln -sf $guestoutdir/console /tmp/guest$guest_number.fifo");
                return "Can't create guest console file $guestoutdir/console: $retval" if $error;
        }
        return 0;
}


sub nfs_mount
{
        my ($self) = @_;
        my ($error, $retval);

        $error = $self->makedir($self->cfg->{paths}{prc_nfs_mountdir});
        return $error if $error;

        ($error, $retval) = $self->log_and_exec("mount",$self->cfg->{paths}{prc_nfs_mountdir});
        return 0 if not $error;
        ($error, $retval) = $self->log_and_exec("mount",$self->cfg->{prc_nfs_server}.":".$self->cfg->{paths}{prc_nfs_mountdir},$self->cfg->{paths}{prc_nfs_mountdir});
        # report error, but only if not already mounted
        return "Can't mount ".$self->cfg->{paths}{prc_nfs_mountdir}.":$retval" if ($error and ! -d $self->cfg->{paths}{prc_nfs_mountdir}."/live");
        return 0;
}


sub control_testprogram
{
        my ($self) = @_;

        $ENV{TAPPER_TESTRUN}         = $self->cfg->{test_run};
        $ENV{TAPPER_SERVER}          = $self->cfg->{mcp_server};
        $ENV{TAPPER_REPORT_SERVER}   = $self->cfg->{report_server};
        $ENV{TAPPER_REPORT_API_PORT} = $self->cfg->{report_api_port};
        $ENV{TAPPER_REPORT_PORT}     = $self->cfg->{report_port};
        $ENV{TAPPER_HOSTNAME}        = $self->cfg->{hostname};
        $ENV{TAPPER_REBOOT_COUNTER}  = $self->cfg->{reboot_counter} if $self->cfg->{reboot_counter};
        $ENV{TAPPER_MAX_REBOOT}      = $self->cfg->{max_reboot} if $self->cfg->{max_reboot};
        $ENV{TAPPER_GUEST_NUMBER}    = $self->cfg->{guest_number} || 0;
        $ENV{TAPPER_SYNC_FILE}       = $self->cfg->{syncfile} if $self->cfg->{syncfile};
        $ENV{TAPPER_SYNC_PATH}       = $self->cfg->{paths}{sync_path}; # if -d ($self->cfg->{paths}{sync_path} || '');
        if ($self->{cfg}->{testplan}) {
                $ENV{TAPPER_TESTPLAN_ID}   = $self->cfg->{testplan}{id};
                $ENV{TAPPER_TESTPLAN_PATH} = $self->cfg->{testplan}{path};
        }

        my $test_run         = $self->cfg->{test_run};
        my $out_dir          = $self->cfg->{paths}{output_dir}."/$test_run/test/";
        my @testprogram_list;
           @testprogram_list = @{$self->cfg->{testprogram_list}} if $self->cfg->{testprogram_list};

        # prepend outdir with guest number if we are in virtualisation guest
        $out_dir.="guest-".$self->{cfg}->{guest_number}."/" if $self->{cfg}->{guest_number};

        my $error = $self->makedir($out_dir);

        # can't create output directory. Make
        if ($error) {
                $self->log->warn($error);
                $out_dir = tempdir( CLEANUP => 1 );
        }

        $ENV{TAPPER_OUTPUT_PATH} = $out_dir;

        if ($self->cfg->{test_program}) {
                my $argv;
                my $environment;
                my $chdir;
                $argv        = $self->cfg->{parameters} if $self->cfg->{parameters};
                $environment = $self->cfg->{environment} if $self->cfg->{environment};
                $chdir       = $self->cfg->{chdir} if $self->cfg->{chdir};
                my $timeout  = $self->cfg->{timeout_testprogram} || 0;
                $timeout     = int $timeout;
                my $runtime  = $self->cfg->{runtime};
                push (@testprogram_list, {program => $self->cfg->{test_program},
                                          chdir => $chdir,
                                          parameters => $argv,
                                          environment => $environment,
                                          timeout => $timeout,
                                          runtime => $runtime,
                                          upload_before => $self->cfg->{upload_before},
                                          upload_after => $self->cfg->{upload_after},
                                         });
        }


        for (my $i=0; $i<=$#testprogram_list; $i++) {
                my $testprogram =  $testprogram_list[$i];

                $ENV{TAPPER_TS_RUNTIME}      = $testprogram->{runtime} || 0;

                # unify differences in program vs. program_list vs. virt
                $testprogram->{program}   ||= $testprogram->{test_program};
                $testprogram->{timeout}   ||= $testprogram->{timeout_testprogram};
                $testprogram->{argv}        = $testprogram->{parameters} if @{$testprogram->{parameters} || []};

                # create hash for testprogram_execute
                $testprogram->{timeout}   ||= 0;
                $testprogram->{out_dir}     = $out_dir;

                my $retval = $self->testprogram_execute($testprogram);

                if ($retval) {
                        my $error_msg = "Error while executing $testprogram->{program}: $retval";
                        $self->mcp_inform({testprogram => $i, state => 'error-testprogram', error => $error_msg});
                        $self->log->info($error_msg);
                } else {
                        $self->mcp_inform({testprogram => $i , state => 'end-testprogram'});
                        $self->log->info("Successfully finished test suite $testprogram->{program}");
                }

        }

        return(0);
}


sub get_peers_from_file
{
        my ($self, $file) = @_;
        my $peers;

        $peers = LoadFile($file);
        return "Syncfile does not contain a list of host names" if not ref($peers) eq 'ARRAY';

        my $hostname = $self->cfg->{hostname};
        my %peerhosts;
        foreach my $host (@$peers) {
                $peerhosts{$host} = 1;
        }
        delete $peerhosts{$hostname};

        return \%peerhosts;
}


sub wait_for_sync
{
        my ($self, $syncfile) = @_;

        my %peerhosts;   # easier to delete than from array

        eval {
                %peerhosts = %{$self->get_peers_from_file($syncfile)};
        };
        return $@ if $@;


        my $hostname = $self->cfg->{hostname};
        my $port = $self->cfg->{sync_port};
        my $sync_srv = IO::Socket::INET->new( LocalPort => $port, Listen => 5, );
        my $select = IO::Select->new($sync_srv);

        $self->log->info("Trying to sync with: ". join(", ",sort keys %peerhosts));

        foreach my $host (keys %peerhosts) {
                my $remote = IO::Socket::INET->new(PeerPort => $port, PeerAddr => $host,);
                if ($remote) {
                        $remote->print($hostname);
                        $remote->close();
                        delete($peerhosts{$host});
                }
                if ($select->can_read(0)) {
                        my $msg_srv = $sync_srv->accept();
                        my $remotehost;
                        $msg_srv->read($remotehost, 2048); # no hostnames are that long, anything longer is wrong and can be ignored
                        chomp $remotehost;
                        $msg_srv->close();
                        if ($peerhosts{$remotehost}) {
                                delete($peerhosts{$remotehost});
                        } else {
                                $self->log->warn(qq(Received sync request from host "$remotehost" which is not in our peerhost list. Request was sent from ),$msg_srv->peerhost);
                        }
                }
                $self->log->debug("In sync with $host.");

        }

        while (%peerhosts) {
                if ($select->can_read()) {   # TODO: timeout handling
                        my $msg_srv = $sync_srv->accept();
                        my $remotehost;
                        $msg_srv->read($remotehost, 2048); # no hostnames are that long, anything longer is wrong and can be ignored
                        chomp $remotehost;
                        $msg_srv->close();
                        if ($peerhosts{$remotehost}) {
                                delete($peerhosts{$remotehost});
                                $self->log->debug("In sync with $remotehost.");
                        } else {
                                $self->log->warn(qq(Received sync request from host "$remotehost" which is not in our peerhost list. Request was sent from ),$msg_srv->peerhost);
                        }
                } else {
                        # handle timeout here when can_read() has a timeout eventually
                }
        }
        return 0;
}


sub send_keep_alive_loop
{
        my ($self, $sleeptime) = @_;
        return unless $sleeptime;
        while (1) {
                $self->mcp_inform("keep-alive");
                sleep($sleeptime);
        }
        return;
}


sub run
{
        my ($self) = @_;

        my $producer = Tapper::Remote::Config->new();
        my $config   = $producer->get_local_data("test-prc0");

        $self->cfg($config);

        $0 = "tapper-prc-testcontrol-".$self->cfg->{test_run};

        $self->cfg->{reboot_counter} = 0 if not defined($self->cfg->{reboot_counter});

        if ($self->cfg->{log_to_file}) {
                $self->log_to_file('testing');
        }

        # ignore error
        $self->log_and_exec('ntpdate -s gwo');

        if ($config->{prc_nfs_server}) {
                if ( my $retval = $self->nfs_mount() ) {
                        $self->log->warn($retval);
                }
        }

        if ( my $retval = $self->create_log() ) {
                $self->log->logdie($retval);
        }

        if ($config->{scenario_id}) {
                my $syncfile = $config->{paths}{sync_path}."/".$config->{scenario_id}."/syncfile";
                if (-e $syncfile) {
                        $self->cfg->{syncfile} = $syncfile;

                        if ( my $retval = $self->wait_for_sync($syncfile) ) {
                                $self->log->logdie("Can not sync - $retval");
                        }
                }
        }

        if ($self->{cfg}->{guest_count}) {
                if ( my $retval = $self->guest_start() ) {
                        $self->log->error($retval);
                }
        }

        if ( not $self->cfg->{reboot_counter} ) {
                $self->mcp_inform({state => 'start-testing'});
        }

        if ( $self->cfg->{test_program} or $self->cfg->{testprogram_list} ) {
                $self->control_testprogram();
        }

        if ($self->cfg->{max_reboot}) {
                $self->mcp_inform({state => 'reboot', count => $self->cfg->{reboot_counter}, max_reboot => $self->cfg->{max_reboot}});
                if ($self->cfg->{reboot_counter} < $self->cfg->{max_reboot}) {
                        $self->cfg->{reboot_counter}++;
                        YAML::Syck::DumpFile($config->{filename}, $self->{cfg}) or $self->mcp_error("Can't write config to file: $!");
                        $self->log_and_exec("reboot");
                        return 0;
                }

        }

        sleep 1; # make sure last end-testing can't overtake last end-testprogram (Yes, this did happen)

        # send attachment report
        my ( $b_error, $s_error_msg ) = $self->send_attachements();
        if ( $b_error ) {
                $self->log->error( $s_error_msg );
        }

        $self->mcp_inform({state => 'end-testing'});

        return 1;

}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Tapper::PRC::Testcontrol - Control running test programs

=head1 FUNCTIONS

=head2 capture_handler_tap

This function is a handler for the capture function. It handles capture
requests of type 'tap'. This means the captured output is supposed to be
TAP already and therefore no transformation is needed.

@param file handle - opened file handle

@return string - output in TAP format
@return error  - die()

=head2 send_output

Send the captured TAP output to the report receiver.

@param string - TAP text

@return success - 0
@return error   - error string

=head2 send_output

Send the a attachment to the report receiver and add attachements.

@return success - 0
@return error   - error string

=head2 upload_files

Upload files written in one stage of the testrun to report framework.

@param int - report id
@param int - testrun id

@return success - 0
@return error   - error string

=head2 get_appendix

For testprogram with the same name the output file names will be
identical. To prevent this, we append a serial number. This function
calculates this appendix and returns the next one to use. If no such
serial is needed because no output file of the given name exists yet the
empty string is returned.

@param string  - name of the output file without appendix

@return string - string to append to output file name to make it unique

=head2 kill_process($pid)

Gracefully kill a single process.

=head2 get_process_tree($pid)

Get list of children for a process. The process itself is not
contained in the list.

=head2 kill_process_tree($pid)

Kill whole tree of processes, depth-first, with extreme prejudice.

=head2 testprogram_execute

Execute one testprogram. Handle all error conditions.

@param hash ref - contains all config options for program to execute
* program     - program name
* timeout     - timeout in seconds
* outdir      - output directory
* parameters  - arrayref of strings - parameters for test program
* environment - hashref of strings - environment variables for test program
* chdir       - string - where to chdir before executing the testprogram

@return success - 0
@return error   - error string

=head2 guest_start

Start guest images for virtualisation. Only Xen guests can be started at the
moment.

@return success - 0
@return error   - error string

=head2 create_log

Checks whether fifos for guest logging exists and creates them if
not. Existing files of wrong type are deleted.

@retval success - 0
@retval error   - error string

=head2 nfs_mount

Mount the output directory from an NFS server. This method is used since we
only want to mount this NFS share in live mode.

@return success - 0
@return error   - error string

=head2 control_testprogram

Control running of one program including caring for its input, output and
the environment variables some testers asked for.

@return success - 0
@return error   - error string

=head2 get_peers_from_file

Read syncfile and extract list of peer hosts (not including this host).

@param string - file name

@return success - hash ref

@throws plain error message

=head2 wait_for_sync

Synchronise with other hosts belonging to the same interdependent testrun.

@param array ref - list of hostnames of peer machines

@return success - 0
@return error   - error string

=head2 send_keep_alive_loop

Send keepalive messages to MCP in an endless loop.

@param int - sleep time between two keepalives

=head2 run

Main function of Program Run Control.

=head1 AUTHORS

=over 4

=item *

AMD OSRC Tapper Team <tapper@amd64.org>

=item *

Tapper Team <tapper-ops@amazon.com>

=back

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2016 by Advanced Micro Devices, Inc..

This is free software, licensed under:

  The (two-clause) FreeBSD License

=cut
