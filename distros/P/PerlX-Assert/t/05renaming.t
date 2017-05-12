=pod

=encoding utf-8

=head1 PURPOSE

Rename the C<assert> function to something else.

=head1 AUTHOR

Toby Inkster E<lt>tobyink@cpan.orgE<gt>.

=head1 COPYRIGHT AND LICENCE

This software is copyright (c) 2014 by Toby Inkster.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

use Test::Modern;
use PerlX::Assert -check, assert => { -as => 'run_assertion' };
no warnings qw(void);

my $e;

#line 0 05renaming.t
$e = exception {
	run_assertion 1;
	run_assertion 0;
};
like($e, qr{\AAssertion failed at 05renaming.t line 2}, 'run_assertion EXPR');

#line 0 05renaming.t
$e = exception {
	run_assertion { 1 };
	run_assertion { 0 };
};
like($e, qr{\AAssertion failed at 05renaming.t line 2}, 'run_assertion { BLOCK }');

#line 0 05renaming.t
$e = exception {
	run_assertion {
		1;
	};
	run_assertion {
		0;
	};
};
like($e, qr{\AAssertion failed at 05renaming.t line 4}, 'run_assertion { BLOCK } (multiline block)');

#line 0 05renaming.t
$e = exception {
	run_assertion "Test", 1;
	run_assertion "Test", 0;
};
like($e, qr{\AAssertion failed: Test at 05renaming.t line 2}, 'run_assertion "name", EXPR');

#line 0 05renaming.t
$e = exception {
	run_assertion "Test",
		1;
	run_assertion "Test",
		0;
};
like($e, qr{\AAssertion failed: Test at}, 'run_assertion "name", EXPR (multiline)');

#line 0 05renaming.t
$e = exception {
	run_assertion "Test" { 1 };
	run_assertion "Test" { 0 };
};
like($e, qr{\AAssertion failed: Test at 05renaming.t line 2}, 'run_assertion "name" { BLOCK }');

#line 0 05renaming.t
$e = exception {
	run_assertion "Test" {
		1;
	};
	run_assertion "Test" {
		0;
	};
};
like($e, qr{\AAssertion failed: Test at 05renaming.t line 4}, 'run_assertion "name" { BLOCK } (multiline block)');

done_testing;
