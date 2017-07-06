=pod

=encoding utf-8

=head1 PURPOSE

Test that Template::Compiled compiles and works.

=head1 AUTHOR

Toby Inkster E<lt>tobyink@cpan.orgE<gt>.

=head1 COPYRIGHT AND LICENCE

This software is copyright (c) 2017 by Toby Inkster.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

use strict;
use warnings;
use Test::More;
use Test::Fatal;

use Types::Standard -types;

use_ok('Template::Compiled');

do {
	my $tmpl = q{Foo = <?= $foo ?>};
	my $compiled = Template::Compiled->new(
		template   => $tmpl,
		signature  => [ foo => Int ],
	);
	is(
		$compiled->render(foo => '42'),
		'Foo = 42',
		'Template works',
	);
	like(
		exception { $compiled->render() },
		qr/Missing required parameter/,
		'Exception for bad params',
	);
};

do {
	my $tmpl = q{Foo = [%= $foo %]};
	my $compiled = Template::Compiled->new(
		template   => $tmpl,
		signature  => [ foo => Int ],
		delimiters => [ qw( [% %] ) ]
	);
	is(
		$compiled->render(foo => '42'),
		'Foo = 42',
		'Template works, alternative delimiters',
	);
};

do {
	my $tmpl = q{Foo = [%= '[%'.$foo %]42%]};
	my $compiled = Template::Compiled->new(
		template   => $tmpl,
		signature  => [ foo => Int ],
		delimiters => [ qw( [% %] ) ]
	);
	is(
		$compiled->render(foo => '42'),
		'Foo = [%4242%]',
		'Template works, using delimiters wierdly',
	);
};

do {
	my $tmpl = q{
		Foo
		Bar
		<?= $doesnotexist ?>
		Baz
	};
	my $e = exception {
		Template::Compiled->new(
			trim       => 1,
			template   => $tmpl,
			signature  => [ foo => Int ],
		)->render();
	};
	like(
		$e,
		qr/\$doesnotexist.*requires explicit package name.*template line 3/sm,
		'Syntax errors in templates provide a useful error message',
	);
};


done_testing;

