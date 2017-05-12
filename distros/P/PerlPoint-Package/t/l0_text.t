

# = HISTORY SECTION =====================================================================

# ---------------------------------------------------------------------------------------
# version | date     | author   | changes
# ---------------------------------------------------------------------------------------
# 0.06    |01.11.2005| JSTENZEL | each document needs a headline now;
# 0.05    |16.08.2001| JSTENZEL | no need to build a Safe object;
# 0.04    |20.03.2001| JSTENZEL | adapted to tag templates;
# 0.03    |09.12.2000| JSTENZEL | new namespace: "PP" => "PerlPoint";
# 0.02    |05.10.2000| JSTENZEL | parser takes a Safe object now;
# 0.01    |08.04.2000| JSTENZEL | new.
# ---------------------------------------------------------------------------------------

# PerlPoint test script


# pragmata
use strict;
use lib qw(t);

# load modules
use Cwd;
use Carp;
use PerlPoint::Backend;
use PerlPoint::Constants;
use PerlPoint::Parser 0.40;
use Test::More qw(no_plan);

# declare variables
my (@streamData, @results);

# build parsers
my ($parser1, $parser2)=(new PerlPoint::Parser, new PerlPoint::Parser);

# and call the first of them
$parser1->run(
              stream  => \@streamData,
              files   => ['t/text.pp'],
              trace   => TRACE_NOTHING,
              display => DISPLAY_NOINFO + DISPLAY_NOWARN,
             );

# build a backend
my $backend=new PerlPoint::Backend(
                                   name    =>'installation test: text',
                                   trace   =>TRACE_NOTHING,
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

# now run the backend for the first parser
$backend->run(\@streamData);

# perform checks for first parser
shift(@results) until $results[0] eq DIRECTIVE_TEXT or not @results;

# these checks are straight forward (almost too simple)
foreach (1..4)
 {
  is(shift(@results), $_) foreach (DIRECTIVE_TEXT, DIRECTIVE_START);
  shift(@results) until $results[0] eq DIRECTIVE_TEXT or not @results;
  is(shift(@results), $_) foreach (DIRECTIVE_TEXT, DIRECTIVE_COMPLETE);
 }


# run the second parser
$parser2->run(
              stream  => \@streamData,
              files   => ['t/text2.pp'],
              trace   => TRACE_NOTHING,
              display => DISPLAY_NOINFO + DISPLAY_NOWARN,
             );

# now run the backend for the second parser
$backend->run(\@streamData);

# perform checks for first parser
shift(@results) until (defined($results[0]) and $results[0] eq DIRECTIVE_TEXT) or not @results;

# these checks are straight forward (almost too simple)
foreach (1..4)
 {
  is(shift(@results), $_) foreach (DIRECTIVE_TEXT, DIRECTIVE_START);
  shift(@results) until $results[0] eq DIRECTIVE_TEXT or not @results;
  is(shift(@results), $_) foreach (DIRECTIVE_TEXT, DIRECTIVE_COMPLETE);
 }


# SUBROUTINES ###############################################################################

# headline handler: store what you found
sub handler
 {
  # simply store what you received
  push(@results, @_);
 }
