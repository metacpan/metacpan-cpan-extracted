use strict;
use warnings;
use Test::More;
use Tcl::Tk;

# Check for GUI availability to prevent failures on headless CPAN testers
my $mw;
eval {
    $mw = Tcl::Tk::MainWindow->new();
};

if ($@ || !$mw) {
    plan skip_all => "X11/Window server is not available or Tcl::Tk failed to init MainWindow";
    exit;
}

plan tests => 18;

# 1. Verify MainWindow creation
isa_ok($mw, 'Tcl::Tk::Widget', 'MainWindow creation');

# Map of new Ttk widgets to test
my %ttk_widgets = (
    TtkCheckbutton => 'tchk',
    TtkButton      => 'tbtn',
    TtkRadiobutton => 'trdb',
    TtkLabel       => 'tlbl',
    TtkEntry       => 'tent',
    TtkFrame       => 'tfrm',
    TtkLabelframe  => 'tlfr',
    TtkNotebook    => 'tnb',
    TtkScrollbar   => 'tsb',
    TtkCombobox    => 'tcbo',
    TtkProgressbar => 'tprg',
    TtkScale       => 'tscl',
    TtkSeparator   => 'tsep',
    TtkSizegrip    => 'tsz',
    TtkTreeview    => 'ttv',
    TtkPanedwindow => 'tpw',
    TtkSpinbox     => 'tspn',
);

# 2. Test widget factory methods sequentially
while (my ($method, $prefix) = each %ttk_widgets) {
    my ($lab,$w);
    eval {
        $lab = $mw->Label(-text=>$method)->pack(-side=>'top');
        $w = $mw->$method()->pack(-side=>'top');
    };

    ok(defined($w) && !$@, "Widget method call: $method");

    $w->interp->update;
    sleep 1;

    $w->destroy if defined $w;
    $lab->destroy if defined $lab;
}

$mw->after(3000,sub{$mw->destroy});
Tcl::Tk::MainLoop;

