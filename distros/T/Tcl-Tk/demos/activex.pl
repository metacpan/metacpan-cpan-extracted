#####################################################
# This file demonstrates the Calendar control being 
# integrated within a Tk widget
#####################################################

use strict;
use Tcl::Tk qw(:widgets);

my $interp = new Tcl::Tk;

# in case we want to do some debugging
$interp->bind('.', '<F2>', 'console show');

my $t = text(".t", -height=>1, -width=>20,-font => "-*-Arial Unicode MS--R---*-350-*-*-*-*-*-*")->pack;
$t->insert("end", "thishishis\x{5678}\x{265c}\x{265d}\x{265e}\x{2345}\x{2346}\x{2347}");

# optcl load happens here
$interp->Eval('package require optcl');

my $cd = '***';
label(".cd", -bd=>1, -relief=>'sunken', -textvariable=>\$cd)
  ->pack(qw/-side bottom -fill x/);

sub new_activex {
  my ($nam, $type) = @_;
  my $obj = $interp->call('optcl::new', -window=>$nam, $type);
  return ((bless \$nam, "Tcl::Tk::Widget"),$obj);
}
# create the calendar object
my ($wcal, $acal) = new_activex('.cal', 'MSCAL.Calendar');
my ($wcombo,$acombo) = new_activex('.acombo', 'Forms.ComboBox.1');
my ($wspin,$aspin) = new_activex('.aspin', 'Forms.SpinButton.1');

$interp->pack(".cal", ".acombo", ".aspin");

#$wcal->config(qw/-width 300 -height 300/);
#$wcombo->configure(qw/-width 300 -height 20/);
$interp->call($$wcal,qw/configure -width 300 -height 300/);
$interp->call($$wcombo,qw/configure -width 300 -height 20/);
$interp->call($acombo,'AddItem',$_) for qw/one two three five/;
$interp->call($acombo, ':', 'Text', 'Bla-bla-bla-bla');

# make a button to view the type information of 
# the calendar
#button ".b", -text=>'TypeInfo', -command=>{tlview::viewtype [optcl::class $cal]}
#pack .b -side bottom -anchor se

$interp->MainLoop;
