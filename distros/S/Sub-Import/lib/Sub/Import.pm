use strict;
use warnings;

package Sub::Import 1.002;
# ABSTRACT: import routines from most anything using Sub::Exporter

use B qw(svref_2object);
use Carp ();
use Exporter ();
use Params::Util qw(_CLASS _CLASSISA);
use Sub::Exporter ();

#pod =head1 SYNOPSIS
#pod
#pod   use Sub::Import 'Some::Library' => (
#pod     some_routine  => { -as => 'some_other_name' },
#pod     other_routine => undef,
#pod   );
#pod
#pod Some more examples:
#pod
#pod   # import a function with a custom name
#pod   use Sub::Import 'Digest::MD5', md5_hex => {-as => 'md5sum'};
#pod
#pod   # import multiple functions, each with its own name
#pod   use Sub::Import 'MIME::Base64',
#pod     encode_base64 => {-as => 'e64'},
#pod     decode_base64 => {-as => 'd64'};
#pod
#pod   # Import most functions with the "trig_" prefix, e.g. "trig_log",
#pod   # "trig_sin", "trig_cos", etc.
#pod   use Sub::Import 'Math::Trig', -all => {-prefix => 'trig_'};
#pod
#pod   # Import PI-related functions with the "_the_great" suffix, e.g.
#pod   # "pi_the_great", "pi2_the_great", etc.
#pod   use Sub::Import 'Math::Trig', -pi  => {-suffix => '_the_great'};
#pod
#pod =head1 DESCRIPTION
#pod
#pod Sub::Import is the companion to Sub::Exporter.  You can use Sub::Import to get
#pod Sub::Exporter-like import semantics, even if the library you're importing from
#pod used Exporter.pm.
#pod
#pod The synopsis above should say it all.  Where you would usually say:
#pod
#pod   use Some::Library qw(foo bar baz);
#pod
#pod ...to get Exporter.pm semantics, you can now get Sub::Exporter semantics with:
#pod
#pod   use Sub::Import 'Some::Library' => qw(foo bar baz);
#pod
#pod =head1 WARNINGS AND LIMITATIONS
#pod
#pod While you can rename imports, there is no way to customize them, because they
#pod are not being built by generators.  At present, extra arguments for each import
#pod will be thrown away.  In the future, they may become a fatal error.
#pod
#pod Non-subroutine imports will not be importable via this mechanism.
#pod
#pod The regex-like import features of Exporter.pm will be unavailable.  (Will
#pod anyone miss them?)
#pod
#pod =cut

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

=encoding UTF-8

=head1 NAME

Sub::Import - import routines from most anything using Sub::Exporter

=head1 VERSION

version 1.002

=head1 SYNOPSIS

  use Sub::Import 'Some::Library' => (
    some_routine  => { -as => 'some_other_name' },
    other_routine => undef,
  );

Some more examples:

  # import a function with a custom name
  use Sub::Import 'Digest::MD5', md5_hex => {-as => 'md5sum'};

  # import multiple functions, each with its own name
  use Sub::Import 'MIME::Base64',
    encode_base64 => {-as => 'e64'},
    decode_base64 => {-as => 'd64'};

  # Import most functions with the "trig_" prefix, e.g. "trig_log",
  # "trig_sin", "trig_cos", etc.
  use Sub::Import 'Math::Trig', -all => {-prefix => 'trig_'};

  # Import PI-related functions with the "_the_great" suffix, e.g.
  # "pi_the_great", "pi2_the_great", etc.
  use Sub::Import 'Math::Trig', -pi  => {-suffix => '_the_great'};

=head1 DESCRIPTION

Sub::Import is the companion to Sub::Exporter.  You can use Sub::Import to get
Sub::Exporter-like import semantics, even if the library you're importing from
used Exporter.pm.

The synopsis above should say it all.  Where you would usually say:

  use Some::Library qw(foo bar baz);

...to get Exporter.pm semantics, you can now get Sub::Exporter semantics with:

  use Sub::Import 'Some::Library' => qw(foo bar baz);

=head1 PERL VERSION

This library should run on perls released even a long time ago.  It should work
on any version of perl released in the last five years.

Although it may work on older versions of perl, no guarantee is made that the
minimum required version will not be increased.  The version may be increased
for any reason, and there is no promise that patches will be accepted to lower
the minimum required perl.

=head1 WARNINGS AND LIMITATIONS

While you can rename imports, there is no way to customize them, because they
are not being built by generators.  At present, extra arguments for each import
will be thrown away.  In the future, they may become a fatal error.

Non-subroutine imports will not be importable via this mechanism.

The regex-like import features of Exporter.pm will be unavailable.  (Will
anyone miss them?)

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
