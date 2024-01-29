package Tcl::Tk::Tkwidget::Tix;
require DynaLoader;
our @ISA = qw(DynaLoader);
__PACKAGE__->bootstrap;

# happen to NOT have the required Tix widget
sub init {
    my $int = shift;
    $INC{'Tcl/Tk/Tkwidget/Tix.pm'} =~ /^(.*)\// or die "?";
    $int->SetVar('::tix_library',"$1/../library");
    Tcl::Tk::Tkwidget::Tix::Tix_Init($int);
}
1;
