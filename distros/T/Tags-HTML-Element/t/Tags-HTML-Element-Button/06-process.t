use strict;
use warnings;

use Data::HTML::Element::Button;
use English;
use Error::Pure::Utils qw(clean);
use Tags::HTML::Element::Button;
use Test::More 'tests' => 6;
use Test::NoWarnings;
use Tags::Output::Raw;

# Test.
my $tags = Tags::Output::Raw->new;
my $obj = Tags::HTML::Element::Button->new(
	'tags' => $tags,
);
my $button = Data::HTML::Element::Button->new;
$obj->init($button);
$obj->process;
my $ret = $tags->flush(1);
my $right_ret = <<'END';
<button type="button"></button>
END
chomp $right_ret;
is($ret, $right_ret, "Button defaults.");

# Test.
$tags = Tags::Output::Raw->new;
$obj = Tags::HTML::Element::Button->new(
	'tags' => $tags,
);
$button = Data::HTML::Element::Button->new(
	'css_class' => 'foo',
	'name' => 'button-name',
	'value' => 'button value',
);
$obj->init($button);
$obj->process;
$ret = $tags->flush(1);
$right_ret = <<'END';
<button type="button" class="foo" name="button-name" value="button value"></button>
END
chomp $right_ret;
is($ret, $right_ret, "Button with attributes and value.");

# Test.
$tags = Tags::Output::Raw->new;
$obj = Tags::HTML::Element::Button->new(
	'tags' => $tags,
);
$button = Data::HTML::Element::Button->new(
	'autofocus' => 1,
	'disabled' => 1,
);
$obj->init($button);
$obj->process;
$ret = $tags->flush(1);
$right_ret = <<'END';
<button type="button" autofocus="autofocus" disabled="disabled"></button>
END
chomp $right_ret;
is($ret, $right_ret, "Button with boolean values.");

# Test.
$tags = Tags::Output::Raw->new;
$obj = Tags::HTML::Element::Button->new(
	'tags' => $tags,
);
$obj->process;
$ret = $tags->flush(1);
$right_ret = '';
is($ret, $right_ret, "Without initialization.");

# Test.
$obj = Tags::HTML::Element::Button->new;
eval {
	$obj->process;
};
is($EVAL_ERROR, "Parameter 'tags' isn't defined.\n", "Parameter 'tags' isn't defined.");
clean();
