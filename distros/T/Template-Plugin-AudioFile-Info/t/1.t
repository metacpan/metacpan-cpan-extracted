use Test::More tests => 2;
use Template;

my $t = <<END;
[%- USE song = AudioFile.Info(file) -%]
Title:  [% song.title %]
Artist: [% song.artist %]
Album:  [% song.album %] (track [% song.track | format '%1d' %])
Year:   [% song.year %]
Genre:  [% song.genre %]
END

my $out = <<END;
Title:  test
Artist: davorg
Album:  none (track 0)
Year:   2003
Genre:  nonsense
END

my $tt = Template->new;

foreach (qw/mp3 ogg/) {
  my $result;
  $tt->process(\$t, { file => "t/test.$_" }, \$result)
    or die $tt->error;
  is($result, $out);
}
