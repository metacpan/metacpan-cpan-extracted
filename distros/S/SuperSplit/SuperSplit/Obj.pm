package SuperSplit::Obj;
use strict;

=head1 NAME

SuperSplit::Obj - Provides object interface to L<SuperSplit>

=head1 SYNOPSIS

 use SuperSplit::Obj;
 
 #example: split on newlines and whitespace and print
 #the same data joined on tabs and whitespace. The split works on STDIN
 #
 $s = SuperSplit::Obj->new();
 $s->stdin();
 $array = $s->split();
 #
 #use filehandle, filename to open or string:
 $s->handle( $fh );
 $s->open( "<$filename" );
 $s->text( $string );
 #
 #use separators
 $s->sep( @separator_array );
 #use limits
 $s->limits( @limit_array );
 #split everything, and join it using @sep
 $s->splitjoin( @sep );
 
=head1 DESCRIPTION

This module just provides an object-interface to the L<SuperSplit> 
module.  
You initialize it using the input specifiers, and optionally the 
separator 
and/or LIMIT separators.  The behavior is just like the 
supersplit_hashref 
method of the L<SuperSplit> module.

=over 4

=item new()

Initialises the object and retuns it, aka just what you expect from a 
simple object constructor.

=item stdin()

Tells the object to use STDIN to obtain data. STDIN is read right away.

=item handle( $fh )

Tells the object to use the filehandle $fh for input.  $fh is read right 
away, and left open in case you want to L<perlfunc/seek>.

=item open( ">$filename" )

Tells the object to get data from the argument using an open statement.  
It 
returns the opened and read filehandle, or undef if something went wrong.

=item string( $string )

Tells the object to use the string for data input. 

=item sep( @separator_array )

Uses the given array as separators. Synonyms: separator(); separators().

=item limit( @limit_array )

Uses the given array as LIMITs. Synonyms: lim(); limits().

=item split()

Perform the actual multi-dimensional splitting using earlier provided 
arguments.  It returns a multi-dimensional array.

=item join( @args )

Behaves exactly like the superjoin method.  So you don't even need to use 
the constructor before calling it.

=item splitjoin( @args )

This method combines the previous two.  It first splits like the split 
method, and than joins the resulting array with the provided arguments, 
passing them to superjoin.

=back

=head1 AUTHOR

Jeroen Elassaiss-Schaap.

=head1 LICENSE

Perl/ artisitic license

=head1 STATUS

Alpha

=cut

use vars qw(@VERSION);
@VERSION = 0.01;
use SuperSplit;

sub new{
	my $proto = shift;
	my $class = ref( $proto) || $proto;
	my $self = {};
	#Initialize  containers
	$self->{ string } = '';
	$self->{ limits } = [];
	$self->{ sep } = [];
	$self->{ array } = [];
	bless( $self, $class );
	return $self;
}

sub stdin{
	my $self = shift;
	$self->_read( \*STDIN ) ? 1 : undef;
}

sub handle{
	my $self = shift;
	my $fh = shift;
	$self->_read( $fh ) ? $fh : undef;
}

sub open{
	my $self = shift;
	my $input = shift;
	open DATA, $input or return undef;
	my $fh = \*DATA;
	$self->_read( $fh ) ? $fh : undef;
}

sub _read{
	my $self = shift;
	my $fh = shift;
	$self->{ string } = do{ local $/ = undef; join '', <$fh>; } or return 
undef;
}


sub string{
	my $self = shift;
	$self->{string} = shift;
}

sub sep{
	my $self = shift;
	$self->{ separators } = [ @_ ];
} 

sub separator{
	my $self = shift;
	$self->sep( @_ );
}

sub separators{
	my $self = shift;
	$self->sep( @_ );
}

sub lim{
	my $self = shift;
	$self->{ limits } = [ @_ ];
}

sub limit{
	my $self = shift;
	$self->lim( @_ );
}

sub limits{
	my $self = shift;
	$self->lim( @_ );
}

sub split{
	my $self = shift;
	supersplit_limits( $self->{ string }, $self->{ separators },
		$self->{ limits } );
}

sub join{
	my $self = shift if ref( $_[0] ) eq 'SuperSplit::Obj';
	superjoin( @_ );
}

sub splitjoin{
	my $self = shift;
	$self->split();
	$self->join( @_ );
}

1;
