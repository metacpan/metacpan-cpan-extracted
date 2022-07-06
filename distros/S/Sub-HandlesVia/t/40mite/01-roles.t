=pod

=encoding utf-8

=head1 PURPOSE

Test that Sub::HandlesVia works with L<Mite> roles.

=head1 AUTHOR

Toby Inkster E<lt>tobyink@cpan.orgE<gt>.

=head1 COPYRIGHT AND LICENCE

This software is copyright (c) 2022 by Toby Inkster.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

use strict;
use warnings;
use Test::More;
use Test::Requires '5.010001';

use FindBin qw($Bin);
use lib "$Bin/lib";

use MyTest::Class1;

ok !exists &MyTest::Role1::pop;
ok !exists &MyTest::Role2::pop;
ok  exists &MyTest::Class1::pop;

ok !exists &MyTest::Role1::push;
ok !exists &MyTest::Role2::push;
ok  exists &MyTest::Class1::push;

done_testing;
