=pod

=encoding utf-8

=head1 PURPOSE

Unit tests for L<Missing::XS>.

=head1 AUTHOR

Toby Inkster E<lt>tobyink@cpan.orgE<gt>.

=head1 COPYRIGHT AND LICENCE

This software is copyright (c) 2023 by Toby Inkster.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

BEGIN {
	$ENV{PERL_MISSING_XS_NO_END} = 1;
};

use Test2::V0 -target => 'Missing::XS';
use Test2::Tools::Spec;
use Data::Dumper;

describe "class `$CLASS`" => sub {
	tests 'basic_check' => sub {
		my $rand = sprintf( 'Dummy%06d', int rand( 1_000_000 ) );
		ok !$CLASS->basic_check( $CLASS, "$CLASS\::Module::Does::Not::Exist::$rand\::Sorry1" );
		ok $CLASS->basic_check( "$CLASS\::Module::Does::Not::Exist::$rand\::Sorry2", "$CLASS\::Module::Does::Not::Exist::$rand\::Sorry3" );
	};
};

done_testing;
