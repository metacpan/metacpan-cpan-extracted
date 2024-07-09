package Slack::BlockKit::Role::HasBasicStyle 0.002;
# ABSTRACT: a Block Kit element with optional (bold, code, italic, strike) styles

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
#pod
#pod =cut

with 'Slack::BlockKit::Role::HasStyle' => {
  styles => [ qw( bold italic strike code ) ],
};

no Moose::Role;
1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Slack::BlockKit::Role::HasBasicStyle - a Block Kit element with optional (bold, code, italic, strike) styles

=head1 VERSION

version 0.002

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

=back

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

Ricardo SIGNES <rjbs@semiotic.systems>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2024 by Ricardo SIGNES.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
