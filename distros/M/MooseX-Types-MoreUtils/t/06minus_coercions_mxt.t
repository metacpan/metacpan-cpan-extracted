=pod

=encoding utf-8

=head1 PURPOSE

Test C<< $_minus_coercions >> with L<MooseX::Types>.

=head1 AUTHOR

Toby Inkster E<lt>tobyink@cpan.orgE<gt>.

=head1 COPYRIGHT AND LICENCE

This software is copyright (c) 2014 by Toby Inkster.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

use Test::Modern -requires => { 'MooseX::Types::Moose' => 0 };
use Local::StdTests;

use MooseX::Types::MoreUtils;
use MooseX::Types::Moose qw( ArrayRef Str Int );

subtest "MooseX::Types-based types, with coercions as coderefs" => sub
{
	my $type2 = ArrayRef->$_plus_coercions(
		Int, sub { [ (undef) x $_ ] },
		Str, sub { [ split /:/, $_ ] },
	);
	my $type1 = $type2->$_minus_coercions(Int);
	@_ = ( $type1, $type2 );
	goto \&Local::StdTests::arrayref_coercion_tests;
};

subtest "MooseX::Types-based types, with coercions as strings" => sub
{
	my $type2 = ArrayRef->$_plus_coercions(
		Int, q{ [ (undef) x $_ ] },
		Str, q{ [ split /:/, $_ ] },
	);
	my $type1 = $type2->$_minus_coercions(Int);
	@_ = ( $type1, $type2 );
	goto \&Local::StdTests::arrayref_coercion_tests;
};

subtest "MooseX::Types-based types, with coercions as strings, and Sub::Quote loaded" => sub
{
	my $type2 = ArrayRef->$_plus_coercions(
		Int, q{ [ (undef) x $_ ] },
		Str, q{ [ split /:/, $_ ] },
	);
	my $type1 = $type2->$_minus_coercions(Int);
	@_ = ( $type1, $type2 );
	goto \&Local::StdTests::arrayref_coercion_tests;
} if eval { require Sub::Quote };

done_testing;

