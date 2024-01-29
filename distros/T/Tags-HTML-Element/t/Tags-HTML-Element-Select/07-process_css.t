use strict;
use warnings;

use CSS::Struct::Output::Indent;
use Data::HTML::Element::Select;
use English;
use Error::Pure::Utils qw(clean);
use Tags::HTML::Element::Select;
use Test::More 'tests' => 4;
use Test::NoWarnings;

# Test.
my $css = CSS::Struct::Output::Indent->new,;
my $select = Data::HTML::Element::Select->new;
my $obj = Tags::HTML::Element::Select->new(
	'css' => $css,
);
$obj->init($select);
$obj->process_css;
my $ret = $css->flush(1);
my $right_ret = <<'END';
select {
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
is($ret, $right_ret, "Select defaults.");

# Test.
$obj = Tags::HTML::Element::Select->new(
	'no_css' => 1,
);
$ret = $obj->process_css;
is($ret, undef, 'No css mode.');

# Test.
$obj = Tags::HTML::Element::Select->new;
eval {
	$obj->process_css;
};
is($EVAL_ERROR, "Parameter 'css' isn't defined.\n", "Parameter 'css' isn't defined.");
clean();
