package Slack::BlockKit::Block::Divider 0.003;
# ABSTRACT: a Block Kit "divider" block
use Moose;
use MooseX::StrictConstructor;

with 'Slack::BlockKit::Role::Block';

#pod =head1 OVERVIEW
#pod
#pod This is possibly the simplest block in Block Kit.  It's a divider.  It has no
#pod attributes other than its type and optionally its block id.
#pod
#pod =cut

use v5.36.0;

sub as_struct ($self) {
  return {
    type => 'divider',
  };
}

no Moose;
__PACKAGE__->meta->make_immutable;

__END__

=pod

=encoding UTF-8

=head1 NAME

Slack::BlockKit::Block::Divider - a Block Kit "divider" block

=head1 VERSION

version 0.003

=head1 OVERVIEW

This is possibly the simplest block in Block Kit.  It's a divider.  It has no
attributes other than its type and optionally its block id.

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
