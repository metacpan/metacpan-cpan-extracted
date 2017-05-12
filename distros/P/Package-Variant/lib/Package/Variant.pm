package Package::Variant;

use strictures 2;
use Import::Into;
use Module::Runtime qw(require_module);
use Carp qw(croak);

our $VERSION = '1.003002';

$VERSION = eval $VERSION;

our %Variable;

my $sanitize_importing = sub {
  my ($me, $spec) = @_;
  return []
    unless defined $spec;
  my @specced =
    not(ref $spec)
      ? ($spec)
    : (ref($spec) eq 'ARRAY')
      ? (@$spec)
    : (ref($spec) eq 'HASH')
      ? (map {
          croak qq{The import argument list for '$_' is not an array ref}
            unless ref($spec->{$_}) eq 'ARRAY';
          ($_ => $spec->{$_});
        } sort keys %$spec)
    : croak q{The 'importing' option has to be either a hash or array ref};
  my @imports;
  my $arg_count = 1;
  while (@specced) {
    my $key = shift @specced;
    croak qq{Value $arg_count in 'importing' is not a package string},
      $arg_count
      unless defined($key) and not(ref $key);
    $arg_count++;
    my $import_args =
      (not(@specced) or (defined($specced[0]) and not ref($specced[0])))
        ? []
      : (ref($specced[0]) eq 'ARRAY')
        ? do { $arg_count++; shift @specced }
      : croak(
            qq{Value $arg_count for package '$key' in 'importing' is not}
          . qq{ a package string or array ref}
        );
    push @imports, [$key, $import_args];
  }
  return \@imports;
};

my $sub_namer = eval {
  require Sub::Name; sub { shift if @_ > 2; Sub::Name::subname(@_) }
} || sub { $_[-1] };

sub import {
  my $variable = caller;
  my $me = shift;
  my $last = (split '::', $variable)[-1];
  my $anon = 'A000';
  my %args = @_;
  no strict 'refs';
  $Variable{$variable} = {
    anon => $anon,
    args => {
      %args,
      importing => $me->$sanitize_importing($args{importing}),
    },
    subs => {
      map +($_ => sub {}), @{$args{subs}||[]},
    },
  };
  *{"${variable}::import"} = sub {
    my $target = caller;
    my (undef, %arg) = @_;
    my $as = defined($arg{as}) ? $arg{as} : $last;
    no strict 'refs';
    *{"${target}::${as}"} = sub {
      $me->build_variant_of($variable, @_);
    };
  };
  my $subs = $Variable{$variable}{subs};
  foreach my $name (keys %$subs) {
    *{"${variable}::${name}"} = sub {
      goto &{$subs->{$name}}
    };
  }
  *{"${variable}::install"} = sub {
    goto &{$Variable{$variable}{install}};
  };
  *{"${variable}::build_variant"} = sub {
    shift;
    $me->build_variant_of($variable, @_);
  };
}

sub build_variant_package_name {
  my ($me, $variable, @args) = @_;
  if ($variable->can('make_variant_package_name')) {
    return $variable->make_variant_package_name(@args);
  }
  return "${variable}::_Variant_".++$Variable{$variable}{anon};
}

sub build_variant_of {
  my ($me, $variable, @args) = @_;
  my $variant_name = $me->build_variant_package_name($variable, @args);
  foreach my $to_import (@{$Variable{$variable}{args}{importing}}) {
    my ($pkg, $args) = @$to_import;
    require_module $pkg;
    eval q{ BEGIN { $pkg->import::into($variant_name, @{$args}) }; 1; }
      or die $@;
  }
  my $subs = $Variable{$variable}{subs};
  local @{$subs}{keys %$subs} = map $variant_name->can($_), keys %$subs;
  local $Variable{$variable}{install} = sub {
    my $full_name = "${variant_name}::".shift;

    my $ref = $sub_namer->($full_name, @_);
    
    no strict 'refs';
    *$full_name = $ref;
  };
  $variable->make_variant($variant_name, @args);
  return $variant_name;
}

1;

__END__

=head1 NAME

Package::Variant - Parameterizable packages

=head1 SYNOPSIS

Creation of anonymous variants:

  # declaring a variable Moo role
  package My::VariableRole::ObjectAttr;
  use strictures 2;
  use Package::Variant
    # what modules to 'use'
    importing => ['Moo::Role'],
    # proxied subroutines
    subs => [ qw(has around before after with) ];

  sub make_variant {
    my ($class, $target_package, %arguments) = @_;
    # access arguments
    my $name = $arguments{name};
    # use proxied 'has' to add an attribute
    has $name => (is => 'lazy');
    # install a builder method
    install "_build_${name}" => sub {
      return $arguments{class}->new;
    };
  }

  # using the role
  package My::Class::WithObjectAttr;
  use strictures 2;
  use Moo;
  use My::VariableRole::ObjectAttr;

  with ObjectAttr(name => 'some_obj', class => 'Some::Class');

  # using our class
  my $obj = My::Class::WithObjectAttr->new;
  $obj->some_obj; # returns a Some::Class instance

And the same thing, only with named variants:

  # declaring a variable Moo role that can be named
  package My::VariableRole::ObjectAttrNamed;
  use strictures 2;
  use Package::Variant importing => ['Moo::Role'],
    subs => [ qw(has around before after with) ];
  use Module::Runtime 'module_notional_filename'; # only if you need protection

  # this method is run at variant creation time to determine its custom
  # package name. it can use the arguments or do something entirely else.
  sub make_variant_package_name {
    my ($class, $package, %arguments) = @_;
    $package = "Private::$package"; # you can munge the input here if you like
    # only if you *need* protection
    die "Won't clobber $package" if $INC{module_notional_filename $package};
    return $package;
  }

  # same as in the example above, except for the argument list. in this example
  # $package is the user input, and
  # $target_package is the actual package in which the variant gets installed
  sub make_variant {
    my ($class, $target_package, $package, %arguments) = @_;
    my $name = $arguments{name};
    has $name => (is => 'lazy');
    install "_build_${name}" => sub {return $arguments{class}->new};
  }

  # using the role
  package My::Class::WithObjectAttr;
  use strictures 2;
  use Moo;
  use My::VariableRole::ObjectAttrNamed;

  # create the role under a specific name
  ObjectAttrNamed "My::Role" => (name => 'some_obj', class => 'Some::Class');
  # and use it
  with "Private::My::Role";

  # using our class
  my $obj = My::Class::WithObjectAttr->new;
  $obj->some_obj; # returns a Some::Class instance

=head1 DESCRIPTION

This module allows you to build a variable package that contains a package
template and can use it to build variant packages at runtime.

Your variable package will export a subroutine which will build a variant
package, combining its arguments with the template, and return the name of the
new variant package.

The implementation does not care about what kind of packages it builds, be they
simple function exporters, classes, singletons or something entirely different.

=head2 Declaring a variable package

There are two important parts to creating a variable package. You first
have to give C<Package::Variant> some basic information about what kind of
variant packages you want to provide, and how. The second part is implementing a
method which builds the components of the variant packages that use the user's
arguments or cannot be provided with a static import.

=head3 Setting up the environment for building variants

When you C<use Package::Variant>, you pass along some arguments that
describe how you intend to build your variants.

  use Package::Variant
    importing => { $package => \@import_arguments, ... },
    subs      => [ @proxied_subroutine_names ];

The L</importing> option needs to be a hash or array reference with
package names to be C<use>d as keys, and array references containing the
import arguments as values. These packages will be imported into every new
variant package, to provide static functionality of the variant packages and to
set up every declarative subroutine you require to build variants package
components. The next option will allow you to use these functions. See
L</importing> for more options. You can omit empty import argument lists when
passing an array reference.

The L</subs> option is an array reference of subroutine names that are
exported by the packages specified with L</importing>. These subroutines
will be proxied from your variable package to the variant to be
generated.

With L</importing> initializing your package and L</subs> declaring what
subroutines you want to use to build a variant, you can now write a
L</make_variant> method building your variants.

=head3 Declaring a method to produce variants

Every time a user requests a new variant, a method named L</make_variant>
will be called with the name of the target package and the arguments from
the user.

It can then use the proxied subroutines declared with L</subs> to
customize the variant package. An L</install> subroutine is exported as well
allowing you to dynamically install methods into the variant package. If these
options aren't flexible enough, you can use the passed name of the variant
package to do any other kind of customizations.

  sub make_variant {
    my ($class, $target, @arguments) = @_;
    # ...
    # customization goes here
    # ...
  }

When the method is finished, the user will receive the name of the new variant
package you just set up.

=head2 Using variable packages

After your variable package is L<created|/Declaring a variable package>
your users can get a variant generator subroutine by simply importing
your package.

  use My::Variant;
  my $new_variant_package = Variant(@variant_arguments);
  # the variant package is now fully initialized and used

You can import the subroutine under a different name by specifying an C<as>
argument.

=head2 Dynamic creation of variant packages

For regular uses, the L<normal import|/Using variable packages> provides
more than enough flexibility. However, if you want to create variants of
dynamically determined packages, you can use the L</build_variant_of>
method.

You can use this to create variants of other packages and pass arguments
on to them to allow more modular and extensible variants.

=head1 OPTIONS

These are the options that can be passed when importing
C<Package::Variant>. They describe the environment in which the variants
are created.

  use Package::Variant
    importing => { $package => \@import_arguments, ... },
    subs      => [ @proxied_subroutines ];

=head2 importing

This option is a hash reference mapping package names to array references
containing import arguments. The packages will be imported with the given
arguments by every variant before the L</make_variant> method is asked
to create the package (this is done using L<Import::Into>).

If import order is important to you, you can also pass the C<importing>
arguments as a flat array reference:

  use Package::Variant
    importing => [ 'PackageA', 'PackageB' ];

  # same as
  use Package::Variant
    importing => [ 'PackageA' => [], 'PackageB' => [] ];

  # or
  use Package::Variant
    importing => { 'PackageA' => [], 'PackageB' => [] };

The import method will be called even if the list of import arguments is
empty or not specified,

If you just want to import a single package's default exports, you can
also pass a string instead:

  use Package::Variant importing => 'Package';

=head2 subs

An array reference of strings listing the names of subroutines that should
be proxied. These subroutines are expected to be installed into the new
variant package by the modules imported with L</importing>. Subroutines
with the same name will be available in your variable package, and will
proxy through to the newly created package when used within
L</make_variant>.

=head1 VARIABLE PACKAGE METHODS

These are methods on the variable package you declare when you import
C<Package::Variant>.

=head2 make_variant

  Some::Variant::Package->make_variant( $target, @arguments );

B<You need to provide this method.> This method will be called for every
new variant of your package. This method should use the subroutines
declared in L</subs> to customize the new variant package.

This is a class method receiving the C<$target> package and the
C<@arguments> defining the requested variant.

=head2 make_variant_package_name

  Some::Variant::Package->make_variant_package_name( @arguments );

B<You may optionally provide this method.> If present, this method will be
used to determine the package name for a particular variant being constructed.

If you do not implement it, a unique package name something like

  Some::Variant::Package::_Variant_A003

will be created for you.

=head2 import

  use Some::Variant::Package;
  my $variant_package = Package( @arguments );

This method is provided for you. It will allow a user to C<use> your
package and receive a subroutine taking C<@arguments> defining the variant
and returning the name of the newly created variant package.

The following options can be specified when importing:

=over

=item * B<as>

  use Some::Variant::Package as => 'Foo';
  my $variant_package = Foo(@arguments);

Exports the generator subroutine under a different name than the default.

=back

=head2 build_variant

  use Some::Variant::Package ();
  my $variant_package = Some::Variant::Package->build_variant( @arguments );

This method is provided for you.  It will generate a variant package
and return its name, just like the generator sub provided by
L</import>.  This allows you to avoid importing anything into the
consuming package.

=head1 C<Package::Variant> METHODS

These methods are available on C<Package::Variant> itself.

=head2 build_variant_of

  my $variant_package = Package::Variant
    ->build_variant_of($variable_package, @arguments);

This is the dynamic method of creating new variants. It takes the
C<$variable_package>, which is a pre-declared variable package, and a set
of C<@arguments> passed to the package to generate a new
C<$variant_package>, which will be returned.

=head2 import

  use Package::Variant @options;

Sets up the environment in which you declare the variants of your
packages. See L</OPTIONS> for details on the available options and
L</EXPORTS> for a list of exported subroutines.

=head1 EXPORTS

Additionally to the proxies for subroutines provided in L</subs>, the
following exports will be available in your variable package:

=head2 install

  install($method_name, $code_reference);

Installs a method with the given C<$method_name> into the newly created
variant package. The C<$code_reference> will be used as the body for the
method, and if L<Sub::Name> is available the coderef will be named. If you
want to name it something else, then use:

  install($method_name, $name_to_use, $code_reference);

=head1 AUTHOR

mst - Matt S. Trout (cpan:MSTROUT) <mst@shadowcat.co.uk>

=head1 CONTRIBUTORS

phaylon - Robert Sedlacek (cpan:PHAYLON) <r.sedlacek@shadowcat.co.uk>

haarg - Graham Knop (cpan:HAARG) <haarg@haarg.org>

=head1 COPYRIGHT

Copyright (c) 2010-2012 the C<Package::Variant> L</AUTHOR> and
L</CONTRIBUTORS> as listed above.

=head1 LICENSE

This library is free software and may be distributed under the same
terms as perl itself.

=cut
