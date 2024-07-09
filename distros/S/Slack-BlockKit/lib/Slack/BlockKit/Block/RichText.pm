package Slack::BlockKit::Block::RichText 0.002;
# ABSTRACT: the top-level rich text block in Block Kit

use Moose;
use MooseX::StrictConstructor;
use Slack::BlockKit::Types qw(RichTextBlocks);

#pod =head1 OVERVIEW
#pod
#pod The RichText block is pretty boring, but must exist to contain all the other
#pod rich text object:
#pod
#pod =for :list
#pod * L<User        |Slack::BlockKit::Block::RichText::User>
#pod * L<Link        |Slack::BlockKit::Block::RichText::Link>
#pod * L<UserGroup   |Slack::BlockKit::Block::RichText::UserGroup>
#pod * L<List        |Slack::BlockKit::Block::RichText::List>
#pod * L<Channel     |Slack::BlockKit::Block::RichText::Channel>
#pod * L<Emoji       |Slack::BlockKit::Block::RichText::Emoji>
#pod * L<Quote       |Slack::BlockKit::Block::RichText::Quote>
#pod * L<Preformatted|Slack::BlockKit::Block::RichText::Preformatted>
#pod * L<Section     |Slack::BlockKit::Block::RichText::Section>
#pod * L<Text        |Slack::BlockKit::Block::RichText::Text>
#pod
#pod As usual, these classes are I<lightly> documented in the Slack::BlockKit
#pod distribution, but to really understand how they're meant to be used, see the
#pod Slack Block Kit documentation on Slack.
#pod
#pod =cut

with 'Slack::BlockKit::Role::Block';

use v5.36.0;

#pod =attr elements
#pod
#pod This must be an arrayref of the kinds of objects that are permitted within a
#pod rich test block:
#pod
#pod =for :list
#pod * L<List        |Slack::BlockKit::Block::RichText::List>
#pod * L<Quote       |Slack::BlockKit::Block::RichText::Quote>
#pod * L<Preformatted|Slack::BlockKit::Block::RichText::Preformatted>
#pod * L<Section     |Slack::BlockKit::Block::RichText::Section>
#pod
#pod =cut

has elements => (
  isa => RichTextBlocks(),
  traits  => [ 'Array' ],
  handles => { elements => 'elements' },
);

sub as_struct ($self) {
  return {
    type => 'rich_text',
    elements => [ map {; $_->as_struct } $self->elements ],
  };
}

no Slack::BlockKit::Types;
no Moose;
__PACKAGE__->meta->make_immutable;

__END__

=pod

=encoding UTF-8

=head1 NAME

Slack::BlockKit::Block::RichText - the top-level rich text block in Block Kit

=head1 VERSION

version 0.002

=head1 OVERVIEW

The RichText block is pretty boring, but must exist to contain all the other
rich text object:

=over 4

=item *

L<User        |Slack::BlockKit::Block::RichText::User>

=item *

L<Link        |Slack::BlockKit::Block::RichText::Link>

=item *

L<UserGroup   |Slack::BlockKit::Block::RichText::UserGroup>

=item *

L<List        |Slack::BlockKit::Block::RichText::List>

=item *

L<Channel     |Slack::BlockKit::Block::RichText::Channel>

=item *

L<Emoji       |Slack::BlockKit::Block::RichText::Emoji>

=item *

L<Quote       |Slack::BlockKit::Block::RichText::Quote>

=item *

L<Preformatted|Slack::BlockKit::Block::RichText::Preformatted>

=item *

L<Section     |Slack::BlockKit::Block::RichText::Section>

=item *

L<Text        |Slack::BlockKit::Block::RichText::Text>

=back

As usual, these classes are I<lightly> documented in the Slack::BlockKit
distribution, but to really understand how they're meant to be used, see the
Slack Block Kit documentation on Slack.

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

This must be an arrayref of the kinds of objects that are permitted within a
rich test block:

=over 4

=item *

L<List        |Slack::BlockKit::Block::RichText::List>

=item *

L<Quote       |Slack::BlockKit::Block::RichText::Quote>

=item *

L<Preformatted|Slack::BlockKit::Block::RichText::Preformatted>

=item *

L<Section     |Slack::BlockKit::Block::RichText::Section>

=back

=head1 AUTHOR

Ricardo SIGNES <rjbs@semiotic.systems>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2024 by Ricardo SIGNES.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
