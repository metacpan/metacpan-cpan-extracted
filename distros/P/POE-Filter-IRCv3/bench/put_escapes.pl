use strictures 1;
use Benchmark ':all';

require POE::Filter::IRCv3;
my $new = POE::Filter::IRCv3->new;

my $tagged_with_escapes =
  '@foo=bar\nb\0az\\quux;meh=bork stuff';

my $tagged_without_escapes =
  '@foo=barbazquux;meh=bork stuff';

cmpthese( 100_000, +{
  WithEscapes => sub {
    my $ev = $new->get([$tagged_with_escapes]);
    my $raw = $new->put([@$ev]);
  },
  NoEscapes => sub {
    my $ev = $new->get([$tagged_without_escapes]);
    my $raw = $new->put([@$ev]);
  },
});
