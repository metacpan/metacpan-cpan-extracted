package Slack::BlockKit::Role::HasMentionStyle 0.005;
# ABSTRACT: a Block Kit element with a bunch of styles

use Moose::Role;

#pod =head1 OVERVIEW
#pod
#pod This is a specialization of the role L<Slack::BlockKit::Role::HasBasicStyle>,
#pod in which the permitted C<styles> are:
#pod
#pod =for :list
#pod * bold
#pod * code
#pod * italic
#pod * strike
#pod * highlight
#pod * client_highlight
#pod * unlink
#pod
#pod The author of this library doesn't know what those last three do, but they are
#pod documented.
#pod
#pod =cut

with 'Slack::BlockKit::Role::HasStyle' => {
  styles => [
    qw( bold italic strike ), # the basic styles (HasBasicStyle) minus code
    qw( highlight client_highlight unlink ), # mysteries to rjbs
  ],
};

no Moose::Role;
1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Slack::BlockKit::Role::HasMentionStyle - a Block Kit element with a bunch of styles

=head1 VERSION

version 0.005

=head1 OVERVIEW

This is a specialization of the role L<Slack::BlockKit::Role::HasBasicStyle>,
in which the permitted C<styles> are:

=over 4

=item *

bold

=item *

code

=item *

italic

=item *

strike

=item *

highlight

=item *

client_highlight

=item *

unlink

=back

The author of this library doesn't know what those last three do, but they are
documented.

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

=head1 AUTHOR

Ricardo SIGNES <cpan@semiotic.systems>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2024 by Ricardo SIGNES.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
