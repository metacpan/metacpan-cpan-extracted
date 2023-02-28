#
# This file is part of StorageDisplay
#
# This software is copyright (c) 2014-2023 by Vincent Danjean.
#
# This is free software; you can redistribute it and/or modify it under
# the same terms as the Perl 5 programming language system itself.
#
use strict;
use warnings;

package StorageDisplay::Collect;
# ABSTRACT: modules required to collect data. No dependencies (but perl itself)

our $VERSION = '1.0.11'; # VERSION


use Storable;

sub collectors {
    my $self = shift;
    return @{$self->{_attr_collectors}};
}

sub collector {
    my $self = shift;
    my $name = shift;
    return $self->{_attr_collectors_by_provide}->{$name};
}

sub registerCollector {
    my $self = shift;
    my $collector = shift;

    die "$collector not a StorageDisplay::Collect::Collector"
        if not $collector->isa("StorageDisplay::Collect::Collector");

    push @{$self->{_attr_collectors}}, $collector;
    foreach my $cn ($collector->provides) {
        if (exists($self->{_attr_collectors_by_provide}->{$cn})) {
            die "$cn provided by both ".$collector->module." and ".
                $self->{_attr_collectors_by_provide}->{$cn}->module;
        }
        $self->{_attr_collectors_by_provide}->{$cn} = $collector;
    }
}

sub open_cmd_pipe {
    my $self = shift;
    return $self->cmdreader->open_cmd_pipe(@_);
}

sub open_cmd_pipe_root {
    my $self = shift;
    return $self->cmdreader->open_cmd_pipe_root(@_);
}

sub open_file {
    my $self = shift;
    return $self->cmdreader->open_file(@_);
}

sub has_file {
    my $self = shift;
    return $self->cmdreader->has_file(@_);
}

sub cmdreader {
    my $self = shift;
    return $self->{_attr_cmdreader};
}

my @collectors;

sub new {
    my $class = shift;
    my $reader = shift // 'Local';

    if (ref($reader) eq '') {
        my $fullreadername = 'StorageDisplay::Collect::CMD::'.$reader;
        $reader = $fullreadername->new(@_);
    }

    my $self = {
        _attr_cmdreader => $reader,
        _attr_collectors => [],
        _attr_collectors_by_provide => {},
    };

    bless $self, $class;

    foreach my $cdata (@collectors) {
        my $cn = $cdata->{name};
        $cn->new($cdata, $self);
    }
    return $self;
}

sub registerCollectorModule {
    my $class = shift;
    my $collector = shift;

    #my $collector = caller 0;
    #print STDERR "Registering $collector from ".(caller 0)."\n";
    my $info = { name => $collector, @_ };
    foreach my $entry (qw(provides requires)) {
        next if not exists($info->{$entry});
        if (ref($info->{$entry}) eq "") {
            $info->{$entry} = [ $info->{$entry} ];
        }
    }
    push @collectors, $info;
}

# Main collect function
#
# It will iterate on the collectors, respecting dependencies.
sub collect {
    my $self = shift;
    my $req = shift;
    my $infos = {};

    $infos = $self->cmdreader->data_init($infos);

    # 0/undef : not computed
    # 1 : computed
    # 2 : computing
    # 3 : N/A
    my $collector_state = {};

    my $load;
    $load = sub {
        my $col = shift;
        $collector_state->{$_} = 2 for $col->provides;
        foreach my $cname ($col->requires) {
            #print STDERR "  preloading $cname\n";
            my $state = $collector_state->{$cname};
            if (not defined($state)) {
                my $collector = $self->collector($cname);
                die "E: No $cname collector available for ".$col->module."\n"
                    if not defined($collector);
                $load->($collector);
            } elsif ($collector_state->{$cname} == 1) {
                next
            } else {
                die "Loop in collectors requires ($cname required in $col->name)";
            }
        }
        # are files present?
        my @missing_files =
            grep {
                not $self->has_file($_);
            } $col->depends('files');
        if (scalar(@missing_files)) {
            print STDERR "I: skipping ", $col->module, " due to missing file(s): '",
                join("', '", @missing_files), "'\n";
            $collector_state->{$_} = 3 for $col->provides;
            return;
        }
        my $opencmd = $col->depends('root') ?
            'open_cmd_pipe_root' : 'open_cmd_pipe';
        # are programs present?
        my @missing_progs =
            grep {
                my @cmd=('which', $_);
                my $dh = $col->$opencmd(@cmd);
                my $path = <$dh>;
                close($dh);
                not defined($path);
            } $col->depends('progs');
        if (scalar(@missing_progs)) {
            print STDERR "I: skipping ", $col->module, " due to missing program(s): '",
                join("', '", @missing_progs), "'\n";
            $collector_state->{$_} = 3 for $col->provides;
            return;
        }
        # collecting data while providing required data
        my $collected_infos = $col->collect(
            {
                map { $_ => $infos->{$_} } $col->requires
            }, $req);
        # registering provided data
        $infos->{$_} = $collected_infos->{$_} for $col->provides;
        $collector_state->{$_} = 1 for $col->provides;
        #print STDERR "loaded $cn\n";
    };
    # Be sure to collect all collectors
    foreach my $col ($self->collectors) {
        $load->($col);
    }

    return $self->cmdreader->data_finish($infos);
}

1;

###########################################################################
package StorageDisplay::Collect::CMD;

sub new {
    my $class = shift;
    my $self = {};
    bless $self, $class;
    return $self;
}

sub cmd2str {
    my $self = shift;
    my @cmd = @_;
    my $str = join(' ', map {
        my $s = $_;
        $s =~ s/(['\\])/\\$1/g;
        if ($s !~ /^[0-9a-zA-Z_@,:\/=-]+$/) {
            $s="'".$s."'";
        }
        $s;
    } @cmd);
    return $str;
}

sub data_init {
    my $self = shift;
    my $data = shift;

    return $data;
}

sub data_finish {
    my $self = shift;
    my $data = shift;

    return $data;
}

sub open_file {
    my $self = shift;
    my $filename = shift;

    return $self->open_cmd_pipe('cat', $filename);

    my $dh;
    open($dh, '<', $filename) or die "Cannot open $filename: $!";
    return $dh;
}

sub has_file {
    my $self = shift;
    my $filename = shift;

    return -e $filename;
}

1;

###########################################################################
package StorageDisplay::Collect::CMD::Local;

use parent -norequire => "StorageDisplay::Collect::CMD";

sub open_cmd_pipe {
    my $self = shift;
    my @cmd = @_;
    print STDERR "Running: ", $self->cmd2str(@cmd)."\n";
    open(my $dh, '-|', @cmd) or
        die "Cannot run ".$self->cmd2str(@cmd).": $!\n";
    return $dh;
}

sub open_cmd_pipe_root {
    my $self = shift;
    if ($> != 0) {
        return $self->open_cmd_pipe('sudo', @_);
    } else {
        return $self->open_cmd_pipe(@_);
    }
}

1;

###########################################################################
package StorageDisplay::Collect::CMD::LocalBySSH;

use parent -norequire => "StorageDisplay::Collect::CMD";

sub open_cmd_pipe {
    my $self = shift;
    my @cmd = @_;
    my $cmd = $self->cmd2str(@cmd);
    $cmd =~ s/sudo password:\n/sudo password:/;
    print STDERR "Running: $cmd\n";
    open(my $dh, '-|', @cmd) or
        die "Cannot run $cmd: $!\n";
    return $dh;
}

sub open_cmd_pipe_root {
    my $self = shift;
    if ($> != 0) {
        return $self->open_cmd_pipe(qw(sudo -S -p), 'sudo password:'."\n", '--', @_);
    } else {
        return $self->open_cmd_pipe(@_);
    }
}

1;

###########################################################################
package StorageDisplay::Collect::CMD::Proxy::Recorder;

use parent -norequire => "StorageDisplay::Collect::CMD";
use Scalar::Util 'blessed';

sub new {
    my $class = shift;
    my %args = ( @_ );
    if (not exists($args{'recorder-reader'})) {
        die 'recorder-reader argument required';
    }
    my $reader = $args{'recorder-reader'};
    if (ref($reader) eq '') {
        my $fullreadername = 'StorageDisplay::Collect::CMD::'.$reader;
        $reader = $fullreadername->new(@_, %{$args{'recorder-args-pass'} // {}});
    }
    die "Invalid reader" if not blessed($reader) or not $reader->isa("StorageDisplay::Collect::CMD");
    my $self = $class->SUPER::new(@_);
    $self->{'_attr_reader'} = $reader;
    return $self;
}

sub reader {
    my $self = shift;
    return $self->{_attr_reader};
}

sub data_finish {
    my $self = shift;
    my $infos = shift;
    $infos = $self->SUPER::data_finish($infos);
    $infos->{'recorder'} = $self->{_attr_records};
    return $infos;
}

sub _record {
    my $self = shift;
    my $args = { @_ };
    my $dh = $args->{'dh'};
    delete($args->{'dh'});
    my @infos = <$dh>;
    @infos = map { chomp; $_ } @infos;
    close($dh);
    $args->{'stdout'} = \@infos;
    push @{$self->{'_attr_records'}}, $args;
    my $infos = join("\n", @infos);
    if (scalar(@infos)) {
        $infos .= "\n";
    }
    open(my $fh, "<",  \$infos);
    return $fh;
}

sub open_cmd_pipe {
    my $self = shift;
    return $self->_record(
        'root' => 0,
        'cmd' => [ @_ ],
        'dh' => $self->reader->open_cmd_pipe(@_),
        );
}

sub open_cmd_pipe_root {
    my $self = shift;
    return $self->_record(
        'root' => 1,
        'cmd' => [ @_ ],
        'dh' => $self->reader->open_cmd_pipe_root(@_),
        );
}

sub has_file {
    my $self = shift;
    my $filename = shift;
    my $ret = $self->reader->has_file($filename);
    push @{$self->{'_attr_records'}}, {
        'filename' => $filename,
            'value' => $ret,
    };
    return $ret;
}

1;

###########################################################################
package is_collector;

our $CALLER;

sub import {
    my $class = shift;

    my $inheritor = caller(0);

    {
        no strict 'refs'; ## no critic
        push @{"$inheritor\::ISA"}, 'StorageDisplay::Collect::Collector'; # dies if a loop is detected
        $CALLER = $inheritor;
        StorageDisplay::Collect->registerCollectorModule($inheritor, @_);
    };
};

BEGIN {
    # Mark current package as loaded;
    my $p = __PACKAGE__;
    $p =~ s,::,/,g;
    chomp(my $cwd = `pwd`);
    $INC{$p.'.pm'} = $cwd.'/'.__FILE__;#k"current file";
}

1;

###########################################################################
package StorageDisplay::Collect::Collector;

use Storable;

sub open_cmd_pipe {
    my $self = shift;
    return $self->proxy->open_cmd_pipe(@_);
}

sub open_cmd_pipe_root {
    my $self = shift;
    return $self->proxy->open_cmd_pipe_root(@_);
}

sub open_file {
    my $self = shift;
    return $self->proxy->open_file(@_);
}

sub has_file {
    my $self = shift;
    return $self->proxy->has_file(@_);
}

sub collect {
    my $self = shift;
    print STDERR "collect must be implemented in $self\n";
}

sub names_avail {
    my $self = shift;
    print STDERR "names_avail must be implemented in $self\n";
}

sub import {
    print STDERR __PACKAGE__." imported from ".(caller 0)."\n";
}

BEGIN {
    # Mark current package as loaded;
    my $p = __PACKAGE__;
    $p =~ s,::,/,g;
    $INC{$p.'.pm'} = "current file";
}

sub module {
    my $self = shift;
    return $self->{_attr_module};
}

sub requires {
    my $self = shift;
    return @{$self->{_attr_requires}};
}

sub depends {
    my $self = shift;
    my $kind = shift;
    return wantarray
        ? @{$self->{_attr_depends}->{$kind} // []}
        : $self->{_attr_depends}->{$kind};
}

sub provides {
    my $self = shift;
    return @{$self->{_attr_provides}};
}

sub proxy {
    my $self = shift;
    return $self->{_attr_collect};
}

sub select {
    my $self = shift;
    my $infos = shift;
    my $request = shift // {};
    return $self->names_avail;
}

sub new {
    my $class = shift;
    my $infos = shift;
    my $collect = shift;

    my $self = {};
    bless $self, $class;

    $self->{_attr_module} = $infos->{name};
    $self->{_attr_collect} = $collect;
    $self->{_attr_requires} = Storable::dclone($infos->{requires}//[]);
    $self->{_attr_provides} = Storable::dclone($infos->{provides}//[]);
    $self->{_attr_depends} = Storable::dclone($infos->{depends}//{});
    $collect->registerCollector($self);

    return $self;
}

1;

###########################################################################
###########################################################################
###########################################################################
###########################################################################
package StorageDisplay::Collect::SystemBlocks;

use is_collector
    provides => [ qw(lsblk lsblk-hierarchy udev) ],
    no_names => 1,
    depends => {
        progs => [ 'lsblk', 'udevadm' ],
};

use JSON::PP;

sub lsblkjson2perl {
    my $self = shift;
    my $json = shift;
    my $jsonparser = JSON::PP->new;
    eval {
        $jsonparser->allow_bignum;
    };
    eval {
        $jsonparser->boolean_values([0, 1]);
    };
    my $info = {
        map { $_->{kname} => $_ }
            (@{$jsonparser->decode($json)->{"blockdevices"}})
    };
    return $info;
}

sub collect {
    my $self = shift;
    my $infos = {};
    my $dh;
    my $json;

    # Get all infos on system blocks
    # 'lsblk-json-hierarchy' -> Str(json)
    #my $dh=open_cmd_pipe(qw(lsblk --json --bytes --output-all));
    $dh=$self->open_cmd_pipe(qw(lsblk --all --json --output), 'name,kname');
    $json=join("\n", <$dh>);
    close $dh;
    $infos->{'lsblk-hierarchy'}=$self->lsblkjson2perl($json);

    # And keep json infos
    # 'lsblk-json' -> kn -> Str(json)
    $dh=$self->open_cmd_pipe(qw(lsblk --all --json --bytes --output-all --list));
    $infos->{'lsblk'}=$self->lsblkjson2perl(join("\n", <$dh>));
    close $dh;

    # Get all infos with udev
    # 'udev' -> kn ->
    #   - 'path' -> Str(P:)
    #   - 'name' -> Str(N:)
    #   - 'names' -> [ N:, S:... ]
    #   - '_udev_infos' -> id -> Str(val)
    $dh=$self->open_cmd_pipe(qw(udevadm info --query all --export-db));
    my $data={'_udev_infos' => {}};
    my $dname;
    my $lastline;
    while (defined(my $line=<$dh>)) {
        chomp($line);
        $lastline=$line;
        if ($line eq '') {
            if (defined($dname)) {
                if (exists($data->{'names'})) {
                    my @sorted_names=sort @{$data->{'names'}};
                    $data->{'names'}=\@sorted_names;
                }
                $infos->{'udev'}->{$dname}=$data;
            } else {
                #print STDERR "No 'N:' tag in udev entry ".($data->[0]//"")."\n";
            }
            $data={'_udev_infos' => {}};
            $dname=undef;
        } else {
            if ($line =~ /^P: (.*)$/) {
                $data->{'path'}=$1;
            } elsif ($line =~ /^N: (.*)$/) {
                $dname=$1;
                $data->{'name'}=$1;
                push @{$data->{'names'}}, $1;
            } elsif ($line =~ /^S: (.*)$/) {
                push @{$data->{'names'}}, $1;
            } elsif ($line =~ /^E: (DEVLINKS)=(.*)$/) {
                $data->{'_udev_infos'}->{$1}=join(' ', sort(split(' ',$2)));
            } elsif ($line =~ /^E: ([^=]*)=(.*)$/) {
                $data->{'_udev_infos'}->{$1}=$2;
            } elsif ($line =~ /^[MRUTDILQV]: .*$/) {
                # Unused info. See udevadm(8) / Table 1 for more info
            } else {
                print STDERR "Ignoring '$line'".(defined($dname)?(' for '.$dname):'')."\n";
            }
        }
    }
    close $dh;
    if(defined($dname)) {
        die "E: pb avec $dname ($lastline)", "\n";
    }
    return $infos;
}

1;

###########################################################################
package StorageDisplay::Collect::DeviceMapper;

use is_collector
    provides => qw(dm),
    depends => {
        progs => [ 'dmsetup' ],
        root => 1,
};

sub collect {
    my $self = shift;
    my $dm={};
    my $dh;

    # Get all infos with dmsetup
    # 'dm' -> kn ->
    #   DM_NAME
    #   DM_BLKDEVNAME
    #   DM_BLKDEVS_USED
    #   DM_SUBSYSTEM
    #   DM_DEVS_USED
    $dh=$self->open_cmd_pipe_root(qw(dmsetup info -c --nameprefix --noheadings -o),
                                  'name,blkdevname,blkdevs_used,subsystem,devs_used',
                                  '--separator', "\n ");
    my $data={};
    my $dname;
    while (defined(my $line=<$dh>)) {
        chomp($line);
        next if $line eq 'No devices found';
        if ($line =~ /^DM_/) {
            if (defined($dname)) {
                $dm->{$dname}=$data;
            } else {
                #print STDERR "No 'N:' tag in udev entry ".($data->[0]//"")."\n";
            }
            $data={};
            $dname=undef;
        }
        if ($line =~ /^ ?(DM_[^=]*)='(.*)'$/) {
            if ($2 ne '') {
                $data->{$1} = $2;
            }
            if ($1 eq 'DM_BLKDEVNAME') {
                $dname = $2;
            }
        } else {
            print STDERR "Ignoring '$line'".(defined($dname)?(' for '.$dname):'')."\n";
        }
    }
    if (defined($dname)) {
        $dm->{$dname}=$data;
    }
    close $dh;
    return { 'dm' => $dm };
}

1;

###########################################################################
package StorageDisplay::Collect::Partitions;

use is_collector
    provides => [ qw(partitions disks-no-part)],
    requires => [ qw(lsblk udev) ],
    depends => {
        progs => [ 'parted' ],
        root => 1,
};

sub select {
    my $self = shift;
    my $infos = shift;
    my $request = shift // {};
    my @devs=();

    foreach my $kn (sort keys %{$infos->{'lsblk'}}) {
        my $udev_info = $infos->{'udev'}->{$kn};
        my $lsblk_info = $infos->{'lsblk'}->{$kn};
        next if not defined($udev_info);
        if (($udev_info->{'_udev_infos'}->{DEVTYPE} // '') ne 'disk') {
            next;
        }
        if (($udev_info->{'_udev_infos'}->{ID_PART_TABLE_TYPE} // '') eq '') {
            if (($lsblk_info->{'rm'} // 0) == 1) {
                # removed disk (cd, ...), skipping
                next;
            }
            if (($lsblk_info->{'type'} // '') eq 'loop'
		&& ($lsblk_info->{'size'} // 0) == 0) {
                # loop device not attached
                next;
            }
            if (($lsblk_info->{'type'} // '') eq 'lvm') {
                # handled by lvm subsystem
                next;
            }
            # disk with no partition, just get it
            push @devs, $kn;
            next;
        }
        if (
            ($udev_info->{'_udev_infos'}->{ID_PART_TABLE_TYPE} // '') eq 'dos'
            && ($udev_info->{'_udev_infos'}->{ID_PART_ENTRY_NUMBER} // '') ne ''
            && ($udev_info->{'_udev_infos'}->{DM_TYPE} // '') eq 'raid'
            ) {
            print STDERR "I: $kn seems to be a dm-mapped extended dos partition. Skipping it as disk\n";
            #$partitions->{$kn}->{"dos-extended"}=1;
            next;
        }
        push @devs, $kn;
    }
    return @devs;
}

sub collect {
    my $self = shift;
    my $infos = shift;
    my $partitions;
    my $noparts;
    my $dh;

    my @devs=$self->select($infos);

    foreach my $kn (@devs) {
        my $udev_info = $infos->{'udev'}->{$kn};
        if (($udev_info->{'_udev_infos'}->{ID_PART_TABLE_TYPE} // '') eq '') {
            $noparts->{$kn}={'no partitions' => 1};
            next;
        }
        $dh=$self->open_cmd_pipe_root(qw(parted -m -s), "/dev/".$kn, qw(unit B print free));
        my $state=0;
        my $parted={ 'parts' => [] };
        my $startline = '';
        while(defined(my $line=<$dh>)) {
            chomp($line);
            my $multiline = 0;
            if ($startline ne '') {
                $line = $startline . $line;
                $multiline = 1;
            }
            if ($line !~ /;$/) {
                $startline = $line;
                next;
            }
            $startline = '';
            if ($state == 0) {
                if ($line eq "BYT;") {
                    $state = 1;
                    next;
                }
            } elsif ($state == 1) {
                if ($line =~ /.*:([0-9]+)B:[^:]*:[0-9]+:[0-9]+:([^:]*):(.*):;/) {
                    $parted->{size} = $1;
                    $parted->{type} = $2;
                    $parted->{label} = $3;
                    $state = 2;
                    next;
                }
            } elsif ($state == 2) {
                if ($line =~ m/^1:([0-9]+)B:[0-9]+B:([0-9]+)B:free;$/) {
                    push @{$parted->{parts}}, {
                        'kind' => 'free',
                            'start' => $1,
                            'size' => $2,
                    };
                    next;
                } elsif ($line =~ m/^([0-9]+):([0-9]+)B:[0-9]+B:([0-9]+)B:[^:]*:(.*):([^:]*);$/) {
                    push @{$parted->{parts}}, {
                        'kind' => 'part',
                            'id' => $1,
                            'start' => $2,
                            'size' => $3,
                            'label' => $4,
                            'flags' => $5,
                    };
                    if ($multiline) {
                        my $label = $4;
                        if ($label =~ /^Project-Id.*Content-Transfer-Encoding: 8bit$/) {
                            # workaround a parted bug with xfs partitions (at least)
                            $parted->{parts}->[-1]->{'label'}='';
                        }
                    }
                    next;
                }
            }
            print STDERR "W: parted on $kn: Unknown line '$line'\n";
        }
        close($dh);
        if ($state != 2) {
            print STDERR "W: parted on $kn: invalid data (skipping device)\n";
            next;
        }
        if ($udev_info->{'_udev_infos'}->{ID_PART_TABLE_TYPE} eq 'dos') {
            $dh=$self->open_cmd_pipe_root(qw(parted -s), "/dev/".$kn, qw(print));
            $state=0;
            while(defined(my $line=<$dh>)) {
                chomp($line);
                if ($line =~ /^\s([1234]) .* extended( .*)?$/) {
                    $parted->{extended} = $1;
                    last;
                }
            }
        }
        $partitions->{$kn}=$parted;
    }
    return {
        'partitions' => $partitions,
            'disks-no-part' => $noparts,
    };
}

1;

###########################################################################
package StorageDisplay::Collect::LVM;

use is_collector
    provides => 'lvm',
    depends => {
        progs => [ 'lvm' ],
        root => 1,
};

use JSON::PP;

sub lvmjson2perl {
    my $self = shift;
    my $kind = shift;
    my $kstore = shift;
    my $uniq = shift;
    my $keys = shift;
    my $info = shift // {};
    my $json = shift;
    my $jsonparser = JSON::PP->new;
    eval {
        $jsonparser->allow_bignum;
    };
    eval {
        $jsonparser->boolean_values([0, 1]);
    };
    my $alldata = $jsonparser->decode($json)->{'report'}->[0]->{$kind};
    foreach my $data (@$alldata) {
        my $vg=$data->{vg_name} // die "no vg_name in data!";
        my $base = $info->{$vg}->{$kstore};
        my $hashs = [ [$info->{$vg}, $kstore] ];
        if (scalar(@$keys) == 1) {
            # force creation of $info->{$vg}->{$kstore} hash if needed
            my $dummy=$info->{$vg}->{$kstore}->{$data->{$keys->[0]}};
            $hashs = [ [ $info->{$vg}->{$kstore},
                         $data->{$keys->[0]} ] ];
        } elsif (scalar(@$keys) > 1) {
            $hashs = [
                map {
                    # force creation of $info->{$vg}->{$kstore}->{$_} hash if needed
                    my $dummy=$info->{$vg}->{$kstore}->{$_}->{$data->{$_}};
                    [ $info->{$vg}->{$kstore}->{$_},
                      $data->{$_} ]
                } @$keys
                ];
        }
        foreach my $i (@$hashs) {
            my ($h, $k) = @$i;
            if ($uniq) {
                die "duplicate info" if defined($h->{$k});
                $h->{$k} = $data;
            } else {
                push @{$h->{$k}}, $data;
            }
        }
    }
    return $info;
}

sub collect {
    my $self = shift;
    my $dh;
    my $lvm = {};

   # Get all infos on LVM
    # 'lvm' -> 'pv'| -> Str(json)
    $dh=$self->open_cmd_pipe_root(
        qw(lvm pvs --units B --reportformat json --all -o),
        'pv_name,pv_size,pv_free,pv_used,seg_size,seg_start,segtype,pvseg_start,pvseg_size,lv_name,lv_role,vg_name',
        '--select', 'pv_size > 0 || vg_name != ""');
    $self->lvmjson2perl('pv', 'pvs', 0, [], $lvm, join("\n", <$dh>));
    close $dh;

    $dh=$self->open_cmd_pipe_root(
        qw(lvm lvs --units B --reportformat json --all -o),
        'lv_name,seg_size,segtype,seg_start,seg_pe_ranges,seg_le_ranges,vgname,devices,pool_lv,lv_parent');
    $self->lvmjson2perl('lv', 'lvs', 0, [], $lvm, join("\n", <$dh>));
    close $dh;

    $dh=$self->open_cmd_pipe_root(
        qw(lvm vgs --units B --reportformat json --all -o),
        'vg_name,vg_size,vg_free');
    $self->lvmjson2perl('vg', 'vgs-vg', 1, [], $lvm, join("\n", <$dh>));
    close $dh;

    $dh=$self->open_cmd_pipe_root(
        qw(lvm vgs --units B --reportformat json --all -o),
        'vg_name,pv_name,pv_size,pv_free,pv_used');
    $self->lvmjson2perl('vg', 'vgs-pv', 1, ['pv_name'], $lvm, join("\n", <$dh>));
    close $dh;

    $dh=$self->open_cmd_pipe_root(
        qw(lvm vgs --units B --reportformat json --all -o),
        'vg_name,lv_name,lv_size,data_percent,origin,pool_lv,lv_role');
    $self->lvmjson2perl('vg', 'vgs-lv', 1, ['lv_name'], $lvm, join("\n", <$dh>));
    close $dh;

    return {'lvm' => $lvm };
}

1;

###########################################################################
package StorageDisplay::Collect::FS;

use is_collector
    provides => 'fs',
    no_names => 1,
    depends => {
        progs => [ '/sbin/swapon', 'df' ],
	root => 1,
};

sub collect {
    my $self = shift;
    my $dh;

    # Swap and mounted FS
    $dh=$self->open_cmd_pipe(qw(/sbin/swapon --noheadings --raw --bytes),
                             '--show=NAME,TYPE,SIZE,USED');
    my $fs={};
    while(defined(my $line=<$dh>)) {
        chomp($line);
        if ($line =~ m,([^ ]+) (partition|file) ([0-9]+) ([0-9]+)$,) {
            my $info={
                size => $3,
                used => $4,
                free => ''.($3-$4),
                fstype => $2,
                mountpoint => 'SWAP',
            };
            my $dev = $1;
            if ($2 eq 'file') {
                my $dh2=$self->open_cmd_pipe_root(qw(findmnt -n -o TARGET --target), $1);
                my $mountpoint = <$dh2>;
                chomp($mountpoint) if defined($mountpoint);
                close $dh2;
                $info->{'file-mountpoint'}=$mountpoint;
            }
            $fs->{$dev} = $info;
        } elsif ($line =~ m,([^ ]+) ([^ ]+) ([0-9]+) ([0-9]+)$,) {
            # skipping other kind of swap
        } else {
            print STDERR "W: swapon: Unknown line '$line'\n";
        }
    }
    close $dh;

    $dh=$self->open_cmd_pipe_root(qw(df -B1 --local),
                             '--output=source,fstype,size,used,avail,target');
    while(defined(my $line=<$dh>)) {
        chomp($line);
        next if $line !~ m,^/,;
        my @i=split(/\s+/, $line);
        $fs->{$i[0]} = {
            fstype => $i[1],
            size => $i[2],
            used => $i[3],
            free => $i[4],
            mountpoint => $i[5],
        };
    }
    close $dh;

    return { 'fs' => $fs };
}

1;

###########################################################################
package StorageDisplay::Collect::LUKS;

use is_collector
    provides => 'luks',
    requires => [ qw(dm lsblk udev) ],
    depends => {
        progs => [ 'cryptsetup' ],
        root => 1,
};

sub select {
    my $self = shift;
    my $infos = shift;
    my $request = shift // {};
    my @devs=();

    my $dh;
    foreach my $kn (sort keys %{$infos->{'lsblk'}}) {
        my $udev_info = $infos->{'udev'}->{$kn};
        next if not defined($udev_info);
        if (($udev_info->{'_udev_infos'}->{ID_FS_TYPE} // '') ne 'crypto_LUKS') {
            next;
        }
        push @devs, $kn;
    }
    return @devs;
}

sub collect {
    my $self = shift;
    my $infos = shift;
    my $dh;
    my $luks={};

    my @devs=$self->select($infos);

    my $decrypted={
        map {
            $_->{DM_BLKDEVS_USED} => $_->{DM_BLKDEVNAME}
        } grep {
            ($_->{DM_SUBSYSTEM} // '') eq 'CRYPT'
        } values(%{$infos->{dm}})
    };

    foreach my $dev (@devs) {
        $dh=$self->open_cmd_pipe_root(
            qw(cryptsetup luksDump), '/dev/'.$dev);
        my $l={};
        my $luks_header=0;
        while(defined(my $line=<$dh>)) {
            chomp($line);
            if ($line =~ /^LUKS header information/) {
                $luks_header=1;
            } elsif ($line =~ /^Version:\s*([^\s]*)$/) {
                $l->{VERSION} = $1;
            }
        }
        close $dh;
        if ($luks_header) {
            $l->{decrypted} = $decrypted->{$dev};
            $luks->{$dev} = $l;
        }
    }

    return { 'luks' => $luks };
}

1;

###########################################################################
package StorageDisplay::Collect::MD;

use is_collector
    provides => 'md',
    requires => [ qw(dm lsblk udev) ],
    depends => {
        files => [ '/proc/mdstat' ],
        progs => [ 'mdadm' ],
        root => 1,
};

sub names_avail {
    my $self = shift;
    my $infos = shift;
    my @devs=();

    my $dh=$self->open_file('/proc/mdstat');
    while (defined(my $line=<$dh>)) {
        chomp($line);
        next if ($line =~ /^Personalities/);
        next if ($line =~ /^unused devices/);
        next if ($line =~ /^\s/);
        push @devs, ((split(/\s/, $line))[0]);
    }
    close $dh;
    return @devs;
}

sub collect {
    my $self = shift;
    my $infos = shift;
    my @devs = @{ shift // [ $self->select($infos) ]  };
    my $dh;
    my $md={};

    foreach my $dev (@devs) {
        $dh=$self->open_cmd_pipe_root(
            qw(mdadm --misc --detail), '/dev/'.$dev);
        my $l={};
        my $container=0;
        while(defined(my $line=<$dh>)) {
            chomp($line);
            if ($line =~ /^\s*Array Size :\s*([0-9]+)\s*\(/) {
                $l->{'array-size'} = $1*1024;
            } elsif ($line =~ /^\s*Used Dev Size :\s*([0-9]+)\s*\(/) {
                $l->{'used-dev-size'} = $1*1024;
            } elsif ($line =~ /^\s*Raid Level :\s*([^\s].*)/) {
                $l->{'raid-level'} = $1;
                if ($1 eq 'container') {
                    $l->{'raid-container'} = 1;
                    $container = 1;
                }
            } elsif ($line =~ /^\s*State : \s*([^\s].*)/) {
                $l->{'raid-state'} = $1;
            } elsif ($line =~ /^\s*Version : \s*([^\s].*)/) {
                $l->{'raid-version'} = $1;
            } elsif ($line =~ /^\s*Name : \s*([^\s]+)\s*/) {
                $l->{'raid-name'} = $1;
            } elsif ($line =~ /^\s*Member Arrays : \s*([^\s]+.*[^\s])\s*/) {
                $l->{'raid-member-arrays'} = [ split(/ +/, $1) ];
            } elsif ($line =~ /^\s*Container : \s*([^\s]+), member ([0-9]+)\s*/) {
                $l->{'raid-container-device'} = $1;
                $l->{'raid-container-member'} = $2;
            } elsif ($line =~ /^\s*Number\s*Major\s*Minor\s*RaidDevice(\s*State)?/) {
                last;
            }
        }

        my $raid_id = 0;
        while(defined(my $line=<$dh>)) {
            chomp($line);
            if ((! $container)
                && $line =~ /^\s*([0-9]+)\s+([0-9]+)\s+([0-9]+)\s+([0-9-]+)\s+([^\s].*[^\s])\s+([^\s]+)$/) {
                $l->{'devices'}->{$6} = {
                    state => $5,
                    raiddevice => $4,
                };
            } elsif ($container
                     && $line =~ /^\s*(-)\s+([0-9]+)\s+([0-9]+)\s+(-)\s+([^\s]+)$/) {
                $l->{'devices'}->{$5} = {
                    raiddevice => $raid_id++,
                };
            } elsif ($line =~ /^\s*$/) {
            } else {
                print STDERR "W: mdadm on $dev: Unknown line '$line'\n";
            }
        }
        close $dh;
        $md->{$dev} = $l;
    }

    return { 'md' => $md };
}

1;

###########################################################################
package StorageDisplay::Collect::LSI::Sas2ircu;

use is_collector
    provides => 'lsi-sas-ircu',
    depends => {
        progs => [ 'sas2ircu' ],
        root => 1,
};

sub select {
    my $self = shift;
    my $infos = shift;
    my $request = shift // {};
    my @devs=();

    my $dh;
    $dh=$self->open_cmd_pipe_root(qw(sas2ircu LIST));
    my $state=0;
    my $nodata=0;
    while (defined(my $line=<$dh>)) {
        chomp($line);
        if ($state == 0) {
            $nodata=1 if $line eq 'SAS2IRCU: MPTLib2 Error 1';
            next if $line !~ /^[\s-]*-[\s-]*$/;
            $state = 1;
        } elsif ($state == 1) {
            if ($line =~ /^SAS2IRCU:/) {
                if ($line ne 'SAS2IRCU: Utility Completed Successfully.') {
                    print STDERR "W: sas2ircu: $line\n";
                }
                $state = 2;
            } elsif ($line =~ /^\s*([0-9]+)\s+/) {
                push @devs, $1;
            } else {
                print STDERR "E: sas2ircu: unknown line: $line\n";
            }
        } elsif ($state == 2) {
            print STDERR "W: sas2ircu: $line\n";
        }
    }
    if ($state != 2) {
        if ($state != 0 || $nodata != 1) {
            print STDERR "E: sas2ircu: Cannot parse data\n";
        }
    }
    close $dh;
    return @devs;
}

sub parse {
    my $parser = shift;
    my $closure = shift;
    my $res = shift // {};

}

my %name = (
    'Size (in MB)' => 'size-mb',
    'Volume ID' => 'id',
    'Volume wwid' => 'wwid',
    'Status of volume' => 'status',
    );

sub collect {
    my $self = shift;
    my $infos = shift;
    my $dh;
    my $lsi={};

    my @devs=$self->select($infos);


    my $parse_section = sub {
        my $self = shift;
        my $line = shift;
        if ($line eq 'Controller information') {
            #$self->push_new_section->($parse_controller, $closure_controller);
        } elsif ($line eq 'IR Volume information') {
            #return (1, $parse_volumes);
        } elsif ($line eq 'Physical device information') {
            #return (1, $parse_phydev);
        } elsif ($line eq 'Enclosure information') {
            #return (1, $parse_phydev);
        } elsif ($line =~ /SAS2IRCU:/) {
            if ($line eq 'SAS2IRCU: Command DISPLAY Completed Successfully.'
                or $line eq 'SAS2IRCU: Utility Completed Successfully.') {
            } else {
                print STDERR "W: sas2ircu: $line\n";
            }
        } else {
            #if (scalar(keys %$l) != 0) {
            #    print  STDERR "W: sas2ircu: unknown line: $line\n";
            #}
        }
        return 1;
    };


    foreach my $dev (@devs) {
        $dh=$self->open_cmd_pipe_root('sas2ircu', $dev, 'DISPLAY');
        my $l={};
        my $state = 0;
        my $wwid = {};
        my $guid = {};

        my $data = undef;
        my $secdata = undef;

        my $closure=sub {} ;
        my $subclosure=sub {} ;
        while(defined(my $line=<$dh>)) {
            chomp($line);
            next if $line =~ /^[\s-]*$/;
            if ($line =~ /^(Controller) information$/
                || $line =~ /^(Enclosure) information$/) {
                my $section = lc($1);
                $subclosure->($data);
                $closure->($data);
                $data = {};
                $subclosure = sub {};
                $closure = sub {
                    my $curdata = shift;
                    if (exists($l->{$section})) {
                        print STDERR "E: sas2ircu: duplicate section: $line\n";
                    }
                    $l->{$section}=$curdata;
                    return {};
                };
                $state=10;
            } elsif ($line =~ /^IR (Volume) information$/
                     || $line =~ /^Physical (device) information$/) {
                my $section = lc($1).'s';
                $subclosure->($data);
                $closure->($data);
                $secdata=[];
                $subclosure = sub { };
                $closure=sub {
                    my $data = shift;
                    if (exists($l->{$section})) {
                        print STDERR "E: sas2ircu: duplicate section: $line\n";
                    }
                    $l->{$section}=$secdata;
                    return
                };
            } elsif ($line =~ /^IR volume ([^\s])+$/) {
                my $name = $1;
                $subclosure->($data);
                $data = {
                    name => $name,
                };
                $subclosure = sub {
                    my $data = shift;
                    push @$secdata, $data;
                };
            } elsif ($line =~ /^Device is a Hard disk$/) {
                $subclosure->($data);
                $data = {};
                $subclosure = sub {
                    my $data = shift;
                    push @$secdata, $data;
                };
            } elsif ($line =~ /^Initiator at ID .*$/) {
            } elsif ($line =~ /^SAS2IRCU: .* Completed Successfully.$/) {
            } elsif ($line =~ /^[^\s]/) {
                if ($state != 0) {
                    print STDERR "W: sas2ircu: unknown line: $line\n";
                }
            } elsif ($line =~ /^\s+([^\s][^:]*[^\s])\s*:\s+([^\s].*)$/) {
                my $k = $1;
                my $v = $2;
                if ($k =~ m,^PHY\[([^\]]+)\] Enclosure#/Slot#,) {
                    my $phy=$1;
                    my ($e, $s) = split(':', $v);
                    $data->{PHY}->{$phy} = { enclosure => $e, slot => $s };
                    next;
                } elsif ($k eq 'Size (in MB)/(in sectors)') {
                    my ($s1, $s2) = split('/', $v);
                    $data->{'size-mb'}=$s1;
                    $data->{'size-s'}=$s2;
                    $data->{'size'}=$s2 * 512;
                    next;
                }
                $k = $name{$k} // $k;
                $k =~ s/\s*[#]//;
                $k = lc($k);
                $k =~ s/\s+/-/g;
                if ($k eq 'guid') {
                    $guid->{$v}=1;
                } elsif ($k eq 'wwid') {
                    $wwid->{$v}=1;
                }
                $data->{$k}=$v;
            }
        }
        $subclosure->($data);
        $closure->($data);
        close $dh;
        $dh=$self->open_cmd_pipe(qw(find /sys/devices -name sas_address));
        my @lines=<$dh>;
        for my $line (sort @lines) {
            chomp($line);
            my $dh2 = $self->open_file($line)
                or die "Cannot open $line: $!\n";
            my $addr=<$dh2>;
            close $dh2;
            chomp($addr);
            $addr =~ s/^0x//;
            if (defined($wwid->{$addr})) {
                my $dir = $line;
                $dir =~ s/sas_address/block/;
                my $dh3 = $self->open_cmd_pipe('ls', '-1', $dir);
                my @dirs=<$dh3>;
                close($dh3);
                if (scalar(@dirs) != 1) {
                    print STDERR "E: sas2ircu: bad number of block devices for $addr\n";
                } else {
                    chomp($l->{wwid}->{$addr} = $dirs[0]);
                }
            }
        }
        $lsi->{$dev} = $l;
    }

    return { 'lsi-sas-ircu' => $lsi };
}

1;

###########################################################################
package StorageDisplay::Collect::LSI::Megacli;

use is_collector
    provides => 'lsi-megacli',
    depends => {
        progs => [ 'megaclisas-status', 'megacli' ],
        root => 1,
};

sub select {
    my $self = shift;
    my $infos = shift;
    my $request = shift // {};
    my @devs=();

    my $dh;
    $dh=$self->open_cmd_pipe_root(qw(megacli -adpCount -NoLog));
    while (defined(my $line=<$dh>)) {
        chomp($line);
        next if $line !~ /^Controller Count:\s*([0-9]+)\.?\s*$/;
        my $nb_controllers = $1;
        for (my $i=0; $i<$nb_controllers; $i++) {
            push @devs, $i;
        }
        close $dh;
        return @devs;
    }
    print STDERR "E: megacli: cannot find the number of controllers, assuming 0\n";
    close $dh;
    return @devs;
}

sub parse {
    my $parser = shift;
    my $closure = shift;
    my $res = shift // {};

}

sub interleave {
  my @lists = map [@$_], @_;
  my @res;
  while (my $list = shift @lists) {
    if (@$list) {
      push @res, shift @$list;
      push @lists, $list;
    }
  }
  wantarray ? @res : \@res;
}

sub collect {
    my $self = shift;
    my $infos = shift;
    my $dh;

    my @devs=$self->select($infos);

    my $megacli={ map { $_ => {} } @devs };

    $dh=$self->open_cmd_pipe_root('megaclisas-status');

    my $section_name;
    my @headers;
    while(defined(my $line=<$dh>)) {
        chomp($line);
        next if $line =~ /^\s*$/;
        if ($line =~ /^-- (.*) [Ii]nformation(s)?(\s*--)?\s*$/) {
            $section_name=$1;
            if ($section_name =~ /Disk/) {
                $section_name = 'Disk';
            }
        } elsif ($line =~ /^--\s*(ID\s*|.*[^\s])\s*$/) {
            @headers = split(/\s*[|]\s*/, $1);
        } elsif ($line =~ /^(c([0-9]+)(\s|u).*[^\s])\s*$/) {
            my $idc = $2;
            next if not exists($megacli->{$idc});
            my @infos = split(/\s*[|]\s*/, $1);
            if (scalar(@infos) != scalar(@headers)) {
                print STDERR "E: megaclisas-status: invalid number of information: $line\n";
                next;
            }
            my $infos = { interleave(\@headers, \@infos) };
            my $id = $infos->{ID};
            if ($section_name eq 'Disk') {
                $id = $infos->{'Slot ID'};
            }
            if (exists($megacli->{$idc}->{$section_name}->{$id})) {
                print STDERR "E: megaclisas-status: duplicate info for $id: $line\n";
            }
            $megacli->{$idc}->{$section_name}->{$id}=$infos;
        } elsif ($line =~ /^There is at least one disk\/array in a NOT OPTIMAL state.$/) {
            # skip
        } elsif ($line =~ /^RAID ERROR - Arrays: OK:[0-9]+ Bad:[0-9]+ - Disks: OK:[0-9]+ Bad:[0-9]+$/) {
            # skip
        } elsif ($line =~ /^No MegaRAID or PERC adapter detected on your system!$/) {
	    # skip
        } else {
            print STDERR "E: megaclisas-status: invalid line: $line\n";
        }
    }
    close($dh);

    for my $dev (@devs) {
        $dh=$self->open_cmd_pipe_root(qw(megacli -PDList), "-a$dev");
        my $cur_enc;
        my $cur_slot;
        my $cur_size;
        my $get_cur_disk=sub {
            my $slot_id = "[$cur_enc:$cur_slot]";
            if (not exists($megacli->{$dev}->{'Disk'}->{$slot_id})) {
                print STDERR "E: missing disk with slot $slot_id\n";
                return;
            }
            return $megacli->{$dev}->{'Disk'}->{$slot_id};
        };
        while(defined(my $line=<$dh>)) {
            chomp($line);
            next if $line =~ /^\s*$/;
            next if $line eq "Adapter #$dev";
            if ($line eq "^Adapter") {
                print STDERR "W: megacli: strange adapter for #$dev: $line\n";
                next;
            }
            if ($line =~ /^Enclosure Device ID: *([0-9]+|N\/A) *$/) {
                $cur_enc=$1;
		$cur_enc='' if $cur_enc eq 'N/A';
                $cur_slot=undef;
                next;
            }
            if ($line =~ /^Enclosure Device ID: *(.*) *$/) {
                print STDERR "W: megacli: strange enclosure device ID '$1'\n";
	    }
            if ($line =~ /^Slot Number: *([0-9]+) *$/) {
                if (defined($cur_slot) || not defined($cur_enc)) {
                    print STDERR "W: megacli: strange state when finding slot number $1\n";
                }
                $cur_slot=$1;
                next;
            }
            if ($line =~ /^Array *#: *([0-9]+) *$/) {
                my $d=$get_cur_disk->() // next;
                if ($d->{'ID'} !~ /^c[0-9]+uXpY$/) {
                    my $slot_id = $d->{'Slot ID'};
                    print STDERR "E: slot $slot_id has a strange ID\n";
                    next;
                }
                $d->{'ID'} =~ s/X/$dev/;
            }
            if ($line =~ /^Coerced Size:.*\[(0x[0-9a-f]+) *Sectors\]/i) {
                my $d=$get_cur_disk->() // next;
                $d->{'# sectors'} = $1;
            }
            if ($line =~ /^Sector Size: *([0-9]+)$/i) {
                my $d=$get_cur_disk->() // next;
                $d->{'sector size'} = ($1==0)?512:$1;
            }
        }
        close($dh);
    }

    return { 'lsi-megacli' => $megacli };
}

1;

###########################################################################
package StorageDisplay::Collect::Libvirt;

use is_collector
    provides => 'libvirt',
    depends => {
        progs => [ 'virsh' ],
        root => 1,
};

sub select {
    my $self = shift;
    my $infos = shift;
    my $request = shift // {};
    my @vms=();

    my $dh=$self->open_cmd_pipe_root(qw(virsh list --all --name));
    while(defined(my $line=<$dh>)) {
        chomp($line);
        next if $line =~ /^\s*$/;
        push @vms, $line;
    }
    close $dh;
    @vms = sort @vms;
    return @vms;
}

sub collect {
    my $self = shift;
    my $infos = shift;
    my $dh;
    my $libvirt={};

    my @vms=$self->select($infos);

    foreach my $vm (@vms) {
        $dh=$self->open_cmd_pipe_root(qw(virsh domstate), $vm);
        my $v={ name => $vm };
        while(defined(my $line=<$dh>)) {
            chomp($line);
            if ($line =~ /running/) {
                $v->{state} = 'running';
                last;
            }
        }
        close $dh;
        $dh=$self->open_cmd_pipe_root(qw(virsh domblklist --details), $vm);
        while(defined(my $line=<$dh>)) {
            chomp($line);
            next if $line =~ /^[\s-]*$/;
            my @info=split(' ', $line);
            next if ($info[0]//'') eq 'Type';
            #next if ($info[0]//'') ne 'block';
            next if $info[3] eq '-';
            if (scalar(@info) != 4) {
                print STDERR "W: libvirt on $vm: Unknown line '$line'\n";
                next;
            }
            $v->{'blocks'}->{$info[3]} = {
                type => $info[0],
                device => $info[1],
                target => $info[2],
                source => $info[3],
            };
            if ($info[0] eq 'file') {
                my $dh2=$self->open_cmd_pipe_root(qw(findmnt -n -o TARGET --target), $info[3]);
                my $mountpoint = <$dh2>;
                chomp($mountpoint) if defined($mountpoint);
                close $dh2;
                $v->{'blocks'}->{$info[3]}->{'mount-point'}=$mountpoint;
            }
        }
        close $dh;
        $libvirt->{$vm} = $v;
    }

    return { 'libvirt' => $libvirt };
}

1;

###########################################################################
###########################################################################
###########################################################################
###########################################################################
package StorageDisplay::Collect;

sub dump_collect {
    my $reader = shift // 'Local';
    my $collector = __PACKAGE__->new($reader, @_);

    my $info = $collector->collect();

    use Data::Dumper;
    # sort keys
    $Data::Dumper::Sortkeys = 1;
    $Data::Dumper::Purity = 1;

    print Dumper($info);
    #print Dumper(\%INC);
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

StorageDisplay::Collect - modules required to collect data. No dependencies (but perl itself)

=head1 VERSION

version 1.0.11

Main class, allows one to register collectors and run them (through the collect method)

Collectors will be registered when their class is loaded

Base (abstract) class to run command to collect infos

Only one instance should be created

# sub classes must implement open_cmd_pipe and open_cmd_pipe_root

Run commands locally

Run commands through SSH

Record commands

Used to declare a class to be a collector.

The collector will be registered

Base class for collectors

=head1 AUTHOR

Vincent Danjean <Vincent.Danjean@ens-lyon.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2014-2023 by Vincent Danjean.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
