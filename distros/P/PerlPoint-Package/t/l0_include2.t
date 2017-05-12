

# = HISTORY SECTION =====================================================================

# ---------------------------------------------------------------------------------------
# version | date     | author   | changes
# ---------------------------------------------------------------------------------------
# 0.03    |27.02.2005| JSTENZEL | adapted to fixed variable handling, see parser log;
#         |01.11.2005| JSTENZEL | each document needs a headline now;
# 0.02    |< 14.04.02| JSTENZEL | empty text paragraphs are not streamed any longer;
#         |          | JSTENZEL | switched to Test::More;
# 0.01    |28.05.2001| JSTENZEL | new.
# ---------------------------------------------------------------------------------------

# PerlPoint test script


# pragmata
use strict;
use lib qw(t);

# load modules
use Cwd;
use Carp;
use Safe;
use PerlPoint::Backend;
use PerlPoint::Constants;
use Test::More qw(no_plan);
use PerlPoint::Parser 0.34;

# helper lib
use testlib;

# declare variables
my (@streamData, @results);

# build parser
my ($parser)=new PerlPoint::Parser;

# and call it
$parser->run(
             stream     => \@streamData,
             files      => ['t/include3.pp'],
             filter     => 'pp',
             safe       => new Safe,
             var2stream => 1,
             trace      => TRACE_NOTHING, # PARSER+TRACE_LEXER+TRACE_SEMANTIC+TRACE_PARAGRAPHS,   # NOTHING,
             display    => DISPLAY_NOINFO+DISPLAY_NOWARN,
            );

# build a backend
my $backend=new PerlPoint::Backend(
                                   name    => 'installation test: include files preserving variables',
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
                                           DIRECTIVE_VARRESET,
                                           DIRECTIVE_TAG,
                                           DIRECTIVE_TEXT,
                                           DIRECTIVE_UPOINT,
                                           DIRECTIVE_VARSET,
                                           DIRECTIVE_VERBATIM,
                                           DIRECTIVE_SIMPLE,
                                          );

# now run the backend
$backend->run(\@streamData);

# perform checks, starting by skipping predeclared variables (checked by another test)
shift(@results) until $results[0] eq DIRECTIVE_DOCUMENT and $results[1] eq DIRECTIVE_START;

# source stream begins
is(shift(@results), $_) foreach (DIRECTIVE_DOCUMENT, DIRECTIVE_START, 'include3.pp');


# variable hash
my $varhash={
             _STARTDIR       => cwd(),
             _PARSER_VERSION => $PerlPoint::Parser::VERSION,
             _SOURCE_LEVEL   => 1,
            };

is(shift(@results), $_) foreach (DIRECTIVE_HEADLINE, DIRECTIVE_START, 1, 'Includes', '');
{
 my $docstreams=shift(@results);
 is(ref($docstreams), 'ARRAY');
 is(join(' ', @$docstreams), '');
}

checkHeadline(\@results, 1, ['Includes'], ['Includes'], [1], [1], $varhash);

is(shift(@results), $_) foreach (DIRECTIVE_SIMPLE, DIRECTIVE_START, 'Includes');
is(shift(@results), $_) foreach (DIRECTIVE_HEADLINE, DIRECTIVE_COMPLETE, 1);

# variables are set
is(shift(@results), $_) foreach (DIRECTIVE_VARSET, DIRECTIVE_START);
{
 my $pars=shift(@results);
 is(ref($pars), 'HASH');
 is(join(' ', sort keys %$pars), 'value var');
 is($pars->{var}, 'toBeRestored1');
 is($pars->{value}, 'value1');
}
is(shift(@results), $_) foreach (DIRECTIVE_VARSET, DIRECTIVE_START);
{
 my $pars=shift(@results);
 is(ref($pars), 'HASH');
 is(join(' ', sort keys %$pars), 'value var');
 is($pars->{var}, 'toBeRestored2');
 is($pars->{value}, 'value2');
}
is(shift(@results), $_) foreach (DIRECTIVE_VARSET, DIRECTIVE_START);
{
 my $pars=shift(@results);
 is(ref($pars), 'HASH');
 is(join(' ', sort keys %$pars), 'value var');
 is($pars->{var}, 'canBeOverwritten');
 is($pars->{value}, 'value3');
}

# original values
is(shift(@results), $_) foreach (DIRECTIVE_TEXT, DIRECTIVE_START);
is(shift(@results), $_) foreach (DIRECTIVE_SIMPLE, DIRECTIVE_START, 'Original values');
is(shift(@results), $_) foreach (DIRECTIVE_SIMPLE, DIRECTIVE_START, q(: "));
is(shift(@results), $_) foreach (DIRECTIVE_SIMPLE, DIRECTIVE_START, q(value1));
is(shift(@results), $_) foreach (DIRECTIVE_SIMPLE, DIRECTIVE_START, q(", "));
is(shift(@results), $_) foreach (DIRECTIVE_SIMPLE, DIRECTIVE_START, q(value2));
is(shift(@results), $_) foreach (DIRECTIVE_SIMPLE, DIRECTIVE_START, q(", "));
is(shift(@results), $_) foreach (DIRECTIVE_SIMPLE, DIRECTIVE_START, q(value3));
is(shift(@results), $_) foreach (DIRECTIVE_SIMPLE, DIRECTIVE_START, q(".));
is(shift(@results), $_) foreach (DIRECTIVE_TEXT, DIRECTIVE_COMPLETE);

# internal variable is set
is(shift(@results), $_) foreach (DIRECTIVE_VARSET, DIRECTIVE_START);
{
 my $pars=shift(@results);
 is(ref($pars), 'HASH');
 is(join(' ', sort keys %$pars), 'value var');
 is($pars->{var}, '_SOURCE_LEVEL');
 is($pars->{value}, 2);
}

# variables are set
is(shift(@results), $_) foreach (DIRECTIVE_VARSET, DIRECTIVE_START);
{
 my $pars=shift(@results);
 is(ref($pars), 'HASH');
 is(join(' ', sort keys %$pars), 'value var');
 is($pars->{var}, 'toBeRestored1');
 is($pars->{value}, 'newValue1');
}
is(shift(@results), $_) foreach (DIRECTIVE_VARSET, DIRECTIVE_START);
{
 my $pars=shift(@results);
 is(ref($pars), 'HASH');
 is(join(' ', sort keys %$pars), 'value var');
 is($pars->{var}, 'toBeRestored2');
 is($pars->{value}, 'newValue2');
}

# use Data::Dumper; warn Dumper(\@results);

is(shift(@results), $_) foreach (DIRECTIVE_VARSET, DIRECTIVE_START);
{
 my $pars=shift(@results);
 is(ref($pars), 'HASH');
 is(join(' ', sort keys %$pars), 'value var');
 is($pars->{var}, 'canBeOverwritten');
 is($pars->{value}, 'newValue3');
}

# use Data::Dumper; warn Dumper(\@results);

# in the nested source
is(shift(@results), $_) foreach (DIRECTIVE_TEXT, DIRECTIVE_START);
is(shift(@results), $_) foreach (DIRECTIVE_SIMPLE, DIRECTIVE_START, 'Values inside nested source');
is(shift(@results), $_) foreach (DIRECTIVE_SIMPLE, DIRECTIVE_START, q(: "));
is(shift(@results), $_) foreach (DIRECTIVE_SIMPLE, DIRECTIVE_START, q(newValue1));
is(shift(@results), $_) foreach (DIRECTIVE_SIMPLE, DIRECTIVE_START, q(", "));
is(shift(@results), $_) foreach (DIRECTIVE_SIMPLE, DIRECTIVE_START, q(newValue2));
is(shift(@results), $_) foreach (DIRECTIVE_SIMPLE, DIRECTIVE_START, q(", "));
is(shift(@results), $_) foreach (DIRECTIVE_SIMPLE, DIRECTIVE_START, q(newValue3));
is(shift(@results), $_) foreach (DIRECTIVE_SIMPLE, DIRECTIVE_START, q(".));
is(shift(@results), $_) foreach (DIRECTIVE_TEXT, DIRECTIVE_COMPLETE);

# internal variable is set
is(shift(@results), $_) foreach (DIRECTIVE_VARSET, DIRECTIVE_START);
{
 my $pars=shift(@results);
 is(ref($pars), 'HASH');
 is(join(' ', sort keys %$pars), 'value var');
 is($pars->{var}, '_SOURCE_LEVEL');
 is($pars->{value}, 1);
}

# all variables are reset ...
is(shift(@results), $_) foreach (DIRECTIVE_VARRESET, DIRECTIVE_START);

# ... and set again to restore original values
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
 is($pars->{var}, '_SOURCE_LEVEL');
 is($pars->{value}, 1);
}
is(shift(@results), $_) foreach (DIRECTIVE_VARSET, DIRECTIVE_START);
{
 my $pars=shift(@results);
 is(ref($pars), 'HASH');
 is(join(' ', sort keys %$pars), 'value var');
 is($pars->{var}, '_STARTDIR');
 # skip the value test here
}
is(shift(@results), $_) foreach (DIRECTIVE_VARSET, DIRECTIVE_START);
{
 my $pars=shift(@results);
 is(ref($pars), 'HASH');
 is(join(' ', sort keys %$pars), 'value var');
 is($pars->{var}, 'canBeOverwritten');
 is($pars->{value}, 'value3');
}
is(shift(@results), $_) foreach (DIRECTIVE_VARSET, DIRECTIVE_START);
{
 my $pars=shift(@results);
 is(ref($pars), 'HASH');
 is(join(' ', sort keys %$pars), 'value var');
 is($pars->{var}, 'toBeRestored1');
 is($pars->{value}, 'value1');
}
is(shift(@results), $_) foreach (DIRECTIVE_VARSET, DIRECTIVE_START);
{
 my $pars=shift(@results);
 is(ref($pars), 'HASH');
 is(join(' ', sort keys %$pars), 'value var');
 is($pars->{var}, 'toBeRestored2');
 is($pars->{value}, 'value2');
}

# restored values
is(shift(@results), $_) foreach (DIRECTIVE_TEXT, DIRECTIVE_START);
is(shift(@results), $_) foreach (DIRECTIVE_SIMPLE, DIRECTIVE_START, 'After 1st inclusion');
is(shift(@results), $_) foreach (DIRECTIVE_SIMPLE, DIRECTIVE_START, q(: "));
is(shift(@results), $_) foreach (DIRECTIVE_SIMPLE, DIRECTIVE_START, q(value1));
is(shift(@results), $_) foreach (DIRECTIVE_SIMPLE, DIRECTIVE_START, q(", "));
is(shift(@results), $_) foreach (DIRECTIVE_SIMPLE, DIRECTIVE_START, q(value2));
is(shift(@results), $_) foreach (DIRECTIVE_SIMPLE, DIRECTIVE_START, q(", "));
is(shift(@results), $_) foreach (DIRECTIVE_SIMPLE, DIRECTIVE_START, q(value3));
is(shift(@results), $_) foreach (DIRECTIVE_SIMPLE, DIRECTIVE_START, q(".));
is(shift(@results), $_) foreach (DIRECTIVE_TEXT, DIRECTIVE_COMPLETE);

# internal variable is set
is(shift(@results), $_) foreach (DIRECTIVE_VARSET, DIRECTIVE_START);
{
 my $pars=shift(@results);
 is(ref($pars), 'HASH');
 is(join(' ', sort keys %$pars), 'value var');
 is($pars->{var}, '_SOURCE_LEVEL');
 is($pars->{value}, 2);
}

# variables are set
is(shift(@results), $_) foreach (DIRECTIVE_VARSET, DIRECTIVE_START);
{
 my $pars=shift(@results);
 is(ref($pars), 'HASH');
 is(join(' ', sort keys %$pars), 'value var');
 is($pars->{var}, 'toBeRestored1');
 is($pars->{value}, 'newValue1');
}
is(shift(@results), $_) foreach (DIRECTIVE_VARSET, DIRECTIVE_START);
{
 my $pars=shift(@results);
 is(ref($pars), 'HASH');
 is(join(' ', sort keys %$pars), 'value var');
 is($pars->{var}, 'toBeRestored2');
 is($pars->{value}, 'newValue2');
}
is(shift(@results), $_) foreach (DIRECTIVE_VARSET, DIRECTIVE_START);
{
 my $pars=shift(@results);
 is(ref($pars), 'HASH');
 is(join(' ', sort keys %$pars), 'value var');
 is($pars->{var}, 'canBeOverwritten');
 is($pars->{value}, 'newValue3');
}

# in the nested source
is(shift(@results), $_) foreach (DIRECTIVE_TEXT, DIRECTIVE_START);
is(shift(@results), $_) foreach (DIRECTIVE_SIMPLE, DIRECTIVE_START, 'Values inside nested source');
is(shift(@results), $_) foreach (DIRECTIVE_SIMPLE, DIRECTIVE_START, q(: "));
is(shift(@results), $_) foreach (DIRECTIVE_SIMPLE, DIRECTIVE_START, q(newValue1));
is(shift(@results), $_) foreach (DIRECTIVE_SIMPLE, DIRECTIVE_START, q(", "));
is(shift(@results), $_) foreach (DIRECTIVE_SIMPLE, DIRECTIVE_START, q(newValue2));
is(shift(@results), $_) foreach (DIRECTIVE_SIMPLE, DIRECTIVE_START, q(", "));
is(shift(@results), $_) foreach (DIRECTIVE_SIMPLE, DIRECTIVE_START, q(newValue3));
is(shift(@results), $_) foreach (DIRECTIVE_SIMPLE, DIRECTIVE_START, q(".));
is(shift(@results), $_) foreach (DIRECTIVE_TEXT, DIRECTIVE_COMPLETE);

# internal variable is set
is(shift(@results), $_) foreach (DIRECTIVE_VARSET, DIRECTIVE_START);
{
 my $pars=shift(@results);
 is(ref($pars), 'HASH');
 is(join(' ', sort keys %$pars), 'value var');
 is($pars->{var}, '_SOURCE_LEVEL');
 is($pars->{value}, 1);
}

# variables are restored
is(shift(@results), $_) foreach (DIRECTIVE_VARSET, DIRECTIVE_START);
{
 my $pars=shift(@results);
 is(ref($pars), 'HASH');
 is(join(' ', sort keys %$pars), 'value var');
 is($pars->{var}, 'toBeRestored1');
 is($pars->{value}, 'value1');
}
is(shift(@results), $_) foreach (DIRECTIVE_VARSET, DIRECTIVE_START);
{
 my $pars=shift(@results);
 is(ref($pars), 'HASH');
 is(join(' ', sort keys %$pars), 'value var');
 is($pars->{var}, 'toBeRestored2');
 is($pars->{value}, 'value2');
}

# restored values
is(shift(@results), $_) foreach (DIRECTIVE_TEXT, DIRECTIVE_START);
is(shift(@results), $_) foreach (DIRECTIVE_SIMPLE, DIRECTIVE_START, 'After 2nd inclusion');
is(shift(@results), $_) foreach (DIRECTIVE_SIMPLE, DIRECTIVE_START, q(: "));
is(shift(@results), $_) foreach (DIRECTIVE_SIMPLE, DIRECTIVE_START, q(value1));
is(shift(@results), $_) foreach (DIRECTIVE_SIMPLE, DIRECTIVE_START, q(", "));
is(shift(@results), $_) foreach (DIRECTIVE_SIMPLE, DIRECTIVE_START, q(value2));
is(shift(@results), $_) foreach (DIRECTIVE_SIMPLE, DIRECTIVE_START, q(", "));
is(shift(@results), $_) foreach (DIRECTIVE_SIMPLE, DIRECTIVE_START, q(newValue3));
is(shift(@results), $_) foreach (DIRECTIVE_SIMPLE, DIRECTIVE_START, q(".));
is(shift(@results), $_) foreach (DIRECTIVE_TEXT, DIRECTIVE_COMPLETE);

is(shift(@results), $_) foreach (DIRECTIVE_DOCUMENT, DIRECTIVE_COMPLETE, 'include3.pp');


# SUBROUTINES ###############################################################################

# headline handler: store what you found
sub handler
 {
  # simply store what you received
  push(@results, @_);
 }
