#!/usr/bin/perl

use strict;
use warnings;
use Test::NoWarnings;
use Test::More ( tests => 78 );
use Errno qw(EINVAL ENOENT);
use Sys::Ptrace;

my @constants = qw(
  PTRACE_TRACEME PT_TRACE_ME
  PTRACE_PEEKTEXT PT_READ_I
  PTRACE_PEEKDATA PT_READ_D
  PTRACE_PEEKUSER PT_READ_U
  PTRACE_POKETEXT PT_WRITE_I
  PTRACE_POKEDATA PT_WRITE_D
  PTRACE_POKEUSER PT_WRITE_U
  PTRACE_CONT PT_CONTINUE
  PTRACE_KILL PT_KILL
  PTRACE_SINGLESTEP PT_STEP
  PTRACE_GETREGS PT_GETREGS
  PTRACE_SETREGS PT_SETREGS
  PTRACE_GETFPREGS PT_GETFPREGS
  PTRACE_SETFPREGS PT_SETFPREGS
  PTRACE_ATTACH PT_ATTACH
  PTRACE_DETACH PT_DETACH
  PTRACE_GETFPXREGS PT_GETFPXREGS
  PTRACE_SETFPXREGS PT_SETFPXREGS
  PTRACE_SYSCALL PT_SYSCALL );

my %seen_sym_vals = ();

foreach my $sym (@constants) {
    undef $!;
    my $sym_val = eval "Sys::Ptrace::$sym()";
    ok( $!{EINVAL} == 0, "Testing $sym didn't return EINVAL" );
    ok( $!{ENOENT} == 0, "Testing $sym didn't return ENOENT" );
    $seen_sym_vals{$sym_val}++;
}

ok( ( 0 == scalar grep { $_ != 2 } values %seen_sym_vals ), "All symbol enums have two names" );
