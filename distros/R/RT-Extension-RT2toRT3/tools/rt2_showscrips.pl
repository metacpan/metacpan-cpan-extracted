#!/home/perl/5.8/bin/perl -w

use lib "/home/rt/rt2/lib";
use lib "/home/rt/rt2/etc";

use RT::Interface::CLI  qw(CleanEnv LoadConfig DBConnect 
                           GetCurrentUser GetMessageContent);

LoadConfig();
DBConnect();

use RT::Queues;
use RT::Scrips;
use RT::Templates;

sub dump_scrips {
  my $queueobj = shift;
  my $scrips = new RT::Scrips( $RT::SystemUser );

  if ($queueobj) {
    $scrips->LimitToQueue( $queueobj->id );
    print "* ",$queueobj->Name,"\n";
  } else {
    $scrips->LimitToGlobal( );
    print "* Global\n";
  }

  while(my $sc = $scrips->Next) {
    my $templatename = "Global";
    if ($sc->TemplateObj && $sc->TemplateObj->Queue) {
      $templatename = $sc->QueueObj->Name;
    }
    
    $templatename .= "::".$sc->TemplateObj->Name;
    $templatename =~ s/\s/_/g;

    print
      $sc->ConditionObj->Name, "\t",
	$sc->ActionObj->Name, "\t",
	  $templatename,"\n";
  }
}

# Global
dump_scrips();

my $queues = new RT::Queues( $RT::SystemUser );
$queues->UnLimit;
$queues->First;

while( my $q = $queues->Next ) {
  dump_scrips( $q );
} 
