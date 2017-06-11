use 5.008;
use strict;
use warnings;

package Test::Compiles;

our $AUTHORITY = 'cpan:TOBYINK';
our $VERSION   = '0.001';

use Exporter::Shiny our @EXPORT = qw( compiles doesnt_compile );

our $PRELUDE = '';

require Test::More;

sub compiles {
	@_ % 2 or splice(@_, 1, 0, 'message');
	my ($code, %opts) = @_;
	
	my $package = $opts{package} || caller;
	
	my $prepend = $PRELUDE || $opts{prelude} || '';
	$prepend .= ';use strict'
		if $opts{strict} || !exists $opts{strict};
	$prepend .= ';use warnings FATAL => qw(all)'
		if $opts{warnings};
	
	my $rand = 100_000 + int rand 900_000;
	my $e = do {
		local $@;
		local $SIG{__WARN__} = sub {};
		no strict; no warnings;
		eval "package $package;\n;"
			. "$prepend;\n;"
			. "$code;\n;"
			. "BEGIN { die \"ERROR$rand\" };\n;";
		$@;
	};
	my $result = (
		!$opts{should_fail} == !!($e =~ /\AERROR$rand\b/)
	);
	
	if (!$result) {
		Test::More::diag($opts{should_fail} ? "no error encountered": "error: $e");
	}
	
	$opts{message} ||= $opts{should_fail}
		? "code shouldn't compile"
		: "code should compile";
	
	@_ = ($result, $opts{message});
	goto \&Test::More::ok;
}

sub doesnt_compile {
	@_ % 2 or splice(@_, 1, 0, 'message');
	my ($code, %opts) = @_;
	$opts{should_fail} = !$opts{should_fail};
	@_ = ($code, %opts);
	goto \&compiles;
}

1;

__END__

=pod

=encoding utf-8

=head1 NAME

Test::Compiles - tests if perl can compile a string of code

=head1 SYNOPSIS

 use Test::More;
 use Test::Compiles;
 
 compiles_ok    q{ print "hello world" };
 doesnt_compile q{ print "hello world  };   # missing end of quote
 
 done_testing;

=head1 DESCRIPTION

Test::Compiles exports two functions to allow you to check whether a
string of code can be compiled by perl without errors. It doesn't check
whether it can be I<executed>.

Note that Perl code can execute arbitrary instructions as part of its
compilation (e.g. in a C<< BEGIN { ... } >> block), so don't pass
untrusted strings to these test functions.

=over

=item C<< compiles $code, $message, %options >>

=item C<< compiles $code, %options >>

=item C<< compiles $code, $message >>

=item C<< compiles $code >>

This test passes if C<< $code >> can be compiled.

Valid options are:

=over

=item * C<strict>: boolean to indicate whether code should be compiled
with C<< use strict >>. Enabled by default.

=item * C<warnings>: boolean to indicate whether code should be
compiled with C<< use warnings FATAL => 'all' >>. Disabled by default.

=item * C<package>: package that the code should be compiled in.
Defaults to the caller.

=item * C<prelude>: a string of Perl code to prepend to C<< $code >>.
Defaults to C<< $Test::Compiles::PRELUDE >>, which is (by default) an
empty string.

=item * C<message>: an alternative to specifying C<< $message >>.

=back

=item C<< doesnt_compile $code, $message, %options >>

=item C<< doesnt_compile $code, %options >>

=item C<< doesnt_compile $code, $message >>

=item C<< doesnt_compile $code >>

This test passes if C<< $code >> cannot be compiled. It accepts the
same options.

=back

This module defines a package variable C<< $Test::Compiles::PRELUDE >>
which can be used to, for example, load pragmata like L<indirect> or
L<bareword::filehandles>.



=head1 BUGS

Please report any bugs to
L<http://rt.cpan.org/Dist/Display.html?Queue=Test-Compiles>.

=head1 SEE ALSO

L<Test::Fatal> — checks for runtime errors.

L<Test::More> — the test framework.

=head1 AUTHOR

Toby Inkster E<lt>tobyink@cpan.orgE<gt>.

=head1 COPYRIGHT AND LICENCE

This software is copyright (c) 2017 by Toby Inkster.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.


=head1 DISCLAIMER OF WARRANTIES

THIS PACKAGE IS PROVIDED "AS IS" AND WITHOUT ANY EXPRESS OR IMPLIED
WARRANTIES, INCLUDING, WITHOUT LIMITATION, THE IMPLIED WARRANTIES OF
MERCHANTIBILITY AND FITNESS FOR A PARTICULAR PURPOSE.

