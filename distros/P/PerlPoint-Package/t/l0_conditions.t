

# = HISTORY SECTION =====================================================================

# ---------------------------------------------------------------------------------------
# version | date     | author   | changes
# ---------------------------------------------------------------------------------------
# 0.05    |28.12.2004| JSTENZEL | adapted to dotted texts;
#         |01.11.2005| JSTENZEL | each document needs a headline now;
# 0.04    |< 14.04.02| JSTENZEL | added SCI function tests;
#         |13.10.2001| JSTENZEL | switched to Test::More;
# 0.03    |20.03.2001| JSTENZEL | adapted to tag templates;
#         |24.05.2001| JSTENZEL | adapted to paragraph reformatting: text paragraphs
#         |          |          | no longer contain a final whitespace string;
#         |01.06.2001| JSTENZEL | adapted to modified lexing algorithm which takes
#         |          |          | "words" as long as possible;
#         |05.06.2001| JSTENZEL | adapted to further optimized lexing;
# 0.02    |09.12.2000| JSTENZEL | new namespace: "PP" => "PerlPoint";
# 0.01    |08.10.2000| JSTENZEL | new.
# ---------------------------------------------------------------------------------------

# PerlPoint test script


# pragmata
use strict;
use lib qw(t);

# load modules
use Cwd;
use Carp;
use Safe;
use PerlPoint::Backend;
use PerlPoint::Constants;
use PerlPoint::Parser 0.37;
use Test::More qw(no_plan);

# helper lib
use testlib;

# declare variables
my (@streamData, @results);

# build parser
my ($parser)=new PerlPoint::Parser;

# and call it
$parser->run(
             stream          => \@streamData,
             files           => ['t/conditions.pp'],
             activeBaseData  => {
                                 userSettings => {flag1=>1},
                                },
             safe            => new Safe,
             trace           => TRACE_NOTHING,
             display         => DISPLAY_NOINFO+DISPLAY_NOWARN,
            );

# build a backend
my $backend=new PerlPoint::Backend(
                                   name    => 'installation test: condition paragraphs',
                                   trace   => TRACE_NOTHING,
                                   display => DISPLAY_NOINFO,
                                  );

# register a complete set of backend handlers
$backend->register($_, \&handler) foreach (
                                           DIRECTIVE_BLOCK,
                                           DIRECTIVE_COMMENT,
                                           DIRECTIVE_DOCUMENT,
                                           DIRECTIVE_DPOINT,
                                           DIRECTIVE_HEADLINE,
                                           DIRECTIVE_LIST_LSHIFT,
                                           DIRECTIVE_LIST_RSHIFT,
                                           DIRECTIVE_OPOINT,
                                           DIRECTIVE_TAG,
                                           DIRECTIVE_TEXT,
                                           DIRECTIVE_UPOINT,
                                           DIRECTIVE_VERBATIM,
                                           DIRECTIVE_SIMPLE,
                                          );

# now run the backend
$backend->run(\@streamData);

# perform checks
is(shift(@results), $_) foreach (DIRECTIVE_DOCUMENT, DIRECTIVE_START, 'conditions.pp');

# variable hash
my $varhash={
             _STARTDIR       => cwd(),
             _PARSER_VERSION => $PerlPoint::Parser::VERSION,
             _SOURCE_LEVEL   => 1,
            };

is(shift(@results), $_) foreach (DIRECTIVE_HEADLINE, DIRECTIVE_START, 1, 'Conditions', '');
{
 my $docstreams=shift(@results);
 is(ref($docstreams), 'ARRAY');
 is(join(' ', @$docstreams), '');
}

checkHeadline(\@results, 1, ['Conditions'], ['Conditions'], [1], [1], $varhash);

is(shift(@results), $_) foreach (DIRECTIVE_SIMPLE, DIRECTIVE_START, 'Conditions');
is(shift(@results), $_) foreach (DIRECTIVE_HEADLINE, DIRECTIVE_COMPLETE, 1);

is(shift(@results), $_) foreach (DIRECTIVE_TEXT, DIRECTIVE_START);
is(shift(@results), $_) foreach (DIRECTIVE_SIMPLE, DIRECTIVE_START, 'Conditions allow to maintain all versions of a presentation in one file');
is(shift(@results), $_) foreach (DIRECTIVE_SIMPLE, DIRECTIVE_START, '.');
is(shift(@results), $_) foreach (DIRECTIVE_TEXT, DIRECTIVE_COMPLETE);

is(shift(@results), $_) foreach (DIRECTIVE_TEXT, DIRECTIVE_START);
is(shift(@results), $_) foreach (DIRECTIVE_SIMPLE, DIRECTIVE_START, 'Back to main text');
is(shift(@results), $_) foreach (DIRECTIVE_SIMPLE, DIRECTIVE_START, '.');
is(shift(@results), $_) foreach (DIRECTIVE_TEXT, DIRECTIVE_COMPLETE);

is(shift(@results), $_) foreach (DIRECTIVE_TEXT, DIRECTIVE_START);
is(shift(@results), $_) foreach (DIRECTIVE_SIMPLE, DIRECTIVE_START, 'flag1 set');
is(shift(@results), $_) foreach (DIRECTIVE_SIMPLE, DIRECTIVE_START, '.');
is(shift(@results), $_) foreach (DIRECTIVE_TEXT, DIRECTIVE_COMPLETE);

is(shift(@results), $_) foreach (DIRECTIVE_TEXT, DIRECTIVE_START);
is(shift(@results), $_) foreach (DIRECTIVE_SIMPLE, DIRECTIVE_START, 'flag1 or flag2 set');
is(shift(@results), $_) foreach (DIRECTIVE_SIMPLE, DIRECTIVE_START, '.');
is(shift(@results), $_) foreach (DIRECTIVE_TEXT, DIRECTIVE_COMPLETE);

is(shift(@results), $_) foreach (DIRECTIVE_TEXT, DIRECTIVE_START);
is(shift(@results), $_) foreach (DIRECTIVE_SIMPLE, DIRECTIVE_START, 'Variable is greater than 10');
is(shift(@results), $_) foreach (DIRECTIVE_SIMPLE, DIRECTIVE_START, '.');
is(shift(@results), $_) foreach (DIRECTIVE_TEXT, DIRECTIVE_COMPLETE);

is(shift(@results), $_) foreach (DIRECTIVE_DOCUMENT, DIRECTIVE_COMPLETE, 'conditions.pp');


# SUBROUTINES ###############################################################################

# headline handler: store what you found
sub handler
 {
  # simply store what you received
  push(@results, @_);
 }
