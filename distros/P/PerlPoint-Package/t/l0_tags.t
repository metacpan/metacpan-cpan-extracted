

# = HISTORY SECTION =====================================================================

# ---------------------------------------------------------------------------------------
# version | date     | author   | changes
# ---------------------------------------------------------------------------------------
# 0.13    |27.12.2004| JSTENZEL | adapted to new headline path data, DPOINT_TEXT and new
#         |          |          | \REF options;
#         |27.02.2005| JSTENZEL | adapted to fixed variable handling, see parser log;
#         |01.11.2005| JSTENZEL | each document needs a headline now;
# 0.12    |31.08.2002| JSTENZEL | adapted to extended tag streaming (body hint);
# 0.11    |< 14.04.02| JSTENZEL | blocks got rid of a trailing newline;
#         |          | JSTENZEL | adapted to headline shortcuts;
#         |15.04.2002| JSTENZEL | adapted to chapter docstream hints;
# 0.10    |16.08.2001| JSTENZEL | no need to build a Safe object;
#         |13.10.2001| JSTENZEL | switched to Test::More;
#         |          | JSTENZEL | added tests to check finish hook interface
#         |          |          | (and parsers anchor management by the way);
#         |27.11.2001| JSTENZEL | adapted to additional shift hints in list directives;
# 0.09    |22.07.2001| JSTENZEL | adapted to perl 5.005;
# 0.08    |20.03.2001| JSTENZEL | adapted to tag templates;
#         |23.03.2001| JSTENZEL | adapted to by line lexing of verbatim blocks;
#         |24.05.2001| JSTENZEL | adapted to paragraph reformatting: text paragraphs
#         |          |          | no longer contain a final whitespace string;
#         |01.06.2001| JSTENZEL | adapted to modified lexing algorithm which takes
#         |          |          | "words" as long as possible;
# 0.07    |30.01.2001| JSTENZEL | ordered lists now provide the entry level number;
# 0.06    |09.12.2000| JSTENZEL | new namespace: "PP" => "PerlPoint";
# 0.05    |05.10.2000| JSTENZEL | parser takes a Safe object now;
# 0.04    |03.10.2000| JSTENZEL | adapted to new definition list grammar: definition item
#         |          |          | is now made of base elements like tags;
# 0.03    |16.08.2000| JSTENZEL | added a demonstration of string parameters;
# 0.02    |27.05.2000| JSTENZEL | adapted to modified list streaming (leading spaces);
# 0.01    |15.04.2000| JSTENZEL | new.
# ---------------------------------------------------------------------------------------

# PerlPoint test script


# pragmata
use strict;
use lib qw(t);

# load modules
use Cwd;
use Carp;
use PerlPoint::Backend;
use Test::More qw(no_plan);
use PerlPoint::Parser 0.34;
use PerlPoint::Constants;

# helper lib
use testlib;

# declare test tags
use PerlPoint::Tags;
use PerlPoint::Tags::_tags;

# declare variables
my (@streamData, @results);

# build parser
my ($parser)=new PerlPoint::Parser;

# and call it
$parser->run(
             stream        => \@streamData,
             files         => ['t/tags.pp'],
             headlineLinks => 1,
             trace         => TRACE_NOTHING,
             display       => DISPLAY_NOINFO,
            );

# build a backend
my $backend=new PerlPoint::Backend(
                                   name    => 'installation test: tags',
                                   trace   => TRACE_NOTHING,
                                   display => DISPLAY_NOINFO,
                                  );

# register a complete set of backend handlers
$backend->register($_, \&handler) foreach (DIRECTIVE_BLOCK .. DIRECTIVE_SIMPLE);

# now run the backend
$backend->run(\@streamData);

# variable hash
my $varhash={_STARTDIR=>cwd(), _PARSER_VERSION=>$PerlPoint::Parser::VERSION, _SOURCE_LEVEL=>1};

# checks
is(shift(@results), $_) foreach (DIRECTIVE_DOCUMENT, DIRECTIVE_START, 'tags.pp');

is(shift(@results), $_) foreach (DIRECTIVE_HEADLINE, DIRECTIVE_START, 1, 'Tags', '');
{
 my $docstreams=shift(@results);
 is(ref($docstreams), 'ARRAY');
 is(join(' ', @$docstreams), '');
}

checkHeadline(\@results, 1, ['Tags'], ['Tags'], [1], [1], $varhash);

is(shift(@results), $_) foreach (DIRECTIVE_SIMPLE, DIRECTIVE_START, 'Tags');
is(shift(@results), $_) foreach (DIRECTIVE_HEADLINE, DIRECTIVE_COMPLETE, 1);

is(shift(@results), $_) foreach (DIRECTIVE_TEXT, DIRECTIVE_START);
is(shift(@results), $_) foreach (DIRECTIVE_SIMPLE, DIRECTIVE_START, 'Simple');
is(shift(@results), $_) foreach (DIRECTIVE_SIMPLE, DIRECTIVE_START, ': ');
is(shift(@results), $_) foreach (DIRECTIVE_TAG, DIRECTIVE_START, 'TEST');
{
 my $pars=shift(@results);
 is(ref($pars), 'HASH');
 is(join(' ', sort keys %$pars), '');
}
is(shift(@results), 0);
is(shift(@results), $_) foreach (DIRECTIVE_TAG, DIRECTIVE_COMPLETE, 'TEST');
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
is(shift(@results), 0);
is(shift(@results), $_) foreach (DIRECTIVE_TAG, DIRECTIVE_COMPLETE, 'TEST');
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
is(shift(@results), 0);
is(shift(@results), $_) foreach (DIRECTIVE_TAG, DIRECTIVE_COMPLETE, 'TOAST');
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


# headline reference (forward)
is(shift(@results), $_) foreach (DIRECTIVE_TEXT, DIRECTIVE_START);
is(shift(@results), $_) foreach (DIRECTIVE_SIMPLE, DIRECTIVE_START, 'Headline reference (forward)');
is(shift(@results), $_) foreach (DIRECTIVE_SIMPLE, DIRECTIVE_START, ': ');
is(shift(@results), $_) foreach (DIRECTIVE_TAG, DIRECTIVE_START, 'REF');
{
 my $pars=shift(@results);
 is(ref($pars), 'HASH');
 is(join(' ', sort keys %$pars), '__body__ __chapter__ __value__ name type valueformat');
 is($pars->{__body__}, 0);
 is($pars->{__chapter__}, 2);
 is($pars->{__value__}, 'Tag in a headline');
 is($pars->{valueformat}, 'pure');
 is($pars->{name}, 'Tag in a headline');
 is($pars->{type}, 'plain');
}
is(shift(@results), 0);
is(shift(@results), $_) foreach (DIRECTIVE_TAG, DIRECTIVE_COMPLETE, 'REF');
{
 my $pars=shift(@results);
 is(ref($pars), 'HASH');
 is(join(' ', sort keys %$pars), '__body__ name type valueformat');
 is($pars->{__body__}, 0);
 is($pars->{valueformat}, 'pure');
 is($pars->{name}, 'Tag in a headline');
 is($pars->{type}, 'plain');
}
is(shift(@results), 0);
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
# is(shift(@results), $_) foreach (DIRECTIVE_SIMPLE, DIRECTIVE_START, ' ');
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
}
is(shift(@results), 1);
is(shift(@results), $_) foreach (DIRECTIVE_TEXT, DIRECTIVE_COMPLETE);

# headline reference (backwards)
is(shift(@results), $_) foreach (DIRECTIVE_TEXT, DIRECTIVE_START);
is(shift(@results), $_) foreach (DIRECTIVE_SIMPLE, DIRECTIVE_START, 'Headline reference (backwards)');
is(shift(@results), $_) foreach (DIRECTIVE_SIMPLE, DIRECTIVE_START, ': ');
is(shift(@results), $_) foreach (DIRECTIVE_TAG, DIRECTIVE_START, 'REF');
{
 my $pars=shift(@results);
 is(ref($pars), 'HASH');
 is(join(' ', sort keys %$pars), '__body__ __chapter__ __value__ name type valueformat');
 is($pars->{__body__}, 0);
 is($pars->{__chapter__}, 2);
 is($pars->{__value__}, 'Tag in a headline');
 is($pars->{valueformat}, 'pure');
 is($pars->{name}, 'Tag in a headline');
 is($pars->{type}, 'plain');
}
is(shift(@results), 0);
is(shift(@results), $_) foreach (DIRECTIVE_TAG, DIRECTIVE_COMPLETE, 'REF');
{
 my $pars=shift(@results);
 is(ref($pars), 'HASH');
 is(join(' ', sort keys %$pars), '__body__ name type valueformat');
 is($pars->{__body__}, 0);
 is($pars->{valueformat}, 'pure');
 is($pars->{name}, 'Tag in a headline');
 is($pars->{type}, 'plain');
}
is(shift(@results), 0);
is(shift(@results), $_) foreach (DIRECTIVE_SIMPLE, DIRECTIVE_START, '.');
is(shift(@results), $_) foreach (DIRECTIVE_TEXT, DIRECTIVE_COMPLETE);


is(shift(@results), $_) foreach (DIRECTIVE_DOCUMENT, DIRECTIVE_COMPLETE, 'tags.pp');


# SUBROUTINES ###############################################################################

# headline handler: store what you found
sub handler
 {
  # simply store what you received
  push(@results, @_);
 }
