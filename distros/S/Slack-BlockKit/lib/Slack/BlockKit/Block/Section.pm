package Slack::BlockKit::Block::Section 0.003;
# ABSTRACT: a Block Kit section block, used to collect text

use Moose;
use MooseX::StrictConstructor;

with 'Slack::BlockKit::Role::Block';

#pod =head1 OVERVIEW
#pod
#pod This represents a C<section> block, which is commonly used to contain text to
#pod be sent.  Don't confuse this class with L<Slack::BlockKit::Block::RichText> or
#pod L<Slack::BlockKit::Block::RichText::Section>, which are used to present I<rich>
#pod text.  A "normal" section block can only present rich text in the form of
#pod C<mrkdwn>-type text objects.
#pod
#pod =cut

use v5.36.0;

use Moose::Util::TypeConstraints qw(class_type);
use MooseX::Types::Moose qw(ArrayRef);

# I have intentionally omitted "accessory" for now.

#pod =attr text
#pod
#pod This is a L<text composition object|Slack::BlockKit::CompObj::Text> with the
#pod text to be displayed in this block.
#pod
#pod If you provide C<text>, then providing C<fields> is an error and will cause an
#pod exception to be raised.
#pod
#pod =cut

has text => (
  is  => 'ro',
  isa => class_type('Slack::BlockKit::CompObj::Text'),
  predicate => 'has_text',
);

#pod =attr fields
#pod
#pod This is a an arrayref of L<text composition
#pod object|Slack::BlockKit::CompObj::Text> with the text to be displayed in this
#pod block.  These objects will be displayed in two columns, generally.
#pod
#pod If you provide C<fields>, then providing C<text> is an error and will cause an
#pod exception to be raised.
#pod
#pod =cut

has fields => (
  isa => ArrayRef([ class_type('Slack::BlockKit::CompObj::Text') ]),
  predicate => 'has_fields',
  traits    => [ 'Array' ],
  handles   => { fields => 'elements' },
);

sub BUILD ($self, @) {
  Carp::croak("neither text nor fields provided in Slack::BlockKit::Block::Section construction")
    unless $self->has_text or $self->has_fields;

  Carp::croak("both text and fields provided in Slack::BlockKit::Block::Section construction")
    if $self->has_text and $self->has_fields;
}

sub as_struct ($self) {
  return {
    type => 'section',
    ($self->has_text
      ? (text => $self->text->as_struct)
      : ()),
    ($self->has_fields
      ? (fields => [ map {; $_->as_struct } $self->fields ])
      : ()),
  };
}

no Moose;
no Moose::Util::TypeConstraints;
no MooseX::Types::Moose;
__PACKAGE__->meta->make_immutable;

__END__

=pod

=encoding UTF-8

=head1 NAME

Slack::BlockKit::Block::Section - a Block Kit section block, used to collect text

=head1 VERSION

version 0.003

=head1 OVERVIEW

This represents a C<section> block, which is commonly used to contain text to
be sent.  Don't confuse this class with L<Slack::BlockKit::Block::RichText> or
L<Slack::BlockKit::Block::RichText::Section>, which are used to present I<rich>
text.  A "normal" section block can only present rich text in the form of
C<mrkdwn>-type text objects.

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

This is a L<text composition object|Slack::BlockKit::CompObj::Text> with the
text to be displayed in this block.

If you provide C<text>, then providing C<fields> is an error and will cause an
exception to be raised.

=head2 fields

This is a an arrayref of L<text composition
object|Slack::BlockKit::CompObj::Text> with the text to be displayed in this
block.  These objects will be displayed in two columns, generally.

If you provide C<fields>, then providing C<text> is an error and will cause an
exception to be raised.

=head1 AUTHOR

Ricardo SIGNES <cpan@semiotic.systems>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2024 by Ricardo SIGNES.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
