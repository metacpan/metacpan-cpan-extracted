

# = HISTORY SECTION =====================================================================

# ---------------------------------------------------------------------------------------
# version | date     | author   | changes
# ---------------------------------------------------------------------------------------
# 0.09    |< 14.04.02| JSTENZEL | blocks got rid of a trailing newline;
#         |28.12.2004| JSTENZEL | adapted to dotted texts;
#         |27.02.2005| JSTENZEL | adapted to fixed variable handling, see parser log;
#         |01.11.2005| JSTENZEL | each document needs a headline now;
# 0.08    |22.07.2001| JSTENZEL | adapted to improved lexer;
# 0.07    |20.03.2001| JSTENZEL | adapted to tag templates;
#         |23.03.2001| JSTENZEL | adapted to by line lexing of verbatim blocks;
#         |12.04.2001| JSTENZEL | added tests of predeclared variables;
#         |25.05.2001| JSTENZEL | adapted to paragraph reformatting: text paragraphs
#         |          |          | no longer contain a final whitespace string;
#         |28.05.2001| JSTENZEL | added _PARSER_VERSION test;
#         |01.06.2001| JSTENZEL | adapted to modified lexing algorithm which takes
#         |          |          | "words" as long as possible;
# 0.06    |20.01.2001| JSTENZEL | variable settings are now propagated into the stream;
# 0.05    |09.12.2000| JSTENZEL | new namespace: "PP" => "PerlPoint";
# 0.04    |07.10.2000| JSTENZEL | variables are accessible by (embedded) Perl now;
# 0.03    |05.10.2000| JSTENZEL | parser takes a Safe object now;
# 0.02    |05.06.2000| JSTENZEL | adapted to modified stream structure;
# 0.01    |15.04.2000| JSTENZEL | new.
# ---------------------------------------------------------------------------------------

# PerlPoint test script


# pragmata
use strict;
use lib qw(t);

# load modules
use Cwd;
use Carp;
use Safe;
use Test::More qw(no_plan);
use PerlPoint::Backend;
use PerlPoint::Parser 0.34;
use PerlPoint::Constants 0.11;

# helper lib
use testlib;

# declare variables
my (@streamData, @results);

# build parser
my ($parser)=new PerlPoint::Parser;

# and call it
$parser->run(
             stream          => \@streamData,
             files           => ['t/variables.pp'],
             safe            => new Safe,
             var2stream      => 1,
             predeclaredVars => {vAr1=>'several', VaR2=>'variables',},
             trace           => TRACE_NOTHING,
             display         => DISPLAY_NOINFO+DISPLAY_NOWARN,
            );

# build a backend
my $backend=new PerlPoint::Backend(
                                   name    =>'installation test: variables',
                                   trace   =>TRACE_NOTHING,
                                   display => DISPLAY_NOINFO,
                                  );

# register a complete set of backend handlers
$backend->register($_, \&handler) foreach (DIRECTIVE_BLOCK .. DIRECTIVE_SIMPLE);

# now run the backend
$backend->run(\@streamData);

# checks
is(shift(@results), $_) foreach (DIRECTIVE_VARSET, DIRECTIVE_START);
{
 my $pars=shift(@results);
 is(ref($pars), 'HASH');
 is(join(' ', sort keys %$pars), 'value var');
 is($pars->{var}, '_PARSER_VERSION');
 is($pars->{value}, $PerlPoint::Parser::VERSION);
}
is(shift(@results), $_) foreach (DIRECTIVE_VARSET, DIRECTIVE_START);
{
 my $pars=shift(@results);
 is(ref($pars), 'HASH');
 is(join(' ', sort keys %$pars), 'value var');
 is($pars->{var}, '_STARTDIR');
 # we skip the value check because this directory setting depends on the installation and may therefore vary
}
is(shift(@results), $_) foreach (DIRECTIVE_VARSET, DIRECTIVE_START);
{
 my $pars=shift(@results);
 is(ref($pars), 'HASH');
 is(join(' ', sort keys %$pars), 'value var');
 is($pars->{var}, 'VAR1');
 is($pars->{value}, 'several');
}
is(shift(@results), $_) foreach (DIRECTIVE_VARSET, DIRECTIVE_START);
{
 my $pars=shift(@results);
 is(ref($pars), 'HASH');
 is(join(' ', sort keys %$pars), 'value var');
 is($pars->{var}, 'VAR2');
 is($pars->{value}, 'variables');
}
is(shift(@results), $_) foreach (DIRECTIVE_VARSET, DIRECTIVE_START);
{
 my $pars=shift(@results);
 is(ref($pars), 'HASH');
 is(join(' ', sort keys %$pars), 'value var');
 is($pars->{var}, '_SOURCE_LEVEL');
 is($pars->{value}, 1);
}


is(shift(@results), $_) foreach (DIRECTIVE_DOCUMENT, DIRECTIVE_START, 'variables.pp');

# variable hash
my $varhash={
             _STARTDIR       => cwd(),
             _PARSER_VERSION => $PerlPoint::Parser::VERSION,
             _SOURCE_LEVEL   => 1,
             VAR1            => 'several',
             VAR2            => 'variables',
            };

is(shift(@results), $_) foreach (DIRECTIVE_HEADLINE, DIRECTIVE_START, 1, 'Variables', '');
{
 my $docstreams=shift(@results);
 is(ref($docstreams), 'ARRAY');
 is(join(' ', @$docstreams), '');
}

checkHeadline(\@results, 1, ['Variables'], ['Variables'], [1], [1], $varhash);

is(shift(@results), $_) foreach (DIRECTIVE_SIMPLE, DIRECTIVE_START, 'Variables');
is(shift(@results), $_) foreach (DIRECTIVE_HEADLINE, DIRECTIVE_COMPLETE, 1);

is(shift(@results), $_) foreach (DIRECTIVE_VARSET, DIRECTIVE_START);
{
 my $pars=shift(@results);
 is(ref($pars), 'HASH');
 is(join(' ', sort keys %$pars), 'value var');
 is($pars->{var}, 'word');
 is($pars->{value}, 'word');
}
is(shift(@results), $_) foreach (DIRECTIVE_VARSET, DIRECTIVE_START);
{
 my $pars=shift(@results);
 is(ref($pars), 'HASH');
 is(join(' ', sort keys %$pars), 'value var');
 is($pars->{var}, 'words');
 is($pars->{value}, 'words words words');
}
is(shift(@results), $_) foreach (DIRECTIVE_VARSET, DIRECTIVE_START);
{
 my $pars=shift(@results);
 is(ref($pars), 'HASH');
 is(join(' ', sort keys %$pars), 'value var');
 is($pars->{var}, 'number');
 is($pars->{value}, '17');
}
is(shift(@results), $_) foreach (DIRECTIVE_VARSET, DIRECTIVE_START);
{
 my $pars=shift(@results);
 is(ref($pars), 'HASH');
 is(join(' ', sort keys %$pars), 'value var');
 is($pars->{var}, 'string1');
 is($pars->{value}, '"double quotes"');
}
is(shift(@results), $_) foreach (DIRECTIVE_VARSET, DIRECTIVE_START);
{
 my $pars=shift(@results);
 is(ref($pars), 'HASH');
 is(join(' ', sort keys %$pars), 'value var');
 is($pars->{var}, 'string2');
 is($pars->{value}, "'single quotes'");
}
is(shift(@results), $_) foreach (DIRECTIVE_VARSET, DIRECTIVE_START);
{
 my $pars=shift(@results);
 is(ref($pars), 'HASH');
 is(join(' ', sort keys %$pars), 'value var');
 is($pars->{var}, 'multiline');
 is($pars->{value}, 'one line next line 3rd line');
}
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
is(shift(@results), $_) foreach (DIRECTIVE_VARSET, DIRECTIVE_START);
{
 my $pars=shift(@results);
 is(ref($pars), 'HASH');
 is(join(' ', sort keys %$pars), 'value var');
 is($pars->{var}, 'value');
 is($pars->{value}, '1st');
}
is(shift(@results), $_) foreach (DIRECTIVE_TEXT, DIRECTIVE_START);
is(shift(@results), $_) foreach (DIRECTIVE_SIMPLE, DIRECTIVE_START, 'value is ');
is(shift(@results), $_) foreach (DIRECTIVE_SIMPLE, DIRECTIVE_START, '1st');
is(shift(@results), $_) foreach (DIRECTIVE_SIMPLE, DIRECTIVE_START, '.');
is(shift(@results), $_) foreach (DIRECTIVE_TEXT, DIRECTIVE_COMPLETE);
is(shift(@results), $_) foreach (DIRECTIVE_VARSET, DIRECTIVE_START);
{
 my $pars=shift(@results);
 is(ref($pars), 'HASH');
 is(join(' ', sort keys %$pars), 'value var');
 is($pars->{var}, 'value');
 is($pars->{value}, '2nd');
}
is(shift(@results), $_) foreach (DIRECTIVE_TEXT, DIRECTIVE_START);
is(shift(@results), $_) foreach (DIRECTIVE_SIMPLE, DIRECTIVE_START, 'value is ');
is(shift(@results), $_) foreach (DIRECTIVE_SIMPLE, DIRECTIVE_START, '2nd');
is(shift(@results), $_) foreach (DIRECTIVE_SIMPLE, DIRECTIVE_START, '.');
is(shift(@results), $_) foreach (DIRECTIVE_TEXT, DIRECTIVE_COMPLETE);
is(shift(@results), $_) foreach (DIRECTIVE_VARSET, DIRECTIVE_START);
{
 my $pars=shift(@results);
 is(ref($pars), 'HASH');
 is(join(' ', sort keys %$pars), 'value var');
 is($pars->{var}, 'value');
 is($pars->{value}, '3rd');
}
is(shift(@results), $_) foreach (DIRECTIVE_TEXT, DIRECTIVE_START);
is(shift(@results), $_) foreach (DIRECTIVE_SIMPLE, DIRECTIVE_START, 'value is ');
is(shift(@results), $_) foreach (DIRECTIVE_SIMPLE, DIRECTIVE_START, '3rd');
is(shift(@results), $_) foreach (DIRECTIVE_SIMPLE, DIRECTIVE_START, '.');
is(shift(@results), $_) foreach (DIRECTIVE_TEXT, DIRECTIVE_COMPLETE);
is(shift(@results), $_) foreach (DIRECTIVE_VARSET, DIRECTIVE_START);
{
 my $pars=shift(@results);
 is(ref($pars), 'HASH');
 is(join(' ', sort keys %$pars), 'value var');
 is($pars->{var}, 'nested1');
 is($pars->{value}, 'word 3rd');
}
is(shift(@results), $_) foreach (DIRECTIVE_VARSET, DIRECTIVE_START);
{
 my $pars=shift(@results);
 is(ref($pars), 'HASH');
 is(join(' ', sort keys %$pars), 'value var');
 is($pars->{var}, 'nested2');
 is($pars->{value}, '17 word 3rd 17');
}
is(shift(@results), $_) foreach (DIRECTIVE_TEXT, DIRECTIVE_START);
is(shift(@results), $_) foreach (DIRECTIVE_SIMPLE, DIRECTIVE_START, '17 word 3rd 17');
is(shift(@results), $_) foreach (DIRECTIVE_TEXT, DIRECTIVE_COMPLETE);

is(shift(@results), $_) foreach (DIRECTIVE_TEXT, DIRECTIVE_START);
is(shift(@results), $_) foreach (DIRECTIVE_SIMPLE, DIRECTIVE_START, 'Predeclared were ');
is(shift(@results), $_) foreach (DIRECTIVE_SIMPLE, DIRECTIVE_START, 'several');
is(shift(@results), $_) foreach (DIRECTIVE_SIMPLE, DIRECTIVE_START, ' ');
is(shift(@results), $_) foreach (DIRECTIVE_SIMPLE, DIRECTIVE_START, 'variables');
is(shift(@results), $_) foreach (DIRECTIVE_SIMPLE, DIRECTIVE_START, '.');
is(shift(@results), $_) foreach (DIRECTIVE_TEXT, DIRECTIVE_COMPLETE);

is(shift(@results), $_) foreach (DIRECTIVE_DOCUMENT, DIRECTIVE_COMPLETE, 'variables.pp');

# SUBROUTINES ###############################################################################

# headline handler: store what you found
sub handler
 {
  # simply store what you received
  push(@results, @_);
 }
