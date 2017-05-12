=head1 NAME

Template::TAL::Language::METAL - Implement METAL

=head1 SYNOPSIS

=head1 DESCRIPTION

This module is not implemented - it's here as a placeholder for the
METAL implementation.
(http://www.zope.org/Wikis/DevSite/Projects/ZPT/METAL/MetalSpecification11)

=cut

package Template::TAL::Language::METAL;
use warnings;
use strict;
use Carp qw( croak );
use base qw( Template::TAL::Language );
use Template::TAL::ValueParser;

sub namespace { 'http://xml.zope.org/namespaces/metal' }

sub tags { qw( define-macro extend-macro use-macro define-slot use-slot ) }

=head1 METHODS

=over

=item provider

=cut

sub provider {
  my $self = shift;
  return $self->{provider} unless @_;
  $self->{provider} = shift;
  return $self;
}

sub process_define_macro {
  my ($self, $parent, $node, $value, $local_context, $global_context) = @_;
  $self->{macros}{ $value } = $node;
  return (); # remove the macro definition node.
}

sub process_extend_macro {
  my ($self, $parent, $node, $value, $local_context, $global_context) = @_;
  return $node; # don't replace node
}

sub process_use_macro {
  my ($self, $parent, $node, $value, $local_context, $global_context) = @_;
  my $macro = $self->{macros}{$value} or die "no such macro '$value'\n";
  my $new = $macro->cloneNode(1); # deep clone
  $parent->_process_node( $new, $local_context, $global_context );
  return $new;
}

sub process_define_slot {
  my ($self, $parent, $node, $value, $local_context, $global_context) = @_;
  return $node; # don't replace node
}

sub process_use_slot {
  my ($self, $parent, $node, $value, $local_context, $global_context) = @_;
  return $node; # don't replace node
}

=back

=head1 COPYRIGHT

Written by Tom Insam, Copyright 2005 Fotango Ltd. All Rights Reserved

This program is free software; you can redistribute
it and/or modify it under the same terms as Perl itself.

=cut

1;
