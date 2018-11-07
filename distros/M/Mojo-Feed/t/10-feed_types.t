use Mojo::Base -strict;
use Mojo::Feed::Reader;
use Mojo::File;
use Test::More;

my $samples = Mojo::File->new('t', 'samples');

#for my $file ($samples->list->each) {
#  say $file->basename, qq{\t}, Mojo::Feed->new(body => $file->slurp)->feed_type;
#}
my %tests = (
'plasmastrum.xml' => 'Atom 1.0',
'atom.xml' => 'Atom 0.3',
'rss10-invalid-date.xml' => 'RSS 1.0',
'rss20.xml' => 'RSS 2.0'
);

for my $file (sort keys %tests) {
  my $f = Mojo::Feed->new(body => $samples->child($file)->slurp);
  is($f->feed_type, $tests{$file}, $tests{$file});
}

done_testing();
