## Test case to check for a problem where a command was created in Tcl-land for each instance of a repeat event.
##   This was changed to reuse the Tcl-command for each instance of ther repeat event, and not create a new one
##
use Tcl::pTk;

#use Tk;
use strict;

use Test;
plan tests => 1;

$| = 1;

#########################################

my $top = MainWindow->new();
my $tk = $top->Toplevel;


my $state = 1;
my $index = 0;

my %windowIndex;

my $id;

my @commands;

# Number of '::perl::CODE*' sub-refs that are created in TCL-land at the begining of the script,
#  after running a lot of repeat commands, and after widget destruction
my ($initialCommands, $afterCommands);

$id = $tk->repeat(
        10,
        [  sub {

                   if ( $state == 1 ) {
                           $index++;
                           #print "Creating CB $index\n";
                           addCheckB($tk, $index);
                           $state = 0;
                   }
                   elsif ( $state == 0 ) {
                           #print "Deleting CB $index\n";
                           delCheckB($tk, $index);
                           $state = 1;
                   }
                   if( $index > 100){
                           $tk->afterCancel($id);
                           @commands = $tk->call('info', 'commands', '::perl::CODE*');
                           #print join(", ", @commands)."\n";
                           # print "Number of commands = ".scalar(@commands)."\n"; 
                           $afterCommands = scalar(@commands);
                           $tk->destroy;
                           $top->after(1000, [$top, 'destroy']);

                   }
           }
        ]
);


@commands = $tk->call('info', 'commands','::perl::CODE*');
#print join(", ", @commands)."\n";
#print "Initial number of commands Number of commands = ".scalar(@commands)."\n";
my $initCommands = scalar(@commands);

MainLoop;

ok($afterCommands, $initCommands, "Extra Commands Created for Repeat"); 

exit;


###########################################################################################


sub addCheckB {
        my ( $w, $index ) = @_;

        $windowIndex{$index} = $w->Label(-text => "Label Create")->pack();
}

sub delCheckB {
        my ( $w, $index ) = @_;

        $windowIndex{$index}->destroy();
        delete $windowIndex{$index};
}
