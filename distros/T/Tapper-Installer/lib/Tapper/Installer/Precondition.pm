package Tapper::Installer::Precondition;
our $AUTHORITY = 'cpan:TAPPER';
$Tapper::Installer::Precondition::VERSION = '5.0.1';
use strict;
use warnings;
use 5.010;

use Hash::Merge::Simple 'merge';
use File::Type;
use File::Basename;
use Moose;
use Socket;
use Sys::Hostname;
use YAML;
use File::Temp qw/tempdir/;

extends 'Tapper::Installer';




sub get_file_type
{
        my ($self, $file) = @_;
        my @file_split=split(/\./,$file);
        my $type=$file_split[-1];
        if ($type eq "iso") {
                return (0,"iso");
        } elsif ($type eq "gz" or $type eq "tgz") {
                return (0,"gzip");
        } elsif ($type eq "tar") {
                return (0,"tar");
        } elsif ($type eq "bz" or $type eq "bz2") {
                return (0,"bz2");
        } elsif ($type eq "rpm") {
                return(0,"rpm");
        } elsif ($type eq "deb") {
                return(0,"deb");
        }

        if (not -e $file) {
                return (0,"$file does not exist. Can't check file type");
        }
        my $ft = File::Type->new();
        $type = $ft->mime_type("$file");
        if ($type eq "application/octet-stream") {
                my ($error, $output)=$self->log_and_exec("file $file");
                return (0, "Getting file type of $file failed: $output") if $error;
                return (0,"iso") if $output =~m/ISO 9660/i;
                return (0,"rpm") if $output =~m/$file: RPM/i;
                return (0,"deb") if $output =~m/$file: Debian/i;
        } elsif ($type eq "application/x-dpkg") {
                return (0,"deb");
        } elsif ($type eq "application/x-gzip") {
                return (0,"gzip");
        } elsif ($type eq "application/x-gtar") {
                return (0,"tar");
        } elsif ($type eq "application/x-bzip2") {
                return (0,"bz2");
        } else {
                return(1, "$file is of unrecognised file type \"$type\"");
        }
}





sub gethostname
{
        my ($self) = @_;
        my $hostname = Sys::Hostname::hostname();
        if ($hostname   =~ m/^\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3}$/) {
                ($hostname) = gethostbyaddr(inet_aton($hostname), AF_INET) or ( print("Can't get hostname: $!") and exit 1);
                $hostname   =~ s/^(\w+?)\..+$/$1/;
                system("hostname", "$hostname");
        }
        return $hostname;
}


sub cleanup
{
        my ($self) = @_;
        foreach my $order (@{$self->cfg->{cleanup} || []}) {
                $order->{call}->(@{$order->{options} || []});
        }
        return 0;
}



sub handle_source_url
{
        my ($self, $precondition) = @_;

        if ( $precondition->{source_url} =~ m{^nfs://(.+/)([^/]+)(/?)$} ) {
                my $nfs_dir = tempdir (CLEANUP => 1); # allow to have multiple nfs mount
                $self->log_and_exec("mount","-t nfs","$1", $nfs_dir);
                $precondition->{name} = $precondition->{filename} = "$nfs_dir/$2";
                push @{$self->cfg->{cleanup}}, {call => sub {$self->log_and_exec(@_)},
                                                options => ['umount',$nfs_dir]};
        }
        return $precondition;
}



sub precondition_install
{
        my ($self, $precondition) = @_;

        $precondition = $self->handle_source_url($precondition) if $precondition->{source_url};

        my $retval;
        my ($error, $loop);
        $self->makedir($self->cfg->{paths}{guest_mount_dir}) if not -d $self->cfg->{paths}{guest_mount_dir};

        my $image;
        my $partition = $precondition->{mountpartition};
        my $new_base_dir = $self->cfg->{paths}{base_dir};

        if ($precondition->{mountfile}) {
                $image        = $self->cfg->{paths}{base_dir}.$precondition->{mountfile};
                $new_base_dir = $self->cfg->{paths}{guest_mount_dir};
                if ( $precondition->{mountpartition} ) {
                        # make sure loop device is free
                        # don't use losetup -f, until it is available on installer NFS root
                        $self->log_and_exec("losetup -d /dev/loop0"); # ignore error since most of the time device won't be already bound
                        return $retval if $retval = $self->log_and_exec("losetup /dev/loop0 $image");
                        return $retval if $retval = $self->log_and_exec("kpartx -a /dev/loop0");
                        return $retval if $retval = $self->log_and_exec("mount /dev/mapper/loop0$partition ".$new_base_dir);
                } else {
                        return $retval if $retval = $self->log_and_exec("mount -o loop $image ".$new_base_dir);
                }
        }
        elsif ($precondition->{mountpartition}) {
                $new_base_dir = $self->cfg->{paths}{guest_mount_dir};
                return $retval if $retval = $self->log_and_exec("mount $partition ".$new_base_dir);
        }
        elsif ($precondition->{mountdir}) {
                        $new_base_dir .= $precondition->{mountdir};
        }

        # call
        my $old_basedir = $self->cfg->{paths}{base_dir};
        $self->cfg->{paths}{base_dir} = $new_base_dir;
        return $retval if $retval=$self->install($precondition);


        if ($precondition->{mountfile}) {
                if ( $precondition->{mountpartition} ) {
                        return $retval if $retval = $self->log_and_exec("umount /dev/mapper/loop0$partition");
                        return $retval if $retval = $self->log_and_exec("kpartx -d /dev/loop0");
                        if ($retval = $self->log_and_exec("losetup -d /dev/loop0")) {
                                sleep (2);
                                return $retval if $retval = $self->log_and_exec("kpartx -d /dev/loop0");
                                return $retval if $retval = $self->log_and_exec("losetup -d /dev/loop0");
                        }
                } else {
                        $retval = $self->log_and_exec("umount $new_base_dir");
                        $self->log->error("Can not unmount $new_base_dir: $retval") if $retval;

                        # seems like mount -o loop uses a loop device that is not freed at umount
                        $self->log_and_exec("kpartx -d /dev/loop0");
                        $self->log_and_exec("losetup -d /dev/loop0");
                }
        }
        elsif ($precondition->{mountpartition}) {
                        $retval = $self->log_and_exec("umount $new_base_dir");
                        $self->log->error("Can not unmount $new_base_dir: $retval") if $retval;
        }
        $self->cleanup();
        $self->cfg->{paths}{base_dir} = $old_basedir;
        return 0;

}



sub file_save
{
        my ($self, $output, $filename) = @_;
        my $testrun_id = $self->cfg->{test_run};
        my $destdir = $self->cfg->{paths}{output_dir}."/$testrun_id/install/";
        my $destfile = $destdir."/$filename";
        if (not -d $destdir) {
                system("mkdir","-p",$destdir) == 0 or return ("Can't create $destdir:$!");
        }
        open(my $FH,">",$destfile)
          or return ("Can't open $destfile:$!");
        print $FH $output;
        close $FH;
}



1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Tapper::Installer::Precondition

=head1 SYNOPSIS

 use Tapper::Installer::Precondition;

=head1 NAME

Tapper::Installer::Precondition - Base class with common functions
for Tapper::Installer::Precondition modules

=head1 FUNCTIONS

=head2 get_file_type

Return the file type of a given file. "rpm, "deb", "tar", "gzip", "bz2" and
"iso" 9660 cd images are recognised at the moment. If file does not exists at
the given file name, only suffix analysis will be available. To enforce any of
the above mentioned types, just set the suffix of the file accordingly.

@param string - file name

@returnlist success - (0, rpm|deb|iso|tar|gzip|bzip2)
@returnlist error   - (1, error string)

=head2 gethostname

This function returns the host name of the machine. When NFS root is
used together with DHCP the hostname set in the kernel usually equals
the IP address received from DHCP as a string. In this case the kernel
hostname is set to the DNS hostname associated to this IP address.

@return hostname of the machine as set in the kernel

=head2 cleanup

Clean up all remaining preparations (given in config).

@return success - 0
@return error   - error string

=head2 handle_source_url

A preconditions source may need some preparation, e.g. if it's located
on an NFS share we need to mount this share. This function handles these
preparations.

@param hash ref - precondition

@return success - hash ref with updated precondition
@return error   - error string

=head2 precondition_install

Install a precondition with preparations up front. This could be
mounting an NFS share or installing inside a virtualisation guest or
even no preparation at all.

A guest can be given as image, partition or directory. This function
makes the necessary preparations, calls the right precondition install
function and cleans up afterwards. An image can be given as file name
and partition or file name only. The later is supposed to be an image
file containing just one partition.

@param hash ref - precondition

@return success - 0
@return error   - error string

=head2 file_save

Save output as file for MCP to find it and upload it to reports receiver.

@param string - output to be written to file
@param string - basename of the file to write output to

@return success - 0
@return errorr  - error string

=head1 AUTHORS

=over 4

=item *

AMD OSRC Tapper Team <tapper@amd64.org>

=item *

Tapper Team <tapper-ops@amazon.com>

=back

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2022 by Advanced Micro Devices, Inc.

This is free software, licensed under:

  The (two-clause) FreeBSD License

=cut
