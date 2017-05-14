package Object::groups ;
$VERSION = 2.21 ;
use 5.006_001 ;
use strict ;

; use Class::groups
; our @ISA = qw| Class::groups |
   
; 1

__END__

=pod

=head1 NAME

Object::groups - Pragma to implement group of properties

=head1 VERSION 2.21

Included in OOTools 2.21 distribution.

The latest versions changes are reported in the F<Changes> file in this distribution.

The distribution includes:

=over

=item Package::props

Pragma to implement lvalue accessors with options

=item * Package::groups

Pragma to implement groups of properties accessors with options

=item * Class::constr

Pragma to implement constructor methods

=item * Class::props

Pragma to implement lvalue accessors with options

=item * Class::groups

Pragma to implement groups of properties accessors with options

=item * Class::Error

Delayed checking of object failure

=item * Class::Util

Class utility functions

=item * Object::props

Pragma to implement lvalue accessors with options

=item * Object::groups

Pragma to implement groups of properties accessors with options

=back

=head1 INSTALLATION

=over

=item Prerequisites

    Perl version >= 5.6.1

=item CPAN

    perl -MCPAN -e 'install OOTools'

=item Standard installation

From the directory where this file is located, type:

    perl Makefile.PL
    make
    make test
    make install

=back

=head1 SYNOPSIS

=head2 Class

    package MyClass ;
    
    # creates constructor method
    use Class::costr ;
    
    # implement group method without options
    use Object::groups qw(this that) ;

    # implement group method with properties
    use Object::groups { name  => 'myGroup' ,
                         props => [qw(prop1 prop2)]
                       } ;
                                                                 
    # with options
    use Object::groups
        { name      => 'myOtherGroup' ,
          no_strict => 1 ,
          default   => { aProp => 'some value' } ,
          pre_process=> sub
                         { if ( ref $_[1] eq 'ARRAY' )
                            { $_[1] = { map { $_=>$_ } @{$_[1]} }
                            }
                         } ,
          props     => [ { name    => [qw(prop3 prop4)] ,
                           default => 'something'
                         }
                       ]
        } ;

=head2 Usage

    $object = MyClass->new ;
    
    $object->myGroup(\%hash) ;

    # same thing
    $object->myGroup( prop1 => 1 ,
                      prop2 => 2 ) ;
    
    $hash_ref = $object->myGroup
    
    $value = $object->prop2 ;             # $value == 2
    $value = $object->myGroup('prop2') ;  # $value == 2
    $value = $$hash_ref{prop2} ;          # $value == 2
    $value = $$object{myGroup}{prop2} ;   # $value == 2
    
    ($p1, $p2) = $object->myGroup(['prop1','prop2']) ;
   
    # the default will initialize the hash reference
    $other_hash_ref = $object->myOtherGroup
    $value = $other_hash_ref->{prop3}     # $value eq 'something'
       
    # adding an unknow property (see no_strict)
    $object->myOtherGroup(prop5 => 5) ;
    
    # copying the whole hash
    %myGroupHash = $object->myGroup

=head1 WARNING

Don't use the group accessor in list context in order to retrieve the hash keys: that way was deprecated and it doesn't work any more with this version.

    # WRONG
    @keys     = MyClass->myGroup ;
    
    # change it with
    @keys     = keys %{MyClass->myGroup} ;
    
    # new behaviour in list context
    %hash = MyClass->myGroup ;

=head1 DESCRIPTION

This pragma easily implements accessor methods for group of properties, which are very efficient function templates that your modules may import at compile time. "This technique saves on both compile time and memory use, and is less error-prone as well, since syntax checks happen at compile time." (quoted from "Function Templates" in the F<perlref> manpage).

This module allows also "lazy" data computing (see the C<default> option).

This module creates an accessor method with a hash in the class that implements it (e.g. $object->{any_group}) and sets/gets it using the options you set; it also creates an accessor method for each property in the C<props> option as you were using the L<Object::props|Object::props> pragma.

B<Note>: The grouped properties will be stored in e.g. C<< $Object->{any_group}{any_property} >> instead of the usual C<< $Object->{any_property} >>

Whit the accessor method for the group you can:

=over

=item *

set a group of properties by passing an hash of values to the accessor

=item *

retrieve (in list context) the list of the names of the (already defined) properties of the group

=item *

retrieve (in scalar context) the reference to the underlying hash containing the grouped properties.

=back

B<Note>: The underlaying hash contains:

=over

=item *

all the already set properties of the class and base classes

=item *

all the properties with a C<default> or C<rt_default> option (of the class and base classes, even if they have not been set yet)

=back

B<IMPORTANT NOTE>: If you write any script that rely on this module, you better send me an e-mail so I will inform you in advance about eventual planned changes, new releases, and other relevant issues that could speed-up your work.

=head2 Examples

If you want to see some working example of this module, take a look at the source of my other distributions. 

=head1 OPTIONS

=head2 name => $name

The name of the group accessor.

=head2 no_strict => 0 | 1

With C<no_strict> option set to a true value, the accessor accepts and sets also unknown properties (i.e. not predeclared). You have to access the unknown properties without any accessor method. All the other options will work as expected. Without this option the method will croak if any property does not have an accessor method.

B<Note>: This option is on by default if you define an accessor group without any C<props> option (i.e. in this case you can omit the 'no_strict' option).

=head2 pre_process => \&code

You can set a code reference to preprocess @_.

The original C<@_> is passed to the referenced pre_process CODE. Modify C<@_> in the CODE to change the actual input value.

    # This code will transform the @_ on input
    # if it's passed a ref to an ARRAY
    # [ qw|a b c| ] will become
    # ( a=>'a', b=>'b', c=>'c')
    
    use Object::groups
        { name       => 'myGroup'
        , pre_process=> sub
                         { if ( ref $_[1] eq 'ARRAY' )
                            { $_[1] = { map { $_=>$_ } @{$_[1]} }
                            }
                         ; 1
                         }
        }

=head2 default => \%props | \&$method

Use this option to set a I<default value>. The I<default value> must be a HASH reference or a CODE reference.

If you pass a CODE reference as the default it will be evaluated only when the group will be accessed, and only if the group has no defined (HASH) value (this allows "lazy" data computing and may save some CPU); the group will be set to the HASH reference that the referenced CODE must return.

You can reset a property to its default value by assigning an empty HASH reference ({}) to it.

=head2 props => \@props

This option creates the same properties accessor methods as you would use directly the L<Object::props|Object::props> pragma. It accepts a reference to an array, containing the same structured parameters as such accepted by the L<Object::props|Object::props> pragma.

=head1 METHODS

=head2 add_to( package, groups )

This will add to the package I<package> the accessors for the I<groups>. It is useful to add properties in other packages.

   package Any::Package;
   Object::groups->('My::Package', { name => 'any_name', ... });
   
   # which has the same effect of
   package My::Package;
   use Object::groups { name => 'any_name', ... }

=head1 SUPPORT and FEEDBACK

If you need support or if you want just to send me some feedback or request, please use this link: http://perl.4pro.net/?Object::groups.

=head1 AUTHOR and COPYRIGHT

© 2004-2005 by Domizio Demichelis.

All Rights Reserved. This module is free software. It may be used, redistributed and/or modified under the same terms as perl itself.

=head1 CREDITS

Thanks to Juerd Waalboer (http://search.cpan.org/author/JUERD) that with its I<Attribute::Property> inspired the creation of this distribution.

=cut
