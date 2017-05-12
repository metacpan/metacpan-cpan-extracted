# Copyright (c) 2003 Ioannis Tambouras <ioannis@earthlink.net> .
# All rights reserved.


package String::TieStack ;
use 5.006;
use Carp;
use strict;
use base 'Tie::Array';
use Data::Dumper;
use Class::MethodMaker             
				   new_with_init  => [qw( new TIEARRAY )],
                                   new_hash_init  => 'ihash',
                                   list           => [qw( DATA buffers )],
		 		   grouped_fields => [ tlimits=>[qw( max_entries max_KBytes)], 
						       info  =>[qw( total_bytes  )], ],
                                   ;

sub STORE     { croak 'ERROR: operation prohibited.' }
*FETCH        = \& STORE      ; 
*FETCHSIZE    = \& DATA_count ;
*SPLICE       = \& STORE      ;

sub import { 
	my ($self, %param) = @_ ;; 
	$__PACKAGE__::DEFAULTS{max_entries} = $param{max_entries} || 0  ;
	$__PACKAGE__::DEFAULTS{max_KBytes}  = $param{max_KBytes}  || 0  ;
};

sub init {  
     my $self = shift; 
     $self->buffers_clear;
     $self->DATA_clear;
     $self->ihash( %__PACKAGE__::DEFAULTS, @_ ) ;
     $self->{top}   =  $self->{total_bytes}  = 0 ;
}


sub limits { 
      my $self = shift;
      ( @_ == 2 )   ? ( $self->max_entries( $_[0] ) , 
		        $self->max_KBytes( $_[1] )  ,  return @_[0,1] )
		    : ( return  ($self->max_entries()||0,  $self->max_KBytes|| 0 )) ;
}

sub _bytes {
       my $sum;
       $sum += length($_||'')       for @_ ;
       $sum;
}


sub _allowed_p {
	my $self      =  shift;
        my ($etarget, $new_bytes)  = ( $self->FETCHSIZE() + scalar @_ , _bytes(@_) );
	return  0     if ($self->max_entries) && ($etarget >  $self->max_entries );

        my $btarget   = ($self->{total_bytes} || 0) + $new_bytes ;
        my $blimit    = ($self->max_KBytes    || 0) * 1024 ;
        return  0     if ($self->max_KBytes)  && ($btarget >  $blimit);
        $new_bytes;
};


sub UNSHIFT { 
        my ($self, @val)  = @_ ;
        return undef  unless my $bytes =  &_allowed_p ;
        $self->DATA_splice( $self->{top} , 0, @val  );
        $self->{total_bytes}           =  $self->{total_bytes} + $bytes  ;
}


sub PUSH { 
	my ($self, @val)  = @_ ;
	return undef  unless my $bytes =  &_allowed_p ;
	$self->{total_bytes}           =  $self->{total_bytes} + $bytes  ;
	$self->DATA_push( @val ) ; 
}

sub POP { 
	my $self = shift;
	$self->dropbuf   if  $self->FETCHSIZE <= $self->{top} ;
        my $ret = $self->DATA_pop ;  
	$self->total_bytes( $self->total_bytes - _bytes($ret));
	$ret;
}

sub CLEAR { 
        my $self = shift; 
	my ($entries , $bytes) = ($self->max_entries(), $self->max_KBytes() ) ;
	$self->init(@_);
	$self->max_entries( $entries ) ;
	$self->max_KBytes( $bytes ) ;
}

sub makebuf {
	my $self      = shift;
	return undef if $self->{top} == $self->FETCHSIZE;
	$self->{top}  = $self->FETCHSIZE ;
	$self->buffers_push ( $self->{top} ); 
}

sub dropbuf {
	my $self     =  shift;
	return unless $self->buffers_count;
        my $start    =  $self->buffers_pop();
	my $end      =  $self->DATA_count;
	$self->DATA_splice( $start, $end );
	$self->{top} =  $self->buffers_index( $self->buffers_count - 1 ) || 0;
}

sub desbuf {
	my $self = shift;
	return unless $self->buffers_count;
        $self->dropbuf   for $self->buffers;
}

sub queue    { shift->UNSHIFT( reverse @_ )                } 
sub pdumpq   { print &dumpq                                }
*qelem       =  \& DATA_count     ;
*queued      =  \& qelem          ;
*qbuf        =  \& buffers_count  ;
*printq      =  \& DATA           ;  
sub dumpq    { Data::Dumper->Dump( [shift], ['tieStack'] ) }

sub pullbuf {
	my  ($self, $num)  = shift;
	return undef  unless $self->buffers_count ;
	$num = $self->DATA_count  - $self->{top};
	$self->pull( $num );
}

sub pull    {
	my  ($self, $num)  = @_;
	$num   = (defined $num) ? $num : 1;
	return undef unless  ($self->qelem() - $num) > -1 ;
	my  @ret;
	push @ret, $self->POP    for (1..$num);
	@ret;
}

sub pullall {
	my $self = shift;
        my @ret = $self->DATA;
	$self->CLEAR;
	@ret;
};

1;
__END__

=head1 NAME

String::TieStack - base class for Rexx-type stacks 

=head1 SYNOPSIS

 # Set default to no stack limits
 use String::TieStack ;                      

 # Set default so stacks are limited to 400 entries
 use String::TieStack  max_entries => 400 ;  

 # Set default so stacks are limited to 2*1024 bytes
 use String::TieStack  max_KBytes  =>   2 ;  

 $t = tie my @arr , 'String::TieStack';
 push       @arr , qw(  one two )  ;
 unshift    @arr , qw( -one zero ) ;
 pop        @arr                   ;
 $t->queue ( qw( -two -three) ;  # Same like $t->UNSHIFT( reverse @_ )
 $t->pull(3) ;                   # Returns the N  topmost elements
 $t->pullall ;                   # Pop() all entries in one step.
 $t->CLEAR   ;                   # Clears the stack. Same as @arr = ()  ;
 $t->qelem   ;                   # Return the number of entries in the stack
 $t->queued  ;                   # Alias for qelem()
 $t->makebuf ;                   # Create a new buffer 
 $t->qbuf    ;                   # Return the number of buffer in the stack
 $t->dropbuf ;                   # Remove the topmost buffer
 $t->desbuf  ;                   # Remove all buffers 
 pullbuf
 $t->max_entries;                # get/set the value of max_entries 
 $t->max_KBytes ;                # get/set the value of max_KBytes
 limits
 $t->printq  ;                   # Print all entries 
 dumpq
 pdumpq


=head1 DESCRIPTION

 This module implements a base class for Rexx-type stacks.

By default, stacks have no entry or size limits; although, defaults can be changed
at "use" time (as shown above), or they can be explicitly set by methods
after the stack is instantiated. See the LIMIT SECTION for details.

=over

=item STORE FUNCTIONS

 queue(), PUSH(),

=over 8


=item queue()

Same like UNSHIFT( reverse @_ ) ; that is,
arguments are (logically) placed into stack as one unshift() call per argument.


=item PUSH()

Takes multiple arguments and performs a push operation on the stack. 
If stack limits prevent the operation to push all arguments, non of the arguments
will be pushed on the stack.
The return value is the number of items of the stack (after 
the push), and false on failure.

Returns the number of entries in the stack.

=back

=item RETRIEVE FUNCTIONS

 UNSHIFT(), POP, pull(), pullall(), pullbuf()

=over 8

=item UNSHIFT()

Similar the Perl's unshift() operator, but 
stack limits could prevent the operation to succeed.

=item POP()

Retrieves the topmost elements. If the element removed
is bellow an empty buffer, the buffer is also destroyed.


=item pull()

Returns the topmost N elements from the stack; it is similar
to calling POP()  N number of times. N defaults to 1 when
the argument is omitted. On failure, it returns undef .


=item pullall()

Returns all elements of the stack as an array of strings.
After this operation, the stack will be empty.

=item pullbuf ()

 See description in section BUFFER FUNCTION .

=back

=item MISC FUNCTIONS

 CLEAR(), qelem(), queued()

=over 8

=item CLEAR()

Clears all entries from the stack. The stack limits
stay the same.

=item qelem()

Returns the number of entries (elements) in the stack

=item queued()

An alias for qelem() .
Returns the number of entries (elements) on the stack. 

=back

=item BUFFER FUNCTIONS

 makebuf(), qbuf(), dropbuf(), desbuf(), pullbuf()

=over 8

=item makebuf()

Creates a buffer on top of the stack. Although 
elements pushed to the stack will still
go on top of the stack, the unshift()
and  queue() operations will place their elements
at the point were there the (last) buffer was created.
For example, if the stack had ten elements 
before makebuf, the push operation will
still place its arguments at the very top, but
the unshift() and queue() operators will think that the
bottom of the stack is just after the 10th item, and
will place their arguments on top of the 10th item
since it now thinks thinks the bottom has moved.

On success, this function returns the number of buffers
on the stack (including this latest one). On failure
it returns undef, this can happen if we try to
create the same buffer twice at the same point.

=item qbuf() 

Returns the number of buffers on the stack.

=item dropbuf()

Removes the topmost buffer (and its elements) from the stack.

=item desbuf()

Removes all buffers (and their elements) from the stack.
The stack could still contain elements that were
not in any buffer.

=item pullbuf()

Returns all elements of the topmost buffer as an array of strings.
After this operation the topmost buffer will be empty.
Returns undef on failure, when the stack has no buffers.

=back

=item LIMIT FUNCTIONS

 max_entries(), max_KBytes(), limits()

=over 8

=item max_entries()

When called with an integer argument, it sets the max_entries limit for the stack
to that value.  The stack remains the same, it will not remove old entries if the
new limit is lower.  The return value is the value of max_entries after the update.
When called without an argument, it returns the current value of max_entries. So,
the return value is the same for both calls.

If max_entries is set to 0 (the default), it means that there are no limits based
on the number entries -- the number of entries is unlimited. 


=item max_KBytes()

When called with an integer or float argument, it sets the max_KBytes limit for the stack
to that value.  The stack remains the same, it will not remove old entries if the 
the new limit is lower. The argument should be in Kilo-Byte units, where 1KB = 1024 Bytes .
Therefore, if you want the stack to contain entries that together total no more than 10 bytes,
call it as max_KBytes(.01);


=item limits()

It is a get/set function that reads or initializes the values
of max_entries and max_KBytes. When called with no arguments,
it returns an array of two values; and when called with two 
arguments it sets max_entries and max_Kbytes. 

=back

=item PRINT FUNCTIONS

 dumpq(), pdumpq(), printq()

=over 8

=item dumpq()

Returns the stringified data structure of the Perl stack object

=item pdumpq()

Prints to stdout the stringified data structure of the Perl stack object

=item printq()

Prints to stdout all elements of the stack. (The stack is not changed.)



=back

=back


=head1 EXPORT

None, and not needed.

=head1 AUTHOR

Ioannis Tambouras, E<lt>ioannis@earthlink.netE<gt>

=head1 SEE ALSO

L<String::RexxStack>,
L<regina>

=cut

