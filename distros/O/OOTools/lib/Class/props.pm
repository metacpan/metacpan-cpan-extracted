package Class::props ;
$VERSION = 2.21 ;
use 5.006_001 ;
use strict ;
  
# This file uses the "Perlish" coding style
# please read http://perl.4pro.net/perlish_coding_style.html

; use Carp
; $Carp::Internal{+__PACKAGE__}++

; sub import
   { my $tool = shift
   ; $tool->add_to(scalar caller, @_)
   }

; sub add_to
   { my ($tool, $pkg, @args) = @_
   ; foreach my $prop ( @args )
      { $prop = $tool->_init_prop_param( $prop )
      ; $tool->_add_prop( $pkg, $prop )
      }
   }

; sub _init_prop_param
   { my ( $tool, $prop ) = @_
   ; $prop = { name => $prop }
             unless ref $prop eq 'HASH'
   ; $$prop{name} = [ $$prop{name} ]
                    unless ref $$prop{name} eq 'ARRAY'
   ; $$prop{allowed} &&= [ $$prop{allowed} ]
                         unless ref $$prop{allowed} eq 'ARRAY'
   ; $prop
   }
                      
; sub _add_prop
   { my ( $tool, $pkg, $prop ) = @_
   ; my $gr = delete $$prop{group}
   ; my $to_tie = (  defined $$prop{default}
                  || defined $$prop{protected}
                  || defined $$prop{allowed}
                  || defined $$prop{validation}
                  || defined $$prop{post_process}
                  )
   ; foreach my $n ( @{$$prop{name}} )     # foreach property
      { no strict 'refs'
      ; *{$pkg.'::'.$n}
        = sub : lvalue
           { (@_ > 2) && croak qq(Too many arguments for "$n" property, died)
           ; my $scalar
             = $tool =~ /^Class/   ? $gr
                                     ? \${(ref $_[0]||$_[0]).'::'.$gr}{$n}
                                     : \${(ref $_[0]||$_[0]).'::'.$n}
             : $tool =~ /^Package/ ? $gr
                                     ? \${$pkg.'::'.$gr}{$n}
                                     : \${$pkg.'::'.$n}
             : $gr
               ? \$_[0]{$gr}{$n}
               : \$_[0]{$n}
           ; my $Tscalar
           ; if ( $to_tie )
              { tie $$Tscalar
                  , 'Class::props::Tie'
                  , $_[0]                   # [0] object/class
                  , $n                      # [1] prop name
                  , $scalar                 # [2] lvalue ref
                  , $prop                   # [3] options ref
              }
             else
              { $Tscalar = $scalar
              }
           ; @_ == 2
             ? ( $$Tscalar = $_[1] )
             :   $$Tscalar
           }
      }
   }

; package Class::props::Tie
; use Carp
; $Carp::Internal{+__PACKAGE__}++
; use strict

; sub TIESCALAR
   { bless \@_, shift
   }
   
; sub FETCH
   { my $val = do
                { if ( defined ${$_[0][2]} )
                   { ${$_[0][2]}
                   }
                  elsif ( defined $_[0][3]{default} )
                   { my $def = ref $_[0][3]{default} eq 'CODE'
                               ? $_[0][3]{default}( $_[0][0] )
                               : $_[0][3]{default}
                   ; $_[0][3]{no_strict}
                     ? ${$_[0][2]} = $def
                     : $_[0]->STORE( $def )
                   }
                  else
                   { undef
                   }
                }
   ; local $_ = $val
   ; defined $_[0][3]{post_process}
     ? $_[0][3]{post_process}( $_[0][0], $val )
     : $val
   }

; sub STORE
   { my $from_FETCH = (caller(1))[3]
                   && (caller(1))[3] =~ /::FETCH$/
   ; my $default = $from_FETCH
                   ? 'default '
                   : ''
   ; if (   $_[0][3]{protected}   # if protected
        &&! $from_FETCH           # bypass for default
        &&! $Class::props::force  # bypass deliberately
        )
      { my ($OK, $f)
      ; until ( $OK )
         { last unless my $caller = caller($f++)
         ; $OK = $caller->can($_[0][1])
         }
      ; $OK || croak qq("$_[0][1]" is a read-only property, died)
      }
   ; if (   $_[0][3]{allowed}     # if restricted
        &&! $from_FETCH           # bypass for default
        &&! $Class::props::force  # bypass deliberately
        )
      { my ($OK, $f)
      ; until ( $OK )
         { last unless my $caller = (caller($f++))[3]
         ; $OK = grep { $caller =~ qr/$_/ } @{$_[0][3]{allowed}}
         }
        ; $OK || croak qq("$_[0][1]" is a read-only property, died)
      }
   ; local $_ = $_[1]
   ; if ( defined $_[0][3]{validation}  # validation subref
        && defined $_                   # bypass for undef (reset to default)
        )
      { $_[0][3]{validation}( $_[0][0], $_)
        || croak qq(Invalid ${default}value for "$_[0][1]" property, died)
      }
   ; ${$_[0][2]} = $_
   }

1 ;

__END__

=pod

=head1 NAME

Class::props - Pragma to implement lvalue accessors with options

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
    
    # implement constructor without options
    use Class::constr ;
    
    # just accessors without options (list of strings)
    use Class::props @prop_names ;                       # @prop_names (1)
    
    # a property with validation and default (list of hash refs)
    use Class::props { name       => 'digits',
                       validation => sub{ /^\d+\z/ } ,    # just digits
                       default    => 10
                     } ;
    
    # a group of properties with common full options
    use Class::props { name       => \@prop_names2,      # @prop_names2 (1)
                       default    => sub{$_[0]->other_default} ,
                       validation => sub{ /\w+/ } ,
                       protected  => 1 ,
                       no_strict  => 1 ,
                       allowed    => qr/::allowed_sub$/
                     } ;
                     
    # all the above in just one step (list of strings and hash refs)
    use Class::props @prop_names ,                       # @prop_names (1)
                     { name       => 'digits',
                       validation => sub{ /^\d+\z/ } ,
                       default    => 10
                     } ,
                     { name       => \@prop_names2,      # @prop_names2 (1)
                       default    => sub{$_[0]->other_default} ,
                       validation => sub{ /\w+/ } ,
                       protected  => 1 ,
                       no_strict  => 1 ,
                       allowed    => qr/::allowed_sub$/
                     } ;
                     
    # (1) must be set in a BEGIN block to have effect at compile time

=head2 Usage

    $object = MyClass->new(digits => '123');
    
    $object->digits    = '123';
    MyClass->digits    = '123';  # same thing
    
    $object->digits('123');      # old way supported
    
    $d = $object->digits;     # $d == 123
    $d = $MyClass::digits     # $d == 123
    
    undef $object->digits        # $object->digits == 10 (default)
    
    # these would croak
    $object->digits    = "xyz";
    MyClass->digits    = "xyz";

    # this will bypass the accessor whithout croaking
    $MyClass::digits   = "xyz";

=head1 DESCRIPTION

This pragma easily implements lvalue accessor methods for the properties of your Class (I<lvalue> means that you can create a reference to it, assign to it and apply a regex to it; see also L<KNOWN ISSUE>), which are very efficient function templates that your modules may import at compile time. "This technique saves on both compile time and memory use, and is less error-prone as well, since syntax checks happen at compile time." (quoted from "Function Templates" in the F<perlref> manpage).

You can completely avoid to write the accessor by just declaring the names and eventually the default value, validation code and other option of your properties.

The accessor method creates a scalar in the class that implements it (e.g. $Class::any_property) and sets/gets it using the options you set.

This module allows also "lazy" data computing (see the C<default> option).

B<IMPORTANT NOTE>: Since the version 1.7 the options are ignored if you access the underlaying scalar without using the accessor, so you can directly access it when you need to bypass the options.  

=head2 Package, Class or Object properties?

The main difference between  C<Packages::props>, C<Object::props> and C<Class::props> is the underlaying scalar that holds the value of the property.

Look at this example:

   package BaseClass;
   use Object::props  'an_object_prop';
   use Class::props   'a_class_prop';
   use Package::props 'a_package_prop';
   
   use Class::constr;
   
   package SubClass;
   our @ISA = 'BaseClass';
   
   package main;
   $obj = SubClass->new;
   
   # object
   $obj->an_object_prop;        # accessor callable through the object
   $obj->{an_object_prop};      # underlaying scalar in object $obj
   
   # class
   $obj->a_class_prop;          # accessor callable through the object
   ref($obj)->a_class_prop;     # accessor callable through the object class
   $SubClass::a_class_prop;     # underlaying scalar in class 'SubClass'
   
   # package
   $obj->a_package_prop;        # accessor callable through the object
   ref($obj)->a_package_prop;   # accessor callable through the object class
                                # accessible through @ISA
   BaseClass->a_package_prop;   # accessor callable through the package
   $BaseClass::a_package_prop;  # underlaying scalar in package 'BaseClass'

The object property is stored into the object itself, a class property is stored in a global scalar in the object class itself, while a package property is sotored in the package that implements it.

Different underlaying scalars are suitable for different usages depending on the need to access them and to inherit the defaults.

=head2 Example

   package MyClass;
   use Class::constr ;
   use Object::props 'obj_prop' ;
   use Class::props qw( class_prop1
                        class_prop2 ) ;
   
   package main ;
   my $object1 = MyClass->new( obj_prop    => 1   ,
                               class_prop1 => 11 ) ;
   my $object2 = MyClass->new( obj_prop    => 2    ,
                               class_prop2 => 22 ) ;
   
   print $object1->obj_prop    ; # would print 1
   print $$object1{obj_prop}   ; # would print 1
   
   print $object2->obj_prop    ; # would print 2
   print $$object2{obj_prop}   ; # would print 2
   
   print $object1->class_prop1 ; # would print 11
   print $object2->class_prop1 ; # would print 11
   print $MyClass::class_prop1 ; # would print 11
   
   print $object1->class_prop2 ; # would print 22
   print $object2->class_prop2 ; # would print 22
   print $MyClass::class_prop2 ; # would print 22
   
   $object2->class_prop1 = 100 ; # object method
   MyClass->class_prop2  = 200 ; # static method works as well
   
   print $object1->class_prop1 ; # would print 100
   print $object2->class_prop1 ; # would print 100
   print $object1->class_prop2 ; # would print 200
   print $object2->class_prop2 ; # would print 200

B<Note>: If you want to see some working example of this module, take a look at the source of my other distributions.

=head1 OPTIONS

=head2 name => $name

The name of the property is used as the identifier to create the accessor method, and the scalar that contains it.

Given 'my_prop' as the class property name:

    MyClass->my_prop = 10 ;  # assign 10 to $MyClass::my_prop
    MyClass->my_prop( 10 );  # assign 10 to $MyClass::my_prop
    
    # assuming $object is an object of class MyClass
    $object->my_prop = 10 ;  # assign 10 to $MyClass::my_prop
    $object->my_prop( 10 );  # assign 10 to $MyClass::my_prop
    
    # same thing if MyClass::constr is implemented
    # by the Class::constr pragma
    
    $object = MyClass->new( my_prop => 10 );

You can group properties that have the same set of option by passing a reference to an array containing the names. If you don't use any option you can pass a list of plain names as well. See L<"SYNOPSYS">.

=head2 default => $value | \&code

Use this option to set a I<default value>. If any C<validation> option is set, then the I<default value> is validated as well (the C<no_strict> option override this).

If you pass a CODE reference as the default it will be evaluated only when the property will be accessed, and only if the property has no defined value (this allows "lazy" data computing and may save some CPU); the property will be set to the result of the referenced CODE.

You can reset a property to its default value by assigning it the undef value.

=head2 no_strict  => 0 | 1

With C<no_strict> option set to a true value, the C<default> value will not be validate even if a validation option is set. Without this option the method will croak if the C<default> are not valid.

=head2 validation => \&code

You can set a code reference to validate a new value. If you don't set any C<validation> option, no validation will be done on the assignment.

In the validation code, the object or class is passed in C<$_[0]> and the value to be validated is passed in C<$_[1]> and for regexing convenience it is aliased in C<$_>.

    # web color validation
    use Class::props { name       => 'web_color'
                     , validation => sub { /^#[0-9A-F]{6}$/ }
                     } ;
    # this would croak
    $object->web_color = 'dark gray' ;

You can alse use the C<validation> code as a sort of pre_process or filter for the input values: just assign to C<$_> in the validation code in order to change the actual imput value.

    # this will uppercase all input values
    use Class::props { name       => 'uppercase_it'
                     , validation => sub { $_ = uc }
                     } ;
    # when used
    $object->uppercase_it = 'abc' ; # stored value will be 'ABC'

The validation code should return true on success and false on failure. Croak explicitly if you don't like the default error message.

=head2 post_process => \&code

You can set a code reference to transform the stored value, just before it is returned. If you don't set any C<post_process> option, no transformation will be done on the returned value, so in that case the returned value will be the same stored value.

In the post_process code, the object or class is passed in C<$_[0]> and the value to be transformed is passed in C<$_[1]>, and for regexing convenience it is aliased in C<$_>; the accessor will return the value returned from the post_process code

    # this will uppercase all output values
    use Class::props { name         => 'uppercase_it'
                     , post_process => sub { uc }
                     }
    
    # when used
    Class->uppercase_it = 'aBc'; # stored value will be 'aBc'
    print Class->uppercase_it  ; # would print 'ABC'

B<Warning>: The post_process code is ALWAYS executed in SCALAR context regardless the execution context of the accessor itself.

=head2 allowed => $re | \@res

The property is settable only by the caller sub that matches with the content of this option. The content can be a compiled RE or a simple string that will be used to check the caller. (Pass an array ref for multiple items)

    use Class::props { name    => 'restricted'
                       allowed => [ qr/::allowed_sub1$/ ,
                                    qr/::allowed_sub2$/ ]
                     }

You can however force the assignation from not matching subs by setting $Class::props::force to a true value.

=head2 protected => 0 | 1

Set this option to a true value and the property will be turned I<read-only> when used from outside its class or sub-classes. This allows you to normally read and set the property from your class but it will croak if your user tries to set it.

You can however force the protection and set the property from outside the class that implements it by setting $Class::props::force to a true value.

=head1 METHODS

=head2 add_to( package, properties )

This will add to the package I<package> the accessors for the I<properties>. It is useful to add properties in other packages.

   package Any::Package;
   Class:props->('My::Package', { name => 'any_name', ... });
   
   # which has the same effect of
   package My::Package;
   use Class::props { name => 'any_name', ... }

=head1 KNOWN ISSUE

Due to the perl bug #17663 I<(Perl 5 Debugger doesn't handle properly lvalue sub assignment)>, you must know that under the B<-d> switch the lvalue sub assignment will not work, so your program will not run as you expect.

In order to avoid the perl-bug you have 3 alternatives:

=over

=item 1

patch perl itself as suggested in this post: http://www.talkaboutprogramming.com/group/comp.lang.perl.moderated/messages/13142.html (See also the cgi-builder-users mailinglist about that topic)

=item 2

use the lvalue sub assignment (e.g. C<< $s->any_property = 'something' >>) only if you will never need B<-d>

=item 3

if you plan to use B<-d>, use only standard assignments (e.g. C<< $s->any_property('something') >>)

=back

Maybe a next version of perl will fix the bug, or maybe lvalue subs will be banned forever, meanwhile be careful with lvalue sub assignment.

=head1 SUPPORT and FEEDBACK

If you need support or if you want just to send me some feedback or request, please use this link: http://perl.4pro.net/?Class::props.

=head1 AUTHOR and COPYRIGHT

© 2004-2005 by Domizio Demichelis.

All Rights Reserved. This module is free software. It may be used, redistributed and/or modified under the same terms as perl itself.

=head1 CREDITS

Thanks to Juerd Waalboer (http://search.cpan.org/author/JUERD) that with its I<Attribute::Property> inspired the creation of this distribution.

=cut
