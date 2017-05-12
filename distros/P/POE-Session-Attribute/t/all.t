use Test::More tests => 18 ;

package	PSATest ;

use	strict ;
use	warnings ;
use	base qw(POE::Session::Attribute) ;
use	POE ;

sub	new {
    	my	$class = shift ;
	main::ok($class, "->new()") ;
	return bless {cnt => shift}, $class ;
}

sub	start : Package(_start) {
    	my	($class, $poe) = @_[OBJECT, KERNEL] ;
    	main::ok(!ref($class) && $class->isa(__PACKAGE__), "_start : Package") ;
	$poe->delay('tick', 1) ;
}

sub	tick : Object {
    	my	($self, $poe) = @_[OBJECT, KERNEL] ;
	main::ok(ref($self) && $self->isa(__PACKAGE__), "tick : Object") ;
	$poe->delay_set('tick', 1) if $self->{cnt} -- ;
}

sub	_stop : Inline { main::ok(1, "_stop : Inline") }

sub	DESTROY {
	main::is(shift->{cnt}, -1, "DESTROY()") ;
	main::inc_destroy_cnt() ;
}

package	PSATest::Subclass ;
use base qw(PSATest) ;
use POE ;

sub	t_ick : Object(tick) {
    	my ($self, @rest) = @_[OBJECT .. $#_] ;
	main::ok(1, 'overriden tick') ;
	$self->SUPER::tick(@rest) ;
}

package main ;

use	POE qw(Kernel) ;

my	$cnt = 0 ;

sub	inc_destroy_cnt { $cnt ++ }

my	($sid, $o) = PSATest->spawn(3) ;
PSATest::Subclass->spawn(1) ;

POE::Kernel->run() ;

undef $sid ;
is($cnt, 1, "1st destroyed") ;
undef $o ;
is($cnt, 2, "2nd destroyed") ;

