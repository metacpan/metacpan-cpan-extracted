use CGI;
use Pilot;
use Pilot::TaskList;

$pilot_path  = 'd:\pilot\wieglej';
$email       = 'johnw@borland.com';
$pilot_cat   = 'Business';

$script_path = "/cgi-shl/tasklist.pl";

$done_color  = "777777";
$due_color   = "FF0000";

# Check whether there is a HotSync in progress

# Create PalmPilot object

$pilot = new Pilot $pilot_path;

# Read the task list database

@tasks = Pilot::TaskList::ReadTaskList($pilot, $pilot_cat);

# Helper functions

sub arg {
    my ($arg, $ref) = @_;
#    if ($ref) {
#        return $q->a({ href => $ref }, $arg);
#    } else {
        return $arg;
#    }
}

sub field_print {
    my ($arg, $font, $align, $ref) = @_;

    my $decl;

    if ($align) {
        $decl = sprintf '<TD align="%s">', $align;
    } else {
        $decl = '<TD>';
    }
    print $decl;

    if ($font) {
        print '<FONT color="', $font, '">', arg($arg, $ref), '</FONT>';
    } else {
        print arg($arg, $ref);
    }
}

# Create the web page

$q = new CGI;

$q->use_named_parameters();

print $q->header();
print $q->start_html(-title => 'Task List', -author => $email);

$index = $q->param("index");

if ($index) {
    print '<H2>Edit To-do Item</H2>';
    
    print $q->startform;
    
    print '<TABLE>';
    print '<TR ALIGN="left">';
    print     '<TH WIDTH="5%">';
    print     '<TH WIDTH="60%">';
    
    print '<TR>';
    print '<TD>Priority:<TD>';
    print $q->popup_menu(-name    => 'Priority',
                         -values  => [ '0','1', '2', '3'  ],
                         -default => $tasks[$index]{"Priority"} - 1);
    print '</TR>';
    
    print '<TR>';
    print '<TD>Description:<TD>';
    print $q->textfield(-name     => 'Description',
                        -size     => 80,
                        -value    => $tasks[$index]{"Description"});
    print '</TR>';
    
    print '<TR>';
    print '<TD>Due Date:<TD>';
    print $q->textfield(-name     => 'Due Date',
                        -value    => Pilot::DateString $tasks[$index]{"Date"});
    print '</TR>';
    
    my $note = "";
    if ($task->{"Note"}) {
        foreach $line (@{$task->{"Note"}}) {
            $note .= $line . "\n";
        }
    }
    
    print '<TR>';
    print '<TD>Notes:<TD>';
    print $q->textarea(-name      => 'Notes',
                       -rows      => 10,
                       -columns   => 50,
                       -value     => $note);
    print '</TR>';
    
    print '<TR><TD><TD></TR>';
    
    print '<TR>';
    print '<TD><TD>', $q->reset;
    print $q->submit('Action', 'Change');
    print $q->submit('Action', 'Delete');
    print '</TR>';
    
    print '</TABLE>';

    print $q->endform;
} else {
    print '<H2>To-do Items</H2>';
    print '<TABLE>';
    print '<TR ALIGN="left">';
    print     '<TH WIDTH="5%">Pri';
    print     '<TH WIDTH="60%">Description';
    print     '<TH ALIGN="right" WIDTH="8%">Due';
    print '</TR>';
    
    my $i = 0;
    foreach $task (@tasks) {
        $i++;
        next if $task->{"Done"};
        
        print '<TR>';
        
        my $color = $task->{"Date"} < time() && $due_color;
        
        if ($task->{"Priority"} != 5) {
            my $x = $i - 1;
            field_print $task->{"Priority"} - 1, $color, "left",
                $script_path . "?index=$x";
        } else {
            field_print "", $color;
        }
        
        field_print $task->{"Description"}, $color;
        
        if ($task->{"Priority"} == 5) {
            field_print "Blocked", $color, "right";
        }
        elsif ($task->{"Date"}) {
            field_print Pilot::DateString($task->{"Date"}), $color, "right";
        }
        
        print '</TR>';
        
        print "\n";
        
        if ($task->{"Note"}) {
            foreach $line (@{$task->{"Note"}}) {
                print '<TR><TD>';
                field_print $line, $done_color;
                print '<TD><TD></TR>';
                print "\n";
            }
        }
    }
    
    print '</TABLE>';
    print "\n\n";
    
    # Print out all of the completed tasks
    
    print '<HR>';
    print '<H2>Completed Items</H2>';
    print '<TABLE>';
    print '<TR ALIGN="left">';
    print     '<TH WIDTH="5%">Pri';
    print     '<TH WIDTH="60%">Description';
    print     '<TH ALIGN="right" WIDTH="8%">Due';
    print '</TR>';
    
    foreach $task (@tasks) {
        next unless $task->{"Done"};
        
        print '<TR>';
        
        field_print $task->{"Priority"} - 1, $done_color;
        field_print $task->{"Description"}, $done_color;

        if ($task->{"Date"}) {
            field_print Pilot::DateString($task->{"Date"}), $done_color, "right";
        }
        
        print '</TR>';
        
        print "\n";
    }
    
    print '</TABLE>';
    print "\n\n";
    print '<HR>';
    print '<H4>(last updated ', Pilot::DateText(1, $pilot->LastSync()), ')</H4>';
}

print $q->end_html();
