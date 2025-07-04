=pod

=encoding utf-8

=head1 PURPOSE

Test that Object::Adhoc is capable of recursion.

=head1 AUTHOR

Toby Inkster E<lt>tobyink@cpan.orgE<gt>.

=head1 COPYRIGHT AND LICENCE

This software is copyright (c) 2025 by Toby Inkster.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

use strict;
use warnings;
use Test::More;
use Object::Adhoc 'make_class';

my $xxx = make_class[ qw/ foo bar / ];
ok !$xxx->can('new');
my $XXX = bless({ foo => 666, bar => 999 }, $xxx);
is $XXX->foo, 666;
is $XXX->bar, 999;

my $yyy = make_class[ qw/ foo bar / ], ctor => 1;
ok $yyy->can('new');
my $YYY = $yyy->new( { foo => 666, bar => 999 } );
is $YYY->foo, 666;
is $YYY->bar, 999;
my $YYY2 = $yyy->new( foo => 666, bar => 999 );
is $YYY2->foo, 666;
is $YYY2->bar, 999;

my $e;
eval {
	$yyy->new( foo => 666, bar => 999, baz => 111 );
	1;
} or $e = $@;
like $e, qr/Bad key: baz/;

done_testing;
