package Slack::BlockKit::Block::RichText::UserGroup 0.005;
# ABSTRACT: a Block Kit rich text element that mentions a @usergroup

use Moose;
use MooseX::StrictConstructor;

with 'Slack::BlockKit::Role::HasMentionStyle';

#pod =head1 OVERVIEW
#pod
#pod This represents the mention of a specific Slack user group in a hunk of rich
#pod text.  The group name will be styled and linked-to.  So, to send something
#pod like:
#pod
#pod     I will ask @team-tam.
#pod
#pod You would use the L<sugar|Slack::BlockKit::Sugar> like so:
#pod
#pod     blocks(richtext(section(
#pod       "I will ask ", usergroup($usergroup_id), "."
#pod     )));
#pod
#pod =cut

use v5.36.0;

#pod =attr usergroup_id
#pod
#pod This must be the Slack usergroup id for the group being mentioned.  This is
#pod generally a bunch of alphanumeric characters beginning with C<S>.
#pod
#pod =cut

has usergroup_id => (
  is  => 'ro',
  isa => 'Str',
  required => 1,
);

sub as_struct ($self) {
  return {
    type => 'usergroup',
    usergroup_id => $self->usergroup_id,
  };
}

no Moose;
__PACKAGE__->meta->make_immutable;

__END__

=pod

=encoding UTF-8

=head1 NAME

Slack::BlockKit::Block::RichText::UserGroup - a Block Kit rich text element that mentions a @usergroup

=head1 VERSION

version 0.005

=head1 OVERVIEW

This represents the mention of a specific Slack user group in a hunk of rich
text.  The group name will be styled and linked-to.  So, to send something
like:

    I will ask @team-tam.

You would use the L<sugar|Slack::BlockKit::Sugar> like so:

    blocks(richtext(section(
      "I will ask ", usergroup($usergroup_id), "."
    )));

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

=head2 usergroup_id

This must be the Slack usergroup id for the group being mentioned.  This is
generally a bunch of alphanumeric characters beginning with C<S>.

=head1 AUTHOR

Ricardo SIGNES <cpan@semiotic.systems>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2024 by Ricardo SIGNES.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
