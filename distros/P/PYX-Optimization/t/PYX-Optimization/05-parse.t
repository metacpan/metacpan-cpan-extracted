use strict;
use warnings;

use PYX::Optimization;
use Test::More 'tests' => 7;
use Test::NoWarnings;
use Test::Output;
use Unicode::UTF8 qw(decode_utf8);

# Test.
my $obj = PYX::Optimization->new;
my $right_ret = <<"END";
_comment
_comment
_comment
_comment
_comment
_comment
END
stdout_is(
	sub {
		my $data = <<'END';
_comment
_   comment
_comment    
_\ncomment
_comment\n
_   \n   comment   \n    
_  \n  
END
		$obj->parse($data);
		return;
	},
	$right_ret,
	'Dfferent comments which are cleaned.',
);

# Test.
$right_ret = <<"END";
-data
-data
-data
-data
-data
-data
END
stdout_is(
	sub {
		my $data = <<'END';
-data
-   data
-data   
-\ndata
-data\n
-   \n   data   \n   
-   \n
END
		$obj->parse($data);
		return;
	},
	$right_ret,
	'Different data which are cleaned (simple).',
);

# Test.
$right_ret = <<"END";
-data data
-data data
-data data
-data data
-data data
-data data
END
stdout_is(
	sub {
		my $data = <<'END';
-data data
-   data data
-data   data
-\ndata data
-data\ndata
-   data\n   data   \n   
END
		$obj->parse($data);
		return;
	},
	$right_ret,
	'Different data which are cleaned (multiple).',
);

# Test.
$right_ret = <<"END";
_comment
(tag
Aattr value
-data
)tag
?app vskip="10px"
END
stdout_is(
	sub {
		my $data = <<'END';
_   \n   comment   \n   
(tag
Aattr value
-   \n   data   \n   
)tag
?app vskip="10px"
END
		$obj->parse($data);
		return;
	},
	$right_ret,
	'Complex data which are cleaned.',
);

# Test.
$right_ret = <<'END';
-žluťoučký
-žluťoučký
-žluťoučký
-žluťoučký
-žluťoučký
-žluťoučký
END
stdout_is(
	sub {
		my $data = decode_utf8(<<'END');
-žluťoučký
-   žluťoučký
-žluťoučký   
-\nžluťoučký
-žluťoučký\n
-   \n   žluťoučký   \n   
-   \n
END
		$obj->parse($data);
		return;
	},
	$right_ret,
	'Different data which are cleaned (simple - utf8).',
);

# Test.
$right_ret = <<'END';
(žlutá
Aattr červená
)žlutá
?app color=červená
END
stdout_is(
	sub {
		my $data = decode_utf8(<<'END');
(žlutá
Aattr červená
)žlutá
?app color=červená
END
		$obj->parse($data);
		return;
	},
	$right_ret,
	'PYX rewrite in utf8.',
);
