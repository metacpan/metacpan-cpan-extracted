#!/usr/bin/env perl
use strict; use warnings;
use File::Temp qw(tempfile);
use File::Basename;
use Test::More;
use English;

chdir dirname(__FILE__);
my $short_name = basename(__FILE__);
sub test_rc($$) {
    my ($is_zero, $msg) = @_;
    0 == $is_zero ? is($?>>8, 0, $msg) : isnt($?>>8, 0, $msg);
}

diag("Testing return code only");
my @prefix = ("$EXECUTABLE_NAME", '-I../lib', '-MPerl::Syntax');

system(@prefix, $short_name);
test_rc(0, __FILE__ . " is syntactically valid Perl" );

system(@prefix, 'bad.pl');
test_rc(1, "bad.pl is syntactically invalid" );

system(@prefix, '-e', '1+2');
test_rc(0, "1+2 is a syntactically valid Perl expression" );

system(@prefix, '-e', '1+');
test_rc(1, "1+ is not a syntactically invalid Perl expression" );

system("$EXECUTABLE_NAME -I../lib -MPerl::Syntax $short_name");
test_rc(0, "run system with a string" );

diag("Testing Temporary file contents");

my ($fh, $tempfile) = tempfile('SyntaxXXXX', SUFFIX=>'.log',
			       UNLINK => 1,  TMPDIR => 1);

@prefix = ("$EXECUTABLE_NAME", '-I../lib', "-MPerl::Syntax=$tempfile");

system(@prefix, basename(__FILE__));
ok(-s $tempfile, "Should have have written something to $tempfile");
seek($fh, 0, 0);
like(<$fh>, qr/syntax OK/, "Syntax OK message in program file");

system(@prefix, 'bad.pl');
ok(-s $tempfile, "Should have somthing to $tempfile");
seek($fh, 0, 0);
like(<$fh>, qr/^syntax error at /, "syntax error message in program file");

system(@prefix, '-e', 'my $a=foo();');
seek($fh, 0, 0);
like(<$fh>, qr/syntax OK/, "Syntax OK on -e string");

system(@prefix, '-e', 'my $a=foo(');
seek($fh, 0, 0);
like(<$fh>, qr/^syntax error at /, "Syntax error on -e string");

done_testing();
