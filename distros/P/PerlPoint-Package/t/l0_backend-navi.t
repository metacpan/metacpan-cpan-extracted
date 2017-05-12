

# = HISTORY SECTION =====================================================================

# ---------------------------------------------------------------------------------------
# version | date     | author   | changes
# ---------------------------------------------------------------------------------------
# 0.03    |26.12.2004| JSTENZEL | adapted to new headline path data;
#         |28.12.2004| JSTENZEL | adapted to dotted texts;
# 0.02    |< 14.04.02| JSTENZEL | adapted to headline shortcuts;
#         |15.04.2002| JSTENZEL | adapted to chapter docstream hints;
# 0.01    |15.08.2001| JSTENZEL | new.
# ---------------------------------------------------------------------------------------

# PerlPoint test script


# pragmata
use strict;
use lib qw(t);

# load helper module
use testlib;

# load modules
use Cwd;
use Carp;
use Test::More qw(no_plan);
use PerlPoint::Backend 0.10;
use PerlPoint::Parser 0.35;
use PerlPoint::Constants 0.15 qw(:DEFAULT :stream);

# declare variables
my ($passedHeadlines, @streamData, @results)=(0);

# build parser
my ($parser)=new PerlPoint::Parser;

# and call it
$parser->run(
             stream  => \@streamData,
             files   => ['t/backend-modes.pp'],
             safe    => undef,
             trace   => TRACE_NOTHING,
             display => DISPLAY_NOINFO+DISPLAY_NOWARN,
            );

# build a backend
my $backend=new PerlPoint::Backend(
                                   name    => 'installation test: backend navigation',
                                   trace   => TRACE_NOTHING,
                                   display => DISPLAY_NOINFO,
                                  );

# register a complete set of backend handlers
$backend->register($_, \&jumper) foreach (
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

# init headline jump table
my @jumpTable=(3, 2, 1, 3, 1);

# run the backend
$backend->run(\@streamData);

# run tests
testSuite();

# - next turn ---

# ok, now use the alternative interface: bind stream, walk manually, unbind stream
$backend->bind(\@streamData);
{redo while $backend->next;}
$backend->unbind;

# results should not differ from default processing
is(shift(@results), $_) foreach (DIRECTIVE_DOCUMENT, DIRECTIVE_START, 'backend-modes.pp');

is(shift(@results), $_) foreach (DIRECTIVE_HEADLINE, DIRECTIVE_START, 1, 'A new chapter', '');
{
 my $docstreams=shift(@results);
 is(ref($docstreams), 'ARRAY');
 is(join(' ', @$docstreams), '');
 checkHeadline(\@results, 1, ['A new chapter'], ['A new chapter'], [1], [1], {_STARTDIR=>cwd(), _PARSER_VERSION=>$PerlPoint::Parser::VERSION, _SOURCE_LEVEL=>1});
}
is(shift(@results), $_) foreach (DIRECTIVE_SIMPLE, DIRECTIVE_START, 'A new chapter');
is(shift(@results), $_) foreach (DIRECTIVE_HEADLINE, DIRECTIVE_COMPLETE, 1);

is(shift(@results), $_) foreach (DIRECTIVE_TEXT, DIRECTIVE_START);
is(shift(@results), $_) foreach (DIRECTIVE_SIMPLE, DIRECTIVE_START, 'It comes with text');
is(shift(@results), $_) foreach (DIRECTIVE_SIMPLE, DIRECTIVE_START, '.');
is(shift(@results), $_) foreach (DIRECTIVE_TEXT, DIRECTIVE_COMPLETE);

is(shift(@results), $_) foreach (DIRECTIVE_HEADLINE, DIRECTIVE_START, 2, 'And a subchapter', '');
{
 my $docstreams=shift(@results);
 is(ref($docstreams), 'ARRAY');
 is(join(' ', @$docstreams), '');
 checkHeadline(\@results, 2, ['A new chapter', 'And a subchapter'], ['A new chapter', 'And a subchapter'], [1, 1], [1, 2], {_STARTDIR=>cwd(), _PARSER_VERSION=>$PerlPoint::Parser::VERSION, _SOURCE_LEVEL=>1});
}
is(shift(@results), $_) foreach (DIRECTIVE_SIMPLE, DIRECTIVE_START, 'And a subchapter');
is(shift(@results), $_) foreach (DIRECTIVE_HEADLINE, DIRECTIVE_COMPLETE, 2);

is(shift(@results), $_) foreach (DIRECTIVE_TEXT, DIRECTIVE_START);
is(shift(@results), $_) foreach (DIRECTIVE_SIMPLE, DIRECTIVE_START, 'with more text');
is(shift(@results), $_) foreach (DIRECTIVE_SIMPLE, DIRECTIVE_START, '.');
is(shift(@results), $_) foreach (DIRECTIVE_TEXT, DIRECTIVE_COMPLETE);

is(shift(@results), $_) foreach (DIRECTIVE_HEADLINE, DIRECTIVE_START, 1, 'OK for today', '');
{
 my $docstreams=shift(@results);
 is(ref($docstreams), 'ARRAY');
 is(join(' ', @$docstreams), '');
 checkHeadline(\@results, 1, ['OK for today'], ['OK for today'], [2], [3], {_STARTDIR=>cwd(), _PARSER_VERSION=>$PerlPoint::Parser::VERSION, _SOURCE_LEVEL=>1});
}
is(shift(@results), $_) foreach (DIRECTIVE_SIMPLE, DIRECTIVE_START, 'OK for today');
is(shift(@results), $_) foreach (DIRECTIVE_HEADLINE, DIRECTIVE_COMPLETE, 1);

is(shift(@results), $_) foreach (DIRECTIVE_TEXT, DIRECTIVE_START);
is(shift(@results), $_) foreach (DIRECTIVE_SIMPLE, DIRECTIVE_START, 'This might be sufficient');
is(shift(@results), $_) foreach (DIRECTIVE_SIMPLE, DIRECTIVE_START, '.');
is(shift(@results), $_) foreach (DIRECTIVE_TEXT, DIRECTIVE_COMPLETE);

is(shift(@results), $_) foreach (DIRECTIVE_DOCUMENT, DIRECTIVE_COMPLETE, 'backend-modes.pp');

# results should be checked completely now
is(scalar(@results), 0);

# - next turn ---

# next: walk manually and call move2chapter() from callbacks
# (ok, this is a crazy idea, but this is a test)
@jumpTable=(3, 2, 1, 3, 1);
$backend->bind(\@streamData);
{redo while $backend->next;}
$backend->unbind;

# run test suite again
testSuite();

# - next turn ---

# register a new set of backend handlers
$backend->register($_, \&counter) foreach (
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

# next: walk manually and call move2chapter() from *outside*
# a callback (as if a projector jumps through the slides)
@jumpTable=(3, 2, 1, 3, 1);
$backend->bind(\@streamData);
{
 my $previousCounter=$passedHeadlines;
 my $rc=$backend->next;
 $backend->move2chapter(shift(@jumpTable)) if $passedHeadlines>$previousCounter;
 redo if $rc;
}
$backend->unbind;

# run test suite again
testSuite();




# SUBROUTINES ###############################################################################

# handler: store what you found and perform chapter jumps as specified
sub jumper
 {
  # simply store what you received
  push(@results, @_);

  # if we completed a headline, jump to another chapter as specified
  $backend->move2chapter(shift(@jumpTable))
    if @jumpTable and $_[0]==DIRECTIVE_HEADLINE and $_[1]==DIRECTIVE_COMPLETE;
 }

# handler: store what you found and update a headline counter
sub counter
 {
  # simply store what you received
  push(@results, @_);

  # if we completed a headline, increase the counter
  $passedHeadlines++ if @jumpTable and $_[0]==DIRECTIVE_HEADLINE and $_[1]==DIRECTIVE_COMPLETE;
 }


sub testSuite
 {
  # check jumping from callbacks
  is(shift(@results), $_) foreach (DIRECTIVE_DOCUMENT, DIRECTIVE_START, 'backend-modes.pp');

  # headline 1 (initial)
  is(shift(@results), $_) foreach (DIRECTIVE_HEADLINE, DIRECTIVE_START, 1, 'A new chapter', '');
  {
   my $docstreams=shift(@results);
   is(ref($docstreams), 'ARRAY');
   is(join(' ', @$docstreams), '');
   checkHeadline(\@results, 1, ['A new chapter'], ['A new chapter'], [1], [1], {_STARTDIR=>cwd(), _PARSER_VERSION=>$PerlPoint::Parser::VERSION, _SOURCE_LEVEL=>1});
  }
  is(shift(@results), $_) foreach (DIRECTIVE_SIMPLE, DIRECTIVE_START, 'A new chapter');
  is(shift(@results), $_) foreach (DIRECTIVE_HEADLINE, DIRECTIVE_COMPLETE, 1);

  # headline 3
  is(shift(@results), $_) foreach (DIRECTIVE_HEADLINE, DIRECTIVE_START, 1, 'OK for today', '');
  {
   my $docstreams=shift(@results);
   is(ref($docstreams), 'ARRAY');
   is(join(' ', @$docstreams), '');
   checkHeadline(\@results, 1, ['OK for today'], ['OK for today'], [2], [3], {_STARTDIR=>cwd(), _PARSER_VERSION=>$PerlPoint::Parser::VERSION, _SOURCE_LEVEL=>1});
  }
  is(shift(@results), $_) foreach (DIRECTIVE_SIMPLE, DIRECTIVE_START, 'OK for today');
  is(shift(@results), $_) foreach (DIRECTIVE_HEADLINE, DIRECTIVE_COMPLETE, 1);

  # headline 2
  is(shift(@results), $_) foreach (DIRECTIVE_HEADLINE, DIRECTIVE_START, 2, 'And a subchapter', '');
  {
   my $docstreams=shift(@results);
   is(ref($docstreams), 'ARRAY');
   is(join(' ', @$docstreams), '');
   checkHeadline(\@results, 2, ['A new chapter', 'And a subchapter'], ['A new chapter', 'And a subchapter'], [1, 1], [1, 2], {_STARTDIR=>cwd(), _PARSER_VERSION=>$PerlPoint::Parser::VERSION, _SOURCE_LEVEL=>1});
  }
  is(shift(@results), $_) foreach (DIRECTIVE_SIMPLE, DIRECTIVE_START, 'And a subchapter');
  is(shift(@results), $_) foreach (DIRECTIVE_HEADLINE, DIRECTIVE_COMPLETE, 2);

  # headline 1
  is(shift(@results), $_) foreach (DIRECTIVE_HEADLINE, DIRECTIVE_START, 1, 'A new chapter', '');
  {
   my $docstreams=shift(@results);
   is(ref($docstreams), 'ARRAY');
   is(join(' ', @$docstreams), '');
   checkHeadline(\@results, 1, ['A new chapter'], ['A new chapter'], [1], [1], {_STARTDIR=>cwd(), _PARSER_VERSION=>$PerlPoint::Parser::VERSION, _SOURCE_LEVEL=>1});
  }
  is(shift(@results), $_) foreach (DIRECTIVE_SIMPLE, DIRECTIVE_START, 'A new chapter');
  is(shift(@results), $_) foreach (DIRECTIVE_HEADLINE, DIRECTIVE_COMPLETE, 1);

  # headline 3
  is(shift(@results), $_) foreach (DIRECTIVE_HEADLINE, DIRECTIVE_START, 1, 'OK for today', '');
  {
   my $docstreams=shift(@results);
   is(ref($docstreams), 'ARRAY');
   is(join(' ', @$docstreams), '');
   checkHeadline(\@results, 1, ['OK for today'], ['OK for today'], [2], [3], {_STARTDIR=>cwd(), _PARSER_VERSION=>$PerlPoint::Parser::VERSION, _SOURCE_LEVEL=>1});
  }
  is(shift(@results), $_) foreach (DIRECTIVE_SIMPLE, DIRECTIVE_START, 'OK for today');
  is(shift(@results), $_) foreach (DIRECTIVE_HEADLINE, DIRECTIVE_COMPLETE, 1);

  # headline 1
  is(shift(@results), $_) foreach (DIRECTIVE_HEADLINE, DIRECTIVE_START, 1, 'A new chapter', '');
  {
   my $docstreams=shift(@results);
   is(ref($docstreams), 'ARRAY');
   is(join(' ', @$docstreams), '');
   checkHeadline(\@results, 1, ['A new chapter'], ['A new chapter'], [1], [1], {_STARTDIR=>cwd(), _PARSER_VERSION=>$PerlPoint::Parser::VERSION, _SOURCE_LEVEL=>1});
  }
  is(shift(@results), $_) foreach (DIRECTIVE_SIMPLE, DIRECTIVE_START, 'A new chapter');
  is(shift(@results), $_) foreach (DIRECTIVE_HEADLINE, DIRECTIVE_COMPLETE, 1);

  # continue with all tokens as usual
  is(shift(@results), $_) foreach (DIRECTIVE_TEXT, DIRECTIVE_START);
  is(shift(@results), $_) foreach (DIRECTIVE_SIMPLE, DIRECTIVE_START, 'It comes with text');
  is(shift(@results), $_) foreach (DIRECTIVE_SIMPLE, DIRECTIVE_START, '.');
  is(shift(@results), $_) foreach (DIRECTIVE_TEXT, DIRECTIVE_COMPLETE);

  is(shift(@results), $_) foreach (DIRECTIVE_HEADLINE, DIRECTIVE_START, 2, 'And a subchapter', '');
  {
   my $docstreams=shift(@results);
   is(ref($docstreams), 'ARRAY');
   is(join(' ', @$docstreams), '');
   checkHeadline(\@results, 2, ['A new chapter', 'And a subchapter'], ['A new chapter', 'And a subchapter'], [1, 1], [1, 2], {_STARTDIR=>cwd(), _PARSER_VERSION=>$PerlPoint::Parser::VERSION, _SOURCE_LEVEL=>1});
  }
  is(shift(@results), $_) foreach (DIRECTIVE_SIMPLE, DIRECTIVE_START, 'And a subchapter');
  is(shift(@results), $_) foreach (DIRECTIVE_HEADLINE, DIRECTIVE_COMPLETE, 2);

  is(shift(@results), $_) foreach (DIRECTIVE_TEXT, DIRECTIVE_START);
  is(shift(@results), $_) foreach (DIRECTIVE_SIMPLE, DIRECTIVE_START, 'with more text');
  is(shift(@results), $_) foreach (DIRECTIVE_SIMPLE, DIRECTIVE_START, '.');
  is(shift(@results), $_) foreach (DIRECTIVE_TEXT, DIRECTIVE_COMPLETE);

  is(shift(@results), $_) foreach (DIRECTIVE_HEADLINE, DIRECTIVE_START, 1, 'OK for today', '');
  {
   my $docstreams=shift(@results);
   is(ref($docstreams), 'ARRAY');
   is(join(' ', @$docstreams), '');
   checkHeadline(\@results, 1, ['OK for today'], ['OK for today'], [2], [3], {_STARTDIR=>cwd(), _PARSER_VERSION=>$PerlPoint::Parser::VERSION, _SOURCE_LEVEL=>1});
  }
  is(shift(@results), $_) foreach (DIRECTIVE_SIMPLE, DIRECTIVE_START, 'OK for today');
  is(shift(@results), $_) foreach (DIRECTIVE_HEADLINE, DIRECTIVE_COMPLETE, 1);

  is(shift(@results), $_) foreach (DIRECTIVE_TEXT, DIRECTIVE_START);
  is(shift(@results), $_) foreach (DIRECTIVE_SIMPLE, DIRECTIVE_START, 'This might be sufficient');
  is(shift(@results), $_) foreach (DIRECTIVE_SIMPLE, DIRECTIVE_START, '.');
  is(shift(@results), $_) foreach (DIRECTIVE_TEXT, DIRECTIVE_COMPLETE);

  is(shift(@results), $_) foreach (DIRECTIVE_DOCUMENT, DIRECTIVE_COMPLETE, 'backend-modes.pp');

  # results should be checked completely now
  is(scalar(@results), 0);
 }
