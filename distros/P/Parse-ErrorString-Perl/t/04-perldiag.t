#!/usr/bin/perl

use strict;
use warnings;

use Test::More tests => 4;
use Parse::ErrorString::Perl;
use Test::Differences;


# use strict;
# use warnings;
#
# $kaboom;

my $msg_compile;

if ( $] <  5.021004 ) {
	$msg_compile = <<'ENDofMSG';
Global symbol "$kaboom" requires explicit package name at error.pl line 8.
Execution of error.pl aborted due to compilation errors.
ENDofMSG
} else {
	$msg_compile = <<'ENDofMSG';
Global symbol "$kaboom" requires explicit package name (did you forget to declare "my $kaboom"?) at error.pl line 8.
Execution of error.pl aborted due to compilation errors.
ENDofMSG
}

my $message;

if ( $] < 5.021004 ) {
	$message = q{Global symbol "$kaboom" requires explicit package name};
} else {
	$message = q{Global symbol "$kaboom" requires explicit package name (did you forget to declare "my $kaboom"?)};
}

my $diagnostics;

if ( $] < 5.008009 ) {

	$diagnostics = <<'ENDofMSG';
(F) You've said "use strict vars", which indicates that all variables
must either be lexically scoped (using "my"), declared beforehand using
"our", or explicitly qualified to say which package the global variable
is in (using "::").
ENDofMSG

} elsif ( $] < 5.010000 ) {

	$diagnostics = <<'ENDofMSG';
(F) You've said "use strict" or "use strict vars", which indicates
that all variables must either be lexically scoped (using "my"),
declared beforehand using "our", or explicitly qualified to say
which package the global variable is in (using "::").
ENDofMSG

} else {

	$diagnostics = <<'ENDofMSG';
(F) You've said "use strict" or "use strict vars", which indicates
that all variables must either be lexically scoped (using "my" or "state"),
declared beforehand using "our", or explicitly qualified to say
which package the global variable is in (using "::").
ENDofMSG

}


chomp($diagnostics);

$diagnostics =~ s/\s\n/\n/gs;

my $parser         = Parse::ErrorString::Perl->new;
my @errors_compile = $parser->parse_string($msg_compile);
is( $errors_compile[0]->message, $message, 'message' );

#ok($errors_compile[0]->diagnostics eq $diagnostics, 'diagnostics');
my $obtained_diagnostics = $errors_compile[0]->diagnostics;
$obtained_diagnostics =~ s/\s\n/\n/gs;
eq_or_diff( $obtained_diagnostics, $diagnostics, 'diagnostics' );
is( $errors_compile[0]->type,             'F',           'type' );
is( $errors_compile[0]->type_description, 'fatal error', 'error type' );

