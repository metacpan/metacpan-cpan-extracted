# Tests for Net::RGTP          -*- cperl -*-
#
# This program is free software; you may distribute it under the same
# conditions as Perl itself.
#
# Copyright (c) 2005 Thomas Thurman <marnanel@marnanel.org>

use Test::More tests => 21;
use strict;
use warnings;
use Net::RGTP;

################################################################
#
# A number of these tests require a certain predictable state on the
# GROGGS dev server (rgtp://rgtp-serv.groggs.group.cam.ac.uk:1432).
#
# This isn't the most elegant way of testing, because someone could
# theoretically come along with editor powers and (say) change the index,
# which would cause such a test always to fail. We need to think up a more
# general solution, but this will do for now.
#
# It will become easier to construct more general tests when Net::RGTP
# supports posting.
#
################################################################

ok(1, "loaded Net::RGTP");

################################################################
# CONNECTION AND LOGIN

my $rgtp = Net::RGTP->new(Port=>1432,
			  #Debug=>1
			  );
ok(defined $rgtp, 'Connected to dev server');

die "not connected" unless $rgtp;
ok($rgtp->access_level==0, 'Connected at level 0');

# As mentioned above, this requires the existence of this
# real account on the dev server.
$rgtp->login('perltest@example.com', 'EFC8258C02690015')
  or die "Can't log in: $@";
ok($rgtp->access_level!=0, 'Login with real account');

$rgtp = Net::RGTP->new(Port=>1432,
		       #Debug=>1
		      );
$rgtp->login # user 'guest', no password
  or die "Can't log in: $@";
ok($rgtp->access_level==1, "Guest becomes level 1");

################################################################
# TEST "items"

my $items = $rgtp->items or die "Can't get index: $@";

# Test the existence of a known item.

ok($items->{'S1672138'}{'parent'}    eq 'S2291319' , 'Item parent');
ok($items->{'S1672138'}{'child'}     eq 'S1491219' , 'Item child');
ok($items->{'S1672138'}{'posts'}     == 13         , 'Item post count');
ok($items->{'S1672138'}{'seq'}       == 640        , 'Item last sequence');
ok($items->{'S1672138'}{'subject'}   eq 'And so it passes into a continuation',
   'Item title');
ok($items->{'S1672138'}{'timestamp'} == 1061212751 , 'Item last timestamp');

################################################################
# TEST "item"

my $R1262220 = $rgtp->item('R1262220') or die "Can't get item: $@";
ok($R1262220->{'parent'} eq 'R1262059', 'Post parent');
ok($R1262220->{'posts'}[0]->{'text'} =~ /If you use a proportional font/,
   'First post');
ok($R1262220->{'posts'}[1]->{'text'} =~ /spurious error messages/,
   'Second post');

################################################################
# TEST "quick_item" (a.k.a. "STAT")

my $stat = $rgtp->quick_item('K2622347') or die "Can't stat item: $@";

ok($stat->{'reply'} == 408, 'quick_item reply seq');
ok($stat->{'parent'} eq 'K2622248', 'quick_item parent');
ok($stat->{'child'} eq 'K2630044', 'quick_item child');
ok($stat->{'subject'} eq 'Fish (2)', 'quick_item subject');

################################################################
# TEST "motd"

# This is a more general test, because it only checks that there *is* a MOTD.
my $motd = $rgtp->motd or die "Can't get MOTD: $@";
ok(defined $motd->{'posts'}[0]->{'seq'}, 'MOTD sequence');
ok(defined $motd->{'posts'}[0]->{'timestamp'}, 'MOTD timestamp');
ok(defined $motd->{'posts'}[0]->{'text'}, 'MOTD text');

################################################################
# End of tests.
