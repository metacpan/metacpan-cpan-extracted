#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;

use SyForm::FormHTML;
use HTML::Declare ':all';

my $empty = SyForm::FormHTML->new;
is("".$empty->html_declare,'<form><input type="submit"/></form>','Empty form');

my $nosubmit = SyForm::FormHTML->new( no_submit => 1 );
is("".$nosubmit->html_declare,'<form/>','No submit form (so REALLY empty)');

my $some = SyForm::FormHTML->new(
  action => 'testaction',
  onerror => 'testonerror',
  dir => 'testdir',
  data => {
    test => 'testdata',
    test_2 => 'testdata2',
  },
);
my $html = "".$some->html_declare;
like($html,qr/^\<form/,'$some has formtag');
like($html,qr/action="testaction"/,'$some has action');
like($html,qr/onerror="testonerror"/,'$some has onerror');
like($html,qr/dir="testdir"/,'$some has dir');
like($html,qr/data-test="testdata"/,'$some has data-test');
like($html,qr/data-test-2="testdata2"/,'$some has data-test-2');

my $childs = SyForm::FormHTML->new(
  action => 'testaction',
  onerror => 'testonerror',
  dir => 'testdir',
  data => {
    test => 'testdata',
    test_2 => 'testdata2',
  },
);
my $chtml = "".$childs->html_declare;
like($chtml,qr/^\<form/,'$childs has opening formtag');
like($chtml,qr/action="testaction"/,'$childs has action');
like($chtml,qr/onerror="testonerror"/,'$childs has onerror');
like($chtml,qr/dir="testdir"/,'$childs has dir');
like($chtml,qr/data-test="testdata"/,'$childs has data-test');
like($chtml,qr/data-test-2="testdata2"/,'$childs has data-test-2');

done_testing;
