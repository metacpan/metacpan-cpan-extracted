use v5.14;
use strict;
use warnings;

package Pantry::Model::EnvRunList;
# ABSTRACT: Standalone runlist object for environment runlists
our $VERSION = '0.012'; # VERSION

use Moose 2;
use namespace::autoclean;

with 'Pantry::Role::Runlist';

1;


# vim: ts=2 sts=2 sw=2 et:

__END__

=pod

=head1 NAME

Pantry::Model::EnvRunList - Standalone runlist object for environment runlists

=head1 VERSION

version 0.012

=head1 SYNOPSIS

  use Pantry::Model::EnvRunList;

=head1 DESCRIPTION

Chef Roles can have environment-specific runlists.  This is a standalone
runlist object that merely instantiates the the Pantry::Role::Runlist role.

=for Pod::Coverage method_names_here

=head1 AUTHOR

David Golden <dagolden@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2011 by David Golden.

This is free software, licensed under:

  The Apache License, Version 2.0, January 2004

=cut
