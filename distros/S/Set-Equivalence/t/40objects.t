=pod

=encoding utf-8

=head1 PURPOSE

Test that objects can be stored in sets.

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

use Set::Equivalence qw(set);

my $arr1 = [ 1 ];
my $str1 = "$arr1";

is("$arr1", "$str1", '$arr1 and $str1 have the same stringification');
ok($arr1 eq $str1, '... and $arr1 eq $str1');
is(set($arr1, $str1)->size, 2, '... yet they live side by side in a set!');

my $arr2 = [ 1 ];
is(set($arr1, $arr1)->size, 1, 'the same reference cannot be added to a set twice');
is(set($arr1, $arr2)->size, 2, '... but similar references can be');

done_testing;
