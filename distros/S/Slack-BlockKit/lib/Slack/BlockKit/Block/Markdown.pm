package Slack::BlockKit::Block::Markdown 0.005;
# ABSTRACT: a Block Kit Markdown block

use Moose;
use MooseX::StrictConstructor;

with 'Slack::BlockKit::Role::Block';

#pod =head1 OVERVIEW
#pod
#pod This object represents a "markdown" block.  These blocks only have one special
#pod attribute: the text they display.
#pod
#pod =cut

use v5.36.0;

use Moose::Util::TypeConstraints qw(class_type);

#pod =attr text
#pod
#pod The C<text> attribute must be a I<string>.  This is in contrast to most other
#pod Block Kit blocks, where the C<text> attribute is a text composition object.
#pod The Markdown block acts sort of like a text composition object, but it can't be
#pod used as one.  It can only be used as a block in a section.
#pod
#pod =cut

has text => (
  is  => 'ro',
  isa => 'Str',
  required => 1,
);

sub as_struct ($self) {
  return {
    type  => 'markdown',
    text  => $self->text,
  };
}

no Moose;
__PACKAGE__->meta->make_immutable;

__END__

=pod

=encoding UTF-8

=head1 NAME

Slack::BlockKit::Block::Markdown - a Block Kit Markdown block

=head1 VERSION

version 0.005

=head1 OVERVIEW

This object represents a "markdown" block.  These blocks only have one special
attribute: the text they display.

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

=head2 text

The C<text> attribute must be a I<string>.  This is in contrast to most other
Block Kit blocks, where the C<text> attribute is a text composition object.
The Markdown block acts sort of like a text composition object, but it can't be
used as one.  It can only be used as a block in a section.

=head1 AUTHOR

Ricardo SIGNES <cpan@semiotic.systems>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2024 by Ricardo SIGNES.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
