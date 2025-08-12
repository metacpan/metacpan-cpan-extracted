package Slack::BlockKit::BlockCollection 0.005;
# ABSTRACT: a collection of Block Kit blocks
use Moose;

#pod =head1 OVERVIEW
#pod
#pod This is the very top level "array of Block Kit blocks" object that exists
#pod mostly to serve as a container for the blocks that are your real message.  You
#pod don't exactly need it, but its C<< ->as_struct >> method will collect all the
#pod structs created by its contained blocks, so it's easy to pass around as "the
#pod thing that gets sent to Slack".
#pod
#pod =cut

use v5.36.0;

use MooseX::Types::Moose qw(ArrayRef);
use Moose::Util::TypeConstraints qw(role_type);

#pod =attr blocks
#pod
#pod This is an arrayref of objects that implement L<Slack::BlockKit::Role::Block>.
#pod It must be defined and non-empty, or an exception will be raised.
#pod
#pod =cut

has blocks => (
  isa => ArrayRef([ role_type('Slack::BlockKit::Role::Block') ]),
  traits  => [ 'Array' ],
  handles => { blocks => 'elements', block_count => 'count' },
  predicate => '_has_blocks',
);

sub BUILD ($self, @) {
  Carp::croak("a BlockCollection's list of blocks can't be empty")
    unless $self->_has_blocks and $self->block_count;
}

sub as_struct ($self) {
  return [ map {; $_->as_struct } $self->blocks ];
}

sub TO_JSON ($self) {
  return $self->as_struct;
}

no Moose;
no MooseX::Types::Moose;
no Moose::Util::TypeConstraints;
__PACKAGE__->meta->make_immutable;

__END__

=pod

=encoding UTF-8

=head1 NAME

Slack::BlockKit::BlockCollection - a collection of Block Kit blocks

=head1 VERSION

version 0.005

=head1 OVERVIEW

This is the very top level "array of Block Kit blocks" object that exists
mostly to serve as a container for the blocks that are your real message.  You
don't exactly need it, but its C<< ->as_struct >> method will collect all the
structs created by its contained blocks, so it's easy to pass around as "the
thing that gets sent to Slack".

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

=head2 blocks

This is an arrayref of objects that implement L<Slack::BlockKit::Role::Block>.
It must be defined and non-empty, or an exception will be raised.

=head1 AUTHOR

Ricardo SIGNES <cpan@semiotic.systems>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2024 by Ricardo SIGNES.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
