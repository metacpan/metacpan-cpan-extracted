###########################################
package Sys::Ramdisk::OSX;
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

      # hdiutil attach -nomount ram://1165430
      # diskutil erasevolume HFS+ "ramdisk" `...`

     for (qw(dir size)) {
         if(! defined $self->{ $_ }) {
             LOGWARN "Mandatory parameter $_ not set";
             return undef;
         }
     }

     for (qw(hdiutil diskutil)) {
         $self->{$_}  = bin_find($_) unless $self->{$_};
         if(!defined $self->{$_}) {
             LOGWARN "No $_ command found in PATH";
             return undef;
         }
     }

     my $ramsize = $self->size_normalize( $self->{size} );
     $ramsize /= 512;
     $ramsize = int( $ramsize );

     my @cmd = ($self->{hdiutil}, "attach", "-nomount",
                "ram://$ramsize");

     INFO "Requesting ramdisk: @cmd";
     my($stdout, $stderr, $rc) = tap @cmd;
 
    if($rc) {
        LOGWARN "Requesting ramdisk command '@cmd' failed: $stderr";
        return;
    }
 
    $self->{disk_dev} = $stdout;
    $self->{disk_dev} =~ s/\s.*//;
    chomp $self->{disk_dev};

    $self->{volume} = "ramdisk-$$";

    @cmd = ($self->{diskutil}, "erasevolume", "HFS+", $self->{volume},
            $self->{disk_dev});

    $self->dir( "/Volumes/$self->{volume}" );

    INFO "Mounting ramdisk: @cmd";
    ($stdout, $stderr, $rc) = tap @cmd;
 
    if($rc) {
        LOGWARN "Mounting ramdisk command '@cmd' failed: $stderr";
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

    my @cmd = ($self->{hdiutil}, "detach", $self->{disk_dev});

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

Sys::Ramdisk::OSX - Mount and unmount RAM disks on OSX

=head1 SYNOPSIS

    # Use base class Sys::Ramdisk instead

=head1 DESCRIPTION

Sys::Ramdisk::OSX mounts and unmounts RAM disks on OSX.

=head1 LEGALESE

Copyright 2010 by Mike Schilli, all rights reserved.
This program is free software, you can redistribute it and/or
modify it under the same terms as Perl itself.

=head1 AUTHOR

2010, Mike Schilli <cpan@perlmeister.com>
