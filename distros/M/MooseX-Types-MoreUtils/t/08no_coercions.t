=pod

=encoding utf-8

=head1 PURPOSE

Test C<< $_no_coercions >>.

=head1 AUTHOR

Toby Inkster E<lt>tobyink@cpan.orgE<gt>.

=head1 COPYRIGHT AND LICENCE

This software is copyright (c) 2014 by Toby Inkster.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

use Test::Modern -requires => { 'Moose' => '2.0600' };

use MooseX::Types::MoreUtils;

subtest "Moose-based types, with coercions as coderefs" => sub
{
	my $type1 = 'ArrayRef'->$_plus_coercions(
		'Int', sub { [ (undef) x $_ ] },
		'Str', sub { [ split /:/, $_ ] },
	);
	my $type2 = $type1->$_no_coercions;
	ok( $type1->has_coercion, '$type1 has coercions');
	ok(!$type2->has_coercion, '$type2 has no coercions');
};

subtest "Moose-based types, with coercions as strings" => sub
{
	my $type1 = 'ArrayRef'->$_plus_coercions(
		'Int', q{ [ (undef) x $_ ] },
		'Str', q{ [ split /:/, $_ ] },
	);
	my $type2 = $type1->$_no_coercions;
	ok( $type1->has_coercion, '$type1 has coercions');
	ok(!$type2->has_coercion, '$type2 has no coercions');
};

subtest "Moose-based types, with coercions as strings, and Sub::Quote loaded" => sub
{
	my $type1 = 'ArrayRef'->$_plus_coercions(
		'Int', q{ [ (undef) x $_ ] },
		'Str', q{ [ split /:/, $_ ] },
	);
	my $type2 = $type1->$_no_coercions;
	ok( $type1->has_coercion, '$type1 has coercions');
	ok(!$type2->has_coercion, '$type2 has no coercions');
} if eval { require Sub::Quote };

done_testing;

