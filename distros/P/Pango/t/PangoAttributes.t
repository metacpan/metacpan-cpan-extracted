#!/usr/bin/perl
use strict;
use warnings;
use lib qw(t/inc);
use PangoTestHelper tests => 202;

#
# pango_color_parse(), pango_color_to_string()
#

my $color = Pango::Color->parse ('white');
isa_ok ($color, 'Pango::Color');
isa_ok ($color, 'ARRAY');
is_deeply ($color, [0xffff, 0xffff, 0xffff]);

SKIP: {
	skip 'new 1.16 stuff', 2
		unless Pango->CHECK_VERSION (1, 16, 0);

	is (Pango::Color->to_string ($color), '#ffffffffffff');
	is ($color->to_string, '#ffffffffffff');
}

#
# PangoAttrLanguage
#

my $lang = Pango::Language->from_string ('de-de');
my $attr = Pango::AttrLanguage->new ($lang);
isa_ok ($attr, 'Pango::AttrLanguage');
isa_ok ($attr, 'Pango::Attribute');
is ($attr->value->to_string, 'de-de');

$lang = Pango::Language->from_string ('en-us');
$attr->value ($lang);
is ($attr->value->to_string, 'en-us');

$attr = Pango::AttrLanguage->new ($lang, 23, 42);
is ($attr->start_index, 23);
is ($attr->end_index, 42);

#
# PangoAttrFamily
#

$attr = Pango::AttrFamily->new ('sans');
isa_ok ($attr, 'Pango::AttrFamily');
isa_ok ($attr, 'Pango::AttrString');
isa_ok ($attr, 'Pango::Attribute');
is ($attr->value, 'sans');

is ($attr->value ('sans-serif'), 'sans');
is ($attr->value, 'sans-serif');

$attr = Pango::AttrFamily->new ('sans', 23, 42);
is ($attr->start_index, 23);
is ($attr->end_index, 42);

#
# PangoAttrForeground
#

$attr = Pango::AttrForeground->new (0, 0, 0);
isa_ok ($attr, 'Pango::AttrForeground');
isa_ok ($attr, 'Pango::AttrColor');
isa_ok ($attr, 'Pango::Attribute');
is_deeply ($attr->value, [0, 0, 0]);

is_deeply ($attr->value ([0xffff, 0xffff, 0xffff]), [0, 0, 0]);
is_deeply ($attr->value, [0xffff, 0xffff, 0xffff]);

$attr = Pango::AttrForeground->new (0, 0, 0, 23, 42);
is ($attr->start_index, 23);
is ($attr->end_index, 42);

#
# PangoAttrBackground
#

$attr = Pango::AttrBackground->new (0, 0, 0);
isa_ok ($attr, 'Pango::AttrBackground');
isa_ok ($attr, 'Pango::AttrColor');
isa_ok ($attr, 'Pango::Attribute');
is_deeply ($attr->value, [0, 0, 0]);

$attr->value ([0xffff, 0xffff, 0xffff]);
is_deeply ($attr->value, [0xffff, 0xffff, 0xffff]);

$attr = Pango::AttrBackground->new (0, 0, 0, 23, 42);
is ($attr->start_index, 23);
is ($attr->end_index, 42);

#
# PangoAttrSize
#

$attr = Pango::AttrSize->new (23);
isa_ok ($attr, 'Pango::AttrSize');
isa_ok ($attr, 'Pango::AttrInt');
isa_ok ($attr, 'Pango::Attribute');
is ($attr->value, 23);

$attr->value (42);
is ($attr->value, 42);

$attr = Pango::AttrSize->new (23, 23, 42);
is ($attr->start_index, 23);
is ($attr->end_index, 42);

SKIP: {
	skip 'Pango::AttrSize->new_absolute', 7
		unless Pango->CHECK_VERSION (1, 8, 0);

	$attr = Pango::AttrSize->new_absolute (23);
	isa_ok ($attr, 'Pango::AttrSize');
	isa_ok ($attr, 'Pango::AttrInt');
	isa_ok ($attr, 'Pango::Attribute');
	is ($attr->value, 23);

	$attr->value (42);
	is ($attr->value, 42);

	$attr = Pango::AttrSize->new_absolute (23, 23, 42);
	is ($attr->start_index, 23);
	is ($attr->end_index, 42);
}

#
# PangoAttrStyle
#

$attr = Pango::AttrStyle->new ('normal');
isa_ok ($attr, 'Pango::AttrStyle');
isa_ok ($attr, 'Pango::Attribute');
is ($attr->value, 'normal');

$attr->value ('italic');
is ($attr->value, 'italic');

$attr = Pango::AttrStyle->new ('normal', 23, 42);
is ($attr->start_index, 23);
is ($attr->end_index, 42);

#
# PangoAttrWeight
#

$attr = Pango::AttrWeight->new ('bold');
isa_ok ($attr, 'Pango::AttrWeight');
isa_ok ($attr, 'Pango::Attribute');
is ($attr->value, 'bold');

$attr->value ('heavy');
is ($attr->value, 'heavy');

$attr = Pango::AttrWeight->new ('bold', 23, 42);
is ($attr->start_index, 23);
is ($attr->end_index, 42);

#
# PangoAttrVariant
#

$attr = Pango::AttrVariant->new ('normal');
isa_ok ($attr, 'Pango::AttrVariant');
isa_ok ($attr, 'Pango::Attribute');
is ($attr->value, 'normal');

$attr->value ('small-caps');
is ($attr->value, 'small-caps');

$attr = Pango::AttrVariant->new ('normal', 23, 42);
is ($attr->start_index, 23);
is ($attr->end_index, 42);

#
# PangoAttrStretch
#

$attr = Pango::AttrStretch->new ('normal');
isa_ok ($attr, 'Pango::AttrStretch');
isa_ok ($attr, 'Pango::Attribute');
is ($attr->value, 'normal');

$attr->value ('condensed');
is ($attr->value, 'condensed');

$attr = Pango::AttrStretch->new ('normal', 23, 42);
is ($attr->start_index, 23);
is ($attr->end_index, 42);

#
# PangoAttrUnderline
#

$attr = Pango::AttrUnderline->new ('none');
isa_ok ($attr, 'Pango::AttrUnderline');
isa_ok ($attr, 'Pango::Attribute');
is ($attr->value, 'none');

$attr->value ('double');
is ($attr->value, 'double');

$attr = Pango::AttrUnderline->new ('none', 23, 42);
is ($attr->start_index, 23);
is ($attr->end_index, 42);

#
# PangoAttrStrikethrough
#

$attr = Pango::AttrStrikethrough->new (FALSE);
isa_ok ($attr, 'Pango::AttrStrikethrough');
isa_ok ($attr, 'Pango::Attribute');
ok (!$attr->value);

$attr->value (TRUE);
ok ($attr->value);

$attr = Pango::AttrStrikethrough->new (FALSE, 23, 42);
is ($attr->start_index, 23);
is ($attr->end_index, 42);

#
# PangoAttrFontDesc
#

my $desc = Pango::FontDescription->from_string ('Sans 12');
$attr = Pango::AttrFontDesc->new ($desc);
isa_ok ($attr, 'Pango::AttrFontDesc');
isa_ok ($attr, 'Pango::Attribute');
is ($attr->desc->to_string, 'Sans 12');

$desc = Pango::FontDescription->from_string ('Sans 14');
is ($attr->desc ($desc)->to_string, 'Sans 12');
is ($attr->desc->to_string, 'Sans 14');

$attr = Pango::AttrFontDesc->new ($desc, 23, 42);
is ($attr->start_index, 23);
is ($attr->end_index, 42);

#
# PangoAttrScale
#

$attr = Pango::AttrScale->new (2.0);
isa_ok ($attr, 'Pango::AttrScale');
isa_ok ($attr, 'Pango::Attribute');
is ($attr->value, 2.0);

$attr->value (4.0);
is ($attr->value, 4.0);

$attr = Pango::AttrScale->new (2.0, 23, 42);
is ($attr->start_index, 23);
is ($attr->end_index, 42);

#
# PangoAttrRise
#

$attr = Pango::AttrRise->new (23);
isa_ok ($attr, 'Pango::AttrRise');
isa_ok ($attr, 'Pango::Attribute');
is ($attr->value, 23);

$attr->value (42);
is ($attr->value, 42);

$attr = Pango::AttrRise->new (23, 23, 42);
is ($attr->start_index, 23);
is ($attr->end_index, 42);

#
# PangoAttrShape
#

my $ink     = { x => 23, y => 42, width => 10, height => 15 };
my $logical = { x => 42, y => 23, width => 15, height => 10 };

$attr = Pango::AttrShape->new ($ink, $logical);
isa_ok ($attr, 'Pango::AttrShape');
isa_ok ($attr, 'Pango::Attribute');
is_deeply ($attr->ink_rect, $ink);
is_deeply ($attr->logical_rect, $logical);

$attr->ink_rect ($logical);
is_deeply ($attr->ink_rect, $logical);
$attr->logical_rect ($ink);
is_deeply ($attr->logical_rect, $ink);

$attr = Pango::AttrShape->new ($ink, $logical, 23, 42);
is ($attr->start_index, 23);
is ($attr->end_index, 42);

#
# PangoAttrFallback
#

SKIP: {
	skip 'Pango::AttrFallback', 6
		unless Pango->CHECK_VERSION (1, 4, 0);

	$attr = Pango::AttrFallback->new (FALSE);
	isa_ok ($attr, 'Pango::AttrFallback');
	isa_ok ($attr, 'Pango::Attribute');
	ok (!$attr->value);

	$attr->value (TRUE);
	ok ($attr->value);

	$attr = Pango::AttrFallback->new (FALSE, 23, 42);
	is ($attr->start_index, 23);
	is ($attr->end_index, 42);
}

#
# PangoAttrLetterSpacing
#

SKIP: {
	skip 'Pango::AttrLetterSpacing', 7
		unless Pango->CHECK_VERSION (1, 6, 0);

	$attr = Pango::AttrLetterSpacing->new (23);
	isa_ok ($attr, 'Pango::AttrLetterSpacing');
	isa_ok ($attr, 'Pango::AttrInt');
	isa_ok ($attr, 'Pango::Attribute');
	is ($attr->value, 23);

	$attr->value (42);
	is ($attr->value, 42);

	$attr = Pango::AttrLetterSpacing->new (23, 23, 42);
	is ($attr->start_index, 23);
	is ($attr->end_index, 42);
}

#
# PangoAttrUnderlineColor
#

SKIP: {
	skip 'Pango::AttrUnderlineColor', 8
		unless Pango->CHECK_VERSION (1, 8, 0);

	$attr = Pango::AttrUnderlineColor->new (0, 0, 0);
	isa_ok ($attr, 'Pango::AttrUnderlineColor');
	isa_ok ($attr, 'Pango::AttrColor');
	isa_ok ($attr, 'Pango::Attribute');
	is_deeply ($attr->value, [0, 0, 0]);

	is_deeply ($attr->value ([0xffff, 0xffff, 0xffff]), [0, 0, 0]);
	is_deeply ($attr->value, [0xffff, 0xffff, 0xffff]);

	$attr = Pango::AttrUnderlineColor->new (0, 0, 0, 23, 42);
	is ($attr->start_index, 23);
	is ($attr->end_index, 42);
}

#
# PangoAttrStrikethroughColor
#

SKIP: {
	skip 'Pango::AttrStrikethroughColor', 8
		unless Pango->CHECK_VERSION (1, 8, 0);

	$attr = Pango::AttrStrikethroughColor->new (0, 0, 0);
	isa_ok ($attr, 'Pango::AttrStrikethroughColor');
	isa_ok ($attr, 'Pango::AttrColor');
	isa_ok ($attr, 'Pango::Attribute');
	is_deeply ($attr->value, [0, 0, 0]);

	is_deeply ($attr->value ([0xffff, 0xffff, 0xffff]), [0, 0, 0]);
	is_deeply ($attr->value, [0xffff, 0xffff, 0xffff]);

	$attr = Pango::AttrStrikethroughColor->new (0, 0, 0, 23, 42);
	is ($attr->start_index, 23);
	is ($attr->end_index, 42);
}

#
# PangoAttrGravity, PangoAttrGravityHint
#

SKIP: {
	skip 'PangoAttrGravity, PangoAttrGravityHint', 14
		unless Pango->CHECK_VERSION (1, 16, 0);

	$attr = Pango::AttrGravity->new ('south');
	isa_ok ($attr, 'Pango::AttrGravity');
	isa_ok ($attr, 'Pango::Attribute');
	is ($attr->value, 'south');

	is ($attr->value ('north'), 'south');
	is ($attr->value, 'north');

	$attr = Pango::AttrGravity->new ('south', 23, 42);
	is ($attr->start_index, 23);
	is ($attr->end_index, 42);

	$attr = Pango::AttrGravityHint->new ('strong');
	isa_ok ($attr, 'Pango::AttrGravityHint');
	isa_ok ($attr, 'Pango::Attribute');
	is ($attr->value, 'strong');

	is ($attr->value ('line'), 'strong');
	is ($attr->value, 'line');

	$attr = Pango::AttrGravityHint->new ('strong', 23, 42);
	is ($attr->start_index, 23);
	is ($attr->end_index, 42);
}

#
# PangoAttrList
#

my $attr_one = Pango::AttrWeight->new ('light', 23, 42);
my $attr_two = Pango::AttrWeight->new ('normal', 23, 42);
my $attr_three = Pango::AttrWeight->new ('bold', 23, 42);

my $list_one = Pango::AttrList->new;
$list_one->insert ($attr_one);
$list_one->insert_before ($attr_two);
$list_one->change ($attr_three);

my $list_two = Pango::AttrList->new;
$list_one->insert ($attr_three);
$list_one->insert_before ($attr_two);
$list_one->change ($attr_one);

$list_one->splice ($list_two, 0, 2);

#
# PangoAttrIterator
#

my $list = Pango::AttrList->new;

my $attr_weight = Pango::AttrWeight->new ('normal', 0, 23);
$list->insert ($attr_weight);

my $attr_variant = Pango::AttrVariant->new ('normal', 0, 42);
$list->insert ($attr_variant);

my $iter = $list->get_iterator;
isa_ok ($iter, 'Pango::AttrIterator');

is_deeply ([$iter->range], [0, 23]);
ok ($iter->get ('weight')->equal ($attr_weight));


SKIP: {
	skip 'get_attrs', 6
		unless Pango->CHECK_VERSION (1, 2, 0);

	my @attrs = $iter->get_attrs;
	is (scalar @attrs, 2);
	ok ($attrs[1]->equal ($attr_variant));

	ok ($iter->next);
	ok ($iter->next);

	@attrs = $iter->get_attrs;
	is (scalar @attrs, 0);

	is ($iter->get ('weight'), undef);
}

# get_font
$list = Pango::AttrList->new;

$lang = Pango::Language->from_string ('de-de');
$attr = Pango::AttrLanguage->new ($lang, 0, 23);
$list->insert($attr);

$attr = Pango::AttrWeight->new ('bold', 0, 23);
$list->insert($attr);

$iter = $list->get_iterator;
my ($desc_new, $lang_new, @extra) = $iter->get_font;
is ($desc_new->get_weight, 'bold');
is ($lang_new->to_string, 'de-de');
is (scalar @extra, 0);

$attr = Pango::AttrBackground->new (0, 0, 0, 0, 23);
$list->insert($attr);

$attr = Pango::AttrForeground->new (0, 0, 0, 0, 23);
$list->insert($attr);

$iter = $list->get_iterator;
($desc_new, $lang_new, @extra) = $iter->get_font;
is ($desc_new->get_weight, 'bold');
is ($lang_new->to_string, 'de-de');
is (scalar @extra, 2);
isa_ok ($extra[0], 'Pango::AttrBackground');
isa_ok ($extra[1], 'Pango::AttrForeground');

# filter
SKIP: {
	skip 'filter', 12
		unless Pango->CHECK_VERSION (1, 2, 0);

	# run four times -> 8 tests
	my $callback = sub {
	  my ($attr, $data) = @_;
	  isa_ok ($attr, 'Pango::Attribute');
	  is ($data, 'urgs');
	  return $attr->isa ('Pango::AttrWeight');
	};

	my $list_new = $list->filter ($callback, 'urgs');
	$iter = $list_new->get_iterator;
	my @attrs = $iter->get_attrs;
	is (scalar @attrs, 1);
	isa_ok ($attrs[0], 'Pango::AttrWeight');
	ok ($iter->next);
	ok (!$iter->next);
}

#
# pango_parse_markup()
#

my ($attr_list, $text, $accel_char) =
	Pango->parse_markup
		('<big>this text is <i>really</i> cool</big> (no lie)');
isa_ok ($attr_list, 'Pango::AttrList');
is ($text, 'this text is really cool (no lie)', 'text is stripped of tags');
ok ((not defined $accel_char), 'no accel_char if no accel_marker');

SKIP: {
	skip 'need get_attrs', 7
		unless Pango->CHECK_VERSION (1, 2, 0);

	# first, only <big>
	my $iter = $attr_list->get_iterator;
	my @attrs = $iter->get_attrs;
	is (scalar @attrs, 1);
	isa_ok ($attrs[0], 'Pango::AttrScale');

	# then, <big> and <i>
	$iter->next;
	@attrs = $iter->get_attrs;
	is (scalar @attrs, 2);
	isa_ok ($attrs[0], 'Pango::AttrScale');
	isa_ok ($attrs[1], 'Pango::AttrStyle');

	# finally, only <big> again
	$iter->next;
	@attrs = $iter->get_attrs;
	is (scalar @attrs, 1);
	isa_ok ($attrs[0], 'Pango::AttrScale');
}

($attr_list, $text) = Pango->parse_markup ('no markup here');
isa_ok ($attr_list, 'Pango::AttrList');
is ($text, 'no markup here', 'no tags, nothing stripped');

($attr_list, $text, $accel_char) =
	Pango->parse_markup ('Text with _accel__chars', '_');
isa_ok ($attr_list, 'Pango::AttrList');
is ($text, 'Text with accel_chars');
is ($accel_char, 'a');

# invalid markup causes an exception...
eval { Pango->parse_markup ('<bad>invalid markup') };
isa_ok ($@, 'Glib::Error');
isa_ok ($@, 'Glib::Markup::Error');
is ($@->domain, 'g-markup-error-quark');
ok ($@->matches ('Glib::Markup::Error', 'unknown-element'),
    'invalid markup causes exceptions');
$@ = undef;

__END__

Copyright (C) 2005-2006 by the gtk2-perl team (see the file AUTHORS for the
full list).  See LICENSE for more information.
