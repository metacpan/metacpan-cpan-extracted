#!/usr/bin/perl

#
# This is a simple (mostly) qwizard script that adds up a series of
# user entered numbers.  It's primary purpose is to demonstrate how
# the -remap flag works for the add_todos function.
#

use QWizard;
use QWizard::Plugins::History qw(get_history_widgets);

%primaries = 
  (

   'getanum' => {
		 title => 'A number to add in',
		 questions => [{ type => 'text', 
				 check_value => \&qw_integer,
				 name => 'addthis',
				 text => 'Enter a number:'}],
		 actions => [sub { return 'msg: ' .
				     qwparam('addthis')}]
		},

   'topprimary' => {
		    title => 'Adding machine',

		    questions => 
		    [{ type => 'text',
		       name => 'num',
		       check_value => \&qw_integer,
		       default => 2,
		       text => 'How many numbers do you want to add up:'}],

		    post_answers => 
		    [sub {
			 $wiz = $_[0];
			 for (my $i = 0; $i < qwparam('num'); $i++) {
			     #
			     # This repeatedly adds the same primary
			     # to the todo list, but remaps the result
			     # names to begin with the prefix "num$i"
			     #
			     $wiz->add_todos(-remap => "num$i", 'getanum');
			 }
		     }],

		    actions => 
		    [sub { 
			 my $result = 0;
			 for (my $i = 0; $i < qwparam('num'); $i++) {
			     $result += qwparam('num' . $i . 'addthis');
			 }
			 return "msg: add up to: $result";
		     }]
		   },
  );

my $qw = new QWizard(primaries => \%primaries,
		     title => 'Adding up numbers',
		     leftside => [get_history_widgets()],
		     no_confirm => 1);

# $QWizard::qwdebug = 1;

$qw->magic('topprimary');
