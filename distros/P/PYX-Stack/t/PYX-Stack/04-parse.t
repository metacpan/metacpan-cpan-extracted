# Pragmas.
use strict;
use warnings;

# Modules.
use English;
use Error::Pure::Utils qw(clean);
use File::Object;
use PYX::Stack;
use Test::More 'tests' => 5;
use Test::NoWarnings;
use Test::Output;

# Directories.
my $data_dir = File::Object->new->up->dir('data');

# Test.
my $obj = PYX::Stack->new(
	'verbose' => 1,
);
my $right_ret = <<'END';
xml
xml/xml2
xml/xml2/xml3
xml/xml2
xml
END
stdout_is(
	sub {
		$obj->parse(<<'END');
(xml
-text
(xml2
(xml3
-text
)xml3
-text
)xml2
-text
)xml
END
		return;
	},
	$right_ret,
	'Simple stack tree.',
);

# Test.
$obj = PYX::Stack->new;
eval {
	$obj->parse(<<'END');
(pyx
END
};
is($EVAL_ERROR, "Stack has some elements.\n", 'Stack has some elements.');
clean();

# Test.
$obj = PYX::Stack->new(
	'bad_end' => 1,
);
eval {
	$obj->parse(<<'END');
(pyx
(data
)pyx
END
};
is($EVAL_ERROR, "Bad end of element.\n", 'Bad end of element.');
clean();

# Test.
# XXX This is a bit problematic.
$obj = PYX::Stack->new;
eval {
	$obj->parse(<<'END');
(pyx
(data
)pyx
END
};
is($EVAL_ERROR, "Stack has some elements.\n", 'Stack has some elements.');
clean();
