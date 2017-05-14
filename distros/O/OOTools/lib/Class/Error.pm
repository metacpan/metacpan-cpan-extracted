package Class::Error ;
$VERSION = 2.21 ;
use strict ;

# This file uses the "Perlish" coding style
# please read http://perl.4pro.net/perlish_coding_style.html

; use Carp
; $Carp::Internal{+__PACKAGE__}++

; use overload bool     => sub { $_[0][2] }
             , fallback => 1

; sub new     # class, error, errnum, false
   { my $c = shift
   ; $_[2] and croak "'$_[2]' is not a false value, died"
   ; ($Class::Error::error, $Class::Error::errnum) = @_
   ; bless \ @_, $c
   }
   
; sub error  { ref $_[0] ? $_[0][0] : $Class::Error::error }
; sub errnum { ref $_[0] ? $_[0][1] : $Class::Error::errnum }
   
; sub AUTOLOAD { $_[0] }

; 1

__END__

=pod

=head1 NAME

Class::Error - Delayed checking of object failure

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

  package My::Package ;
  
  use Class::Error ;
  
  $undef_obj = Class::Error->new($error, $errnum)
  
  $undef_obj->any_method ;              # won't die and will return $undef_obj
  print 'is false' unless $undef_obj ;  # 'is false'
  print "$undef_obj" ;                  # '' with warning "Use of uninitialized
                                        # value in string..."
  print $undef_obj->any_method ;        # '' with same warning
  
  $empty_obj = Class::Error->new($error, $errnum, '')
  
  $empty_obj->any_method ;              # won't die and will return $empty_obj
  print 'is false' unless $empty_obj ;  # 'is false'
  print "$empty_obj" ;                  # '' no warnings
  print $empty_obj->any_method ;        # '' no warnings

=head1 DESCRIPTION

You can use this module to return a Class::Error object instead of a simple false value (e.g. when a sub or a property may return an object OR the undef value on failure).

That feature allows to check on the object itself, or delay the checking after calling any method on the object.

   $obj = AnyClass->new or die $obj->error
   AnyClass->new->any_method or die Class::Error->error  # static

For example, compare the difference between the behaviour of C<obj_A> and C<obj_B> if the C<< AnyClass->new >> would return false:

   use Object::props
     ( { name    => 'obj_A',
         default => sub{ AnyClass->new or undef }
       },
       { name    => 'obj_B',
         default => sub{ AnyClass->new
                         or Class::Error->new('AnyClass->new failed') }
       }
     );
   
   # if AnyClass->new would fail (returning a false value)
   
   # this would die "Can't call method "any_method" on an undefined value..."
   $s->obj_A->any_method or do{ warn 'doing something else...';
                                do_something_else()
                              };
   # but this would execute the do{} block
   $s->obj_B->any_method or do{ warn 'doing something else...';
                                do_something_else()
                              };

=head1 METHODS

=head2 AUTOLOAD

All the methods called on the Class::Error object (regardless the arguments) return a reference to the object itself, thus allowing you to call methods on methods:

   $error_obj->any_method('a', 'b')->any_other_method...

=head1 METHODS

=head2 new ([ error [, errnum [, false]]] )

   $undef_obj = Class::Error->new($error, $errnum)       # undef
   $empty_obj = Class::Error->new($error, $errnum, '')   # empty
   $zero_obj  = Class::Error->new($error, $errnum, 0)    # 0

The constructor accepts 3 optional arguments and returns a Class::Error object.

I<error> sets the error, which could be a simple string or any other value (also stored in C<$Class::Error::error>), I<errnum> sets the error number (also stored in C<$Class::Error::errnum>) which you can retrieve with the C<error> and C<errnum> static or dynamic methods.

You can also pass a third argument (which must be false) to the new method or leave it undef: the scalar reference to the I<false> argument will be used as the object value in any contexts (internally using C<overload>).

For example, if you leave the I<false> argument as C<undef>, the Class::Error object itself is evaluated as undef in any contexts (e.g. false in boolean context like the undef value), but unlike the undef value, it is defined and allows you to call any methods on it.

B<Note>: If you want to avoid the "use of uninitialized value..." warning when you use the object itself (or the result of its methods) in string context, you can pass an empty string to the constructor, or the C<0> value for numeric context. Use that feature only if you know what you are doing, since a defined false value might make more difficult the debgging of real errors.

=head2 error

Returns the last error string passed to the new() method:

   AnyClass->new->any_method or die Class::Error->error  # static
   $result = AnyClass->new->any_method or die $result->error
   $obj = AnyClass->new or die $obj->error

=head2 errnum

Returns the last error number passed to the new() method:

   if ( Class::Error->errnum == 230 ) { .... }  # static
   if ( $obj->errnum == 230 ) { .... }

=head1 SUPPORT and FEEDBACK

If you need support or if you want just to send me some feedback or request, please use this link: http://perl.4pro.net/?Class::Error.

=head1 AUTHOR and COPYRIGHT

© 2004-2005 by Domizio Demichelis.

All Rights Reserved. This module is free software. It may be used, redistributed and/or modified under the same terms as perl itself.

=cut
