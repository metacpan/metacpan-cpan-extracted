=pod

=encoding utf-8

=head1 PURPOSE

Tests for C<< $_tap >>.

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

eval "sub TestClass::$_ { my \$self = shift; \$self->{$_} = \$_[0] if \@_; \$self->{$_} }"
	for qw/foo bar baz/;

my $test = bless({ foo => [1..3], bar => 666, baz => 999 }, 'TestClass');

is(
	$test->$_tap(bar => 42),
	$test,
	'$_tap returned correct value',
);

is(
	$test->bar,
	42,
	'tapped method was really called',
);

is(
	$test->$_tap(sub { shift->baz(@_) }, 21),
	$test,
	'$_tap($coderef) returned correct value',
);

is(
	$test->baz,
	21,
	'tapped coderef was really called',
);

done_testing;

