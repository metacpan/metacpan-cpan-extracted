#!/usr/bin/perl

#
# This is a simple (mostly) qwizard script that adds up a series of
# user entered numbers.  It's primary purpose is to demonstrate how
# the -remap flag works for the add_todos function.
#

use QWizard;
%primaries = 
  (

   'init_display' => {
		 title => 'Progress Bar Demonstration',
		 questions => [{ type => 'text', 
				 check_value => \&qw_integer,
				 name => 'numsteps',
				 text => 'Enter the number of progress steps:',
				 help_desc => '(1 second between each step)',
			       }],
		 actions => [sub { 
				 my ($qw) = @_;
				 my $steps = qwparam('numsteps');
				 for (my $i = 0; $i < $steps ; $i++) {
				     print STDERR "sleeping $i/$steps\n";
				     sleep(1);
				     $qw->set_progress(($i+1)/$steps);
				 }
			     }]
		},
  );

my $qw = new QWizard(primaries => \%primaries,
		     title => 'Progress Bar Demonstrator',
		     no_confirm => 1);

# $QWizard::qwdebug = 1;

$qw->magic('init_display');
