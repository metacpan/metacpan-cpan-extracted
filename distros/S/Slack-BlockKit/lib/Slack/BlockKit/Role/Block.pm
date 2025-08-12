package Slack::BlockKit::Role::Block 0.005;
# ABSTRACT: a Block Kit block object

use Moose::Role;

use v5.36.0;

#pod =head1 OVERVIEW
#pod
#pod This role is composed by any "block" in Block Kit.  The definition of what is
#pod or isn't a block is not well defined, but here it means "anything that can be
#pod turned into a struct and has an optional C<block_id> attribute".
#pod
#pod =attr block_id
#pod
#pod This is an optional string, which will become the C<block_id> of this object in
#pod the emitted structure.
#pod
#pod =cut

has block_id => (
  is  => 'ro',
  isa => 'Str',
  predicate => 'has_block_id',
);

#pod =method as_struct
#pod
#pod All classes composing Block must provide an C<as_struct> method.  Its result is
#pod decorated so that the C<block_id> of this block, if any, is added to the
#pod returned structure.
#pod
#pod =cut

requires 'as_struct';

around as_struct => sub ($orig, $self, @rest) {
  my $struct = $self->$orig(@rest);

  if ($self->has_block_id) {
    $struct->{block_id} = $self->block_id;
  }

  return $struct;
};

no Moose::Role;
1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Slack::BlockKit::Role::Block - a Block Kit block object

=head1 VERSION

version 0.005

=head1 OVERVIEW

This role is composed by any "block" in Block Kit.  The definition of what is
or isn't a block is not well defined, but here it means "anything that can be
turned into a struct and has an optional C<block_id> attribute".

=head1 PERL VERSION

This module should work on any version of perl still receiving updates from
the Perl 5 Porters.  This means it should work on any version of perl
released in the last two to three years.  (That is, if the most recently
released version is v5.40, then this module should work on both v5.40 and
v5.38.)

Although it may work on older versions of perl, no guarantee is made that the
minimum required version will not be increased.  The version may be increased
for any reason, and there is no promise that patches will be accepted to
lower the minimum required perl.

=head1 ATTRIBUTES

=head2 block_id

This is an optional string, which will become the C<block_id> of this object in
the emitted structure.

=head1 METHODS

=head2 as_struct

All classes composing Block must provide an C<as_struct> method.  Its result is
decorated so that the C<block_id> of this block, if any, is added to the
returned structure.

=head1 AUTHOR

Ricardo SIGNES <cpan@semiotic.systems>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2024 by Ricardo SIGNES.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
