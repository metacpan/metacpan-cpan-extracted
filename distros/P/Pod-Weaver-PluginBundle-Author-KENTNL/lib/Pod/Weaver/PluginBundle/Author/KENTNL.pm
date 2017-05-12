use 5.006; # our
use strict;
use warnings;

package Pod::Weaver::PluginBundle::Author::KENTNL;

our $VERSION = '0.001003';

# ABSTRACT: KENTNL's amazing Pod::Weaver Plugin Bundle.

our $AUTHORITY = 'cpan:KENTNL'; # AUTHORITY

use Moo qw( has with );
with 'Pod::Weaver::PluginBundle::Author::KENTNL::Role::Easy';





sub bundle_prefix       { return '@A:KNL' }
sub mvp_aliases         { return { command => qw[commands] } }
sub mvp_multivalue_args { return qw( commands ) }





has 'commands' => (
  is        => ro  =>,
  predicate => 'has_commands',
  lazy      => 1,
  default   => sub { [] },
);





sub instance_config {
  my ($self) = @_;
  $self->inhale_bundle('@Author::KENTNL::Core');
  $self->inhale_bundle('@Author::KENTNL::Prelude');
  my (@config);
  if ( $self->has_commands ) {
    push @config, { payload => { 'commands' => $self->commands } };
  }
  $self->inhale_bundle( '@Author::KENTNL::Collectors', @config );
  $self->inhale_bundle('@Author::KENTNL::Postlude');
  return;
}

no Moo;

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Pod::Weaver::PluginBundle::Author::KENTNL - KENTNL's amazing Pod::Weaver Plugin Bundle.

=head1 VERSION

version 0.001003

=head1 QUICK REFERENCE

  [@Author::KENTNL]

  -~- Inherited from @Author::KENTNL::Collectors -~-
  ; command[].default = [ required function attr method pfunction pattr pmethod ]
  ; command[].entry_type[0] = KNOWNCOMMANDNAME
  ; command[].entry_type[1] = COMMANDNAME = DESCRIPTION
  ;        KNOWNCOMMANDNAME.enums =
  ;             = required      ; REQUIRED METHODS
  ;             = function      ; FUNCTIONS
  ;             = method        ; METHODS
  ;             = attr          ; ATTRIBUTES
  ;             = cattr         ; ATTRIBUTES / CONSTRUCTOR ARGUMENTS
  ;             = pfuncton      ; PRIVATE FUNCTIONS
  ;             = pmethod       ; PRIVATE METHODS
  ;             = pattr         ; PRIVATE ATTRIBUTES

=head1 SYNOPSIS

  [@Author::KENTNL]

This is basically the same as

  [@Author::KENTNL::Core]

  [@Author::KENTNL::Prelude]

  [@Author::KENTNL::Collectors]

  [@Author::KENTNL::Postlude]

=over 4

=item * C<[@Author::KENTNL::Core]> : L<<
C<Pod::Weaver::PluginBundle::Author::KENTNL::Core>
|Pod::Weaver::PluginBundle::Author::KENTNL::Core
>>

=item * C<[@Author::KENTNL::Prelude]> : L<<
C<Pod::Weaver::PluginBundle::Author::KENTNL::Prelude>
|Pod::Weaver::PluginBundle::Author::KENTNL::Prelude
>>

=item * C<[@Author::KENTNL::Collectors]> : L<<
C<Pod::Weaver::PluginBundle::Author::KENTNL::Collectors>
|Pod::Weaver::PluginBundle::Author::KENTNL::Collectors
>>

=item * C<[@Author::KENTNL::Postlude]> : L<<
C<Pod::Weaver::PluginBundle::Author::KENTNL::Postlude>
|Pod::Weaver::PluginBundle::Author::KENTNL::Postlude
>>

=back

=for Pod::Coverage bundle_prefix mvp_aliases mvp_multivalue_args

=for Pod::Coverage has_commands

=for Pod::Coverage instance_config

=head1 AUTHOR

Kent Fredric <kentnl@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2017 by Kent Fredric <kentfredric@gmail.com>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
