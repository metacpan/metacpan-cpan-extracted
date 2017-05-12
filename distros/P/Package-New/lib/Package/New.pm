package Package::New;
use strict;
use warnings;

our $VERSION='0.07';

=head1 NAME

Package::New - Simple base package from which to inherit

=head1 SYNOPSIS

  package My::Package;
  use base qw{Package::New}; #provides new and initialize

=head1 DESCRIPTION

The Package::New object provides a consistent constructor for objects.

I find that I always need these two methods in every package that I build.  I plan to use this package as the base for all of my CPAN packages. 

=head1 RECOMMENDATIONS

=head2 Sane defaults

I recommend that you have sane default for all of your object properties.  I recommend using code like this.

  sub myproperty {
    my $self=shift;
    $self->{"myproperty"}=shift if @_;
    $self->{"myproperty"}="Default Value" unless defined $self->{"myproperty"};
    return $self->{"myproperty"};
  }

=head2 use strict and warnings

I recommend to always use strict, warnings and our version.

  package My::Package;
  use base qw{Package::New};
  use strict;
  use warnings;
  our $VERSION='0.01';

=head2 Lazy Load where you can

I recommend Lazy Loading where you can.

  sub mymethod {
    my $self=shift;
    $self->load unless $self->loaded;
    return $self->{"mymethod"};
  }

=head1 USAGE

=head1 CONSTRUCTOR

=head2 new

  my $obj = Package::New->new(key=>$value, ...);

=cut

sub new {
  my $this=shift;
  my $class=ref($this) || $this;
  my $self={};
  bless $self, $class;
  $self->initialize(@_);
  return $self;
}

=head2 initialize

You can override this method in your package if you need to do something after construction.  But, lazy loading may be a better option.

=cut

sub initialize {
  my $self=shift;
  %$self=@_;
}

=head1 BUGS

Log on RT and contact the author.

=head1 SUPPORT

DavisNetworks.com provides support services for all Perl applications including this package.

=head1 AUTHOR

  Michael R. Davis
  CPAN ID: MRDVT
  DavisNetworks.com
  http://www.DavisNetworks.com/

=head1 COPYRIGHT

This program is free software licensed under the...

  The BSD License

The full text of the license can be found in the LICENSE file included with this module.

=head1 SEE ALSO

=head2 Building Blocks

L<base>, L<parent>

=head2 Other Light Weight Base Objects Similar to Package::New

L<Package::Base>, L<Class::Base>, L<Class::Easy>, L<Object::Tiny>

=head2 Heavy Base Objects - Drink the Kool-Aid

L<Moose>, (as well as Moose-alikes L<Moo>, L<Mouse>), L<Class::Accessor>, L<Class::Accessor::Fast>, L<Class::MethodMaker>, L<Class::Meta>

=head2 Even more

L<Spiffy>, L<mixin>, L<SUPER>, L<Class::Trait>, L<Class::C3>, L<Moose::Role>

=cut

1;
