use strict;
use warnings;

use CSS::Struct::Output::Indent;
use Data::HTML::Element::Textarea;
use English;
use Error::Pure::Utils qw(clean);
use Tags::HTML::Element::Textarea;
use Test::More 'tests' => 5;
use Test::NoWarnings;

# Test.
my $obj = Tags::HTML::Element::Textarea->new(
	'no_css' => 1,
);
my $ret = $obj->process_css;
is($ret, undef, 'No css mode.');

# Test.
my $css = CSS::Struct::Output::Indent->new,;
$obj = Tags::HTML::Element::Textarea->new(
	'css' => $css,
);
my $textarea = Data::HTML::Element::Textarea->new;
$obj->init($textarea);
$obj->process_css;
$ret = $css->flush(1);
my $right_ret = <<'END';
textarea {
	width: 100%;
	padding: 12px 20px;
	margin: 8px 0;
	display: inline-block;
	border: 1px solid #ccc;
	border-radius: 4px;
	box-sizing: border-box;
}
END
chomp $right_ret;
is($ret, $right_ret, "Textarea defaults.");

# Test.
$css = CSS::Struct::Output::Indent->new,;
$obj = Tags::HTML::Element::Textarea->new(
	'css' => $css,
);
$textarea = Data::HTML::Element::Textarea->new(
	'css_class' => 'foo',
);
$obj->init($textarea);
$obj->process_css;
$ret = $css->flush(1);
$right_ret = <<'END';
textarea.foo {
	width: 100%;
	padding: 12px 20px;
	margin: 8px 0;
	display: inline-block;
	border: 1px solid #ccc;
	border-radius: 4px;
	box-sizing: border-box;
}
END
chomp $right_ret;
is($ret, $right_ret, "Textarea defaults (with CSS class).");

# Test.
$obj = Tags::HTML::Element::Textarea->new;
eval {
	$obj->process_css;
};
is($EVAL_ERROR, "Parameter 'css' isn't defined.\n", "Parameter 'css' isn't defined.");
clean();
