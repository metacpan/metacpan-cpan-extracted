#  File: Stem/Test/Flow.pm

#  This file is part of Stem.
#  Copyright (C) 1999, 2000, 2001 Stem Systems, Inc.

#  Stem is free software; you can redistribute it and/or modify
#  it under the terms of the GNU General Public License as published by
#  the Free Software Foundation; either version 2 of the License, or
#  (at your option) any later version.

#  Stem is distributed in the hope that it will be useful,
#  but WITHOUT ANY WARRANTY; without even the implied warranty of
#  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#  GNU General Public License for more details.

#  You should have received a copy of the GNU General Public License
#  along with Stem; if not, write to the Free Software
#  Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307  USA

#  For a license to use the Stem under conditions other than those
#  described here, to purchase support for this software, or to purchase a
#  commercial warranty contract, please contact Stem Systems at:

#       Stem Systems, Inc.		781-643-7504
#  	79 Everett St.			info@stemsystems.com
#  	Arlington, MA 02474
#  	USA

package Stem::Test::Flow ;

use Test::More tests => 30 ;

use base 'Stem::Cell' ;

my $attr_spec = [

	{
		'name'		=> 'reg_name',
		'help'		=> <<HELP,
This is the name under which this Cell was registered.
HELP
	},

	{
		'class'		=> 'Stem::Cell',
		'name'		=> 'cell_attr',
		'help'		=> <<HELP,
This value is the attributes for the included Stem::Cell which handles
cloning, async I/O and pipes.
HELP
	},
		
] ;

sub new {

	my( $class ) = shift ;

	my $self = Stem::Class::parse_args( $attr_spec, @_ ) ;
	return $self unless ref $self ;

	my $flow_text = <<FLOW ;

		meth1 ;
		meth2( 1, a ) ;
		if if1 {
			meth3 ;
		}

		unless if1 {
			meth_bad ;
		}

		while while1 {
			meth4 ;
		}

		until until1 {

			unless unless1 {

				meth5 ;
			}
			else {

				meth6 ;
			}
		}

		while while2 {
			next ;
		}

		next_ok ;

		LABEL1 :
		while while3 {

			while while4 {

				next LABEL1 ;
			}
		}

		LABEL2 :
		until until2 {

			if if2 {

				last LABEL2 ;
			}
		}

		last_ok ;

		delay_time ;
		delay 1 ;
		delay_done( 1 ) ;

		delay delay_set( 2 ) ;
		delay_done( 2 ) ;

		msg1 ;
		get_msg1 ;


		exit_meth ;
FLOW

	$self->cell_flow_init( 'test', $flow_text ) ;

	$self->cell_flow_go_in() ;

	return $self ;
}

sub meth1 {
	ok(1, 'plain method') ;
	return ;
}

sub meth2 {
	my( $self, $arg1, $arg2 ) = @_ ;
	ok( $arg1 ==1 && $arg2 eq 'a', 'methods with args' ) ;
	return ;
}

sub if1 {
	ok(1, 'if condition') ;
	return 1 ;
}

sub meth3 {
	ok(1, 'method in block' ) ;
	return ;
}

sub meth_bad {
	ok(0, 'then block was called' ) ;
	return ;
}

my $w1 ;

sub while1 {
	ok(1, 'while condition') ;
	return 1 if $w1++ < 2 ;

	return ;
}

sub meth4 {
	ok(1, 'method in while' ) ;
	return ;
}

my $u1 ;
my $u2 ;

sub until1 {
	ok(1, 'until condition') ;
	return $u1 ;
}

sub unless1 {
	ok(1, 'unless condition') ;
	return $u2 ;
}

sub meth5 {
	ok(1, 'method in unless' ) ;

	$u2++ ;
	return ;
}

sub meth6 {
	ok(1, 'method in else' ) ;

	$u1++ ;
}

my $w3 ;

sub while3 {
	ok(1, 'outer while condition') ;
	return 1 if $w3++ < 1 ;

	return ;
}

my $w4 ;

sub while4 {
	ok(1, 'inner while condition') ;
	return 1 if $w4++ < 1 ;

	return ;
}

sub next_ok {

	ok( 1, 'next' ) ;

	return ;
}


my $w2 ;

sub while2 {
	ok(1, 'while condition') ;
	return 1 if $w1++ < 1 ;

	return ;
}

sub until2 {
	
	return ;
}

sub if2 {
	return 1 ;
}

sub last_ok {

	ok( 1, 'last' ) ;

	return ;
}


my $delay_time ;

sub delay_time {

	$delay_time = time ;

	return ;
}

sub delay_done {

	my( $self, $delta ) = @_ ;

	my $time = time ;

	$delta ||= 1 ;

#print "$time $delay_time\n" ;

	ok( $time - $delay_time >= $delta, 'delay done' ) ;

	return ;
}


sub delay_set {

	my( $self, $delay ) = @_ ;

	ok( 1, 'delay set method' ) ;

	return $delay || 1 ;
}

sub msg1 {

	my ( $self ) = @_ ;

	ok(1, 'message method' ) ;

	my $msg = Stem::Msg->new( to => $self->{'reg_name'},
			       from => $self->{'reg_name'},
			       type => 'flow_msg'
	) ;

#print $msg->dump( 'MSG1' ) ;

	return $msg ;

}

sub flow_msg_in {

	my ( $self, $msg ) = @_ ;

#print $msg->dump( 'FLOW' ) ;
	ok(1, 'flow message in' ) ;

	my $reply = $msg->reply() ;

#print $reply->dump( 'reply' ) ;

	$reply->dispatch() ;

	return ;
}

sub get_msg1 {

	my ( $self, $msg ) = @_ ;

	ok(1, 'message received' ) ;

#print $msg->dump( 'GET' ) ;

	return ;
}

sub exit_meth {
	ok(1, 'exit method' ) ;

	exit ;
}

1 ;
