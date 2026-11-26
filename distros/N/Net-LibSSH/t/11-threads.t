#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;
use Config;

# Perl clones every live SV, ext magic included, when an ithread is
# created. Without CLONE_SKIP the clone points at the same NLSS_Session
# struct and both copies run svt_free: ssh_disconnect + ssh_free +
# Safefree twice. The thread does not even have to touch the object.
#
# CLONE_SKIP makes perl leave the object out of the clone: the new thread
# gets a plain reference to an undef scalar and only the parent ever
# frees the struct.
#
# The scenario runs in a subprocess so that a regression shows up as a
# failing is() on the exit status instead of taking `prove` down.

plan skip_all => 'perl was built without ithreads' unless $Config{useithreads};

use Net::LibSSH;

for my $class (qw( Net::LibSSH Net::LibSSH::Channel Net::LibSSH::SFTP )) {
  ok( $class->can('CLONE_SKIP'), $class.' defines CLONE_SKIP' );
}

sub run_perl {
  my ( $code ) = @_;
  my @cmd = ( $^X, ( map { '-I'.$_ } @INC ), '-Mthreads', '-MNet::LibSSH', '-e', $code );
  open my $fh, '-|', @cmd or die 'cannot run '.$^X.': '.$!;
  local $/;
  my $out = <$fh>;
  close $fh;
  return ( $out // '', $? );
}

my ( $out, $status ) = run_perl(
  '$|=1; my $s = Net::LibSSH->new; print "created\n";'
  .' threads->create(sub { 1 })->join; print "after join\n";'
  .' undef $s; print "after undef\n"'
);
is( $status, 0, 'creating a thread with a live session exits cleanly' )
  or diag( 'exit status '.( $status >> 8 ).', signal '.( $status & 127 ) );
is( $out, "created\nafter join\nafter undef\n", 'parent runs through to the end' );

( $out, $status ) = run_perl(
  'my $s = Net::LibSSH->new;'
  .' print threads->create(sub { ref($s) . "," . (defined $$s ? "defined" : "undef") })->join, "\n";'
);
is( $status, 0, 'a thread that looks at the session exits cleanly' );
is( $out, "SCALAR,undef\n", "inside the new thread the session is a plain reference to an undef scalar" );

done_testing;
