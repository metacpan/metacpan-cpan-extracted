

# = HISTORY SECTION =====================================================================

# ---------------------------------------------------------------------------------------
# version | date     | author   | changes
# ---------------------------------------------------------------------------------------
# 0.09    |01.11.2005| JSTENZEL | each document needs a headline now;
# 0.08    |16.08.2001| JSTENZEL | no need to build a Safe object;
#         |13.11.2001| JSTENZEL | DIRECTIVE_COMPLETE entries for list shifts are gone;
#         |          | JSTENZEL | switched to Test::More;
#         |27.11.2001| JSTENZEL | adapted to additional shift hints in list directives;
# 0.07    |20.03.2001| JSTENZEL | adapted to tag templates;
#         |01.06.2001| JSTENZEL | adapted to modified lexing algorithm which takes
#         |          |          | "words" as long as possible;
# 0.06    |30.01.2001| JSTENZEL | ordered lists now provide the entry level number;
# 0.05    |09.12.2000| JSTENZEL | new namespace: "PP" => "PerlPoint";
# 0.04    |18.11.2000| JSTENZEL | new ordered list continuation;
# 0.03    |05.10.2000| JSTENZEL | parser takes a Safe object now;
#         |07.10.2000| JSTENZEL | new multilevel shifts;
# 0.02    |03.10.2000| JSTENZEL | adapted to new definition list syntax;
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
use PerlPoint::Parser 0.08;
use Test::More qw(no_plan);

# helper lib
use testlib;

# declare variables
my (@streamData, @results);

# build parser
my ($parser)=new PerlPoint::Parser;

# and call it
$parser->run(
             stream  => \@streamData,
             files   => ['t/lists.pp'],
             trace   => TRACE_NOTHING,
             display => DISPLAY_NOINFO+DISPLAY_NOWARN,
            );

# build a backend
my $backend=new PerlPoint::Backend(
                                   name    =>'installation test: lists',
                                   trace   =>TRACE_NOTHING,
                                   display => DISPLAY_NOINFO,
                                  );

# register a complete set of backend handlers
$backend->register($_, \&handler) foreach (DIRECTIVE_BLOCK .. DIRECTIVE_SIMPLE);

# now run the backend
$backend->run(\@streamData);

# perform checks
shift(@results) until $results[0] eq DIRECTIVE_ULIST or not @results;

# 1st level
is(shift(@results), $_) foreach (DIRECTIVE_ULIST, DIRECTIVE_START, (0) x 5);
is(shift(@results), $_) foreach (DIRECTIVE_UPOINT, DIRECTIVE_START);
shift(@results) until $results[0] eq DIRECTIVE_UPOINT or not @results;
is(shift(@results), $_) foreach (DIRECTIVE_UPOINT, DIRECTIVE_COMPLETE);

is(shift(@results), $_) foreach (DIRECTIVE_UPOINT, DIRECTIVE_START);
shift(@results) until $results[0] eq DIRECTIVE_UPOINT or not @results;
is(shift(@results), $_) foreach (DIRECTIVE_UPOINT, DIRECTIVE_COMPLETE);
is(shift(@results), $_) foreach (DIRECTIVE_ULIST, DIRECTIVE_COMPLETE, (0) x 5);

is(shift(@results), $_) foreach (DIRECTIVE_OLIST, DIRECTIVE_START, 1, (0) x 4);
is(shift(@results), $_) foreach (DIRECTIVE_OPOINT, DIRECTIVE_START);
shift(@results) until $results[0] eq DIRECTIVE_OPOINT or not @results;
is(shift(@results), $_) foreach (DIRECTIVE_OPOINT, DIRECTIVE_COMPLETE);

is(shift(@results), $_) foreach (DIRECTIVE_OPOINT, DIRECTIVE_START);
shift(@results) until $results[0] eq DIRECTIVE_OPOINT or not @results;
is(shift(@results), $_) foreach (DIRECTIVE_OPOINT, DIRECTIVE_COMPLETE);
is(shift(@results), $_) foreach (DIRECTIVE_OLIST, DIRECTIVE_COMPLETE, 1, 0, 0, DIRECTIVE_LIST_RSHIFT, 1);

# shift right
is(shift(@results), $_) foreach (DIRECTIVE_LIST_RSHIFT, DIRECTIVE_START, 1);

# 2nd level
is(shift(@results), $_) foreach (DIRECTIVE_OLIST, DIRECTIVE_START, 1, DIRECTIVE_LIST_RSHIFT, 1, 0, 0);
is(shift(@results), $_) foreach (DIRECTIVE_OPOINT, DIRECTIVE_START);
shift(@results) until $results[0] eq DIRECTIVE_OPOINT or not @results;
is(shift(@results), $_) foreach (DIRECTIVE_OPOINT, DIRECTIVE_COMPLETE);
is(shift(@results), $_) foreach (DIRECTIVE_OLIST, DIRECTIVE_COMPLETE, 1, (0) x 4);

is(shift(@results), $_) foreach (DIRECTIVE_ULIST, DIRECTIVE_START, (0) x 5);
is(shift(@results), $_) foreach (DIRECTIVE_UPOINT, DIRECTIVE_START);
shift(@results) until $results[0] eq DIRECTIVE_UPOINT or not @results;
is(shift(@results), $_) foreach (DIRECTIVE_UPOINT, DIRECTIVE_COMPLETE);
is(shift(@results), $_) foreach (DIRECTIVE_ULIST, DIRECTIVE_COMPLETE, (0) x 5);

is(shift(@results), $_) foreach (DIRECTIVE_OLIST, DIRECTIVE_START, 2, (0) x 4);
is(shift(@results), $_) foreach (DIRECTIVE_OPOINT, DIRECTIVE_START, 2);
shift(@results) until $results[0] eq DIRECTIVE_OPOINT or not @results;
is(shift(@results), $_) foreach (DIRECTIVE_OPOINT, DIRECTIVE_COMPLETE, 2);
is(shift(@results), $_) foreach (DIRECTIVE_OLIST, DIRECTIVE_COMPLETE, 2, 0, 0, DIRECTIVE_LIST_RSHIFT, 2);

# shift right 2 levels
is(shift(@results), $_) foreach (DIRECTIVE_LIST_RSHIFT, DIRECTIVE_START, 2);

# 4th level
is(shift(@results), $_) foreach (DIRECTIVE_ULIST, DIRECTIVE_START, 0, DIRECTIVE_LIST_RSHIFT, 2, 0, 0);
is(shift(@results), $_) foreach (DIRECTIVE_UPOINT, DIRECTIVE_START);
shift(@results) until $results[0] eq DIRECTIVE_UPOINT or not @results;
is(shift(@results), $_) foreach (DIRECTIVE_UPOINT, DIRECTIVE_COMPLETE);
is(shift(@results), $_) foreach (DIRECTIVE_ULIST, DIRECTIVE_COMPLETE, (0) x 5);

is(shift(@results), $_) foreach (DIRECTIVE_OLIST, DIRECTIVE_START, 1, (0) x 4);
is(shift(@results), $_) foreach (DIRECTIVE_OPOINT, DIRECTIVE_START);
shift(@results) until $results[0] eq DIRECTIVE_OPOINT or not @results;
is(shift(@results), $_) foreach (DIRECTIVE_OPOINT, DIRECTIVE_COMPLETE);
is(shift(@results), $_) foreach (DIRECTIVE_OLIST, DIRECTIVE_COMPLETE, 1, 0, 0, DIRECTIVE_LIST_LSHIFT, 2);

# shift left 2 levels
is(shift(@results), $_) foreach (DIRECTIVE_LIST_LSHIFT, DIRECTIVE_START, 2);

# 2nd level
is(shift(@results), $_) foreach (DIRECTIVE_ULIST, DIRECTIVE_START, 0, DIRECTIVE_LIST_LSHIFT, 2, 0, 0);
is(shift(@results), $_) foreach (DIRECTIVE_UPOINT, DIRECTIVE_START);
shift(@results) until $results[0] eq DIRECTIVE_UPOINT or not @results;
is(shift(@results), $_) foreach (DIRECTIVE_UPOINT, DIRECTIVE_COMPLETE);
is(shift(@results), $_) foreach (DIRECTIVE_ULIST, DIRECTIVE_COMPLETE, 0, 0, 0, DIRECTIVE_LIST_LSHIFT, 1);

# shift left
is(shift(@results), $_) foreach (DIRECTIVE_LIST_LSHIFT, DIRECTIVE_START, 1);

# 1st level
is(shift(@results), $_) foreach (DIRECTIVE_OLIST, DIRECTIVE_START, 1, DIRECTIVE_LIST_LSHIFT, 1, 0, 0);
is(shift(@results), $_) foreach (DIRECTIVE_OPOINT, DIRECTIVE_START);
shift(@results) until $results[0] eq DIRECTIVE_OPOINT or not @results;
is(shift(@results), $_) foreach (DIRECTIVE_OPOINT, DIRECTIVE_COMPLETE);

is(shift(@results), $_) foreach (DIRECTIVE_OPOINT, DIRECTIVE_START);
shift(@results) until $results[0] eq DIRECTIVE_OPOINT or not @results;
is(shift(@results), $_) foreach (DIRECTIVE_OPOINT, DIRECTIVE_COMPLETE);
is(shift(@results), $_) foreach (DIRECTIVE_OLIST, DIRECTIVE_COMPLETE, 1, (0) x 4);

is(shift(@results), $_) foreach (DIRECTIVE_ULIST, DIRECTIVE_START, (0) x 5);
is(shift(@results), $_) foreach (DIRECTIVE_UPOINT, DIRECTIVE_START);
shift(@results) until $results[0] eq DIRECTIVE_UPOINT or not @results;
is(shift(@results), $_) foreach (DIRECTIVE_UPOINT, DIRECTIVE_COMPLETE);
is(shift(@results), $_) foreach (DIRECTIVE_ULIST, DIRECTIVE_COMPLETE, (0) x 5);


is(shift(@results), $_) foreach (DIRECTIVE_DLIST, DIRECTIVE_START, (0) x 5);
is(shift(@results), $_) foreach (DIRECTIVE_DPOINT, DIRECTIVE_START);
is(shift(@results), $_) foreach (DIRECTIVE_DPOINT_ITEM, DIRECTIVE_START);
is(shift(@results), $_) foreach (DIRECTIVE_SIMPLE, DIRECTIVE_START, 'definition');
is(shift(@results), $_) foreach (DIRECTIVE_DPOINT_ITEM, DIRECTIVE_COMPLETE);
shift(@results) until $results[0] eq DIRECTIVE_DPOINT or not @results;
is(shift(@results), $_) foreach (DIRECTIVE_DPOINT, DIRECTIVE_COMPLETE);

is(shift(@results), $_) foreach (DIRECTIVE_DPOINT, DIRECTIVE_START);
is(shift(@results), $_) foreach (DIRECTIVE_DPOINT_ITEM, DIRECTIVE_START);
is(shift(@results), $_) foreach (DIRECTIVE_SIMPLE, DIRECTIVE_START, ' ');
is(shift(@results), $_) foreach (DIRECTIVE_SIMPLE, DIRECTIVE_START, 'definition with spaces ');
is(shift(@results), $_) foreach (DIRECTIVE_DPOINT_ITEM, DIRECTIVE_COMPLETE);
shift(@results) until $results[0] eq DIRECTIVE_DPOINT or not @results;
is(shift(@results), $_) foreach (DIRECTIVE_DPOINT, DIRECTIVE_COMPLETE);
is(shift(@results), $_) foreach (DIRECTIVE_DLIST, DIRECTIVE_COMPLETE, (0) x 5);



# SUBROUTINES ###############################################################################

# headline handler: store what you found
sub handler
 {
  # simply store what you received
  push(@results, @_);
 }
