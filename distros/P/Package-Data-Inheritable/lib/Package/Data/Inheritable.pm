use warnings;
use strict;
use 5.006_000;   # Perl >=5.6.0  we need 'our' and other stuff

package Package::Data::Inheritable;
use base qw( Exporter );

use Carp;

our $VERSION = '0.05';


# This method carries out the actual package variable inheritance via export
# <$class>   Is the package/class which is exporting
# <$caller>  Is the package/class into which we're exporting
# <@symbols> Is the list of symbols requested for import.
#            This does not make sense for this module since we do not export
#            syms, we rather propagate to our children classes and they
#            should not be able to control what to inherit
sub inherit {
    my ($class, @symbols) = @_;
    croak __PACKAGE__ . "::inherit: Extra params specified. (@symbols)" if @symbols;

    my ($caller, $file, $line) = caller;
    no strict "refs";

    # propagate inherited fields up to our caller
    my @inherited;
    {
        # collect inherited fields from all superclasses
        my @inherited = $class->_get_inherited_from_parent();
        # ... and add them to those that this class wants to make inheritable
        push @{$class ."::EXPORT_INHERIT"}, @inherited;

        # and now push onto EXPORT_OK everything we want to be inheritable
        push @{$class ."::EXPORT_OK"}, @{$class ."::EXPORT_INHERIT"};
    }
    # make Exporter export our INHERITANCE fields together with the usual @EXPORT
    push @symbols, (@inherited, @{$class ."::EXPORT_INHERIT"});
    push @symbols, @{$class ."::EXPORT"};

    # handle derived class (our caller) overriden fields
    foreach my $overriden (@{$caller .'::EXPORT_INHERIT'}) {
        @symbols = grep { $_ ne $overriden } @symbols;
    }

    $class->export_to_level(1, $class, @symbols);
}


# static method
# Make a static field inheritable by adding it to @EXPORT_INHERIT
sub pkg_inheritable {
    my ($callpkg, $symbol, $value) = @_;
    ref $callpkg and croak "pkg_inheritable: called on a reference: $callpkg";

    no strict "refs";
    my $export_ok = \@{"${callpkg}::EXPORT_INHERIT"};
    croak "pkg_inheritable: trying to redefine symbol '$symbol' in package $callpkg"
        if grep { $_ eq $symbol } @$export_ok;

    $symbol =~ s/^(\W)// or croak "pkg_inheritable: no sigil in symbol '$symbol'";
    my $sigil = $1;
    my $qualified_symbol = "${callpkg}::$symbol";

    no strict 'vars';
    *pkg_stash = *{"${callpkg}::"};

    # install in the caller symbol table a new symbol
    # this will override any already existing one
    *$qualified_symbol =
        $sigil eq '&' ? \&$value :
        $sigil eq '$' ? \$value  :
        $sigil eq '@' ? \@$value :
        $sigil eq '%' ? \%$value :
        $sigil eq '*' ? \*$value :
        do { Carp::croak("Can't install symbol: $sigil$symbol") };

    push @$export_ok, "$sigil$symbol";
}

# static method
# Make a static field inheritable by adding it to @EXPORT_INHERIT
# make it const if it's a scalar, croak otherwise
sub pkg_const_inheritable {
    my ($callpkg, $symbol, $value) = @_;
    ref $callpkg and croak "pkg_const_inheritable: called on a reference: $callpkg";

    no strict "refs";
    my $export_ok = \@{"${callpkg}::EXPORT_INHERIT"};
    croak "pkg_const_inheritable: trying to redefine symbol '$symbol' in package $callpkg"
        if grep { $_ eq $symbol } @$export_ok;

    $symbol =~ s/^(\W)// or croak "pkg_const_inheritable: no sigil in symbol '$symbol'";
    my $sigil = $1;
    my $qualified_symbol = "${callpkg}::$symbol";
    croak "pkg_const_inheritable: not a scalar, cannot make const symbol '$symbol'"
        if $sigil ne '$';

    no strict 'vars';
    *pkg_stash = *{"${callpkg}::"};

    # install in the caller symbol table a new symbol
    # this will override any already existing one
    eval "*$qualified_symbol = \\'$value'";
    croak "Cannot install constant symbol $qualified_symbol: $@" if $@;

    push @$export_ok, "$sigil$symbol";
}


# collect inherited fields from all superclasses
sub _get_inherited_from_parent {
    my ($class) = @_;

    no strict "refs";
    my @inherited;
    foreach my $super (@{$class . "::ISA"}) {
        push @inherited, @{$super . "::EXPORT_INHERIT"};
    }
    return @inherited;
}



=head1 NAME

Package::Data::Inheritable - Inheritable and overridable package data/variables

=head1 VERSION

Version 0.05

=cut

=head1 SYNOPSIS

  use strict;
  package Base;
  use base qw( Package::Data::Inheritable );

  BEGIN {
      Base->pkg_inheritable('$foo' => 'a not so ordinary package variable');
  }

  print $foo;


  package Derived;
  use base qw( Base );

  BEGIN {
      Derived->pkg_inheritable('$bar');
      Derived->pkg_inheritable('@baz' => [1,2,3]);

      inherit Base;
  }

  print $foo,
        @baz, $bar;

=head1 DESCRIPTION

This module tries to deliver inheritable package data (variables) with a reasonably
convenient interface.
After declaration the variables can be used like ordinary package variables. Most
importantly, these variables can be inherited by derived classes (packages) by
calling the inherit() method.
If a derived class doesn't call inherit() it will still be able to define its
variables and make them inheritable by its subclasses.
 Scalar variables can be declared constant.

Within your class (hierarchy) code you will benefit from compiler checks on those
variables. The overall result is close to real class data members.
Of course you can wrap your variables in accessor/mutators methods as you need.

The semantic provided mimics the class data members in languages like C++ and Java.
When you assign to an inherited variable within a derived class, every class
in the inheritance hierarchy will see the new value. If you want to override a
variable you must redeclare it explicitly.

To declare inheritable variables two interfaces are provided:
  a method interface via pkg_inheritable() and pkg_const_inheritable().
  an Exporter-like interface, via the array @EXPORT_INHERIT.

Inheriting always requires invoking the inherit() method.
 The variable visibility (scope) depends on the interface you used. If you use
the Exporter-like interface, variables will be declared via our, while if you
use the method interface it will be like you had imported those variables.
The Exporter like interface does not currently support constants.

=head1 EXPORT

Package::Data::Inheritable is an Exporter, inheriting from it (via use base or @ISA)
will make your class an Exporter as well.
The package variable @EXPORT_INHERIT contains the symbols that will be inherited
and @EXPORT_OK will always contain at least those symbols.

The Exporter like interface allows your class to set @EXPORT_INHERIT in pretty
much the same way you would set @EXPORT and @EXPORT_OK with Exporter.


=head1 DEFINING AND INHERITING VARIABLES


=head2 Method interface

  BEGIN {
      Class->pkg_inheritable('$scalar');
      Class->pkg_inheritable('@array' => [1,2,3]);
      Class->pkg_const_inheritable('$const_scalar' => 'readonly');
      inherit BaseClass;
  }

Every variable declaration must be inside a BEGIN block because there's no 'our'
declaration of that variable and we need compile time installation of that
symbol in the package symbol table. The same holds for the call to inherit(),
inherited variables must be installed at compile time.


=head2 Exporter like interface

  BEGIN {
      our @EXPORT_INHERIT = qw( $scalar @array );
      inherit BaseClass;
  }
  our $scalar;
  our @array = (1,2,3);

If you're defining variables, none of which is overriding a parent package's one
(see overriding below), it's not required to define @EXPORT_INHERIT inside
a BEGIN block.
You will declare the variables via 'our' in the usual way.
The actual our declaration of each variable must be outside the BEGIN block in
any case because of 'our' scoping rules.


=head1 OVERRIDING VARIABLES

In order to override a parent variable you just have to redefine that
variable in the current package.
When you use the Exporter like interface and you want to override a parent
package variable you must define @EXPORT_INHERIT before calling inherit(),
otherwise inherit() will not find any of your overrides.
  On the contrary, if you use the pkg_inheritable() method interface, ordering
doesn't matter.


=head1 METHODS

=head2 inherit

Make the caller package inherit variables from the package on which the method is invoked.
e.g.

    package Derived;
      BEGIN {
        inherit Base;
        # or
        Base->inherit;
      }

will make Derived inherit variables from Base.

This method must be invoked from within a BEGIN block in order to
install the inherited variables at compile time.
Otherwise any attempt to refer to those package variables in your code will
trigger a 'Global symbol "$yourvar" requires explicit package name' error.

=cut


=head2 pkg_inheritable

    Class->pkg_inheritable('$variable_name');
    Class->pkg_inheritable('$variable_name' => $value);
    Class->pkg_inheritable('@variable_name' => ['value1','value2']);

Method interface to declare/override an inheritable package variable.
$variable_name will be installed in the package symbol table like it had
been declared with use 'vars' and then initialized.
The variable will be inherited by packages invoking inherit() on class 'Class'.

=head2 pkg_const_inheritable

    Class->pkg_const_inheritable('$variable_name');
    Class->pkg_const_inheritable('$variable_name' => $value);
    Class->pkg_const_inheritable('@variable_name' => ['value1','value2']);

Method interface to declare/override an inheritable constant package variable.
It is similar to pkg_inheritable but the variable will be made constant. Only
constant scalars are supported.
It's possible to override a parent package var that was constant and make it
non constant, as well as the opposite.

=cut

=head1 EXAMPLES

=head2 Inheriting and overriding

   # set up Base class with the method interface:
    use strict;
    package Base;
    use base qw( Package::Data::Inheritable );
   
    BEGIN {
        Base->pkg_inheritable('$scalar1' => 'Base scalar');
        Base->pkg_inheritable('$scalar2' => 'Base scalar');
        Base->pkg_inheritable('@array'   => [1,2,3]);
    }
   
    print $scalar1;         # prints "Base scalar"
    print @array;           # prints 123
   
   # set up Derived class with the Exporter like interface:
    package Derived;
    use base qw( Base );
   
    BEGIN {
        # declare our variables and overrides *before* inheriting
        our @EXPORT_INHERIT = qw( $scalar2 @array );
   
        inherit Base;
    }
    our @array = (2,4,6);
    our $scalar2 = "Derived scalar";
   
    print $scalar2;             # prints "Derived scalar"
    print $Base::scalar2;       # prints "Base scalar"
    print @array;               # prints 246
    print $scalar1;             # prints "Base scalar"

    $scalar1 = "Base and Derived scalar";
    print $Base::scalar1,       # prints "Base and Derived scalar" twice
          $Derived::scalar1;


=head2 Accessing and wrapping data members

Be aware that when you qualify your variables with the package prefix you're
giving up compiler checks on those variables. In any case, direct access to
class data from outside your classes is better avoided.

    use strict;
    package Base;
    use base qw( Package::Data::Inheritable );

    BEGIN {
        Base->pkg_inheritable('$_some_scalar'  => 'some scalar');
        Base->pkg_inheritable('$public_scalar' => 'public scalar');
    }

    sub new { bless {}, shift }

    # accessor/mutator example
    sub some_scalar {
        my $class = shift;
        if (@_) {
           my $val = shift;
           # check $val, caller etc. or croak...
           $_some_scalar = $val;
        }
        return $_some_scalar;
    }

    sub do_something {
        my ($self) = @_;
        print $public_scalar;           # ok
        print $Base::public_scalar;     # ok, but dangerous

        print $publicscalar;            # compile error

        print $Base::publicscalar;      # variable undefined but no compile
                                        #  error because of package prefix
    }

    package Derived;
    use base qw( Base );
    BEGIN {
        inherit Base;
    }
  
  And then in some user code:

    use strict;
    use Base;
    use Derived;
    
    print $Base::public_scalar;     # prints "public scalar". Discouraged.
    print Base->some_scalar;        # prints "some scalar"
    
    Base->some_scalar("reset!");
    my $obj = Base->new;
    print Base->some_scalar;        # prints "reset!"
    print $obj->some_scalar;        # prints "reset!"
    print Derived->some_scalar;     # prints "reset!"

    Derived->some_scalar("derived reset!");
    print Derived->some_scalar;     # prints "derived reset!"
    print Base->some_scalar;        # prints "derived reset!"


=head1 CAVEATS

The interface of this module is not stable yet.
I'm still looking for ways to reduce the amount of boilerplate code needed.
Suggestions and comments are welcome.


=head1 AUTHOR

Giacomo Cerrai, C<< <gcerrai at cpan.org> >>

=head1 BUGS

Please report any bugs or feature requests to
C<bug-package-data-inheritable at rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Package-Data-Inheritable>.
I will be notified, and then you'll automatically be notified of progress on
your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Package::Data::Inheritable

You can also look for information at:

=over 4

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Package-Data-Inheritable>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Package-Data-Inheritable>

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Package-Data-Inheritable>

=item * Search CPAN

L<http://search.cpan.org/dist/Package-Data-Inheritable>

=back

=head1 SEE ALSO

Class::Data::Inheritable,

=head1 ACKNOWLEDGEMENTS

=head1 COPYRIGHT & LICENSE

Copyright 2007 Giacomo Cerrai, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

######################################################
# TECHNICALITIES
#
# - OVERRIDING VARIABLES
#   When you use the Exporter like interface and you want to override a parent
#   package variable you must define @EXPORT_INHERIT before calling inherit(),
#   otherwise inherit() will not find any of your overrides.
#     On the contrary, if you use the pkg_inheritable() method interface, ordering
#   doesn't matter. If you define your overrides before calling inherit,
#   @EXPORT_INHERIT will already be defined (being set by the method calls).
#   If you call inherit and after that you call pkg_inheritable(), this will take
#   care of performing the overriding. Do not fit well in the POD but they're still useful

1; # End of Package::Data::Inheritable
