package Object::Botox;

use 5.008;
use strict;
use warnings;


=head1 NAME

Object::Botox - simple object constructor with accessor, prototyping and default-settings of inheritanced values.

=head1 VERSION

Version 1.15

=cut

our $VERSION = '1.15';
$VERSION = eval $VERSION;

=head1 SYNOPSIS

Object::Botox writed for easy object creation by default constructor and support managment properties,
inherited by children of prototyping class.

  package Parent;
  use Botox; # yes, we now are got |new| constructor
  
  # default properties for ANY object of `Parent` class:
  # prop1_ro ISA 'write-protected' && prop2 ISA 'public'
  # and seting default value for each other
  
  # strictly named constant PROTOTYPE !
  use constant PROTOTYPE => { 'prop1_ro' => 1 , 'prop2' => 'abcde' };
 
=head1 DESCRIPTION

Object::Botox - simple constructor and properties prototyper whith checking of properties existans.

To create parent module:
   
	package Parent;

	use Botox;
        
    # strictly named constant PROTOTYPE !
	use constant PROTOTYPE => {
                'prop1_ro' => 1 ,
                'prop2' => 'abcde'
                };
	
	sub show_prop1{ # It`s poinlessly - indeed property IS A accessor itself
		my ( $self ) = @_;
		return $self->prop1;
	}
	
	sub set_prop1{ # It`s NEEDED for RO aka protected on write property
		my ( $self, $value ) = @_;
		$self->prop1($value);
	}
	
	sub parent_sub{ # It`s class method itself
		my $self = shift;
		return $self->prop1;
	}
	1; 

after that we are create instanse:

	package main;
	use Data::Dumper;
	
	# change default value for prop1
	my $foo = new Parent( { prop1 => 888888 } );
	
	print Dumper($foo);

outputs get to us:

	$VAR1 = bless( {
			'Parent::prop1' => 888888,
			'Parent::prop2' => 'abcde'
			 }, 'Parent' );

properties may have _rw[default] or _ro acess mode and inheritated.

	eval{ $foo->prop1(-23) };
	print $@."\n";
	
output somthing like this:

	Can`t change RO properties |prop1| to |-23| in object Parent from main at ./test_more.t line 84

to deal (write to) with this properties we are must create accessor .

Also all of properties are inheritanced.

	package Child;	
	use base 'Parent';

	use constant PROTOTYPE => {
          'prop1' => 48,
          'prop5' => 55,
          'prop8_ro' => 'tetete'
			    };
	1;

give to us something like this

	$VAR1 = bless( {
                 'Child::prop5' => 55,
                 'Child::prop2' => 'abcde',
                 'Child::prop1' => 48,
                 'Child::prop8' => 'tetete'
               }, 'Child' );

Chainings - all setter return $self in success, so its chained

	$baz->prop1(88)->prop2('loreum ipsum');

=head1 EXPORT

new() method by default

=cut

use constant 1.01;
use MRO::Compat qw( get_linear_isa ); # mro::* interface compatibility for Perls < 5.9.5
use autouse 'Carp' => qw( croak carp );

my ( $create_accessor, $prototyping, $setup, $pre_set );

my %properties_cache; # inside-out styled chache

my $err_text =  [
	qq(Can`t change RO property |%s| to |%s| in object %s from %s),
	qq(Haven`t property |%s|, can't set to |%s| in object %s from %s),
	qq(Name |%s| reserved as property, but subroutine named |%s| in class %s was founded, new\(\) method from %s aborted),
	qq(Odd number of elements in list),
	qq(Only list or anonymous hash are alowed in new\(\) method in object %s)
		];

=head1 SUBROUTINES/METHODS

=head2 new

new() - create object (on hashref-base) by prototype and initiate it from args

=cut

sub new{
  my $invocant = shift;
  my $self = bless( {}, ref $invocant || $invocant ); 
	exists $properties_cache{ ref $self } ? $pre_set->( $self ) : $prototyping->( $self );
	$setup->( $self, @_ ) if @_;
	return $self;
}


=begin comment

import(protected)
    
Parameters: 
    @_ - calling args
Returns: 
    void
Explain:
	- implant to caller new() constructor (I don`t think is it need to rename)

=end comment

=cut

sub import{
    no strict 'refs';
    *{+caller().'::new'} = \&new; # fix 'Use of "caller" without parentheses is ambiguous' warning
    
}

=begin comment

pre_set (private)

	initiate object with proto-properites, if we are have some object of this class in cache

Parameters: 
	$self - object
Returns: 
	void
Explain:
	get the cached properties and initiate by this values
	we are always have all accessors

=end comment

=cut 


$pre_set = sub{

	my $self = shift;		
	while ( my ($key, $value) = each %{$properties_cache{ ref $self }} ){		
		$self->$key($value);
	};

};

=begin comment

prototyping (private)

	construct object by available proto-properties, declared in itself or in parents 
Parameters: 
	$self - object
Returns: 
	void
Explain:
	walk thrue object tree, begin by object themself and build it by proto 

=end comment

=cut 


$prototyping = sub{
	
	my $self = shift;
	my $class_list = mro::get_linear_isa( ref $self );	
	# it`s for exist properies ( we are allow redefine, keeping highest )
	my %seen_prop;

	foreach my $class ( @$class_list ){
            
		# next if haven`t prototype
		next unless ( $constant::declared{$class."::PROTOTYPE"} );
 
		my $proto = $class->PROTOTYPE();
		next unless ( ref $proto eq 'HASH' );

		# or if we are having prototype - use it !		
		for ( reverse keys %$proto ) { # anyway we are need some order, isn`t it?
			
			my ( $field, $ro ) = /^(.+)_(r[ow])$/ ? ( $1, $2 ) : $_ ;
			next if ( exists $seen_prop{$field} );
			$seen_prop{$field} = $proto->{$_}; # for caching
			
			$create_accessor->( $self, $field, defined $ro && $ro eq 'ro' );
			$self->$field( $proto->{$_} );
			
			# need check property are REALY setted, or user defined same named subroutine, I think
			unless ( exists $self->{ (ref $self).'::'.$field} ){
				croak sprintf $err_text->[2], $field, $field, ref $self, caller(1);
			}
			
		}
	}
	
	$properties_cache{ ref $self } = \%seen_prop; # for caching
};

=begin comment

create_accessor (private)

	create accessors for properites
Parameters: 
	$class	- object class
	$field	- property name
	$ro	- property type : [ 1|undef ]
Returns: 
	void

=end comment

=cut

$create_accessor = sub{
	my $class = ref shift;
	my ( $field, $ro ) = @_ ;
	
	my $slot = "$class\::$field"; # inject sub to invocant package space
	no strict 'refs';             # So symbolic ref to typeglob works.
	return if ( *$slot{CODE} );   # don`t redefine ours closures
	
	*$slot = sub {      		  # or create closures
			my $self = shift;
			return $self->{$slot} unless ( @_ );
			if ( $ro && !( caller eq ref $self || caller eq __PACKAGE__ ) ){
				croak sprintf $err_text->[0], $field, shift, ref $self, caller;
			}
			$self->{$slot} = shift;
			return $self;	      # yap! for chaining
		};

};

=begin comment

setup (private)

	fill object properties by default values
Parameters: 
	$self - object
	@_ - properties as list or hashref:
		(prop1=>aaa,prop2=>bbb) AND ({prop1=>aaa,prop2=>bbb}) ARE allowed
Returns: 
	void

=end comment

=cut

$setup = sub{
	my $self = shift;
	my %prop;
	
	if ( ref $_[0] eq 'HASH' ){
	    %prop = %{$_[0]};
	}
	elsif ( ! ref $_[0] ) {
	    unless ( $#_ % 2 ) {
		# so, if list are odd whe are have many troubless,
		# but for support some way as perl 'Odd number at anonimous hash'
		carp sprintf $err_text->[3], caller(1);
		push @_, undef;
	    }
	    %prop = @_ ;
	}
	else {
	    croak sprintf $err_text->[4], ref $self, caller(1);
	}

	while ( my ($key, $value) = each %prop ){
	    # if realy haven`t property in PROTOTYPE
	    unless ( exists ${$properties_cache{ ref $self }}{$key} ) {
		    croak sprintf $err_text->[1], $key, $value, ref $self, caller(1);
	    }
	    $self->$key( $value );
	}

};

=head1 SEE ALSO

Moose, Mouse, Class::Accessor, Class::XSAccessor

=head1 AUTHOR

Meettya, C<< <meettya at cpan.org> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-object-botox at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Object-Botox>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.


=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Object::Botox


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Object-Botox>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Object-Botox>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Object-Botox>

=item * Search CPAN

L<http://search.cpan.org/dist/Object-Botox/>

=back


=head1 ACKNOWLEDGEMENTS


=head1 LICENSE AND COPYRIGHT

Copyright 2011 Meettya.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.


=cut

1; # End of Object::Botox
