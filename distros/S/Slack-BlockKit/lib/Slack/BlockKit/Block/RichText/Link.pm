package Slack::BlockKit::Block::RichText::Link 0.003;
# ABSTRACT: a Block Kit rich text hyperlink element

use Moose;
use MooseX::StrictConstructor;

with 'Slack::BlockKit::Role::HasBasicStyle';

#pod =head1 OVERVIEW
#pod
#pod This represents a hyperlink element in rich text in Block Kit.
#pod
#pod =cut

use v5.36.0;

#pod =attr url
#pod
#pod This is the URL to which the link links.
#pod
#pod =cut

has url => (
  is  => 'ro',
  isa => 'Str',
  required => 1,
);

#pod =attr text
#pod
#pod This is the text displayed for the link.  It's optional, and Slack will display
#pod the URL if no text was given.
#pod
#pod This attribute stores a string, not any form of Block Kit text object.
#pod
#pod =cut

has text => (
  is  => 'ro',
  isa => 'Str',
  predicate => 'has_text',
);

#pod =attr unsafe
#pod
#pod This is a boolean indicating whether the link is unsafe.  The author has not
#pod figured out what this actually I<does> and so never uses it.
#pod
#pod =cut

has unsafe => (
  is  => 'ro',
  isa => 'Bool',
  predicate => 'has_unsafe',
);

sub as_struct ($self) {
  return {
    type => 'link',

    ($self->has_text    ? (text   => q{} . $self->text) : ()),
    ($self->has_unsafe  ? (unsafe => Slack::BlockKit::boolify($self->unsafe))  : ()),
    url => $self->url,
  };
}

no Moose;
__PACKAGE__->meta->make_immutable;

__END__

=pod

=encoding UTF-8

=head1 NAME

Slack::BlockKit::Block::RichText::Link - a Block Kit rich text hyperlink element

=head1 VERSION

version 0.003

=head1 OVERVIEW

This represents a hyperlink element in rich text in Block Kit.

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

=head2 url

This is the URL to which the link links.

=head2 text

This is the text displayed for the link.  It's optional, and Slack will display
the URL if no text was given.

This attribute stores a string, not any form of Block Kit text object.

=head2 unsafe

This is a boolean indicating whether the link is unsafe.  The author has not
figured out what this actually I<does> and so never uses it.

=head1 AUTHOR

Ricardo SIGNES <cpan@semiotic.systems>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2024 by Ricardo SIGNES.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
