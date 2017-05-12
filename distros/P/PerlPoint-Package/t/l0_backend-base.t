

# = HISTORY SECTION =====================================================================

# ---------------------------------------------------------------------------------------
# version | date     | author   | changes
# ---------------------------------------------------------------------------------------
# 0.05    |16.08.2001| JSTENZEL | no need to build a Safe object;
#         |17.08.2001| JSTENZEL | switched from Test to Test::More;
# 0.04    |20.03.2001| JSTENZEL | adapted to tag templates;
# 0.03    |09.12.2000| JSTENZEL | new namespace: "PP" => "PerlPoint";
# 0.02    |05.10.2000| JSTENZEL | parser takes a Safe object now;
# 0.01    |08.04.2000| JSTENZEL | new.
# ---------------------------------------------------------------------------------------

# PerlPoint test script


# pragmata
use strict;

# load modules
use Carp;
use Test::More qw(no_plan);
use PerlPoint::Backend;
use PerlPoint::Parser 0.08;
use PerlPoint::Constants;

# declare variables
my (@streamData, @results);

# build parser
my ($parser)=new PerlPoint::Parser;

# and call it
$parser->run(
             stream  => \@streamData,
             files   => ['t/empty1.pp'],
             safe    => undef,
             trace   => TRACE_NOTHING,
             display => DISPLAY_NOINFO+DISPLAY_NOWARN,
            );

# build a first backend
my $backend1=new PerlPoint::Backend(
                                    name    => 'installation test: backend1',
                                    trace   => TRACE_NOTHING,
                                    display => DISPLAY_NOINFO,
                                   );

# register a complete set of backend handlers
$backend1->register($_, \&handler1) foreach (
                                             DIRECTIVE_BLOCK,
                                             DIRECTIVE_COMMENT,
                                             DIRECTIVE_DOCUMENT,
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

# now run the 1st backend
$backend1->run(\@streamData);

# start first checks
is(shift(@results), $_) foreach (
                                 DIRECTIVE_DOCUMENT, DIRECTIVE_START,    'empty1.pp',
                                 DIRECTIVE_DOCUMENT, DIRECTIVE_COMPLETE, 'empty1.pp',
                                );

# install a second backend
my $backend2=new PerlPoint::Backend(
                                    name    => 'installation test: backend2',
                                    trace   => TRACE_NOTHING,
                                    display => DISPLAY_NOINFO,
                                   );

# register a complete set of backend handlers
$backend2->register($_, \&handler2) foreach (
                                             DIRECTIVE_BLOCK,
                                             DIRECTIVE_COMMENT,
                                             DIRECTIVE_DOCUMENT,
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

# now run the 2nd backend
$backend2->run(\@streamData);

# start second check suite
is(shift(@results), $_) foreach (1..6);



# SUBROUTINES ###############################################################################

# helper
my $i;

# handler: store what you found
sub handler1
 {
  # simply store what you received
  push(@results, @_);
 }

# handler: 
sub handler2
 {
  # simply store a counter value
  push(@results, ++$i) foreach @_;
 }
