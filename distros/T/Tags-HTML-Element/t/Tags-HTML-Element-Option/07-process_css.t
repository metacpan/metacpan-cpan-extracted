use strict;
use warnings;

use CSS::Struct::Output::Indent;
use Data::HTML::Element::Option;
use English;
use Error::Pure::Utils qw(clean);
use Tags::HTML::Element::Option;
use Test::More 'tests' => 4;
use Test::NoWarnings;

# Test.
my $css = CSS::Struct::Output::Indent->new,;
my $option = Data::HTML::Element::Option->new;
my $obj = Tags::HTML::Element::Option->new(
	'css' => $css,
);
$obj->init($option);
$obj->process_css;
my $ret = $css->flush(1);
my $right_ret = <<'END';
END
chomp $right_ret;
is($ret, $right_ret, "Option defaults.");

# Test.
$obj = Tags::HTML::Element::Option->new(
	'no_css' => 1,
);
$ret = $obj->process_css;
is($ret, undef, 'No css mode.');

# Test.
$obj = Tags::HTML::Element::Option->new;
eval {
	$obj->process_css;
};
is($EVAL_ERROR, "Parameter 'css' isn't defined.\n", "Parameter 'css' isn't defined.");
clean();
