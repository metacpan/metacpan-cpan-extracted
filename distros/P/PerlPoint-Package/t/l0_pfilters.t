

# = HISTORY SECTION =====================================================================

# ---------------------------------------------------------------------------------------
# version | date     | author   | changes
# ---------------------------------------------------------------------------------------
# 0.01    |26.02.2002| JSTENZEL | new.
# ---------------------------------------------------------------------------------------

# PerlPoint test script


# pragmata
use strict;
use vars qw(@results);
use lib qw(t);

# helper lib
use testlib;

# load modules
use Cwd;
use Carp;
use Safe;
use Test::More qw(no_plan);
use PerlPoint::Backend;
use PerlPoint::Constants;
use PerlPoint::Parser 0.37;
use PerlPoint::Tags;                # perl 5.005 needs this
use PerlPoint::Tags::Basic;

# declare test tags

# declare variables
my (@streamData);

# build parser
my ($parser)=new PerlPoint::Parser;

# and call it
$parser->run(
             stream        => \@streamData,
             files         => ['t/pfilters.pp'],
             safe          => new Safe,
             trace         => TRACE_NOTHING,
             display       => DISPLAY_NOINFO,
            );

# build a backend
my $backend=new PerlPoint::Backend(
                                   name    => 'installation test: paragraph filters',
                                   trace   => TRACE_NOTHING,
                                   display => DISPLAY_NOINFO,
                                  );

# register a complete set of backend handlers
$backend->register($_, \&handler) foreach (DIRECTIVE_BLOCK .. DIRECTIVE_SIMPLE);

# now run the backend
$backend->run(\@streamData);

# checks
is(shift(@results), $_) foreach (DIRECTIVE_DOCUMENT, DIRECTIVE_START, 'pfilters.pp');


# shared tests (used by other test scripts as well and therefore imported)
# ------------------------------------------------------------------------
# {_STARTDIR=>cwd(), _PARSER_VERSION=>$PerlPoint::Parser::VERSION, _SOURCE_LEVEL=>1, multiline=>'one line next line 3rd line', number=>17, value=>'3rd', words=>'words words words', string2=>'\'single quotes\'', word=>'word', string1=>'"double quotes"', nested1=>'word 3rd', nested2=>'17 word 3rd 17'}
pfilterChecks(\@results, 1, 1, {_STARTDIR=>cwd(), _PARSER_VERSION=>$PerlPoint::Parser::VERSION, _SOURCE_LEVEL=>1});

# filtered block at document source end
is(shift(@results), $_) foreach (DIRECTIVE_BLOCK, DIRECTIVE_START);
is(shift(@results), $_) foreach (DIRECTIVE_SIMPLE, DIRECTIVE_START, '  ');
is(shift(@results), $_) foreach (DIRECTIVE_SIMPLE, DIRECTIVE_START, '40: A filtered block');
is(shift(@results), $_) foreach (DIRECTIVE_SIMPLE, DIRECTIVE_START, "\n");
is(shift(@results), $_) foreach (DIRECTIVE_SIMPLE, DIRECTIVE_START, '  ');
is(shift(@results), $_) foreach (DIRECTIVE_SIMPLE, DIRECTIVE_START, '41: at the end of a document (no subsequent lines).');
is(shift(@results), $_) foreach (DIRECTIVE_BLOCK, DIRECTIVE_COMPLETE);


is(shift(@results), $_) foreach (DIRECTIVE_DOCUMENT, DIRECTIVE_COMPLETE, 'pfilters.pp');


# SUBROUTINES ###############################################################################

# handler: store what you found
sub handler
 {
  # simply store what you received
  push(@results, @_);
 }
