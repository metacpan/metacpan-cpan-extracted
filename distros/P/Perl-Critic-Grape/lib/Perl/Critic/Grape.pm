package Perl::Critic::Grape;

use strict;
use warnings;

our $VERSION='0.1.0';

1;

__END__

=head1 NAME

Perl::Critic::Grape - Additional Perl::Critic policies.

=head1 DESCRIPTION

Fruit is good for you!  Grapes can also be red or green, just like the status of your code based on these policies.

=head2 Policies

=over

=item L<CodeLayout::RequireParensWithBuiltins|Perl::Critic::Policy::CodeLayout::RequireParensWithBuiltins>

Built-in functions called without parentheses.

=item L<ControlStructures::ProhibitInlineDo|Perl::Critic::Policy::ControlStructures::ProhibitInlineDo>

Do not use inline do blocks.

=item L<References::ProhibitRefChecks|Perl::Critic::Policy::References::ProhibitRefChecks>

Do not perform manual ref checks.

=item L<References::RequireSigils|Perl::Critic::Policy::References::RequireSigils>

Use sigils to signal type.  Only use dereferencing arrows for method calls.

=item L<Subroutines::RequireConsistentReturn|Perl::Critic::Policy::Subroutines::RequireConsistentReturn>

Don't use an implicit return in a subroutine with explicit returns.

=item L<Subroutines::RequireSubOrder|Perl::Critic::Policy::Subroutines::RequireSubOrder>

Place subroutines in dependency order.

=item L<ValuesAndExpressions::RequireSlices|Perl::Critic::Policy::ValuesAndExpressions::RequireSlices>

Use array and hash slices for lookup sequences.

=item L<Variables::ProhibitTopicIterator|Perl::Critic::Policy::Variables::ProhibitTopicIterator>

Always use named loop control variables.

=back

=cut
