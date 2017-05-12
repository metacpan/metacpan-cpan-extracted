# Posting tests for Net::RGTP  -*- cperl -*-
#
# This program is free software; you may distribute it under the same
# conditions as Perl itself.
#
# Copyright (c) 2005 Thomas Thurman <marnanel@marnanel.org>

use Test::More tests => 20;
use strict;
use warnings;
use Net::RGTP;
use Data::Dumper;

ok(1, "loaded Net::RGTP");

################################################################
# CONNECTION AND LOGIN

my $rgtp = Net::RGTP->new(Port=>1432,
			  #Debug=>1
			  );
ok(defined $rgtp, 'Connected to dev server');

die "not connected" unless $rgtp;

$rgtp->login('perltest@example.com', 'EFC8258C02690015');
ok($rgtp->access_level!=0, 'Login with real account');

################################################################
# POSTING

my $test_string = rand() . ' ' . rand() . 
<<EOF

. This is a line beginning with a dot.
^ This is a line beginning with a caret.

Sally is gone that was so kindly,
Sally is gone from Ha'nacker Hill,
And the Briar grows ever since then so blindly;
And ever since then the clapper is still...
And the sweeps have fallen from Ha'nacker Mill.

    -- Hillaire Belloc
EOF
;

# FAIL reports always include the platform name, so include $^O so
# we can see which post was the one that failed.

my $subject = 'Net::RGTP test ' . int(rand()*1000) .
  " Does Net::RGTP work on $^O?";

################################################################
# REPLIES

my ($first_itemid, $first_seq) =
  $rgtp->post('new', $test_string,
	      Grogname => 'Automated',
	      Subject => $subject);

ok(defined $first_itemid,    'new item has itemid');
ok(defined $first_seq,       'new item has seq');
ok(!($rgtp->item_is_full),   'new item is not full');
ok(!($rgtp->item_has_grown), 'new item has not grown');

ok($rgtp->post($first_itemid,
	       'This should post because the item has not been replied to',
	       Seq => $first_seq),
  'first post posted');

ok(!($rgtp->item_is_full),   'item is not full');
ok(!($rgtp->item_has_grown), 'item has not grown');

ok(!$rgtp->post($first_itemid,
		'This should not post because the item has been replied to',
		Seq => $first_seq),
  'second post did not post');

ok(!($rgtp->item_is_full),   'item is not full');
ok($rgtp->item_has_grown,    'item has grown');

while (!($rgtp->item_is_full)) {
  $rgtp->post($first_itemid, "Dummy text to fill to continuation\n" x 50);
}

my $second_itemid =
  $rgtp->post('continue', 'And this should begin a brand new item',
	      Grogname => 'Automated',
	      Subject => 'Net::RGTP test: Continuation item');

ok(defined $second_itemid, 'Continuation created');
ok(!($rgtp->item_is_full),   'continuation is not full');
ok(!($rgtp->item_has_grown), 'continuation has not grown');

################################################################
# READING IT BACK

my $first_item = $rgtp->item($first_itemid)
  or die "Can't find first item! $@";
my $second_item = $rgtp->item($second_itemid)
  or die "Can't find second item! $@";

ok($first_item->{'child'} eq $second_itemid,
   'First item\'s child is second item');
ok($second_item->{'parent'} eq $first_itemid,
   'Second item\'s parent is first item');

ok($first_item->{'subject'} eq $subject,
   'Subject came back OK');

ok($first_item->{'posts'}->[0]->{'text'} eq $test_string,
   'First post came back OK');

################################################################
# End of tests.
