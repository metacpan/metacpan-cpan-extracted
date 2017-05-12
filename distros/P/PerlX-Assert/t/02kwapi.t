=pod

=encoding utf-8

=head1 PURPOSE

Check that the C<assert> keyword's preferred implementation, which
uses the Perl keyword API on recent releases of Perl, but falls
back to a L<Devel::Declare>-based version on older Perls.

=head1 AUTHOR

Toby Inkster E<lt>tobyink@cpan.orgE<gt>.

=head1 COPYRIGHT AND LICENCE

This software is copyright (c) 2013-2014 by Toby Inkster.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

use Test::Modern;
require TestLib;
