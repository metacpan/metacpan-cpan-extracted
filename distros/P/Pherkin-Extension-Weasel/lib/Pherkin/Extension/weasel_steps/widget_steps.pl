#!perl

use strict;
use warnings;

use Test::BDD::Cucumber::StepFile;


Then qr/I should see a (radio button|textbox|password box) "(.*)"/, sub {
    my $want_type = $1;
    my $label = $2;
    my $element = S->{ext_wsl}->page->find('*labeled', text => $label);

    my %element_type = (
        'radio button' => 'radio',
        'textbox'      => qr/(text)?/, # text or empty string
        'password box' => 'password',
        );

    is($element->tag_name, 'input', "$want_type tag name is 'input'");
    my $type = $element->get_attribute('type') || '';
    ok($type =~ m/^$element_type{$want_type}$/,
       "$want_type tag type att matches $element_type{$want_type}");
};

Then qr/I should see a (dropdown|combobox) "(.*)"/, sub {
    my $want_type = $1;
    my $label = $2;
    my $element = S->{ext_wsl}->page->find('*labeled', text => $label);

    my %expect_tag_name = (
        'dropdown'    => 'select',
        'combobox'    => 'input',
        );

    is($element->tag_name, $expect_tag_name{$want_type},
       "$want_type tag name is '$expect_tag_name{$want_type}'");
};

Then qr/I should see "(.*)"/, sub {
    my $want_text = $1;

    my $elements = S->{ext_wsl}->page->find('*contains', text => $want_text);
    my $count = scalar(@$elements);
    if (! $count) {
        ###TODO get_page_source not implemented yet!
        print STDERR S->{ext_wsl}->get_page_source;
    }
    ok($count, "Found $count elements containing '$want_text'");
};

Then qr/I should see a button "(.*)"/, sub {
    my $button_text = $1;

    my $btn = S->{ext_wsl}->page->find('*button', text => $button_text);
    ok($btn, "found button containing the text '$button_text'");
};


Then qr/I should see a drop down "(.*)"( with these items:)?/, sub {
    my $label_text = $1;
    my $want_values = $2;

    my $select = S->{ext_wsl}->page->find('*select', label => $label_text);
    ok($select, "Found the drop down with label '$label_text'");

    if ($want_values) {
        ok($select->find_option(text => $_),
           "Found option '$_' of dropdown '$label_text'")
            for (@{ C->data });
    }
};


Then qr/I should see these fields:/, sub {
    ok(S->{ext_wsl}->page->find('*labeled', text => $_->{label}),
       "Found field with label text '$_->{label}'")
        for (@{ C->data });
};

When qr/I press "(.*)"/, sub {
    my $button_text = $1;

    S->{ext_wsl}->page->find('*button', text => $button_text)->click;
};

When qr/I select "(.*)" from the drop down "(.*)"/, sub {
    my $value = $1;
    my $label = $2;

    S->{ext_wsl}->page->find('*labeled', text => $label)
        ->select_option($value);
};

When qr/I enter (([^"].*)|"(.*)") into "(.+)"/, sub {
    my $param = $2;
    my $value = $3;
    my $label = $4;

    my $element = S->{ext_wsl}->page->find(
        "*labeled", text => $label);
    ok($element, "found element with label '$label'");
    $value ||= C->stash->{feature}->{$param} if $param;
    $element->click;
    $element->clear;
    $element->send_keys($value);
};

When qr/I enter these values:/, sub {
    foreach my $field (@{ C->data }) {
        my $elm = S->{ext_wsl}->page->find(
            "*labeled", text => $field->{label});
        if ($elm->can("find_option")) {
            $elm->find_option($field->{value})->click;
        }
        else {
            $elm->click;
            $elm->clear;
            $elm->send_keys($field->{value});
        }
    }
};



1;
