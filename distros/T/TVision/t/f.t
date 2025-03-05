use strict;
use TVision (':commands', 'tnew', 'TRect');

my $data = [
    ["Helton, Andrew", "Asterisk International", "Purch. Mgr.", "(415) 868-3964", 'business | personal', 'male'],
    ["White, Natalie", "Exclamation, Inc.", "VP sales", "(408) 242-2030", 'business', 'female'],
    ["Stern, Peter", "", "Decent violinist", "(111) 222-5555", 'personal', 'male'],
    ["Whitcom, Hana O.", "Nate's girlfriend", "Birthday: Jan 8, 1990", "(408) 426-1234", 'personal', 'female'],
];

sub makeForm {
    my $formX1 = shift || 5,
    my $formY1 = shift || 3,
    my $formWd = 41,
    my $formHt = 17,
    my $labelCol = 1,
    my $labelWid = 8,
    my $inputCol = 11,
    my $buttonWd = 12,
    my $nameWidth = 25,
    my $companyWidth = 23,
    my $remarksWidth = 22,
    my $phoneWidth = 20;
    my $d = shift || [];

    my $f = tnew TDialog=>[$formX1, $formY1, $formX1 + $formWd, $formY1 + $formHt], "Phone Numbers";

    # Create and insert controls into the form
    my $y = 2;
    my $r = TRect($inputCol, $y, $inputCol + $nameWidth + 2, $y + 1);
    my $control = tnew TInputLine=>($r, $nameWidth);
    $f->insert($control);
    $r = TRect($labelCol, $y, $labelCol + $labelWid, $y + 1);
    $control->setData($d->[0]);

    $f->insert(tnew TLabel=>($r, "~N~ame", $control));

    $y += 2;
    $r = TRect($inputCol, $y, $inputCol + $companyWidth + 2, $y + 1);
    $control = tnew TInputLine=>($r, $companyWidth);
    $f->insert($control);
    $control->setData($d->[1]);

    $r = TRect($labelCol, $y, $labelCol + $labelWid, $y + 1);
    $f->insert(tnew TLabel=>($r, "~C~ompany", $control));

    $y += 2;
    $r = TRect($inputCol, $y, $inputCol + $remarksWidth + 2, $y + 1);
    $control = tnew TInputLine=>($r, $remarksWidth);
    $f->insert($control);
    $control->setData($d->[2]);

    $r = TRect($labelCol, $y, $labelCol + $labelWid, $y + 1);

    $f->insert(tnew TLabel=>($r, "~R~emarks", $control));

    $y += 2;
    $r = TRect($inputCol, $y, $inputCol + $phoneWidth + 2, $y + 1);
    $control = tnew TInputLine=>($r, $phoneWidth);
    $f->insert($control);
    $control->setData($d->[3]);

    $r = TRect($labelCol, $y, $labelCol + $labelWid, $y + 1);
    $f->insert(tnew TLabel=>($r, "~P~hone", $control));

    # Checkboxes
    my $x = $inputCol;
    $y += 3;
    $r = TRect($inputCol, $y , $inputCol + length("Business") + 6, $y + 2);
    $control = tnew TCheckBoxes=>($r, ["Business", "Personal",]);
    $f->insert($control);
    $r = TRect($x, $y - 1, $x + $labelWid, $y);
    $f->insert(tnew TLabel=>($r, "~T~ype", $control));

    # Radio buttons 
    $x += 15;
    $r = TRect($x, $y, $x + length("Female") + 6, $y + 2);

    $control = tnew TRadioButtons=>($r, [ "Male", "Female"]);
    $f->insert($control);
    $r = TRect($x, $y - 1, $x + $labelWid, $y);
    $f->insert(tnew TLabel=>($r, "~G~ender", $control));

    # Buttons 
    $y += 3;
    $x = $formWd - 2 * ($buttonWd + 2);
    $r = TRect($x, $y, $x + $buttonWd, $y + 2);
    $f->insert(tnew TButton=>($r, "~S~ave", 3001, bfDefault));

    $x = $formWd - 1 * ($buttonWd + 2);
    $r = TRect($x, $y, $x + $buttonWd, $y + 2);
    $f->insert(tnew TButton=>($r, "Cancel", cmCancel, bfNormal));
    $f->selectNext(0);      #/ Select first field 

    return $f;
}


my $tapp = tnew 'TVApp';
my $desktop = $tapp->deskTop;


my @f = map {makeForm($_,$_, $data->[$_ % 4])} 1 .. 45;
$desktop->insert($_) for @f;

$tapp->on_idle(my $sub = sub {
    $::e++;
    if ($::e % 10 == 0) {
	$f[int(rand($#f))]->focus();
    }
    if ($::e>500) {
	$tapp->endModal(42+42+42+42+42);
    }
});

use Test;
plan tests=>2;
ok(1);
$tapp->run;
ok(2);

