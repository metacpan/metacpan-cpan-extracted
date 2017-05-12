package Tapper::Installer::Precondition::PRC;
our $AUTHORITY = 'cpan:TAPPER';
$Tapper::Installer::Precondition::PRC::VERSION = '5.0.0';
use strict;
use warnings;

use File::Basename;
use Hash::Merge::Simple 'merge';
use File::ShareDir      'module_file';
use Moose;
use YAML;
extends 'Tapper::Installer::Precondition';




sub create_common_config
{
        my ($self, $config) = @_;
        $config->{report_server}   = $self->{cfg}->{report_server};
        $config->{report_port}     = $self->{cfg}->{report_port};
        $config->{report_api_port} = $self->{cfg}->{report_api_port};
        $config->{hostname}        = $self->{cfg}->{hostname};  # allows guest systems to know their host system name
        $config->{test_run}        = $self->{cfg}->{test_run};
        $config->{mcp_port}        = $self->{cfg}->{mcp_port} if $self->{cfg}->{mcp_port};
        $config->{mcp_server}      = $self->{cfg}->{mcp_server};
        $config->{sync_port}       = $self->{cfg}->{sync_port} if $self->{cfg}->{sync_port};
        $config->{prc_nfs_server}  = $self->{cfg}->{prc_nfs_server} if $self->{cfg}->{prc_nfs_server}; # prc_nfs_path is set by merging paths above
        $config->{scenario_id}     = $self->{cfg}->{scenario_id} if $self->{cfg}->{scenario_id};
        $config->{paths}           = $self->{cfg}->{paths};
        $config->{files}           = $self->{cfg}->{files} if $self->{cfg}->{files} ;
        $config->{testplan}        = $self->{cfg}->{testplan} if $self->{cfg}->{testplan};
        $config->{log_to_file}     = $self->{cfg}->{log_to_file};


        return $config;
}


sub create_unix_config
{
        my ($self, $prc) = @_;

        my $config = $self->create_common_config($prc->{config});
        $config    = merge($config, {times=>$self->{cfg}->{times}});
        my @timeouts;

        if ($prc->{config}->{guest_count})
        {
                $config->{guest_count} = $prc->{config}->{guest_count};
                $config->{timeouts}    = $prc->{config}->{timeouts};
        }
        else
        {
                $config->{mcp_server}      = $self->{cfg}->{mcp_server};
        }

        return $config;
}


sub write_unix_config
{
        my ($self, $prc) = @_;
        my $basedir = $self->cfg->{paths}{base_dir};
        my $config = $self->create_unix_config($prc);

        $self->makedir("$basedir/etc") if not -d "$basedir/etc";
        open my $file, '>',"$basedir/etc/tapper" or return "Can not open /etc/tapper in $basedir:$!";
        print $file YAML::Dump($config);
        close $file;
        return 0;
}



sub install_startscript
{
        my ($self, $distro) = @_;
        my $basedir = $self->cfg->{paths}{base_dir};
        my ($error, $retval);
        if (not -d "$basedir/etc/init.d" ) {
                mkdir("$basedir/etc/init.d") or return "Can't create /etc/init.d/ in $basedir";
        }
        ($error, $retval) = $self->log_and_exec("cp",module_file('Tapper::Installer', "startfiles/$distro/etc/init.d/tapper"),"$basedir/etc/init.d/tapper");
        return $retval if $error;
        if ($distro!~/tapper/) {

                pipe (my $read, my $write);
                return ("Can't open pipe:$!") if not (defined $read and defined $write);

                # fork for the stuff inside chroot
                my $pid     = fork();
                return "fork failed: $!" if not defined $pid;

                # child
                if ($pid == 0) {
                        close $read;
                        chroot $basedir;
                        chdir ("/");

                        my $ret = 0;
                        my ($error, $retval);
                        if ($distro=~m/suse|debian/) {
                                ($error, $retval)=$self->log_and_exec("insserv","/etc/init.d/tapper");
                        } elsif ($distro=~m/(redhat)|(fedora)/) {
                                ($error, $retval)=$self->log_and_exec("chkconfig","--add","tapper");
                        } elsif ($distro=~m/(ubuntu)/) {
                                ($error, $retval)=$self->log_and_exec("update-rc.d","-f", "tapper", "defaults");
                        } elsif ($distro=~/gentoo/) {
                                ($error, $retval)=$self->log_and_exec("rc-update", "add", "tapper_gentoo", "default");
                        } else {
                                ($error, $retval)=(1,"No supported distribution detected.");
                        }
                        print($write "$retval") if $error;
                        close $write;
                        exit $error;
                } else {        # parent
                        close $write;
                        waitpid($pid,0);
                        if ($?) {
                                my $output = <$read>;
                                return($output);
                        }
                }
        }
}


sub create_windows_config
{
        my ($self, $prc) = @_;
        my $basedir = $self->cfg->{paths}{base_dir};

        my $config = $self->create_common_config();
        $config->{guest_number} = $prc->{config}->{guest_number} if $prc->{config}->{guest_number};

        if ($prc->{config}->{guest_count})
        {
                $config->{guest_count} = $prc->{config}->{guest_count};
        }
        if ($prc->{config}->{testprogram_list}) {
                for (my $i=0; $i< int @{$prc->{config}->{testprogram_list}}; $i++) {
                        # string concatenation for hash keys, otherwise perl can't tell whether
                        # $i ot $i_prog is the name of the variable
                        my $list_element = $prc->{config}->{testprogram_list}->[$i];
                        $config->{"test".$i."_prog"}            = $list_element->{program};
                        $config->{"test".$i."_prog"}          ||= $list_element->{test_program};
                        $config->{"test".$i."_runtime_default"} = $list_element->{runtime};
                        $config->{"test".$i."_timeout"}         = $list_element->{timeout};
                        $config->{"test".$i."_timeout"}       ||= $list_element->{timeout_testprogram};
                }
        } elsif ($prc->{config}->{test_program}) {
                $config->{test0_prog}            = $prc->{config}->{test_program};
                $config->{test0_runtime_default} = $prc->{config}->{runtime};
                $config->{test0_timeout}         = $prc->{config}->{timeout_testprogram}
        }
        return $config;

}


sub write_windows_config
{
        my ($self, $prc) = @_;

        my $config = $self->create_windows_config($prc);
        my $basedir = $self->cfg->{paths}{base_dir};
        open my $file, '>', $basedir.'/test.config' or return "Can not open /test.config in $basedir:$!";
        print $file YAML::Dump($config);
        close $file;

        return 0
}




sub install
{
        my ($self, $prc) = @_;

        my $basedir = $self->cfg->{paths}{base_dir};
        my ($error, $retval);
        my $distro = $self->get_distro($basedir);
        $retval    = $self->install_startscript($distro) if $distro and not $prc->{skip_startscript};
        return $retval if $retval;

        $error = $self->write_unix_config($prc);
        return $error if $error;


        $error = $self->write_windows_config($prc);
        return $error if $error;

        if ($prc->{tapper_package}) {
                my $pkg_object=Tapper::Installer::Precondition::Package->new($self->cfg);
                my $package={filename => $prc->{tapper_package}};
                $self->logdie($retval) if $retval = $pkg_object->install($package);
        }

        return 0;
}




sub get_distro
{
        my ($self, $dir) = @_;
        my @files=glob("$dir/etc/*-release");
        for my $file(@files){
                return "suse"    if $file  =~ /suse/i;
                return "redhat"  if $file  =~ /redhat/i;
                return "gentoo"  if $file  =~ /gentoo/i;
                return "tapper" if $file  =~ /tapper/i;
        }
        {
                open my $fh, '<',"$dir/etc/issue" or next;
                local $\='';
                my $issue = <$fh>;
                close $fh;
                my $distro;
                ($distro) = $issue =~ m/(Debian|Ubuntu)/i;
                return lc($distro) if $distro;
        }
        return "";
}


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Tapper::Installer::Precondition::PRC

=head1 SYNOPSIS

 use Tapper::Installer::Precondition::PRC;

=head1 NAME

Tapper::Installer::Precondition::PRC - Install Program Run Control to a given location

=head1 FUNCTIONS

=head2 create_common_config

Create the part of the config that is the same for both Windows and Unix.

@return hash ref

=head2 create_unix_config

Generate a config for PRC running on Unix system. Take special care for
virtualisation environments. In this case, the host system runs a proxy
which collects status messages from all virtualisation guests.

@param hash reference - contains all information about the PRC to install

@return hash ref - config

=head2 write_unix_config

Generate and write config for unix test.

@param hash reference - contains all information about the PRC to install

@return success - 0
@return error   - error string

=head2 install_startscript

Install a startscript for init in test state.

@return success - 0
@return error   - error string

=head2 create_windows_config

Create the config for a windows guest running the special Win-PRC. Win-PRC
expects a flat YAML with some different keys and does not want any waste
options.

@param hash reference - contains all information about the PRC to install

@return hash ref - windows config

=head2 write_windows_config

Generate and write config for windows guest.

@param hash reference - contains all information about the PRC to install

@return success - 0
@return error   - error string

=head2 install

Install the tools used to control running of programs on the test
system. This function is implemented to fullfill the needs of kernel
testing and is likely to change dramatically in the future due to
limited extensibility. Furthermore, it has the name of the PRC hard
coded which isn't a good thing either.

@param hash ref - contains all information about the PRC to install

@return success - 0
@return error   - return value of system or error string

=head2 get_distro

Find out which distribution is installed below the directory structure
given as argument. The guessed distribution is returned as a string.

@param string - path name under which to check for an installed
distribution

@return success - name of the distro
@return error   - empty string

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
