use strictures 1;
use Benchmark ':all';

require POE::Filter::IRCD;
require POE::Filter::IRCv3;
my $old = POE::Filter::IRCD->new;
my $new = POE::Filter::IRCv3->new;

my $basic = ':test!me@test.ing PRIVMSG #Test :This is a test';

my $tagged_with_escapes =
  '@foo=bar\nb\0az\\quux;meh=bork stuff';

my $tagged_without_escapes =
  '@foo=barbazquux;meh=bork stuff';


sub test {
    $new->get([$basic]);
    $new->get([':foo bar']);
    $new->get(['@foo=bar;baz :test PRIVMSG #quux :chickens. ']);

    sub {
      my $ev = $new->get([$tagged_with_escapes]);
      my $raw = $new->put([@$ev]);
    }->();
    
    sub {
      my $ev = $new->get([$tagged_without_escapes]);
      my $raw = $new->put([@$ev]);
    }->();
}

test for 1 .. 40_000;
