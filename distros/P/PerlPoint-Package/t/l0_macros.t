

# = HISTORY SECTION =====================================================================

# ---------------------------------------------------------------------------------------
# version | date     | author   | changes
# ---------------------------------------------------------------------------------------
# 0.08    |07.03.2006| JSTENZEL | adapted to removal of dummy tokens;
# 0.07    |31.08.2002| JSTENZEL | adapted to extended tag streaming (body hint);
#         |01.11.2005| JSTENZEL | each document needs a headline now;
# 0.06    |16.08.2001| JSTENZEL | no need to build a Safe object;
#         |23.11.2001| JSTENZEL | switched to Test::More;
#         |          | JSTENZEL | added option default tests;
# 0.05    |22.07.2001| JSTENZEL | adapted to perl 5.005;
# 0.04    |20.03.2001| JSTENZEL | adapted to tag templates;
#         |24.05.2001| JSTENZEL | adapted to paragraph reformatting: text paragraphs
#         |          |          | no longer contain a final whitespace string;
#         |01.06.2001| JSTENZEL | adapted to modified lexing algorithm which takes
#         |          |          | "words" as long as possible;
#         |05.06.2001| JSTENZEL | adapted to further optimized lexing;
# 0.03    |08.02.2000| JSTENZEL | adapted to improved handling of bodyless macros;
# 0.02    |09.12.2000| JSTENZEL | new namespace: "PP" => "PerlPoint";
# 0.01    |11.10.2000| JSTENZEL | new.
# ---------------------------------------------------------------------------------------

# PerlPoint test script


# pragmata
use strict;

# load modules
use Cwd;
use Carp;
use PerlPoint::Backend;
use PerlPoint::Constants;
use PerlPoint::Parser 0.08;
use Test::More qw(no_plan);

# declare test tags
use lib qw(t);
use testlib;
use PerlPoint::Tags;
use PerlPoint::Tags::_macros;

# declare variables
my (@streamData, @results);

# build parser
my ($parser)=new PerlPoint::Parser;

# and call it
$parser->run(
             stream  => \@streamData,
             files   => ['t/macros.pp'],
             trace   => TRACE_NOTHING,
             display => DISPLAY_NOINFO,
            );

# build a backend
my $backend=new PerlPoint::Backend(
                                   name    => 'installation test: macros',
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
is(shift(@results), $_) foreach (DIRECTIVE_DOCUMENT, DIRECTIVE_START, 'macros.pp');

# variable hash
my $varhash={
             _STARTDIR       => cwd(),
             _PARSER_VERSION => $PerlPoint::Parser::VERSION,
             _SOURCE_LEVEL   => 1,
            };

is(shift(@results), $_) foreach (DIRECTIVE_HEADLINE, DIRECTIVE_START, 1, 'Macros', '');
{
 my $docstreams=shift(@results);
 is(ref($docstreams), 'ARRAY');
 is(join(' ', @$docstreams), '');
}

checkHeadline(\@results, 1, ['Macros'], ['Macros'], [1], [1], $varhash);

is(shift(@results), $_) foreach (DIRECTIVE_SIMPLE, DIRECTIVE_START, 'Macros');
is(shift(@results), $_) foreach (DIRECTIVE_HEADLINE, DIRECTIVE_COMPLETE, 1);

is(shift(@results), $_) foreach (DIRECTIVE_TEXT, DIRECTIVE_START);
is(shift(@results), $_) foreach (DIRECTIVE_SIMPLE, DIRECTIVE_START, 'This ');
is(shift(@results), $_) foreach (DIRECTIVE_TAG, DIRECTIVE_START, 'I');
{
 my $pars=shift(@results);
 is(ref($pars), 'HASH');
 is(join('', sort keys %$pars), '');
}
is(shift(@results), 3);
is(shift(@results), $_) foreach (DIRECTIVE_TAG, DIRECTIVE_START, 'B');
{
 my $pars=shift(@results);
 is(ref($pars), 'HASH');
 is(join('', sort keys %$pars), '');
}
is(shift(@results), 1);
is(shift(@results), $_) foreach (DIRECTIVE_SIMPLE, DIRECTIVE_START, 'text');
is(shift(@results), $_) foreach (DIRECTIVE_TAG, DIRECTIVE_COMPLETE, 'B');
{
 my $pars=shift(@results);
 is(ref($pars), 'HASH');
 is(join('', sort keys %$pars), '');
}
is(shift(@results), 1);
is(shift(@results), $_) foreach (DIRECTIVE_TAG, DIRECTIVE_COMPLETE, 'I');
{
 my $pars=shift(@results);
 is(ref($pars), 'HASH');
 is(join('', sort keys %$pars), '');
}
is(shift(@results), 3);
is(shift(@results), $_) foreach (DIRECTIVE_SIMPLE, DIRECTIVE_START, ' ');
is(shift(@results), $_) foreach (DIRECTIVE_SIMPLE, DIRECTIVE_START, 'is ');

is(shift(@results), $_) foreach (DIRECTIVE_TAG, DIRECTIVE_START, 'FONT');
{
 my $pars=shift(@results);
 is(ref($pars), 'HASH');
 is(join('', sort keys %$pars), 'color');
 is(join('', sort values %$pars), 'red');
}
is(shift(@results), 1);
is(shift(@results), $_) foreach (DIRECTIVE_SIMPLE, DIRECTIVE_START, 'colored');
is(shift(@results), $_) foreach (DIRECTIVE_TAG, DIRECTIVE_COMPLETE, 'FONT');
{
 my $pars=shift(@results);
 is(ref($pars), 'HASH');
 is(join('', sort keys %$pars), 'color');
 is(join('', sort values %$pars), 'red');
}
is(shift(@results), 1);
is(shift(@results), $_) foreach (DIRECTIVE_SIMPLE, DIRECTIVE_START, '.');
is(shift(@results), $_) foreach (DIRECTIVE_TEXT, DIRECTIVE_COMPLETE);

# 2nd section
is(shift(@results), $_) foreach (DIRECTIVE_TEXT, DIRECTIVE_START);
is(shift(@results), $_) foreach (DIRECTIVE_SIMPLE, DIRECTIVE_START, 'Macro options can be preset to contain ');
is(shift(@results), $_) foreach (DIRECTIVE_SIMPLE, DIRECTIVE_START, 'default values as set up');
is(shift(@results), $_) foreach (DIRECTIVE_SIMPLE, DIRECTIVE_START, '.');
is(shift(@results), $_) foreach (DIRECTIVE_SIMPLE, DIRECTIVE_START, ' ');
is(shift(@results), $_) foreach (DIRECTIVE_SIMPLE, DIRECTIVE_START, 'If you want,');
is(shift(@results), $_) foreach (DIRECTIVE_SIMPLE, DIRECTIVE_START, ' ');
is(shift(@results), $_) foreach (DIRECTIVE_SIMPLE, DIRECTIVE_START, 'you can assign ');
is(shift(@results), $_) foreach (DIRECTIVE_SIMPLE, DIRECTIVE_START, 'up to date values');
is(shift(@results), $_) foreach (DIRECTIVE_SIMPLE, DIRECTIVE_START, '.');
is(shift(@results), $_) foreach (DIRECTIVE_TEXT, DIRECTIVE_COMPLETE);

# 3rd text
is(shift(@results), $_) foreach (DIRECTIVE_TEXT, DIRECTIVE_START);
is(shift(@results), $_) foreach (DIRECTIVE_SIMPLE, DIRECTIVE_START, 'Tags can be ');
is(shift(@results), $_) foreach (DIRECTIVE_TAG, DIRECTIVE_START, 'FONT');
{
 my $pars=shift(@results);
 is(ref($pars), 'HASH');
 is(join('', sort keys %$pars), 'color');
 is(join('', sort values %$pars), 'red');
}
is(shift(@results), 3);
is(shift(@results), $_) foreach (DIRECTIVE_TAG, DIRECTIVE_START, 'I');
{
 my $pars=shift(@results);
 is(ref($pars), 'HASH');
 is(join('', sort keys %$pars), '');
}
is(shift(@results), 1);
is(shift(@results), $_) foreach (DIRECTIVE_SIMPLE, DIRECTIVE_START, 'nested');
is(shift(@results), $_) foreach (DIRECTIVE_TAG, DIRECTIVE_COMPLETE, 'I');
{
 my $pars=shift(@results);
 is(ref($pars), 'HASH');
 is(join('', sort keys %$pars), '');
}
is(shift(@results), 1);
is(shift(@results), $_) foreach (DIRECTIVE_TAG, DIRECTIVE_COMPLETE, 'FONT');
{
 my $pars=shift(@results);
 is(ref($pars), 'HASH');
 is(join('', sort keys %$pars), 'color');
 is(join('', sort values %$pars), 'red');
}
is(shift(@results), 3);
is(shift(@results), $_) foreach (DIRECTIVE_SIMPLE, DIRECTIVE_START, ' ');
is(shift(@results), $_) foreach (DIRECTIVE_SIMPLE, DIRECTIVE_START, 'into macros. And ');
is(shift(@results), $_) foreach (DIRECTIVE_TAG, DIRECTIVE_START, 'I');
{
 my $pars=shift(@results);
 is(ref($pars), 'HASH');
 is(join('', sort keys %$pars), '');
}
is(shift(@results), 3);
is(shift(@results), $_) foreach (DIRECTIVE_TAG, DIRECTIVE_START, 'FONT');
{
 my $pars=shift(@results);
 is(ref($pars), 'HASH');
 is(join('', sort keys %$pars), 'color');
 is(join('', sort values %$pars), 'red');
}
is(shift(@results), 1);
is(shift(@results), $_) foreach (DIRECTIVE_SIMPLE, DIRECTIVE_START, 'vice versa');
is(shift(@results), $_) foreach (DIRECTIVE_TAG, DIRECTIVE_COMPLETE, 'FONT');
{
 my $pars=shift(@results);
 is(ref($pars), 'HASH');
 is(join('', sort keys %$pars), 'color');
 is(join('', sort values %$pars), 'red');
}
is(shift(@results), 1);
is(shift(@results), $_) foreach (DIRECTIVE_TAG, DIRECTIVE_COMPLETE, 'I');
{
 my $pars=shift(@results);
 is(ref($pars), 'HASH');
 is(join('', sort keys %$pars), '');
}
is(shift(@results), 3);
is(shift(@results), $_) foreach (DIRECTIVE_SIMPLE, DIRECTIVE_START, '.');
is(shift(@results), $_) foreach (DIRECTIVE_SIMPLE, DIRECTIVE_START, ' ');
is(shift(@results), $_) foreach (DIRECTIVE_TAG, DIRECTIVE_START, 'I');
{
 my $pars=shift(@results);
 is(ref($pars), 'HASH');
 is(join('', sort keys %$pars), '');
}
is(shift(@results), 5);
is(shift(@results), $_) foreach (DIRECTIVE_TAG, DIRECTIVE_START, 'B');
{
 my $pars=shift(@results);
 is(ref($pars), 'HASH');
 is(join('', sort keys %$pars), '');
}
is(shift(@results), 3);
is(shift(@results), $_) foreach (DIRECTIVE_TAG, DIRECTIVE_START, 'FONT');
{
 my $pars=shift(@results);
 is(ref($pars), 'HASH');
 is(join('', sort keys %$pars), 'color');
 is(join('', sort values %$pars), 'blue');
}
is(shift(@results), 1);
is(shift(@results), $_) foreach (DIRECTIVE_SIMPLE, DIRECTIVE_START, 'This');
is(shift(@results), $_) foreach (DIRECTIVE_TAG, DIRECTIVE_COMPLETE, 'FONT');
{
 my $pars=shift(@results);
 is(ref($pars), 'HASH');
 is(join('', sort keys %$pars), 'color');
 is(join('', sort values %$pars), 'blue');
}
is(shift(@results), 1);
is(shift(@results), $_) foreach (DIRECTIVE_TAG, DIRECTIVE_COMPLETE, 'B');
{
 my $pars=shift(@results);
 is(ref($pars), 'HASH');
 is(join('', sort keys %$pars), '');
}
is(shift(@results), 3);
is(shift(@results), $_) foreach (DIRECTIVE_TAG, DIRECTIVE_COMPLETE, 'I');
{
 my $pars=shift(@results);
 is(ref($pars), 'HASH');
 is(join('', sort keys %$pars), '');
}
is(shift(@results), 5);
is(shift(@results), $_) foreach (DIRECTIVE_SIMPLE, DIRECTIVE_START, ' ');
is(shift(@results), $_) foreach (DIRECTIVE_SIMPLE, DIRECTIVE_START, 'is formatted by nested macros.');
is(shift(@results), $_) foreach (DIRECTIVE_SIMPLE, DIRECTIVE_START, ' ');
is(shift(@results), $_) foreach (DIRECTIVE_TAG, DIRECTIVE_START, 'EMBED');
{
 my $pars=shift(@results);
 is(ref($pars), 'HASH');
 is(join('', sort keys %$pars), 'lang');
 is(join('', sort values %$pars), 'html');
}
is(shift(@results), $_) foreach (DIRECTIVE_SIMPLE, DIRECTIVE_START, ' ');
is(shift(@results), $_) foreach (DIRECTIVE_SIMPLE, DIRECTIVE_START, 'This is <i>embedded HTML</i>');
is(shift(@results), $_) foreach (DIRECTIVE_TAG, DIRECTIVE_COMPLETE, 'EMBED');
{
 my $pars=shift(@results);
 is(ref($pars), 'HASH');
 is(join('', sort keys %$pars), 'lang');
 is(join('', sort values %$pars), 'html');
}
is(shift(@results), $_) foreach (DIRECTIVE_SIMPLE, DIRECTIVE_START, '.');
is(shift(@results), $_) foreach (DIRECTIVE_TEXT, DIRECTIVE_COMPLETE);

# 4th section
is(shift(@results), $_) foreach (DIRECTIVE_TEXT, DIRECTIVE_START);
is(shift(@results), $_) foreach (DIRECTIVE_SIMPLE, DIRECTIVE_START, 'Macros can be used to abbreviate longer texts as well as other tags or tag combinations.');
is(shift(@results), $_) foreach (DIRECTIVE_TEXT, DIRECTIVE_COMPLETE);

is(shift(@results), $_) foreach (DIRECTIVE_DOCUMENT, DIRECTIVE_COMPLETE, 'macros.pp');


# SUBROUTINES ###############################################################################

# headline handler: store what you found
sub handler
 {
  # simply store what you received
  push(@results, @_);
 }
