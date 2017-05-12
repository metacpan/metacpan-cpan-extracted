

# = HISTORY SECTION =====================================================================

# ---------------------------------------------------------------------------------------
# version | date     | author   | changes
# ---------------------------------------------------------------------------------------
# 0.09    |26.12.2004| JSTENZEL | adapted to new headline path data and table hints;
#         |28.12.2004| JSTENZEL | adapted to dotted texts;
#         |27.02.2005| JSTENZEL | adapted to fixed variable handling, see parser log;
#         |01.11.2005| JSTENZEL | each document needs a headline now;
# 0.08    |20.08.2002| JSTENZEL | adapted to extended tag streaming (body hint);
# 0.07    |< 14.04.02| JSTENZEL | blocks got rid of a trailing newline;
#         |          | JSTENZEL | added paragraph filter tests using new do() strategy;
#         |          | JSTENZEL | adapted to headline shortcuts;
#         |          | JSTENZEL | added document stream tests;
#         |15.04.2002| JSTENZEL | adapted to chapter docstream hints;
# 0.06    |18.08.2001| JSTENZEL | switched from Test to Test::More;
#         |13.10.2001| JSTENZEL | adapted to headline title providing;
#         |27.11.2001| JSTENZEL | adapted to additional shift hints in list directives;
#         |01.12.2001| JSTENZEL | adapted to TABLEs modified parameter passing
#         |          |          | (which was built in to support retranslations
#         |          |          | performed when a paragraph filter is assigned);
# 0.05    |22.07.2001| JSTENZEL | adapted to perl 5.005;
#         |          | JSTENZEL | adapted to improved lexer;
# 0.04    |20.03.2001| JSTENZEL | adapted to tag templates;
#         |23.03.2001| JSTENZEL | adapted to by line lexing of verbatim blocks;
#         |23.05.2001| JSTENZEL | adapted to field trimming;
#         |24.05.2001| JSTENZEL | adapted to paragraph reformatting: text paragraphs
#         |          |          | containing only a table become just a table now;
#         |25.05.2001| JSTENZEL | adapted to paragraph reformatting: text paragraphs
#         |          |          | no longer contain a final whitespace string;
#         |26.05.2001| JSTENZEL | adapted to new table nesting information;
#         |01.06.2001| JSTENZEL | adapted to modified lexing algorithm which takes
#         |          |          | "words" as long as possible;
# 0.03    |30.01.2001| JSTENZEL | ordered lists now provide the entry level number;
# 0.02    |09.12.2000| JSTENZEL | new namespace: "PP" => "PerlPoint";
# 0.01    |16.11.2000| JSTENZEL | new.
# ---------------------------------------------------------------------------------------

# PerlPoint test script


# pragmata
use strict;
use lib qw(t);
use vars qw(@results);

# load modules
use Cwd;
use Carp;
use Safe;
use PerlPoint::Backend;
use Test::More qw(no_plan);
use PerlPoint::Parser 0.40;
use PerlPoint::Constants 0.16;

# helper lib
use testlib;

# declare test tags
use PerlPoint::Tags;
use PerlPoint::Tags::_tags;

# declare variables
my (@streamData);

# build parser
my ($parser)=new PerlPoint::Parser;

# and call it
$parser->run(
             stream          => \@streamData,
             files           => ['t/cache.pp'],
             safe            => new Safe,
             docstreams2skip => ['The ignored docstream'],
             docstreaming    => DSTREAM_DEFAULT,
	     cache           => CACHE_ON+CACHE_CLEANUP,
             trace           => TRACE_NOTHING,
             display         => DISPLAY_NOINFO,
            );

# build a backend
my $backend=new PerlPoint::Backend(
                                   name    => 'installation test: cache init',
                                   trace   => TRACE_NOTHING,
                                   display => DISPLAY_NOINFO,
                                  );

# register a complete set of backend handlers
$backend->register($_, \&handler) foreach (DIRECTIVE_BLOCK .. DIRECTIVE_SIMPLE);

# now run the backend
$backend->run(\@streamData);

# perform checks: start
is(shift(@results), $_) foreach (DIRECTIVE_DOCUMENT, DIRECTIVE_START, 'cache.pp');

# variable hash
my $varhash={
             _STARTDIR       => cwd(),
             _PARSER_VERSION => $PerlPoint::Parser::VERSION,
             _SOURCE_LEVEL   => 1,
            };

is(shift(@results), $_) foreach (DIRECTIVE_HEADLINE, DIRECTIVE_START, 1, 'Cache', '');
{
 my $docstreams=shift(@results);
 is(ref($docstreams), 'ARRAY');
 is(join(' ', @$docstreams), '');
}

checkHeadline(\@results, 1, ['Cache'], ['Cache'], [1], [1], $varhash);

is(shift(@results), $_) foreach (DIRECTIVE_SIMPLE, DIRECTIVE_START, 'Cache');
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
is(shift(@results), $_) foreach (DIRECTIVE_SIMPLE, DIRECTIVE_START, 'Spalte 1');
is(shift(@results), $_) foreach (DIRECTIVE_TAG, DIRECTIVE_COMPLETE, 'TABLE_COL');

is(shift(@results), $_) foreach (DIRECTIVE_TAG, DIRECTIVE_START, 'TABLE_COL');
is(shift(@results), $_) foreach (DIRECTIVE_SIMPLE, DIRECTIVE_START, 'Spalte 2');
is(shift(@results), $_) foreach (DIRECTIVE_TAG, DIRECTIVE_COMPLETE, 'TABLE_COL');

is(shift(@results), $_) foreach (DIRECTIVE_TAG, DIRECTIVE_START, 'TABLE_COL');
is(shift(@results), $_) foreach (DIRECTIVE_SIMPLE, DIRECTIVE_START, 'Spalte 3');
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
is(shift(@results), $_) foreach (DIRECTIVE_SIMPLE, DIRECTIVE_START, 'Spalte 1');
is(shift(@results), $_) foreach (DIRECTIVE_TAG, DIRECTIVE_COMPLETE, 'TABLE_HL');

is(shift(@results), $_) foreach (DIRECTIVE_TAG, DIRECTIVE_START, 'TABLE_HL');
is(shift(@results), $_) foreach (DIRECTIVE_SIMPLE, DIRECTIVE_START, 'Spalte 2');
is(shift(@results), $_) foreach (DIRECTIVE_TAG, DIRECTIVE_COMPLETE, 'TABLE_HL');

is(shift(@results), $_) foreach (DIRECTIVE_TAG, DIRECTIVE_START, 'TABLE_HL');
is(shift(@results), $_) foreach (DIRECTIVE_SIMPLE, DIRECTIVE_START, 'Spalte 3');
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

# perform checks: tags
is(shift(@results), $_) foreach (DIRECTIVE_TEXT, DIRECTIVE_START);
is(shift(@results), $_) foreach (DIRECTIVE_SIMPLE, DIRECTIVE_START, 'Simple');
is(shift(@results), $_) foreach (DIRECTIVE_SIMPLE, DIRECTIVE_START, ': ');
is(shift(@results), $_) foreach (DIRECTIVE_TAG, DIRECTIVE_START, 'TEST');
{
 my $pars=shift(@results);
 is(ref($pars), 'HASH');
 is(join(' ', sort keys %$pars), '');
}
is(shift(@results), $_) foreach (0, DIRECTIVE_TAG, DIRECTIVE_COMPLETE, 'TEST');
{
 my $pars=shift(@results);
 is(ref($pars), 'HASH');
 is(join(' ', sort keys %$pars), '');
}
is(shift(@results), 0);
is(shift(@results), $_) foreach (DIRECTIVE_SIMPLE, DIRECTIVE_START, '.');
is(shift(@results), $_) foreach (DIRECTIVE_SIMPLE, DIRECTIVE_START, ' ');
is(shift(@results), $_) foreach (DIRECTIVE_SIMPLE, DIRECTIVE_START, 'Guarded: ');
is(shift(@results), $_) foreach (DIRECTIVE_SIMPLE, DIRECTIVE_START, '\\');
is(shift(@results), $_) foreach (DIRECTIVE_SIMPLE, DIRECTIVE_START, 'TEST.');
is(shift(@results), $_) foreach (DIRECTIVE_SIMPLE, DIRECTIVE_START, ' ');
is(shift(@results), $_) foreach (DIRECTIVE_SIMPLE, DIRECTIVE_START, 'Sequence: ');
is(shift(@results), $_) foreach (DIRECTIVE_TAG, DIRECTIVE_START, 'TEST');
{
 my $pars=shift(@results);
 is(ref($pars), 'HASH');
 is(join(' ', sort keys %$pars), '');
}
is(shift(@results), $_) foreach (0, DIRECTIVE_TAG, DIRECTIVE_COMPLETE, 'TEST');
{
 my $pars=shift(@results);
 is(ref($pars), 'HASH');
 is(join(' ', sort keys %$pars), '');
}
is(shift(@results), 0);
is(shift(@results), $_) foreach (DIRECTIVE_TAG, DIRECTIVE_START, 'TOAST');
{
 my $pars=shift(@results);
 is(ref($pars), 'HASH');
 is(join(' ', sort keys %$pars), '');
}
is(shift(@results), $_) foreach (0, DIRECTIVE_TAG, DIRECTIVE_COMPLETE, 'TOAST');
{
 my $pars=shift(@results);
 is(ref($pars), 'HASH');
 is(join(' ', sort keys %$pars), '');
}
is(shift(@results), 0);
is(shift(@results), $_) foreach (DIRECTIVE_SIMPLE, DIRECTIVE_START, '.');
is(shift(@results), $_) foreach (DIRECTIVE_TEXT, DIRECTIVE_COMPLETE);
is(shift(@results), $_) foreach (DIRECTIVE_TEXT, DIRECTIVE_START);
is(shift(@results), $_) foreach (DIRECTIVE_SIMPLE, DIRECTIVE_START, 'With body');
is(shift(@results), $_) foreach (DIRECTIVE_SIMPLE, DIRECTIVE_START, ': ');
is(shift(@results), $_) foreach (DIRECTIVE_TAG, DIRECTIVE_START, 'TOAST');
{
 my $pars=shift(@results);
 is(ref($pars), 'HASH');
 is(join(' ', sort keys %$pars), '');
}
is(shift(@results), 1);
is(shift(@results), $_) foreach (DIRECTIVE_SIMPLE, DIRECTIVE_START, 'toast');
is(shift(@results), $_) foreach (DIRECTIVE_TAG, DIRECTIVE_COMPLETE, 'TOAST');
{
 my $pars=shift(@results);
 is(ref($pars), 'HASH');
 is(join(' ', sort keys %$pars), '');
}
is(shift(@results), 1);
is(shift(@results), $_) foreach (DIRECTIVE_SIMPLE, DIRECTIVE_START, '.');
is(shift(@results), $_) foreach (DIRECTIVE_SIMPLE, DIRECTIVE_START, ' ');
is(shift(@results), $_) foreach (DIRECTIVE_SIMPLE, DIRECTIVE_START, 'Sequence: ');
is(shift(@results), $_) foreach (DIRECTIVE_TAG, DIRECTIVE_START, 'TEST');
{
 my $pars=shift(@results);
 is(ref($pars), 'HASH');
 is(join(' ', sort keys %$pars), '');
}
is(shift(@results), 1);
is(shift(@results), $_) foreach (DIRECTIVE_SIMPLE, DIRECTIVE_START, 'test');
is(shift(@results), $_) foreach (DIRECTIVE_TAG, DIRECTIVE_COMPLETE, 'TEST');
{
 my $pars=shift(@results);
 is(ref($pars), 'HASH');
 is(join(' ', sort keys %$pars), '');
}
is(shift(@results), 1);
is(shift(@results), $_) foreach (DIRECTIVE_TAG, DIRECTIVE_START, 'TOAST');
{
 my $pars=shift(@results);
 is(ref($pars), 'HASH');
 is(join(' ', sort keys %$pars), '');
}
is(shift(@results), 1);
is(shift(@results), $_) foreach (DIRECTIVE_SIMPLE, DIRECTIVE_START, 'toast');
is(shift(@results), $_) foreach (DIRECTIVE_TAG, DIRECTIVE_COMPLETE, 'TOAST');
{
 my $pars=shift(@results);
 is(ref($pars), 'HASH');
 is(join(' ', sort keys %$pars), '');
}
is(shift(@results), 1);
is(shift(@results), $_) foreach (DIRECTIVE_SIMPLE, DIRECTIVE_START, '.');
is(shift(@results), $_) foreach (DIRECTIVE_SIMPLE, DIRECTIVE_START, ' ');
is(shift(@results), $_) foreach (DIRECTIVE_SIMPLE, DIRECTIVE_START, 'Nested: ');
is(shift(@results), $_) foreach (DIRECTIVE_TAG, DIRECTIVE_START, 'TEST');
{
 my $pars=shift(@results);
 is(ref($pars), 'HASH');
 is(join(' ', sort keys %$pars), '');
}
is(shift(@results), 4);
is(shift(@results), $_) foreach (DIRECTIVE_SIMPLE, DIRECTIVE_START, 'tested ');
is(shift(@results), $_) foreach (DIRECTIVE_TAG, DIRECTIVE_START, 'TOAST');
{
 my $pars=shift(@results);
 is(ref($pars), 'HASH');
 is(join(' ', sort keys %$pars), '');
}
is(shift(@results), 1);
is(shift(@results), $_) foreach (DIRECTIVE_SIMPLE, DIRECTIVE_START, 'toast');
is(shift(@results), $_) foreach (DIRECTIVE_TAG, DIRECTIVE_COMPLETE, 'TOAST');
{
 my $pars=shift(@results);
 is(ref($pars), 'HASH');
 is(join(' ', sort keys %$pars), '');
}
is(shift(@results), 1);
is(shift(@results), $_) foreach (DIRECTIVE_TAG, DIRECTIVE_COMPLETE, 'TEST');
{
 my $pars=shift(@results);
 is(ref($pars), 'HASH');
 is(join(' ', sort keys %$pars), '');
}
is(shift(@results), 4);
is(shift(@results), $_) foreach (DIRECTIVE_SIMPLE, DIRECTIVE_START, '.');
is(shift(@results), $_) foreach (DIRECTIVE_TEXT, DIRECTIVE_COMPLETE);
is(shift(@results), $_) foreach (DIRECTIVE_TEXT, DIRECTIVE_START);
is(shift(@results), $_) foreach (DIRECTIVE_SIMPLE, DIRECTIVE_START, 'With parameters');
is(shift(@results), $_) foreach (DIRECTIVE_SIMPLE, DIRECTIVE_START, ': ');
is(shift(@results), $_) foreach (DIRECTIVE_TAG, DIRECTIVE_START, 'TEST');
{
 my $pars=shift(@results);
 is(ref($pars), 'HASH');
 is(join(' ', sort keys %$pars), 'par1 par2');
 is($pars->{par1}, 'p1');
 is($pars->{par2}, 'p2');
}
is(shift(@results), 0);
is(shift(@results), $_) foreach (DIRECTIVE_TAG, DIRECTIVE_COMPLETE, 'TEST');
{
 my $pars=shift(@results);
 is(ref($pars), 'HASH');
 is(join(' ', sort keys %$pars), 'par1 par2');
 is($pars->{par1}, 'p1');
 is($pars->{par2}, 'p2');
}
is(shift(@results), 0);
is(shift(@results), $_) foreach (DIRECTIVE_SIMPLE, DIRECTIVE_START, ' ');
is(shift(@results), $_) foreach (DIRECTIVE_SIMPLE, DIRECTIVE_START, 'Sequence: ');
is(shift(@results), $_) foreach (DIRECTIVE_TAG, DIRECTIVE_START, 'TEST');
{
 my $pars=shift(@results);
 is(ref($pars), 'HASH');
 is(join(' ', sort keys %$pars), 't');
 is($pars->{t}, 'test');
}
is(shift(@results), 0);
is(shift(@results), $_) foreach (DIRECTIVE_TAG, DIRECTIVE_COMPLETE, 'TEST');
{
 my $pars=shift(@results);
 is(ref($pars), 'HASH');
 is(join(' ', sort keys %$pars), 't');
 is($pars->{t}, 'test');
}
is(shift(@results), 0);
is(shift(@results), $_) foreach (DIRECTIVE_TAG, DIRECTIVE_START, 'TOAST');
{
 my $pars=shift(@results);
 is(ref($pars), 'HASH');
 is(join(' ', sort keys %$pars), 't');
 is($pars->{t}, 'toast');
}
is(shift(@results), 0);
is(shift(@results), $_) foreach (DIRECTIVE_TAG, DIRECTIVE_COMPLETE, 'TOAST');
{
 my $pars=shift(@results);
 is(ref($pars), 'HASH');
 is(join(' ', sort keys %$pars), 't');
 is($pars->{t}, 'toast');
}
is(shift(@results), 0);
is(shift(@results), $_) foreach (DIRECTIVE_SIMPLE, DIRECTIVE_START, '.');
is(shift(@results), $_) foreach (DIRECTIVE_TEXT, DIRECTIVE_COMPLETE);
is(shift(@results), $_) foreach (DIRECTIVE_TEXT, DIRECTIVE_START);
is(shift(@results), $_) foreach (DIRECTIVE_SIMPLE, DIRECTIVE_START, 'Complete');
is(shift(@results), $_) foreach (DIRECTIVE_SIMPLE, DIRECTIVE_START, ': ');
is(shift(@results), $_) foreach (DIRECTIVE_TAG, DIRECTIVE_START, 'TEST');
{
 my $pars=shift(@results);
 is(ref($pars), 'HASH');
 is(join(' ', sort keys %$pars), 't');
 is($pars->{t}, 'test');
}
is(shift(@results), 1);
is(shift(@results), $_) foreach (DIRECTIVE_SIMPLE, DIRECTIVE_START, 'test');
is(shift(@results), $_) foreach (DIRECTIVE_TAG, DIRECTIVE_COMPLETE, 'TEST');
{
 my $pars=shift(@results);
 is(ref($pars), 'HASH');
 is(join(' ', sort keys %$pars), 't');
 is($pars->{t}, 'test');
}
is(shift(@results), 1);
is(shift(@results), $_) foreach (DIRECTIVE_SIMPLE, DIRECTIVE_START, ' ');
is(shift(@results), $_) foreach (DIRECTIVE_SIMPLE, DIRECTIVE_START, 'Sequence: ');
is(shift(@results), $_) foreach (DIRECTIVE_TAG, DIRECTIVE_START, 'TEST');
{
 my $pars=shift(@results);
 is(ref($pars), 'HASH');
 is(join(' ', sort keys %$pars), 't');
 is($pars->{t}, 'test');
}
is(shift(@results), 1);
is(shift(@results), $_) foreach (DIRECTIVE_SIMPLE, DIRECTIVE_START, 'test');
is(shift(@results), $_) foreach (DIRECTIVE_TAG, DIRECTIVE_COMPLETE, 'TEST');
{
 my $pars=shift(@results);
 is(ref($pars), 'HASH');
 is(join(' ', sort keys %$pars), 't');
 is($pars->{t}, 'test');
}
is(shift(@results), 1);
is(shift(@results), $_) foreach (DIRECTIVE_TAG, DIRECTIVE_START, 'TOAST');
{
 my $pars=shift(@results);
 is(ref($pars), 'HASH');
 is(join(' ', sort keys %$pars), 't');
 is($pars->{t}, 'toast');
}
is(shift(@results), 1);
is(shift(@results), $_) foreach (DIRECTIVE_SIMPLE, DIRECTIVE_START, 'toast');
is(shift(@results), $_) foreach (DIRECTIVE_TAG, DIRECTIVE_COMPLETE, 'TOAST');
{
 my $pars=shift(@results);
 is(ref($pars), 'HASH');
 is(join(' ', sort keys %$pars), 't');
 is($pars->{t}, 'toast');
}
is(shift(@results), 1);
is(shift(@results), $_) foreach (DIRECTIVE_SIMPLE, DIRECTIVE_START, '.');
is(shift(@results), $_) foreach (DIRECTIVE_SIMPLE, DIRECTIVE_START, ' ');
is(shift(@results), $_) foreach (DIRECTIVE_SIMPLE, DIRECTIVE_START, 'Nested: ');
is(shift(@results), $_) foreach (DIRECTIVE_TAG, DIRECTIVE_START, 'TEST');
{
 my $pars=shift(@results);
 is(ref($pars), 'HASH');
 is(join(' ', sort keys %$pars), 't');
 is($pars->{t}, 'test');
}
is(shift(@results), 4);
is(shift(@results), $_) foreach (DIRECTIVE_SIMPLE, DIRECTIVE_START, 'tested ');
is(shift(@results), $_) foreach (DIRECTIVE_TAG, DIRECTIVE_START, 'TOAST');
{
 my $pars=shift(@results);
 is(ref($pars), 'HASH');
 is(join(' ', sort keys %$pars), 't');
 is($pars->{t}, 'toast');
}
is(shift(@results), 1);
is(shift(@results), $_) foreach (DIRECTIVE_SIMPLE, DIRECTIVE_START, 'toast');
is(shift(@results), $_) foreach (DIRECTIVE_TAG, DIRECTIVE_COMPLETE, 'TOAST');
{
 my $pars=shift(@results);
 is(ref($pars), 'HASH');
 is(join(' ', sort keys %$pars), 't');
 is($pars->{t}, 'toast');
}
is(shift(@results), 1);
is(shift(@results), $_) foreach (DIRECTIVE_TAG, DIRECTIVE_COMPLETE, 'TEST');
{
 my $pars=shift(@results);
 is(ref($pars), 'HASH');
 is(join(' ', sort keys %$pars), 't');
 is($pars->{t}, 'test');
}
is(shift(@results), 4);
is(shift(@results), $_) foreach (DIRECTIVE_SIMPLE, DIRECTIVE_START, '.');
is(shift(@results), $_) foreach (DIRECTIVE_TEXT, DIRECTIVE_COMPLETE);
is(shift(@results), $_) foreach (DIRECTIVE_HEADLINE, DIRECTIVE_START, 1, 'Tag in a headline', '');
{
 my $docstreams=shift(@results);
 is(ref($docstreams), 'ARRAY');
 is(join(' ', @$docstreams), '');
 checkHeadline(\@results, 1, ['Tag in a headline'], ['Tag in a headline'], [2], [2], $varhash);
}
is(shift(@results), $_) foreach (DIRECTIVE_SIMPLE, DIRECTIVE_START, 'Tag in a ');
is(shift(@results), $_) foreach (DIRECTIVE_TAG, DIRECTIVE_START, 'TEST');
{
 my $pars=shift(@results);
 is(ref($pars), 'HASH');
 is(join(' ', sort keys %$pars), '');
}
is(shift(@results), 1);
is(shift(@results), $_) foreach (DIRECTIVE_SIMPLE, DIRECTIVE_START, 'headline');
is(shift(@results), $_) foreach (DIRECTIVE_TAG, DIRECTIVE_COMPLETE, 'TEST');
{
 my $pars=shift(@results);
 is(ref($pars), 'HASH');
 is(join(' ', sort keys %$pars), '');
}
is(shift(@results), 1);
is(shift(@results), $_) foreach (DIRECTIVE_HEADLINE, DIRECTIVE_COMPLETE, 1);
is(shift(@results), $_) foreach (DIRECTIVE_ULIST, DIRECTIVE_START, (0) x 5);
is(shift(@results), $_) foreach (DIRECTIVE_UPOINT, DIRECTIVE_START);
is(shift(@results), $_) foreach (DIRECTIVE_TAG, DIRECTIVE_START, 'TEST');
{
 my $pars=shift(@results);
 is(ref($pars), 'HASH');
 is(join(' ', sort keys %$pars), '');
}
is(shift(@results), 1);
is(shift(@results), $_) foreach (DIRECTIVE_SIMPLE, DIRECTIVE_START, 'Tags');
is(shift(@results), $_) foreach (DIRECTIVE_TAG, DIRECTIVE_COMPLETE, 'TEST');
{
 my $pars=shift(@results);
 is(ref($pars), 'HASH');
 is(join(' ', sort keys %$pars), '');
}
is(shift(@results), 1);
is(shift(@results), $_) foreach (DIRECTIVE_UPOINT, DIRECTIVE_COMPLETE);
is(shift(@results), $_) foreach (DIRECTIVE_ULIST, DIRECTIVE_COMPLETE, (0) x 5);
is(shift(@results), $_) foreach (DIRECTIVE_OLIST, DIRECTIVE_START, 1, (0) x 4);
is(shift(@results), $_) foreach (DIRECTIVE_OPOINT, DIRECTIVE_START);
is(shift(@results), $_) foreach (DIRECTIVE_TAG, DIRECTIVE_START, 'TOAST');
{
 my $pars=shift(@results);
 is(ref($pars), 'HASH');
 is(join(' ', sort keys %$pars), '');
}
is(shift(@results), 1);
is(shift(@results), $_) foreach (DIRECTIVE_SIMPLE, DIRECTIVE_START, 'in');
is(shift(@results), $_) foreach (DIRECTIVE_TAG, DIRECTIVE_COMPLETE, 'TOAST');
{
 my $pars=shift(@results);
 is(ref($pars), 'HASH');
 is(join(' ', sort keys %$pars), '');
}
is(shift(@results), 1);
is(shift(@results), $_) foreach (DIRECTIVE_OPOINT, DIRECTIVE_COMPLETE);
is(shift(@results), $_) foreach (DIRECTIVE_OLIST, DIRECTIVE_COMPLETE, 1, (0) x 4);
is(shift(@results), $_) foreach (DIRECTIVE_DLIST, DIRECTIVE_START, (0) x 5);
is(shift(@results), $_) foreach (DIRECTIVE_DPOINT, DIRECTIVE_START);
is(shift(@results), $_) foreach (DIRECTIVE_DPOINT_ITEM, DIRECTIVE_START);
is(shift(@results), $_) foreach (DIRECTIVE_TAG, DIRECTIVE_START, 'FONT');
{
 my $pars=shift(@results);
 is(ref($pars), 'HASH');
 is(join(' ', sort keys %$pars), 'color');
 is($pars->{color}, 'blue')
}
is(shift(@results), 1);
is(shift(@results), $_) foreach (DIRECTIVE_SIMPLE, DIRECTIVE_START, 'item');
is(shift(@results), $_) foreach (DIRECTIVE_TAG, DIRECTIVE_COMPLETE, 'FONT');
{
 my $pars=shift(@results);
 is(ref($pars), 'HASH');
 is(join(' ', sort keys %$pars), 'color');
 is($pars->{color}, 'blue')
}
is(shift(@results), 1);
is(shift(@results), $_) foreach (DIRECTIVE_DPOINT_ITEM, DIRECTIVE_COMPLETE);
is(shift(@results), $_) foreach (DIRECTIVE_DPOINT_TEXT, DIRECTIVE_START);
is(shift(@results), $_) foreach (DIRECTIVE_SIMPLE, DIRECTIVE_START, 'list ');
is(shift(@results), $_) foreach (DIRECTIVE_TAG, DIRECTIVE_START, 'TEST');
{
 my $pars=shift(@results);
 is(ref($pars), 'HASH');
 is(join(' ', sort keys %$pars), '');
}
is(shift(@results), 5);
is(shift(@results), $_) foreach (DIRECTIVE_SIMPLE, DIRECTIVE_START, 'po');
is(shift(@results), $_) foreach (DIRECTIVE_TAG, DIRECTIVE_START, 'TOAST');
{
 my $pars=shift(@results);
 is(ref($pars), 'HASH');
 is(join(' ', sort keys %$pars), '');
}
is(shift(@results), 1);
is(shift(@results), $_) foreach (DIRECTIVE_SIMPLE, DIRECTIVE_START, 'i');
is(shift(@results), $_) foreach (DIRECTIVE_TAG, DIRECTIVE_COMPLETE, 'TOAST');
{
 my $pars=shift(@results);
 is(ref($pars), 'HASH');
 is(join(' ', sort keys %$pars), '');
}
is(shift(@results), 1);
is(shift(@results), $_) foreach (DIRECTIVE_SIMPLE, DIRECTIVE_START, 'nts');
is(shift(@results), $_) foreach (DIRECTIVE_TAG, DIRECTIVE_COMPLETE, 'TEST');
{
 my $pars=shift(@results);
 is(ref($pars), 'HASH');
 is(join(' ', sort keys %$pars), '');
}
is(shift(@results), 5);
is(shift(@results), $_) foreach (DIRECTIVE_SIMPLE, DIRECTIVE_START, '.');
is(shift(@results), $_) foreach (DIRECTIVE_DPOINT_TEXT, DIRECTIVE_COMPLETE);
is(shift(@results), $_) foreach (DIRECTIVE_DPOINT, DIRECTIVE_COMPLETE);
is(shift(@results), $_) foreach (DIRECTIVE_DLIST, DIRECTIVE_COMPLETE, (0) x 5);
is(shift(@results), $_) foreach (DIRECTIVE_BLOCK, DIRECTIVE_START);
is(shift(@results), $_) foreach (DIRECTIVE_SIMPLE, DIRECTIVE_START, '   ');
is(shift(@results), $_) foreach (DIRECTIVE_SIMPLE, DIRECTIVE_START, 'And in');
is(shift(@results), $_) foreach (DIRECTIVE_SIMPLE, DIRECTIVE_START, "\n");
is(shift(@results), $_) foreach (DIRECTIVE_SIMPLE, DIRECTIVE_START, '   ');
is(shift(@results), $_) foreach (DIRECTIVE_SIMPLE, DIRECTIVE_START, 'a ');
is(shift(@results), $_) foreach (DIRECTIVE_TAG, DIRECTIVE_START, 'TEST');
{
 my $pars=shift(@results);
 is(ref($pars), 'HASH');
 is(join(' ', sort keys %$pars), '');
}
is(shift(@results), 1);
is(shift(@results), $_) foreach (DIRECTIVE_SIMPLE, DIRECTIVE_START, 'block');
is(shift(@results), $_) foreach (DIRECTIVE_TAG, DIRECTIVE_COMPLETE, 'TEST');
{
 my $pars=shift(@results);
 is(ref($pars), 'HASH');
 is(join(' ', sort keys %$pars), '');
}
is(shift(@results), 1);
is(shift(@results), $_) foreach (DIRECTIVE_SIMPLE, DIRECTIVE_START, '.');
is(shift(@results), $_) foreach (DIRECTIVE_BLOCK, DIRECTIVE_COMPLETE);
is(shift(@results), $_) foreach (DIRECTIVE_VERBATIM, DIRECTIVE_START);
is(shift(@results), $_) foreach (DIRECTIVE_SIMPLE, DIRECTIVE_START, "\n");
is(shift(@results), $_) foreach (DIRECTIVE_SIMPLE, DIRECTIVE_START, "  Tags are currently \\TEST<not>\n");
is(shift(@results), $_) foreach (DIRECTIVE_SIMPLE, DIRECTIVE_START, "  processed in \\TOAST<Verbatim blocks>.\n");
is(shift(@results), $_) foreach (DIRECTIVE_SIMPLE, DIRECTIVE_START, "\n");
is(shift(@results), $_) foreach (DIRECTIVE_VERBATIM, DIRECTIVE_COMPLETE);

is(shift(@results), $_) foreach (DIRECTIVE_TEXT, DIRECTIVE_START);
is(shift(@results), $_) foreach (DIRECTIVE_SIMPLE, DIRECTIVE_START, 'String parameter');
is(shift(@results), $_) foreach (DIRECTIVE_SIMPLE, DIRECTIVE_START, ': ');
is(shift(@results), $_) foreach (DIRECTIVE_TAG, DIRECTIVE_START, 'TEST');
{
 my $pars=shift(@results);
 is(ref($pars), 'HASH');
 is(join(' ', sort keys %$pars), 'addr t');
 is($pars->{addr}, 'http://www.perl.com');
 is($pars->{t}, 'test');
}
is(shift(@results), 1);
is(shift(@results), $_) foreach (DIRECTIVE_SIMPLE, DIRECTIVE_START, 'test');
is(shift(@results), $_) foreach (DIRECTIVE_TAG, DIRECTIVE_COMPLETE, 'TEST');
{
 my $pars=shift(@results);
 is(ref($pars), 'HASH');
 is(join(' ', sort keys %$pars), 'addr t');
 is($pars->{addr}, 'http://www.perl.com');
 is($pars->{t}, 'test');
}
is(shift(@results), 1);
is(shift(@results), $_) foreach (DIRECTIVE_TEXT, DIRECTIVE_COMPLETE);

# perform checks: text
shift(@results) until $results[0] eq DIRECTIVE_TEXT or not @results;

# these checks are straight forward
foreach (1..4)
 {
  is(shift(@results), $_) foreach (DIRECTIVE_TEXT, DIRECTIVE_START);
  shift(@results) until $results[0] eq DIRECTIVE_TEXT or not @results;
  is(shift(@results), $_) foreach (DIRECTIVE_TEXT, DIRECTIVE_COMPLETE);
 }

# perform checks: variables
is(shift(@results), $_) foreach (DIRECTIVE_TEXT, DIRECTIVE_START);
is(shift(@results), $_) foreach (DIRECTIVE_SIMPLE, DIRECTIVE_START, '$');
is(shift(@results), $_) foreach (DIRECTIVE_SIMPLE, DIRECTIVE_START, '{noAssignment}=no assignment');
is(shift(@results), $_) foreach (DIRECTIVE_TEXT, DIRECTIVE_COMPLETE);
is(shift(@results), $_) foreach (DIRECTIVE_TEXT, DIRECTIVE_START);

is(shift(@results), $_) foreach (DIRECTIVE_SIMPLE, DIRECTIVE_START, 'Text');
is(shift(@results), $_) foreach (DIRECTIVE_SIMPLE, DIRECTIVE_START, ': ');
is(shift(@results), $_) foreach (DIRECTIVE_SIMPLE, DIRECTIVE_START, 'word');
is(shift(@results), $_) foreach (DIRECTIVE_SIMPLE, DIRECTIVE_START, '.');
is(shift(@results), $_) foreach (DIRECTIVE_TEXT, DIRECTIVE_COMPLETE);
is(shift(@results), $_) foreach (DIRECTIVE_TEXT, DIRECTIVE_START);
is(shift(@results), $_) foreach (DIRECTIVE_SIMPLE, DIRECTIVE_START, 'words words words');
is(shift(@results), $_) foreach (DIRECTIVE_SIMPLE, DIRECTIVE_START, ' ');
is(shift(@results), $_) foreach (DIRECTIVE_SIMPLE, DIRECTIVE_START, 'at the beginning.');
is(shift(@results), $_) foreach (DIRECTIVE_TEXT, DIRECTIVE_COMPLETE);
is(shift(@results), $_) foreach (DIRECTIVE_TEXT, DIRECTIVE_START);
is(shift(@results), $_) foreach (DIRECTIVE_SIMPLE, DIRECTIVE_START, 'And these are number (');
is(shift(@results), $_) foreach (DIRECTIVE_SIMPLE, DIRECTIVE_START, '17');
is(shift(@results), $_) foreach (DIRECTIVE_SIMPLE, DIRECTIVE_START, '), double (');
is(shift(@results), $_) foreach (DIRECTIVE_SIMPLE, DIRECTIVE_START, q("double quotes"));
is(shift(@results), $_) foreach (DIRECTIVE_SIMPLE, DIRECTIVE_START, ') and single quoted (');
is(shift(@results), $_) foreach (DIRECTIVE_SIMPLE, DIRECTIVE_START, q('single quotes'));
is(shift(@results), $_) foreach (DIRECTIVE_SIMPLE, DIRECTIVE_START, ') strings.');
is(shift(@results), $_) foreach (DIRECTIVE_TEXT, DIRECTIVE_COMPLETE);
is(shift(@results), $_) foreach (DIRECTIVE_TEXT, DIRECTIVE_START);
is(shift(@results), $_) foreach (DIRECTIVE_SIMPLE, DIRECTIVE_START, 'This was assigned in a multiline');
is(shift(@results), $_) foreach (DIRECTIVE_SIMPLE, DIRECTIVE_START, ': ');
is(shift(@results), $_) foreach (DIRECTIVE_SIMPLE, DIRECTIVE_START, 'one line next line 3rd line');
is(shift(@results), $_) foreach (DIRECTIVE_SIMPLE, DIRECTIVE_START, '.');
is(shift(@results), $_) foreach (DIRECTIVE_TEXT, DIRECTIVE_COMPLETE);
is(shift(@results), $_) foreach (DIRECTIVE_TEXT, DIRECTIVE_START);
is(shift(@results), $_) foreach (DIRECTIVE_SIMPLE, DIRECTIVE_START, 'Text');
is(shift(@results), $_) foreach (DIRECTIVE_SIMPLE, DIRECTIVE_START, ': ');
is(shift(@results), $_) foreach (DIRECTIVE_SIMPLE, DIRECTIVE_START, 'word');
is(shift(@results), $_) foreach (DIRECTIVE_SIMPLE, DIRECTIVE_START, '.');
is(shift(@results), $_) foreach (DIRECTIVE_TEXT, DIRECTIVE_COMPLETE);
is(shift(@results), $_) foreach (DIRECTIVE_TEXT, DIRECTIVE_START);
is(shift(@results), $_) foreach (DIRECTIVE_SIMPLE, DIRECTIVE_START, 'words words words');
is(shift(@results), $_) foreach (DIRECTIVE_SIMPLE, DIRECTIVE_START, ' ');
is(shift(@results), $_) foreach (DIRECTIVE_SIMPLE, DIRECTIVE_START, 'at the beginning.');
is(shift(@results), $_) foreach (DIRECTIVE_TEXT, DIRECTIVE_COMPLETE);
is(shift(@results), $_) foreach (DIRECTIVE_TEXT, DIRECTIVE_START);
is(shift(@results), $_) foreach (DIRECTIVE_SIMPLE, DIRECTIVE_START, 'And these are number (');
is(shift(@results), $_) foreach (DIRECTIVE_SIMPLE, DIRECTIVE_START, '17');
is(shift(@results), $_) foreach (DIRECTIVE_SIMPLE, DIRECTIVE_START, '), double (');
is(shift(@results), $_) foreach (DIRECTIVE_SIMPLE, DIRECTIVE_START, q("double quotes"));
is(shift(@results), $_) foreach (DIRECTIVE_SIMPLE, DIRECTIVE_START, ') and single quoted (');
is(shift(@results), $_) foreach (DIRECTIVE_SIMPLE, DIRECTIVE_START, q('single quotes'));
is(shift(@results), $_) foreach (DIRECTIVE_SIMPLE, DIRECTIVE_START, ') strings.');
is(shift(@results), $_) foreach (DIRECTIVE_TEXT, DIRECTIVE_COMPLETE);
is(shift(@results), $_) foreach (DIRECTIVE_TEXT, DIRECTIVE_START);
is(shift(@results), $_) foreach (DIRECTIVE_SIMPLE, DIRECTIVE_START, 'This was assigned in a multiline');
is(shift(@results), $_) foreach (DIRECTIVE_SIMPLE, DIRECTIVE_START, ': ');
is(shift(@results), $_) foreach (DIRECTIVE_SIMPLE, DIRECTIVE_START, 'one line next line 3rd line');
is(shift(@results), $_) foreach (DIRECTIVE_SIMPLE, DIRECTIVE_START, '.');
is(shift(@results), $_) foreach (DIRECTIVE_TEXT, DIRECTIVE_COMPLETE);
is(shift(@results), $_) foreach (DIRECTIVE_BLOCK, DIRECTIVE_START);
is(shift(@results), $_) foreach (DIRECTIVE_SIMPLE, DIRECTIVE_START, '  ');
is(shift(@results), $_) foreach (DIRECTIVE_SIMPLE, DIRECTIVE_START, 'Variables in');
is(shift(@results), $_) foreach (DIRECTIVE_SIMPLE, DIRECTIVE_START, "\n");
is(shift(@results), $_) foreach (DIRECTIVE_SIMPLE, DIRECTIVE_START, '  ');
is(shift(@results), $_) foreach (DIRECTIVE_SIMPLE, DIRECTIVE_START, 'a code block:');
is(shift(@results), $_) foreach (DIRECTIVE_SIMPLE, DIRECTIVE_START, "\n");
is(shift(@results), $_) foreach (DIRECTIVE_SIMPLE, DIRECTIVE_START, '  ');
is(shift(@results), $_) foreach (DIRECTIVE_SIMPLE, DIRECTIVE_START, 'word');
is(shift(@results), $_) foreach (DIRECTIVE_SIMPLE, DIRECTIVE_START, ', ');
is(shift(@results), $_) foreach (DIRECTIVE_SIMPLE, DIRECTIVE_START, 'word');
is(shift(@results), $_) foreach (DIRECTIVE_SIMPLE, DIRECTIVE_START, '.');
is(shift(@results), $_) foreach (DIRECTIVE_BLOCK, DIRECTIVE_COMPLETE);
is(shift(@results), $_) foreach (DIRECTIVE_VERBATIM, DIRECTIVE_START);
is(shift(@results), $_) foreach (DIRECTIVE_SIMPLE, DIRECTIVE_START, "\n");
is(shift(@results), $_) foreach (DIRECTIVE_SIMPLE, DIRECTIVE_START, "  Variables in\n");
is(shift(@results), $_) foreach (DIRECTIVE_SIMPLE, DIRECTIVE_START, "  a verbatim block:\n");
is(shift(@results), $_) foreach (DIRECTIVE_SIMPLE, DIRECTIVE_START, "  \$word, \${word}.\n");
is(shift(@results), $_) foreach (DIRECTIVE_SIMPLE, DIRECTIVE_START, "\n");
is(shift(@results), $_) foreach (DIRECTIVE_VERBATIM, DIRECTIVE_COMPLETE);
is(shift(@results), $_) foreach (DIRECTIVE_TEXT, DIRECTIVE_START);
is(shift(@results), $_) foreach (DIRECTIVE_SIMPLE, DIRECTIVE_START, '$nondeclared');
is(shift(@results), $_) foreach (DIRECTIVE_SIMPLE, DIRECTIVE_START, ' ');
is(shift(@results), $_) foreach (DIRECTIVE_SIMPLE, DIRECTIVE_START, '$');
is(shift(@results), $_) foreach (DIRECTIVE_SIMPLE, DIRECTIVE_START, '{variables}.');
is(shift(@results), $_) foreach (DIRECTIVE_TEXT, DIRECTIVE_COMPLETE);
is(shift(@results), $_) foreach (DIRECTIVE_TEXT, DIRECTIVE_START);
is(shift(@results), $_) foreach (DIRECTIVE_SIMPLE, DIRECTIVE_START, 'value is ');
is(shift(@results), $_) foreach (DIRECTIVE_SIMPLE, DIRECTIVE_START, '1st');
is(shift(@results), $_) foreach (DIRECTIVE_SIMPLE, DIRECTIVE_START, '.');
is(shift(@results), $_) foreach (DIRECTIVE_TEXT, DIRECTIVE_COMPLETE);
is(shift(@results), $_) foreach (DIRECTIVE_TEXT, DIRECTIVE_START);
is(shift(@results), $_) foreach (DIRECTIVE_SIMPLE, DIRECTIVE_START, 'value is ');
is(shift(@results), $_) foreach (DIRECTIVE_SIMPLE, DIRECTIVE_START, '2nd');
is(shift(@results), $_) foreach (DIRECTIVE_SIMPLE, DIRECTIVE_START, '.');
is(shift(@results), $_) foreach (DIRECTIVE_TEXT, DIRECTIVE_COMPLETE);
is(shift(@results), $_) foreach (DIRECTIVE_TEXT, DIRECTIVE_START);
is(shift(@results), $_) foreach (DIRECTIVE_SIMPLE, DIRECTIVE_START, 'value is ');
is(shift(@results), $_) foreach (DIRECTIVE_SIMPLE, DIRECTIVE_START, '3rd');
is(shift(@results), $_) foreach (DIRECTIVE_SIMPLE, DIRECTIVE_START, '.');
is(shift(@results), $_) foreach (DIRECTIVE_TEXT, DIRECTIVE_COMPLETE);
is(shift(@results), $_) foreach (DIRECTIVE_TEXT, DIRECTIVE_START);
is(shift(@results), $_) foreach (DIRECTIVE_SIMPLE, DIRECTIVE_START, '17 word 3rd 17');
is(shift(@results), $_) foreach (DIRECTIVE_TEXT, DIRECTIVE_COMPLETE);


# paragraph filter tests
# ------------------------
$varhash={_STARTDIR=>cwd(), _PARSER_VERSION=>$PerlPoint::Parser::VERSION, _SOURCE_LEVEL=>1, multiline=>'one line next line 3rd line', number=>17, value=>'3rd', words=>'words words words', string2=>'\'single quotes\'', word=>'word', string1=>'"double quotes"', nested1=>'word 3rd', nested2=>'17 word 3rd 17'};
pfilterChecks(\@results, 3, 3, $varhash);


# docstream tests
# ------------------------
docstreamDefaultChecks(\@results, 4, 4, $varhash);


# perform checks: verbatim
shift(@results) until $results[0] eq DIRECTIVE_VERBATIM or not @results;

# these checks are straight forward
foreach (1..2)
 {
  is(shift(@results), $_) foreach (DIRECTIVE_VERBATIM, DIRECTIVE_START);
  shift(@results) until $results[0] eq DIRECTIVE_VERBATIM or not @results;
  is(shift(@results), $_) foreach (DIRECTIVE_VERBATIM, DIRECTIVE_COMPLETE);
 }



# SUBROUTINES ###############################################################################

# headline handler: store what you found
sub handler
 {
  # simply store what you received
  push(@results, @_);
 }
