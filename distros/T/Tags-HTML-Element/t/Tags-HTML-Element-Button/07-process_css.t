use strict;
use warnings;

use CSS::Struct::Output::Indent;
use Data::HTML::Element::Button;
use English;
use Error::Pure::Utils qw(clean);
use Tags::HTML::Element::Button;
use Test::More 'tests' => 6;
use Test::NoWarnings;

# Test.
my $css = CSS::Struct::Output::Indent->new;
my $obj = Tags::HTML::Element::Button->new(
	'css' => $css,
);
my $button = Data::HTML::Element::Button->new;
$obj->init($button);
$obj->process_css;
my $ret = $css->flush(1);
my $right_ret = <<'END';
button {
	width: 100%;
	background-color: #4CAF50;
	color: white;
	padding: 14px 20px;
	margin: 8px 0;
	border: none;
	border-radius: 4px;
	cursor: pointer;
}
button:hover {
	background-color: #45a049;
}
END
chomp $right_ret;
is($ret, $right_ret, "Button defaults.");

# Test.
$css = CSS::Struct::Output::Indent->new,;
$obj = Tags::HTML::Element::Button->new(
	'css' => $css,
);
$button = Data::HTML::Element::Button->new(
	'css_class' => 'foo',
);
$obj->init($button);
$obj->process_css;
$ret = $css->flush(1);
$right_ret = <<'END';
button.foo {
	width: 100%;
	background-color: #4CAF50;
	color: white;
	padding: 14px 20px;
	margin: 8px 0;
	border: none;
	border-radius: 4px;
	cursor: pointer;
}
button.foo:hover {
	background-color: #45a049;
}
END
chomp $right_ret;
is($ret, $right_ret, "Button defaults (with CSS class).");

# Test.
$obj = Tags::HTML::Element::Button->new(
	'no_css' => 1,
);
$ret = $obj->process_css;
is($ret, undef, 'No css mode.');

# Test.
$css = CSS::Struct::Output::Indent->new;
$obj = Tags::HTML::Element::Button->new(
	'css' => $css,
);
$obj->process_css;
$ret = $css->flush(1);
$right_ret = '';
is($ret, $right_ret, "Without initialization.");

# Test.
$obj = Tags::HTML::Element::Button->new;
eval {
	$obj->process_css;
};
is($EVAL_ERROR, "Parameter 'css' isn't defined.\n", "Parameter 'css' isn't defined.");
clean();
