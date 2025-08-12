package Slack::BlockKit::Block::Context 0.005;
# ABSTRACT: a Block Kit context block, used to collect images and text

use Moose;
use MooseX::StrictConstructor;

with 'Slack::BlockKit::Role::Block';

#pod =head1 OVERVIEW
#pod
#pod This represents a C<context> block, which is commonly used to contain text to
#pod be sent.  Don't confuse this class with L<Slack::BlockKit::Block::RichText> or
#pod L<Slack::BlockKit::Block::RichText::Section>, which are used to present I<rich>
#pod text.  A "normal" section block can only present rich text in the form of
#pod C<mrkdwn>-type text objects.
#pod
#pod A C<context> block is similar to a C<section> block, but can contain images.
#pod Also, it seems like a C<section> block is a bit smaller, textwise?  It's a bit
#pod of a muddle.
#pod
#pod =cut

use v5.36.0;

use Moose::Util::TypeConstraints qw(class_type);
use MooseX::Types::Moose qw(ArrayRef);

use Slack::BlockKit::Types qw(ContextElementList);

#pod =attr elements
#pod
#pod This must be an arrayref of element objects, of either text or image types.
#pod (At present, though, Slack::BlockKit does not support image elements.)
#pod
#pod =cut

has elements => (
  isa => ContextElementList(),
  traits  => [ 'Array' ],
  handles => { elements => 'elements' },
);

sub as_struct ($self) {
  return {
    type => 'context',
    elements => [ map {; $_->as_struct } $self->elements ],
  }
}

no Moose;
no Moose::Util::TypeConstraints;
no MooseX::Types::Moose;
__PACKAGE__->meta->make_immutable;

__END__

=pod

=encoding UTF-8

=head1 NAME

Slack::BlockKit::Block::Context - a Block Kit context block, used to collect images and text

=head1 VERSION

version 0.005

=head1 OVERVIEW

This represents a C<context> block, which is commonly used to contain text to
be sent.  Don't confuse this class with L<Slack::BlockKit::Block::RichText> or
L<Slack::BlockKit::Block::RichText::Section>, which are used to present I<rich>
text.  A "normal" section block can only present rich text in the form of
C<mrkdwn>-type text objects.

A C<context> block is similar to a C<section> block, but can contain images.
Also, it seems like a C<section> block is a bit smaller, textwise?  It's a bit
of a muddle.

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

=head2 elements

This must be an arrayref of element objects, of either text or image types.
(At present, though, Slack::BlockKit does not support image elements.)

=head1 AUTHOR

Ricardo SIGNES <cpan@semiotic.systems>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2024 by Ricardo SIGNES.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
