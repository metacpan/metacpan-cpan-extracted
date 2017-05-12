#!/usr/bin/perl
use strict; use warnings;
use POE;

# uncomment this to have debugging
#sub POE::Component::Fuse::DEBUG { 1 }

# load the module!
use POE::Devel::ProcAlike;
POE::Devel::ProcAlike->spawn();

# create our own "fake" session
POE::Session->create(
	'inline_states'	=> {
		'_start'	=> sub {
			$_[KERNEL]->alias_set( 'foo' );
			$_[KERNEL]->yield( 'timer' );
		},
		'timer'		=> sub {
			$_[KERNEL]->delay_set( 'timer' => 60 );
		}
	},
	'heap'		=> {
		'fakedata'	=> 1,
		'oomph'		=> 'haha',
	},
);

# run the kernel!
POE::Kernel->run();
