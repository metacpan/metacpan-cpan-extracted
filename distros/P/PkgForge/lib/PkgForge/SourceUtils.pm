package PkgForge::SourceUtils;    # -*-perl-*-
use strict;
use warnings;

# $Id: SourceUtils.pm.in 16519 2011-03-25 15:50:07Z squinney@INF.ED.AC.UK $
# $Source:$
# $Revision: 16519 $
# $HeadURL: https://svn.lcfg.org/svn/source/tags/PkgForge/PkgForge_1_4_8/lib/PkgForge/SourceUtils.pm.in $
# $Date: 2011-03-25 15:50:07 +0000 (Fri, 25 Mar 2011) $

our $VERSION = '1.4.8';

use English qw(-no_match_vars);
use Module::Find ();
use Readonly;
use UNIVERSAL::require;

use Exporter;
our @ISA       = qw(Exporter);
our @EXPORT_OK = qw($SOURCE_PACKAGE_BASE $BUILDER_BASE);

Readonly our $SOURCE_PACKAGE_BASE => 'PkgForge::Source';
Readonly our $BUILDER_BASE        => 'PkgForge::Builder';

sub list_builder_types {

    my @modules = Module::Find::findsubmod($BUILDER_BASE);
    my @types = qw(None);
    for my $mod (@modules) {
        if ( $mod =~ m/^\Q$BUILDER_BASE\E::(.+)$/ ) {
            push @types, $1;
        }
    }

    return @types;
}

sub find_builder {
    my ($type) = @_;

    my $module = join q{::}, $BUILDER_BASE, $type;

    my $loaded = $module->require;
    if ( !$loaded ) {
        die "Could not load '$module' : $UNIVERSAL::require::ERROR\n";
    }

    return $module;
}

sub load_source_handler {
    my ($type) = @_;

    # This is used to verify and untaint the type
    if ( $type =~ m/^(\w+)$/ ) {
        $type = $1;
    } else {
        die "Source package type '$type' is not well formed.\n";
    }

    my @valid_types = list_source_types();

    my $pkg_class;
    if ( grep { $_ eq $type } @valid_types ) {
        $pkg_class = join q{::}, $SOURCE_PACKAGE_BASE, $type;
        $pkg_class->require or die $UNIVERSAL::require::ERROR;
    } else {
        die "Source package type '$type' is not supported.\n";
    }

    return $pkg_class;
}

sub list_source_types {

    my @modules = list_handlers();
    my @types = qw(None);
    for my $mod (@modules) {
        if ( $mod =~ m/^\Q$SOURCE_PACKAGE_BASE\E::(.+)$/ ) {
            push @types, $1;
        }
    }

    return @types;
}

sub list_handlers {

    # Doing this in a single step results in weirdness...
    my @modules = Module::Find::findsubmod($SOURCE_PACKAGE_BASE);
    my @sorted  = sort @modules;
    return @sorted;
}

sub find_handler {
    my ($file) = @_;

    for my $module ( list_handlers() ) {
        my $loaded = $module->require;
        if ( !$loaded ) {
            warn "Could not load '$module' : $UNIVERSAL::require::ERROR\n";
            next;
        }

        return $module if $module->can_handle($file);
    }

    return;
}

sub unpack_packages {
  my ($data) = @_;

  my @packages;
  if ( defined $data && ref $data eq 'ARRAY' ) {
    for my $item ( @{$data} ) {
      if ( !defined $item || ref $item ne 'HASH' ) {
        next;
      }

      my $type = $item->{type};
      if ( !defined $type ) {
        die "Source package type not defined, cannot load packages data'\n";
      }

      my $pkg_class = eval { load_source_handler($type) };
      if ( !defined $pkg_class || $EVAL_ERROR ) {
	die "Cannot load a source package of type '$type'\n";
      }

      my %pkg;
      for my $attr ( $pkg_class->meta->get_all_attributes ) {
        my $name  = $attr->name;
	my $value = $item->{$name};

        if ( $attr->does('PkgForge::Meta::Attribute::Trait::Serialise') ) {
          if ( $attr->has_unpack_method ) {
            my $method = $attr->unpack;
	    if ( ref $method eq 'CODE') {
	      $value = $method->($value);
	    } elsif ( $pkg_class->can($method) ) {
              $value = $pkg_class->$method($value);
            } else {
              die "Could not find '$method' source package unserialisation method\n";
            }
          }

	  $pkg{$name} = $value if defined $value;
        }

      }

      my $pkg_obj = $pkg_class->new(%pkg);

      push @packages, $pkg_obj;
    }
  }

  return \@packages;
}

sub pack_packages {
  my ($packages) = @_;

  my @dump;
  for my $package (@{$packages}) {
    my %data;
    for my $attr ( $package->meta->get_all_attributes ) {
      my $name  = $attr->name;
      my $value = $attr->get_value($package);

      if ( $attr->does('PkgForge::Meta::Attribute::Trait::Serialise') ) {

        if ( $attr->has_pack_method ) {
          my $method = $attr->pack;
	  if ( ref $method eq 'CODE') {
	    $value = $method->($value);
	  } elsif ( $package->can($method) ) {
            $value = $package->$method($value);
          } else {
            die "Could not find '$method' source package serialisation method\n";
          }
        }

	$data{$name} = $value;
      }

    }

    push @dump, {%data};
  }

  return \@dump;
}

1;
__END__

=head1 NAME

PkgForge::SourceUtils - Utilities to help with source module handling

=head1 VERSION

This documentation refers to PkgForge::SourceUtils version 1.4.8

=head1 SYNOPSIS

    use PkgForge::SourceUtils;

    my @modules = PkgForge::SourceUtils::list_handlers();

    my $module = PkgForge::SourceUtils::find_handler($file);

    if ( defined $module ) {
       my $pkg = $module->new( ... );
       $pkg->validate();
    }

=head1 DESCRIPTION

This module provides a set of utilities which are commonly useful to
handling source packages with L<PkgForge::Source> modules.

=head1 SUBROUTINES/METHODS

=over

=item list_source_types

This lists the types of source packages which are supported. It does
this by using a similar approach to C<list_handlers> except it returns
the short name rather than the full module name. For example,
L<PkgForge::Source::SRPM> has a type of C<SRPM>.

=item list_handlers

This lists all available source package handler modules. You will get
a sorted list of the names of all modules under the
L<PkgForge::Source> base.

=item load_source_handler($type)

This takes the type of a source package and attempts to find the
associated module in the L<PkgForge::Source> namespace. This will die
if the type is not a valid module name or the module cannot be loaded.

=item find_handler($file)

This will attempt to find a suitable source package handler for a
given file. For example, an SRPM might be handled by
L<PkgForge::Source::SRPM>. If none is found then undef will be
returned. Note that if the source package type is supported by
multiple modules then the first to be found wins.

=item list_builder_types()

This lists all the available types of source package builder
modules. Effectively, you will get a sorted list of the short names of
all modules under the L<PkgForge::Builder> base. For example, the
module L<PkgForge::Builder::RPM> will have a type of C<RPM>.

=item find_builder($type)

Finds and loads the specified type of source package builder
module. Returns a string containing the name of the module which can
be used to call the C<new()> method.

=head1 DEPENDENCIES

This module requires L<Module::Find>, L<Readonly> and L<UNIVERSAL::require>.

=head1 SEE ALSO

L<PkgForge>, L<PkgForge::Source>, L<PkgForge::Source::SRPM>,
L<PkgForge::Builder>

=head1 PLATFORMS

This is the list of platforms on which we have tested this
software. We expect this software to work on any Unix-like platform
which is supported by Perl.

ScientificLinux5, Fedora13

=head1 BUGS AND LIMITATIONS

Please report any bugs or problems (or praise!) to bugs@lcfg.org,
feedback and patches are also always very welcome.

=head1 AUTHOR

    Stephen Quinney <squinney@inf.ed.ac.uk>

=head1 LICENSE AND COPYRIGHT

    Copyright (C) 2010-2011 University of Edinburgh. All rights reserved.

This library is free software; you can redistribute it and/or modify
it under the terms of the GPL, version 2 or later.

=cut

