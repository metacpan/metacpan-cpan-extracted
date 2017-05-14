package Class::constr ;
$VERSION = 2.21 ;
use 5.006_001 ;
use strict ;

# This file uses the "Perlish" coding style
# please read http://perl.4pro.net/perlish_coding_style.html

; use Carp
; $Carp::Internal{+__PACKAGE__}++


; sub import
   { my ($pkg, @args) = @_
   ; my $callpkg = caller
   ; $args[0] ||= {}
   ; foreach my $constr ( @args )
      { my $n = $$constr{name} || 'new'
      ; $$constr{init} &&= [ $$constr{init} ]
                           unless ref $$constr{init} eq 'ARRAY'
      ; no strict 'refs'
      ; *{$callpkg.'::'.$n}
        = sub
           { &{$$constr{pre_process}} if defined $$constr{pre_process}
           ; my $c = shift
           ; my %props = ref $_[0] eq 'HASH' ? %{$_[0]} : @_
           ; my $class = ref($c) || $c
           ; my $s = bless {}, $class
           ; my $default_props = {}
           ; if (my $cdef = $$constr{default})
              { $default_props =  ref $cdef eq 'HASH' && $cdef
                               || ref $cdef eq 'CODE' && $s->$cdef(%props)
                               || not (ref $cdef)     && $s->$cdef(%props)
              ; ref $default_props eq 'HASH' or croak
                "Invalid default option for '$n' ($default_props), died"
              }
           # Values passed to the constructor   (%props)
           # will override copied values,       (%$c)
           # which will override default values (%$default_props)
           ; %props = ( %$default_props
                       , $$constr{copy} && ref $c ? %$c : ()
                       , %props
                       )
           # Set the initial values for the new object
           ; while ( my ($p, $v) = each %props )
              { if (my $a = $s->can($p))      # if accessor available, use it
                 { $s->$a( $v )
                 }
                else
                 { croak "No such property '$p', died"
                         unless $$constr{no_strict}
                 ; if ( $$constr{skip_autoload} )
                    { $$s{$p} = $v
                    }
                   else
                    { eval { $s->$p( $v ) }       # try AUTOLOAD
                    ; $@ && do{ $$s{$p} = $v }    # no strict so just set it
                    }
                 }
              }
           # Execute any initializer methods
           ; if ( $$constr{init} )
              { foreach my $m ( @{$$constr{init}} )
                 # any initializer can cancel construction by undefining the
                 # object or returning a Class::Error object (false)
                 # If this happens, no need to continue
                 { last unless $s
                 ; $s->$m(%props)
                 }
              }
           ; $s
           }#END sub
      }#END for $constr
   }#END import


; 1

__END__

=pod

=head1 NAME

Class::constr - Pragma to implement constructor methods

=head1 VERSION 2.21

Included in OOTools 2.21 distribution.

The latest versions changes are reported in the F<Changes> file in this distribution.

The distribution includes:

=over

=item * Class::constr

Pragma to implement constructor methods

=item * Class::props

Pragma to implement lvalue accessors with options

=item * Class::groups

Pragma to implement groups of properties accessors with options

=item * Class::Error

Delayed checking of object failure

=item * Object::props

Pragma to implement lvalue accessors with options

=item * Object::groups

Pragma to implement groups of properties accessors with options

=item * Class::Util

Class utility functions

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
    
    # with all the possible options
    use Class::constr { name        => 'new_object' ,
                        pre_process => \&change_input,
                        default     => { propA => 'something' },
                        init        => [ qw( init1 init2 ) ] ,
                        copy        => 1
                        no_strict   => 1
                      } ;
                    
    # init1 and init2 will be called at run-time

=head2 Usage

    # creates a new object and eventually validates
    # the properties if any validation property option is set
    my $object = MyClass->new(digits => '123');

=head1 DESCRIPTION

This pragma easily implements constructor methods for your class, which are very efficient function templates that your modules may imports at compile time. "This technique saves on both compile time and memory use, and is less error-prone as well, since syntax checks happen at compile time." (quoted from "Function Templates" in the F<perlref> manpage).

Use it with C<Class::props> and C<Object::props> to automatically validate the input passed with C<new()>, or use the C<no_strict> option to accept unknown properties as well.

You can completely avoid to write the constructor mehtod by just using this pragma and eventually declaring the name and the init methods to call.

=head2 Examples

If you want to see some working example of this module, take a look at the source of my other distributions.

=head1 OPTIONS

=head2 name => $name

The name of the constructor method. If you omit this option the 'new' name will be used by default.

=head2 no_strict => 0 | 1

With C<no_strict> option set to a true value, the constructor method accepts and sets also unknown properties (i.e. not predeclared). You have to access the unknown properties without any accessor method. All the other options will work as expected. Without this option the constructor will croak if any property does not have an accessor method.

=head2 skip_autoload => 0 | 1

This option might be useful only if C<no_strict> is true, and your package defines an C<AUTOLOAD> sub. A true value will not try to set any unknown property by using the C<AUTOLOAD> sub: it will just set the value (C<$$s{your_property} = $v>) directly.

=head2 pre_process => \&$code

You can set a code reference to preprocess @_.

The original C<@_> is passed to the referenced pre_process CODE. Modify C<@_> in the CODE to change the actual input value.

    # This code will transform the @_ on input
    # if it's passed a ref to an ARRAY
    # [ qw|a b c| ] will become
    # ( a=>'a', b=>'b', c=>'c')
    
    use Class::constr
        { name       => 'new'
        , pre_process=> sub
                         { if ( ref $_[1] eq 'ARRAY' )
                            { $_[1] = { map { $_=>$_ } @{$_[1]} }
                            }
                         }
        }

=head2 default => \%props | \&$method

Use this option to supply any default properties to the constructor. Setting a default is very similar to pass the properties/values pairs to the constructor, but properties passed as arguments will override defaults.

You can set the default to a HASH reference or to a method name or method reference. In case you use a method, it will be called at runtime with the blessed object passed in C<$_[0]> and the other properties in the remaining C<@_>; it must return a HASH reference.

=head2 init => $method | \@methods

Use this option if you want to call other methods in your class to further initialize the object. You can use methods names or method references.

After the assignation and validation of the properties (i.e. those passed to the constructor, the default properties and the copied properties), the initialization methods in the C<init> option will be called. Each init method will receive the blessed object passed in C<$_[0]> and the other properties in the remaining C<@_>.

Any C<init> method can cancel construction of the object by undefining C<$_[0]>. This will cause the constructor to return undef. If you prefer, you can explicitly C<croak> from your init method.

   
   use Class::constr
      { name       => 'new'
      , init       => 'too_many'
      }
   ;
   sub too_many
      { if ( $MyClass::num_instances > $MyClass::max_instances)
         { $_[0] = undef # Do not allow new object to be returned
         }
        else
         { $MyClass::num_instances++
         }
      }
   

=head2 copy => 0 | 1

If this option is set to a true value, the constructor will be a "copy constructor". Copy constructors allow you to create a new object that inherits data from an existing object. Properties passed to the constructor will overwrite copied properties, that overwrite the default properties, and C<init> methods will also have a chance to manipulate the values.

B<Warning:> The copy constructor will only perform a I<shallow> copy, which means that after a copy any references stored in properties will point to the I<same> variable in I<both> objects (the objects will share a single variable instead of each having its own private copy). If you don't want this behavior, you should reset these properties in your C<init> method. Properties created by the Object::groups pragma are effected by this. Such properties should be explicitly set to C<undef> in your C<init> method for sane behavior.

Copy constructors may also be called as traditional class method constructors, but of course there will be no values to be copied into the new object. Generally, you will want to have a normal constructor to use when you don't need the copy functionality.

   package My::Class;
   use Class::constr
      ( { name       => 'new'
        , init       => '_init'
        }
      , { name       => 'copy_me'
        , copy       => 1
        , init       => '_init_copy' # Special init undefs properties
                                     # containing shared references
        }
      )
   
   # Then in your program somewhere
   my $obj = My::Class->new( property => 1); 
   my $copy = $obj->copy_me(); # $copy->property == 1
   

=head1 SUPPORT and FEEDBACK

If you need support or if you want just to send me some feedback or request, please use this link: http://perl.4pro.net/?Class::constr.

=head1 AUTHOR and COPYRIGHT

© 2004-2005 by Domizio Demichelis.

All Rights Reserved. This module is free software. It may be used, redistributed and/or modified under the same terms as perl itself.

=head1 CREDITS

Thanks to Juerd Waalboer (L<http://search.cpan.org/author/JUERD>) that with its I<Attribute::Property> inspired the creation of this distribution.

Thanks to Vince Veselosky (L<(http://search.cpan.org/author/VESELOSKY)>) for his patches and improvement.

=cut
