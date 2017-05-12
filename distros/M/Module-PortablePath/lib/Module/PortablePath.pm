#########
# Author:        rmp
# Maintainer:    rmp
# Created:       2005-02-14
# Last Modified: $Date: 2008-02-28$
# Id:            $Id$
# Source:        $Source$
# $HeadURL$
#
package Module::PortablePath;
use strict;
use warnings;
use Sys::Hostname;
use Config::IniFiles;
use Carp;
use English qw(-no_match_vars);

our $VERSION = q[0.17];
our $CONFIGS = {
		default => map { m{([[:lower:][:digit:]_./]+)}smix } ($ENV{MODULE_PORTABLEPATH_CONF} || q[/etc/perlconfig.ini]),
	       };

sub config {
  my $cfgfile  = $CONFIGS->{'default'};
  my $hostname = hostname() || q[];

  for my $k (sort { length $a <=> length $b } keys %{$CONFIGS}) {
    if($hostname =~ /$k/smx) {
      $cfgfile = $CONFIGS->{$k};
      last;
    }
  }

  my $config;
  if(-f $cfgfile) {
    $config = Config::IniFiles->new(
				    -file => $cfgfile,
				   );
  } else {
    $config = Config::IniFiles->new();
  }

  return $config;
}

sub import {
  my ($pkg, @args) = @_;
  if(!scalar @args) {
    return;
  }

  my $config = config();
  $pkg->_import_libs($config, @args);
  $pkg->_import_ldlibs($config, @args);

  return;
}

sub _import_libs {
  my ($pkg, $config, @args) = @_;
  my $forward      = {};
  my $reverse      = {};

  for my $param ($config->Parameters('libs')) {
    for my $v (split /[,\s;:]+/smx, $config->val('libs', $param)||q[]) {
      $reverse->{$v} = $param;
      unshift @{$forward->{$param}}, $v;
    }
  }

  my $seentags = {};
  for my $i (@INC) {
    if(!$reverse->{$i}) {
      next;
    }

    my ($tag) = $reverse->{$i} =~ /([[:lower:]]+)/smx;
    $seentags->{$tag} = $reverse->{$i};
  }

  for my $a (@args) {
    if(!$forward->{$a}) {
      carp qq[Use of unknown tag "$a"];
    }
    for my $i (@{$forward->{$a}}) {
      my ($tag) = $reverse->{$i} =~ /([[:lower:]]+)/smx;
      if($seentags->{$tag} && ($seentags->{$tag} ne $reverse->{$i})) {
	carp qq[Import of tag "$a" may clash with tag "$seentags->{$tag}"];
      }
      unshift @INC, $i;
    }
  }
  return;
}

sub _import_ldlibs {
  my ($pkg, $config, @args) = @_;
  my $forward      = {};
  my $reverse      = {};
  my @LDLIBS       = split /:/smx, $ENV{LD_LIBRARY_PATH}||q[];

  for my $param ($config->Parameters('ldlibs')) {
    for my $v (split /[,\s;:]+/smx, $config->val('ldlibs', $param) || q[]) {
      $reverse->{$v} = $param;
      unshift @{$forward->{$param}}, $v;
    }
  }

  my $seentags = {};
  for my $i (@LDLIBS) {
    if(!$reverse->{$i}) {
      next;
    }
    my ($tag) = $reverse->{$i} =~ /([[:lower:]]+)/smx;
    $seentags->{$tag} = $reverse->{$i};
  }

  for my $a (@args) {
    if(!$forward->{$a}) {
      next;
    }

    for my $i (@{$forward->{$a}}) {
      my ($tag) = $reverse->{$i} =~ /([[:lower:]]+)/smx;
      if($seentags->{$tag} && ($seentags->{$tag} ne $reverse->{$i})) {
	carp qq[Import of tag "$a" may clash with tag "$seentags->{$tag}"];
      }
      unshift @LDLIBS, $i;
    }
  }

  $ENV{'LD_LIBRARY_PATH'} = join q[:], @LDLIBS; ## no critic (RequireLocalizedPunctuationVars)
  return;
}

sub dump { ## no critic (Homonyms)
  my $config = config();
  for my $l (qw(Libs LDlibs)) {
    print $l, "\n" or croak $ERRNO;
    for my $s (sort $config->Parameters(lc $l)) {
      printf qq[%-12s %s\n], $s, $config->val(lc $l, $s);
    }
    print "\n\n" or croak $ERRNO;
  }

  return;
}

1;

__END__

=head1 NAME

Module::PortablePath - Perl extension follow modules to exist in
different non-core locations on different systems without having to
refer to explicit library paths in code.

=head1 VERSION

$Revision$

=head1 SYNOPSIS

  use Module::PortablePath qw(tag1 tag2 tag3);

=head1 DESCRIPTION

This module overrides its import() method to fiddle with @INC and
$ENV{'LD_LIBRARY_PATH'}, adding sets of paths for applications as
configured by the system administrator.

It requires Config::IniFiles.

=head1 SUBROUTINES/METHODS

=head2 config - Return a Config::IniFiles object appropriate for the execution environment

  my $cfg = Module::PortablePath->config();

=head2 import - Perform the path modifications on import (or 'use') of this module

  use Module::PortablePath qw(bioperl ensembl core);

  # or

  require Module::PortablePath;
  Module::PortablePath->import(qw(bioperl ensembl core));

=head2 dump - Print out library configuration for this environment

  perl -MModule::PortablePath -e 'Module::PortablePath->dump'

=head1 DIAGNOSTICS

  See Module::PortablePath::dump();

=head1 CONFIGURATION AND ENVIRONMENT

=head1 DEPENDENCIES

Sys::Hostname
Config::IniFiles
Carp

=head1 INCOMPATIBILITIES

=head1 BUGS AND LIMITATIONS

=head1 AUTHOR

Roger Pettett, E<lt>rpettett@cpan.orgE<gt>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2007 GRL, by Roger Pettett

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.4 or,
at your option, any later version of Perl 5 you may have available.

=cut
