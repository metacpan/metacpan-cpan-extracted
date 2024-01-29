use strict;
use warnings;

use Data::HTML::Element::Select;
use English;
use Error::Pure::Utils qw(clean);
use Tags::HTML::Element::Select;
use Test::More 'tests' => 3;
use Test::NoWarnings;
use Tags::Output::Raw;

# Test.
my $tags = Tags::Output::Raw->new;
my $select = Data::HTML::Element::Select->new;
my $obj = Tags::HTML::Element::Select->new(
	'tags' => $tags,
);
$obj->init($select);
$obj->process;
my $ret = $tags->flush(1);
my $right_ret = <<'END';
<select></select>
END
chomp $right_ret;
is($ret, $right_ret, "Select defaults.");

# Test.
$obj = Tags::HTML::Element::Select->new;
eval {
	$obj->process;
};
is($EVAL_ERROR, "Parameter 'tags' isn't defined.\n", "Parameter 'tags' isn't defined.");
clean();

