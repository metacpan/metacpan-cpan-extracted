use strict;
use warnings;

use Test::More;
BEGIN {
   unless ($ENV{DISPLAY}) {
      plan skip_all => "Need a DISPLAY to run these tests";
  }
  plan tests => 3;#'no_plan';
}

package Foo;
use Test::More;

use Gtk2;
use POE qw(Loop::Glib);
use POE::Session::GladeXML2;


sub on_delete {
   ok('and we got our fake on_delete. bye');
   exit 0;
}

sub on_button1_clicked {
   if (not defined $_[ARG1]) {
      ok('got our fake click');
   }
}

sub package_start {
	ok('in _start so we loaded');
	$_[KERNEL]->delay_set(on_button1_clicked => .1);
	$_[KERNEL]->delay_set(on_delete => .2);
}

sub new {
   my ($class) = @_;

   my $self = {};
   bless $self, $class;
   my $s = POE::Session::GladeXML2->create (
	       glade_object => $self,
	       glade_file => 'samples/sample.glade',
	       glade_mainwin => 'window2',
	       #inline_states => { _start => \&package_start },
	       #package_states => [ $class => {_start => "package_start" }],
	       object_states => [ $self => {
		     _start => "package_start",
		  }],
	    );
   return $self;
}

package main;

Gtk2->init;
my $foo = Foo->new;
POE::Kernel->run;
