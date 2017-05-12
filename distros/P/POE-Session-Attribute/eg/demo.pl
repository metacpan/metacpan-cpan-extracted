#! /usr/bin/perl -w

use	strict ;
use	lib qw(lib ../lib) ;

package	Foo ;

use	strict ;
use	warnings ;
use	base qw(POE::Session::Attribute) ;

sub	_start : Object {
    	warn "_start (Foo)" ;
}

sub	_stop : Inline {
    	warn "_stop (Foo)" ;
}

package	Bar ;
use	strict ;
use	warnings ;
use	base qw(Foo) ;
use	POE qw(Kernel) ;

sub	_start : Object {
    	my	($self, $poe) = @_[OBJECT, KERNEL] ;
	$poe->delay_set("tick", 1) ;
	$self->SUPER::_start(@_[1 .. $#_]) ;
}

sub	tick : Object {
    	warn "tick (Bar)" ;
}

package	Baaz ;
use	strict ;
use	warnings ;
use	base qw(Bar) ;
use	POE qw(Kernel) ;

sub	tick {
	my	($self, $poe) = @_[OBJECT, KERNEL] ;
	$self->SUPER::tick(@_[1 .. $#_]) ;
	$poe->delay_set("tack", 2) ;
}

sub	tack : Object {
    	warn "tack (Baaz)" ;
}

package	main ;

use	POE qw(Kernel) ;

Baaz->spawn(qw(one two three)) ;
POE::Kernel->run() ;

