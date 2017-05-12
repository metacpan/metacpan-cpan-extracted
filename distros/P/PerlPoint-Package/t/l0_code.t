

# = HISTORY SECTION =====================================================================

# ---------------------------------------------------------------------------------------
# version | date     | author   | changes
# ---------------------------------------------------------------------------------------
# 0.05    |01.11.2005| JSTENZEL | each document needs a headline now;
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
use Safe;
use PerlPoint::Backend;
use PerlPoint::Constants;
use PerlPoint::Parser 0.08;
use Test::More qw(no_plan);

# declare variables
my (@streamData, @results);

# build parser
my ($parser)=new PerlPoint::Parser;

# and call it
$parser->run(
             stream  => \@streamData,
             files   => ['t/code.pp'],
             safe    => new Safe,
             trace   => TRACE_NOTHING,
             display => DISPLAY_NOINFO+DISPLAY_NOWARN,
            );

# build a backend
my $backend=new PerlPoint::Backend(
                                   name    =>'installation test: code',
                                   trace   =>TRACE_NOTHING,
                                   display => DISPLAY_NOINFO,
                                  );

# register a complete set of backend handlers
$backend->register($_, \&handler) foreach (DIRECTIVE_BLOCK .. DIRECTIVE_SIMPLE);

# now run the backend
$backend->run(\@streamData);

# perform checks
shift(@results) until $results[0] eq DIRECTIVE_BLOCK or not @results;

# just three blocks
foreach (1..2)
 {
  is(shift(@results), $_) foreach (DIRECTIVE_BLOCK, DIRECTIVE_START);
  shift(@results) until $results[0] eq DIRECTIVE_BLOCK or not @results;
  is(shift(@results), $_) foreach (DIRECTIVE_BLOCK, DIRECTIVE_COMPLETE);
 }


# SUBROUTINES ###############################################################################

# headline handler: store what you found
sub handler
 {
  # simply store what you received
  push(@results, @_);
 }
