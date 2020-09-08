# much of this test code is blatently ripped out of the test code from
# Ogg::Vorbis::Header.
# This is in part due to laziness and in part to try to ensure the
# two modules share the same API.

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

use strict;
use warnings;

use Test::More;
use Ogg::Vorbis::Header::PurePerl;

#########################

# See if partial load works
ok(my $ogg = Ogg::Vorbis::Header::PurePerl->new('t/test.ogg'));

# Try all the routines
is($ogg->info->{'rate'}, 44_100, 'Got rate from hash');
is($ogg->info('rate'), 44_100, 'Got rate from subroutine');
ok($ogg->comment_tags, 'Got comment tags');
is($ogg->comment('artist'), 'maloi', 'Got artist');
is($ogg->path, 't/test.ogg', 'Got path');

my @artists = $ogg->comment('artist');
is(@artists, 1, 'Correct number of artists');
is($artists[0], 'maloi', 'Correct artist');

$ogg = 0;

# See if full load works
ok($ogg = Ogg::Vorbis::Header::PurePerl->new('t/test.ogg'),
   'Got an object');
isa_ok($ogg, 'Ogg::Vorbis::Header::PurePerl');
is($ogg->comment('artist'), 'maloi', 'Got artist again');

# and see if we can get comments including the '=' character
is($ogg->comment('album'), 'this=that', 'Got title');

# Make sure we're getting the right track length
is($ogg->info->{'length'}, 0, 'Got length');

done_testing();
