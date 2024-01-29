package Tcl::Tk::Tkwidget::treectrl;
require DynaLoader;
our @ISA = qw(DynaLoader);
__PACKAGE__->bootstrap;

# happen to NOT have the required treectrl widget
sub init {
    my $int = shift;
    $INC{'Tcl/Tk/Tkwidget/treectrl.pm'} =~ /^(.*)\// or die "?";
    $int->SetVar('::treectrl_library',"$1/../library");
    Tcl::Tk::Tkwidget::treectrl::Treectrl_Init($int);
    #$int->Eval('package require treectrl');
}
1;
