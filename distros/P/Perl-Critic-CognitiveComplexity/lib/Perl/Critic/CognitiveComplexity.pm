package Perl::Critic::CognitiveComplexity;
use 5.010;
use strict;
use warnings;

our $VERSION = '0.5';


1;
__END__

=encoding utf-8

=head1 NAME

Perl::Critic::CognitiveComplexity - Cognitive Complexity, Because Testability != Understandability

=head1 DESCRIPTION

Perl::Critic::Policy::CognitiveComplexity::ProhibitExcessCognitiveComplexity is a rule that checks the
cognitive complexity score of your subroutines. It is based on a new scoring algorithm introduced by
SonarSource. See L<SonarSource blog entry|https://blog.sonarsource.com/cognitive-complexity-because-testability-understandability/>.

=head2 Rules

=over 1

=item L<CognitiveComplexity::ProhibitExcessCognitiveComplexity|Perl::Critic::Policy::CognitiveComplexity::ProhibitExcessCognitiveComplexity> - Avoid code that is nested, and thus difficult to grasp. 
Examples can be seen in the Policy POD.

=back

=head2 Configuration

The default complexity score before code starts to be reported with medium severity, is 10. This can be changed by changing the C<warn_level> parameter.
By default all subroutines with complexity level of more than 0 are reported in lowest severity level. This allows third-party tools to pick up these 
values as code metrics.

  [Perl::Critic::Policy::CognitiveComplexity::ProhibitExcessCognitiveComplexity]
  warn_level = 10
  info_level = 1



=head1 SEE ALSO

L<Perl::Critic>

=head1 COPYRIGHT

Copyright (C) 2017 Oliver Trosien

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 AUTHOR

Oliver Trosien E<lt>cpan@pocket-design.deE<gt>

=cut
