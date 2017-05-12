######################################################################
# Test suite for Net::Evernote::Simple
# by Mike Schilli <cpan@perlmeister.com>
######################################################################
use warnings;
use strict;

use Test::More;

plan tests => 3;

use Net::Evernote::Simple;
use Log::Log4perl qw(:easy);
Log::Log4perl->easy_init($ERROR);

my $en = Net::Evernote::Simple->new();

ok 1, "loaded ok";

SKIP: {
    if( !$ENV{ LIVE_TEST } ) {
        skip "LIVE_TEST not set, skipping live tests", 2;
    }

    is $en->version_check(), 1, "version check";

    my $note_store = $en->note_store();

    if( !$note_store ) {
        die "getting notestore failed: $@";
    }

    my $notebooks =
      $note_store->listNotebooks( $en->dev_token() );
    
    ok scalar @$notebooks > 0, "retrieving notebooks";
}
