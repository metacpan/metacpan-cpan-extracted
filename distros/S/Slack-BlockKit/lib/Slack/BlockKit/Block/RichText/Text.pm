package Slack::BlockKit::Block::RichText::Text 0.005;
# ABSTRACT: a Block Kit rich text object for the text in the rich text

use Moose;
use MooseX::StrictConstructor;

with 'Slack::BlockKit::Role::HasBasicStyle';

#pod =head1 OVERVIEW
#pod
#pod When building a hunk of rich text with Slack::BlockKit, it's this object that
#pod contains most of the actual text.  These objects represent the objects in
#pod Block Kit with a C<type> of "text".
#pod
#pod This class includes L<Slack::BlockKit::Role::HasBasicStyle>, so these objects
#pod can have C<bold>, C<code>, C<italic>, and C<strike> styles.
#pod
#pod (For more information on how to actually build text look at
#pod L<Slack::BlockKit::Sugar>.)
#pod
#pod =cut

use v5.36.0;

#pod =attr text
#pod
#pod This is the actual text of the text object.  It's a string, and required.
#pod
#pod =cut

has text => (
  is  => 'ro',
  isa => 'Str',
  required => 1,
);

sub as_struct ($self) {
  return {
    type => 'text',
    text => q{} . $self->text,
  };
}

no Moose;
__PACKAGE__->meta->make_immutable;

__END__

=pod

=encoding UTF-8

=head1 NAME

Slack::BlockKit::Block::RichText::Text - a Block Kit rich text object for the text in the rich text

=head1 VERSION

version 0.005

=head1 OVERVIEW

When building a hunk of rich text with Slack::BlockKit, it's this object that
contains most of the actual text.  These objects represent the objects in
Block Kit with a C<type> of "text".

This class includes L<Slack::BlockKit::Role::HasBasicStyle>, so these objects
can have C<bold>, C<code>, C<italic>, and C<strike> styles.

(For more information on how to actually build text look at
L<Slack::BlockKit::Sugar>.)

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

This is the actual text of the text object.  It's a string, and required.

=head1 AUTHOR

Ricardo SIGNES <cpan@semiotic.systems>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2024 by Ricardo SIGNES.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
