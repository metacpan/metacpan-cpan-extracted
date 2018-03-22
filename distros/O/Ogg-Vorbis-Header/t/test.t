
use strict;
use warnings;

use Test::More;
use FindBin '$Bin';
BEGIN { use_ok 'Ogg::Vorbis::Header'; }

# See if partial load works
ok(my $ogg = Ogg::Vorbis::Header->new("$Bin/test.ogg"));

# See if load_after works
ok($ogg->load);

# Try all the routines
is($ogg->info->{"rate"}, 44_100);
ok($ogg->comment_tags);
is(($ogg->comment("artist"))[0], "Dan");
ok($ogg->add_comments("moog", "bog"));
ok($ogg->edit_comment("moog", "bug"));
ok($ogg->delete_comment("artist"));
ok($ogg->write_vorbis);
system("cp $Bin/test.ogg $Bin/test.ogg.2");
system("cp $Bin/test.ogg.bak $Bin/test.ogg");
ok($ogg->clear_comments);

# See if full load works
ok(my $ogg2 = Ogg::Vorbis::Header->load("$Bin/test.ogg.2"));
is(($ogg2->comment("moog"))[0], "bug");

unlink("$Bin/test.ogg.2");

done_testing();
