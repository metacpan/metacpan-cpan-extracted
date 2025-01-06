# NAME

Package::New - Simple base package from which to inherit

# SYNOPSIS

    package My::Package;
    use base qw{Package::New}; #provides new and initialize

# DESCRIPTION

The Package::New object provides a consistent constructor for objects.

I find that I always need these two methods in every package that I build.  I plan to use this package as the base for all of my CPAN packages. 

# RECOMMENDATIONS

## Sane defaults

I recommend that you have sane default for all of your object properties.  I recommend using code like this.

    sub myproperty {
      my $self=shift;
      $self->{"myproperty"}=shift if @_;
      $self->{"myproperty"}="Default Value" unless defined $self->{"myproperty"};
      return $self->{"myproperty"};
    }

## use strict and warnings

I recommend to always use strict, warnings and our version.

    package My::Package;
    use base qw{Package::New};
    use strict;
    use warnings;
    our $VERSION='0.01';

## Lazy Load where you can

I recommend Lazy Loading where you can.

    sub mymethod {
      my $self=shift;
      $self->load unless $self->loaded;
      return $self->{"mymethod"};
    }

# USAGE

# CONSTRUCTOR

## new

    my $obj = Package::New->new(key=>$value, ...);

## initialize

You can override this method in your package if you need to do something after construction.  But, lazy loading may be a better option.

# BUGS

Log on RT and contact the author.

# SUPPORT

DavisNetworks.com provides support services for all Perl applications including this package.

# AUTHOR

    Michael R. Davis
    CPAN ID: MRDVT
    DavisNetworks.com
    http://www.DavisNetworks.com/

# COPYRIGHT

This program is free software licensed under the...

    The BSD License

The full text of the license can be found in the LICENSE file included with this module.

# SEE ALSO

## Building Blocks

[base](https://metacpan.org/pod/base), [parent](https://metacpan.org/pod/parent)

## Other Light Weight Base Objects Similar to Package::New

[Package::Base](https://metacpan.org/pod/Package::Base), [Class::Base](https://metacpan.org/pod/Class::Base), [Class::Easy](https://metacpan.org/pod/Class::Easy), [Object::Tiny](https://metacpan.org/pod/Object::Tiny), [Badger::Base](https://metacpan.org/pod/Badger::Base)

## Heavy Base Objects - Drink the Kool-Aid

[VSO](https://metacpan.org/pod/VSO), [Class::Accessor::Fast](https://metacpan.org/pod/Class::Accessor::Fast), [Class::Accessor](https://metacpan.org/pod/Class::Accessor), [Moose](https://metacpan.org/pod/Moose), (as well as Moose-alikes [Moo](https://metacpan.org/pod/Moo), [Mouse](https://metacpan.org/pod/Mouse)), [Class::MethodMaker](https://metacpan.org/pod/Class::MethodMaker), [Class::Meta](https://metacpan.org/pod/Class::Meta)

## Even more

[Spiffy](https://metacpan.org/pod/Spiffy), [mixin](https://metacpan.org/pod/mixin), [SUPER](https://metacpan.org/pod/SUPER), [Class::Trait](https://metacpan.org/pod/Class::Trait), [Class::C3](https://metacpan.org/pod/Class::C3), [Moose::Role](https://metacpan.org/pod/Moose::Role)
