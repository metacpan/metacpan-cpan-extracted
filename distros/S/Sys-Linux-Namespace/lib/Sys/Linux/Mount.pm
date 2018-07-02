package Sys::Linux::Mount;

use strict;
use warnings;
use Carp qw/croak/;

require Exporter;
our @ISA = qw/Exporter/;
require XSLoader;

XSLoader::load();

my @mount_consts = qw/MS_RDONLY MS_NOSUID MS_NODEV MS_NOEXEC MS_SYNCHRONOUS MS_REMOUNT MS_MANDLOCK MS_DIRSYNC MS_NOATIME 
                      MS_NODIRATIME MS_BIND MS_MOVE MS_REC MS_SILENT MS_POSIXACL MS_UNBINDABLE MS_PRIVATE MS_SLAVE MS_SHARED
                      MS_RELATIME MS_KERNMOUNT MS_I_VERSION MS_STRICTATIME MS_LAZYTIME MS_ACTIVE MS_NOUSER MS_MGC_VAL
                      MNT_FORCE MNT_DETACH MNT_EXPIRE UMOUNT_NOFOLLOW/;

use constant {MS_RDONLY => 1,        
             MS_NOSUID => 2,        
             MS_NODEV => 4,         
             MS_NOEXEC => 8,        
             MS_SYNCHRONOUS => 16,      
             MS_REMOUNT => 32,      
             MS_MANDLOCK => 64,     
             MS_DIRSYNC => 128,     
             MS_NOATIME => 1024,        
             MS_NODIRATIME => 2048,     
             MS_BIND => 4096,       
             MS_MOVE => 8192,
             MS_REC => 16384,
             MS_SILENT => 32768,
             MS_POSIXACL => 1 << 16,    
             MS_UNBINDABLE => 1 << 17,  
             MS_PRIVATE => 1 << 18,     
             MS_SLAVE => 1 << 19,       
             MS_SHARED => 1 << 20,      
             MS_RELATIME => 1 << 21,    
             MS_KERNMOUNT => 1 << 22,   
             MS_I_VERSION =>  1 << 23,  
             MS_STRICTATIME => 1 << 24, 
             MS_LAZYTIME => 1 << 25,    
             MS_ACTIVE => 1 << 30,
             MS_NOUSER => 1 << 31,
             MS_MGC_VAL => 0xc0ed0000, #	/* Magic flag number to indicate "new" flags */
# umount flags
             MNT_FORCE => 1,
             MNT_DETACH => 2,
             MNT_EXPIRE => 4,
             UMOUNT_NOFOLLOW => 8,
};
our @EXPORT_OK = (@mount_consts, qw/mount umount/);

our %EXPORT_TAGS = (
  'consts' => \@mount_consts,
  'all' => [@mount_consts, qw/mount umount/],
);

sub mount {
  my ($source, $target, $filesystem, $flags, $options_hr) = @_;

  my $options_str = ""; 
  if ($options_hr) {
    $options_str = join ',', map {"$_=".$options_hr->{$_}} keys %$options_hr;
  }

  my $ret = _mount_sys($source//"", $target//"", $filesystem//"", $flags//MS_MGC_VAL, $options_str);

  if ($ret != 0) {
      croak "mount failed: $ret $!";
  }

  return 1;
}

sub umount {
  my ($target, $flags) = @_;

  croak "No filesystem given to umount()" unless $target;

  my $ret;
  if (defined $flags) {
    $ret = _umount2_sys($target, $flags);
  } else {
    $ret = _umount_sys($target);
  }

  if ($ret != 0) {
    croak "umount failed: $ret $!";
  }

  return 1;
}

1;


__END__
=head1 NAME

Sys::Linux::Mount - Bindings for the linux mount syscall.  

Provides a nice high-ish level wrapper to make mounting filesystems easier.

=head1 SYNOPSIS

    use Sys::Linux::Mount ':all'; # or :consts, or any specific constant or function

    mount("/dev/source", "/target", "ext4", MS_RDONLY|MS_NOEXEC|MS_NODEV, {noacl=>1, ...});
    umount("/target");    

=head1 REQUIREMENTS

This module requires your script to have CAP_SYS_ADMIN, usually by running as C<root>.  Without that every call will likely fail.

=head1 FUNCTIONS

All of these functions closely mirror the calling convetions and options of the respective syscalls, and more details can be found in the manpages for those calls

    man 2 mount
    man 2 umount

=head2 C<mount>

    mount(source, target, [filesystem, [flags, [options]]])

Mount a filesystem, mostly mirrors the setup for the syscall, taking in flags as a bitwise combination of C<MS_*> constants.  
C<MS_MGC_VAL> is the magic value to say you have no flags.

options should be a hashref containing the options to give filesystem specific options, things like C<< {uid => 'nobody', gid => 'nogroup'} >> for mounting CIFS filesystems.
These are typically the things you'd see in C<mount -o uid=nobody,gid=nogroup,...> except for a few like MS_NOATIME or MS_NODEV that aren't filesystem specific.

=head2 C<umount>

    umount(mountpoint, [flags])

Unmount a filesystem.  Possible flag values are MNT_FORCE, MNT_EXPIRE, MNT_DETACH, UMOUNT_NOFOLLOW.

=head1 CONSTANTS

The following constants are available to be exported, 

    MS_RDONLY MS_NOSUID MS_NODEV MS_NOEXEC MS_SYNCHRONOUS MS_REMOUNT MS_MANDLOCK MS_DIRSYNC MS_NOATIME 
    MS_NODIRATIME MS_BIND MS_MOVE MS_REC MS_SILENT MS_POSIXACL MS_UNBINDABLE MS_PRIVATE MS_SLAVE MS_SHARED
    MS_RELATIME MS_KERNMOUNT MS_I_VERSION MS_STRICTATIME MS_LAZYTIME MS_ACTIVE MS_NOUSER MS_MGC_VAL
    MNT_FORCE MNT_DETACH MNT_EXPIRE UMOUNT_NOFOLLOW

For details about what they do, see the man pages for the mount syscall C<man 2 mount>

=head1 AUTHOR

Ryan Voots L<simcop@cpan.org|mailto:SIMCOP@cpan.org>

=cut
