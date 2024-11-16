package Tapper::Installer::Precondition::Kernelbuild;
our $AUTHORITY = 'cpan:TAPPER';
$Tapper::Installer::Precondition::Kernelbuild::VERSION = '5.0.2';

use Moose;
use IO::Handle; # needed to set pipe nonblocking
extends 'Tapper::Installer::Precondition';

use strict;
use warnings;



sub fix_git_url
{
        my ($self, $git_url) = @_;
        $self->log->info("Git URL before rewrite: $git_url");
        $git_url =~ s|^git://osrc((\.osrc)?\.amd\.com)?/|git://wotan.amd.com/|;
        $self->log->info("Git URL after  rewrite: $git_url");
        return $git_url;
}


sub git_get
{
        my ($self, $git_url, $git_rev)=@_;

        # git may generate more output than log_and_exec can handle, thus keep the system()
        chdir $self->cfg->{paths}{base_dir};
        $git_url = $self->fix_git_url($git_url);
        system("git","clone","-q",$git_url,"linux") == 0
          or return("unable to clone git repository $git_url");
        chdir ("linux");
        system("git","checkout",$git_rev) == 0
          or return("unable to check out $git_rev from git repository $git_url");
        return(0);
}


sub get_config
{
        my ($self, $config_file) = @_;
        $config_file ||= $self->cfg->{paths}{config_path}."/kernelconfigs/config_x86_64";
        $self->log->debug("Getting config $config_file");

        return "Can not get config $config_file because the file does not exist"
          if not -e $config_file;

        system("cp $config_file .config") == 0
          or return "Can not get config $config_file";
        return 0;
}


sub make_kernel
{
        my ($self) = @_;
        system("make","clean") == 0
          or return("Making mrproper failed: $!");

        system('yes ""|make oldconfig') == 0
          or return("Making oldconfig failed: $!");

        system('make','-j8') == 0
          or return("Build the kernel failed: $!");

        system('make','install') == 0
          or return("Installing the kernel failed: $!");

        system('make','modules_install') == 0
          or return("Installing the kernel failed: $!");

        return 0;
}


sub younger { stat($a)->mtime() <=> stat($b)->mtime() }


sub make_initrd
{
        my ($self) = @_;
        my ($error, $kernelversion) = $self->log_and_exec("make","kernelversion");
        my $kernel_file = "vmlinuz-$kernelversion";

        # double block, the outermost belongs to if, the innermost can be left with last;
        # great stuff, isn't it?
        if (not -e "/boot/$kernel_file") {{
                if (-e "/boot/vmlinuz-${kernelversion}+"){
                        $kernelversion .='+';
                        $kernel_file = "vmlinuz-$kernelversion";
                        last;
                }
                if (-e "/boot/bzImage") {
                        $kernel_file = "bzImage";
                        last;
                }
                if (-e "/boot/bzImage-$kernelversion") {
                        $kernel_file = "bzImage-$kernelversion";
                        last;
                }
                if (-e "/boot/bzImage-$kernelversion+") {
                        $kernel_file = "bzImage-$kernelversion";
                        last;
                }

                my @files = sort younger </boot/vmlinuz-*>;
                if (@files) {
                        $kernel_file   = $files[0];
                        $kernelversion = $1;
                        last;
                }
                my $filename;
                $filename = "/tmp/bootdir-content";
                system("ls -l /boot/ > $filename");
                return "kernel install failed, can not find new kernel";
        }}

        system("depmod $kernelversion") == 0
          or return("Can not create initrd file, see log file");

        my $modules = "ixgbe forcedeth r8169 libata sata-sil scsi-mod atiixp ide-disk";
        $modules   .= " ide-core 3c59x tg3 mii amd8111e e1000e bnx2 bnx2x ixgb";
        my $mkinitrd_command = "mkinitrd -k /boot/$kernel_file -i /boot/initrd-$kernelversion ";
        $mkinitrd_command   .= qq(-m "$modules");

        $self->log->debug($mkinitrd_command);
        system($mkinitrd_command) == 0
          or return("Can not create initrd file, see log file");

        # prepare_boot called at the end of the install process will generate
        # a grub entry for vmlinuz/initrd with no version string attached
        $error = $self->log_and_exec("ln -sf","/boot/$kernel_file", "/boot/vmlinuz");
        return $error if $error;
        $error = $self->log_and_exec("ln -sf","/boot/initrd-$kernelversion", "/boot/initrd");
        return $error if $error;

        return 0;
}




sub install
{
        my ($self, $build) = @_;
        my $git_url     = $build->{git_url} or return 'No git url given';
        my $git_rev     = $build->{git_changeset} || 'HEAD';
        my $config_file = $build->{configfile_path};

        $self->log->debug("Installing kernel from $git_url $git_rev");

        my $git_path   = qx(which git);
        chomp $git_path;
        return "Can not find git. Git_path is '$git_path'" if not -e $git_path;

        pipe (my $read, my $write);
        return ("Can't open pipe:$!") if not (defined $read and defined $write);


        # we need to fork for chroot
        my $pid = fork();
        return "fork failed: $!" if not defined $pid;

        # hello child
        if ($pid == 0) {
                close $read;
                my ($error, $output);

                # TODO: handle error
                ($error, $output) = $self->log_and_exec("mount -o bind /dev/ ".$self->cfg->{paths}{base_dir}."/dev");
                ($error, $output) = $self->log_and_exec("mount -t sysfs sys ".$self->cfg->{paths}{base_dir}."/sys");
                ($error, $output) = $self->log_and_exec("mount -t proc proc ".$self->cfg->{paths}{base_dir}."/proc");

                my $filename = $git_url.$git_rev;
                $filename =~ s/[^A-Za-z_-]+/_/g;

                my $testrun_id  = $self->cfg->{test_run};
                my $output_dir  = $self->cfg->{paths}{output_dir}."/$testrun_id/install/";
                $self->makedir($output_dir);


                my $output_file = $output_dir."/$filename";
                # dup output to file before git_get and chroot but inside child
                # so we don't need to care how to get rid of it at the end
                open (STDOUT, ">>", "$output_file.stdout") or print($write "Can't open output file $output_file.stdout: $!\n"),exit 1;
                open (STDERR, ">>", "$output_file.stderr") or print($write "Can't open output file $output_file.stderr: $!\n"),exit 1;

                $error = $self->git_get($git_url, $git_rev);
                if ($error) {
                        print(write $error,"\n");
                        exit -1;
                }

                $error = $self->get_config($config_file);
                if ($error) {
                        print(write $error,"\n");
                        exit -1;
                }


                $ENV{TAPPER_TESTRUN}         = $self->cfg->{test_run};
                $ENV{TAPPER_SERVER}          = $self->cfg->{mcp_host};
                $ENV{TAPPER_REPORT_SERVER}   = $self->cfg->{report_server};
                $ENV{TAPPER_REPORT_API_PORT} = $self->cfg->{report_api_port};
                $ENV{TAPPER_REPORT_PORT}     = $self->cfg->{report_port};
                $ENV{TAPPER_HOSTNAME}        = $self->cfg->{hostname};
                $ENV{TAPPER_OUTPUT_PATH}     = $output_dir;


                # chroot to execute script inside the future root file system
                chroot $self->cfg->{paths}{base_dir};
                chdir('linux');

                $error = $self->make_kernel();
                if ($error) {
                        print( $write $error, "\n");
                        exit -1;
                }

                $error = $self->make_initrd();
                if ($error) {
                        print( $write $error, "\n");
                        exit -1;
                }

                close $write;
                exit 0;
        } else {
                close $write;
                my $select = IO::Select->new( $read );
                my ($error, $output);
        MSG_FROM_CHILD:
                while (my @ready = $select->can_read()){
                        my $tmpout = <$read>;   # only $read can be in @ready, since no other FH is in $select
                        last MSG_FROM_CHILD if not $tmpout;
                        $output.=$tmpout;
                }
                # save logfile from within chroot
                if (-e  $self->cfg->{paths}{base_dir}."/tmp/bootdir-content" ) {
                        log_and_exec("cp",$self->cfg->{paths}{base_dir}."/tmp/bootdir-content",
                                     $self->cfg->{paths}{output_dir}."/".$self->cfg->{test_run}."/install/");
                }

                $self->log_and_exec("umount ".$self->cfg->{paths}{base_dir}."/sys");
                $self->log_and_exec("umount ".$self->cfg->{paths}{base_dir}."/dev");
                $self->log_and_exec("umount ".$self->cfg->{paths}{base_dir}."/proc");
                waitpid($pid,0);
                if ($?) {
                        return("Building kernel from $git_url $git_rev failed: $output");
                }
                return(0);
        }
}
;


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Tapper::Installer::Precondition::Kernelbuild

=head1 SYNOPSIS

 my $kernel_precondition = '
precondition_type: kernelbuild
git_url: git://osrc.amd.com/linux-2.6.git
changeset: HEAD
patchdir: /patches
';

 use Tapper::Installer::Precondition::Kernelbuild;
 $kernel = Tapper::Installer::Precondition::Kernelbuild->new($config);
 $kernel->install(YAML::Load($kernel_precondition));

=head1 NAME

Tapper::Installer::Precondition::Kernelbuild - Build and install a kernel from git

=head1 FUNCTIONS

=head2 fix_git_url

URL rewrite.

@param string git_url

@return string - fixed git url

=head2 git_get

This function encapsulates getting a kernel source directory out of a git
repository. It changes the current directory into the the repository.

@param string - repository URL
@param string - revision in this repository

@return success - 0
@return error   - error string

=head2 get_config

Get the kernel config.

@return success - 0
@return error   - error string

=head2 make_kernel

Build and install a kernel and write all log messages to STDOUT/STDERR.

@return success - 0
@return error   - error string

=head2 younger

Sort function, sort files based on modification time.

=head2 make_initrd

Build and install an initrd and write all log messages to STDOUT/STDERR.

@return success - 0
@return error   - error string

=head2 install

Get the source if needed, prepare the config, build and install the
kernel and initrd file.

@param hash reference - contains all information about the kernel

@return success - 0
@return error   - error string

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
