

# = HISTORY SECTION =====================================================================

# ---------------------------------------------------------------------------------------
# version | date     | author   | changes
# ---------------------------------------------------------------------------------------
# 0.04    |10.10.2007| JSTENZEL | caller() needs to be declared as safe opcode if using
#         |          |          | strict under Safe with perl 5.9.5 and higher;
# 0.03    |19.04.2006| JSTENZEL | added tests for new standard filter API;
# 0.02    |27.12.2004| JSTENZEL | adapted to new headline path data;
#         |28.12.2004| JSTENZEL | adapted to dotted texts;
# 0.01    |04.01.2003| JSTENZEL | new.
# ---------------------------------------------------------------------------------------

# PerlPoint test script


# pragmata
use strict;

# load modules
use Cwd;
use Carp;
use Safe;
use PerlPoint::Backend;
use PerlPoint::Constants;
use PerlPoint::Parser 0.43;
use Test::More qw(no_plan);

# extend the lib path for the API filter search
use lib Cwd::abs_path('t');

# helper lib
use testlib;


# declare variables
my (@streamData, @results);

# build parser
my ($parser)=new PerlPoint::Parser;

# and call it for the first time: ifilter parameter in \INCLUDE, Safe object
$parser->run(
             stream  => \@streamData,
             files   => ['t/ifilters.pp'],
             safe    => new Safe,
             trace   => TRACE_NOTHING,
             display => DISPLAY_NOINFO+DISPLAY_NOWARN,
            );

# build a backend
my $backend=new PerlPoint::Backend(
                                   name    =>'installation test: ifilters',
                                   trace   =>TRACE_NOTHING,
                                   display => DISPLAY_NOINFO,
                                  );

# register a complete set of backend handlers
$backend->register($_, \&handler) foreach (DIRECTIVE_BLOCK .. DIRECTIVE_SIMPLE);

# now run the backend
$backend->run(\@streamData);

# run checks
performChecksFull();



# second test: ifilter parameter in \INCLUDE, eval() for active content
undef(@results);
undef(@streamData);

$parser->run(
             stream  => \@streamData,
             files   => ['t/ifilters.pp'],
             safe    => 'ALL',
             trace   => TRACE_NOTHING,
             display => DISPLAY_NOINFO+DISPLAY_NOWARN,
            );

# now run the backend
$backend->run(\@streamData);

# run checks
performChecksFull();



# perform the same procedure again, this time using the standard filter API, with a Safe object for active contents
undef(@results);
undef(@streamData);

# build a Safe object that is allowed to call require() and caller()
my $safe=new Safe;
$safe->permit(qw(caller require));    # caller() needs to be added for perl 5.9.5 and higher;

# and call it
$parser->run(
             stream  => \@streamData,
             files   => ['IMPORT:t/ifilters.lang'],
             safe    => $safe,             
             trace   => TRACE_NOTHING,
             display => DISPLAY_NOINFO+DISPLAY_NOWARN,
            );

# now run the backend
$backend->run(\@streamData);

# run checks
performChecksLang();



# perform the same procedure again, using the standard filter API, and eval() for active contents
undef(@results);
undef(@streamData);

# and call it
$parser->run(
             stream  => \@streamData,
             files   => ['IMPORT:t/ifilters.lang'],
             safe    => 'ALL',
             trace   => TRACE_NOTHING,
             display => DISPLAY_NOINFO+DISPLAY_NOWARN,
            );

# now run the backend
$backend->run(\@streamData);

# run checks
performChecksLang();




# SUBROUTINES ###############################################################################

# headline handler: store what you found
sub handler
 {
  # simply store what you received
  push(@results, @_);
 }


# perform checks for the full set (wrapping PP source with included LANG parts)
sub performChecksFull
 {
  is(shift(@results), $_) foreach (DIRECTIVE_DOCUMENT, DIRECTIVE_START, 'ifilters.pp');

  # variable hash
  my $varhash={_STARTDIR=>cwd(), _PARSER_VERSION=>$PerlPoint::Parser::VERSION, _SOURCE_LEVEL=>1};

  # a comment
  is(shift(@results), $_) foreach (DIRECTIVE_COMMENT, DIRECTIVE_START);
  shift(@results) until $results[0] eq DIRECTIVE_COMMENT or not @results;
  is(shift(@results), $_) foreach (DIRECTIVE_COMMENT, DIRECTIVE_COMPLETE);

  # a headline
  is(shift(@results), $_) foreach (DIRECTIVE_HEADLINE, DIRECTIVE_START, 1, 'A starting headline', '');
  {
   my $docstreams=shift(@results);
   is(ref($docstreams), 'ARRAY');
   is(join(' ', @$docstreams), '');
   checkHeadline(\@results, 1, ['A starting headline'], ['A starting headline'], [1], [1], $varhash);
  }
  is(shift(@results), $_) foreach (DIRECTIVE_SIMPLE, DIRECTIVE_START, 'A starting headline');
  is(shift(@results), $_) foreach (DIRECTIVE_HEADLINE, DIRECTIVE_COMPLETE, 1);

  # the intro
  is(shift(@results), $_) foreach (DIRECTIVE_TEXT, DIRECTIVE_START);
  is(shift(@results), $_) foreach (DIRECTIVE_SIMPLE, DIRECTIVE_START, 'Now the included file');
  is(shift(@results), $_) foreach (DIRECTIVE_SIMPLE, DIRECTIVE_START, ':');
  is(shift(@results), $_) foreach (DIRECTIVE_TEXT, DIRECTIVE_COMPLETE);

  # we embed a file: adapt variable hash
  $varhash->{_SOURCE_LEVEL}=2;

  # included headline
  is(shift(@results), $_) foreach (DIRECTIVE_HEADLINE, DIRECTIVE_START, 2, 'This should mark a headline of level 1', '');
  {
   my $docstreams=shift(@results);
   is(ref($docstreams), 'ARRAY');
   is(join(' ', @$docstreams), '');
   checkHeadline(\@results, 2, ['A starting headline', 'This should mark a headline of level 1'], ['A starting headline', 'This should mark a headline of level 1'], [1, 1], [1, 2], $varhash);
  }
  is(shift(@results), $_) foreach (DIRECTIVE_SIMPLE, DIRECTIVE_START, 'This should mark a headline of level 1');
  is(shift(@results), $_) foreach (DIRECTIVE_HEADLINE, DIRECTIVE_COMPLETE, 2);

  # included text
  is(shift(@results), $_) foreach (DIRECTIVE_TEXT, DIRECTIVE_START);
  is(shift(@results), $_) foreach (DIRECTIVE_SIMPLE, DIRECTIVE_START, 'This is a simple text');
  is(shift(@results), $_) foreach (DIRECTIVE_SIMPLE, DIRECTIVE_START, '.');
  is(shift(@results), $_) foreach (DIRECTIVE_TEXT, DIRECTIVE_COMPLETE);

  # included bullet list
  is(shift(@results), $_) foreach (DIRECTIVE_ULIST, DIRECTIVE_START, (0) x 5);

  is(shift(@results), $_) foreach (DIRECTIVE_UPOINT, DIRECTIVE_START);
  is(shift(@results), $_) foreach (DIRECTIVE_SIMPLE, DIRECTIVE_START, 'And a bullet point.');
  is(shift(@results), $_) foreach (DIRECTIVE_UPOINT, DIRECTIVE_COMPLETE);

  is(shift(@results), $_) foreach (DIRECTIVE_UPOINT, DIRECTIVE_START);
  is(shift(@results), $_) foreach (DIRECTIVE_SIMPLE, DIRECTIVE_START, 'Another bullet.');
  is(shift(@results), $_) foreach (DIRECTIVE_UPOINT, DIRECTIVE_COMPLETE);

  is(shift(@results), $_) foreach (DIRECTIVE_ULIST, DIRECTIVE_COMPLETE, (0) x 5);

  # included headline
  is(shift(@results), $_) foreach (DIRECTIVE_HEADLINE, DIRECTIVE_START, 3, 'A 2nd level headline', '');
  {
   my $docstreams=shift(@results);
   is(ref($docstreams), 'ARRAY');
   is(join(' ', @$docstreams), '');
   checkHeadline(\@results, 3, ['A starting headline', 'This should mark a headline of level 1', 'A 2nd level headline'], ['A starting headline', 'This should mark a headline of level 1', 'A 2nd level headline'], [1, 1, 1], [1, 2, 3], $varhash);
  }
  is(shift(@results), $_) foreach (DIRECTIVE_SIMPLE, DIRECTIVE_START, 'A 2nd level headline');
  is(shift(@results), $_) foreach (DIRECTIVE_HEADLINE, DIRECTIVE_COMPLETE, 3);

  # included text
  is(shift(@results), $_) foreach (DIRECTIVE_TEXT, DIRECTIVE_START);
  is(shift(@results), $_) foreach (DIRECTIVE_SIMPLE, DIRECTIVE_START, 'What a language!');
  is(shift(@results), $_) foreach (DIRECTIVE_TEXT, DIRECTIVE_COMPLETE);

  # text with embedded parts
  is(shift(@results), $_) foreach (DIRECTIVE_TEXT, DIRECTIVE_START);
  is(shift(@results), $_) foreach (DIRECTIVE_SIMPLE, DIRECTIVE_START, 'And now, we embed something in this language');
  is(shift(@results), $_) foreach (DIRECTIVE_SIMPLE, DIRECTIVE_START, '. ');
  is(shift(@results), $_) foreach (DIRECTIVE_SIMPLE, DIRECTIVE_START, 'Oops!');
  is(shift(@results), $_) foreach (DIRECTIVE_TEXT, DIRECTIVE_COMPLETE);

  is(shift(@results), $_) foreach (DIRECTIVE_TEXT, DIRECTIVE_START);
  is(shift(@results), $_) foreach (DIRECTIVE_SIMPLE, DIRECTIVE_START, 'Another lang(usage) source!');
  is(shift(@results), $_) foreach (DIRECTIVE_TEXT, DIRECTIVE_COMPLETE);

  # embedded bullet list
  is(shift(@results), $_) foreach (DIRECTIVE_ULIST, DIRECTIVE_START, (0) x 5);

  is(shift(@results), $_) foreach (DIRECTIVE_UPOINT, DIRECTIVE_START);
  is(shift(@results), $_) foreach (DIRECTIVE_SIMPLE, DIRECTIVE_START, 'lang is simple');
  is(shift(@results), $_) foreach (DIRECTIVE_UPOINT, DIRECTIVE_COMPLETE);

  is(shift(@results), $_) foreach (DIRECTIVE_UPOINT, DIRECTIVE_START);
  is(shift(@results), $_) foreach (DIRECTIVE_SIMPLE, DIRECTIVE_START, 'PerlPoint is simple and powerfull');
  is(shift(@results), $_) foreach (DIRECTIVE_UPOINT, DIRECTIVE_COMPLETE);

  is(shift(@results), $_) foreach (DIRECTIVE_ULIST, DIRECTIVE_COMPLETE, (0) x 5);

  # embedded: text
  is(shift(@results), $_) foreach (DIRECTIVE_TEXT, DIRECTIVE_START);
  is(shift(@results), $_) foreach (DIRECTIVE_SIMPLE, DIRECTIVE_START, 'OK!');
  is(shift(@results), $_) foreach (DIRECTIVE_TEXT, DIRECTIVE_COMPLETE);

  # base document: text
  is(shift(@results), $_) foreach (DIRECTIVE_TEXT, DIRECTIVE_START);
  is(shift(@results), $_) foreach (DIRECTIVE_SIMPLE, DIRECTIVE_START, 'Well');
  is(shift(@results), $_) foreach (DIRECTIVE_SIMPLE, DIRECTIVE_START, '.');
  is(shift(@results), $_) foreach (DIRECTIVE_TEXT, DIRECTIVE_COMPLETE);

  # ok!
  is(shift(@results), $_) foreach (DIRECTIVE_DOCUMENT, DIRECTIVE_COMPLETE, 'ifilters.pp');
 }




# perform checks for the LANG file only
sub performChecksLang
 {
  # document start
  is(shift(@results), $_) foreach (DIRECTIVE_DOCUMENT, DIRECTIVE_START);

  # the name of the temporary file is unknown here, shift it
  shift(@results);

  # variable hash
  my $varhash={_STARTDIR=>cwd(), _PARSER_VERSION=>$PerlPoint::Parser::VERSION, _SOURCE_LEVEL=>2};

  # included headline
  is(shift(@results), $_) foreach (DIRECTIVE_HEADLINE, DIRECTIVE_START, 1, 'This should mark a headline of level 1', '');
  {
   my $docstreams=shift(@results);
   is(ref($docstreams), 'ARRAY');
   is(join(' ', @$docstreams), '');
   checkHeadline(\@results, 1, ['This should mark a headline of level 1'], ['This should mark a headline of level 1'], [1, 1], [1], $varhash);
  }
  is(shift(@results), $_) foreach (DIRECTIVE_SIMPLE, DIRECTIVE_START, 'This should mark a headline of level 1');
  is(shift(@results), $_) foreach (DIRECTIVE_HEADLINE, DIRECTIVE_COMPLETE, 1);

  # included text
  is(shift(@results), $_) foreach (DIRECTIVE_TEXT, DIRECTIVE_START);
  is(shift(@results), $_) foreach (DIRECTIVE_SIMPLE, DIRECTIVE_START, 'This is a simple text');
  is(shift(@results), $_) foreach (DIRECTIVE_SIMPLE, DIRECTIVE_START, '.');
  is(shift(@results), $_) foreach (DIRECTIVE_TEXT, DIRECTIVE_COMPLETE);

  # included bullet list
  is(shift(@results), $_) foreach (DIRECTIVE_ULIST, DIRECTIVE_START, (0) x 5);

  is(shift(@results), $_) foreach (DIRECTIVE_UPOINT, DIRECTIVE_START);
  is(shift(@results), $_) foreach (DIRECTIVE_SIMPLE, DIRECTIVE_START, 'And a bullet point.');
  is(shift(@results), $_) foreach (DIRECTIVE_UPOINT, DIRECTIVE_COMPLETE);

  is(shift(@results), $_) foreach (DIRECTIVE_UPOINT, DIRECTIVE_START);
  is(shift(@results), $_) foreach (DIRECTIVE_SIMPLE, DIRECTIVE_START, 'Another bullet.');
  is(shift(@results), $_) foreach (DIRECTIVE_UPOINT, DIRECTIVE_COMPLETE);

  is(shift(@results), $_) foreach (DIRECTIVE_ULIST, DIRECTIVE_COMPLETE, (0) x 5);

  # included headline
  is(shift(@results), $_) foreach (DIRECTIVE_HEADLINE, DIRECTIVE_START, 2, 'A 2nd level headline', '');
  {
   my $docstreams=shift(@results);
   is(ref($docstreams), 'ARRAY');
   is(join(' ', @$docstreams), '');
   checkHeadline(\@results, 2, ['This should mark a headline of level 1', 'A 2nd level headline'], ['This should mark a headline of level 1', 'A 2nd level headline'], [1, 1], [1, 2], $varhash);
  }
  is(shift(@results), $_) foreach (DIRECTIVE_SIMPLE, DIRECTIVE_START, 'A 2nd level headline');
  is(shift(@results), $_) foreach (DIRECTIVE_HEADLINE, DIRECTIVE_COMPLETE, 2);

  # included text
  is(shift(@results), $_) foreach (DIRECTIVE_TEXT, DIRECTIVE_START);
  is(shift(@results), $_) foreach (DIRECTIVE_SIMPLE, DIRECTIVE_START, 'What a language!');
  is(shift(@results), $_) foreach (DIRECTIVE_TEXT, DIRECTIVE_COMPLETE);

  # ok! (do not check the source filename parameter, as it is temporary)
  is(shift(@results), $_) foreach (DIRECTIVE_DOCUMENT, DIRECTIVE_COMPLETE);
 }



