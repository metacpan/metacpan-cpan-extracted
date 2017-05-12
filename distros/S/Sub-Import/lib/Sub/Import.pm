use strict;
use warnings;

package Sub::Import;
{
  $Sub::Import::VERSION = '1.001';
}
# ABSTRACT: import routines from most anything using Sub::Exporter

use B qw(svref_2object);
use Carp ();
use Exporter ();
use Params::Util qw(_CLASS _CLASSISA);
use Sub::Exporter ();


sub import {
  my ($self, $target, @args) = @_;

  my $import = $self->_get_import($target);

  @_ = ($target, @args);
  goto &$import;
}

sub unimport {
  my ($self, $target, @args) = @_;

  my $unimport = $self->_get_unimport($target);

  @_ = ($target, @args);
  goto &$unimport;
}

sub _get_unimport {
  my ($self, $target) = @_;

  $self->_get_methods($target)->{unimport};
}

sub _get_import {
  my ($self, $target) = @_;

  $self->_get_methods($target)->{import};
}

my %GENERATED_METHODS;
sub _get_methods {
  my ($self, $target) = @_;

  $GENERATED_METHODS{$target} ||= $self->_create_methods($target);
}

sub _require_class {
  my ($self, $class) = @_;

  Carp::croak("invalid package name: $class") unless _CLASS($class);

  local $@;
  eval "require $class; 1" or die;

  return;
}

sub _is_sexy {
  my ($self, $class) = @_;

  local $@;
  my $isa;
  my $ok = eval {
    my $obj = svref_2object( $class->can('import') );
    my $importer_pkg = $obj->START->stashpv;
    $isa = _CLASSISA($importer_pkg, 'Sub::Exporter');
    1;
  };

  return $isa;
}

my $EXPORTER_IMPORT;
BEGIN { $EXPORTER_IMPORT = Exporter->can('import'); }
sub _is_exporterrific {
  my ($self, $class) = @_;
  
  my $class_import = do {
    local $@;
    eval { $class->can('import') };
  };

  return unless $class_import;
  return $class_import == $EXPORTER_IMPORT;
}

sub _create_methods {
  my ($self, $target) = @_;

  $self->_require_class($target);

  if ($self->_is_sexy($target)) {
    return {
      import   => $target->can("import"),
      unimport => $target->can("unimport"),
    };
  } elsif ($self->_is_exporterrific($target)) {
    return $self->_create_methods_exporter($target);
  } else {
    return $self->_create_methods_fallback($target);
  }
}

sub __filter_subs {
  my ($self, $exports) = @_;

  @$exports = map { s/\A&//; $_ } grep { /\A[&_a-z]/ } @$exports;
}

sub _create_methods_exporter {
  my ($self, $target) = @_;

  no strict 'refs';

  my @ok      = @{ $target . "::EXPORT_OK"   };
  my @default = @{ $target . "::EXPORT"      };
  my %groups  = %{ $target . "::EXPORT_TAGS" };

  $self->__filter_subs($_) for (\@ok, \@default, values %groups);

  my @all = do {
    my %seen;
    grep { ! $seen{$_}++ } @ok, @default;
  };

  my $import = Sub::Exporter::build_exporter({
    exports => \@all,
    groups  => {
      %groups,
      default => \@default,
    }
  });

  return {
    import   => $import,
    unimport => sub { die "unimport not handled for Exporter via Sub::Import" },
  };
}

sub _create_methods_fallback {
  my ($self, @target) = @_;

  Carp::confess(
    "Sub::Import only handles Sub::Exporter and Exporter-based import methods"
  );
}

1;

__END__

=pod

=head1 NAME

Sub::Import - import routines from most anything using Sub::Exporter

=head1 VERSION

version 1.001

=head1 SYNOPSIS

  use Sub::Import 'Some::Library' => (
    some_routine  => { -as => 'some_other_name' },
    other_routine => undef,
  );

=head1 DESCRIPTION

Sub::Import is the companion to Sub::Exporter.  You can use Sub::Import to get
Sub::Exporter-like import semantics, even if the library you're importing from
used Exporter.pm.

The synopsis above should say it all.  Where you would usually say:

  use Some::Library qw(foo bar baz);

...to get Exporter.pm semantics, you can now get Sub::Exporter semantics with:

  use Sub::Import 'Some::Library' => qw(foo bar baz);

=head1 WARNINGS AND LIMITATIONS

While you can rename imports, there is no way to customize them, because they
are not being built by generators.  At present, extra arguments for each import
will be thrown away.  In the future, they may become a fatal error.

Non-subroutine imports will not be importable via this mechanism.

The regex-like import features of Exporter.pm will be unavailable.  (Will
anyone miss them?)

=head1 AUTHOR

Ricardo Signes <rjbs@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2013 by Ricardo Signes.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
