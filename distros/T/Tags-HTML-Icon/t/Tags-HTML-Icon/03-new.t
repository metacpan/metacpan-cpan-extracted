use strict;
use warnings;

use English;
use Error::Pure::Utils qw(clean);
use Tags::HTML::Icon;
use Test::More 'tests' => 4;
use Test::NoWarnings;

# Test.
my $obj = Tags::HTML::Icon->new;
isa_ok($obj, 'Tags::HTML::Icon');

# Test.
eval {
	Tags::HTML::Icon->new(
		'css_class' => '1bad',
	);
};
is($EVAL_ERROR, "Parameter 'css_class' has bad CSS class name (number on begin).\n",
	"Parameter 'css_class' has bad CSS class name (number on begin) (1bad).");
clean();

# Test.
eval {
	Tags::HTML::Icon->new(
		'css_class' => '@bad',
	);
};
is($EVAL_ERROR, "Parameter 'css_class' has bad CSS class name.\n",
	"Parameter 'css_class' has bad CSS class name (\@bad).");
clean();
