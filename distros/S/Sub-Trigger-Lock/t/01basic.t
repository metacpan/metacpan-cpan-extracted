=pod

=encoding utf-8

=head1 PURPOSE

Test that Sub::Trigger::Lock works.

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
use Test::Fatal;

use Sub::Trigger::Lock;

my $h = { foo => 1, quux => [666] };
$h->{bar} = 2;

Lock->(undef, $h);

like(
	exception { $h->{baz} = 1 },
	qr/^Attempt to access disallowed key/,
	'error trying to add hash key'
);

like(
	exception { delete($h->{bar}) },
	qr/^Attempt to delete readonly key/,
	'error trying to remove hash key'
);

like(
	exception { $h->{bar} = 1 },
	qr/^Modification of a read-only value/,
	'error trying to change value for existing hash key'
);

like(
	exception { $h->{quux} = [] },
	qr/^Modification of a read-only value/,
	'error trying to change arrayref value for existing hash key'
);

is(
	exception { @{$h->{quux}} = (); push @{$h->{quux}}, 42 },
	undef,
	'... but can alter the array referred to by the arrayref'
);

is_deeply(
	$h,
	{ foo => 1, bar => 2, quux => [42] },
	"hashref wasn't modified when exceptions were thrown",
);

my $r = [ { xxx => 42 }, 1, 2, 3 ];
push @$r, 4;

Lock->(undef, $r);

like(
	exception { $r->[1] = 999 },
	qr/^Modification of a read-only value/,
	'error trying to alter array value'
);

like(
	exception { pop(@$r) },
	qr/^Modification of a read-only value/,
	'error trying to pop array'
);

like(
	exception { push(@$r, 5) },
	qr/^Modification of a read-only value/,
	'error trying to push to array'
);

like(
	exception { shift(@$r) },
	qr/^Modification of a read-only value/,
	'error trying to shift array'
);

like(
	exception { unshift(@$r, 0) },
	qr/^Modification of a read-only value/,
	'error trying to unshift to array'
);

like(
	exception { $r->[0] = {} },
	qr/^Modification of a read-only value/,
	'error trying to alter hashref array value'
);

is(
	exception { %{$r->[0]} = (); $r->[0]{quux} = 666 },
	undef,
	'... but can alter the hash referred to by the hashref'
);

is_deeply(
	$r,
	[ { quux => 666 }, 1, 2, 3, 4 ],
	"arrayref wasn't modified when exceptions were thrown",
);

done_testing;

