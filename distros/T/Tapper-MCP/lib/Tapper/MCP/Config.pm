package Tapper::MCP::Config;
our $AUTHORITY = 'cpan:TAPPER';
$Tapper::MCP::Config::VERSION = '5.0.9';
use strict;
use warnings;

use 5.010;
use Data::DPath 'dpath';
use File::Basename;
use Fcntl;
use File::Path;
use LockFile::Simple;
use Moose;
use Socket 'inet_ntoa';
use Sys::Hostname;
use YAML::Syck qw /Load Dump LoadFile DumpFile/;

use Tapper::Model 'model';
use Tapper::Cmd::Cobbler;
use Tapper::Config;
use Tapper::MCP::Info;
use Tapper::Producer;
use Try::Tiny;

extends 'Tapper::MCP::Control';

has mcp_info => (is  => 'rw',
                );

sub BUILD
{
        my ($self) = @_;
        $self->{mcp_info} = Tapper::MCP::Info->new();
}




sub parse_simnow_preconditions
{
        my ($self, $config, $precondition) = @_;
        $self->mcp_info->test_type('simnow');
        $config->{log_to_file} = 1;
        return $config;
}


sub parse_hint_preconditions
{
        my ($self, $config, $precondition) = @_;
        $config->{log_to_file} = 1;
        if ($precondition->{simnow}) {
                $self->mcp_info->test_type('simnow');
                $config->{paths}{base_dir}='/';
                $config->{files}{simnow_script} = $precondition->{script} if $precondition->{script};
                push @{$config->{preconditions}}, {precondition_type => 'simnow_backend'};
        } elsif ($precondition->{ssh}) {
                $self->mcp_info->test_type('ssh');
                $config->{paths}{base_dir}='/';
                $config->{prcs}->[0]->{skip_startscript} = 1;
                $config->{client_package} = {
                                             arch      => $precondition->{arch},
                                             dest_path => $precondition->{dest_path},
                                            } if $precondition->{arch};
        } elsif ($precondition->{local}) {
                $self->mcp_info->test_type('local');
                $config->{prcs}->[0]->{skip_startscript} = 1;
                $self->mcp_info->skip_install(1) if $precondition->{skip_install};
        } elsif ($precondition->{minion}) {
                $self->mcp_info->test_type('minion');
                $config->{prcs}->[0]->{skip_startscript} = 1;
                $self->mcp_info->skip_install(1);
        }
        return $config;
}



sub add_tapper_package_for_guest
{

        my ($self, $config, $guest, $guest_number) = @_;
        my $tapper_package->{precondition_type} = '';

        my $guest_arch                       = $guest->{root}{arch} or return "No architecture set for guest #$guest_number";
        $tapper_package->{filename}          = $self->cfg->{files}->{tapper_package}{$guest_arch};

        $tapper_package->{precondition_type} = 'package';
        $tapper_package->{mountpartition}    = $guest->{mountpartition};
        $tapper_package->{mountfile}         = $guest->{mountfile} if $guest->{mountfile};

        push @{$config->{preconditions}}, $tapper_package;
        return $config;
}



sub handle_guest_tests
{
        my ($self, $config, $guest, $guest_number) = @_;

        $config = $self->parse_testprogram($config, $guest->{testprogram}, $guest_number)
          if $guest->{testprogram};
        return $config unless ref $config eq 'HASH';

        $config = $self->parse_testprogram_list($config, $guest->{testprogram_list}, $guest_number)
          if $guest->{testprogram_list};
        return $config unless ref $config eq 'HASH';

        return $config;
}



sub parse_virt_host
{
        my ($self, $config, $virt) = @_;
        my $lc_type = lc($virt->{host}->{root}->{precondition_type});
                if ($lc_type eq 'image') {
                        $config = $self->parse_image_precondition($config, $virt->{host}->{root});
                }
                elsif ($lc_type eq 'autoinstall') {
                        $config = $self->parse_autoinstall($config, $virt->{host}->{root});
                }

        # additional preconditions for virt host
        if ($virt->{host}->{preconditions}) {
                push @{$config->{preconditions}}, @{$virt->{host}->{preconditions}};
        }
        return $config;
}




sub parse_virt_preconditions
{

        my ($self, $config, $virt) = @_;
        my $retval;

        $config = $self->parse_virt_host($config, $virt);
        $config = $self->parse_testprogram($config, $virt->{host}->{testprogram}, 0) if $virt->{host}->{testprogram};
        $config = $self->parse_testprogram_list($config, $virt->{host}->{testprogram_list}, 0) if $virt->{host}->{testprogram_list};
        return $config unless ref($config) eq 'HASH';
        my $total_guests = int @{$virt->{guests} || []};

        for (my $guest_number = 1; $guest_number <= int @{$virt->{guests} || []}; $guest_number++ ) {
                my $guest = $virt->{guests}->[$guest_number-1];

                $guest->{mountfile} = $guest->{root}->{mountfile};
                $guest->{mountpartition} = $guest->{root}->{mountpartition};
                $guest->{mountdir} = $guest->{root}->{mountdir};
                delete $guest->{root}->{mountpartition};
                delete $guest->{root}->{mountfile} if $guest->{root}->{mountfile};
                delete $guest->{root}->{mountdir};


                $retval = $self->mcp_info->add_prc($guest_number, $self->cfg->{times}{boot_timeout});
                return $retval if $retval;

                # if we have a qcow image, we need a raw image to copy PRC stuff to
                no warnings 'uninitialized';
                my $mtype = $guest->{root}{mounttype};
                        if ($mtype eq 'raw') {
                                my $raw_image = {
                                                 precondition_type => 'rawimage',
                                                 name              => basename($guest->{mountfile}),
                                                 path              => dirname($guest->{mountfile})
                                                };
                                push @{$config->{preconditions}}, $raw_image;
                        }
                        elsif ($mtype eq 'windows') {
                                my $raw_image = {
                                                 precondition_type => 'copyfile',
                                                 name              => $self->cfg->{files}{windows_test_image},
                                                 dest              => $guest->{mountfile},
                                                 protocol          => 'nfs',
                                                };
                                push @{$config->{preconditions}}, $raw_image;
                        }
                use warnings;

                push @{$config->{preconditions}}, $guest->{root} if $guest->{root}->{precondition_type};
                push @{$config->{preconditions}}, $guest->{config} if exists $guest->{config}->{precondition_type};
                if ($guest->{config}->{svm}) {
                        push @{$config->{prcs}->[0]->{config}->{guests}}, {svm=>$guest->{config}->{svm}};
                } elsif ($guest->{config}->{kvm}) {
                        push @{$config->{prcs}->[0]->{config}->{guests}}, {exec=>$guest->{config}->{kvm}};
                } elsif ($guest->{config}->{exec}) {
                        push @{$config->{prcs}->[0]->{config}->{guests}}, {exec=>$guest->{config}->{exec}};
                }

                if ($guest->{testprogram} or $guest->{testprogram_list}) {
                        $config = $self->handle_guest_tests($config, $guest, $guest_number);
                        return $config unless ref $config eq 'HASH';
                }

                # put guest preconditions into precondition list
                foreach my $guest_precondition(@{$guest->{preconditions}}) {
                        if ( $guest_precondition->{precondition_type} eq 'testprogram' ) {
                                $config = $self->parse_testprogram($config, $guest_precondition, $guest_number);
                        } elsif ( $guest_precondition->{precondition_type} eq 'testprogram' ) {
                                $config = $self->parse_testprogram_list($config, $guest_precondition, $guest_number);
                        } else {
                                $guest_precondition->{mountpartition} = $guest->{mountpartition};
                                $guest_precondition->{mountfile} = $guest->{mountfile} if $guest->{mountfile};
                                push @{$config->{preconditions}}, $guest_precondition;
                        }
                        return $config unless ref $config eq 'HASH';
                }

                # add a PRC for every guest
                $config = $self->add_tapper_package_for_guest($config, $guest, $guest_number);
                return $config unless ref $config eq 'HASH';

                $config->{prcs}->[$guest_number]->{mountfile} = $guest->{mountfile};
                $config->{prcs}->[$guest_number]->{mountpartition} = $guest->{mountpartition};
                $config->{prcs}->[$guest_number]->{config}->{guest_number} = $guest_number;
                $config->{prcs}->[$guest_number]->{config}->{total_guests} = $total_guests;
        }
        $config->{prcs}->[0]->{config}->{guest_count} = int @{$virt->{guests} || []};

        return $config;
}



sub  parse_grub
{
        my ($self, $config, $precondition) = @_;
        $config->{grub} = $precondition->{config};
        return $config;
}




sub  parse_reboot
{
        my ($self, $config, $reboot) = @_;
        $self->mcp_info->set_max_reboot(0, $reboot->{count});
        $config->{prcs}->[0]->{config}->{max_reboot} = $reboot->{count};
        return $config;
}


sub parse_image_precondition
{
        my ($self, $config, $precondition) = @_;
        my $opt_pkg;

        if ($precondition->{arch}) {
                $opt_pkg = {precondition_type => 'package',
                            filename => $self->cfg->{files}->{tapper_package}{$precondition->{arch}},
                           };
                $opt_pkg->{mountfile} = $precondition->{mountfile} if $precondition->{mountfile};
                $opt_pkg->{mountpartition} = $precondition->{mountpartition} if $precondition->{mountpartition};
                delete $precondition->{arch};
        }

        if ($precondition->{mount} eq '/') {
                unshift @{$config->{preconditions}}, $precondition;
        } else {
                push @{$config->{preconditions}}, $precondition;
        }

        if ($opt_pkg) {
                push @{$config->{preconditions}}, $opt_pkg;
                push @{$config->{preconditions}}, {precondition_type => 'exec',
                                                   filename          => '/opt/tapper/perl/perls/current/bin/tapper-testsuite-hwtrack',
                                                   continue_on_error => 1 };
        }
        return $config;
}



sub parse_cobbler_preconditions
{
        my ($self, $config, $cobbler) = @_;
        my $cmd = Tapper::Cmd::Cobbler->new();
        my $host = $self->testrun->testrun_scheduling->host->name;
        my $error;


        # add host if not already known to Cobbler
        my @hosts = eval{ $cmd->host_list({name => $host})};
        return $@ if $@;
        if (not @hosts) {
                # one possible error is a race condition between list and host_new
                # this should be rare enough to justify the issue for easier development
                $error = $cmd->host_new($host);
                return $error if $error;
        }

        $error  = $cmd->host_update({name => $host, profile => $cobbler->{profile}, "netboot-enabled" => 1});
        return $error if $error;
        $config->{cobbler} = $cobbler->{profile};
        return $config;
}


sub parse_testprogram
{
        my ($self, $config, $testprogram, $prc_number) = @_;
        $prc_number //= 0;
        $prc_number = $testprogram->{prc} if $testprogram->{prc}; # allow overriding PRC number for nesting

        if (not $testprogram->{timeout}) {
                $testprogram->{timeout} = $testprogram->{timeout_testprogram};
                delete $testprogram->{timeout_testprogram};
        }
        if ($testprogram->{execname}) {
                $testprogram->{program} = $testprogram->{execname};
                delete $testprogram->{execname};
        }
        $testprogram->{runtime} = $testprogram->{runtime} || $self->cfg->{times}{test_runtime_default};

        $testprogram->{timeout} = ($self->cfg->{times}{default_testprogram_timeout} // 600) unless defined $testprogram->{timeout};
        no warnings 'uninitialized';
        push @{$config->{prcs}->[$prc_number]->{config}->{testprogram_list}}, $testprogram;

        $config->{prcs}->[$prc_number]->{mountfile} = $testprogram->{mountfile}
          if $testprogram->{mountfile} and not $config->{prcs}->[$prc_number]->{mountfile};
        $config->{prcs}->[$prc_number]->{mountpartition} = $testprogram->{mountpartition}
          if $testprogram->{mountpartition} and not $config->{prcs}->[$prc_number]->{mountpartition};

        $self->mcp_info->add_testprogram($prc_number, $testprogram);
        use warnings;
        return $config;

}


sub parse_testprogram_list
{
        my ($self, $config, $testprogram_list, $prc_number) = @_;

        return $config unless ref $testprogram_list eq 'ARRAY';
        foreach my $testprogram (@$testprogram_list) {
                $config = $self->parse_testprogram($config, $testprogram, $prc_number);
        }
        return $config;
}




sub parse_autoinstall
{
        my ($self, $config, $autoinstall) = @_;

        if ($autoinstall->{grub_text}) {
                $config->{installer_grub} = $autoinstall->{grub_text};
        } elsif ($autoinstall->{grub_file}) {
                open my $fh, "<", $autoinstall->{grub_file} or return "Can not open grub file ( ".$autoinstall->{grub_file}." ):$!";
                $config->{installer_grub} = do {local $\; <$fh>};
                close $fh;
        } else {
                return "Can not find autoinstaller grub config";
        }

        $config->{autoinstall} = 1;
        $config->{paths}{base_dir} = '/';
        my $timeout = $autoinstall->{timeout} || $self->cfg->{times}{installer_timeout};
        $self->mcp_info->set_installer_timeout($timeout);
        return $config;
}


sub update_installer_grub
{
        my ($self, $config)    = @_;

        $config->{installer_grub} = $self->cfg->{mcp}{installer}{default_grub} if not $config->{installer_grub};
        return $config;
}


sub produce
{
        my ($self, $config, $precondition) = @_;
        my $producer = Tapper::Producer->new();
        my $producer_config = $producer->produce($self->testrun->testrun_scheduling, $precondition);

        die $producer_config if not ref($producer_config) eq 'HASH';

        if ($producer_config->{topic}) {
                $self->testrun->topic_name($producer_config->{topic});
                $self->testrun->update;
        }
        my @precond_array = Load($producer_config->{precondition_yaml});
        return \@precond_array;
}



sub parse_produce_precondition
{
        my ($self, $config, $precondition) = @_;

        my $error;
        my $produced_preconditions = try {$self->produce($config, $precondition->precondition_as_hash)} catch {$error = $_};
        return $error if $error;

        return $produced_preconditions
          unless ref($produced_preconditions) eq 'ARRAY';
        my $position = model->resultset('TestrunPrecondition')->search({testrun_id => $self->testrun->id,
                                                                        precondition_id => $precondition->id}, {rows => 1})->first->succession;
        $self->testrun->disassign_preconditions($precondition->id);

        foreach my $produced_precondition (@$produced_preconditions) {
                my ($new_id) = model->resultset('Precondition')->add( [$produced_precondition] );
                $self->testrun->insert_preconditions($position++, $new_id);

                my ($new_precondition) = model->resultset('Precondition')->find( $new_id );
                $config = $self->parse_precondition($config, $new_precondition);
                return $config unless ref($config) eq 'HASH';
        }
        return $config;

}


sub produce_preconds_in_arrayref
{
        my ($self, $config, $preconditions) = @_;
        my @new_preconds;

        my $error;
        return "Did not receive an array ref for 'produce_preconds_in_arrayref'"
          unless ref $preconditions eq 'ARRAY';

        foreach my $precondition ( @$preconditions ) {
                if (lc($precondition->{precondition_type}) eq 'produce') {
                        my $produced_preconditions = try {$self->produce($config, $precondition)} catch {$error = $_};
                        return $error if $error;
                        push @new_preconds, @$produced_preconditions;
                } else {
                        push @new_preconds, $precondition;
                }
        }
        @$preconditions = @new_preconds;
        return 0;
}


sub produce_virt_precondition
{
        my ($self, $config, $precondition) = @_;
        local $Data::DPath::USE_SAFE; # path not from user, Safe.pm deactivated for debug and speed
        my @producers = dpath('//*[key eq "precondition_type" and lc(value) eq "produce"]/../..')->match($precondition);
        foreach my $producer (@producers) {
                if (ref $producer eq 'ARRAY') {
                        my $error = $self->produce_preconds_in_arrayref($config, $producer);
                        return $error if $error;
                } elsif (ref $producer eq 'HASH') {
                        foreach my $key ( keys %$producer ) {
                                if (ref($producer->{$key}) eq 'ARRAY') {
                                        my $error = $self->produce_preconds_in_arrayref($config, $producer->{$key});
                                        return $error if $error;
                                } elsif (ref($producer->{$key}) eq 'HASH' and
                                         lc($producer->{$key}->{precondition_type}) eq 'produce') {
                                        my $error;
                                        my $produced_preconditions = try {$self->produce($config, $producer->{$key})} catch {$error = $_};
                                        return $error if $error;
                                        $producer->{$key} = $produced_preconditions->[0];
                                }
                        }
                }
        }
        return $precondition;
}



sub parse_precondition
{
        my ($self, $config, $precondition_result) = @_;
        my $precondition = $precondition_result->precondition_as_hash;

        my $type = lc($precondition->{precondition_type});
                if ($type eq 'produce') {
                        $config = $self->parse_produce_precondition($config, $precondition_result);
                }
                elsif ($type eq 'image' ) {
                        $config = $self->parse_image_precondition($config, $precondition);
                }
                elsif ($type eq 'virt' ) {
                        $precondition = $self->produce_virt_precondition($config, $precondition);
                        return $precondition unless ref $precondition eq 'HASH';


                        $precondition_result->precondition(Dump($precondition));
                        $precondition_result->update;

                        $config       = $self->parse_virt_preconditions($config, $precondition);
                }
                elsif ($type eq 'grub') {
                        $config = $self->parse_grub($config, $precondition);
                }
                elsif ($type eq 'installer_stop') {
                        $config->{installer_stop} = 1;
                }
                elsif ($type eq 'testrun_stop') {
                        $config->{testrun_stop} = 1;
                }
                elsif ($type eq 'reboot') {
                        $config = $self->parse_reboot($config, $precondition);
                }
                elsif ($type eq 'autoinstall') {
                        $config = $self->parse_autoinstall($config, $precondition);
                }
                elsif ($type eq 'testprogram') {
                        $config = $self->parse_testprogram($config, $precondition);
                }
                elsif ($type eq 'testprogram_list') {
                        $config = $self->parse_testprogram_list($config, $precondition);
                }
                elsif ($type eq 'simnow' ) {
                        $config=$self->parse_simnow_preconditions($config, $precondition);
                }
                elsif ($type eq 'hint' ) {
                        $config=$self->parse_hint_preconditions($config, $precondition);
                }
                elsif ($type eq 'cobbler' ) {
                        $config=$self->parse_cobbler_preconditions($config, $precondition);
                }
                else {
                        push @{$config->{preconditions}}, $precondition;
                }


        return $config;
}

# replace $TAPPER_PLACEHOLDERS in grub config file
sub grub_substitute_variables
{
        no warnings 'uninitialized'; # some options may not be set, especially during testing. This is ok.
        my ($self, $config, $grubtext) = @_;

        my $tapper_host        = $config->{mcp_host};
        my $tapper_port        = $config->{mcp_port};
        my $packed_ip          = gethostbyname($tapper_host);
        die "Can not get an IP address for tapper_host ($tapper_host): $!" if not defined $packed_ip;
        my $tapper_ip          = inet_ntoa($packed_ip);
        my $tapper_environment = Tapper::Config::_getenv();
        my $testrun            = $config->{test_run};
        my $nfsroot            = $config->{paths}{nfsroot};
        my $kernel             = $config->{files}{installer_kernel};
        my $tftp_server        = $self->cfg->{tftp_server_address};
        my $hostoptions        = $self->cfg->{grub_completion_HOSTOPTIONS}{$config->{hostname}} || $self->cfg->{grub_completion_HOSTOPTIONS}{_default};
        my $xenhostoptions     = $self->cfg->{grub_completion_XENHOSTOPTIONS}{$config->{hostname}} || $self->cfg->{grub_completion_XENHOSTOPTIONS}{_default};

        $grubtext =~ s|\$TAPPER_OPTIONS\b|tapper_ip=$tapper_ip tapper_port=$tapper_port testrun=$testrun tapper_host=$tapper_host tapper_environment=$tapper_environment|g;
        $grubtext =~ s|\$TAPPER_NFSROOT\b|$nfsroot|g;
        $grubtext =~ s|\$TAPPER_TFTPSERVER\b|$tftp_server|g;
        $grubtext =~ s|\$TAPPER_KERNEL\b|$kernel|g;
        $grubtext =~ s|\$HOSTOPTIONS\b|$hostoptions|g;
        $grubtext =~ s|\$XENHOSTOPTIONS\b|$xenhostoptions|g;

        return $grubtext;
}


sub get_install_config
{
        my ($self, $config) = @_;


        my $retval = $self->mcp_info->add_prc(0, $self->cfg->{times}{boot_timeout});
        return $retval if $retval;

        {
                no warnings 'uninitialized'; # allowing this timeout to be undef is a feature
                $retval    = $self->mcp_info->set_keep_alive_timeout($self->cfg->{keep_alive}{timeout_receive});
                $config->{times}{keep_alive_timeout} = $self->cfg->{keep_alive}{timeout_send};
                $config->{mcp_callback_handler}{plugin} = $self->cfg->{mcp_callback_handler}{plugin};
                $config->{mcp_callback_handler}{plugin_plugin} = $self->cfg->{mcp_callback_handler}{plugin_options};
        }

 PRECONDITION:
        foreach my $precondition_result ( $self->testrun->ordered_preconditions) {
                $config = $self->parse_precondition($config, $precondition_result);
                # was not able to parse precondition and thus
                # return received error string
                if (not ref($config) eq 'HASH' ) {
                        return $config;
                }
        }



        # always have a PRC0 even without any test programs
        unless ($self->mcp_info->test_type() eq 'simnow'
                or $config->{prcs}) {
                $config->{prcs}->[0] = {testprogram_list => []};
        }

        # generate installer config
        $config = $self->update_installer_grub($config);

        my $current_prc_number = 0;
        while (my $prc_precondition = shift(@{$config->{prcs}})){
                $prc_precondition->{precondition_type} = "prc";
                $prc_precondition->{config}->{guest_number} = $current_prc_number++;
                push(@{$config->{preconditions}}, $prc_precondition);
        }

        $config->{grub} = $self->cfg->{mcp}{test}{default_grub} if not $config->{grub};

        my $error;
        $config->{installer_grub} = try { $self->grub_substitute_variables($config, $config->{installer_grub}) }
          catch { $error = $_} if $config->{installer_grub}; return $error if $error;
        $config->{grub}           = try { $self->grub_substitute_variables($config, $config->{grub}) }
          catch { $error = $_} if ($config->{grub}); return $error if $error;
        return $config;
}



sub get_common_config
{
        my ($self) = @_;
        my $config;
        my $testrun = $self->testrun;

        $config->{paths}                     = $self->cfg->{paths};
        $config->{times}                     = $self->cfg->{times};
        $config->{files}                     = $self->cfg->{files};
        $config->{mcp_host}                  = Sys::Hostname::hostname() || $self->cfg->{mcp_host};
        $config->{mcp_server}                = $config->{mcp_host};
        $config->{mcp_port}                  = $self->cfg->{mcp_port};
        $config->{sync_port}                 = $self->cfg->{sync_port};
        $config->{report_server}             = $self->cfg->{report_server};
        $config->{report_port}               = $self->cfg->{report_port};
        $config->{report_api_port}           = $self->cfg->{report_api_port};
        $config->{prc_nfs_server}            = $self->cfg->{prc_nfs_server}
          if $self->cfg->{prc_nfs_server}; # prc_nfs_path is set by merging paths above
        $config->{test_run}                  = $testrun->id;
        $config->{testrun_id}                = $testrun->id;

        if ($testrun->testplan_id) {
                $config->{testplan} = { id => $testrun->testplan_id, path => $testrun->testplan_instance->path };
        }

        if ($self->testrun->scenario_element) {
                $config->{scenario_id} = $self->testrun->scenario_element->scenario_id;
                $config->{paths}{sync_path}.="/".$config->{scenario_id}."/";
                my $path = $config->{paths}{sync_path};
                $config->{files}{sync_file} = "$path/syncfile";

                if ($self->testrun->scenario_element->peer_elements->search({}, {rows => 1})->first->testrun->id == $testrun->id) {
                        if (not -d $path) {
                                File::Path::mkpath($path, {error => \my $retval});
                        ERROR:
                                foreach my $diag (@$retval) {
                                        my ($file, $message) = each %$diag;
                                        #  $file might have been created by other scenario element between -d and mkpath
                                        # in this case ignore the error
                                        next ERROR if -d $file;
                                        return "general error: $message\n" if $file eq '';
                                        return "Can't create $file: $message";
                                }
                        }

                        # shortest way to deal with undefined options
                        if (not eval {$self->testrun->scenario_element->scenario->options->{no_sync}})
                        {
                                my @peers = map {$_->testrun->testrun_scheduling->host->name} $self->testrun->scenario_element->peer_elements->all;
                                if (sysopen(my $fh, $config->{files}{sync_file}, O_CREAT | O_EXCL |O_RDWR )) {
                                        print $fh $self->testrun->scenario_element->peer_elements->count;
                                        close $fh;
                                } # else trust the creator
                                my $error;
                                try {
                                        YAML::DumpFile($config->{files}{sync_file}, \@peers);
                                } catch { $error = $_};
                                return $error if $error;
                        }
                }
        }
        return ($config);
}




sub get_test_config
{
        my ($self) = @_;
        my $retval;


        for (my $i=0; $i<=$self->mcp_info->get_prc_count(); $i++) {
                push @$retval, {testprogram_list => [ $self->mcp_info->get_testprograms($i) ]};
        }
        return $retval;
}



sub create_config
{
        my ($self) = @_;
        my $config = $self->get_common_config();
        return $config if not ref $config eq 'HASH';

        $config    = $self->get_install_config($config);
        return $config;
}


sub write_config
{
        my ($self, $config, $cfg_file) = @_;
        my $cfg = YAML::Dump($config);
        $cfg_file = $self->cfg->{paths}{localdata_path}."/$cfg_file" if not $cfg_file =~ m(^/);
        my $dir = dirname($cfg_file);
        $self->makedir($dir);
        open (my $file, ">", $cfg_file)
          or return "Can't open config file $cfg_file for writing: $!";
        print $file $cfg;
        close $file;
        return 0;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Tapper::MCP::Config

=head1 SYNOPSIS

 use Tapper::MCP::Config;

=head1 NAME

Tapper::MCP::Config - Generate config for a certain test run

=head1 FUNCTIONS

=head2 parse_simnow_preconditions

Parse a simnow precondition.

@param hash ref - config
@param hash ref - simnow precondition

@return success - 0

=head2 parse_hint_preconditions

Parse a hint precondition.

@param hash ref - config
@param hash ref - hint precondition

@return success - 0

=head2 add_tapper_package_for_guest

Add opt tapper package to guest

@param hash ref - config
@param hash ref - guest
@param int - guest number

@return success - new config (hash ref)
@return error   - error string

=head2 handle_guest_tests

Create guest PRC config based on guest tests.

@param hash ref - old config
@param hash ref - guest description
@param int      - guest number

@return success - new config hash ref
@return error   - error string

=head2 parse_virt_host

Parse host definition of a virt precondition and change config accordingly

@param hash ref - old config
@param hash ref - virt precondition

@return hash ref - new config

=head2 parse_virt_preconditions

Unpack a precondition virt entry into images, packages and files to be
installed for this virt package to work.

@param hash ref - config hash to which virt precondition should be added
@param hash ref - precondition as hash

@return success - hash reference containing the new config
@return error   - error string

=head2 parse_grub

Handle precondition grub. Even though a preconfigured grub config is provided
as precondition, it needs to get a special place in the Yaml file. Otherwise
it would be hard to find for the installer process generating the grub config
file.

@param hash ref - config to change
@param hash ref - precondition as hash

@return success - config hash
@return error   - error string

=head2 parse_reboot

Handle precondition grub. Even though a preconfigured grub config is provided
as precondition, it needs to get a special place in the Yaml file. Otherwise
it would be hard to find for the installer process generating the grub config
file.

@param hash ref - config to change
@param hash ref - precondition as hash

@return success - config hash
@return error   - error string

=head2 parse_image_precondition

Handle precondition image. Make sure the appropriate opt-tapper package is
installed if needed. Care for the root image being installed first.

@param hash ref - config to change
@param hash ref - precondition as hash

@return success - config hash
@return error   - error string

=head2 parse_cobbler_preconditions

Handle precondition cobbler. Make sure host exists in cobbler system.

@param hash ref - config to change
@param hash ref - precondition as hash

@return success - config hash
@return error   - error string

=head2 parse_testprogram

Handle precondition testprogram. Make sure testprogram is correctly to config
and internal information set.

@param hash ref - config to change
@param hash ref - precondition as hash
@param int - prc_number, optional

@return success - config hash
@return error   - error string

=head2 parse_testprogram_list

Handle testprogram list precondition. Puts testprograms to config and
internal information set.

@param hash ref - config to change
@param hash ref - precondition as hash
@param int - prc_number, optional

@return success - config hash
@return error   - error string

=head2 parse_autoinstall

Parse precondition autoinstall and change config accordingly.

@param hash ref - config to change
@param hash ref - precondition as hash

@return success - config hash
@return error   - error string

=head2 update_installer_grub

Get the text for grub config file at booting into installation.

@param hash ref - config to change

@return success - config hash
@return error   - error string

=head2 produce

Calls the producer for the given precondition

@param hash ref - config
@param hash ref - precondition

@return success - array ref containing preconditions

@throws die()

=head2 parse_produce_precondition

Parse a producer precondition, insert the produced ones and delete the
old one. In case of success the updated config is returned.

@param hash ref                   - old config
@param precondition result object - precondition

@return success - hash ref
@return error   - error string

=head2 produce_preconds_in_arrayref

Take an array ref, find the producers in it and produce them. Substitute
the producer preconditions with the produced preconditions they generated.

This function changes the received argument instead of returning an
updated version. This makes sure you can change your precondition step
by step instead of having to create a new one.

@param hash ref  - config
@param array ref - preconditions with producers

@return success - 0
@return error   - error string

=head2 produce_virt_precondition

Find all producers in a virt precondition, call them and substitute the
producer preconditions with the received produced preconditions. It
returns the updated virt precondition.

@param hash ref - config
@param hash ref - precondition as hash

@return success - hash ref containing updated precondition
@return error   - error string

=head2 parse_precondition

Parse a given precondition and update the config accordingly.

@param hash ref                   - old config
@param precondition result object - precondition

@return success - hash ref containing updated config
@return error   - error string

=head2 get_install_config

Add installation configuration part to a given config hash.

@param hash reference - config to change

@return success - config hash
@return error   - error string

=head2 get_common_config

Create configuration to be used for installation on a given host.

@return success - config hash reference
@return error   - error string

=head2 get_test_config

Returns a an array of configs for all PRCs of a given test. All information
are taken from the MCP::Info attribute of the object so its only save to call
this function after create_config which configures this attribute.

@return success - config array (array ref)
@return error   - error string

=head2 create_config

Create a configuration for the current status of the test machine. All config
information are taken from the database based upon the given testrun id.

@return success - config (hash reference)
@return error   - error string

=head2 write_config

Write the config created before into appropriate YAML file.

@param string - config (hash reference)
@param string - output file name, in absolut form or relative to configured localdata_path

@return success - 0
@return error   - error string

=head1 AUTHOR

AMD OSRC Tapper Team, C<< <tapper at amd64.org> >>

=head1 BUGS

None.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

 perldoc Tapper

=head1 ACKNOWLEDGEMENTS

=head1 COPYRIGHT & LICENSE

Copyright 2008-2011 AMD OSRC Tapper Team, all rights reserved.

This program is released under the following license: freebsd

=head1 AUTHORS

=over 4

=item *

AMD OSRC Tapper Team <tapper@amd64.org>

=item *

Tapper Team <tapper-ops@amazon.com>

=back

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2024 by Advanced Micro Devices, Inc.

This is free software, licensed under:

  The (two-clause) FreeBSD License

=cut
