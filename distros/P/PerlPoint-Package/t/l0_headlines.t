

# = HISTORY SECTION =====================================================================

# ---------------------------------------------------------------------------------------
# version | date     | author   | changes
# ---------------------------------------------------------------------------------------
# 0.08    |27.12.2004| JSTENZEL | adapted to new headline path data;
#         |27.02.2005| JSTENZEL | adapted to fixed variable handling, see parser log;
# 0.07    |31.08.2002| JSTENZEL | adapted to extended tag streaming (body hint);
# 0.06    |27.09.2001| JSTENZEL | switched to Test::More;
#         |          | JSTENZEL | tests were really basic, improved;
#         |          | JSTENZEL | adapted to shortcuts;
#         |15.04.2002| JSTENZEL | adapted to chapter docstream hints;
# 0.05    |16.08.2001| JSTENZEL | no need to build a Safe object;
# 0.04    |20.03.2001| JSTENZEL | adapted to tag templates;
# 0.03    |09.12.2000| JSTENZEL | new namespace: "PP" => "PerlPoint";
# 0.02    |05.10.2000| JSTENZEL | parser takes a Safe object now;
# 0.01    |08.04.2000| JSTENZEL | new.
# ---------------------------------------------------------------------------------------

# PerlPoint test script


# pragmata
use strict;
use lib qw(t);

# helper lib
use testlib;

# load modules
use Cwd;
use Carp;
use Test::More qw(no_plan);
use PerlPoint::Backend;
use PerlPoint::Parser 0.37;
use PerlPoint::Tags;                # perl 5.005 needs this
use PerlPoint::Tags::Basic;
use PerlPoint::Constants;

# declare variables
my (@streamData, @results);

# build parser
my ($parser)=new PerlPoint::Parser;

# and call it
$parser->run(
             stream  => \@streamData,
             files   => ['t/headlines.pp'],
             safe    => undef,
             trace   => TRACE_NOTHING,
             display => DISPLAY_NOINFO+DISPLAY_NOWARN,
            );

# build a backend
my $backend=new PerlPoint::Backend(
                                   name    =>'installation test: headlines',
                                   trace   =>TRACE_NOTHING,
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

# now run the backends
$backend->run(\@streamData);

# perform checks
is(shift(@results), $_) foreach (DIRECTIVE_DOCUMENT, DIRECTIVE_START, 'headlines.pp');

# variable hash
my $varhash={_STARTDIR=>cwd(), _PARSER_VERSION=>$PerlPoint::Parser::VERSION, _SOURCE_LEVEL=>1};

# level recognition
is(shift(@results), $_) foreach (DIRECTIVE_HEADLINE, DIRECTIVE_START, 1, 'A simple headline, 1st level', '');
{
 my $docstreams=shift(@results);
 is(ref($docstreams), 'ARRAY');
 is(join(' ', @$docstreams), '');
 checkHeadline(\@results, 1, ['A simple headline, 1st level'], ['A simple headline, 1st level'], [1], [1], $varhash);
}
is(shift(@results), $_) foreach (DIRECTIVE_SIMPLE, DIRECTIVE_START, 'A simple headline, 1st level');
is(shift(@results), $_) foreach (DIRECTIVE_HEADLINE, DIRECTIVE_COMPLETE, 1);

is(shift(@results), $_) foreach (DIRECTIVE_HEADLINE, DIRECTIVE_START, 2, '2nd level', '');
{
 my $docstreams=shift(@results);
 is(ref($docstreams), 'ARRAY');
 is(join(' ', @$docstreams), '');
 checkHeadline(\@results, 2, ['A simple headline, 1st level', '2nd level'], ['A simple headline, 1st level', '2nd level'], [1, 1], [1, 2], $varhash);
}
is(shift(@results), $_) foreach (DIRECTIVE_SIMPLE, DIRECTIVE_START, '2nd level');
is(shift(@results), $_) foreach (DIRECTIVE_HEADLINE, DIRECTIVE_COMPLETE, 2);

is(shift(@results), $_) foreach (DIRECTIVE_HEADLINE, DIRECTIVE_START, 3, '3rd level', '');
{
 my $docstreams=shift(@results);
 is(ref($docstreams), 'ARRAY');
 is(join(' ', @$docstreams), '');
 checkHeadline(\@results, 3, ['A simple headline, 1st level', '2nd level', '3rd level'], ['A simple headline, 1st level', '2nd level', '3rd level'], [1, 1, 1], [1, 2, 3], $varhash);
}
is(shift(@results), $_) foreach (DIRECTIVE_SIMPLE, DIRECTIVE_START, '3rd level');
is(shift(@results), $_) foreach (DIRECTIVE_HEADLINE, DIRECTIVE_COMPLETE, 3);

is(shift(@results), $_) foreach (DIRECTIVE_HEADLINE, DIRECTIVE_START, 30, '30th level', '');
{
 my $docstreams=shift(@results);
 is(ref($docstreams), 'ARRAY');
 is(join(' ', @$docstreams), '');
 checkHeadline(\@results, 30, ['A simple headline, 1st level', '2nd level', '3rd level', (undef) x 26, '30th level'], ['A simple headline, 1st level', '2nd level', '3rd level', (undef) x 26, '30th level'], [1, 1, 1, (undef) x 26, 1], [1, 2, 3, (undef) x 26, 4], $varhash);
}
is(shift(@results), $_) foreach (DIRECTIVE_SIMPLE, DIRECTIVE_START, '30th level');
is(shift(@results), $_) foreach (DIRECTIVE_HEADLINE, DIRECTIVE_COMPLETE, 30);

# line combination and paragraph termination
is(shift(@results), $_) foreach (DIRECTIVE_HEADLINE, DIRECTIVE_START, 1, 'Single line', '');
{
 my $docstreams=shift(@results);
 is(ref($docstreams), 'ARRAY');
 is(join(' ', @$docstreams), '');
 checkHeadline(\@results, 1, ['Single line'], ['Single line'], [2], [5], $varhash);
}
is(shift(@results), $_) foreach (DIRECTIVE_SIMPLE, DIRECTIVE_START, 'Single line');
is(shift(@results), $_) foreach (DIRECTIVE_HEADLINE, DIRECTIVE_COMPLETE, 1);

is(shift(@results), $_) foreach (DIRECTIVE_HEADLINE, DIRECTIVE_START, 2, 'Multiple line', '');
{
 my $docstreams=shift(@results);
 is(ref($docstreams), 'ARRAY');
 is(join(' ', @$docstreams), '');
 checkHeadline(\@results, 2, ['Single line', 'Multiple line'], ['Single line', 'Multiple line'], [2, 1], [5, 6], $varhash);
}
is(shift(@results), $_) foreach (DIRECTIVE_SIMPLE, DIRECTIVE_START, 'Multiple');
is(shift(@results), $_) foreach (DIRECTIVE_SIMPLE, DIRECTIVE_START, ' ');
is(shift(@results), $_) foreach (DIRECTIVE_SIMPLE, DIRECTIVE_START, 'line');
is(shift(@results), $_) foreach (DIRECTIVE_HEADLINE, DIRECTIVE_COMPLETE, 2);

is(shift(@results), $_) foreach (DIRECTIVE_HEADLINE, DIRECTIVE_START, 3, 'Multiple ===line (should be detected as ONE paragraph)', '');
{
 my $docstreams=shift(@results);
 is(ref($docstreams), 'ARRAY');
 is(join(' ', @$docstreams), '');
 checkHeadline(\@results, 3, ['Single line', 'Multiple line', 'Multiple ===line (should be detected as ONE paragraph)'], ['Single line', 'Multiple line', 'Multiple ===line (should be detected as ONE paragraph)'], [2, 1, 1], [5, 6, 7], $varhash);
}
is(shift(@results), $_) foreach (DIRECTIVE_SIMPLE, DIRECTIVE_START, 'Multiple');
is(shift(@results), $_) foreach (DIRECTIVE_SIMPLE, DIRECTIVE_START, ' ');
is(shift(@results), $_) foreach (DIRECTIVE_SIMPLE, DIRECTIVE_START, '===line (should be detected as ONE paragraph)');
is(shift(@results), $_) foreach (DIRECTIVE_HEADLINE, DIRECTIVE_COMPLETE, 3);

is(shift(@results), $_) foreach (DIRECTIVE_HEADLINE, DIRECTIVE_START, 4, 'Really heavy multiple headline (all lines complete the SAME paragraph)', '');
{
 my $docstreams=shift(@results);
 is(ref($docstreams), 'ARRAY');
 is(join(' ', @$docstreams), '');
 checkHeadline(\@results, 4, ['Single line', 'Multiple line', 'Multiple ===line (should be detected as ONE paragraph)', 'Really heavy multiple headline (all lines complete the SAME paragraph)'], ['Single line', 'Multiple line', 'Multiple ===line (should be detected as ONE paragraph)', 'Really heavy multiple headline (all lines complete the SAME paragraph)'], [2, 1, 1, 1], [5, 6, 7, 8], $varhash);
}
is(shift(@results), $_) foreach (DIRECTIVE_SIMPLE, DIRECTIVE_START, 'Really');
is(shift(@results), $_) foreach (DIRECTIVE_SIMPLE, DIRECTIVE_START, ' ');
is(shift(@results), $_) foreach (DIRECTIVE_SIMPLE, DIRECTIVE_START, 'heavy');
is(shift(@results), $_) foreach (DIRECTIVE_SIMPLE, DIRECTIVE_START, ' ');
is(shift(@results), $_) foreach (DIRECTIVE_SIMPLE, DIRECTIVE_START, 'multiple');
is(shift(@results), $_) foreach (DIRECTIVE_SIMPLE, DIRECTIVE_START, ' ');
is(shift(@results), $_) foreach (DIRECTIVE_SIMPLE, DIRECTIVE_START, 'headline');
is(shift(@results), $_) foreach (DIRECTIVE_SIMPLE, DIRECTIVE_START, ' ');
is(shift(@results), $_) foreach (DIRECTIVE_SIMPLE, DIRECTIVE_START, '(all lines complete the SAME paragraph)');
is(shift(@results), $_) foreach (DIRECTIVE_HEADLINE, DIRECTIVE_COMPLETE, 4);

# trailing whitespace handling
is(shift(@results), $_) foreach (DIRECTIVE_HEADLINE, DIRECTIVE_START, 1, 'No trailing whitespace', '');
{
 my $docstreams=shift(@results);
 is(ref($docstreams), 'ARRAY');
 is(join(' ', @$docstreams), '');
 checkHeadline(\@results, 1, ['No trailing whitespace'], ['No trailing whitespace'], [3], [9], $varhash);
}
is(shift(@results), $_) foreach (DIRECTIVE_SIMPLE, DIRECTIVE_START, 'No trailing whitespace');
is(shift(@results), $_) foreach (DIRECTIVE_HEADLINE, DIRECTIVE_COMPLETE, 1);

is(shift(@results), $_) foreach (DIRECTIVE_HEADLINE, DIRECTIVE_START, 2, 'A trailing whitespace', '');
{
 my $docstreams=shift(@results);
 is(ref($docstreams), 'ARRAY');
 is(join(' ', @$docstreams), '');
 checkHeadline(\@results, 2, ['No trailing whitespace', 'A trailing whitespace'], ['No trailing whitespace', 'A trailing whitespace'], [3, 1], [9, 10], $varhash);
}
is(shift(@results), $_) foreach (DIRECTIVE_SIMPLE, DIRECTIVE_START, 'A trailing whitespace');
is(shift(@results), $_) foreach (DIRECTIVE_HEADLINE, DIRECTIVE_COMPLETE, 2);

is(shift(@results), $_) foreach (DIRECTIVE_HEADLINE, DIRECTIVE_START, 3, 'Several trailing whitespaces', '');
{
 my $docstreams=shift(@results);
 is(ref($docstreams), 'ARRAY');
 is(join(' ', @$docstreams), '');
 checkHeadline(\@results, 3, ['No trailing whitespace', 'A trailing whitespace', 'Several trailing whitespaces'], ['No trailing whitespace', 'A trailing whitespace', 'Several trailing whitespaces'], [3, 1, 1], [9, 10, 11], $varhash);
}
is(shift(@results), $_) foreach (DIRECTIVE_SIMPLE, DIRECTIVE_START, 'Several trailing whitespaces');
is(shift(@results), $_) foreach (DIRECTIVE_HEADLINE, DIRECTIVE_COMPLETE, 3);

is(shift(@results), $_) foreach (DIRECTIVE_HEADLINE, DIRECTIVE_START, 1, 'A headline with a tag', '');
{
 my $docstreams=shift(@results);
 is(ref($docstreams), 'ARRAY');
 is(join(' ', @$docstreams), '');
 checkHeadline(\@results, 1, ['A headline with a tag'], ['A headline with a tag'], [4], [12], $varhash);
}
is(shift(@results), $_) foreach (DIRECTIVE_SIMPLE, DIRECTIVE_START, 'A headline with ');
is(shift(@results), $_) foreach (DIRECTIVE_TAG, DIRECTIVE_START, 'I');
{
 my $pars=shift(@results);
 is(ref($pars), 'HASH');
 is(join(' ', sort keys %$pars), '');
}
is(shift(@results), 1);
is(shift(@results), $_) foreach (DIRECTIVE_SIMPLE, DIRECTIVE_START, 'a tag');
is(shift(@results), $_) foreach (DIRECTIVE_TAG, DIRECTIVE_COMPLETE, 'I');
{
 my $pars=shift(@results);
 is(ref($pars), 'HASH');
 is(join(' ', sort keys %$pars), '');
}
is(shift(@results), 1);
is(shift(@results), $_) foreach (DIRECTIVE_HEADLINE, DIRECTIVE_COMPLETE, 1);

is(shift(@results), $_) foreach (DIRECTIVE_HEADLINE, DIRECTIVE_START, 1, 'And another one which is so long that we need a shortcut', 'Abbreviated');
{
 my $docstreams=shift(@results);
 is(ref($docstreams), 'ARRAY');
 is(join(' ', @$docstreams), '');
 checkHeadline(\@results, 1, ['And another one which is so long that we need a shortcut'], ['Abbreviated'], [5], [13], $varhash);
}
is(shift(@results), $_) foreach (DIRECTIVE_SIMPLE, DIRECTIVE_START, 'And another one which is so long that we need a shortcut');
is(shift(@results), $_) foreach (DIRECTIVE_HEADLINE, DIRECTIVE_COMPLETE, 1);

is(shift(@results), $_) foreach (DIRECTIVE_HEADLINE, DIRECTIVE_START, 1, "This headlines looks like abbreviated, ~ but actually it's just a usual headline", '');
{
 my $docstreams=shift(@results);
 is(ref($docstreams), 'ARRAY');
 is(join(' ', @$docstreams), '');
 checkHeadline(\@results, 1, ["This headlines looks like abbreviated, ~ but actually it's just a usual headline"], ["This headlines looks like abbreviated, ~ but actually it's just a usual headline"], [6], [14], $varhash);
}
is(shift(@results), $_) foreach (DIRECTIVE_SIMPLE, DIRECTIVE_START, "This headlines looks like abbreviated, ");
is(shift(@results), $_) foreach (DIRECTIVE_SIMPLE, DIRECTIVE_START, "~");
is(shift(@results), $_) foreach (DIRECTIVE_SIMPLE, DIRECTIVE_START, " ");
is(shift(@results), $_) foreach (DIRECTIVE_SIMPLE, DIRECTIVE_START, "but actually it's just a usual headline");
is(shift(@results), $_) foreach (DIRECTIVE_HEADLINE, DIRECTIVE_COMPLETE, 1);

is(shift(@results), $_) foreach (DIRECTIVE_HEADLINE, DIRECTIVE_START, 4, 'A final simple headline (without final carriage return ...)', '');
{
 my $docstreams=shift(@results);
 is(ref($docstreams), 'ARRAY');
 is(join(' ', @$docstreams), '');
 checkHeadline(\@results, 4, ["This headlines looks like abbreviated, ~ but actually it's just a usual headline", (undef) x 2, 'A final simple headline (without final carriage return ...)'], ["This headlines looks like abbreviated, ~ but actually it's just a usual headline", (undef) x 2, 'A final simple headline (without final carriage return ...)'], [6, undef, undef, 1], [14, undef, undef, 15], $varhash);
}
is(shift(@results), $_) foreach (DIRECTIVE_SIMPLE, DIRECTIVE_START, 'A final simple headline (without final carriage return ...)');
is(shift(@results), $_) foreach (DIRECTIVE_HEADLINE, DIRECTIVE_COMPLETE, 4);


is(shift(@results), $_) foreach (DIRECTIVE_DOCUMENT, DIRECTIVE_COMPLETE, 'headlines.pp');


# SUBROUTINES ###############################################################################

# headline handler: store what you found
sub handler
 {
  # simply store what you received
  push(@results, @_);
 }
