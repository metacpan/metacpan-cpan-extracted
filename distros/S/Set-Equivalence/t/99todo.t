=pod

=encoding utf-8

=head1 PURPOSE

Stub tests cases for curently unimplemented methods.

=head1 AUTHOR

Toby Inkster E<lt>tobyink@cpan.orgE<gt>.

=head1 COPYRIGHT AND LICENCE

This software is copyright (c) 2013 by Toby Inkster.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

use strict;
use warnings;
use Test::More;
use Test::Fatal;

use Set::Equivalence qw(set);

ok  exception { set->weaken };
ok !exception { set->strengthen };
ok  exception { set->as_string_callback(sub { 1 }) };
ok  exception { set->compare };

done_testing;
