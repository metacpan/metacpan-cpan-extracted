
# = HISTORY SECTION =====================================================================

# ---------------------------------------------------------------------------------------
# version | date     | author   | changes
# ---------------------------------------------------------------------------------------
# 0.02    |27.12.2004| JSTENZEL | adapted to Package 0.40;
# 0.01    |02.03.2002| JSTENZEL | new.
# ---------------------------------------------------------------------------------------

# PerlPoint test script


# pragmata
use strict;
use vars qw(@results);
use lib qw(t);

# helper module
use testlib;

# load modules
use Cwd;
use Carp;
use Safe;
use Test::More qw(no_plan);
use PerlPoint::Parser 0.37;
use PerlPoint::Backend 0.11;
use PerlPoint::Constants 0.16;

# declare variables
my (@streamData);

# build parser
my ($parser)=new PerlPoint::Parser;

# and call it
$parser->run(
             stream          => \@streamData,
             files           => ['t/docstreams.pp'],
             filter          => 'pp|perl|anything',
             docstreams2skip => ['The ignored docstream'],
             docstreaming    => DSTREAM_DEFAULT,
             safe            => new Safe,
             trace           => TRACE_NOTHING,
             display         => DISPLAY_NOINFO+DISPLAY_NOWARN,
            );

# build a backend
my $backend=new PerlPoint::Backend(
                                   name    => 'installation test: document streams',
                                   trace   => TRACE_NOTHING,
                                   display => DISPLAY_NOINFO,
                                  );

# register a complete set of backend handlers
$backend->register($_, \&handler) foreach (
                                           DIRECTIVE_BLOCK,
                                           DIRECTIVE_COMMENT,
                                           DIRECTIVE_DOCUMENT,
                                           DIRECTIVE_DPOINT,
                                           DIRECTIVE_DSTREAM_ENTRYPOINT,
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

# bind the backend to the stream and query the document stream titles
$backend->bind(\@streamData);
my @docstreams=sort $backend->docstreams;

# check the docstream summary
is(scalar(@docstreams), 2);
is($docstreams[0], 'The 2nd object');
is($docstreams[1], 'The first object');

# now run the backend
$backend->run(\@streamData);

# perform data stream checks
is(shift(@results), $_) foreach (DIRECTIVE_DOCUMENT, DIRECTIVE_START, 'docstreams.pp');

# docstream tests
# ------------------------
docstreamDefaultChecks(\@results, 1, 1, {_STARTDIR=>cwd(), _PARSER_VERSION=>$PerlPoint::Parser::VERSION, _SOURCE_LEVEL=>1});

is(shift(@results), $_) foreach (DIRECTIVE_DOCUMENT, DIRECTIVE_COMPLETE, 'docstreams.pp');


# SUBROUTINES ###############################################################################

# headline handler: store what you found
sub handler
 {
  # simply store what you received
  push(@results, @_);
 }
