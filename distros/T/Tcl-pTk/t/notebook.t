# Notebook, selectable pages.

use Tcl::pTk;
use Tcl::pTk::DialogBox;

use Test;


my $name = "Rajappa Iyer";
my $email = "rsi\@netcom.com";
my $os = "Linux";

use vars qw($top);

$top = MainWindow->new;

# This will skip if Tix not present
my $retVal = $top->interp->pkg_require('Tix');
unless( $retVal){
	plan tests => 1;
        skip("Tix Tcl package not available", 1);
        exit;
}

plan test => 2;


my $notebook = donotebook();


my @pages = $notebook->pages;
ok(join(", ", @pages), 'address, pref', 'Notebook pages call');

ok(1);



my $f;

sub donotebook {
    my $n;
    if (not defined $f) {
	# The current example uses a DialogBox, but you could just
	# as easily not use one... replace the following by
	# $n = $top->NoteBook(-ipadx => 6, -ipady => 6);
	# Of course, then you'd have to take care of the OK and Cancel
	# buttons yourself. :-)
	$f = $top->DialogBox(-title => "Personal Profile",
			     -buttons => ["OK", "Cancel"]);
	$n = $f->add('NoteBook', -ipadx => 6, -ipady => 6);

	my $address_p = $n->add("address", -label => "Address", -underline => 0);
	my $pref_p = $n->add("pref", -label => "Preferences", -underline => 0);

	$address_p->LabEntry(-label => "Name:             ",
	     -labelPack => [-side => "left", -anchor => "w"],
	     -width => 20,
	     -textvariable => \$name)->pack(-side => "top", -anchor => "nw");
	$address_p->LabEntry(-label => "Email Address:",
	     -labelPack => [-side => "left", -anchor => "w"],
	     -width => 50,
	     -textvariable => \$email)->pack(-side => "top", -anchor => "nw");
	$pref_p->LabEntry(-label => "Operating System:",
	     -labelPack => [-side => "left"],
	     -width => 15,
	     -textvariable => \$os)->pack(-side => "top", -anchor => "nw");
	$n->pack(-expand => "yes",
		 -fill => "both",
		 -padx => 5, -pady => 5,
		 -side => "top");
	

    }
    
    # Get the ok button and press it after two seconds
    my $okbutton = $f->Subwidget('B_OK');

    # Make sure the raise method works
    $top->after(1000, sub{ $n->raise('pref') });

    $f->after(2000, 
        sub{
                
                $okbutton->invoke();
        }
        );

    my $result = $f->Show;
    if ($result =~ /OK/) {
	print "name = $name, email = $email, os = $os\n";
    }
    return $n;
}

