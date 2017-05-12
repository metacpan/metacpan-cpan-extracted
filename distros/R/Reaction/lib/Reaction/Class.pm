package Reaction::Class;

use Moose qw(confess);
use Sub::Exporter ();
use Sub::Name ();
use Reaction::Types::Core ':all';
use Reaction::Object;

sub exporter_for_package {
  my ($self, $package) = @_;
  my %exports_proto = $self->exports_for_package($package);
  no warnings 'uninitialized'; # XXX fix this
  my %exports = (
    map { my $cr = $exports_proto{$_}; ($_, sub { Sub::Name::subname "${self}::$_" => $cr; }) }
    keys %exports_proto
  );

  my $exporter = Sub::Exporter::build_exporter({
    exports => \%exports,
    groups  => {
        default => [':all']
    }
  });

  return $exporter;
}

sub do_import {
  my ($self, $pkg, $args) = @_;
  my $exporter = $self->exporter_for_package($pkg, $args);
  $exporter->($self, { into => $pkg }, @$args);
  if (my @default_base = $self->default_base) {
    no strict 'refs';
    @{"${pkg}::ISA"} = @default_base unless @{"${pkg}::ISA"};
  }
}

sub default_base { ('Reaction::Object'); }

sub exports_for_package {
  my ($self, $package) = @_;
  return (
    set_or_lazy_build => sub {
      my $name = shift;
      my $build = "build_${name}";
      return (required => 1, lazy => 1,
              default => sub { shift->$build(); });
    },
    set_or_lazy_fail => sub {
      my $name = shift;
      my $message = "${name} must be provided before calling reader";
      return (required => 1, lazy => 1,
              default => sub { confess($message); });
    },
    trigger_adopt => sub {
      my $type = shift;
      my @args = @_;
      my $adopt = "adopt_${type}";
      return (trigger => sub { shift->$adopt(@args); });
    },
    register_inc_entry => sub {
      my $inc = $package;
      $inc =~ s/::/\//g;
      $inc .= '.pm';
      $INC{$inc} = 1;
    },
    #this needs to go away soon. its never used. pollution.
    reflect_attributes_from => sub {
      my ($from_class, @attrs) = @_;

      #Should we use Class::Inspector to make sure class is loaded?
      #unless( Class::Inspector->loaded($from_class) ){
      #  eval "require $from_class" || die("Failed to load: $from_class");
      #}
      foreach my $attr_name (@attrs){
        my $from_attr = $from_class->meta->get_attribute($attr_name);
        confess("$from_attr does not exist in $from_class")
            unless $from_attr;
        #Not happy
        #$package->meta->add_attribute( $from_attr->name, %{$from_attr} );
        $package->meta->add_attribute( bless { %{$from_attr} } =>
                                       $package->meta->attribute_metaclass );
      }
    },
    class => sub {
      $self->do_class_sub($package, @_);
    },
    does => sub {
      $package->can('with')->(@_);
    },
    overrides => sub {
      $package->can('override')->(@_)
    },
    $self->make_package_sub($package),
    implements => sub { confess "implements only valid within class block" },
    $self->make_sugar_sub('is'),
    $self->make_code_sugar_sub('which'),
    $self->make_code_sugar_sub('as'),
    run => sub (;&@) { @_ },
  );
}

sub do_class_sub {
  my ($self, $package, $class, @args) = @_;
  my $error = "Invalid class declaration, should be: class Class (is Superclass)*, which { ... }";
  confess $error if (@args % 1);
  my @supers;
  while (@args > 2) {
    my $should_be_is = shift(@args);
    confess $error unless $should_be_is eq 'is';
    push(@supers, shift(@args));
  }
  confess $error unless $args[0] eq 'which' && ref($args[1]) eq 'CODE';
  my $setup = $args[1];

  #this eval is fucked, but I can't fix it
  unless ($class->can('meta')) {
    print STDERR "** MAKING CLASS $class useing Reaction::Class **\n";
    eval "package ${class}; use Reaction::Class;";
    if ($@) { confess "Couldn't make ${class} a Reaction class: $@"; }
  }
  if (@supers) {
    Class::MOP::load_class($_) for @supers;
    $class->meta->superclasses(@supers);
  }
  $self->setup_and_cleanup($package, $setup);

  #immutable code
  #print STDERR "$package \n";
  #print STDERR $package->meta->blessed, " \n";
  $package->meta->make_immutable;
  #    (inline_accessor    => 0, inline_destructor  => 0,inline_constructor => 0,);
}

sub setup_and_cleanup {
  my ($self, $package, $setup) = @_;
  my @methods;
  my @apply_after;
  my %save_delayed;
  {
    no strict 'refs';
    no warnings 'redefine';
    local *{"${package}::implements"} =
      Sub::Name::subname "${self}::implements" => sub {
        my $name = shift;
        shift if $_[0] eq 'as';
        push(@methods, [ $name, shift ]);
      };
    my $s = $setup;
    foreach my $meth ($self->delayed_methods) {
      $save_delayed{$meth} = $package->can($meth);
      my $s_copy = $s;
      $s = sub {
        local *{"${package}::${meth}"} =
          Sub::Name::subname "${self}::${meth}" => sub {
            push(@apply_after, [ $meth => @_ ]);
          };
        $s_copy->(@_);
      };
    }
    # XXX - need additional fuckery to handle multi-class-per-file
    $s->(); # populate up the crap
  }
  my %exports = $self->exports_for_package($package);
  {
    no strict 'refs';
    foreach my $nuke (keys %exports) {
      delete ${"${package}::"}{$nuke};
    }
  }
  my $unimport_class = $self->next_import_package;
  eval "package ${package}; no $unimport_class;";
  confess "$unimport_class unimport from ${package} failed: $@" if $@;
  foreach my $m (@methods) {
    $self->add_method_to_target($package, $m);
  }
  foreach my $a (@apply_after) {
    my $call = shift(@$a);
    $save_delayed{$call}->(@$a);
  }
}

sub add_method_to_target {
  my ($self, $target, $method) = @_;
  $target->meta->add_method(@$method);
}

sub delayed_methods {
  return (qw/has with extends before after around override augment/);
}

sub make_package_sub {
  my ($self, $package) = @_;
  my ($last) = (split('::', $package))[-1];
  return $last => sub {
    $self->do_package_sub($package => @_);
  };
}

sub do_package_sub {
  my $self = shift;
  my $package = shift;
  return (@_ ? ($package => @_) : $package);
}

sub make_sugar_sub {
  my ($self, $name) = @_;
  return $name => sub {
    return ($name => @_);
  };
}

sub make_code_sugar_sub {
  my ($self, $name) = @_;
  return $name => sub (;&@) {
    return ($name => @_);
  };
}

sub import {
  my $self = shift;
  my $pkg = caller;
  my @args = @_;
  strict->import;
  warnings->import;
  $self->do_import($pkg, \@args);
  goto &{$self->next_import} if $self->next_import;
}

sub next_import {
  return shift->next_import_package(@_)->can('import');
}

sub next_import_package { 'Moose' }

__PACKAGE__->meta->make_immutable;

1;

#---------#---------#---------#---------#---------#---------#---------#--------#

=head1 NAME

Reaction::Class

=head1 DESCRIPTION

=head1 SEE ALSO

=over

=item * L<Catalyst>

=item * L<Reaction::Manual>

=back

=head1 Unstructured reminders

(will properly format and stuff later.  no time right now)

C<use>ing C<Reaction::Class> will alias the current package name
see L<aliased>.

    package MyApp::Pretty::Picture

    # Picture expands to 'MyApp::Pretty::Picture'
    class Picture, which { ...

=head2 default_base

=head2 set_or_lazy_build $attrname

Will make your attributes lazy and required, if they are not set they
will default to the value returned by C<&build_$attrname>

    has created_d => (isa => 'DateTime', set_or_lazy_build('created_d') );
    sub build_created_d{ DateTime->now }

=head2 set_or_lazy_fail $attrname

Will make your attributes lazy and required, if they are not set
and their accessor is called an exception will be thrown

=head2 trigger_adopt $attrname

=head2 register_inc_entry

=head2 reflect_attributes_from  $from_class, @attrs

Create attributes in the local class that mirror the specified C<@attrs>
in C<$from_class>

=head2 class $name [, is $superclass ], which {

Sugary class declaration, will create a a package C<$name> with an
optional base class of $superclass. The class declaration, should be placed inside
the brackets using C<implements> to declare a method and C<has> to declare an
attribute.

=head2 does

Alias to C<with> for the current package, see C<Moose::Role>

=head2 implements $method_name [is | which | as]

Only valid whithin a class block, allows you to declare a method for the class.

    implements 'current_date' => as { DateTime->today };

=head2 run

=head1 AUTHORS

=over

=item * Matt S. Trout

=item * K. J. Cheetham

=item * Guillermo Roditi

=item * Justin Hunter

=item * Jess Robinson (Documentation)

=item * Kaare Rasmussen (Documentation)

=item * Andres N. Kievsky (Documentation)

=item * Robert Sedlacek (Documentation)

=back

=head1 SPONSORS

=over

=item * Ionzero

L<Ionzero|http://www.ionzero.com/> sponsored the writing of the 
L<Reaction::Manual::Tutorial>, L<Reaction::Manual::Overview> and
L<Reaction::Manual::Widgets> documentations as well as improvements
to L<Reaction::Manual::Intro> and many API documentation improvements
throughout the project.

=back

=head1 LICENSE

This library is free software, you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
