package Module::New::Loader;

use strict;
use warnings;
use Carp;
use String::CamelCase qw( camelize );

sub new {
  my ($class, @base) = @_;
  unless ( grep { $_ eq 'Module::New' } @base ) {
    push @base, 'Module::New';
  }
  bless { _base => \@base }, $class;
}

sub _base { @{ shift->{_base} } }

sub load_class {
  my ($self, @parts) = @_;

  @parts = map  { tr/a-zA-Z0-9_://cd; camelize( $_ ); }
              grep { defined } @parts;

  foreach my $base ( $self->_base ) {
    my $package = join '::', $base, @parts;

    if ( $self->{_reload} ) {
      (my $file = $package) =~ s|::|/|g;
      delete $INC{"$file.pm"};
    }

    local $@;
    eval "require $package; $package->import;";
    if ( $@ ) {
      next if $@ =~ /^Can't locate/;
      croak $@;
    }
    return $package;
  }
  croak "Can't locate ".(join '::', @parts);
}

sub reload_class {
  my $self = shift;

  local $self->{_reload} = 1;

  $self->load_class(@_);
}

sub load {
  my ($self, $type, $name, @args) = @_;

  $self->load_class($type, $name)->new(@args);
}

1;

__END__

=head1 NAME

Module::New::Loader

=head1 SYNOPSIS

=head1 DESCRIPTION

  my $loader = Module::New::Loader->new('SomeClass');
  my $object = $loader->load('Recipe', 'Foo', @args);

  # the $object should hopefully be SomeClass::Recipe::Foo,
  # or Module::New::Recipe::Foo if the former is not found.
  # (or croaks if the latter is not found, either.)

=head1 METHODS

This is a dedicated module loader used internally.

=head2 new

may take some extra namespaces, and creates a loader object.

=head2 load_class, reload_class

looks for a module under the registered namespaces and loads it.

=head2 load

loads and creates an instance of the specified module with extra arguments.

=head1 AUTHOR

Kenichi Ishigaki, E<lt>ishigaki at cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2007-2009 by Kenichi Ishigaki.

This program is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

=cut
