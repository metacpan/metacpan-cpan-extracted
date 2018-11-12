
BEGIN {
  unless ($ENV{AUTHOR_TESTING}) {
    print qq{1..0 # SKIP these tests are for testing by the author\n};
    exit
  }
}

use strict;
use warnings;

# this test was generated with Dist::Zilla::Plugin::Test::NoTabs 0.15

use Test::More 0.88;
use Test::NoTabs;

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
    'lib/RT/Client/REST/User.pm',
    't/00-compile.t',
    't/00-report-prereqs.dd',
    't/00-report-prereqs.t',
    't/01-use.t',
    't/10-core.t',
    't/11-server-name.t',
    't/20-object.t',
    't/21-user.t',
    't/22-ticket.t',
    't/23-attachment.t',
    't/24-transaction.t',
    't/25-queue.t',
    't/26-group.t',
    't/35-db.t',
    't/40-search.t',
    't/50-forms.t',
    't/60-with-rt.t',
    't/80-timeout.t',
    't/81-submit.t',
    't/82-stringify.t',
    't/83-attachments.t',
    't/84-attachments-rt127607.t',
    't/85-attachments-rt127607.t',
    't/author-critic.t',
    't/author-eof.t',
    't/author-eol.t',
    't/author-no-breakpoints.t',
    't/author-no-tabs.t',
    't/author-pod-coverage.t',
    't/author-pod-spell.t',
    't/author-pod-syntax.t',
    't/author-portability.t',
    't/release-distmeta.t',
    't/release-kwalitee.t',
    't/release-pause-permissions.t',
    't/release-unused-vars.t'
);

notabs_ok($_) foreach @files;
done_testing;
