# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl test.pl'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

use Test;
BEGIN { plan tests => 13 };
use Ogg::Vorbis::Header;
ok(1); # If we made it this far, we're ok.

#########################

# Insert your test code below, the Test module is use()ed here so read
# its man page ( perldoc Test ) for help writing this test script.


# See if partial load works
ok(my $ogg = Ogg::Vorbis::Header->new("test.ogg"));

# See if load_after works
ok($ogg->load);

# Try all the routines
ok($ogg->info->{"rate"} == 44100);
ok($ogg->comment_tags);
ok(($ogg->comment("artist"))[0] eq "Dan");
ok($ogg->add_comments("moog", "bog"));
ok($ogg->edit_comment("moog", "bug"));
ok($ogg->delete_comment("artist"));
ok($ogg->write_vorbis);
system("cp test.ogg test.ogg.2");
system("cp test.ogg.bak test.ogg");
ok($ogg->clear_comments);

# See if full load works
ok(my $ogg = Ogg::Vorbis::Header->load("test.ogg.2"));
ok(($ogg->comment("moog"))[0] eq "bug");

unlink("test.ogg.2");
