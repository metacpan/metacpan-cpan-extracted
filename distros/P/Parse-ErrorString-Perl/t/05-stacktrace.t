#!/usr/bin/perl

use strict;
use warnings;

use Test::More tests => 8;
use Parse::ErrorString::Perl;


# use strict;
# use warnings;
# use diagnostics '-traceonly';
#
# sub dying { my $illegal = 10 / 0;}
# sub calling {dying()}
#
# calling();


my $msg = <<'ENDofMSG';
Uncaught exception from user code:
	Illegal division by zero at error.pl line 5.
 at error.pl line 5
	main::dying() called at error.pl line 6
	main::calling() called at error.pl line 8
ENDofMSG

my $parser = Parse::ErrorString::Perl->new;
my @errors = $parser->parse_string($msg);
is( scalar(@errors), 1, 'message results' );
my @stacktrace = $errors[0]->stack;
is( scalar(@stacktrace),          2,                 'stacktrace results' );
is( $stacktrace[0]->sub,          'main::dying()',   'stack 1 sub' );
is( $stacktrace[0]->file_msgpath, 'error.pl',        'stack 1 file_msgpath' );
is( $stacktrace[0]->line,         6,                 'stack 1 line' );
is( $stacktrace[1]->sub,          'main::calling()', 'stack 2 sub' );
is( $stacktrace[1]->file_msgpath, 'error.pl',        'stack 2 file_msgpath' );
is( $stacktrace[1]->line,         8,                 'stack 2 line' );


