package Tak::REPL;

use Term::ReadLine;
use Moo;

has client => (is => 'ro', required => 1);

sub run {
  my $client = $_[0]->client;
  my $read = Term::ReadLine->new('REPL');

  while (1) {
    my $line = $read->readline('re.pl$ ');
    last unless defined $line;
    next unless length $line;
    my $result = $client->do(eval => $line);
    print exists($result->{return})
            ? $result->{return}
            : "Error: ".$result->{exception};
    if ($result->{stdout}) {
      chomp($result->{stdout});
      print "STDOUT:\n${\$result->{stdout}}\n";
    }
    if ($result->{stderr}) {
      chomp($result->{stderr});
      print "STDERR:\n${\$result->{stderr}}\n";
    }
  }
}

1;
