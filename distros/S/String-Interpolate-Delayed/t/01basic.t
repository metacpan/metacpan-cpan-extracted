=head1 PURPOSE

Check basic functionality of quote-like operator, object constructor, object
methods and string overloading.

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
use Test::Fatal;

use String::Interpolate::Delayed;

{
	my $str   = delayed "The $title of the $thing\n";
	my $title = "Lord";
	my $thing = "Dance";
	
	is(
		"$str",
		"The Lord of the Dance\n",
		"simple usage",
	);
	
	$thing = "Rings";
	
	is(
		"$str",
		"The Lord of the Rings\n",
		"redefinition of captured variable",
	);
}

{
	my $str   = delayed "The $title of the $thing\n";
	our $title = "Lord";
	our $thing = "Flies";
	
	is(
		"$str",
		"The Lord of the Flies\n",
		"package variables",
	);
}

{
	my $str   = "String::Interpolate::Delayed"->new('The $title of the $thing\n');
	my $title = "Lord";
	my $thing = "Dance";
	
	is(
		"$str",
		"The Lord of the Dance\n",
		"OO usage",
	);
}

{
	my $str   = delayed "The $thing in $place @description.\n";
	my $thing = "rain";
	
	is(
		$str->interpolated({
			place       => \"Spain",
			description => [qw/ stays mainly on the plain /],
		}),
		"The rain in Spain stays mainly on the plain.\n",
		"additional variables via hashref",
	);
}

{
	my $str   = delayed "The $thing in $place @description.\n";
	my $thing = "rain";
	
	is(
		$str->uninterpolated,
		'The $thing in $place @description.\n',
		"uninterpolated method",
	);
}

{
	my $str   = delayed "The $title of the $topic\n";
	my $title = "Lord";
	
	like(
		exception { "$str" },
		qr{\$topic.? requires explicit package name},
		"throws exception for undeclared variable",
	);
}

done_testing;
