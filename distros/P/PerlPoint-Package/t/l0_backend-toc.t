

# = HISTORY SECTION =====================================================================

# ---------------------------------------------------------------------------------------
# version | date     | author   | changes
# ---------------------------------------------------------------------------------------
# 0.01    |29.09.2001| JSTENZEL | new.
# ---------------------------------------------------------------------------------------

# PerlPoint test script


# pragmata
use strict;

# load modules
use Carp;
use PerlPoint::Tags;            # for perl 5.00503, perl 5.6 loads this implicitly with ...::Basic
use Test::More qw(no_plan);
use PerlPoint::Backend 0.10;
use PerlPoint::Parser 0.36;
use PerlPoint::Tags::Basic;
use PerlPoint::Constants 0.15 qw(:DEFAULT :stream);

# declare variables
my ($toc, @streamData, @expected);

# build parser
my ($parser)=new PerlPoint::Parser;

# and call it
$parser->run(
             stream  => \@streamData,
             files   => ['t/backend-toc.pp'],
             safe    => undef,
             trace   => TRACE_NOTHING,
             display => DISPLAY_NOINFO+DISPLAY_NOWARN,
            );

# build a backend
my $backend=new PerlPoint::Backend(
                                   name    => 'installation test: backend API: TOC',
                                   trace   => TRACE_NOTHING,
                                   display => DISPLAY_NOINFO,
                                  );


# bind stream to backend
$backend->bind(\@streamData);


# describe expected result
@expected=(
           [1, 'A first chapter'],
           [2, 'Details 1'],
           [2, 'Details 2'],
           [2, 'Details 3'],
           [1, 'Back to start level'],
           [1, 'Another topic'],
           [2, 'Subtopic 1'],
           [2, 'Subtopic 2'],
           [3, 'Subtopic 2.1'],
           [3, 'Subtopic 2.2'],
           [4, 'And more: 2.2.1'],
           [2, 'Formatted headline'],
           [2, 'And even heavier tag usage'],
           [1, 'Appendix'],
          );

# complete TOC, default parameters
$toc=$backend->toc;

# check result
is(join('', map {join('', @$_)} @$toc), join('', map {join('', @$_)} @expected));

# ----

# describe expected result
@expected=(
           [1, 'A first chapter'],
           [2, 'Details 1'],
           [2, 'Details 2'],
           [2, 'Details 3'],
           [1, 'Back to start level'],
           [1, 'Another topic'],
           [2, 'Subtopic 1'],
           [2, 'Subtopic 2'],
           [3, 'Subtopic 2.1'],
           [3, 'Subtopic 2.2'],
           [4, 'And more: 2.2.1'],
           [2, 'Formatted headline'],
           [2, 'And even heavier tag usage'],
           [1, 'Appendix'],
          );

# complete TOC, paramters set to 0
$toc=$backend->toc(0, 0);

# check result
is(join('', map {join('', @$_)} @$toc), join('', map {join('', @$_)} @expected));

# ----

# describe expected result
@expected=(
           [1, 'A first chapter'],
           [2, 'Details 1'],
           [2, 'Details 2'],
           [2, 'Details 3'],
           [1, 'Back to start level'],
           [1, 'Another topic'],
           [2, 'Subtopic 1'],
           [2, 'Subtopic 2'],
           [2, 'Formatted headline'],
           [2, 'And even heavier tag usage'],
           [1, 'Appendix'],
          );

# limited depth
$toc=$backend->toc(0, 2);

# check result
is(join('', map {join('', @$_)} @$toc), join('', map {join('', @$_)} @expected));

# ----

# describe expected result
@expected=(
           [3, 'Subtopic 2.1'],
           [3, 'Subtopic 2.2'],
           [4, 'And more: 2.2.1'],
          );

# certain chapter
$toc=$backend->toc(8);

# check result
is(join('', map {join('', @$_)} @$toc), join('', map {join('', @$_)} @expected));

# ----

# describe expected result
@expected=(
           [2, 'Subtopic 1'],
           [2, 'Subtopic 2'],
           [2, 'Formatted headline'],
           [2, 'And even heavier tag usage'],
          );

# certain chapter, limited depth
$toc=$backend->toc(6, 1);

# check result
is(join('', map {join('', @$_)} @$toc), join('', map {join('', @$_)} @expected));

