#!/usr/bin/perl -w
# $Id: 03_dbi.t,v 1.4 2000/11/28 04:55:00 jgoff Exp $

use strict;

sub POE::Kernel::ASSERT_DEFAULT () { 1 };
use POE;
use POE::Component::UserBase;

BEGIN {
  eval 'use DBI;';
  unless (defined $@ and length $@) {
    print "1..0 # skipped: DBI is not installed\n";
    exit 0;
  }
};

sub DEBUG () { 0 };

my $max_test = 1;
print "1..$max_test\n";

my @test_results = map { "not ok $_" } (1..$max_test);

#------------------------------------------------------------------------------

sub dbi_log_on {
  $_[KERNEL]->post( user_base => log_on => user_name => 'jgoff',
                                           persist   => $_[HEAP],
                                           response  => 'validate',
                  );
}

sub dbi_log_off {
  $_[KERNEL]->post( user_base => log_off => user_name => 'jgoff' );
}

sub dbi_validate {
  $test_results[0] = 'ok 1' if $_[ARG1][0];

  $_[HEAP]->{_persist}='hi';
}

#------------------------------------------------------------------------------

my $dbh = DBI->connect('dbi:Pg:dbname=auth_test','jgoff');

POE::Component::UserBase->spawn
    ( Alias      => 'user_base',
      Protocol   => 'dbi',
	
      Connection => $dbh,
      Table      => 'auth',
    );

#------------------------------------------------------------------------------

POE::Session->create
  ( inline_states => { _start   => \&dbi_log_on,
		       _stop    => \&dbi_log_off,
		       validate => \&dbi_validate,
	  	     }
  );

# Run it all until done.
$poe_kernel->run();

$dbh->disconnect();

print "$_\n" for @test_results; # Figure out whether the tests worked.

exit;







