package Scalar::Cycle::Manual ;

use strict;
use warnings ;

BEGIN 
{
use Sub::Exporter -setup => 
	{
	exports => [ qw() ],
	groups  => 
		{
		all  => [ qw() ],
		}
	};
	
use vars qw ($VERSION);
$VERSION = '0.03';
}

#-------------------------------------------------------------------------------

#~ use English qw( -no_match_vars ) ;
#~ use Carp qw(carp croak confess) ;


=head1 NAME

Scalar::Cycle::Manual - Cycle through a list of values (with optional automatic incrementation)

=head1 SYNOPSIS

    use Scalar::Cycle::Manual ;
	
	my $cyclic_variable = new 'Scalar::Cycle::Manual',  qw( first second third ) ;
	
	print $cyclic_variable; # 'first'
	print $cyclic_variable; # still 'first'
	
	print $cyclic_variable->next ; # 'second'
	print $cyclic_variable; # still 'first'
	
	print $cyclic_variable->previous; #  'third'
	print $cyclic_variable; # still 'first'
	
	print $cyclic_variable->increment;
	print $cyclic_variable; # 'second'
	
	print $cyclic_variable->increment;
	print $cyclic_variable; # 'third'
	
	$cyclic_variable->reset;
	print $cyclic_variable; # first
	
	print $cyclic_variable->decrement;
	print $cyclic_variable; # 'third'
	
	$cyclic_variable++;
	print $cyclic_variable; # 'first'
	
	$cyclic_variable--;
	print $cyclic_variable; # 'third'
	
	$cyclic_variable->auto_increment(1) ;
	print $cyclic_variable; # 'third'
	print $cyclic_variable; # 'first'

=head1 DESCRIPTION

There's a bunch of modules implementing a scalar which cycles in a list of values. Take your time to compare them.

If you want more control over when the variable cycles, this module may suit your needs.

=head1 DOCUMENTATION

Use C<Scalar::Cycle::Manual> to go through a list over and over again. Once you get to the end of the list, you go back to the beginning.

=head2 Overloaded operator

=head3 ++ and --

These operator act as the L<increment> and L<decrement> subroutines.

=head3 0+ and ""

These operators implement the fetching of the current value in scalar and string context.

=head3 <>

The '<>' operator returns the current value and increments the current position even if L<auto_increment> is set to B<0>.

=head1 SUBROUTINES/METHODS

=cut

 ## no critic
use constant CURRENT_INDEX => 0 ;
use constant MAX_INDEX => 1 ;
use constant VALUES => 2 ;
use constant AUTO_INCREMENT=> 3 ;
 ## use critic
#-------------------------------------------------------------------------------

use overload 
	'=' => \&copy_constructor,
	'<>' => \&increment,
	'++' => \&increment,
	'--' => \&decrement,
	'""' => \&as_scalar,
	'0+' => \&as_scalar;

#-------------------------------------------------------------------------------

sub new 
{

=head2 new(@value_list)

Creates a B<Scalar::Cycle::Manual> object that you can use to cycle through values. 

	use Scalar::Cycle::Manual ;
	
	my $cyclic_variable = new 'Scalar::Cycle::Manual'( qw( first second third )) ;

B<Arguments>

=over 2

=item * @value_list - list of values to be cycled through

=back

B<Return>

=over 2

=item * a B<Scalar::Cycle::Manual> object

=back

=cut

my ($class , @values) = @_ ;

return(bless [ 0, scalar(@values) - 1, \@values, 0], ($class || __PACKAGE__)) ;
}

#-------------------------------------------------------------------------------

sub copy_constructor
{

=head2 copy_constructor

This is needed by the B<++> operator.

=cut

my ($self) = @_ ;

return(bless [ @{$self}], __PACKAGE__);
}

#-------------------------------------------------------------------------------

sub auto_increment
{

=head2 auto_increment([$boolean])

When set, the current position in the value list is automatically incremented after the value is accessed.

When a B<Scalar::Cycle::Manual> object is created, auto_increment is set to I<false>.

	my $cyclic_variable = new 'Scalar::Cycle::Manual'( qw( first second third )) ;
	
	print $cyclic_variable; # 'first'
	print $cyclic_variable; # 'first'
	
	$cyclic_variable->auto_increment(1) ;
	
	print $cyclic_variable; # 'second'
	print $cyclic_variable; # 'third'
	
	my $is_auto_increment_on = $cyclic_variable->auto_increment() ;

B<Arguments>

=over 2

=item * $boolean- an optional value to set the auto_increment state

=back

B<Return>

=over 2

=item *  If $bolean is not defined, the current state is returned

=back

=cut

my ($self, $auto_increment) = @_ ;

return
	(
	defined $auto_increment ? $self->[AUTO_INCREMENT] = $auto_increment : $self->[AUTO_INCREMENT]
	);
}

#-------------------------------------------------------------------------------
sub as_scalar
{

=head2 as_scalar

Transform the object to the current cycle values. This is automatically called by Perl.

	use Scalar::Cycle::Manual ;
	
	my $cyclic_variable = new 'Scalar::Cycle::Manual'( qw( first second third )) ;
	
	my $value = $cyclic_variable ;
	print $cyclic_variable ;
	

B<Return>

=over 2

=item * the current value extracted from the cycle values.

=back

=cut
#~ my @caller = caller() ;
#~ print  "@caller as_scalar\n" ;

my ($self) = @_ ;

my $value =  $self->[VALUES][$self->[CURRENT_INDEX]];

if($self->[AUTO_INCREMENT])
	{
	$self->[CURRENT_INDEX]++;
	$self->[CURRENT_INDEX] = 0 if $self->[CURRENT_INDEX] > $self->[MAX_INDEX];
	}

return($value) ;
}

#-------------------------------------------------------------------------------

sub increment
{

=head2 increment()

Forces the B<Scalar::Cycle::Manual> to change to the next value in the cycle value list.

	use Scalar::Cycle::Manual ;
	
	my $cyclic_variable = new 'Scalar::Cycle::Manual'( qw( first second third )) ;
	
	print $cyclic_variable->increment;
	print $cyclic_variable ;
	
	# or 
	
	print $cyclic_variable->increment;

B<Return>

=over 2

=item * the next value, extracted from the cycle values.

=back

=cut

my ($self) = @_ ;

my $value = $self->[VALUES][$self->[CURRENT_INDEX]] ;

$self->[CURRENT_INDEX]++ ;
$self->[CURRENT_INDEX] = 0 if $self->[CURRENT_INDEX] > $self->[MAX_INDEX];

return($value) ;
}

#-------------------------------------------------------------------------------

sub decrement
{

=head2 decrement()

Forces the B<Scalar::Cycle::Manual> to change to the previous value in the value list.

	print $cyclic_variable->previous;
	print $cyclic_variable ;
	
	# or 
	
	print $cyclic_variable->previous;

B<Return>

=over 2

=item * the previous value, extracted from the cycle values.

=back

=cut

my ($self) = @_ ;

my $value = $self->[VALUES][$self->[CURRENT_INDEX]] ;

$self->[CURRENT_INDEX]-- ;
$self->[CURRENT_INDEX] = $self->[MAX_INDEX] if $self->[CURRENT_INDEX] < 0 ;

return($value) ;
}

#-------------------------------------------------------------------------------

sub reset  ## no critic (Subroutines::ProhibitBuiltinHomonyms)
{

=head2 reset()

Makes the current value the first value in the value list.

	use Scalar::Cycle::Manual ;
	
	my $cyclic_variable = new 'Scalar::Cycle::Manual'( qw( first second third )) ;
	
	$cyclic_variable->auto_increment(1) ;
	print $cyclic_variable; # 'first'
	
	$cyclic_variable->reset ;
	print $cyclic_variable; # 'first'

=cut

my ($self) = @_ ;
$self->[CURRENT_INDEX] = 0 ;

return ;
}

#-------------------------------------------------------------------------------

sub previous
{

=head2 previous()

Returns the value prior to the value at the current position. This does not affect the current position in the cycle value list.

	use Scalar::Cycle::Manual ;
	
	my $cyclic_variable = new 'Scalar::Cycle::Manual'( qw( first second third )) ;

B<Return>

=over 2

=item * the value prior to the value at the current position

=back

=cut

my ($self) = @_ ;

my $index = $self->[CURRENT_INDEX] ;

$index-- ;
$index  = $self->[MAX_INDEX] if $index < 0;

return($self->[VALUES][$index]) ;
}

#-------------------------------------------------------------------------------

sub next ## no critic (Subroutines::ProhibitBuiltinHomonyms)
{

=head2 next()

Returns the value next to the value at the current position. This does not affect the current position in the value list.

	use Scalar::Cycle::Manual ;
	
	my $cyclic_variable = new 'Scalar::Cycle::Manual'( qw( first second third )) ;

B<Return>

=over 2

=item * the value next to the value at the current position

=back

=cut

my ($self) = @_ ;

my $index = $self->[CURRENT_INDEX] ;

$index++ ;
$index  = 0 if $index > $self->[MAX_INDEX];

return($self->[VALUES][$index]) ;
}
	
#-------------------------------------------------------------------------------

1 ;

=head1 BUGS AND LIMITATIONS

None so far.

=head1 AUTHOR

	Khemir Nadim ibn Hamouda
	CPAN ID: NKH
	mailto:nadim@khemir.net

=head1 LICENSE AND COPYRIGHT

This program is free software; you can redistribute
it and/or modify it under the same terms as Perl itself.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Scalar::Cycle::Manual

You can also look for information at:

=over 4

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Scalar-Cycle-Manual>

=item * RT: CPAN's request tracker

Please report any bugs or feature requests to  L <bug-Scalar-cycle-manual@rt.cpan.org>.

We will be notified, and then you'll automatically be notified of progress on
your bug as we make changes.

=item * Search CPAN

L<http://search.cpan.org/dist/Scalar-Cycle-Manual>

=back

=head1 SEE ALSO

Scalar-MultiValue

	by Graciliano Monteiro Passos: Create a SCALAR with multiple values.

List-Rotation

	by Imre Saling: Loop (Cycle, Alternate or Toggle) through a list of values via a singleton object implemented as closure.

Tie::FlipFlop

    by Abigail: Alternate between two values.

List::Cycle

    by Andi Lester: Objects for cycling through a list of values

Tie::Cycle

    by Brian D. Foy: Cycle through a list of values via a scalar.

Tie::Toggle

    by Brian D. Foy: False and true, alternately, ad infinitum.

=cut
