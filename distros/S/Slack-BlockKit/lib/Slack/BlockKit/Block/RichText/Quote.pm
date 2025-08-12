package Slack::BlockKit::Block::RichText::Quote 0.005;
# ABSTRACT: a Block Kit rich text "quoted text" block

use Moose;
use MooseX::StrictConstructor;

use Slack::BlockKit::Types qw(ExpansiveElementList Pixels);

#pod =head1 OVERVIEW
#pod
#pod This is a "quote" element, which is formatted something like C<< > >>-prefixed
#pod text in Markdown.
#pod
#pod =cut

use v5.36.0;

#pod =attr border
#pod
#pod This property is meant to be the number of pixels wide the border is.  In
#pod practice, the author has only found this to cause Slack to reject Block Kit
#pod structures.
#pod
#pod =cut

has border => (
  is => 'ro',
  isa => Pixels(),
  predicate => 'has_border',
);

#pod =attr elements
#pod
#pod This is an arrayref of rich text elements.
#pod
#pod =cut

has elements => (
  isa => ExpansiveElementList(),
  traits  => [ 'Array' ],
  handles => { elements => 'elements' },
);

sub as_struct ($self) {
  return {
    type => 'rich_text_quote',
    elements => [ map {; $_->as_struct } $self->elements ],
    ($self->has_border ? (border => $self->border) : ()),
  };
}

no Moose;
__PACKAGE__->meta->make_immutable;

__END__

=pod

=encoding UTF-8

=head1 NAME

Slack::BlockKit::Block::RichText::Quote - a Block Kit rich text "quoted text" block

=head1 VERSION

version 0.005

=head1 OVERVIEW

This is a "quote" element, which is formatted something like C<< > >>-prefixed
text in Markdown.

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

=head2 border

This property is meant to be the number of pixels wide the border is.  In
practice, the author has only found this to cause Slack to reject Block Kit
structures.

=head2 elements

This is an arrayref of rich text elements.

=head1 AUTHOR

Ricardo SIGNES <cpan@semiotic.systems>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2024 by Ricardo SIGNES.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
