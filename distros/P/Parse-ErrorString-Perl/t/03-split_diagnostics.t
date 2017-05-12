#!/usr/bin/perl

use strict;
use warnings;

use Test::More tests => 7;
use Parse::ErrorString::Perl;

my $parser = Parse::ErrorString::Perl->new;

# use strict;
# use warnings;
# use diagnostics;
#
# my $empty;
# my $length = length($empty);
#
# my $zero = 0;
# my $result = 5 / 0;

my $msg_split = <<'ENDofMSG';
Use of uninitialized value $empty in length at
	c:\my\very\long\path\to\this\perl\script\called\error.pl line 6 (#1)
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

Illegal division by zero at
	c:\my\very\long\path\to\this\perl\script\called\error.pl line 9 (#2)
    (F) You tried to divide a number by 0.  Either something was wrong in
    your logic, or you need to put a conditional in to guard against
    meaningless input.

Uncaught exception from user code:
	Illegal division by zero at
	c:\my\very\long\path\to\this\perl\script\called\error.pl line 9.
 at c:\my\very\long\path\to\this\perl\script\called\error.pl line 9
ENDofMSG

my @errors_split = $parser->parse_string($msg_split);
is( scalar(@errors_split),          2,                                                          'msg_split results' );
is( $errors_split[0]->message,      'Use of uninitialized value $empty in length',              'msg_split 1 message' );
is( $errors_split[0]->file_msgpath, 'c:\my\very\long\path\to\this\perl\script\called\error.pl', 'msg_split 1 file' );
is( $errors_split[0]->line,         6,                                                          'msg_split 1 line' );
is( $errors_split[1]->message,      'Illegal division by zero',                                 'msg_split 2 message' );
is( $errors_split[1]->file_msgpath, 'c:\my\very\long\path\to\this\perl\script\called\error.pl', 'msg_split 2 file' );
is( $errors_split[1]->line,         9,                                                          'msg_split 2 line' );
