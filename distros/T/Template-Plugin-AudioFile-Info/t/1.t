use strict;
use warnings;

use Test::More;
use Template;

my $t = <<'END';
[%- USE song = AudioFile.Info(file, $ext => 'AudioFile::Info::Dummy') -%]
Title:  [% song.title %]
Artist: [% song.artist %]
Album:  [% song.album %] (track [% song.track | format '%1d' %])
Year:   [% song.year %]
Genre:  [% song.genre %]
END

my $out = <<END;
Title:  TITLE
Artist: ARTIST
Album:  ALBUM (track 0)
Year:   YEAR
Genre:  GENRE
END

my $tt = Template->new;

foreach (qw/mp3 ogg/) {
  my $result;
  $tt->process(\$t, {
    file => "t/test.$_",
    ext  => $_,
  }, \$result)
    or die $tt->error;
  is($result, $out, "Tested $_");
}

done_testing;
