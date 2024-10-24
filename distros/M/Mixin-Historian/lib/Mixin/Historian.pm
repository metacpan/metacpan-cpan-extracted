package Mixin::Historian 0.102001;
# ABSTRACT: a mixin for recording history about objects

use Mixin::ExtraFields 0.008 ();
use parent 'Mixin::ExtraFields';

use strict;
use warnings;

use Sub::Exporter::ForMethods ();

use Sub::Exporter -setup => {
  groups => {
    history => \'gen_fields_group',
  },
  installer => Sub::Exporter::ForMethods::method_installer(),
};

#pod =head1 SYNOPSIS
#pod
#pod   package My::Object;
#pod   use Mixin::Historian -history => {
#pod     driver => {
#pod       class => 'YourDriver',
#pod       ...,
#pod     },
#pod   };
#pod
#pod   # Later...
#pod   my $object = My::Object->retrieve(1234);
#pod
#pod   $object->add_history({
#pod     type     => 'lava damage',
#pod     severity => 'very badly burned',
#pod     volcano  => 'Eyjafjallajokull',
#pod   });
#pod
#pod =head1 DESCRIPTION
#pod
#pod Mixin::Historian is an application of Mixin::ExtraFields.  If you're not
#pod familiar with it, you should read about it, both in L<its
#pod documentation|Mixin::ExtraFields> and in L<this article about
#pod Mixin::ExtraFields|http://advent.rjbs.manxome.org/2009-12-22.html>.
#pod
#pod Generally, it provides simple mechanism for write-only history.  Importing the
#pod C<-history> group will get you the C<add_history> method, which generally will
#pod accept one hashref with at least a C<type> key.  This will be passed along to
#pod the driver's C<add_history> method.
#pod
#pod =head1 TODO
#pod
#pod I have shoehorned an extra layer of functionality into the Historian driver
#pod that I use in my employer's code.  When initialized, the Historian mixin is
#pod told all legal types, something like this:
#pod
#pod   type_map => {
#pod     'lava damage' => {
#pod       severity => { required => 1, store_as => 'extra_1' },
#pod       volcano  => { required => 0, store_as => 'extra_2' },
#pod     },
#pod     ...
#pod   }
#pod
#pod This way, history entries can be validated before writing.  The C<store_as>
#pod entries indicate how the arguments to C<add_history> are mapped to database
#pod columns.  The entire argument is also stored in one field as JSON, and a few
#pod other attributes are always required (like C<by_whom>) and some are added just
#pod in time (like C<logged_at>).
#pod
#pod This feature is not yet present in the CPAN library because I have not yet
#pod found a suitable decomposition of concerns to make it a component.
#pod
#pod =cut

sub default_moniker { 'history' }

sub driver_base_class { 'Mixin::Historian::Driver' }

sub methods { qw(add) }

sub driver_method_name {
  my ($self, $method) = @_;
  $self->method_name($method, 'history');
}

sub build_method {
  my ($self, $method_name, $arg) = @_;

  # Remember that these are all passed in as references, to avoid unneeded
  # copying. -- rjbs, 2006-12-07
  my $id_method = $arg->{id_method};
  my $driver    = $arg->{driver};

  my $driver_method  = $self->driver_method_name($method_name);

  return sub {
    my $object = shift;
    my $id     = $object->$$id_method;
    Carp::confess "couldn't determine id for object" unless defined $id;
    $$driver->$driver_method({
      object => $object,
      mixin  => $self,
      id     => $id,
      args   => \@_,
    });
  };
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Mixin::Historian - a mixin for recording history about objects

=head1 VERSION

version 0.102001

=head1 SYNOPSIS

  package My::Object;
  use Mixin::Historian -history => {
    driver => {
      class => 'YourDriver',
      ...,
    },
  };

  # Later...
  my $object = My::Object->retrieve(1234);

  $object->add_history({
    type     => 'lava damage',
    severity => 'very badly burned',
    volcano  => 'Eyjafjallajokull',
  });

=head1 DESCRIPTION

Mixin::Historian is an application of Mixin::ExtraFields.  If you're not
familiar with it, you should read about it, both in L<its
documentation|Mixin::ExtraFields> and in L<this article about
Mixin::ExtraFields|http://advent.rjbs.manxome.org/2009-12-22.html>.

Generally, it provides simple mechanism for write-only history.  Importing the
C<-history> group will get you the C<add_history> method, which generally will
accept one hashref with at least a C<type> key.  This will be passed along to
the driver's C<add_history> method.

=head1 PERL VERSION

This library should run on perls released even a long time ago.  It should work
on any version of perl released in the last five years.

Although it may work on older versions of perl, no guarantee is made that the
minimum required version will not be increased.  The version may be increased
for any reason, and there is no promise that patches will be accepted to lower
the minimum required perl.

=head1 TODO

I have shoehorned an extra layer of functionality into the Historian driver
that I use in my employer's code.  When initialized, the Historian mixin is
told all legal types, something like this:

  type_map => {
    'lava damage' => {
      severity => { required => 1, store_as => 'extra_1' },
      volcano  => { required => 0, store_as => 'extra_2' },
    },
    ...
  }

This way, history entries can be validated before writing.  The C<store_as>
entries indicate how the arguments to C<add_history> are mapped to database
columns.  The entire argument is also stored in one field as JSON, and a few
other attributes are always required (like C<by_whom>) and some are added just
in time (like C<logged_at>).

This feature is not yet present in the CPAN library because I have not yet
found a suitable decomposition of concerns to make it a component.

=head1 AUTHOR

Ricardo Signes <cpan@semiotic.systems>

=head1 CONTRIBUTOR

=for stopwords Ricardo Signes

Ricardo Signes <rjbs@semiotic.systems>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2022 by Ricardo Signes.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
