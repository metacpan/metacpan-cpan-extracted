=pod

=encoding utf-8

=head1 PURPOSE

Check the four different syntaxes for C<assert>.

=head1 AUTHOR

Toby Inkster E<lt>tobyink@cpan.orgE<gt>.

=head1 COPYRIGHT AND LICENCE

This software is copyright (c) 2014 by Toby Inkster.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

use Test::Modern;
use PerlX::Assert -check;
no warnings qw(void);

my $e;

#line 0 04syntax.t
$e = exception {
	assert 1;
	assert 0;
};
like($e, qr{\AAssertion failed at 04syntax.t line 2}, 'assert EXPR');

#line 0 04syntax.t
$e = exception {
	assert { 1 };
	assert { 0 };
};
like($e, qr{\AAssertion failed at 04syntax.t line 2}, 'assert { BLOCK }');

#line 0 04syntax.t
$e = exception {
	assert {
		1;
	};
	assert {
		0;
	};
};
like($e, qr{\AAssertion failed at 04syntax.t line 4}, 'assert { BLOCK } (multiline block)');

#line 0 04syntax.t
$e = exception {
	assert "Test", 1;
	assert "Test", 0;
};
like($e, qr{\AAssertion failed: Test at 04syntax.t line 2}, 'assert "name", EXPR');

#line 0 04syntax.t
$e = exception {
	assert "Test",
		1;
	assert "Test",
		0;
};
like($e, qr{\AAssertion failed: Test at}, 'assert "name", EXPR (multiline)');

#line 0 04syntax.t
$e = exception {
	assert "Test" { 1 };
	assert "Test" { 0 };
};
like($e, qr{\AAssertion failed: Test at 04syntax.t line 2}, 'assert "name" { BLOCK }');

#line 0 04syntax.t
$e = exception {
	assert "Test" {
		1;
	};
	assert "Test" {
		0;
	};
};
like($e, qr{\AAssertion failed: Test at 04syntax.t line 4}, 'assert "name" { BLOCK } (multiline block)');

done_testing;
