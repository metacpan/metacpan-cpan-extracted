package Slack::BlockKit::CompObj::Text 0.001;
# ABSTRACT: a BlockKit "composition object" for text
use Moose;
use MooseX::StrictConstructor;

use Moose::Util::TypeConstraints qw(enum);

with 'Slack::BlockKit::Role::Block';

#pod =head1 OVERVIEW
#pod
#pod This is the text "composition object", which is used for non-rich text values
#pod in several places in BlockKit.
#pod
#pod =cut

use v5.36.0;

#pod =attr type
#pod
#pod This required attribute must be either C<plain_text> or C<mrkdwn>, and
#pod instructs Slack how to interpret the text attribute.
#pod
#pod =cut

has type => (
  is => 'ro',
  isa => enum([ qw( plain_text mrkdwn ) ]),
  required => 1,
);

#pod =attr text
#pod
#pod This is the string that is the text of the text object.  There are length
#pod constraints enforced by Slack I<but not by this code>.  Be mindful of those.
#pod
#pod =cut

has text => (
  is  => 'ro',
  isa => 'Str', # add length requirements, mayyyybe
  required => 1,
);

#pod =attr emoji
#pod
#pod This optional boolean option can determine whether emoji colon-codes are
#pod expanded within a C<plain_text> text object.  Using this attribute on a
#pod C<mrkdwn> object will raise an exception.
#pod
#pod =cut

has emoji => (
  is => 'ro',
  isa => 'Bool',
  predicate => 'has_emoji',
);

#pod =attr verbatim
#pod
#pod This optional boolean option can determine whether hyperlinks should be left
#pod unlinked within a C<mrkdown> text object.  Using this attribute on a
#pod C<plain_text> object will raise an exception.
#pod
#pod =cut

has verbatim => (
  is => 'ro',
  isa => 'Bool',
  predicate => 'has_verbatim',
);

sub BUILD ($self, @) {
  Carp::croak("can't use 'emoji' with text composition object of type 'mrkdwn'")
    if $self->type eq 'mrkdwn' and $self->has_emoji;

  Carp::croak("can't use 'verbatim' with text composition object of type 'plain_text'")
    if $self->type eq 'plain_text' and $self->has_verbatim;
}

sub as_struct ($self) {
  return {
    type => $self->type, # (not the object type, as with a block element)
    text => q{} . $self->text,
    ($self->has_emoji     ? (emoji    => Slack::BlockKit::boolify($self->emoji))   : ()),
    ($self->has_verbatim  ? (verbatim => Slack::BlockKit::boolify($self->verbatim)) : ()),
  };
}

no Moose;
no Moose::Util::TypeConstraints;
__PACKAGE__->meta->make_immutable;

__END__

=pod

=encoding UTF-8

=head1 NAME

Slack::BlockKit::CompObj::Text - a BlockKit "composition object" for text

=head1 VERSION

version 0.001

=head1 OVERVIEW

This is the text "composition object", which is used for non-rich text values
in several places in BlockKit.

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

=head2 type

This required attribute must be either C<plain_text> or C<mrkdwn>, and
instructs Slack how to interpret the text attribute.

=head2 text

This is the string that is the text of the text object.  There are length
constraints enforced by Slack I<but not by this code>.  Be mindful of those.

=head2 emoji

This optional boolean option can determine whether emoji colon-codes are
expanded within a C<plain_text> text object.  Using this attribute on a
C<mrkdwn> object will raise an exception.

=head2 verbatim

This optional boolean option can determine whether hyperlinks should be left
unlinked within a C<mrkdown> text object.  Using this attribute on a
C<plain_text> object will raise an exception.

=head1 AUTHOR

Ricardo SIGNES <rjbs@semiotic.systems>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2024 by Ricardo SIGNES.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
