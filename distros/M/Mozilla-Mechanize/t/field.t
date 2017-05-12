#!/usr/bin/perl
use strict;
use warnings;

use URI::file;

use Test::More;
plan tests => 12;

use_ok 'Mozilla::Mechanize';

my $uri = URI::file->new_abs("t/html/field.html")->as_string;

isa_ok my $moz = Mozilla::Mechanize->new(visible => 0), 'Mozilla::Mechanize';

ok $moz->get($uri), "Fetched $uri";


    my $val = 'Modified!';
    my ($rval) = $moz->field(dingo => $val);
    is $rval, $val, "field($val) returns the set value ($rval)";
    my $form1 = $moz->current_form;
    is $form1->value("dingo"), $val, "dingo => $val";
    my ($value) = $moz->value('dingo');
    is $value, $val, "value() returns the set value ($value)";


    $moz->set_visible("bingo", "bango");
    my $form2 = $moz->current_form;
    is $form2->value("dingo"), "bingo", "dingo => bingo";
    is $moz->value('dingo'), 'bingo', "value(dingo) == bingo";
    is $form2->value("bongo"), "bango", "bongo => bango";
    is $moz->value("bongo"), "bango", "value(bongo) == bango";


    $moz->set_visible([ radio => "wongo!" ], "boingo");
    my $form3 = $moz->current_form;

    is $form3->value("wango"), "wongo!", "wango => wongo!";
    is $form3->find_input("dingo", undef, 2)->value, "boingo",
      "dingo(2) => boingo";

$moz->close();
