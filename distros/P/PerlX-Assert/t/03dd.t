=pod

=encoding utf-8

=head1 PURPOSE

Check that the C<assert> keyword's L<Devel::Declare>-based
implementation, even on newer Perls.

=head1 AUTHOR

Toby Inkster E<lt>tobyink@cpan.orgE<gt>.

=head1 COPYRIGHT AND LICENCE

This software is copyright (c) 2013-2014 by Toby Inkster.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

no warnings qw(once);
BEGIN { ++$PerlX::Assert::NO_KEYWORD_API };

use Test::Modern -requires => { 'Devel::Declare' => 0 };
require TestLib;
