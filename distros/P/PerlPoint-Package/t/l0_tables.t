

# = HISTORY SECTION =====================================================================

# ---------------------------------------------------------------------------------------
# version | date     | author   | changes
# ---------------------------------------------------------------------------------------
# 0.09    |27.12.2004| JSTENZEL | tabl directives provide more hints now;
#         |01.11.2005| JSTENZEL | each document needs a headline now;
# 0.08    |16.08.2001| JSTENZEL | no need to build a Safe object;
#         |01.12.2001| JSTENZEL | adapted to TABLEs modified parameter passing
#         |          |          | (which was built in to support retranslations
#         |          |          | performed when a paragraph filter is assigned);
# 0.07    |20.03.2001| JSTENZEL | adapted to tag templates;
#         |          | JSTENZEL | adapted to new TABLE tag behaviour;
#         |          | JSTENZEL | added table normalization checks;
#         |23.05.2001| JSTENZEL | adapted to field trimming;
#         |24.05.2001| JSTENZEL | adapted to paragraph reformatting: text paragraphs
#         |          |          | containing only a table become just a table now;
#         |25.05.2001| JSTENZEL | added test of new inlined (streamed) tables;
#         |          | JSTENZEL | added test of unuasual \END_TABLE tag placement
#         |26.05.2001| JSTENZEL | adapeted to new table nesting information;
#         |01.06.2001| JSTENZEL | adapted to modified lexing algorithm which takes
#         |          |          | "words" as long as possible;
# 0.06    |09.12.2000| JSTENZEL | new namespace: "PP" => "PerlPoint";
# 0.05    |11.10.2000| JSTENZEL | adapted to improved table paragraphs;
# 0.04    |10.10.2000| JSTENZEL | added tests for new table paragraphs;
# 0.03    |09.10.2000| JSTENZEL | adapted to fixed table handling;
# 0.02    |05.10.2000| JSTENZEL | parser takes a Safe object now;
# 0.01    |27.05.2000| JSTENZEL | new.
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
use PerlPoint::Parser 0.34;
use Test::More qw(no_plan);

# helper lib
use testlib;

# declare variables
my (@streamData, @results);

# build parser
my ($parser)=new PerlPoint::Parser;

# and call it
$parser->run(
             stream       => \@streamData,
             files        => ['t/tables.pp'],
             nestedTables => 1,
             trace        => TRACE_NOTHING,
             display      => DISPLAY_NOINFO+DISPLAY_NOWARN,
            );

# build a backend
my $backend=new PerlPoint::Backend(
                                   name    => 'installation test: tables',
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
is(shift(@results), $_) foreach (DIRECTIVE_DOCUMENT, DIRECTIVE_START, 'tables.pp');

# variable hash
my $varhash={
             _STARTDIR       => cwd(),
             _PARSER_VERSION => $PerlPoint::Parser::VERSION,
             _SOURCE_LEVEL   => 1,
            };

is(shift(@results), $_) foreach (DIRECTIVE_HEADLINE, DIRECTIVE_START, 1, 'Tables', '');
{
 my $docstreams=shift(@results);
 is(ref($docstreams), 'ARRAY');
 is(join(' ', @$docstreams), '');
}

checkHeadline(\@results, 1, ['Tables'], ['Tables'], [1], [1], $varhash);

is(shift(@results), $_) foreach (DIRECTIVE_SIMPLE, DIRECTIVE_START, 'Tables');
is(shift(@results), $_) foreach (DIRECTIVE_HEADLINE, DIRECTIVE_COMPLETE, 1);

# first table (made by tag)
is(shift(@results), $_) foreach (DIRECTIVE_TAG, DIRECTIVE_START, 'TABLE');
 {
  my $pars=shift(@results);
  is(ref($pars), 'HASH');
  is(join(' ', sort keys %$pars), '__maxColumns__ __nestingLevel__ __titleColumns__ bg border rowseparator separator');
  is(join(' ', sort values %$pars), '1 2 3 3 \\\n blue |');
 }
is(shift(@results), $_) foreach (DIRECTIVE_TAG, DIRECTIVE_START, 'TABLE_ROW');
is(shift(@results), $_) foreach (DIRECTIVE_TAG, DIRECTIVE_START, 'TABLE_COL');
is(shift(@results), $_) foreach (DIRECTIVE_SIMPLE, DIRECTIVE_START, 'column 1');
is(shift(@results), $_) foreach (DIRECTIVE_TAG, DIRECTIVE_COMPLETE, 'TABLE_COL');

is(shift(@results), $_) foreach (DIRECTIVE_TAG, DIRECTIVE_START, 'TABLE_COL');
is(shift(@results), $_) foreach (DIRECTIVE_SIMPLE, DIRECTIVE_START, 'column 2');
is(shift(@results), $_) foreach (DIRECTIVE_TAG, DIRECTIVE_COMPLETE, 'TABLE_COL');

is(shift(@results), $_) foreach (DIRECTIVE_TAG, DIRECTIVE_START, 'TABLE_COL');
is(shift(@results), $_) foreach (DIRECTIVE_SIMPLE, DIRECTIVE_START, 'column 3');
is(shift(@results), $_) foreach (DIRECTIVE_TAG, DIRECTIVE_COMPLETE, 'TABLE_COL');

is(shift(@results), $_) foreach (DIRECTIVE_TAG, DIRECTIVE_COMPLETE, 'TABLE_ROW');
is(shift(@results), $_) foreach (DIRECTIVE_TAG, DIRECTIVE_START, 'TABLE_ROW');

is(shift(@results), $_) foreach (DIRECTIVE_TAG, DIRECTIVE_START, 'TABLE_COL');
is(shift(@results), $_) foreach (DIRECTIVE_SIMPLE, DIRECTIVE_START, 'xxxx');
is(shift(@results), $_) foreach (DIRECTIVE_TAG, DIRECTIVE_COMPLETE, 'TABLE_COL');

is(shift(@results), $_) foreach (DIRECTIVE_TAG, DIRECTIVE_START, 'TABLE_COL');
is(shift(@results), $_) foreach (DIRECTIVE_SIMPLE, DIRECTIVE_START, 'yyyy');
is(shift(@results), $_) foreach (DIRECTIVE_TAG, DIRECTIVE_COMPLETE, 'TABLE_COL');

is(shift(@results), $_) foreach (DIRECTIVE_TAG, DIRECTIVE_START, 'TABLE_COL');
is(shift(@results), $_) foreach (DIRECTIVE_SIMPLE, DIRECTIVE_START, 'zzzzz');
is(shift(@results), $_) foreach (DIRECTIVE_TAG, DIRECTIVE_COMPLETE, 'TABLE_COL');

is(shift(@results), $_) foreach (DIRECTIVE_TAG, DIRECTIVE_COMPLETE, 'TABLE_ROW');
is(shift(@results), $_) foreach (DIRECTIVE_TAG, DIRECTIVE_START, 'TABLE_ROW');

is(shift(@results), $_) foreach (DIRECTIVE_TAG, DIRECTIVE_START, 'TABLE_COL');
is(shift(@results), $_) foreach (DIRECTIVE_SIMPLE, DIRECTIVE_START, 'uuuu');
is(shift(@results), $_) foreach (DIRECTIVE_TAG, DIRECTIVE_COMPLETE, 'TABLE_COL');

is(shift(@results), $_) foreach (DIRECTIVE_TAG, DIRECTIVE_START, 'TABLE_COL');
is(shift(@results), $_) foreach (DIRECTIVE_SIMPLE, DIRECTIVE_START, 'vvvv');
is(shift(@results), $_) foreach (DIRECTIVE_TAG, DIRECTIVE_COMPLETE, 'TABLE_COL');

is(shift(@results), $_) foreach (DIRECTIVE_TAG, DIRECTIVE_START, 'TABLE_COL');
is(shift(@results), $_) foreach (DIRECTIVE_SIMPLE, DIRECTIVE_START, 'wwwww');
is(shift(@results), $_) foreach (DIRECTIVE_TAG, DIRECTIVE_COMPLETE, 'TABLE_COL');

is(shift(@results), $_) foreach (DIRECTIVE_TAG, DIRECTIVE_COMPLETE, 'TABLE_ROW');

is(shift(@results), $_) foreach (DIRECTIVE_TAG, DIRECTIVE_COMPLETE, 'TABLE');
 {
  my $pars=shift(@results);
  is(ref($pars), 'HASH');
  is(join(' ', sort keys %$pars), '__maxColumns__ __nestingLevel__ __titleColumns__ bg border rowseparator separator');
  is(join(' ', sort values %$pars), '1 2 3 3 \\\n blue |');
 }


# second table (paragraph)
is(shift(@results), $_) foreach (DIRECTIVE_TAG, DIRECTIVE_START, 'TABLE');
{my $pars=shift(@results);}

is(shift(@results), $_) foreach (DIRECTIVE_TAG, DIRECTIVE_START, 'TABLE_ROW');
  
is(shift(@results), $_) foreach (DIRECTIVE_TAG, DIRECTIVE_START, 'TABLE_HL');
is(shift(@results), $_) foreach (DIRECTIVE_SIMPLE, DIRECTIVE_START, 'column 1');
is(shift(@results), $_) foreach (DIRECTIVE_TAG, DIRECTIVE_COMPLETE, 'TABLE_HL');

is(shift(@results), $_) foreach (DIRECTIVE_TAG, DIRECTIVE_START, 'TABLE_HL');
is(shift(@results), $_) foreach (DIRECTIVE_SIMPLE, DIRECTIVE_START, 'column 2');
is(shift(@results), $_) foreach (DIRECTIVE_TAG, DIRECTIVE_COMPLETE, 'TABLE_HL');

is(shift(@results), $_) foreach (DIRECTIVE_TAG, DIRECTIVE_START, 'TABLE_HL');
is(shift(@results), $_) foreach (DIRECTIVE_SIMPLE, DIRECTIVE_START, 'column 3');
is(shift(@results), $_) foreach (DIRECTIVE_TAG, DIRECTIVE_COMPLETE, 'TABLE_HL');

is(shift(@results), $_) foreach (DIRECTIVE_TAG, DIRECTIVE_COMPLETE, 'TABLE_ROW');
is(shift(@results), $_) foreach (DIRECTIVE_TAG, DIRECTIVE_START, 'TABLE_ROW');

is(shift(@results), $_) foreach (DIRECTIVE_TAG, DIRECTIVE_START, 'TABLE_COL');
is(shift(@results), $_) foreach (DIRECTIVE_SIMPLE, DIRECTIVE_START, 'xxxx');
is(shift(@results), $_) foreach (DIRECTIVE_TAG, DIRECTIVE_COMPLETE, 'TABLE_COL');

is(shift(@results), $_) foreach (DIRECTIVE_TAG, DIRECTIVE_START, 'TABLE_COL');
is(shift(@results), $_) foreach (DIRECTIVE_SIMPLE, DIRECTIVE_START, 'yyyy');
is(shift(@results), $_) foreach (DIRECTIVE_TAG, DIRECTIVE_COMPLETE, 'TABLE_COL');

is(shift(@results), $_) foreach (DIRECTIVE_TAG, DIRECTIVE_START, 'TABLE_COL');
is(shift(@results), $_) foreach (DIRECTIVE_SIMPLE, DIRECTIVE_START, 'zzzzz');
is(shift(@results), $_) foreach (DIRECTIVE_TAG, DIRECTIVE_COMPLETE, 'TABLE_COL');

is(shift(@results), $_) foreach (DIRECTIVE_TAG, DIRECTIVE_COMPLETE, 'TABLE_ROW');
is(shift(@results), $_) foreach (DIRECTIVE_TAG, DIRECTIVE_START, 'TABLE_ROW');

is(shift(@results), $_) foreach (DIRECTIVE_TAG, DIRECTIVE_START, 'TABLE_COL');
is(shift(@results), $_) foreach (DIRECTIVE_SIMPLE, DIRECTIVE_START, 'uuuu');
is(shift(@results), $_) foreach (DIRECTIVE_TAG, DIRECTIVE_COMPLETE, 'TABLE_COL');

is(shift(@results), $_) foreach (DIRECTIVE_TAG, DIRECTIVE_START, 'TABLE_COL');
is(shift(@results), $_) foreach (DIRECTIVE_SIMPLE, DIRECTIVE_START, 'vvvv');
is(shift(@results), $_) foreach (DIRECTIVE_TAG, DIRECTIVE_COMPLETE, 'TABLE_COL');

is(shift(@results), $_) foreach (DIRECTIVE_TAG, DIRECTIVE_START, 'TABLE_COL');
is(shift(@results), $_) foreach (DIRECTIVE_SIMPLE, DIRECTIVE_START, 'wwwww');
is(shift(@results), $_) foreach (DIRECTIVE_TAG, DIRECTIVE_COMPLETE, 'TABLE_COL');

is(shift(@results), $_) foreach (DIRECTIVE_TAG, DIRECTIVE_COMPLETE, 'TABLE_ROW');

is(shift(@results), $_) foreach (DIRECTIVE_TAG, DIRECTIVE_COMPLETE, 'TABLE');
{my $pars=shift(@results);}

# first one column table (by tag)
is(shift(@results), $_) foreach (DIRECTIVE_TAG, DIRECTIVE_START, 'TABLE');
 {
  my $pars=shift(@results);
  is(ref($pars), 'HASH');
  is(join(' ', sort keys %$pars), '__maxColumns__ __nestingLevel__ __titleColumns__ bg border rowseparator separator');
  is(join(' ', sort values %$pars), '1 1 1 2 \\\n blue |');
 }

is(shift(@results), $_) foreach (DIRECTIVE_TAG, DIRECTIVE_START, 'TABLE_ROW');
is(shift(@results), $_) foreach (DIRECTIVE_TAG, DIRECTIVE_START, 'TABLE_COL');
is(shift(@results), $_) foreach (DIRECTIVE_SIMPLE, DIRECTIVE_START, 'column 1');
is(shift(@results), $_) foreach (DIRECTIVE_TAG, DIRECTIVE_COMPLETE, 'TABLE_COL');
is(shift(@results), $_) foreach (DIRECTIVE_TAG, DIRECTIVE_COMPLETE, 'TABLE_ROW');

is(shift(@results), $_) foreach (DIRECTIVE_TAG, DIRECTIVE_START, 'TABLE_ROW');
is(shift(@results), $_) foreach (DIRECTIVE_TAG, DIRECTIVE_START, 'TABLE_COL');
is(shift(@results), $_) foreach (DIRECTIVE_SIMPLE, DIRECTIVE_START, 'xxxx');
is(shift(@results), $_) foreach (DIRECTIVE_TAG, DIRECTIVE_COMPLETE, 'TABLE_COL');
is(shift(@results), $_) foreach (DIRECTIVE_TAG, DIRECTIVE_COMPLETE, 'TABLE_ROW');

is(shift(@results), $_) foreach (DIRECTIVE_TAG, DIRECTIVE_START, 'TABLE_ROW');
is(shift(@results), $_) foreach (DIRECTIVE_TAG, DIRECTIVE_START, 'TABLE_COL');
is(shift(@results), $_) foreach (DIRECTIVE_SIMPLE, DIRECTIVE_START, 'uuuu');
is(shift(@results), $_) foreach (DIRECTIVE_TAG, DIRECTIVE_COMPLETE, 'TABLE_COL');
is(shift(@results), $_) foreach (DIRECTIVE_TAG, DIRECTIVE_COMPLETE, 'TABLE_ROW');

is(shift(@results), $_) foreach (DIRECTIVE_TAG, DIRECTIVE_COMPLETE, 'TABLE');
 {
  my $pars=shift(@results);
  is(ref($pars), 'HASH');
  is(join(' ', sort keys %$pars), '__maxColumns__ __nestingLevel__ __titleColumns__ bg border rowseparator separator');
  is(join(' ', sort values %$pars), '1 1 1 2 \\\n blue |');
 }

# next table (by paragraph)
is(shift(@results), $_) foreach (DIRECTIVE_TAG, DIRECTIVE_START, 'TABLE');
{my $pars=shift(@results);}

is(shift(@results), $_) foreach (DIRECTIVE_TAG, DIRECTIVE_START, 'TABLE_ROW');
is(shift(@results), $_) foreach (DIRECTIVE_TAG, DIRECTIVE_START, 'TABLE_HL');
is(shift(@results), $_) foreach (DIRECTIVE_SIMPLE, DIRECTIVE_START, 'column 1');
is(shift(@results), $_) foreach (DIRECTIVE_TAG, DIRECTIVE_COMPLETE, 'TABLE_HL');
is(shift(@results), $_) foreach (DIRECTIVE_TAG, DIRECTIVE_COMPLETE, 'TABLE_ROW');

is(shift(@results), $_) foreach (DIRECTIVE_TAG, DIRECTIVE_START, 'TABLE_ROW');
is(shift(@results), $_) foreach (DIRECTIVE_TAG, DIRECTIVE_START, 'TABLE_COL');
is(shift(@results), $_) foreach (DIRECTIVE_SIMPLE, DIRECTIVE_START, 'xxxx');
is(shift(@results), $_) foreach (DIRECTIVE_TAG, DIRECTIVE_COMPLETE, 'TABLE_COL');
is(shift(@results), $_) foreach (DIRECTIVE_TAG, DIRECTIVE_COMPLETE, 'TABLE_ROW');

is(shift(@results), $_) foreach (DIRECTIVE_TAG, DIRECTIVE_START, 'TABLE_ROW');
is(shift(@results), $_) foreach (DIRECTIVE_TAG, DIRECTIVE_START, 'TABLE_COL');
is(shift(@results), $_) foreach (DIRECTIVE_SIMPLE, DIRECTIVE_START, 'uuuu');
is(shift(@results), $_) foreach (DIRECTIVE_TAG, DIRECTIVE_COMPLETE, 'TABLE_COL');
is(shift(@results), $_) foreach (DIRECTIVE_TAG, DIRECTIVE_COMPLETE, 'TABLE_ROW');

is(shift(@results), $_) foreach (DIRECTIVE_TAG, DIRECTIVE_COMPLETE, 'TABLE');
{my $pars=shift(@results);}

# first normalized table (made by tag)
is(shift(@results), $_) foreach (DIRECTIVE_TAG, DIRECTIVE_START, 'TABLE');
 {
  my $pars=shift(@results);
  is(ref($pars), 'HASH');
  is(join(' ', sort keys %$pars), '__maxColumns__ __nestingLevel__ __titleColumns__ bg border rowseparator separator');
  is(join(' ', sort values %$pars), '1 2 3 3 \\\n blue |');
 }

is(shift(@results), $_) foreach (DIRECTIVE_TAG, DIRECTIVE_START, 'TABLE_ROW');

is(shift(@results), $_) foreach (DIRECTIVE_TAG, DIRECTIVE_START, 'TABLE_COL');
is(shift(@results), $_) foreach (DIRECTIVE_SIMPLE, DIRECTIVE_START, 'column 1');
is(shift(@results), $_) foreach (DIRECTIVE_TAG, DIRECTIVE_COMPLETE, 'TABLE_COL');

is(shift(@results), $_) foreach (DIRECTIVE_TAG, DIRECTIVE_START, 'TABLE_COL');
is(shift(@results), $_) foreach (DIRECTIVE_SIMPLE, DIRECTIVE_START, 'column 2');
is(shift(@results), $_) foreach (DIRECTIVE_TAG, DIRECTIVE_COMPLETE, 'TABLE_COL');

is(shift(@results), $_) foreach (DIRECTIVE_TAG, DIRECTIVE_START, 'TABLE_COL');
is(shift(@results), $_) foreach (DIRECTIVE_SIMPLE, DIRECTIVE_START, 'column 3');
is(shift(@results), $_) foreach (DIRECTIVE_TAG, DIRECTIVE_COMPLETE, 'TABLE_COL');

is(shift(@results), $_) foreach (DIRECTIVE_TAG, DIRECTIVE_COMPLETE, 'TABLE_ROW');
is(shift(@results), $_) foreach (DIRECTIVE_TAG, DIRECTIVE_START, 'TABLE_ROW');

is(shift(@results), $_) foreach (DIRECTIVE_TAG, DIRECTIVE_START, 'TABLE_COL');
is(shift(@results), $_) foreach (DIRECTIVE_SIMPLE, DIRECTIVE_START, 'xxxx');
is(shift(@results), $_) foreach (DIRECTIVE_TAG, DIRECTIVE_COMPLETE, 'TABLE_COL');
is(shift(@results), $_) foreach (DIRECTIVE_TAG, DIRECTIVE_START, 'TABLE_COL');
is(shift(@results), $_) foreach (DIRECTIVE_TAG, DIRECTIVE_COMPLETE, 'TABLE_COL');
is(shift(@results), $_) foreach (DIRECTIVE_TAG, DIRECTIVE_START, 'TABLE_COL');
is(shift(@results), $_) foreach (DIRECTIVE_TAG, DIRECTIVE_COMPLETE, 'TABLE_COL');

is(shift(@results), $_) foreach (DIRECTIVE_TAG, DIRECTIVE_COMPLETE, 'TABLE_ROW');
is(shift(@results), $_) foreach (DIRECTIVE_TAG, DIRECTIVE_START, 'TABLE_ROW');

is(shift(@results), $_) foreach (DIRECTIVE_TAG, DIRECTIVE_START, 'TABLE_COL');
is(shift(@results), $_) foreach (DIRECTIVE_SIMPLE, DIRECTIVE_START, 'xxxx');
is(shift(@results), $_) foreach (DIRECTIVE_TAG, DIRECTIVE_COMPLETE, 'TABLE_COL');

is(shift(@results), $_) foreach (DIRECTIVE_TAG, DIRECTIVE_START, 'TABLE_COL');
is(shift(@results), $_) foreach (DIRECTIVE_TAG, DIRECTIVE_COMPLETE, 'TABLE_COL');

is(shift(@results), $_) foreach (DIRECTIVE_TAG, DIRECTIVE_START, 'TABLE_COL');
is(shift(@results), $_) foreach (DIRECTIVE_TAG, DIRECTIVE_COMPLETE, 'TABLE_COL');

is(shift(@results), $_) foreach (DIRECTIVE_TAG, DIRECTIVE_COMPLETE, 'TABLE_ROW');
is(shift(@results), $_) foreach (DIRECTIVE_TAG, DIRECTIVE_START, 'TABLE_ROW');

is(shift(@results), $_) foreach (DIRECTIVE_TAG, DIRECTIVE_START, 'TABLE_COL');
is(shift(@results), $_) foreach (DIRECTIVE_SIMPLE, DIRECTIVE_START, 'uuuu');
is(shift(@results), $_) foreach (DIRECTIVE_TAG, DIRECTIVE_COMPLETE, 'TABLE_COL');

is(shift(@results), $_) foreach (DIRECTIVE_TAG, DIRECTIVE_START, 'TABLE_COL');
is(shift(@results), $_) foreach (DIRECTIVE_SIMPLE, DIRECTIVE_START, 'vvvv');
is(shift(@results), $_) foreach (DIRECTIVE_TAG, DIRECTIVE_COMPLETE, 'TABLE_COL');

is(shift(@results), $_) foreach (DIRECTIVE_TAG, DIRECTIVE_START, 'TABLE_COL');
is(shift(@results), $_) foreach (DIRECTIVE_TAG, DIRECTIVE_COMPLETE, 'TABLE_COL');

is(shift(@results), $_) foreach (DIRECTIVE_TAG, DIRECTIVE_COMPLETE, 'TABLE_ROW');
is(shift(@results), $_) foreach (DIRECTIVE_TAG, DIRECTIVE_START, 'TABLE_ROW');

is(shift(@results), $_) foreach (DIRECTIVE_TAG, DIRECTIVE_START, 'TABLE_COL');
is(shift(@results), $_) foreach (DIRECTIVE_SIMPLE, DIRECTIVE_START, 'uuuu');
is(shift(@results), $_) foreach (DIRECTIVE_TAG, DIRECTIVE_COMPLETE, 'TABLE_COL');

is(shift(@results), $_) foreach (DIRECTIVE_TAG, DIRECTIVE_START, 'TABLE_COL');
is(shift(@results), $_) foreach (DIRECTIVE_SIMPLE, DIRECTIVE_START, 'vvvv');
is(shift(@results), $_) foreach (DIRECTIVE_TAG, DIRECTIVE_COMPLETE, 'TABLE_COL');

is(shift(@results), $_) foreach (DIRECTIVE_TAG, DIRECTIVE_START, 'TABLE_COL');
is(shift(@results), $_) foreach (DIRECTIVE_TAG, DIRECTIVE_COMPLETE, 'TABLE_COL');

is(shift(@results), $_) foreach (DIRECTIVE_TAG, DIRECTIVE_COMPLETE, 'TABLE_ROW');

is(shift(@results), $_) foreach (DIRECTIVE_TAG, DIRECTIVE_COMPLETE, 'TABLE');
 {
  my $pars=shift(@results);
  is(ref($pars), 'HASH');
  is(join(' ', sort keys %$pars), '__maxColumns__ __nestingLevel__ __titleColumns__ bg border rowseparator separator');
  is(join(' ', sort values %$pars), '1 2 3 3 \\\n blue |');
 }


# 2nd normalized table (declared by paragraph)
is(shift(@results), $_) foreach (DIRECTIVE_TAG, DIRECTIVE_START, 'TABLE');
{my $pars=shift(@results);}

is(shift(@results), $_) foreach (DIRECTIVE_TAG, DIRECTIVE_START, 'TABLE_ROW');

is(shift(@results), $_) foreach (DIRECTIVE_TAG, DIRECTIVE_START, 'TABLE_HL');
is(shift(@results), $_) foreach (DIRECTIVE_SIMPLE, DIRECTIVE_START, 'column 1');
is(shift(@results), $_) foreach (DIRECTIVE_TAG, DIRECTIVE_COMPLETE, 'TABLE_HL');

is(shift(@results), $_) foreach (DIRECTIVE_TAG, DIRECTIVE_START, 'TABLE_HL');
is(shift(@results), $_) foreach (DIRECTIVE_SIMPLE, DIRECTIVE_START, 'column 2');
is(shift(@results), $_) foreach (DIRECTIVE_TAG, DIRECTIVE_COMPLETE, 'TABLE_HL');

is(shift(@results), $_) foreach (DIRECTIVE_TAG, DIRECTIVE_START, 'TABLE_HL');
is(shift(@results), $_) foreach (DIRECTIVE_SIMPLE, DIRECTIVE_START, 'column 3');
is(shift(@results), $_) foreach (DIRECTIVE_TAG, DIRECTIVE_COMPLETE, 'TABLE_HL');

is(shift(@results), $_) foreach (DIRECTIVE_TAG, DIRECTIVE_COMPLETE, 'TABLE_ROW');
is(shift(@results), $_) foreach (DIRECTIVE_TAG, DIRECTIVE_START, 'TABLE_ROW');

is(shift(@results), $_) foreach (DIRECTIVE_TAG, DIRECTIVE_START, 'TABLE_COL');
is(shift(@results), $_) foreach (DIRECTIVE_SIMPLE, DIRECTIVE_START, 'xxxx');
is(shift(@results), $_) foreach (DIRECTIVE_TAG, DIRECTIVE_COMPLETE, 'TABLE_COL');
is(shift(@results), $_) foreach (DIRECTIVE_TAG, DIRECTIVE_START, 'TABLE_COL');
is(shift(@results), $_) foreach (DIRECTIVE_TAG, DIRECTIVE_COMPLETE, 'TABLE_COL');
is(shift(@results), $_) foreach (DIRECTIVE_TAG, DIRECTIVE_START, 'TABLE_COL');
is(shift(@results), $_) foreach (DIRECTIVE_TAG, DIRECTIVE_COMPLETE, 'TABLE_COL');

is(shift(@results), $_) foreach (DIRECTIVE_TAG, DIRECTIVE_COMPLETE, 'TABLE_ROW');
is(shift(@results), $_) foreach (DIRECTIVE_TAG, DIRECTIVE_START, 'TABLE_ROW');

is(shift(@results), $_) foreach (DIRECTIVE_TAG, DIRECTIVE_START, 'TABLE_COL');
is(shift(@results), $_) foreach (DIRECTIVE_SIMPLE, DIRECTIVE_START, 'xxxx');
is(shift(@results), $_) foreach (DIRECTIVE_TAG, DIRECTIVE_COMPLETE, 'TABLE_COL');

is(shift(@results), $_) foreach (DIRECTIVE_TAG, DIRECTIVE_START, 'TABLE_COL');
is(shift(@results), $_) foreach (DIRECTIVE_TAG, DIRECTIVE_COMPLETE, 'TABLE_COL');

is(shift(@results), $_) foreach (DIRECTIVE_TAG, DIRECTIVE_START, 'TABLE_COL');
is(shift(@results), $_) foreach (DIRECTIVE_TAG, DIRECTIVE_COMPLETE, 'TABLE_COL');

is(shift(@results), $_) foreach (DIRECTIVE_TAG, DIRECTIVE_COMPLETE, 'TABLE_ROW');
is(shift(@results), $_) foreach (DIRECTIVE_TAG, DIRECTIVE_START, 'TABLE_ROW');

is(shift(@results), $_) foreach (DIRECTIVE_TAG, DIRECTIVE_START, 'TABLE_COL');
is(shift(@results), $_) foreach (DIRECTIVE_SIMPLE, DIRECTIVE_START, 'uuuu');
is(shift(@results), $_) foreach (DIRECTIVE_TAG, DIRECTIVE_COMPLETE, 'TABLE_COL');

is(shift(@results), $_) foreach (DIRECTIVE_TAG, DIRECTIVE_START, 'TABLE_COL');
is(shift(@results), $_) foreach (DIRECTIVE_SIMPLE, DIRECTIVE_START, 'vvvv');
is(shift(@results), $_) foreach (DIRECTIVE_TAG, DIRECTIVE_COMPLETE, 'TABLE_COL');

is(shift(@results), $_) foreach (DIRECTIVE_TAG, DIRECTIVE_START, 'TABLE_COL');
is(shift(@results), $_) foreach (DIRECTIVE_TAG, DIRECTIVE_COMPLETE, 'TABLE_COL');

is(shift(@results), $_) foreach (DIRECTIVE_TAG, DIRECTIVE_COMPLETE, 'TABLE_ROW');
is(shift(@results), $_) foreach (DIRECTIVE_TAG, DIRECTIVE_START, 'TABLE_ROW');

is(shift(@results), $_) foreach (DIRECTIVE_TAG, DIRECTIVE_START, 'TABLE_COL');
is(shift(@results), $_) foreach (DIRECTIVE_SIMPLE, DIRECTIVE_START, 'uuuu');
is(shift(@results), $_) foreach (DIRECTIVE_TAG, DIRECTIVE_COMPLETE, 'TABLE_COL');

is(shift(@results), $_) foreach (DIRECTIVE_TAG, DIRECTIVE_START, 'TABLE_COL');
is(shift(@results), $_) foreach (DIRECTIVE_SIMPLE, DIRECTIVE_START, 'vvvv');
is(shift(@results), $_) foreach (DIRECTIVE_TAG, DIRECTIVE_COMPLETE, 'TABLE_COL');

is(shift(@results), $_) foreach (DIRECTIVE_TAG, DIRECTIVE_START, 'TABLE_COL');
is(shift(@results), $_) foreach (DIRECTIVE_TAG, DIRECTIVE_COMPLETE, 'TABLE_COL');

is(shift(@results), $_) foreach (DIRECTIVE_TAG, DIRECTIVE_COMPLETE, 'TABLE_ROW');

is(shift(@results), $_) foreach (DIRECTIVE_TAG, DIRECTIVE_COMPLETE, 'TABLE');
{my $pars=shift(@results);}

# table unusually completed
is(shift(@results), $_) foreach (DIRECTIVE_TAG, DIRECTIVE_START, 'TABLE');
 {
  my $pars=shift(@results);
  is(ref($pars), 'HASH');
  is(join(' ', sort keys %$pars), '__maxColumns__ __nestingLevel__ __titleColumns__ rowseparator separator');
  is(join(' ', sort values %$pars), '1 2 2 \\\n |');
 }
is(shift(@results), $_) foreach (DIRECTIVE_TAG, DIRECTIVE_START, 'TABLE_ROW');
is(shift(@results), $_) foreach (DIRECTIVE_TAG, DIRECTIVE_START, 'TABLE_COL');
is(shift(@results), $_) foreach (DIRECTIVE_SIMPLE, DIRECTIVE_START, 'column 1');
is(shift(@results), $_) foreach (DIRECTIVE_TAG, DIRECTIVE_COMPLETE, 'TABLE_COL');

is(shift(@results), $_) foreach (DIRECTIVE_TAG, DIRECTIVE_START, 'TABLE_COL');
is(shift(@results), $_) foreach (DIRECTIVE_SIMPLE, DIRECTIVE_START, 'column 2');
is(shift(@results), $_) foreach (DIRECTIVE_TAG, DIRECTIVE_COMPLETE, 'TABLE_COL');

is(shift(@results), $_) foreach (DIRECTIVE_TAG, DIRECTIVE_COMPLETE, 'TABLE_ROW');
is(shift(@results), $_) foreach (DIRECTIVE_TAG, DIRECTIVE_START, 'TABLE_ROW');

is(shift(@results), $_) foreach (DIRECTIVE_TAG, DIRECTIVE_START, 'TABLE_COL');
is(shift(@results), $_) foreach (DIRECTIVE_SIMPLE, DIRECTIVE_START, 'xxxx');
is(shift(@results), $_) foreach (DIRECTIVE_TAG, DIRECTIVE_COMPLETE, 'TABLE_COL');

is(shift(@results), $_) foreach (DIRECTIVE_TAG, DIRECTIVE_START, 'TABLE_COL');
is(shift(@results), $_) foreach (DIRECTIVE_SIMPLE, DIRECTIVE_START, 'yyyy');
is(shift(@results), $_) foreach (DIRECTIVE_TAG, DIRECTIVE_COMPLETE, 'TABLE_COL');

is(shift(@results), $_) foreach (DIRECTIVE_TAG, DIRECTIVE_COMPLETE, 'TABLE_ROW');

is(shift(@results), $_) foreach (DIRECTIVE_TAG, DIRECTIVE_COMPLETE, 'TABLE');
 {
  my $pars=shift(@results);
  is(ref($pars), 'HASH');
  is(join(' ', sort keys %$pars), '__maxColumns__ __nestingLevel__ __titleColumns__ rowseparator separator');
  is(join(' ', sort values %$pars), '1 2 2 \\\n |');
 }


# inlined table
is(shift(@results), $_) foreach (DIRECTIVE_TEXT, DIRECTIVE_START);
is(shift(@results), $_) foreach (DIRECTIVE_SIMPLE, DIRECTIVE_START, 'Inlined');
is(shift(@results), $_) foreach (DIRECTIVE_SIMPLE, DIRECTIVE_START, ': ');

is(shift(@results), $_) foreach (DIRECTIVE_TAG, DIRECTIVE_START, 'TABLE');
 {
  my $pars=shift(@results);
  is(ref($pars), 'HASH');
  is(join(' ', sort keys %$pars), '__maxColumns__ __nestingLevel__ __titleColumns__ bg border rowseparator separator');
  is(join(' ', sort values %$pars), '+++ 1 2 3 3 blue |');
 }
is(shift(@results), $_) foreach (DIRECTIVE_TAG, DIRECTIVE_START, 'TABLE_ROW');
is(shift(@results), $_) foreach (DIRECTIVE_TAG, DIRECTIVE_START, 'TABLE_COL');
is(shift(@results), $_) foreach (DIRECTIVE_SIMPLE, DIRECTIVE_START, 'column 1');
is(shift(@results), $_) foreach (DIRECTIVE_TAG, DIRECTIVE_COMPLETE, 'TABLE_COL');

is(shift(@results), $_) foreach (DIRECTIVE_TAG, DIRECTIVE_START, 'TABLE_COL');
is(shift(@results), $_) foreach (DIRECTIVE_SIMPLE, DIRECTIVE_START, 'column 2');
is(shift(@results), $_) foreach (DIRECTIVE_TAG, DIRECTIVE_COMPLETE, 'TABLE_COL');

is(shift(@results), $_) foreach (DIRECTIVE_TAG, DIRECTIVE_START, 'TABLE_COL');
is(shift(@results), $_) foreach (DIRECTIVE_SIMPLE, DIRECTIVE_START, 'column 3');
is(shift(@results), $_) foreach (DIRECTIVE_TAG, DIRECTIVE_COMPLETE, 'TABLE_COL');

is(shift(@results), $_) foreach (DIRECTIVE_TAG, DIRECTIVE_COMPLETE, 'TABLE_ROW');
is(shift(@results), $_) foreach (DIRECTIVE_TAG, DIRECTIVE_START, 'TABLE_ROW');

is(shift(@results), $_) foreach (DIRECTIVE_TAG, DIRECTIVE_START, 'TABLE_COL');
is(shift(@results), $_) foreach (DIRECTIVE_SIMPLE, DIRECTIVE_START, 'xxxx');
is(shift(@results), $_) foreach (DIRECTIVE_TAG, DIRECTIVE_COMPLETE, 'TABLE_COL');

is(shift(@results), $_) foreach (DIRECTIVE_TAG, DIRECTIVE_START, 'TABLE_COL');
is(shift(@results), $_) foreach (DIRECTIVE_SIMPLE, DIRECTIVE_START, 'yyyy');
is(shift(@results), $_) foreach (DIRECTIVE_TAG, DIRECTIVE_COMPLETE, 'TABLE_COL');

is(shift(@results), $_) foreach (DIRECTIVE_TAG, DIRECTIVE_START, 'TABLE_COL');
is(shift(@results), $_) foreach (DIRECTIVE_SIMPLE, DIRECTIVE_START, 'zzzzz');
is(shift(@results), $_) foreach (DIRECTIVE_TAG, DIRECTIVE_COMPLETE, 'TABLE_COL');

is(shift(@results), $_) foreach (DIRECTIVE_TAG, DIRECTIVE_COMPLETE, 'TABLE_ROW');
is(shift(@results), $_) foreach (DIRECTIVE_TAG, DIRECTIVE_START, 'TABLE_ROW');

is(shift(@results), $_) foreach (DIRECTIVE_TAG, DIRECTIVE_START, 'TABLE_COL');
is(shift(@results), $_) foreach (DIRECTIVE_SIMPLE, DIRECTIVE_START, 'uuuu');
is(shift(@results), $_) foreach (DIRECTIVE_TAG, DIRECTIVE_COMPLETE, 'TABLE_COL');

is(shift(@results), $_) foreach (DIRECTIVE_TAG, DIRECTIVE_START, 'TABLE_COL');
is(shift(@results), $_) foreach (DIRECTIVE_SIMPLE, DIRECTIVE_START, 'vvvv');
is(shift(@results), $_) foreach (DIRECTIVE_TAG, DIRECTIVE_COMPLETE, 'TABLE_COL');

is(shift(@results), $_) foreach (DIRECTIVE_TAG, DIRECTIVE_START, 'TABLE_COL');
is(shift(@results), $_) foreach (DIRECTIVE_SIMPLE, DIRECTIVE_START, 'wwwww');
is(shift(@results), $_) foreach (DIRECTIVE_TAG, DIRECTIVE_COMPLETE, 'TABLE_COL');

is(shift(@results), $_) foreach (DIRECTIVE_TAG, DIRECTIVE_COMPLETE, 'TABLE_ROW');

is(shift(@results), $_) foreach (DIRECTIVE_TAG, DIRECTIVE_COMPLETE, 'TABLE');
 {
  my $pars=shift(@results);
  is(ref($pars), 'HASH');
  is(join(' ', sort keys %$pars), '__maxColumns__ __nestingLevel__ __titleColumns__ bg border rowseparator separator');
  is(join(' ', sort values %$pars), '+++ 1 2 3 3 blue |');
 }

is(shift(@results), $_) foreach (DIRECTIVE_TEXT, DIRECTIVE_COMPLETE);


# 1st nested table
is(shift(@results), $_) foreach (DIRECTIVE_TEXT, DIRECTIVE_START);
is(shift(@results), $_) foreach (DIRECTIVE_SIMPLE, DIRECTIVE_START, 'Nested 1');
is(shift(@results), $_) foreach (DIRECTIVE_SIMPLE, DIRECTIVE_START, ': ');

is(shift(@results), $_) foreach (DIRECTIVE_TAG, DIRECTIVE_START, 'TABLE');
 {
  my $pars=shift(@results);
  is(ref($pars), 'HASH');
  is(join(' ', sort keys %$pars), '__maxColumns__ __nestingLevel__ __titleColumns__ rowseparator');
  is(join(' ', sort values %$pars), '+++ 1 3 3');
 }

is(shift(@results), $_) foreach (DIRECTIVE_TAG, DIRECTIVE_START, 'TABLE_ROW');

is(shift(@results), $_) foreach (DIRECTIVE_TAG, DIRECTIVE_START, 'TABLE_COL');
is(shift(@results), $_) foreach (DIRECTIVE_SIMPLE, DIRECTIVE_START, 'column 1');
is(shift(@results), $_) foreach (DIRECTIVE_TAG, DIRECTIVE_COMPLETE, 'TABLE_COL');

is(shift(@results), $_) foreach (DIRECTIVE_TAG, DIRECTIVE_START, 'TABLE_COL');
is(shift(@results), $_) foreach (DIRECTIVE_SIMPLE, DIRECTIVE_START, 'column 2');
is(shift(@results), $_) foreach (DIRECTIVE_TAG, DIRECTIVE_COMPLETE, 'TABLE_COL');

is(shift(@results), $_) foreach (DIRECTIVE_TAG, DIRECTIVE_START, 'TABLE_COL');

# --- nested table starts ---

is(shift(@results), $_) foreach (DIRECTIVE_TAG, DIRECTIVE_START, 'TABLE');
 {
  my $pars=shift(@results);
  is(ref($pars), 'HASH');
  is(join(' ', sort keys %$pars), '__maxColumns__ __nestingLevel__ __titleColumns__ rowseparator');
  is(join(' ', sort values %$pars), '%%% 2 2 2');
 }

is(shift(@results), $_) foreach (DIRECTIVE_TAG, DIRECTIVE_START, 'TABLE_ROW');

is(shift(@results), $_) foreach (DIRECTIVE_TAG, DIRECTIVE_START, 'TABLE_COL');
is(shift(@results), $_) foreach (DIRECTIVE_SIMPLE, DIRECTIVE_START, 'n1');
is(shift(@results), $_) foreach (DIRECTIVE_TAG, DIRECTIVE_COMPLETE, 'TABLE_COL');

is(shift(@results), $_) foreach (DIRECTIVE_TAG, DIRECTIVE_START, 'TABLE_COL');
is(shift(@results), $_) foreach (DIRECTIVE_SIMPLE, DIRECTIVE_START, 'n2');
is(shift(@results), $_) foreach (DIRECTIVE_TAG, DIRECTIVE_COMPLETE, 'TABLE_COL');

is(shift(@results), $_) foreach (DIRECTIVE_TAG, DIRECTIVE_COMPLETE, 'TABLE_ROW');
is(shift(@results), $_) foreach (DIRECTIVE_TAG, DIRECTIVE_START, 'TABLE_ROW');

is(shift(@results), $_) foreach (DIRECTIVE_TAG, DIRECTIVE_START, 'TABLE_COL');
is(shift(@results), $_) foreach (DIRECTIVE_SIMPLE, DIRECTIVE_START, 'n3');
is(shift(@results), $_) foreach (DIRECTIVE_TAG, DIRECTIVE_COMPLETE, 'TABLE_COL');

is(shift(@results), $_) foreach (DIRECTIVE_TAG, DIRECTIVE_START, 'TABLE_COL');
is(shift(@results), $_) foreach (DIRECTIVE_SIMPLE, DIRECTIVE_START, 'n4');
is(shift(@results), $_) foreach (DIRECTIVE_TAG, DIRECTIVE_COMPLETE, 'TABLE_COL');

is(shift(@results), $_) foreach (DIRECTIVE_TAG, DIRECTIVE_COMPLETE, 'TABLE_ROW');

is(shift(@results), $_) foreach (DIRECTIVE_TAG, DIRECTIVE_COMPLETE, 'TABLE');
 {
  my $pars=shift(@results);
  is(ref($pars), 'HASH');
  is(join(' ', sort keys %$pars), '__maxColumns__ __nestingLevel__ __titleColumns__ rowseparator');
  is(join(' ', sort values %$pars), '%%% 2 2 2');
 }

# --- nested table completed ---

is(shift(@results), $_) foreach (DIRECTIVE_TAG, DIRECTIVE_COMPLETE, 'TABLE_COL');

is(shift(@results), $_) foreach (DIRECTIVE_TAG, DIRECTIVE_COMPLETE, 'TABLE_ROW');
is(shift(@results), $_) foreach (DIRECTIVE_TAG, DIRECTIVE_START, 'TABLE_ROW');

is(shift(@results), $_) foreach (DIRECTIVE_TAG, DIRECTIVE_START, 'TABLE_COL');
is(shift(@results), $_) foreach (DIRECTIVE_SIMPLE, DIRECTIVE_START, 'xxxx');
is(shift(@results), $_) foreach (DIRECTIVE_TAG, DIRECTIVE_COMPLETE, 'TABLE_COL');

is(shift(@results), $_) foreach (DIRECTIVE_TAG, DIRECTIVE_START, 'TABLE_COL');
is(shift(@results), $_) foreach (DIRECTIVE_SIMPLE, DIRECTIVE_START, 'yyyy');
is(shift(@results), $_) foreach (DIRECTIVE_TAG, DIRECTIVE_COMPLETE, 'TABLE_COL');

is(shift(@results), $_) foreach (DIRECTIVE_TAG, DIRECTIVE_START, 'TABLE_COL');
is(shift(@results), $_) foreach (DIRECTIVE_SIMPLE, DIRECTIVE_START, 'zzzzz');
is(shift(@results), $_) foreach (DIRECTIVE_TAG, DIRECTIVE_COMPLETE, 'TABLE_COL');

is(shift(@results), $_) foreach (DIRECTIVE_TAG, DIRECTIVE_COMPLETE, 'TABLE_ROW');
is(shift(@results), $_) foreach (DIRECTIVE_TAG, DIRECTIVE_START, 'TABLE_ROW');

is(shift(@results), $_) foreach (DIRECTIVE_TAG, DIRECTIVE_START, 'TABLE_COL');
is(shift(@results), $_) foreach (DIRECTIVE_SIMPLE, DIRECTIVE_START, 'uuuu');
is(shift(@results), $_) foreach (DIRECTIVE_TAG, DIRECTIVE_COMPLETE, 'TABLE_COL');

is(shift(@results), $_) foreach (DIRECTIVE_TAG, DIRECTIVE_START, 'TABLE_COL');
is(shift(@results), $_) foreach (DIRECTIVE_SIMPLE, DIRECTIVE_START, 'vvvv');
is(shift(@results), $_) foreach (DIRECTIVE_TAG, DIRECTIVE_COMPLETE, 'TABLE_COL');

is(shift(@results), $_) foreach (DIRECTIVE_TAG, DIRECTIVE_START, 'TABLE_COL');
is(shift(@results), $_) foreach (DIRECTIVE_SIMPLE, DIRECTIVE_START, 'wwwww');
is(shift(@results), $_) foreach (DIRECTIVE_TAG, DIRECTIVE_COMPLETE, 'TABLE_COL');

is(shift(@results), $_) foreach (DIRECTIVE_TAG, DIRECTIVE_COMPLETE, 'TABLE_ROW');

is(shift(@results), $_) foreach (DIRECTIVE_TAG, DIRECTIVE_COMPLETE, 'TABLE');
 {
  my $pars=shift(@results);
  is(ref($pars), 'HASH');
  is(join(' ', sort keys %$pars), '__maxColumns__ __nestingLevel__ __titleColumns__ rowseparator');
  is(join(' ', sort values %$pars), '+++ 1 3 3');
 }

is(shift(@results), $_) foreach (DIRECTIVE_TEXT, DIRECTIVE_COMPLETE);

# 2nd nested table (tag table inside a paragraph table)
is(shift(@results), $_) foreach (DIRECTIVE_TAG, DIRECTIVE_START, 'TABLE');
 {
  my $pars=shift(@results);
  is(ref($pars), 'HASH');
  is(join(' ', sort keys %$pars), '__maxColumns__ __nestingLevel__ __paragraph__ __titleColumns__ separator');
  is(join(' ', sort values %$pars), '1 1 3 3 |');
 }

is(shift(@results), $_) foreach (DIRECTIVE_TAG, DIRECTIVE_START, 'TABLE_ROW');

is(shift(@results), $_) foreach (DIRECTIVE_TAG, DIRECTIVE_START, 'TABLE_HL');
is(shift(@results), $_) foreach (DIRECTIVE_SIMPLE, DIRECTIVE_START, 'column 1');
is(shift(@results), $_) foreach (DIRECTIVE_TAG, DIRECTIVE_COMPLETE, 'TABLE_HL');

is(shift(@results), $_) foreach (DIRECTIVE_TAG, DIRECTIVE_START, 'TABLE_HL');
is(shift(@results), $_) foreach (DIRECTIVE_SIMPLE, DIRECTIVE_START, 'column 2');
is(shift(@results), $_) foreach (DIRECTIVE_TAG, DIRECTIVE_COMPLETE, 'TABLE_HL');

is(shift(@results), $_) foreach (DIRECTIVE_TAG, DIRECTIVE_START, 'TABLE_HL');

# --- nested table starts ---

is(shift(@results), $_) foreach (DIRECTIVE_TAG, DIRECTIVE_START, 'TABLE');
 {
  my $pars=shift(@results);
  is(ref($pars), 'HASH');
  is(join(' ', sort keys %$pars), '__maxColumns__ __nestingLevel__ __titleColumns__ rowseparator');
  is(join(' ', sort values %$pars), '%%% 2 2 2');
 }

is(shift(@results), $_) foreach (DIRECTIVE_TAG, DIRECTIVE_START, 'TABLE_ROW');

is(shift(@results), $_) foreach (DIRECTIVE_TAG, DIRECTIVE_START, 'TABLE_COL');
is(shift(@results), $_) foreach (DIRECTIVE_SIMPLE, DIRECTIVE_START, 'n1');
is(shift(@results), $_) foreach (DIRECTIVE_TAG, DIRECTIVE_COMPLETE, 'TABLE_COL');

is(shift(@results), $_) foreach (DIRECTIVE_TAG, DIRECTIVE_START, 'TABLE_COL');
is(shift(@results), $_) foreach (DIRECTIVE_SIMPLE, DIRECTIVE_START, 'n2');
is(shift(@results), $_) foreach (DIRECTIVE_TAG, DIRECTIVE_COMPLETE, 'TABLE_COL');

is(shift(@results), $_) foreach (DIRECTIVE_TAG, DIRECTIVE_COMPLETE, 'TABLE_ROW');
is(shift(@results), $_) foreach (DIRECTIVE_TAG, DIRECTIVE_START, 'TABLE_ROW');

is(shift(@results), $_) foreach (DIRECTIVE_TAG, DIRECTIVE_START, 'TABLE_COL');
is(shift(@results), $_) foreach (DIRECTIVE_SIMPLE, DIRECTIVE_START, 'n3');
is(shift(@results), $_) foreach (DIRECTIVE_TAG, DIRECTIVE_COMPLETE, 'TABLE_COL');

is(shift(@results), $_) foreach (DIRECTIVE_TAG, DIRECTIVE_START, 'TABLE_COL');
is(shift(@results), $_) foreach (DIRECTIVE_SIMPLE, DIRECTIVE_START, 'n4');
is(shift(@results), $_) foreach (DIRECTIVE_TAG, DIRECTIVE_COMPLETE, 'TABLE_COL');

is(shift(@results), $_) foreach (DIRECTIVE_TAG, DIRECTIVE_COMPLETE, 'TABLE_ROW');

is(shift(@results), $_) foreach (DIRECTIVE_TAG, DIRECTIVE_COMPLETE, 'TABLE');
 {
  my $pars=shift(@results);
  is(ref($pars), 'HASH');
  is(join(' ', sort keys %$pars), '__maxColumns__ __nestingLevel__ __titleColumns__ rowseparator');
  is(join(' ', sort values %$pars), '%%% 2 2 2');
 }

# --- nested table completed ---

is(shift(@results), $_) foreach (DIRECTIVE_TAG, DIRECTIVE_COMPLETE, 'TABLE_HL');

is(shift(@results), $_) foreach (DIRECTIVE_TAG, DIRECTIVE_COMPLETE, 'TABLE_ROW');
is(shift(@results), $_) foreach (DIRECTIVE_TAG, DIRECTIVE_START, 'TABLE_ROW');

is(shift(@results), $_) foreach (DIRECTIVE_TAG, DIRECTIVE_START, 'TABLE_COL');
is(shift(@results), $_) foreach (DIRECTIVE_SIMPLE, DIRECTIVE_START, 'xxxx');
is(shift(@results), $_) foreach (DIRECTIVE_TAG, DIRECTIVE_COMPLETE, 'TABLE_COL');

is(shift(@results), $_) foreach (DIRECTIVE_TAG, DIRECTIVE_START, 'TABLE_COL');
is(shift(@results), $_) foreach (DIRECTIVE_SIMPLE, DIRECTIVE_START, 'yyyy');
is(shift(@results), $_) foreach (DIRECTIVE_TAG, DIRECTIVE_COMPLETE, 'TABLE_COL');

is(shift(@results), $_) foreach (DIRECTIVE_TAG, DIRECTIVE_START, 'TABLE_COL');
is(shift(@results), $_) foreach (DIRECTIVE_SIMPLE, DIRECTIVE_START, 'zzzzz');
is(shift(@results), $_) foreach (DIRECTIVE_TAG, DIRECTIVE_COMPLETE, 'TABLE_COL');

is(shift(@results), $_) foreach (DIRECTIVE_TAG, DIRECTIVE_COMPLETE, 'TABLE_ROW');
is(shift(@results), $_) foreach (DIRECTIVE_TAG, DIRECTIVE_START, 'TABLE_ROW');

is(shift(@results), $_) foreach (DIRECTIVE_TAG, DIRECTIVE_START, 'TABLE_COL');
is(shift(@results), $_) foreach (DIRECTIVE_SIMPLE, DIRECTIVE_START, 'uuuu');
is(shift(@results), $_) foreach (DIRECTIVE_TAG, DIRECTIVE_COMPLETE, 'TABLE_COL');

is(shift(@results), $_) foreach (DIRECTIVE_TAG, DIRECTIVE_START, 'TABLE_COL');
is(shift(@results), $_) foreach (DIRECTIVE_SIMPLE, DIRECTIVE_START, 'vvvv');
is(shift(@results), $_) foreach (DIRECTIVE_TAG, DIRECTIVE_COMPLETE, 'TABLE_COL');

is(shift(@results), $_) foreach (DIRECTIVE_TAG, DIRECTIVE_START, 'TABLE_COL');
is(shift(@results), $_) foreach (DIRECTIVE_SIMPLE, DIRECTIVE_START, 'wwwww');
is(shift(@results), $_) foreach (DIRECTIVE_TAG, DIRECTIVE_COMPLETE, 'TABLE_COL');

is(shift(@results), $_) foreach (DIRECTIVE_TAG, DIRECTIVE_COMPLETE, 'TABLE_ROW');

is(shift(@results), $_) foreach (DIRECTIVE_TAG, DIRECTIVE_COMPLETE, 'TABLE');
 {
  my $pars=shift(@results);
  is(ref($pars), 'HASH');
  is(join(' ', sort keys %$pars), '__maxColumns__ __nestingLevel__ __paragraph__ __titleColumns__ separator');
  is(join(' ', sort values %$pars), '1 1 3 3 |');
 }

is(shift(@results), $_) foreach (DIRECTIVE_DOCUMENT, DIRECTIVE_COMPLETE, 'tables.pp');

# everything tested?
is(scalar(@results), 0);

# SUBROUTINES ###############################################################################

# headline handler: store what you found
sub handler
 {
  # simply store what you received
  push(@results, @_);
 }
