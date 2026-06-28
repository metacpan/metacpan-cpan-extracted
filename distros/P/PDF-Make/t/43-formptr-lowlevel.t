#!/usr/bin/perl
use strict;
use warnings;
use Test::More;

BEGIN {
    use_ok('PDF::Make::Document');
    use_ok('PDF::Make::FormPtr');
    use_ok('PDF::Make::FieldPtr');
}

my $doc = PDF::Make::Document->new;
$doc->add_page(612, 792);
my $page = $doc->get_page(0);

ok(!defined PDF::Make::FormPtr::get($doc), 'get() returns undef before form creation');

my $form = PDF::Make::FormPtr::create($doc);
ok($form, 'FormPtr::create returns a form handle');
ok(defined PDF::Make::FormPtr::get($doc), 'get() returns form after creation');
is($form->field_count, 0, 'new low-level form has zero fields');
ok(!defined $form->field_at(0), 'field_at(0) is undef for empty form');

my $text = PDF::Make::FieldPtr::text($doc, 'email', 72, 700, 220, 20);
ok($text, 'FieldPtr::text creates field');
is($text->type, 'text', 'low-level text field type');
is($text->name, 'email', 'low-level text field name');
is($text->full_name, 'email', 'low-level text field full name');
is($text->value('user@example.com'), 'user@example.com', 'value() setter returns assigned value');
is($text->value, 'user@example.com', 'value() getter round-trips');
$text->readonly(1);
$text->required(1);
ok($text->is_readonly, 'readonly flag set via low-level API');
ok($text->is_required, 'required flag set via low-level API');
$text->add_to_page($page);

is($form->field_count, 1, 'text field counted in form');
my $found = $form->field_by_name('email');
ok($found, 'field_by_name finds low-level field');
is($found->name, 'email', 'field_by_name returns expected field');

my $choice = PDF::Make::FieldPtr::choice($doc, 'priority', 72, 650, 140, 40, 0);
$choice->add_option('High', 'H');
$choice->add_option('Low');
is($choice->option_count, 2, 'choice field option_count works');
my @options = $choice->options;
is($options[0]->{display}, 'High', 'first choice display value');
is($options[0]->{export}, 'H', 'first choice export value');
is($options[1]->{display}, 'Low', 'second choice display value');
$choice->set_value('H');
is($choice->value, 'H', 'choice set_value works');
$choice->add_to_page($page);

my $button = PDF::Make::FieldPtr::button($doc, 'visit', 72, 600, 100, 24, 'Visit');
$button->set_uri_action('https://example.com');
$button->add_to_page($page);
ok($form->field_count >= 3, 'multiple low-level fields tracked by form');

my @fields = $form->fields;
ok(@fields >= 3, 'fields() returns all low-level fields');
ok(!defined $form->field_by_name('missing'), 'field_by_name returns undef for missing field');

my $fdf = $form->export_fdf;
like($fdf, qr/%FDF/, 'low-level form exports FDF');
like($fdf, qr/email|priority/, 'FDF contains field names');

my $xfdf = $form->export_xfdf;
like($xfdf, qr/<xfdf/i, 'low-level form exports XFDF');
like($xfdf, qr/user\@example\.com/, 'XFDF contains field value');

$form->finalize;
my $bytes = $doc->to_bytes;
like($bytes, qr/AcroForm/, 'finalized low-level form renders into PDF');
like($bytes, qr/email|priority|visit/, 'rendered PDF contains low-level field names');
like($bytes, qr/URI.*example\.com/s, 'button URI action is serialized');

done_testing;
