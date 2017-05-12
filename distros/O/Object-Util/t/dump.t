=pod

=encoding utf-8

=head1 PURPOSE

Tests for C<< $_dump >>.

=head1 AUTHOR

Toby Inkster E<lt>tobyink@cpan.orgE<gt>.

=head1 COPYRIGHT AND LICENCE

This software is copyright (c) 2014 by Toby Inkster.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

use strict;
use warnings;
use Test::More;
use Test::Warnings;

use Object::Util;

my $test = bless({ foo => [1..3], bar => 666, baz => 999 }, 'TestClass');
my $dump = $test->$_dump();

like($dump, qr/foo\s*=>/, 'dump formatted nicely');
is_deeply( eval($dump), $test, 'dump seems OK' );

sub OtherTestClass::dump { sprintf('[%d,%d]', @{$_[0]}{qw/ x y /}) }
my $test2 = bless({x => 1, y => 2}, 'OtherTestClass');
is( $test2->$_dump, '[1,2]', 'dump can be overridden' );

done_testing;

