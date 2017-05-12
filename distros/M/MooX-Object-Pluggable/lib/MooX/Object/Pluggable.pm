package MooX::Object::Pluggable;
use Moo::Role;
use Modern::Perl;
use Scalar::Util 'refaddr';
require Module::Pluggable::Object;
use namespace::clean;

our $VERSION = '0.0.5'; # VERSION
# ABSTRACT: Moo eXtension to inject plugins to exist objects as a role


sub _apply_roles {
  my ($self, @roles) = @_;
  map {
    my $role = $_;
    Moo::Role->apply_roles_to_object($self, $role) unless $self->does($role)
  } @roles;
  return $self;
}

sub load_plugin { load_plugins(@_) }

sub load_plugins {
  my ($self, @plugin_options) = @_;
  my $pluggable_object = $self->_pluggable_object;
  my @plugins = $pluggable_object->plugins;
  # Provide ability for roles in a real package, with syntax: '+MooX::ConfigFromFile'
  map {
    my $option = $_; $option=~s/^\+//;
    $self->_apply_roles($option);
  } grep { /^\+/ } @plugin_options;
  return $self unless @plugins;
  for my $plugin_option (@plugin_options) {
    if ($plugin_option eq '-all') {
      $self->_apply_roles(@plugins);
    } elsif (ref $plugin_option eq 'ARRAY') {
      $self->load_plugins(@$plugin_option);
    } elsif (ref $plugin_option eq 'Regexp') {
      my @load_plugins = grep { $plugin_option } @plugins;
      return $self unless @load_plugins;
      $self->_apply_roles(@load_plugins);
    } else {
      my @load_plugins = map { $_.'::'.$plugin_option } @{$pluggable_object->{search_path}};
      my %all_plugins = map { $_ => 1 } @plugins;
      my @real_roles = grep { $all_plugins{$_} } @load_plugins;
      return $self unless @real_roles;
      $self->_apply_roles(@real_roles)
    }
  }
  return $self;
}


sub plugins {
  my ($self) = @_;
  $self->_pluggable_object->plugins;
}


sub loaded_plugins {
  my $self = shift;
  grep { $self->does($_) } $self->plugins;
}


my %pluggable_objects = (); # key: object, value: loaded plugins

sub BUILD { }  # BUILD() will be override by consumers, so we use afterBuild

after BUILD => sub {
  my ($self, $opts) = @_;
  if (defined $opts->{pluggable_options}) {
    my $pluggable_options = $opts->{pluggable_options};
    $pluggable_options->{package} = ref $self ? ref $self : $self;
    $pluggable_objects{refaddr($self)} = Module::Pluggable::Object->new(%$pluggable_options);
  }
  if (defined $self->_build_load_plugins and scalar @{$self->_build_load_plugins} > 0) {
    $self->load_plugins(@{$self->_build_load_plugins});
  }
  if (defined $opts->{load_plugins}) {
    $self->load_plugins(ref $opts->{load_plugins} eq 'ARRAY' ?
      @{$opts->{load_plugins}} : $opts->{load_plugins}
    );
  }
};

sub _build_pluggable_options { {} }

sub _build_load_plugins { [] }

sub _pluggable_object {
  my $self = shift;
  my ($class, $addr);
  if (ref $self) {
    $class = ref $self;
    $addr = refaddr $self;
  } else {
    $class = $self;
  }
  # Find self pluggable object;
  return $pluggable_objects{$addr} if defined $addr and defined $pluggable_objects{$addr};
  # Find package pluggable object;
  $class=~s/__WITH__.*//g; # use parent package name as class name.
  return $pluggable_objects{$class} if defined $pluggable_objects{$class};
  # Not found, create a new one for package.
  my $pluggable_options = $self->_build_pluggable_options;
  $pluggable_options->{package} = $class;
  $pluggable_objects{$class} = Module::Pluggable::Object->new(
    %$pluggable_options,
  );
}


sub _inject_roles_to {
  my ($target, $import_options) = @_;
  my $with = $target->can("with");
  return unless $with; # Do nothing unless it's a Moo(se) object or role.

  $with->('MooX::Object::Pluggable');
  my $around = $target->can("around");
  for my $builder (qw/pluggable_options load_plugins/) {
    my ($key) = grep /$builder/, keys %$import_options;
    next unless $key;
    $around->("_build_$builder" => sub { $import_options->{$key} });
  }
}

sub import
{
  my ( undef, %import_options ) = @_;
  my $target = caller;
  # Inject roles to target namespace
  &_inject_roles_to($target, \%import_options);

  # Compatible for MooX
  my $around = $target->can("around");
  return unless $around;
  $around->("import" => sub {
      my ($orig, $self, @opts) = @_;
      my %pluggable_opts = map { $opts[$_] => $opts[$_ + 1] } grep { $opts[$_] =~/^-(pluggable_options|load_plugins)$/ } 0..$#opts;
      &_inject_roles_to($target, \%pluggable_opts);
      my %hash = map { $_ => 1 } %pluggable_opts;
      my @remains = grep { ! defined $hash{$_} } @opts;
      $self->$orig(@remains);
    });
  return;
}


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

MooX::Object::Pluggable - Moo eXtension to inject plugins to exist objects as a role

=head1 VERSION

version 0.0.5

=head1 SYNOPSIS

In your package:

  package MyPackage;
  use Moo;
  use namespace::clean;

  with 'MooX::Object::Pluggable';
  1

Define your plugin package:

  package MyPackage::Plugin::Foo;
  use Moo::Role;
  use namespace::clean;

  sub foo { 'foo' }

Then in your script:

  #!perl
  use MyPackage;
  my $object = MyPackage->new;
  $object->load_plugins('Foo');

Or C<new> with pluggable options:

  use MyPackage;
  MyPackage->new(
    pluggable_options => { search_path => 'MyPackage::Plugin' }, # optional
    load_plugins => [ "Foo", qr/::Bar$/ ]
  );

Or use MooX with this:

  use MooX 'Object::Pluggable' => { ... };

=head1 DESCRIPTION

C<MooX::Object::Pluggable> for moo is designed to perform like C<MooseX::Object::Pluggable>
for Moose staff. Mainly it use Moo::Role's C<apply_roles_to_object> to load plugins
at runtime, but with the ability to choose plugins with package L<Module::Pluggable::Object>.

=head1 METHODS

=head2 load_plugins

In most situation, your need only call the fuction C<load_plugins> on an object.
The parameters support String, Regexp, or Array or ArrayRef of them.

eg.

  $o->load_plugins("Foo", "Bar", qr/^Class::Plugin::(Abc|N)[0-9]/, [ qw/Other Way/ ]);

And there's another syntax sugar, when you just want to load a specific role:

  $o->load_plugins("+MooX::ConfigFromFile::Role");
  # Notice that the '+' sign does not support Regexp, use whole package name with it.

=head2 plugins

The method C<plugins> returns a array of plugins, defaultly in the namespace
C<Your::Package::Plugin::>. You can manage it by implement the C<_build_pluggable_options>
in your package and given the avaliable options' HashRef.

  package MyPackage;
  use Moo;
  with 'MooX::Object::Pluggable';
  sub _build_pluggable_options {
    { search_path => __PACKAGE__.'::Funtionals' }
  }

All the avaliable options will be found in tutorial of package L<Module::Pluggable>.

=head2 loaded_plugins

This will list all loaded plugins of current object for you.

=head1 DESIGN

Considering not import any new attributes to the consumers,
I'm using a private variable for help to maintain L<Module::Pluggable::Object>
objects so that it only create once for each package,
and could provide private configuration for specific objects
that use diffent pluggable options in C<new>.

There's two way to configure user defined pluggable options.

=head2 new(pluggable_options => {}, load_plugins => [])

User could directly use there specific options for plugin.
And create objects with some plugins after C<BUILD> step.

=head2 _build_pluggable_options

Implement this build function in your package, and C<MooX::Object::Pluggable>
will apply the options for you.

And you still could change default options in C<new> method.

=head1 MooX

A L<MooX>-compatible interface like this:

  package MyPackage::Hello;
  use Moo::Role;
  sub hello { 'hello' }

...

  package MyPackage;
  use MooX::Object::Pluggable -pluggable_options => { search_path => ["MyPackage"] }, -load_plugins => ['Hello'];

Or:

  use MooX
    'Object::Pluggable' => { -pluggable_options => { search_path => ["MyPackage"] }, -load_plugins => ['Hello'] };

=head1 SEE ALSO

L<Module::Pluggable>, L<MooseX::Object::Pluggable>

=head1 AUTHOR

Huo Linhe <linhehuo@gmail.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2016 by Huo Linhe.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
