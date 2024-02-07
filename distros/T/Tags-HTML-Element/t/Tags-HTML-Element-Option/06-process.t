use strict;
use warnings;

use Data::HTML::Element::Option;
use English;
use Error::Pure::Utils qw(clean);
use Tags::HTML::Element::Option;
use Test::More 'tests' => 7;
use Test::NoWarnings;
use Tags::Output::Raw;

# Test.
my $tags = Tags::Output::Raw->new;
my $option = Data::HTML::Element::Option->new;
my $obj = Tags::HTML::Element::Option->new(
	'tags' => $tags,
);
$obj->init($option);
$obj->process;
my $ret = $tags->flush(1);
my $right_ret = <<'END';
<option></option>
END
chomp $right_ret;
is($ret, $right_ret, "Option defaults.");

# Test.
$tags = Tags::Output::Raw->new;
$option = Data::HTML::Element::Option->new(
	'id' => 'one',
	'data' => ['Option'],
);
$obj = Tags::HTML::Element::Option->new(
	'tags' => $tags,
);
$obj->init($option);
$obj->process;
$ret = $tags->flush(1);
$right_ret = <<'END';
<option id="one">Option</option>
END
chomp $right_ret;
is($ret, $right_ret, "Option (plain).");

# Test.
$tags = Tags::Output::Raw->new;
$option = Data::HTML::Element::Option->new(
	'id' => 'one',
	'data' => [['d', 'Option']],
	'data_type' => 'tags',
);
$obj = Tags::HTML::Element::Option->new(
	'tags' => $tags,
);
$obj->init($option);
$obj->process;
$ret = $tags->flush(1);
$right_ret = <<'END';
<option id="one">Option</option>
END
chomp $right_ret;
is($ret, $right_ret, "Option (tags).");

# Test.
$tags = Tags::Output::Raw->new;
$option = Data::HTML::Element::Option->new(
	'id' => 'one',
	'data' => [sub {
		my $self = shift;
		$self->{'tags'}->put(['d', 'Option']);
		return;
	}],
	'data_type' => 'cb',
);
$obj = Tags::HTML::Element::Option->new(
	'tags' => $tags,
);
$obj->init($option);
$obj->process;
$ret = $tags->flush(1);
$right_ret = <<'END';
<option id="one">Option</option>
END
chomp $right_ret;
is($ret, $right_ret, "Option (callback).");

# Test.
$tags = Tags::Output::Raw->new;
$obj = Tags::HTML::Element::Option->new(
	'tags' => $tags,
);
$obj->process;
$ret = $tags->flush(1);
$right_ret = '';
is($ret, $right_ret, "Without initialization.");

# Test.
$obj = Tags::HTML::Element::Option->new;
eval {
	$obj->process;
};
is($EVAL_ERROR, "Parameter 'tags' isn't defined.\n", "Parameter 'tags' isn't defined.");
clean();

