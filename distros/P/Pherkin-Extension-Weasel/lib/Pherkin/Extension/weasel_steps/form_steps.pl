use strict;
use warnings;

use Test::BDD::Cucumber::StepFile;

When qr/^I fill in:$/, sub {
    my $data = C->data;

    for my $row (@$data) {
        my $fld = S->{ext_wsl}->find('*labeled' => $row->{field});
        $fld->value($row->{value});
    }
};

When qr/^I fill "(.*)" with "(.*)"$/, sub {
    my $field = $1;
    my $value = $2;

    my $fld = S->{ext_wsl}->find('*labeled' => $field);
    $fld->value($value);
};

1;
