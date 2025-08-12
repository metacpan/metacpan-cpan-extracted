package Slack::BlockKit::Block::RichText::List 0.005;
# ABSTRACT: a Block Kit rich text list element
use Moose;
use MooseX::StrictConstructor;

use Moose::Util::TypeConstraints qw(class_type enum);
use MooseX::Types::Moose qw(ArrayRef);
use Slack::BlockKit::Types qw(Pixels RichTextArray);

#pod =head1 OVERVIEW
#pod
#pod This represents a rich text list, which will be rendered as either a bullet or
#pod numbered list.
#pod
#pod =cut

use v5.36.0;

#pod =attr elements
#pod
#pod This must be an arrayref of L<rich text
#pod section|Slack::BlockKit::Block::RichText::Section> objects.  Each section will
#pod be one item in the list.
#pod
#pod =cut

has elements => (
  isa => RichTextArray(),
  traits  => [ 'Array' ],
  handles => { elements => 'elements' },
);

#pod =attr indent
#pod
#pod This optional attribute is a count of pixels to indent the list.  The author
#pod has never managed to use this successfully.
#pod
#pod =attr offset
#pod
#pod This optional attribute is a count of pixels to offset the list.  The author
#pod has never managed to use this successfully.
#pod
#pod =attr border
#pod
#pod This optional attribute is a count of pixels for the list's border width.  The
#pod author has never managed to use this successfully.
#pod
#pod =cut

# I don't know how to use these successfully. -- rjbs, 2024-06-29
my @PX_PROPERTIES = qw(indent offset border);
for my $name (@PX_PROPERTIES) {
  has $name => (
    is => 'ro',
    isa => Pixels(),
    predicate => "has_$name",
  );
}

#pod =attr style
#pod
#pod This required attribute is I<not> the text style, but the list style.  It may
#pod be either C<bullet> or C<ordered>.
#pod
#pod =cut

has style => (
  is  => 'ro',
  isa => enum([ qw(bullet ordered) ]),
  required => 1,
);

sub as_struct ($self) {
  return {
    type => 'rich_text_list',
    elements => [ map {; $_->as_struct } $self->elements ],
    style => $self->style,

    (map {; my $p = "has_$_"; ($self->$p ? ($_ => $self->$_) : ()) }
      @PX_PROPERTIES)
  };
}

no Moose::Util::TypeConstraints;
no Moose;
__PACKAGE__->meta->make_immutable;

__END__

=pod

=encoding UTF-8

=head1 NAME

Slack::BlockKit::Block::RichText::List - a Block Kit rich text list element

=head1 VERSION

version 0.005

=head1 OVERVIEW

This represents a rich text list, which will be rendered as either a bullet or
numbered list.

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

This must be an arrayref of L<rich text
section|Slack::BlockKit::Block::RichText::Section> objects.  Each section will
be one item in the list.

=head2 indent

This optional attribute is a count of pixels to indent the list.  The author
has never managed to use this successfully.

=head2 offset

This optional attribute is a count of pixels to offset the list.  The author
has never managed to use this successfully.

=head2 border

This optional attribute is a count of pixels for the list's border width.  The
author has never managed to use this successfully.

=head2 style

This required attribute is I<not> the text style, but the list style.  It may
be either C<bullet> or C<ordered>.

=head1 AUTHOR

Ricardo SIGNES <cpan@semiotic.systems>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2024 by Ricardo SIGNES.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
