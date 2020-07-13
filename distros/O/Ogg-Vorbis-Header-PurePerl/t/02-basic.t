# much of this test code is blatently ripped out of the test code from
# Ogg::Vorbis::Header.
# This is in part due to laziness and in part to try to ensure the
# two modules share the same API.

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

use Test::More tests => 8;
use Ogg::Vorbis::Header::PurePerl;

#########################

# See if partial load works
ok(my $ogg = Ogg::Vorbis::Header::PurePerl->new('t/test.ogg'));

# Try all the routines
ok($ogg->info->{'rate'} == 44100);
ok($ogg->comment_tags);
ok($ogg->comment('artist')->[0] == 'maloi');

$ogg = 0;

# See if full load works
ok(my $ogg = Ogg::Vorbis::Header::PurePerl->new('t/test.ogg'));
ok($ogg->comment('artist')->[0] == 'maloi');

# and see if we can get comments including the '=' character
ok($ogg->comment('album')->[0] == 'this=that');

# Make sure we're getting the right track length
ok($ogg->info->{'length'} == 0);
