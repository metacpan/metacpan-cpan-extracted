
BEGIN {
  unless ($ENV{AUTHOR_TESTING}) {
    print qq{1..0 # SKIP these tests are for testing by the author\n};
    exit
  }
}

use strict;
use warnings;

# this test was generated with Dist::Zilla::Plugin::Test::EOL 0.19

use Test::More 0.88;
use Test::EOL;

my @files = (
    'lib/RT/Client/REST.pm',
    'lib/RT/Client/REST/Attachment.pm',
    'lib/RT/Client/REST/Exception.pm',
    'lib/RT/Client/REST/Forms.pm',
    'lib/RT/Client/REST/Group.pm',
    'lib/RT/Client/REST/HTTPClient.pm',
    'lib/RT/Client/REST/Object.pm',
    'lib/RT/Client/REST/Object/Exception.pm',
    'lib/RT/Client/REST/Queue.pm',
    'lib/RT/Client/REST/SearchResult.pm',
    'lib/RT/Client/REST/Ticket.pm',
    'lib/RT/Client/REST/Transaction.pm',
    'lib/RT/Client/REST/User.pm'
);

eol_unix_ok($_, { trailing_whitespace => 1 }) foreach @files;
done_testing;
