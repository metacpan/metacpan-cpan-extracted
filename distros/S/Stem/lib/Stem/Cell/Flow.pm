#  File: Stem/Cell/Flow.pm

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

package Stem::Cell ;

use strict ;

my $grammar = <<'GRAMMAR' ;

flow		:	list /\s*\Z/ { $item[1] }

top_list	:	list  

list		:	statement(s) 

statement	:	ifelse	|
			if	|
			while	|
			delay	|
			next	|
			stop	|
			method	|
			<error>

ifelse		:	/(?:if|unless)\b/i method_call block /else/i block {
				{
					op	=> 'IF',
					not	=> lc $item[1] eq 'unless' ?
							1 : 0,
					cond	=> $item[2],
					then	=> $item[3],
					else	=> $item[5]
				}
			}

if		:	/(?:if|unless)\b/i method_call block {
				{
					op	=> 'IF',
					not	=> lc $item[1] eq 'unless' ?
						1 : 0,
					cond	=> $item[2],
					then	=> $item[3],
				}
			}

while		:	label(?) /(?:while|until)\b/i method_call block {
				{
					op	=> 'WHILE',
					label	=> $item[1][0] || '',
					not	=> lc $item[2] eq 'until' ?
						1 : 0,
					cond	=> $item[3],
					block	=> $item[4]
				}
			}

next		:	/(?:next|last)\b/i name(?) ';' {
				{
					op	=> 'NEXT',
					last	=> lc $item[1] eq 'last',
					label	=> $item[2][0] || ''
				}
			}

delay		:	/delay\b/i ( delay_value | delay_method ) ';' {
				{
					op	=> 'DELAY',
					@{$item[2]}
				}
			 }


stop		:	/stop/i ';' {
				{
					op	=> 'STOP',
				}
			}

label		:	name ':' { $item[1] }

delay_value	:	/\d+/ {
				[value	=> $item[1]]
			}

delay_method	:	method_call {
				[method	=> $item[1]]
			}

method		:	method_call ';' { $item[1] }

method_call	:	args_method | plain_method

plain_method	:	name {
				{
					op	=> 'METHOD',
					method	=> $item[1],
				}
			}

args_method	:	name '(' arg(s /,/) ')' {
				{
					op	=> 'METHOD',
					method	=> $item[1],
					args	=> $item[3],
				}
			}

arg		:	/\w+/

name		:	/[^\W\d]\w*/

block		:	'{' list '}' { $item[2] }

GRAMMAR

my $flow_parser ;
my %flows ;

my %flow_ops = (

	WHILE	=> \&flow_while_op,
	IF	=> \&flow_if_op,
	NEXT	=> \&flow_next_op,	
	METHOD	=> \&flow_method_op,
	DELAY	=> \&flow_delay_op,
	STOP	=> \&flow_stop_op,
) ;


$::RD_HINT = 1 ;
$::RD_ERRORS = 1 ;

use Data::Dumper ;

sub cell_flow_init {

	my( $self, $name, $source ) = @_ ;

	my $cell_info = $self->_get_cell_info() ;

	unless( $flow_parser ) {

		require Parse::RecDescent ;

		$flow_parser = Parse::RecDescent->new( $grammar ) or
				die 'bad flow grammar' ;
	}

	my $tree = $flows{$name}{'tree'} ;

	unless( $tree ) {

		$source =~ s/#.+$//mg ;

		$tree = $flow_parser->flow( $source ) ;

#print Dumper $tree ;

		$flows{$name} = {

			'tree'	=> $tree,
			'source' => $source,
		} ;
	}

	$cell_info->{'flow'} = {

			'name'	=> $name,
			'tree'	=> $tree,
			'pc'	=> [ $tree, 0 ],
	} ;

	return ;
}

sub cell_flow_go_in {

	my( $self, $msg ) = @_ ;

	my $cell_info = $self->_get_cell_info() ;

#print $msg->dump( 'GO') if $msg ;

#print "GO\n" ;
	my $flow = $cell_info->{'flow'} ;

#print Dumper $flow ;

	while( 1 ) {

		my ( $pc_ref, $pc_index ) = @{$flow->{'pc'}} ;

#print "IND $pc_index ", Dumper $pc_ref ;

		if ( $pc_index >= @{$pc_ref} ) {

#print "LIST END\n" ;

			my $old_pc = pop( @{$flow->{'stack'}} ) ;

			$old_pc or die "FELL off FLOW STACK" ;

#print "POP\n" ;

			$flow->{'pc'} = $old_pc ;
			next ;
		}

		my $op = $pc_ref->[$pc_index] ;

		my $op_name = $op->{'op'} ;

#print "OP $op_name\n" ;

		my $code = $flow_ops{$op_name} ;

		$code or die "unknown flow op code [$code]" ;

		my $meth_val = $code->( $flow, $op, $self, $msg ) ;

		$msg = undef ;

		next unless $meth_val ;

		return if $meth_val && $meth_val eq 'FLOW_STOP' ;

# check for a message

		if ( ref $meth_val eq 'Stem::Msg' ) {

			$meth_val->reply_type( 'cell_flow_go' ) ;

			$meth_val->dispatch() ;

			return ;
		}

		return ;
	}

	return ;
}

sub flow_stop_op {

	my( $flow ) = @_ ;

	my $pc = $flow->{'pc'} ;

# always go to the next op

	$pc->[1]++ ;
	return 'FLOW_STOP' ;
}

sub flow_method_op {

	my( $flow, $op, $obj, $msg ) = @_ ;

	my $pc = $flow->{'pc'} ;

# always go to the next op

	$pc->[1]++ ;

#print Dumper $pc ;

	return( flow_call_method( $op, $obj, $msg ) ) ;
}

sub flow_while_op {

	my( $flow, $op, $obj ) = @_ ;

	my $pc = $flow->{'pc'} ;

	my $cond_val = flow_cond( $op, $obj ) ;

	unless( $cond_val ) {

#print "WHILE END\n" ;

		$pc->[1]++ ;
		return ;
	}

#print "WHILE LOOP\n" ;

	push( @{$flow->{'stack'}}, $pc ) ;

	$flow->{'pc'} = [ $op->{'block'}, 0 ] ;

	return ;
}

sub flow_if_op {

	my( $flow, $op, $obj ) = @_ ;

	my $cond_val = flow_cond( $op, $obj ) ;

	my $block = $cond_val ? $op->{'then'} : $op->{'else'} ;

	my $pc = $flow->{'pc'} ;

# always go to the next op

	$pc->[1]++ ;

	if ( $block ) {

		push( @{$flow->{'stack'}}, $pc ) ;

		$flow->{'pc'} = [ $block, 0 ] ;
	}

	return ;
}

sub flow_next_op {

	my( $flow, $op, $obj ) = @_ ;

	my $label = $op->{'label'} ;

	while( 1 ) {

		my $pc = pop( @{$flow->{'stack'}} ) ;

		$pc or die "can't find label '$label' in flow stack" ;

#print "PC: ", Dumper $pc ;

		my $prev_op = $pc->[0][$pc->[1]] ;

#print "PREV: ", Dumper $prev_op ;

		next unless $prev_op && $prev_op->{'op'} eq 'WHILE' ;

#print "FOUND WHILE\n" ;

		next unless $prev_op->{'label'} eq $label ;

		$pc->[1]++ if $op->{'last'} ;

#print "LAST PC: ", Dumper $pc ;

		$flow->{'pc'} = $pc ;

		return ;
	}
}


sub flow_delay_op {

	my( $flow, $op, $obj ) = @_ ;

#print Dumper $op ;

	my $pc = $flow->{'pc'} ;
	$pc->[1]++ ;

	my $delay = $op->{'value'} ;

	unless ( defined $delay ) {

		$delay = flow_call_method( $op->{'method'}, $obj ) ;
	}

	$flow->{'timer'} = Stem::Event::Timer->new( 
				'object'	=> $obj,
				'method'	=> 'cell_flow_go_in',
				'delay'		=> $delay, 
				'hard'		=> 1,
				'single'	=> 1,
	) ;

#	print "D $delay EVT $flow->{'timer'}\n" ;

	return 1 ;
}

sub flow_cond {

	my( $op, $obj ) = @_ ;

	my $cond = $op->{'cond'} ;

	return 1 if $cond eq '1' ;

	my $cond_val = flow_call_method( $cond, $obj ) ? 1 : 0 ;

	return( $cond_val ^ $op->{'not'} ) ;
}

sub flow_call_method {

	my( $call, $obj, $msg ) = @_ ;

	my $method = $call->{'method'} ;

	my @args = @{$call->{'args'} || []} ;

	unshift( @args, $msg ) if $msg ;

# flow methods are always called in scalar context

#print "METHOD $method ( @args )\n" ;

	my $val = $obj->$method( @args ) ;

	return $val ;
}


1 ;
