package Slack::BlockKit::Block::RichText::Emoji 0.001;
# ABSTRACT: a BlockKit rich text element for a :colon_code: emoji

use Moose;
use MooseX::StrictConstructor;

#pod =head1 OVERVIEW
#pod
#pod This represents an C<emoji> element in BlockKit, which are generally put in
#pod place of or between L<text|Slack::BlockKit::Block::RichText::Text> elements in
#pod rich text sections.
#pod
#pod =cut

use v5.36.0;

#pod =attr name
#pod
#pod This is the only notable attribute of an Emoji element.  It's the name of the
#pod emoji, as you'd type it in Slack, except without the outer colons.  So C<adult>
#pod rather than C<:adult:> and C<adult::skin-tone-4> rather than
#pod C<:adult::skin-tone-4:>.
#pod
#pod At time of writing, unknown emoji names are not an error, but will be displayed
#pod as text inside colons.
#pod
#pod =cut

has name => (
  is  => 'ro',
  isa => 'Str', # Unknown names show up as ":bogus_name_here:"
  required => 1,
);

sub as_struct ($self) {
  return {
    type => 'emoji',
    name => $self->name,
  };
}

no Moose;
__PACKAGE__->meta->make_immutable;

__END__

=pod

=encoding UTF-8

=head1 NAME

Slack::BlockKit::Block::RichText::Emoji - a BlockKit rich text element for a :colon_code: emoji

=head1 VERSION

version 0.001

=head1 OVERVIEW

This represents an C<emoji> element in BlockKit, which are generally put in
place of or between L<text|Slack::BlockKit::Block::RichText::Text> elements in
rich text sections.

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

=head2 name

This is the only notable attribute of an Emoji element.  It's the name of the
emoji, as you'd type it in Slack, except without the outer colons.  So C<adult>
rather than C<:adult:> and C<adult::skin-tone-4> rather than
C<:adult::skin-tone-4:>.

At time of writing, unknown emoji names are not an error, but will be displayed
as text inside colons.

=head1 AUTHOR

Ricardo SIGNES <rjbs@semiotic.systems>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2024 by Ricardo SIGNES.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
