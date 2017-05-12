# Copyright (c) 2003 Ioannis Tambouras <ioannis@earthlink.net> .
# All rights reserved.
 
package String::RexxStack::Named;

use 5.006;
use strict;
use warnings;
use base qw( Exporter String::TieStack );
use Filter::Simple;
use Want  qw(wantref want);
use Data::Dumper;

our $VERSION = '0.3';

our @EXPORT      = qw(  pull Pull Push Pop clear qelem Queue  );

our @extra       = qw(  newstack  printq       printq_s  info
                        qstack    delstack     dumpe     dumpe_s
                        limits    limit_bytes  limit_entries
                        makebuf   dropbuf      desbuf    qbuf
                        total_bytes ) ;

our %EXPORT_TAGS = ( 'extra' =>  [ @extra ],
                     'all'   =>  [ @EXPORT, @extra ],
                   );

our @EXPORT_OK = ( @{ $EXPORT_TAGS{'extra'} } );




FILTER {
            my $tmp;
            my $pat = qr! \[ \s* (makebuf  | dropbuf  | desbuf    | clear |
                                  newstack | delstack | qstack    |
                                  printq   | printq_s | dumpe   
                                 )
                          \s* (\S*) \s* \] !ix;
            s ! $pat \s* (;?)
	      ! $tmp = lc "$1" ; 
                $tmp = "$tmp $2" ; 
                $tmp .= ';'  if $3 ;
                $tmp;
              !exg;
};


my  %DEFAULT = ( Max_SoStacks => 10, Max_Named=> 20 );  # NOT USED 



sub _create_entry  { {  stack      =>  new String::TieStack,
	                max_sos    =>  $DEFAULT{ Max_SoStacks }, 
	                saved      =>  [] ,
 	             } ;
}

my  %s          =   ( SESSION => _create_entry );
my  $max_named  =   $DEFAULT{ max_named } ;                    
my  $num_named  =   1;


sub qstack  {   return 0  unless $s{my $name = shift||'SESSION'} ;
                1 + scalar @{ $s{$name}{saved} } ;
                                                                                }

sub Pull        {  $s{ defined $_[1]  ? shift :'SESSION' }  {stack}->pull(@_)   }
sub pull        {  ($s{ shift || 'SESSION' }{stack} || return undef)  ->pullall }
sub qelem       {  ($s{ shift || 'SESSION' }{stack} || return undef)  ->qelem   }
sub qbuf        {  ($s{ shift || 'SESSION' }{stack} || return undef)  ->qbuf    }
sub clear       {  ($s{ shift || 'SESSION' }{stack} || return undef)  ->CLEAR   }
sub makebuf     {  ($s{ shift || 'SESSION' }{stack} || return undef)  ->makebuf }
sub dropbuf     {  ($s{ shift || 'SESSION' }{stack} || return undef)  ->dropbuf }
sub desbuf      {  ($s{ shift || 'SESSION' }{stack} || return undef)  ->desbuf   }
sub printq      {  $,="\n"; print +($s{ shift||'SESSION'} {stack}|| return undef) ->printq }
sub printq_s    {  $,="\n"; +($s{ shift||'SESSION'} {stack}|| return undef) ->printq }
sub total_bytes {  ($s{ shift || 'SESSION' }{stack} || return undef)  ->total_bytes   }
*queue = \&Queue  ;
*Pop   =  \& Pull ;


sub _allow_stack {
        my $name = shift;
	qstack($name) + 1  <=  $s{$name}{max_sos}  ;
}


sub newstack   {
	my $name = shift|| 'SESSION';
	if ( exists $s{$name}{stack} ) {
		return undef unless  _allow_stack $name ;
                my  ($entries, $bytes)          =  $s{$name}{stack}->limits;
		push   @ { $s{$name}{saved} } , $s{$name}{stack};
		$s{$name}{stack}                =  new String::TieStack;

		$s{$name}{stack}->{'max_entries'} =  $entries;
		$s{$name}{stack}->{'max_KBytes'}  =  $bytes  ;
	}else{
		$s{ $name } = _create_entry ; 
	}
	return qstack $name     if want('SCALAR', '!HASH') ;
        return $s{$name}        if want('HASH'); 
}


sub delstack  {
	my $name = shift || 'SESSION' ;
	@{ $s{$name}{saved} }   ? do{ $s{$name}{stack} = pop @{ $s{$name}{saved} } } 
				: $s{$name}{stack}->CLEAR   ;
        qstack $name ;
}
sub Queue       {  
	my $name = defined $_[1]  ? shift :'SESSION'  ;
	newstack $name unless $s{$name} ;
	$s{ $name }  {stack}->queue(@_)  
}

sub dumpe {  
	my $name = shift || 'SESSION' ;
	print Data::Dumper->Dump( [$s{$name}] , ["*$name"]     )  
} 

sub Push  ($;@)    {  
	my $name =  $_[1] ? shift() : 'SESSION'; 
	newstack $name   unless exists $s{$name}{stack} ;
	$s{ $name }{stack}->PUSH(@_)         
}


sub dumpe_s {  
	my $name = shift || 'SESSION' ;
	Data::Dumper->Dump( [$s{$name}] , ["*$name"]     )  
} 


sub limit_bytes {  
	my ($name, $val) = @_ ;
	(defined $val)  ?  ( ($s{$name}->{stack}||newstack($name)->{stack}) ->max_KBytes($val))
		        : $s{$name || 'SESSION'} {stack}  ->max_KBytes() ;
}
		   
sub limit_entries {  
	my ($name, $val) = @_ ;
	(defined $val)  ?  ( ($s{$name}->{stack}||newstack($name)->{stack}) ->max_entries($val))
			:  $s{$name||'SESSION'}{stack} ->max_entries() ;
}


sub limits {
	my ($q, $ent,  $byt ) = @_ ;
	#$s{$q}{stack}  || newstack $q ;
	(defined $_[1])     ?  (limit_entries( $q, $ent )    , limit_bytes( $q, $byt) )
			    :  (limit_entries( $q||'SESSION'), limit_bytes $q||'SESSION') ;
}

sub info {
	 map { 
		 (limit_bytes $_)  ?  sprintf "%-15s %5d stacks %5d entries %9d bytes\n",
                                      $_, qstack( $_), qelem( $_) , total_bytes($_)
		      	           :  sprintf "%-15s %5d stacks %5d entries\n",
                                      $_, qstack( $_), qelem( $_) ;
	     }  keys  %s ;
}


1;
__END__

=head1 NAME

String::RexxStack::Named - implements named stacks 

=head1 SYNOPSIS

 Using some basic functions with named stacks:
Push    'name1', qw( two  three);
Queue   'name1', qw( one  zero );
qelem   'name1';
qbuf    'name1';
Pull    'name1', 1;
limit_entries 'name1', 5 ;
newstack 'name1';
Push    'name1', qw( apple  orange);
dumpe   'name1';

 Using some basic functions with the default stack:
Push   'SESSION',  qw( two  three);
Queue  'SESSION',  qw( one  zero );
qelem;
qbuf;
limit_entries 'SESSION', 5 ;
newstack;
Push    'SESSION',  qw( apple  orange);
dumpe;


=head1 DESCRIPTION

This module implements multiple named stacks. Conceptually, it is a
logical  extension to String::RexxStack/Single.pm, but instead of one anonymous 
stack-of-stacks, this module supports multiple named stack-of-stacks.

It is a more elaborate data structure than a regular stack since 
(a) it contains buffers within the stack, and stack operations
can be applied within a region of the stack, 
(b) it support multiple stacks in stack-within-stack fashion, 
(c) it supports both a Perlish and Rexx syntax -- the Rexx syntax is probably simpler, 
and (d) the stack scope can be internal to  the application (as usual), or
the Stack can run as a daemon to enable sharing of data between network
applications, or you could use both the internal plus the networking
stacks at the same time.

The above description is for one stack-of-stacks data structure 
(like in String::RexxStack::Single.pm). With this module, we can
have multiple stacks-of-stacks, which can be created via the newstack()
function. For convenience, the stack-of-stacks named 'SESSION' is
already created. In addition, the  short-cut form of many functions will 
implicitly refer to this structure when the stack_name argument is omitted.

Since every stack is actually a stack-of-stacks, this documentation uses
both terms interchangeably.


=over

=item STORE FUNCTIONS

 queue(), PUSH()

=over 8
  
=item PUSH()

 Usage: Push  stack_name   elements...
        Push  element

Takes multiple arguments and performs a push operation on the stack.

There are two forms of invocation: (1) when the number of arguments are greater
than two or more, the first argument is the name of the stack, followed by
the elements destined to the stack, and (2) when the number of arguments
is only one, the function assumes that the name  of the stack is 'SESSION',
and the element to push is that single argument. 

If stack_name does not exist, it will be created.

When stack limits prevent the operation to succeed, non of the arguments
will be pushed on the stack -- therefore, if the stack has room for
some of the argument but not for all, nothing is pushed at all.
The return value is the number of items of the stack after
the push, and false on failure.

=item Queue()

 Usage: Queue  stack_name   elements...
        Queue  element

The two forms of invocation are similar to Push(). 

Arguments are (logically) placed into stack as one unshift call per argument;
therefore, it similar to unshift (reverse @_) .  The return value is not defined.

=item queue()

An alias for Queue() .

=back

=item RETRIEVE FUNCTIONS

 Pull(), Pop(), pull()

=over 8

=item Pull()

 Usage: Pull  stack_name   N
        Pull  [ N ] ;

Returns a list containing the topmost N elements of the stack. If one of the removed 
elements was bellow a marked buffer, the buffer is destroyed. Returns undef on failure.

With the first form of invocation, both arguments are mandatory and there are no
defaults. With the second form, stack_name silently defaults to 'SESSION',
and N defaults to 1;

=item Pop()

And alias for Pull() .
 
=item  pull()

 Usage: pull [ stack_name ] 

Returns all elements of the stack as an array of strings.  After
this operation, the stack will be empty.  When unspecified, 
stack_name defaults to 'SESSION'.  Returns undef on failure;

=back

=item MISC FUNCTIONS

 newstck(), delstack(), qelem(), clear(), 
 printq() , printq_s(), dumpe(), dumpe_s, info(), 

=over 8

=item newstack()

 Usage: [NEWSTACK 'stack_name']
        [NEWSTACK]

The current stack is pushed into an (inaccessible) array of saved
stacks, then a new empty stack is created (with the same stack 
limits) and becomes the current stack.  Returns a reference to
the newly created stack when called in HASH context, or returns
the number of stacks (after the operation) when called in SCALAR (but
not HASH) context. It returns  undef on failure.

When unspecified, stack_name defaults to 'SESSION'.

=item delstack()

 Usage: [DELSTACK 'stack_name' ]
        [DELSTACK]

Deletes the current the stack and the most recently saved stack
becomes the current stack. If before the operation there were no
saved stacks, it will just empty the current stack.  Returns the
total number of stacks (after the operation). The DELSTACK 
command never fails, and the lowest possible return value is 1 .

When unspecified, stack_name defaults to 'SESSION'. 


=item qelem()

 Usage: qelem [ stack_name ] 

Returns the number of entries (elements) in the stack. When unspecified,
stack_name defaults to 'SESSION'.  Returns undef on failure;

=item clear()

 Usage: clear [ stack_name ] 

Clears all entries from the stack. Stack limits stay the same.
When unspecified, stack_name defaults to 'SESSION'.  Returns undef on failure;

=item printq()

 Usage: printq [ stack_name ] 

Prints to stdout all elements of the stack. (The stack remains unchanged.)
When unspecified, stack_name defaults to 'SESSION'.  Returns undef on failure;

=item printq_s()

 Usage: printq_s [ stack_name ] 

Returns a string containing all elements of the stack. (The stack remains unchanged.)
When unspecified, stack_name defaults to 'SESSION'.  Returns undef on failure;

=item dumpe()

 Usage:  dumpe  [ 'stack_name' ]

Prints to stdout the data structure that contains the
current stack and any saved stacks.
 
When unspecified, stack_name defaults to 'SESSION'. 

=item dumpe_s()

Same like dumpe(), except that the return value is the string that
dumpe() would have printed to stdout.

=item info()

 Usage:  print [INFO] ;

Prints to stdout information about he current state of named stacks.
The return value is undefined.

=back

=item BUFFER FUNCTIONS

 qbuf(), makebuf(), dropbuf(), desbuf()

=over 8

=item qbuf()

 Usage: qbuf [ stack_name ] 

Returns the number of buffers in the stack. When unspecified,
stack_name defaults to 'SESSION'.  Returns undef on failure;

=item makebuf()

 Usage: makebuf  [ stack_name ] 

Creates a buffer on top of the stack. Although elements pushed to
the stack will still go on top of the stack, the unshift() and
queue() operations will place their elements at the point were
there the (last) buffer was created.  For example, if the stack had
ten elements before makebuf, the push operation will still place
its arguments at the very top, but the unshift() and queue() 
operators will think that the bottom of the stack is just after the 10th
item, and will place their arguments on top of the 10th item since
it now thinks thinks the bottom has moved.

On success, this function returns the number of buffer on the stack
(including this latest one). On failure it returns undef, this can
happen if we try to create the same buffer twice at the same point.

stack_name defaults to 'SESSION'.  Returns undef on failure;

=item dropbuf()

 Usage:  dropbuf  [stack_name ] 

Removes the topmost buffer (and its elements) from the stack.
stack_name defaults to 'SESSION'.  Returns undef on failure;

=item desbuf()

 Usage: desbuf [ stack_name ] 

Removes all buffers (and their elements) from the stack.  The stack
could still contain elements that were not in any buffer.

stack_name defaults to 'SESSION'.  Returns undef on failure;

=back


=item LIMIT FUNCTIONS

 limit_entries(), limit_bytes(), limits()

=over 8
 
=item limit_entries()

 Usage:  limit_entries  stack_name, [ number ]
         limit_entries 

The first form is the main method of invocation:
when called with a number argument, it sets the max_entries limit
for the stack to that value;  when called without a number argument, it
returns the value of limit. The second, the short form of invocation,
only returns the limit of the 'SESSION' stack. 
If at invocation  stack_name was undefined, a new stack by that name
will be created and then initialized.

This function never fails. 

In all cases, the stack entries stay untouched and no
entries are removed, even if the (new) limit is lower
that the number of entries already in the stack. 

=item limit_bytes()

 Usage:  limit_bytes  stack_name, [ number ]
         limit_entries

The first form is the main method of invocation:
when called with an integer or float argument, it sets the max_KBytes limit 
of the current stack to that value; when called without an argument, it 
returns the value of the limit.  The second, the short form of invocation, 
only returns the limit of the 'SESSION' stack. 

Returns undef on failure.

In all cases, the stack entries stay untouched and no
entries are removed, even if the (new) limit is lower
that the number of bytes already in the stack. 
The number argument should be in Kilo-Byte
units, where 1KB = 1024 Bytes .  Therefore, if we want the total
size for all entries to be no more than 10 bytes, we will call it as
max_KBytes(.01);

=item limits

 Usage:  limits  stack_name, [ number , number ]
         limits

It is a get/set wrapper function around limit_entries() and limit_bytes().
When called with zero or one arguments, it returns an array of two values 
consisting of the results from limit_entries and then from limit_bytes, in
this order. When called with 3 arguments, it calls to initialize
limit_entries and then limit_bytes. 

=back

=back


=head2 EXPORT

 pull(), Pull(), Push(), Pop(), clear(), qelem(), Queue()

=head1 AUTHOR

Ioannis Tambouras, E<lt>ioannis@earthlink.netE<gt>

=head1 SEE ALSO

L<String::TieStack>,
L<regina>

=cut


