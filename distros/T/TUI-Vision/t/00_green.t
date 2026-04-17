use strict;
use warnings;

use Test::More;

my @modules = qw(
    TUI::Vision
    TUI::App
    TUI::Dialogs
    TUI::Drivers
    TUI::Gadgets
    TUI::Memory
    TUI::MsgBox
    TUI::Objects
    TUI::StdDlg
    TUI::TextView
    TUI::Validate
    TUI::Views
    TUI::toolkit
);

foreach my $mod (@modules) {
    use_ok($mod);
}

diag("TUI::Vision $TUI::Vision::VERSION - Namespace Claim - All Green");

done_testing();
