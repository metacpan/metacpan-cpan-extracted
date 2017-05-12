#!/usr/bin/perl -w
# $Id: 02_file.t,v 1.4 2000/11/26 03:27:11 jgoff Exp $

use strict;

sub POE::Kernel::ASSERT_DEFAULT () { 1 };
use POE;
use POE::Component::UserBase;

sub DEBUG () { 0 };

$| = 1;

#------------------------------------------------------------------------------

my %users =
    ( jgoff   => '',
      bgoff   => '',
      troc    => '',
      czjones => '',
      jpgoff  => 'bl1ng', # Not a real password.
      bpgoff  => 'bwong', # Not a real password.
    );

my $cur_test     = 1;
my $max_test     = keys %users;
my @test_results = map { "not ok $_" } (1..$max_test);

print "1..$max_test\n";

#------------------------------------------------------------------------------

sub file_log_on {
  my $heap = $_[HEAP];
  for(keys %users) {
    $_[KERNEL]->post
	( file_user_base => log_on => user_name => $_,
  		                      password  => $users{$_},
                                      persist   => $heap,
		                      response  => 'validate',
        );
  }
}

sub file_log_off {
  for(keys %users) {
    $_[KERNEL]->post( file_user_base => log_off => user_name => $_ );
  }
}

sub file_validate {
  if(exists $users{$_[ARG1][1]}) {
    $test_results[$cur_test-1] = "ok $cur_test" if $_[ARG1][0];
  }
  $cur_test++;
     
  $_[HEAP]->{_persist}='hi';
}

#------------------------------------------------------------------------------

POE::Component::UserBase->spawn
  ( Alias    => 'file_user_base',
    Protocol => 'file',

    File     => 't/files/plain',
  );

#------------------------------------------------------------------------------

POE::Session->create
  ( inline_states => { _start   => \&file_log_on,
                       _stop    => \&file_log_off,
                       validate => \&file_validate,
                     }
  );

# Run it all until done.
$poe_kernel->run();

print "$_\n" for @test_results; # Figure out whether the tests worked.

exit;




