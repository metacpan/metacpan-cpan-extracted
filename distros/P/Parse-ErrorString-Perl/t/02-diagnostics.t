#!/usr/bin/perl

use strict;
use warnings;

use Test::More tests => 25;
use Parse::ErrorString::Perl;

my $parser = Parse::ErrorString::Perl->new;

# use strict;
# use warnings;
# use diagnostics;
#
# $kaboom;

my $msg_compile = <<'ENDofMSG';
Global symbol "$kaboom" requires explicit package name at error.pl line 5.
Execution of error.pl aborted due to compilation errors (#1)
    (F) You've said "use strict" or "use strict vars", which indicates
    that all variables must either be lexically scoped (using "my" or "state"),
    declared beforehand using "our", or explicitly qualified to say
    which package the global variable is in (using "::").

Uncaught exception from user code:
	Global symbol "$kaboom" requires explicit package name at error.pl line 5.
Execution of error.pl aborted due to compilation errors.
 at error.pl line 5

ENDofMSG

my @errors_compile = $parser->parse_string($msg_compile);
is( scalar(@errors_compile),          1,                                                        'msg_compile results' );
is( $errors_compile[0]->message,      'Global symbol "$kaboom" requires explicit package name', 'msg_compile message' );
is( $errors_compile[0]->file_msgpath, 'error.pl',                                               'msg_compile file' );
is( $errors_compile[0]->line,         5,                                                        'msg_compile line' );


# use strict;
# use warnings;
# use diagnostics;
#
# my $empty;
# my $length = length($empty);
#
# my $zero = 0;
# my $result = 5 / 0;

my $msg_runtime = <<'ENDofMSG';
Use of uninitialized value $empty in length at error.pl line 6 (#1)
    (W uninitialized) An undefined value was used as if it were already
    defined.  It was interpreted as a "" or a 0, but maybe it was a mistake.
    To suppress this warning assign a defined value to your variables.

    To help you figure out what was undefined, perl will try to tell you the
    name of the variable (if any) that was undefined. In some cases it cannot
    do this, so it also tells you what operation you used the undefined value
    in.  Note, however, that perl optimizes your program and the operation
    displayed in the warning may not necessarily appear literally in your
    program.  For example, "that $foo" is usually optimized into "that "
    . $foo, and the warning will refer to the concatenation (.) operator,
    even though there is no . in your program.

Illegal division by zero at error.pl line 9 (#2)
    (F) You tried to divide a number by 0.  Either something was wrong in
    your logic, or you need to put a conditional in to guard against
    meaningless input.

Uncaught exception from user code:
	Illegal division by zero at error.pl line 9.
 at error.pl line 9
ENDofMSG

my @errors_runtime = $parser->parse_string($msg_runtime);
is( scalar(@errors_runtime),          2,                                             'msg_runtime results' );
is( $errors_runtime[0]->message,      'Use of uninitialized value $empty in length', 'msg_runtime 1 message' );
is( $errors_runtime[0]->file_msgpath, 'error.pl',                                    'msg_runtime 1 file' );
is( $errors_runtime[0]->line,         6,                                             'msg_runtime 1 line' );
is( $errors_runtime[1]->message,      'Illegal division by zero',                    'msg_runtime 2 message' );
is( $errors_runtime[1]->file_msgpath, 'error.pl',                                    'msg_runtime 2 file' );
is( $errors_runtime[1]->line,         9,                                             'msg_runtime 2 line' );

# use strict;
# use warnings;
# use diagnostics;
#
# my $string = 'tada';
# kaboom
#
# my $length = 5;

my $msg_near = <<'ENDofMSG';
syntax error at error.pl line 8, near "kaboom

my "
Global symbol "$length" requires explicit package name at error.pl line 8.
Execution of error.pl aborted due to compilation errors (#1)
    (F) Probably means you had a syntax error.  Common reasons include:

        A keyword is misspelled.
        A semicolon is missing.
        A comma is missing.
        An opening or closing parenthesis is missing.
        An opening or closing brace is missing.
        A closing quote is missing.

    Often there will be another error message associated with the syntax
    error giving more information.  (Sometimes it helps to turn on -w.)
    The error message itself often tells you where it was in the line when
    it decided to give up.  Sometimes the actual error is several tokens
    before this, because Perl is good at understanding random input.
    Occasionally the line number may be misleading, and once in a blue moon
    the only way to figure out what's triggering the error is to call
    perl -c repeatedly, chopping away half the program each time to see
    if the error went away.  Sort of the cybernetic version of S<20
    questions>.

Uncaught exception from user code:
	syntax error at error.pl line 8, near "kaboom

my "
Global symbol "$length" requires explicit package name at error.pl line 8.
Execution of error.pl aborted due to compilation errors.
 at error.pl line 8
ENDofMSG

my @errors_near = $parser->parse_string($msg_near);
is( scalar(@errors_near),          2,                                                        'msg_near results' );
is( $errors_near[0]->message,      'syntax error',                                           'msg_near 1 message' );
is( $errors_near[0]->file_msgpath, 'error.pl',                                               'msg_near 1 file' );
is( $errors_near[0]->line,         8,                                                        'msg_near 1 line' );
is( $errors_near[1]->message,      'Global symbol "$length" requires explicit package name', 'msg_near 2 message' );
is( $errors_near[1]->file_msgpath, 'error.pl',                                               'msg_near 2 file' );
is( $errors_near[1]->line,         8,                                                        'msg_near 2 line' );

# use strict;
# use warnings;
# use diagnostics;
#
# if (1) { if (2)

my $msg_at = <<'ENDofMSG';
syntax error at error.pl line 5, at EOF
Missing right curly or square bracket at error.pl line 5, at end of line
Execution of error.pl aborted due to compilation errors (#1)
    (F) Probably means you had a syntax error.  Common reasons include:

        A keyword is misspelled.
        A semicolon is missing.
        A comma is missing.
        An opening or closing parenthesis is missing.
        An opening or closing brace is missing.
        A closing quote is missing.

    Often there will be another error message associated with the syntax
    error giving more information.  (Sometimes it helps to turn on -w.)
    The error message itself often tells you where it was in the line when
    it decided to give up.  Sometimes the actual error is several tokens
    before this, because Perl is good at understanding random input.
    Occasionally the line number may be misleading, and once in a blue moon
    the only way to figure out what's triggering the error is to call
    perl -c repeatedly, chopping away half the program each time to see
    if the error went away.  Sort of the cybernetic version of S<20
    questions>.

Uncaught exception from user code:
	syntax error at error.pl line 5, at EOF
Missing right curly or square bracket at error.pl line 5, at end of line
Execution of error.pl aborted due to compilation errors.
 at error.pl line 5
ENDofMSG

my @errors_at = $parser->parse_string($msg_at);
is( scalar(@errors_at),          2,                                       'msg_at results' );
is( $errors_at[0]->message,      'syntax error',                          'msg_at 1 message' );
is( $errors_at[0]->file_msgpath, 'error.pl',                              'msg_at 1 file' );
is( $errors_at[0]->line,         5,                                       'msg_at 1 line' );
is( $errors_at[1]->message,      'Missing right curly or square bracket', 'msg_at 2 message' );
is( $errors_at[1]->file_msgpath, 'error.pl',                              'msg_at 2 file' );
is( $errors_at[1]->line,         5,                                       'msg_at 2 line' );

