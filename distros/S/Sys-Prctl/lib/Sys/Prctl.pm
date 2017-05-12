package Sys::Prctl;
use strict;
use warnings;

our $VERSION = '1.02';

# TODO: FreeBSD support "libc.call('setproctitle', 'hippy\0');"

=head1 NAME

Sys::Prctl - Give access to prctl system call from Perl

=head1 DESCRIPTION

This is simple module that wraps the prctl system call. Currently only the 
PR_SET_NAME and PR_GET_NAME are implemented.

This can be use to change the process name as reported by "ps -A" and be 
killable will killall.   

=head1 SYNOPSIS
  
  use Sys::Prctl(prctl_name);
  
  #
  # Use with functions
  # 

  # Process name is now "My long process name"
  my $oldname = prctl_name();
  prctl_name("My long process name");

  #
  # Use as an object
  #
  
  my $process = new Sys::Prctl();

  # Process name is now "Short name"
  my $oldname = $process->name();
  $process->name('Short name');

  #
  # Real world use
  #

  # instead of "perl helloworld.pl"
  $0 = "helloworld"
  prctl_name("helloworld");

  print "Hello World\n";
  sleep 100;

  # Process can now be killed with "killall helloworld"

=head1 METHODS

=over

=cut

use POSIX qw(uname);
use Config;

use base "Exporter";

our @EXPORT_OK = qw(prctl_name prctl);
our %EXPORT_TAGS = ();

#
# Detect what os we are running and set the correct SYS_* entries
#

# Defined in linux/sched.h
our $TASK_COMM_LEN = 16;

our $SYS_prctl;
our $SYS_PR_SET_NAME = 15;
our $SYS_PR_GET_NAME = 16;

if($^O eq 'linux') {
    my ($sysname, $nodename, $release, $version, $machine) = POSIX::uname();
    
    # if we're running on an x86_64 kernel, but a 32-bit process,
    # we need to use the i386 syscall numbers.
    if ($machine eq "x86_64" && $Config{ptrsize} == 4) {
        $machine = "i386";
    }

    if ($machine =~ /^i[3456]86$/) {
        $SYS_prctl = 172;
    
    } elsif ($machine =~ /^blackfin|cris|frv|h8300|m32r|m68k|microblaze|mn10300|sh|s390|parisc$/) {
        $SYS_prctl = 172;
    
    } elsif ($machine eq "x86_64") {
        $SYS_prctl = 157;
    
    } elsif ($machine eq "sparc64") {
        $SYS_prctl = 147;
   
    } elsif ($machine eq "ppc") {
        $SYS_prctl = 171;

    } elsif ($machine eq "ia64") {
        $SYS_prctl = 1170;

    } elsif ($machine eq "alpha") {
        $SYS_prctl = 348;
    
    } elsif ($machine eq "arm") {
        $SYS_prctl = 0x900000 + 172;
    
    } elsif ($machine eq "avr32") {
        $SYS_prctl = 148;
    
    } elsif ($machine eq "mips") { # 32bit
        $SYS_prctl = 4000 + 192;
    
    } elsif ($machine eq "mips64") { # 64bit
        $SYS_prctl = 5000 + 153;
    
    } elsif ($machine eq "xtensa") {
        $SYS_prctl = 130;

    } else {
        delete @INC{qw<syscall.ph asm/unistd.ph bits/syscall.ph _h2ph_pre.ph 
                    sys/syscall.ph>};
        my $rv = eval { require 'syscall.ph'; 1 } ## no critic 
                or eval { require 'sys/syscall.ph'; 1 }; ## no critic
        $SYS_prctl = eval { &SYS_prctl; } 
            or die "Could not find prctl for this system";
    }
}

=item new()

Creates a new Sys::Prctl object.

=cut

sub new {
    my ($class, %opts) = @_;

    my %self = (
    
    );
    
    return bless \%self, (ref $class || $class);
}

=item name([$string])

Set or get the process name.

=cut

sub name {
    my ($self, $str) = @_;
    return prctl_name($str);
}

=item prctl_name([$string])

Set or get the process name.

$string can only be 15 chars long on Linux.

Returns undef on error. 

=cut

sub prctl_name {
    my ($str) = @_;
    
    if(defined $str) {
        my $rv = prctl($SYS_PR_SET_NAME, $str);  
        if($rv == 0) {
            return 1;
        } else {
            return;
        }

    } else {
        $str = "\x00" x ($TASK_COMM_LEN + 1); # allocate $str
        my $ptr = unpack( 'L', pack( 'P', $str ) );
        my $rv = prctl($SYS_PR_GET_NAME, $ptr);
        if($rv == 0) {
            return substr($str, 0, index($str, "\x00"));
        } else {
            return;
        }
    }
}

=item prctl($option, $arg2, $arg3, $arg4, $arg5)

Direct wrapper for prctl call

=cut

sub prctl {
    my ($option, $arg2, $arg3, $arg4, $arg5) = @_;
    syscall($SYS_prctl, $option,
        ($arg2 or 0), ($arg3 or 0), ($arg4 or 0), ($arg5 or 0));
}

=back

=head1 NOTES

Currently only 32bit Linux has been tested. So test reports and patches are 
wellcome. 

=head1 AUTHOR

Troels Liebe Bentsen <tlb@rapanden.dk> 

=head1 COPYRIGHT

Copyright(C) 2005-2007 Troels Liebe Bentsen

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

1;
