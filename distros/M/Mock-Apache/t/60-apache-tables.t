#!/usr/bin/env perl

use strict;

use Test::More;
use FindBin qw($Bin);
use lib "$Bin/../lib";

use Mock::Apache;
use Apache::Constants qw(:common);
use Readonly;

# set to 0 (no debug), 1 (methods traced), 2 (methods and callers traced)
Readonly my $DEBUG_LEVEL => 0;

my $mock_apache = Mock::Apache->setup_server(DEBUG => $DEBUG_LEVEL);
my $mock_client = $mock_apache->mock_client();


diag "testing Apache::Table emulation";

$mock_apache->execute_handler(\&handler1, $mock_client, GET => 'http://example.com/index.html');

done_testing();


sub handler1 {
    my $r = shift;

    $DB::single=1;

    # Store data in a normal Apache::Table and in a pnotes table
    my $href = {};
    $r->notes(test_note => $href);
    $r->pnotes(test_pnote => $href);
    $href->{answer} = 42;


    # Retrieve the data
    my $note  = $r->notes('test_note');
    my $pnote = $r->pnotes('test_pnote');

    ok(!ref $note, 'note is not a reference');
    like($note, qr{ \A HASH \( 0x[[:xdigit:]]+ \) \z }x, 'note is stringified hash ref');
    is(ref $pnote, 'HASH', 'pnote is a hashref');
    is($pnote->{answer}, 42, 'pnote hashref element');

    return OK;
}


