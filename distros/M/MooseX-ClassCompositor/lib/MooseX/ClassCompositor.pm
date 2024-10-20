package MooseX::ClassCompositor 0.010;
# ABSTRACT: a factory that builds classes from roles

use Moose;

use namespace::autoclean;

use Class::Load;
use Moose::Util qw(apply_all_roles);
use Moose::Util::MetaRole ();
use MooseX::StrictConstructor::Trait::Class;
use MooseX::Types::Perl qw(PackageName);
use Scalar::Util qw(refaddr);
use String::RewritePrefix;

#pod =head1 SYNOPSIS
#pod
#pod   my $comp = MooseX::ClassCompositor->new({
#pod     class_basename  => 'MyApp::Class',
#pod     class_metaroles => {
#pod       class => [ 'MooseX::StrictConstructor::Trait::Class' ],
#pod     },
#pod     role_prefixes   => {
#pod       ''  => 'MyApp::Role::',
#pod       '=' => '',
#pod     },
#pod   });
#pod
#pod   my $class = $comp->class_for( qw( PieEater ContestWinner ) );
#pod
#pod   my $object = $class->new({
#pod     pie_type => 'banana',
#pod     place    => '2nd',
#pod   });
#pod
#pod =head1 OVERVIEW
#pod
#pod A MooseX::ClassCompositor is a class factory.  If you think using a class
#pod factory will make you feel like a filthy "enterprise" programmer, maybe you
#pod should turn back now.
#pod
#pod The compositor has a C<L</class_for>> method that builds a class by combining a
#pod list of roles with L<Moose::Object>, applying any supplied metaclass, and
#pod producing an arbitrary-but-human-scannable name.  The metaclass is then
#pod made immutable, the operation is memoized, and the class name is returned.
#pod
#pod In the L</SYNOPSIS> above, you can see all the major features used:
#pod C<class_metaroles> to enable strict constructors, C<role_prefixes> to use
#pod L<String::RewritePrefix> to expand role name shorthand, and C<class_basename>
#pod to pick a namespace under which to put constructed classes.
#pod
#pod Not shown is the C<L</known_classes>> method, which returns a list of pairs
#pod describing all the classes that the factory has constructed.  This method can
#pod be useful for debugging and other somewhat esoteric purposes like
#pod serialization.
#pod
#pod =cut

#pod =attr class_basename
#pod
#pod This attribute must be given, and must be a valid Perl package name.
#pod Constructed classes will all be under this namespace.
#pod
#pod =cut

has class_basename => (
  is  => 'ro',
  isa => PackageName,
  required => 1,
);

#pod =attr class_metaroles
#pod
#pod This attribute, if given, must be a hashref of class metaroles that will be
#pod applied to newly-constructed classes with
#pod L<Moose::Util::MetaRole/apply_metaroles>.
#pod
#pod =cut

has class_metaroles => (
  reader  => '_class_metaroles',
  isa     => 'HashRef',
  default => sub {  {}  },
);

#pod =attr known_classes
#pod
#pod This attribute stores a mapping of class names to the parameters used to
#pod construct them.  The C<known_classes> method returns its contents as a list of
#pod pairs.
#pod
#pod =cut

has known_classes => (
  reader   => '_known_classes',
  isa      => 'HashRef',
  traits   => [ 'Hash' ],
  handles  => {
    _learn_class   => 'set',
    known_classes => 'elements',
  },
  init_arg => undef,
  default  => sub {  {}  },
);

#pod =attr role_prefixes
#pod
#pod This attribute is used as the arguments to L<String::RewritePrefix> for
#pod expanding role names passed to the compositor's L<class_for> method.
#pod
#pod =cut

has role_prefixes => (
  reader  => '_role_prefixes',
  isa     => 'HashRef',
  default => sub {  {}  },
);

sub _rewrite_roles {
  my $self = shift;
  String::RewritePrefix->rewrite($self->_role_prefixes, @_);
}

#pod =attr fixed_roles
#pod
#pod This attribute may be initialized with an arrayref of role names and/or
#pod L<Moose::Meta::Role> objects.  These roles will I<always> be composed in
#pod the classes built by the compositor.
#pod
#pod Role names (but not Moose::Meta::Role objects) I<will> be rewritten by
#pod the role prefixes.
#pod
#pod =cut

has fixed_roles => (
  reader  => '_fixed_roles',
  isa     => 'ArrayRef',
  default => sub {  []  },
);

has serial_counter => (
  reader  => '_serial_counter',
  isa     => 'Str',
  default => 'AA',
  traits  => [ 'String' ],
  handles => { next_serial => 'inc' },
  init_arg => undef,
);

has memoization_table => (
  isa => 'HashRef',
  default  => sub {  {}  },
  traits   => [ 'Hash' ],
  handles  => {
    _class_for_key     => 'get',
    _set_class_for_key => 'set',
  },
  init_arg => undef,
);

#pod =attr forbid_meta_role_objects
#pod
#pod If true, an exception will be raised if a Moose::Meta::Role object is passed to
#pod C<L</class_for>>.  This is only rarely useful, such as if it's a strict
#pod requirement that the memoization table of the compositor be serializable and
#pod its contents reproduceable.
#pod
#pod Probably you don't need this.
#pod
#pod =cut

has forbid_meta_role_objects => (
  is  => 'ro',
  isa => 'Bool',
  default => 0,
);

#pod =method class_for
#pod
#pod   my $class = $compositor->class_for(
#pod
#pod     'Role::Name',          #  <-- will be expanded with role_prefixes
#pod     Other::Role->meta,     #  <-- will not be touched
#pod
#pod     [
#pod       'Param::Role::Name', #  <-- will be expanded with role_prefixes
#pod       'ApplicationName',   #  <-- will not be touched
#pod       { ...param... },
#pod     ],
#pod   );
#pod
#pod This method will return a class with the roles passed to it.  They can be given
#pod either as names (which will be expanded according to C<L</role_prefixes>>), as
#pod L<Moose::Meta::Role> objects, or as arrayrefs containing a role name,
#pod application name, and hashref of parameters.  In the arrayref form, the
#pod application name is just a name used to uniquely identify this application of
#pod a parameterized role, so that they can be applied multiple times with each
#pod application accounted for internally.
#pod
#pod =cut

sub class_for {
  my ($self, @args) = @_;

  # can't use memoize without losing subclassability, so we reimplemented
  # -- rjbs, 2011-08-05
  my $memo_key = $self->_memoization_key(\@args);
  if (my $cached = $self->_class_for_key($memo_key)) {
    return $cached;
  }

  # Arguments here are role names, or role objects followed by nonce-names.
  my @orig_args = @args;

  # $role_hash is a hash mapping nonce-names to role objects
  # $role_names is an array of names of more roles to add
  my (@roles, @role_class_names, @all_names);

  while (@args) {
    my $name = shift @args;
    if (ref $name eq 'ARRAY') {
      my ($role_name, $moniker, $params) = @$name;

      my $full_name = $self->_rewrite_roles($role_name);
      Class::Load::load_class($full_name);
      my $role_object = $full_name->meta->generate_role(
        parameters => $params,
      );

      push @roles, $role_object;
      $name = $moniker;
    } elsif (blessed $name and $name->isa('Moose::Meta::Role')) {
      confess "this class compositor does not allow role objects"
        if $self->forbid_meta_role_objects;

      push @roles, $name;
      $name = $name->name;
    } else {
      push @role_class_names, $name;
    }

    $name =~ s/::/_/g if @all_names;
    $name =~ s/^=//;

    push @all_names, $name;
  }

  my $name = join q{::}, $self->class_basename, @all_names;

  for my $r (@{ $self->_fixed_roles }) {
    if (blessed $r and $r->isa('Moose::Meta::Role')) {
      push @roles, $r;
    } else {
      push @role_class_names, $r;
    }
  }

  @role_class_names = $self->_rewrite_roles(@role_class_names);

  # We only _try_ to load because in use, some of these are embedded in other
  # packages.  While we'd like to stop relying on this, this is an expedient
  # change.  After all, it'll fail during composition, if the role package is
  # not properly set up.  -- rjbs, 2018-06-21
  Class::Load::try_load_class($_) for @role_class_names;

  if ($name->can('meta')) {
    $name .= "_" . $self->next_serial;
  }

  my $class = Moose::Meta::Class->create( $name => (
    superclasses => [ 'Moose::Object' ],
  ));

  $class = Moose::Util::MetaRole::apply_metaroles(
    for => $class->name,
    class_metaroles => $self->_class_metaroles,
  );

  apply_all_roles($class, @role_class_names, map $_->name, @roles);

  $class->make_immutable;

  $self->_learn_class($name, \@orig_args);
  $self->_set_class_for_key($memo_key, $name);

  return $class->name;
}

sub _memoization_key {
  my ($self, $args) = @_;
  my @args = @$args;

  my @k;
  while (@args) {
    my $arg = shift @args;
    if (ref $arg eq 'ARRAY') {
      my ($role_name, $moniker, $params) = @$arg;
      push @k, "$moniker : { " . __hash_to_string($params) . " }";
    } elsif (blessed $arg and $arg->isa('Moose::Meta::Role')) {
      push @k, $arg->name;
    } else {
      push @k, $arg;
    }
  }
  my $key = join "; ", sort @k;
  return $key;
}

sub __hash_to_string {
  my ($h) = @_;
  my @k;
  for my $k (sort keys %$h) {
    my $v = ! defined($h->{$k}) ? "<undef>" :
              ref($h->{$k}) ? join("-", @{$h->{$k}}) : $h->{$k};
    push @k, "$k => $v";
  }
  join ", " => @k;
}

#pod =head1 THANKS
#pod
#pod Thanks to Pobox.com for sponsoring the development of this library.
#pod
#pod =cut

__PACKAGE__->meta->make_immutable;
1;

__END__

=pod

=encoding UTF-8

=head1 NAME

MooseX::ClassCompositor - a factory that builds classes from roles

=head1 VERSION

version 0.010

=head1 SYNOPSIS

  my $comp = MooseX::ClassCompositor->new({
    class_basename  => 'MyApp::Class',
    class_metaroles => {
      class => [ 'MooseX::StrictConstructor::Trait::Class' ],
    },
    role_prefixes   => {
      ''  => 'MyApp::Role::',
      '=' => '',
    },
  });

  my $class = $comp->class_for( qw( PieEater ContestWinner ) );

  my $object = $class->new({
    pie_type => 'banana',
    place    => '2nd',
  });

=head1 OVERVIEW

A MooseX::ClassCompositor is a class factory.  If you think using a class
factory will make you feel like a filthy "enterprise" programmer, maybe you
should turn back now.

The compositor has a C<L</class_for>> method that builds a class by combining a
list of roles with L<Moose::Object>, applying any supplied metaclass, and
producing an arbitrary-but-human-scannable name.  The metaclass is then
made immutable, the operation is memoized, and the class name is returned.

In the L</SYNOPSIS> above, you can see all the major features used:
C<class_metaroles> to enable strict constructors, C<role_prefixes> to use
L<String::RewritePrefix> to expand role name shorthand, and C<class_basename>
to pick a namespace under which to put constructed classes.

Not shown is the C<L</known_classes>> method, which returns a list of pairs
describing all the classes that the factory has constructed.  This method can
be useful for debugging and other somewhat esoteric purposes like
serialization.

=head1 PERL VERSION

This library should run on perls released even a long time ago.  It should work
on any version of perl released in the last five years.

Although it may work on older versions of perl, no guarantee is made that the
minimum required version will not be increased.  The version may be increased
for any reason, and there is no promise that patches will be accepted to lower
the minimum required perl.

=head1 ATTRIBUTES

=head2 class_basename

This attribute must be given, and must be a valid Perl package name.
Constructed classes will all be under this namespace.

=head2 class_metaroles

This attribute, if given, must be a hashref of class metaroles that will be
applied to newly-constructed classes with
L<Moose::Util::MetaRole/apply_metaroles>.

=head2 known_classes

This attribute stores a mapping of class names to the parameters used to
construct them.  The C<known_classes> method returns its contents as a list of
pairs.

=head2 role_prefixes

This attribute is used as the arguments to L<String::RewritePrefix> for
expanding role names passed to the compositor's L<class_for> method.

=head2 fixed_roles

This attribute may be initialized with an arrayref of role names and/or
L<Moose::Meta::Role> objects.  These roles will I<always> be composed in
the classes built by the compositor.

Role names (but not Moose::Meta::Role objects) I<will> be rewritten by
the role prefixes.

=head2 forbid_meta_role_objects

If true, an exception will be raised if a Moose::Meta::Role object is passed to
C<L</class_for>>.  This is only rarely useful, such as if it's a strict
requirement that the memoization table of the compositor be serializable and
its contents reproduceable.

Probably you don't need this.

=head1 METHODS

=head2 class_for

  my $class = $compositor->class_for(

    'Role::Name',          #  <-- will be expanded with role_prefixes
    Other::Role->meta,     #  <-- will not be touched

    [
      'Param::Role::Name', #  <-- will be expanded with role_prefixes
      'ApplicationName',   #  <-- will not be touched
      { ...param... },
    ],
  );

This method will return a class with the roles passed to it.  They can be given
either as names (which will be expanded according to C<L</role_prefixes>>), as
L<Moose::Meta::Role> objects, or as arrayrefs containing a role name,
application name, and hashref of parameters.  In the arrayref form, the
application name is just a name used to uniquely identify this application of
a parameterized role, so that they can be applied multiple times with each
application accounted for internally.

=head1 THANKS

Thanks to Pobox.com for sponsoring the development of this library.

=head1 AUTHORS

=over 4

=item *

Ricardo Signes <cpan@semiotic.systems>

=item *

Mark Jason Dominus <mjd@cpan.org>

=back

=head1 CONTRIBUTORS

=for stopwords Mohammad S Anwar Ricardo Signes Toby Inkster

=over 4

=item *

Mohammad S Anwar <mohammad.anwar@yahoo.com>

=item *

Ricardo Signes <rjbs@semiotic.systems>

=item *

Toby Inkster <tobyink@cpan.org>

=back

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2011 by Ricardo Signes.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
