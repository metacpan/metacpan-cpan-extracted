package Slack::BlockKit::Block::RichText::Section 0.003;
# ABSTRACT: a collection of rich text elements

use Moose;
use MooseX::StrictConstructor;

use Slack::BlockKit::Types qw(ExpansiveElementList);

#pod =head1 OVERVIEW
#pod
#pod This object represents a rich text section, which is just an array of rich text
#pod elements.  For more info on what you can put in a rich text section, consult
#pod the Slack docs.
#pod
#pod =cut

use v5.36.0;

#pod =attr elements
#pod
#pod This must be an arrayref of RichText element objects, from the approved list
#pod according to the Block Kit docs.
#pod
#pod =cut

has elements => (
  isa => ExpansiveElementList(),
  traits  => [ 'Array' ],
  handles => { elements => 'elements' },
);

sub as_struct ($self) {
  return {
    type => 'rich_text_section',
    elements => [ map {; $_->as_struct } $self->elements ],
  };
}

no Moose;
no Slack::BlockKit::Types;
__PACKAGE__->meta->make_immutable;

__END__

=pod

=encoding UTF-8

=head1 NAME

Slack::BlockKit::Block::RichText::Section - a collection of rich text elements

=head1 VERSION

version 0.003

=head1 OVERVIEW

This object represents a rich text section, which is just an array of rich text
elements.  For more info on what you can put in a rich text section, consult
the Slack docs.

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

This must be an arrayref of RichText element objects, from the approved list
according to the Block Kit docs.

=head1 AUTHOR

Ricardo SIGNES <cpan@semiotic.systems>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2024 by Ricardo SIGNES.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
