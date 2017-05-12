=pod

=encoding utf-8

=head1 PURPOSE

Test C<< $_plus_coercions >>.

=head1 AUTHOR

Toby Inkster E<lt>tobyink@cpan.orgE<gt>.

=head1 COPYRIGHT AND LICENCE

This software is copyright (c) 2014 by Toby Inkster.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

use Test::Modern -requires => { 'Moose' => 2.0600 };
use Local::StdTests;

use MooseX::Types::MoreUtils;

subtest "Moose-based types, with coercions as coderefs" => sub
{
	my $type1 = 'ArrayRef'->$_plus_coercions('Str', sub { [ split /:/, $_ ] });
	my $type2 = $type1->$_plus_coercions('Int', sub { [ (undef) x $_ ] });
	@_ = ( $type1, $type2 );
	goto \&Local::StdTests::arrayref_coercion_tests;
};

subtest "Moose-based types, with coercions as strings" => sub
{
	my $type1 = 'ArrayRef'->$_plus_coercions('Str', q{ [ split /:/, $_ ] });
	my $type2 = $type1->$_plus_coercions('Int', q{ [ (undef) x $_ ] });
	@_ = ( $type1, $type2 );
	goto \&Local::StdTests::arrayref_coercion_tests;
};

subtest "Moose-based types, with coercions as strings, and Sub::Quote loaded" => sub
{
	my $type1 = 'ArrayRef'->$_plus_coercions('Str', q{ [ split /:/, $_ ] });
	my $type2 = $type1->$_plus_coercions('Int', q{ [ (undef) x $_ ] });
	@_ = ( $type1, $type2 );
	goto \&Local::StdTests::arrayref_coercion_tests;
} if eval { require Sub::Quote };

done_testing;

