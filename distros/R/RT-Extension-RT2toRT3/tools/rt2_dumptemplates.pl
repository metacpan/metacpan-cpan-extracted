#!/home/perl/5.8/bin/perl -w

use lib "/home/rt/rt2/lib";
use lib "/home/rt/rt2/etc";

use RT::Interface::CLI  qw(CleanEnv LoadConfig DBConnect 
                           GetCurrentUser GetMessageContent);

LoadConfig();
DBConnect();

use RT::Queues;
use RT::Templates;

sub dump_templates {
  my $templates = new RT::Templates( $RT::SystemUser );
  $templates->UnLimit;

  my $queue = new RT::Queue( $RT::SystemUser );
  my $count = 0;
  while(my $te = $templates->Next) {
    my $qname = "Global";
    $count++;

    if ($te->Queue) {
      $queue->Load($te->Queue);
      $qname = $queue->Name;
    }

    my $name = $qname."::".$te->Name;
    $name =~ s/\s/_/g;
    print "$name\n";

    open(my $out,">$name") or die;
    print $out $te->Content;
    close $out;
  }

  print STDERR "$count templates saved\n";

}


dump_templates();
