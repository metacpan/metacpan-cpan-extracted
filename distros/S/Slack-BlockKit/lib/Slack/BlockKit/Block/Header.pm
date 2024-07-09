package Slack::BlockKit::Block::Header 0.002;
# ABSTRACT: a Block Kit header block

use Moose;
use MooseX::StrictConstructor;

with 'Slack::BlockKit::Role::Block';

#pod =head1 OVERVIEW
#pod
#pod This object represents a "header" block.  These blocks only have one special
#pod attribute: the text they display.
#pod
#pod =cut

use v5.36.0;

use Moose::Util::TypeConstraints qw(class_type);

#pod =attr text
#pod
#pod The C<text> attribute must be a L<text object|Slack::BlockKit::CompObj::Text>
#pod with the text that will be displayed in the header.  The C<type> of that object
#pod must be C<plain_text>, not C<mrkdwn>.
#pod
#pod =cut

has text => (
  is  => 'ro',
  isa => class_type('Slack::BlockKit::CompObj::Text'),
  required => 1,
);

sub BUILD ($self, @) {
  if ($self->text->type ne 'plain_text') {
    Carp::croak("non-plain_text text object provided to header");
  }
}

sub as_struct ($self) {
  return {
    type  => 'header',
    text  => $self->text->as_struct,
  };
}

no Moose;
__PACKAGE__->meta->make_immutable;

__END__

=pod

=encoding UTF-8

=head1 NAME

Slack::BlockKit::Block::Header - a Block Kit header block

=head1 VERSION

version 0.002

=head1 OVERVIEW

This object represents a "header" block.  These blocks only have one special
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

The C<text> attribute must be a L<text object|Slack::BlockKit::CompObj::Text>
with the text that will be displayed in the header.  The C<type> of that object
must be C<plain_text>, not C<mrkdwn>.

=head1 AUTHOR

Ricardo SIGNES <rjbs@semiotic.systems>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2024 by Ricardo SIGNES.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
