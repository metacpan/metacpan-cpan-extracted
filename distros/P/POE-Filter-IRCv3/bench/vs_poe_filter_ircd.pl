use strictures 1;
use Benchmark ':all';


use POE::Filter::IRCD 2.44;
use POE::Filter::IRCv3;

my ($old, $new);
print " -> object construction <- \n";
cmpthese( 500_000, +{
  ircv3  => sub { $new = POE::Filter::IRCv3->new },
  ircd   => sub { $old = POE::Filter::IRCD->new  }
});

{
  my $basic = ':test!me@test.ing PRIVMSG #Test :This is a test'
              .' but not of the emergency broadcast system'
              .' foo bar baz quux snarf';

  print " -> common string get() <- \n";

  my ($ev_new, $ev_old);
  cmpthese( 500_000, +{
    ircv3  => sub { $ev_new = $new->get([ $basic ]) },
    ircd   => sub { $ev_old = $old->get([ $basic ]) }
  });


  print " -> common string put() <- \n";

  cmpthese( 500_000, +{
    ircv3 => sub { my $lines = $new->put([ @$ev_new ]) },
    ircd  => sub { my $lines = $old->put([ @$ev_old ]) }
  });
}

{
  my $multiparam = ':test!me@test.ing foo bar baz quux frobulate snack';

  print " -> multi-param string get() <- \n";

  my ($ev_new, $ev_old);
  cmpthese( 500_000, +{
    ircv3  => sub { $ev_new = $new->get([ $multiparam ]) },
    ircd   => sub { $ev_old = $old->get([ $multiparam ]) }
  });


  print " -> multi-param string put() <- \n";

  cmpthese( 500_000, +{
    ircv3 => sub { my $lines = $new->put([ @$ev_new ]) },
    ircd  => sub { my $lines = $old->put([ @$ev_old ]) }
  });
}

{
  my $tagged = '@foo=bar;baz :foo bar baz';

  print " -> tagged + prefix get() <- \n";

  my ($ev_new, $ev_old);
  cmpthese( 500_000, +{
    ircv3 => sub { $ev_new = $new->get([ $tagged ]) },
    ircd  => sub { $ev_old = $old->get([ $tagged ]) }
  });

  print " -> tagged + prefix put() <- \n";

  cmpthese( 500_00, +{
    ircv3 => sub { my $lines = $new->put([ @$ev_new ]) },
    ircd  => sub { my $lines = $old->put([ @$ev_old ]) },
  });
}

