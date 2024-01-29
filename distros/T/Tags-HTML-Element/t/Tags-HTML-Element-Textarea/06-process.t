use strict;
use warnings;

use Data::HTML::Element::Textarea;
use English;
use Error::Pure::Utils qw(clean);
use Tags::HTML::Element::Textarea;
use Test::More 'tests' => 5;
use Test::NoWarnings;
use Tags::Output::Raw;

# Test.
my $tags = Tags::Output::Raw->new;
my $obj = Tags::HTML::Element::Textarea->new(
	'tags' => $tags,
);
my $textarea = Data::HTML::Element::Textarea->new;
$obj->init($textarea);
$obj->process;
my $ret = $tags->flush(1);
my $right_ret = <<'END';
<textarea></textarea>
END
chomp $right_ret;
is($ret, $right_ret, "Textarea defaults.");

# Test.
$tags = Tags::Output::Raw->new;
$obj = Tags::HTML::Element::Textarea->new(
	'tags' => $tags,
);
$textarea = Data::HTML::Element::Textarea->new(
	'autofocus' => 1,
	'disabled' => 1,
	'readonly' => 1,
	'required' => 1,
);
$obj->init($textarea);
$obj->process;
$ret = $tags->flush(1);
$right_ret = <<'END';
<textarea autofocus="autofocus" readonly="readonly" disabled="disabled" required="required"></textarea>
END
chomp $right_ret;
is($ret, $right_ret, "Textarea with boolean values.");

# Test.
$tags = Tags::Output::Raw->new;
$obj = Tags::HTML::Element::Textarea->new(
	'tags' => $tags,
);
$textarea = Data::HTML::Element::Textarea->new(
	'cols' => 2,
	'css_class' => 'foo',
	'form' => 'form-id',
	'id' => 'textarea-id',
	'name' => 'textarea-name',
	'placeholder' => 'Fill value',
	'rows' => 5,
	'value' => 'textarea value',
);
$obj->init($textarea);
$obj->process;
$ret = $tags->flush(1);
$right_ret = <<'END';
<textarea class="foo" id="textarea-id" name="textarea-name" placeholder="Fill value" cols="2" rows="5" form="form-id">textarea value</textarea>
END
chomp $right_ret;
is($ret, $right_ret, "Textarea with attributes and value.");

# Test.
$obj = Tags::HTML::Element::Textarea->new;
eval {
	$obj->process;
};
is($EVAL_ERROR, "Parameter 'tags' isn't defined.\n", "Parameter 'tags' isn't defined.");
clean();
