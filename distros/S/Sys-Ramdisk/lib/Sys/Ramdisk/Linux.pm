###########################################
package Sys::Ramdisk::Linux;
###########################################
use strict;
use warnings;
use Log::Log4perl qw(:easy);
use Sysadm::Install qw(bin_find tap);

use base qw(Sys::Ramdisk);

###########################################
sub mount {
###########################################
    my($self) = @_;

      # mkdir -p /mnt/myramdisk
      # mount -t tmpfs -o size=20m tmpfs /mnt/myramdisk

     for (qw(dir size)) {
         if(! defined $self->{ $_ }) {
             LOGWARN "Mandatory parameter $_ not set";
             return undef;
         }
     }

     $self->{mount}  = bin_find("mount") unless $self->{mount};
     $self->{umount} = bin_find("umount") unless $self->{umount};

     for (qw(mount umount)) {
         if(!defined $self->{$_}) {
             LOGWARN "No $_ command found in PATH";
             return undef;
         }
     }

     my @cmd = ($self->{mount}, 
                "-t", "tmpfs", 
                "-o", "size=$self->{size}",
                "tmpfs", $self->{dir});

     INFO "Mounting ramdisk: @cmd";
     my($stdout, $stderr, $rc) = tap @cmd;
 
    if($rc) {
        LOGWARN "Mount command '@cmd' failed: $stderr";
        return;
    }
 
    $self->{mounted} = 1;
 
    return 1;
}

###########################################
sub unmount {
###########################################
    my($self) = @_;

    return if !exists $self->{mounted};

    my @cmd = ($self->{umount}, $self->{dir});

    INFO "Unmounting ramdisk: @cmd";

     my($stdout, $stderr, $rc) = tap @cmd;
 
    if($rc) {
        LOGWARN "Mount command '@cmd' failed: $stderr";
        return;
    }
 
    $self->{mounted} = 0;

    return 1;
}

1;

__END__

=head1 NAME

Sys::Ramdisk::Linux - Mount and unmount RAM disks on Linux

=head1 SYNOPSIS

    # Use base class Sys::Ramdisk instead

=head1 DESCRIPTION

Sys::Ramdisk::Linux mounts and unmounts RAM disks on Linux.

=head1 LEGALESE

Copyright 2010 by Mike Schilli, all rights reserved.
This program is free software, you can redistribute it and/or
modify it under the same terms as Perl itself.

=head1 AUTHOR

2010, Mike Schilli <cpan@perlmeister.com>
