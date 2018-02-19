package Perl::Critic::Policy::Freenode::ConditionalDeclarations;

use strict;
use warnings;

use Perl::Critic::Utils qw(:severities :classification :ppi);
use parent 'Perl::Critic::Policy::Variables::ProhibitConditionalDeclarations';

our $VERSION = '0.026';

sub default_severity { $SEVERITY_HIGH }
sub default_themes { 'freenode' }

1;

=head1 NAME

Perl::Critic::Policy::Freenode::ProhibitConditionalDeclarations - Don't declare
variables conditionally

=head1 DESCRIPTION

It is possible to add a postfix condition to a variable declaration, like
C<my $foo = $bar if $baz>. However, it is unclear (and undefined) if the
variable will be declared when the condition is not met. Instead, declare the
variable and then assign to it conditionally, or use the
L<ternary operator|perlop/"Conditional Operator"> to assign a value
conditionally.

  my $foo = $bar if $baz;           # not ok
  my ($foo, $bar) = @_ unless $baz; # not ok
  our $bar = $_ for 0..10;          # not ok
  my $foo; $foo = $bar if $baz;     # ok
  my $foo = $baz ? $bar : undef;    # ok

This policy is a subclass of the core policy
L<Perl::Critic::Policy::Variables::ProhibitConditionalDeclarations>, and
performs the same function but in the C<freenode> theme.

=head1 AFFILIATION

This policy is part of L<Perl::Critic::Freenode>.

=head1 CONFIGURATION

This policy is not configurable except for the standard options.

=head1 AUTHOR

Dan Book, C<dbook@cpan.org>

=head1 COPYRIGHT AND LICENSE

Copyright 2015, Dan Book.

This library is free software; you may redistribute it and/or modify it under
the terms of the Artistic License version 2.0.

=head1 SEE ALSO

L<Perl::Critic>
