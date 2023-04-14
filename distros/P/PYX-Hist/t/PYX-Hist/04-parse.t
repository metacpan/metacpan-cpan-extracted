use strict;
use warnings;

use Capture::Tiny qw(capture);
use English;
use Error::Pure::Utils qw(clean);
use PYX::Hist;
use Test::More 'tests' => 5;
use Test::NoWarnings;

# Test.
my $obj = PYX::Hist->new;
my ($stdout, $stderr) = capture sub {
	$obj->parse(<<'END');
(pyx
(data
-foo
)data
(data
-bar
)data
)pyx
END
};
is($stdout, <<'END', 'Stdout output.');
[ data ] 2
[ pyx  ] 1
END
is($stderr, '', 'Stderr output.');

# Test.
$obj = PYX::Hist->new;
eval {
	$obj->parse(<<'END');
(pyx
END
};
is($EVAL_ERROR, "Stack has some elements.\n", 'Stack has some elements.');
clean();

# Test.
$obj = PYX::Hist->new;
eval {
	$obj->parse(<<'END');
(pyx
(data
)pyx
END
};
is($EVAL_ERROR, "Bad end of element.\n", 'Bad end of element.');
clean();
