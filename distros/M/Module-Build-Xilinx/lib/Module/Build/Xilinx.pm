package Module::Build::Xilinx;
use base 'Module::Build';

use 5.0008;
use strict;
use warnings;
use Carp;
use Cwd;
use Config;
use Data::Dumper;
use File::Spec;
use File::Basename qw/fileparse/;
use File::HomeDir;

our $VERSION = '0.13';
$VERSION = eval $VERSION;

# Xilinx install path
__PACKAGE__->add_property('xilinx', undef);
__PACKAGE__->add_property('xilinx_settings32', undef);
__PACKAGE__->add_property('xilinx_settings64', undef);
# project name property
__PACKAGE__->add_property('proj_name', undef);
# project extension property
__PACKAGE__->add_property('proj_ext', '.xise');
# project parameters related to the device
__PACKAGE__->add_property('proj_params',
    default => sub { {} },
    # this check thing doesnt work
    check => sub {
        if (ref $_ eq 'HASH') {
            return 1 if (defined $_->{family} and defined $_->{device});
            shift->property_error(
                qq{Property "proj_params" needs "family" and "device" defined});
        } else {
            shift->property_error(
                qq{Property "proj_params" should be a hash reference.});
        }
        return 0;
    },
);
__PACKAGE__->add_property('testbench', {});
# source files
__PACKAGE__->add_property('source_files', []);
# testbench files
__PACKAGE__->add_property('testbench_files', []);
# testbench source files
__PACKAGE__->add_property('testbenchsrc_files', []);
# tcl file
__PACKAGE__->add_property('tcl_script', 'program.tcl'); 

sub new {
    my $class = shift;
    # build the M::B object
    # hide the warnings about module_name
    my $self = $class->SUPER::new(module_name => $class, @_);
    my $os = $self->os_type;
    croak "No support for OS" unless $os =~ /Windows|Linux|Unix/i;
    croak "No support for OS" if $os eq 'Unix' and $^O !~ /linux/i;
    $self->libdoc_dirs([]);
    $self->bindoc_dirs([]);
    # sanitize proj_params
    my $pp = $self->proj_params;
    if (defined $pp->{language}) {
        $pp->{language} = 'VHDL' if $pp->{language} =~ /vhdl/i;
        $pp->{language} = 'Verilog' if $pp->{language} =~ /verilog/i;
        $pp->{language} = 'N/A' unless $pp->{language} =~ /VHDL|Verilog/i;
    }
    $self->proj_params($pp);
    # project name can just be dist_name
    $self->proj_name($self->dist_name);
    # add the Verilog/VHDL files as build files
    $self->add_build_element('hdl');
    # add the Verilog/VHDL testbench files as well
    $self->add_build_element('tb');
    # add the ucf files as build files
    $self->add_build_element('ucf');
    if (defined $self->tcl_script) {
        my $tcl = File::Spec->catfile($self->blib, $self->tcl_script);
        $self->tcl_script($tcl);
        $self->add_to_cleanup($tcl);
    }
    # find the Xilinx install path
    my $xil_path = $self->_find_xilinx($ENV{XILINX});
    $self->xilinx($xil_path) if defined $xil_path;
    print "Found Xilinx installed at $xil_path\n" if defined $xil_path;

    my $oref = $self->get_options() || {};
    $oref->{device} = { type => '=s' } unless exists $oref->{device};
    $oref->{view} = { type => '=s@' } unless exists $oref->{view};
    return $self;
}

sub ACTION_build {
    my $self = shift;
    # build invokes the process_*_files() functions
    $self->SUPER::ACTION_build(@_) if $self->SUPER::can_action('build');
    my $tcl = $self->tcl_script;
    $self->log_info("Generating the $tcl script\n");
    if ($self->verbose) {
        local $Data::Dumper::Terse = 1;
        my ($a, $b) = Data::Dumper->Dumper($self->source_files);
        $self->log_verbose("source files: $b");
    }
    # add the tcl code
    open my $fh, '>', $tcl or croak "Unable to open $tcl for writing: $!";
    print $fh $self->_dump_tcl_code();
    close $fh;
    # we do this here since otherwise the tests will fail
    my $xil_path = $self->xilinx;
    croak $self->_cant_find_xilinx() unless defined $xil_path;
    1;
}

sub process_ucf_files {
    my $self = shift;
    my $regex = qr/\.(?:ucf)$/;
    return $self->_process_src_files($regex);
}

sub _process_src_files($) {
    my ($self, $regex) = @_;
    my @filearray = ();
    foreach my $dir (qw/lib src/) {
        next unless -d $dir;
        eval {
            my $files = $self->rscan_dir($dir, $regex);
            push @filearray, @$files if ref $files eq 'ARRAY' and scalar @$files;
        };
        carp "hdl: $@" if $@;
    }
    # make unique
    push @filearray, @{$self->source_files};
    my %fh = map { $_ => 1 } @filearray;
    $self->source_files([keys %fh]);
}

sub process_hdl_files {
    my $self = shift;
    my $regex = qr/\.(?:vhdl|vhd|v)$/;
    return $self->_process_src_files($regex);
}

sub process_tb_files {
    my $self = shift;
    ## patterns taken from $Xilinx/data/projnav/xil_tb_patterns.txt
    my $regex_tb = 
        qr/(?:_tb|_tf|_testbench|_tb_[0-9]+|databench\w*|testbench\w*)\.(?:vhdl|vhd|v)$/;
    my $regex = qr/\.(?:vhdl|vhd|v)$/;
    return $self->_process_tb_files($regex_tb, $regex);
}

sub _process_tb_files($$) {
    my ($self, $regex_tb, $regex) = @_;
    my @filearray = ();
    # find all the _tb files in lib/src
    foreach my $dir (qw/lib src t tb/) {
        next unless -d $dir;
        eval {
            my $files = $self->rscan_dir($dir, $regex_tb);
            push @filearray, @$files if ref $files eq 'ARRAY' and scalar @$files;
        };
        carp "tb: $@" if $@;
    }
    # make unique
    push @filearray, @{$self->testbench_files};
    my %fh = map { $_ => 1 } @filearray;
    $self->testbench_files([keys %fh]);
    # find all the vhd/ver files in t/tb, since multiple testbench files
    # and dependent entity files may co-exist in one as a supplement.
    # this is similar to the t/ directory having a .pm file
    my $tbsrc = $self->testbenchsrc_files;
    foreach my $dir (qw/t tb/) {
        next unless -d $dir;
        eval {
            my $files = $self->rscan_dir($dir, $regex);
            foreach (@$files) {
                next if $fh{$_};
                push @$tbsrc, $_;
            }
        };
        carp "tb: $@" if $@;
    }
    my %fh2 = map { $_ => 1 } @$tbsrc;
    $self->testbenchsrc_files([keys %fh2]);
    # find the correct testbench top-levels
    my $tb = $self->testbench;
    foreach my $key (keys %fh) {
        # we only care about the files that Xilinx assumes can be a testbench
        next unless $key =~ /$regex_tb/;
        my $hh = exists $tb->{$key} ? $tb->{$key} : {};
        croak "Property testbench{$key} has to be a hash reference" unless ref $hh eq 'HASH';
        my ($file, $dirs, $ext) = fileparse($key, $regex);
        $hh->{toplevel} = 'testbench' unless defined $hh->{toplevel};
        $hh->{srclib} = 'work' unless defined $hh->{srclib};
        $hh->{wdb} = $file . '.wdb' unless defined $hh->{wdb};
        $hh->{exe} = $file . '.exe' unless defined $hh->{exe};
        $hh->{prj} = $file . '.prj' unless defined $hh->{prj};
        $hh->{cmd} = $file . '.cmd' unless defined $hh->{cmd};
        $tb->{$key} = $hh;
    }
    $self->testbench($tb);
}

sub _cant_find_xilinx {
    return << 'CANTFIND';
Cannot find Xilinx ISE installation. Set the XILINX environment variable to point to it such as 
/opt/Xilinx/13.2/ISE or set the 'xilinx' property in the Build.PL script of the
Module::Build::Xilinx. You will need to re-run Build.PL after this.
CANTFIND
}

sub _find_xilinx {
    my $self = shift;
    my $env_xil = shift;
    my $xil_path = $self->xilinx;
    my $homedir = File::HomeDir->my_home();
    my @xildirs = ();
    my @final = ();
    push @final, $env_xil if (defined $env_xil and -d $env_xil);
    push @final, $xil_path if (defined $xil_path and -d $xil_path);
    if ($self->is_windowsish()) {
        # in Windows the Xilinx is installed in C:/Xilinx by default
        my @drives = ( $ENV{SystemDrive}, $ENV{HOMEDRIVE} ); 
        @drives = grep { defined $_ } @drives;
        foreach (@drives) {
            my $d = "$_\\Xilinx";
           push @xildirs, $d if -d $d;
        }
        my $pf = $ENV{ProgramFiles} || $ENV{PROGRAMFILES};
        my $pfx86 = $ENV{'ProgramFiles(x86)'} || $ENV{'PROGRAMFILES(X86)'};
        foreach (($homedir, $pf, $pfx86)) {
            next unless defined $_;
            next unless -d $_;
            push @xildirs, "$_\\Xilinx" if -d "$_\\Xilinx";
        }
    } else {
        # in Unix/Linux Xilinx is installed in /opt by default
        foreach (($homedir, '/opt', '/usr', '/usr/local')) {
            next unless defined $_;
            next unless -d $_;
            push @xildirs, "$_/Xilinx" if -d "$_/Xilinx";
        }
    }
    unless (scalar @xildirs) {
        carp "Cannot find any directories with Xilinx software installed";
        return;
    }
    if ($self->verbose) {
        local $Data::Dumper::Terse = 1;
        print "Found directories with Xilinx software installed: ", Dumper(\@xildirs), "\n";
    }
    foreach my $xdir (@xildirs) {
        opendir my $fd, $xdir or carp "Cannot open directory $xdir";
        next unless $fd;
        my @filenames = readdir $fd; 
        closedir $fd;
        my @possible = grep { /\d+\.\d+/ } @filenames;
        next unless scalar @possible;
        @possible = map(File::Spec->catfile($xdir, $_), @possible);
        push @final, @possible;
    }
    if ($self->verbose) {
        print "Found possible directories with Xilinx software installed: ", Dumper(\@final);
    }
    unless (scalar @final) {
        carp "Cannot find any directories with Xilinx software installed";
        return;
    }
    my $result;
    foreach (@final) {
        my $ext = $self->is_windowsish() ? 'bat' : 'sh';
        $result = File::Spec->catfile($_, 'ISE_DS');
        my $f32 = File::Spec->catfile($result, "settings32.$ext");
        my $f64 = File::Spec->catfile($result, "settings64.$ext");
        if (-e $f64 or -e $f32) {
            $self->xilinx_settings64($f64);
            $self->xilinx_settings32($f32);
            print "Found $f64 and $f32 in $result\n" if $self->verbose;
            last;
        }
    }
    return $result;
}

sub _exec_tcl_script($) {
    my ($self, $opt) = @_;
    # find xtclsh and run the tcl script
    # for that you need to find the Xilinx install path or use a user supplied
    # one and run it here
    my $tcl = $self->tcl_script;
    croak "$tcl is missing. Please run ./Build first" unless -e $tcl;
    my $cmd1 = $self->xilinx_settings32;
    $cmd1 = $self->xilinx_settings64 if $Config{archname} =~ /x86_64|x64/;
    my $cmd2 = "xtclsh $tcl $opt";
    print "Loading settings from $cmd1 and running $cmd2\n" if $self->verbose;
    if ($self->is_windowsish()) {
        my $bat = File::Spec->catfile($self->blib, 'runtcl.bat');
        open my $fh, '>', $bat or croak "Unable to open $bat for writing: $!";
        print $fh "call $cmd1\r\n";
        print $fh "$cmd2\r\n";
        print $fh "echo 'done running $cmd2'\r\n";
        print $fh "exit\r\n";
        close $fh;
        system($bat) == 0 or croak "Failure while executing '$bat': $!";
    } else {
        system("source $cmd1 && $cmd2") == 0 or croak "Failure while executing '$cmd1 && $cmd2': $!";
    }
}

sub _exec_isimgui($) {
    my ($self, $wdb) = @_;
    # NO CHDIR here
    # find xtclsh and run the tcl script
    # for that you need to find the Xilinx install path or use a user supplied
    # one and run it here
    my $cmd1 = $self->xilinx_settings32;
    $cmd1 = $self->xilinx_settings64 if $Config{archname} =~ /x86_64|x64/;
    my $cmd2 = "isimgui -view $wdb";
    print "Loading settings from $cmd1 and running $cmd2\n" if $self->verbose;
    if ($self->is_windowsish()) {
        my $bat = File::Spec->catfile($self->blib, 'runview.bat');
        open my $fh, '>', $bat or croak "Unable to open $bat for writing: $!";
        print $fh "call $cmd1\r\n";
        print $fh "$cmd2\r\n";
        print $fh "echo 'done running $cmd2'\r\n";
        print $fh "exit\r\n";
        close $fh;
        system($bat) == 0 or croak "Failure while executing '$bat': $!";
    } else {
        system("source $cmd1 && $cmd2") == 0 or croak "Failure while executing '$cmd1 && $cmd2': $!";
    }
}

sub _exec_fuse($$$) {
    my ($self, $prj, $exe, $topname) = @_;
    my $cwd = Cwd::cwd();
    chdir $self->blib;

    my $cmd1 = $self->xilinx_settings32;
    $cmd1 = $self->xilinx_settings64 if $Config{archname} =~ /x86_64|x64/;
    my $cmd2 = "fuse -incremental $topname -prj $prj -o $exe";
    print "Loading settings from $cmd1 and running $cmd2\n" if $self->verbose;
    if ($self->is_windowsish()) {
        my $bat = 'runfuse.bat';
        open my $fh, '>', $bat or croak "Unable to open $bat for writing: $!";
        print $fh "call $cmd1\r\n";
        print $fh "$cmd2\r\n";
        print $fh "echo 'done running $cmd2'\r\n";
        print $fh "exit\r\n";
        close $fh;
        system($bat) == 0 or croak "Failure while executing '$bat': $!";
    } else {
        system("source $cmd1 && $cmd2") == 0 or croak "Failure while executing '$cmd1 && $cmd2': $!";
    }
    chdir $cwd;
}

sub _exec_simulation($$$$) {
    my ($self, $exe, $cmd, $wdb, $log) = @_;
    my $cwd = Cwd::cwd();
    chdir $self->blib;

    my $cmd1 = $self->xilinx_settings32;
    $cmd1 = $self->xilinx_settings64 if $Config{archname} =~ /x86_64|x64/;
    my $cmd2 = "$exe -tclbatch $cmd -wdb $wdb -log $log";
    print "Loading settings from $cmd1 and running $cmd2\n" if $self->verbose;
    if ($self->is_windowsish()) {
        my $bat = 'runsim.bat';
        open my $fh, '>', $bat or croak "Unable to open $bat for writing: $!";
        print $fh "call $cmd1\r\n";
        print $fh ".\\$cmd2\r\n";
        print $fh "echo 'done running $cmd2'\r\n";
        print $fh "exit\r\n";
        close $fh;
        system($bat) == 0 or croak "Failure while executing '$bat': $!";
    } else {
        system("source $cmd1 && ./$cmd2") == 0 or croak "Failure while executing '$cmd1 && $cmd2': $!";
    }
    chdir $cwd;
}

sub _exec_impact($) {
    my ($self, $device) = @_;
    my $cwd = Cwd::cwd();
    chdir $self->blib;

    my $cmd1 = $self->xilinx_settings32;
    $cmd1 = $self->xilinx_settings64 if $Config{archname} =~ /x86_64|x64/;
    my $pcmd = File::Spec->catfile(File::Spec->curdir(), 'program_device.cmd');
    my $projipf = File::Spec->catfile(File::Spec->curdir(), $self->proj_name . ".ipf");

    my $cmd2 = "impact -batch $pcmd";
    print "Loading settings from $cmd1 and running $cmd2\n" if $self->verbose;
    open my $fh, '>', $pcmd or croak "Unable to write to $pcmd: $!";
    my $data = << 'PROGDATA';
setLog -file program_device.log
setPreference -pref UserLevel:Novice
setPreference -pref ConfigOnFailure:Stop
setMode -bscan
setCable -port auto
identify
PROGDATA
    print $fh $data;
    my $i = 0;
    my @bitfiles = <*.bit>;
    ## assign the bit files to a tag $i
    foreach (@bitfiles) {
        $i++;
        my $line = << "LINEBIT";
assignFile -p $i -file \"$_\"
LINEBIT
        print $fh $line;
    }
    ## program all the tags
    $i = 0;
    foreach (@bitfiles) {
        $i++;
        my $line = << "LINEBIT";
program -p $i
LINEBIT
        print $fh $line;
    }
    $data = << "PROGDATA";
checkIntegrity
saveprojectfile -file \"$projipf\"
quit
PROGDATA
    print $fh $data;
    close $fh;
    if ($self->is_windowsish()) {
        my $bat = 'runprog.bat';
        open my $fh, '>', $bat or croak "Unable to open $bat for writing: $!";
        print $fh "call $cmd1\r\n";
        print $fh "$cmd2\r\n";
        print $fh "echo 'done running $cmd2'\r\n";
        print $fh "exit\r\n";
        close $fh;
        system($bat) == 0 or croak "Failure while executing '$bat': $!";
    } else {
        system("source $cmd1 && $cmd2") == 0 or croak "Failure while executing '$cmd1 && $cmd2': $!";
    }
    chdir $cwd;
}

sub ACTION_psetup {
    my $self = shift;
    $self->ACTION_build(@_);
    return $self->_exec_tcl_script('-setup');
}

sub ACTION_pclean {
    my $self = shift;
    $self->ACTION_build(@_);
    return $self->_exec_tcl_script('-clean');
}

sub ACTION_pbuild {
    my $self = shift;
    $self->ACTION_psetup(@_);
    return $self->_exec_tcl_script('-build');
}

sub ACTION_test {
    return shift->ACTION_simulate(@_);
}

sub ACTION_simulate {
    my $self = shift;
    # manage multiple views. how does one update runtime_params ? hence we just
    # re-run the Build as needed.
    $self->ACTION_build(@_);
    my $tb_data = $self->testbench;
    my $simfiles = $self->SUPER::args('sim_files') || [keys %$tb_data];
    $simfiles = [$simfiles] unless ref $simfiles eq 'ARRAY';
    if (scalar @$simfiles) {
        if ($self->verbose) {
            local $Data::Dumper::Terse = 1;
            print "Running tests for the following: ", Dumper($simfiles);
        }
        my $blib = $self->blib;
        my $flag = File::Spec->catfile($blib, '.done_build');
        croak "You need to run 'Build pbuild' before running simulate" unless -e $flag;
        foreach my $vf (@$simfiles) {
            $vf =~ s:\\:/:g if $self->is_windowsish();# convert windows paths out
            $vf =~ s:^\./::g; # remove ./ from the beginning
            unless (exists $tb_data->{$vf}) {
                carp "$vf is not a valid testbench file";
                next;
            }
            my $prj = $tb_data->{$vf}->{prj};
            my $exe = $tb_data->{$vf}->{exe};
            my $cmd = $tb_data->{$vf}->{cmd};
            my $wdb = $tb_data->{$vf}->{wdb};
            my $topname = $tb_data->{$vf}->{srclib} . '.' . $tb_data->{$vf}->{toplevel};
            my $log = $exe;
            $log =~ s/\.exe$/\.log/g;
            my $cmdfile = File::Spec->catfile($blib, $cmd);
            open my $fh, '>', $cmdfile or croak "Unable to open $cmdfile for writing: $!";
            my $tclcode = << 'CMDEOF';
onerror {resume}
wave add /
run all
quit -f
CMDEOF
            print $fh $tclcode;
            close $fh;
            print "Done creating $cmdfile\n" if $self->verbose; 
            ## will do a chdir into $blib
            $self->_exec_fuse($prj, $exe, $topname);
            ## will do a chdir into $blib
            $self->_exec_simulation($exe, $cmd, $wdb, $log);
        }
        # create .done_simulate
        my $ds = File::Spec->catfile($blib, '.done_simulate');
        open my $dsf, '>', $ds or carp "Unable to create $ds: $!";
        print $dsf "1\n";
        close $dsf;
    } else {
        print "No tests were run since no testbenches were found.\n";
    }
}

sub ACTION_view {
    my $self = shift;
    # manage multiple views. how does one update runtime_params ? hence we just
    # re-run the Build as needed.
    $self->ACTION_build(@_);
    my $tb_data = $self->testbench;
    my $simfiles = $self->SUPER::args('sim_files') || [keys %$tb_data];
    $simfiles = [$simfiles] unless ref $simfiles eq 'ARRAY';
    if (scalar @$simfiles) {
        if ($self->verbose) {
            local $Data::Dumper::Terse = 1;
            print "Running views for the following: ", Dumper($simfiles);
        }
        foreach my $vf (@$simfiles) {
            $vf =~ s:\\:/:g if $self->is_windowsish();# convert windows paths out
            $vf =~ s:^\./::g; # remove ./ from the beginning
            if (exists $tb_data->{$vf} and defined $tb_data->{$vf}->{wdb}) {
                my $wdb = File::Spec->catfile($self->blib, $tb_data->{$vf}->{wdb});
                unless (-e $wdb) {
                    carp "$wdb has not been created. You need to run ./Build simulate first";
                    next;
                }
                ## we do NOT chdir into the blib directory
                $self->_exec_isimgui($wdb);
                print "Finished viewing the output of $vf\n";
            } else {
                carp "$vf is not a valid testbench file";
            }
        }
    } else {
        print "No tests were run since no testbenches were found.\n";
    }
}

sub ACTION_program {
    my $self = shift;
    my $device = $self->SUPER::args('device');
    carp "Guessing which device to use for programming." unless defined $device;
    print "Programming the $device\n" if ($self->verbose and defined $device);
    $self->ACTION_build(@_);
    return $self->_exec_impact($device);
}

sub _tcl_functions {
    return << 'TCLFUNC';
proc add_parameter {param value} {
    puts stderr "INFO: Setting $param to $value"
    if {[catch {xilinx::project set $param $value} err]} then {
        puts stderr "WARN: Unable to set $param to $value\n$err"
        return 1
    }
    return 0
}

proc add_parameters {plist} {
    array set params $plist
    foreach idx [lsort [array names params]] {
        set param [lindex $params($idx) 0]
        set value [lindex $params($idx) 1]
        add_parameter $param $value
    }
    return 0
}
# we have a separate function for adding source and testbench
proc add_source_file {ff} {
    if {[file exists $ff]} then {
        set found [xilinx::search $ff -regexp -type file]
        if {[xilinx::collection sizeof $found] == 0} then {
            puts stderr "INFO: Adding $ff"
            if {[catch {xilinx::xfile add $ff} err]} then {
                puts stderr "ERROR: Unable to add $ff\n$err"
                exit 1
            }
        } else {
            puts stderr "INFO: $ff already in project"
        }
    } else {
        puts stderr "WARN: $ff does not exist"
    }
}

proc add_testbench_file {ff} {
    set viewname Simulation
    if {[file exists $ff]} then {
        set found [xilinx::search $ff -regexp -type file]
        if {[xilinx::collection sizeof $found] == 0} then {
            puts stderr "INFO: Adding $ff to $viewname"
            if {[catch {xilinx::xfile add $ff -view $viewname} err]} then {
                puts stderr "ERROR: Unable to add $ff\n$err"
                exit 1
            }
        } else {
            puts stderr "INFO: $ff already in project"
        }
    } else {
        puts stderr "WARN: $ff does not exist"
    }
}

proc process_run_task {task} {
    if {[catch {xilinx::process run $task} err]} then {
        puts stderr "ERROR: Unable to run $task\n$err"
        return 1
    }
    set rc [xilinx::process get $task status]
    puts stderr "INFO: Status of $task: $rc\n"
    if {[string compare $rc "errors"] == 0  ||
        [string compare $rc "aborted"] == 0 } then {
       puts stderr "ERROR: Unable to run $task: $rc\n"
       return 1
    }
    return 0
}    

proc simulation_create {prj exe topname} {
    if {[catch {exec fuse -incremental $topname -prj $prj -o $exe} err]} then {
        puts stderr "ERROR: Unable to run fuse for $prj\n$err"
        return 1
    }
    return 0
}

proc simulation_run {exe cmd wdb logfile} {
    if {[catch {exec $exe -tclbatch $cmd -wdb $wdb -log $logfile} err]} then {
        puts stderr "ERROR: Unable to run $exe with $cmd\n$err"
        return 1
    }
    return 0
} 

proc simulation_view {wdb} {
    if {[catch {exec isimgui -view $wdb} err]} then {
        puts stderr "ERROR: Unable to view $wdb\n$err"
        return 1
    }
    return 0
}

proc program_device {bitfiles ipf cmdfile} {
    set cmdfile program_device.cmd
    if {[catch {set fd [open $cmdfile w]} err]} then {
        puts stderr "ERROR: Unable to open $cmdfile for writing\n$err"
        return 1
    }
    puts $fd "setLog -file program_device.log"
    puts $fd "setPreference -pref UserLevel:Novice"
    puts $fd "setPreference -pref ConfigOnFailure:Stop"
    puts $fd "setMode -bscan"
    puts $fd "setCable -port auto"
    puts $fd "identify"
    for {set idx 0} {$idx < [llength $bitfiles]} {incr idx} {
        set bitf [lindex $bitfiles $idx]
        set ii [expr $idx + 1]
        # we use assignFile over addDevice since it allows over-writing
        puts $fd "assignFile -p $ii -file \"$bitf\""
    }
    for {set idx 0} {$idx < [llength $bitfiles]} {incr idx} {
        set ii [expr $idx + 1]
        puts $fd "program -p $ii"
    }
    puts $fd "checkIntegrity"
    puts $fd "saveprojectfile -file \"$ipf\""
    puts $fd "quit"
    catch {close $fd}
    if {[catch {exec impact -batch "./program_device.cmd"} err]} then {
        #TODO: check log here for errors
        puts stderr "ERROR: Unable to run impact to program the device"
        return 1
    }
    return 0
}

proc cleanup_and_exit {xise bdir errcode} {
    if {[catch {xilinx::project close} err]} then {
        puts stderr "WARN: error closing $xise\n$err"
        exit 1
    } else {
        puts stderr "INFO: Closed $xise"
    }
    cd $bdir
    exit $errcode
}

proc open_project {projfile projname} {
    if {[file exists $projfile]} then {
        if {[catch {xilinx::project open $projname} err]} then {
            puts stderr "ERROR: Could not open $projfile for reading\n$err"
            exit 1
        }
        puts stderr "INFO: Opened $projfile"
    } else {
        if {[catch {xilinx::project new $projname} err]} then {
            puts stderr "ERROR: Unable to create $projfile\n$err"
            exit 1
        }
        puts stderr "INFO: Created $projfile"
    }
}

# separate tasks that should not be called together
proc clean_project {projfile} {
    if {[catch {xilinx::project clean} err]} then {
        puts stderr "WARN: Unable to clean $projfile\n$err"
    } else {
        puts stderr "INFO: cleaned project $projfile"
    }
}

proc print_usage {appname} {
    puts stderr "$appname \[OPTIONS\]\n"
    puts stderr "OPTIONS are any or all of the following:"
    puts stderr "-setup\t\t\tCreates/Opens the project and adds parameters, files"
    puts stderr "-build\t\t\tBuilds the project and generates bitstream"
    puts stderr "-simulate\t\tSimulates the generated bitstream"
    puts stderr "-view\t\t\tView the simulation output using isimgui"
    puts stderr "-all\t\t\tAlias for '-clean -setup -build -simulate'"
    puts stderr "-clean\t\t\tCleans the project. Has highest precedence"
    puts stderr "-program \[dev\]\t\tProgram the device given"
    exit 1
}

proc create_file {ff} {
    if {[catch {set fd [open $ff w]} err]} then {
        puts stderr "ERROR: Unable to open $ff for writing\n$err"
        return 1
    }
    puts $fd "1"
    catch {close $fd}
}

TCLFUNC
}

sub _dump_tcl_code {
    my $self = shift;
    my $projext = $self->proj_ext;
    my $projname = $self->proj_name;
    my $dir_build = $self->blib;
    my $src_files = join(' ', @{$self->source_files});
    my $tb_files = join(' ', @{$self->testbench_files});
    my $tbsrc_files = join(' ', @{$self->testbenchsrc_files});
    my @tbfiles = (); # ordered tb matching
    my @prjs = ();
    my @exes = ();
    my @toplevels = ();
    my @srclibs = ();
    my @cmds = ();
    my @wdbs = ();

    my $tb_data = $self->testbench;
    foreach my $f (keys %$tb_data) {
        my $hh = $tb_data->{$f};
        # we assume these have to be defined
        push @tbfiles, $f;
        push @prjs, $hh->{prj};
        push @cmds, $hh->{cmd};
        push @wdbs, $hh->{wdb};
        push @exes, $hh->{exe};
        push @toplevels, $hh->{toplevel};
        push @srclibs, $hh->{srclib};
    }
    my $total_files = scalar @prjs + scalar @cmds + scalar @wdbs + scalar @exes
                        + scalar @toplevels + scalar @srclibs;
    carp "There is a mismatch in the count of internal files" if
        (6 * scalar @prjs) != $total_files;
    $total_files /= 6;
    my $prj_files = join(' ', @prjs);
    my $exe_files = join(' ', @exes);
    my $toplevels_ = join(' ', @toplevels);
    my $srclibs_ = join(' ', @srclibs);
    my $cmd_files = join(' ', @cmds);
    my $wdb_files = join(' ', @wdbs);
    my %pp = %{$self->proj_params};
    $pp{family} = $pp{family} || 'spartan3a';
    $pp{device} = $pp{device} || 'xc3s700a';
    $pp{package} = $pp{package} || 'fg484';
    $pp{speed} = $pp{speed} || '-4';
    $pp{language} = $pp{language} || 'N/A';
    $pp{devboard} = $pp{devboard} || 'None Specified';
    my $vars = << "TCLVARS";
# input parameters start here
set projext {$projext}
set projname {$projname}
set dir_build $dir_build
# Tcl arrays are associative arrays. We need these parameters set in order hence
# we use integers as keys to the parameters
# the following can be retrieved by running the command partgen -arch spartan3a
# this allows the same UCF file used in multiple projects as long as the
# constraint names stay the same
array set projparams {
    0 {family $pp{family}}
    1 {device $pp{device}}
    2 {package $pp{package}}
    3 {speed $pp{speed}}
    4 {"Preferred Language" $pp{language}}
    5 {"Evaluation Development Board" "$pp{devboard}"}
    6 {"Allow Unmatched LOC Constraints" true}
    7 {"Write Timing Constraints" true}
}
# test bench file names matter ! Refer \$Xilinx/data/projnav/xil_tb_patterns.txt
# it has to end in _tb/_tf or should be named testbench
# the constraint file and test bench go together for simulation purposes
set src_files [list $src_files]
set tb_files [list $tb_files]
set tbsrc_files [list $tbsrc_files]
set prj_files [list $prj_files]
set exe_files [list $exe_files]
set toplevels [list $toplevels_]
set srclibs [list $srclibs_]
set cmd_files [list $cmd_files]
set wdb_files [list $wdb_files]
set tb_count $total_files

TCLVARS
    my $functions = $self->_tcl_functions;
    my $basecode = << 'TCLBASE';
# main code starts here
#
set mode_setup 0
set mode_build 0
set mode_simulate 0
set mode_view 0
set mode_program 0
set mode_clean 0
set device_name ""

if { $argc > 0 } then {
    for {set idx 0} {$idx < $argc} {incr idx} {
        set opt [lindex $argv $idx]
        if {$opt == "-setup"} then {
            set mode_setup 1
        } elseif {$opt == "-build"} then {
            set mode_build 1
        } elseif {$opt == "-simulate"} then {
            set mode_simulate 1
        } elseif {$opt == "-view"} then {
            set mode_view 1
        } elseif {$opt == "-clean"} then {
            set mode_clean 1
        } elseif {$opt == "-all"} then {
            set mode_clean 1
            set mode_setup 1
            set mode_build 1
            set mode_simulate 1
        } elseif {$opt == "-program"} then {
            set mode_program 1
            incr idx
            if {$idx < $argc} then {
                set device_name [lindex $argv $idx]
            } else {
                puts stderr "WARN: device name not given."
            }
        } else {
            print_usage $argv0
        }
    }
} else {
    print_usage $argv0
}

set projfile $projname$projext
set basedir [pwd]
set builddir $basedir/$dir_build
set srcdir $basedir
set tbdir $basedir
catch {exec mkdir $builddir}
cd $builddir
puts stderr "INFO: In $builddir"
# this is necessary after the chdir
set projipf [pwd]/$projname.ipf

open_project $projfile $projname
if {$mode_clean == 1} then {
    clean_project $projfile
    file delete -force .done_setup .done_build .done_simulate
}
# check if other options need to be set
if {![file exists .done_simulate] && $mode_view == 1} then {
    puts stderr "INFO: No .done_simulate found in $builddir so running simulate"
    set mode_simulate 1
}
if {![file exists .done_build] && ($mode_simulate == 1 || $mode_view == 1 || $mode_program == 1)} then {
    puts stderr "INFO: No .done_build found $builddir so running build"
    set mode_build 1
}
if {![file exists .done_setup] && $mode_build == 1} then {
    puts stderr "INFO: No .done_setup found in $builddir so running setup"
    set mode_setup 1
}

TCLBASE

    my $single_setup = << 'TCLSETUP0';
if {$mode_setup == 1} then {
    # perform setting of the project parameters
    add_parameters [array get projparams]
    foreach fname $src_files {
        set ff $srcdir/$fname
        add_source_file $ff
    }
    foreach fname $tb_files {
        set ff $tbdir/$fname
        add_testbench_file $ff
    }
    foreach fname $tbsrc_files {
        set ff $tbdir/$fname
        add_testbench_file $ff
    }
    add_parameter {iMPACT Project File} $projipf
TCLSETUP0
    for (my $i = 0; $i < scalar @prjs; ++$i) {
        my $tb_prj = $prjs[$i];
        my $tb_lib = $srclibs[$i];
        my $tb_f = $tbfiles[$i];
        $single_setup .= << "TCL_PRJ_ADD1";
    if {1} then {
        set tb_prj $tb_prj
        set tb_lib $tb_lib
        set tb_idx $i
        set tb_f $tb_f
TCL_PRJ_ADD1
        $single_setup .= << 'TCL_PRJ_ADD2';
        # also create the prj file for simulation later
        if {[catch {set fd [open $tb_prj w]} err]} then {
            puts stderr "ERROR: Unable to open $tb_prj for writing\n$err"
            cleanup_and_exit $projfile $basedir 1
        }
        foreach fname $src_files {
            set ff $srcdir/$fname
            if {[string match *.ucf $fname]} then {
                puts stderr "INFO: Not adding $ff to $tb_prj"
            } elseif {[string match *.vhd $fname]} then {
                puts $fd "vhdl $tb_lib \"$ff\""
            } elseif {[string match *.vhdl $fname]} then {
                puts $fd "vhdl $tb_lib \"$ff\""
            } else {
                puts $fd "verilog $tb_lib \"$ff\""
            }
        }
        foreach fname $tbsrc_files {
            set ff $tbdir/$fname
            if {[string match *.ucf $fname]} then {
                puts stderr "INFO: Not adding $ff to $tb_prj"
            } elseif {[string match *.vhd $fname]} then {
                puts $fd "vhdl $tb_lib \"$ff\""
            } elseif {[string match *.vhdl $fname]} then {
                puts $fd "vhdl $tb_lib \"$ff\""
            } else {
                puts $fd "verilog $tb_lib \"$ff\""
            }
        }
        if {[string match *.vhd $tb_f]} then {
            puts $fd "vhdl $tb_lib \"$tbdir/$tb_f\""
        } elseif {[string match *.vhdl $tb_f]} then {
            puts $fd "vhdl $tb_lib \"$tbdir/$tb_f\""
        } else {
            puts $fd "verilog $tb_lib \"$tbdir/$tb_f\""
        }
        catch {close $fd}
    }
TCL_PRJ_ADD2
    } ## end of for loop
    $single_setup .= << 'TCLSETUP1';
    create_file .done_setup
}
TCLSETUP1
    my $build_code = << 'TCLBUILD';
if {$mode_build == 1} then {
    if {[process_run_task "Check Syntax"]} then {
        cleanup_and_exit $projfile $basedir 1
    }
    if {[process_run_task "Implement Design"]} then {
        cleanup_and_exit $projfile $basedir 1
    }
    if {[process_run_task "Generate Programming File"]} then {
        cleanup_and_exit $projfile $basedir 1
    }
    create_file .done_build
}
TCLBUILD

    my $sim_code = << 'TCLSIM0';
if {$mode_simulate == 1} then {
TCLSIM0
    my $view_code = '';
    for (my $i = 0; $i < scalar @prjs; ++$i) {
        my $tb_prj = $prjs[$i];
        my $tb_lib = $srclibs[$i];
        my $tb_top = $toplevels[$i];
        my $tb_exe = $exes[$i];
        my $tb_cmd = $cmds[$i];
        my $tb_wdb = $wdbs[$i];
        my $tb_log = $tb_exe . '.log';
        $tb_log =~ s/\.exe//g;
        $sim_code .= << "TCLSIM1";
    if {1} then {
        set tb_prj $tb_prj
        set tb_lib $tb_lib
        set tb_top $tb_top
        set tb_exe $tb_exe
        set tb_cmd $tb_cmd
        set tb_wdb $tb_wdb
        set tb_idx $i
        set tb_log $tb_log
TCLSIM1
        $sim_code .= << 'TCLSIM2';
        # create the simulation executable
        set topname $tb_lib.$tb_top
        if {[simulation_create $tb_prj $tb_exe $topname]} then {
            cleanup_and_exit $projfile $basedir 1
        }
        # create the simulation command file
        if {[catch {set fd [open $tb_cmd w]} err]} then {
            puts stderr "ERROR: Unable to open $tb_cmd for writing\n$err"
            cleanup_and_exit $projfile $basedir 1
        }
        puts $fd "onerror \{resume\}"
        puts $fd "wave add /"
        puts $fd "run all"
        puts $fd "quit -f"
        catch {close $fd}
        set path2exe [pwd]/$tb_exe
        if {[simulation_run $path2exe $tb_cmd $tb_wdb $tb_log]} then {
            cleanup_and_exit $projfile $basedir 1
        }
        puts stderr "INFO: simulation($tb_idx) complete"
    }
TCLSIM2
        $view_code .= << "TCLVIEW0";
if {\$mode_view == 1} then {
    set tb_wdb $tb_wdb
TCLVIEW0
        $view_code .= << 'TCLVIEW1';
    if {[simulation_view $tb_wdb]} then {
        cleanup_and_exit $projfile $basedir 1
    }
}
TCLVIEW1
    } ## end of for loop
    $sim_code .= << 'TCLSIM2';
    create_file .done_simulate
}
TCLSIM2

    my $prog_code .= << 'TCLPROG';
if {$mode_program == 1} then {
    puts stderr "INFO: will try to program device $device_name"
    set ipf [pwd]/$projname.ipf
    set bit_files [glob -nocomplain -tails -directory $builddir *.bit]
    set cmdfile program_device.cmd
    if {[program_device $bit_files $ipf $cmdfile]} then {
        cleanup_and_exit $projfile $basedir 1
    }
    # we should set the {iMPACT Project File} value
    add_parameter {iMPACT Project File} $ipf
    puts stderr "INFO: Done programming device $device_name"
}
TCLPROG
    return << "TCLCODE";
### -- THIS PROGRAM IS AUTO GENERATED -- DO NOT EDIT -- ###
$vars
$functions
$basecode
$single_setup
$build_code
$sim_code
$view_code
$prog_code
# ok now cleanup and exit with 0
cleanup_and_exit \$projfile \$basedir 0

TCLCODE
}

1;
__END__
#### COPYRIGHT: 2014. Vikas N Kumar. All Rights Reserved
#### AUTHOR: Vikas N Kumar <vikas@cpan.org>
#### DATE: 30th June 2014
