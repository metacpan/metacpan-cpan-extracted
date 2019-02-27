# button.pl

use warnings;
use strict;

#use Tk;

use Tcl::pTk;

use Test;

plan test => 3;

my $TOP = MainWindow->new;


	my $b = $TOP->Button( Name => 'btn',
            -text    => "Balloon Test",
            -width   => 10,
        )->pack;
 
# Create a virtual event that will fire when button 1 is pressed
$TOP->eventAdd( qw/ <<pTkRules>> <1> / );

my $virtEventFired = 0;
$TOP->bind('<<pTkRules>>', 
        sub{ 
                $virtEventFired = 1;
                #print STDERR "Event Fired\n"
        });

my @eventInfo = $TOP->eventInfo();
#print "eventInfo = ".join(", ", sort @eventInfo)."\n";
my @match = grep /pTkRules/, @eventInfo; # Look for a match of ptkRules coming back
ok(join(", ", sort @match), '<<pTkRules>>');

@eventInfo = $TOP->eventInfo('<<pTkRules>>');
#print "eventInfo = ".join(", ", @eventInfo)."\n";
ok(join(", ", @eventInfo), '<Button-1>');

$TOP->after(1000, sub{
                $TOP->eventGenerate('<1>', -x => 10, -y => 10);
                ok($virtEventFired, 1, "Virtual Event Didn't Fire");
}
);
$TOP->after(3000, sub{
                $TOP->eventDelete('<<pTkRules>>');
                $TOP->destroy;
        }
        );


MainLoop;



