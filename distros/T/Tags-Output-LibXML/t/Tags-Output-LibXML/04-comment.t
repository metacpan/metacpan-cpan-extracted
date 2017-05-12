# Pragmas.
use strict;
use warnings;

# Modules.
use Tags::Output::LibXML;
use Test::More 'tests' => 11;
use Test::NoWarnings;

# Test.
my $obj = Tags::Output::LibXML->new;
$obj->put(
	['c', 'comment'],
	['c', ' comment '],
);
my $ret = $obj->flush;
my $right_ret = <<'END';
<?xml version="1.1" encoding="UTF-8"?>
<!--comment-->
<!-- comment -->
END
is($ret, $right_ret);

# Test.
$obj->reset;
$obj->put(
	['c', 'comment-'],
);
$ret = $obj->flush;
$right_ret = <<'END';
<?xml version="1.1" encoding="UTF-8"?>
<!--comment- -->
END
is($ret, $right_ret);

# Test.
$obj->reset;
$obj->put(
	['c', '<tag>comment</tag>'],
);
$ret = $obj->flush;
$right_ret = <<'END';
<?xml version="1.1" encoding="UTF-8"?>
<!--<tag>comment</tag>-->
END
is($ret, $right_ret);

# Test.
$obj->reset;
$obj->put(
	['b', 'tag'],
	['c', '<tag>comment</tag>'],
	['e', 'tag'],
);
$ret = $obj->flush;
$right_ret = <<'END';
<?xml version="1.1" encoding="UTF-8"?>
<tag><!--<tag>comment</tag>--></tag>
END
is($ret, $right_ret);

# Test.
$obj->reset;
$obj->put(
	['b', 'tag'],
	['a', 'par', 'val'],
	['c', '<tag>comment</tag>'],
	['e', 'tag'],
);
$ret = $obj->flush;
$right_ret = <<'END';
<?xml version="1.1" encoding="UTF-8"?>
<tag par="val"><!--<tag>comment</tag>--></tag>
END
is($ret, $right_ret);

# Test.
$obj->reset;
$obj->put(
	['b', 'tag'],
	['c', '<tag>comment</tag>'],
	['a', 'par', 'val'],
	['d', 'data'],
	['e', 'tag'],
);
$ret = $obj->flush;
$right_ret = <<'END';
<?xml version="1.1" encoding="UTF-8"?>
<tag par="val"><!--<tag>comment</tag>-->data</tag>
END
is($ret, $right_ret);

# Test.
$obj->reset;
$obj->put(
	['b', 'oo'],
	['b', 'tag'],
	['c', '<tag>comment</tag>'],
	['a', 'par', 'val'],
	['d', 'data'],
	['e', 'tag'],
	['e', 'oo'],
);
$ret = $obj->flush;
$right_ret = <<'END';
<?xml version="1.1" encoding="UTF-8"?>
<oo><tag par="val"><!--<tag>comment</tag>-->data</tag></oo>
END
is($ret, $right_ret);

# Test.
$obj->reset;
$obj->put(
	['b', 'tag'],
	['c', '<tag>comment</tag>'],
	['a', 'par', 'val'],
	['cd', 'data'],
	['e', 'tag'],
);
$ret = $obj->flush;
$right_ret = <<'END';
<?xml version="1.1" encoding="UTF-8"?>
<tag par="val"><!--<tag>comment</tag>--><![CDATA[data]]></tag>
END
is($ret, $right_ret);

# Test.
$obj->reset;
$obj->put(
	['b', 'tag'],
	['c', '<tag>comment</tag>'],
	['a', 'par', 'val'],
	['e', 'tag'],
);
$ret = $obj->flush;
$right_ret = <<'END';
<?xml version="1.1" encoding="UTF-8"?>
<tag par="val"><!--<tag>comment</tag>--></tag>
END
is($ret, $right_ret);

# Test.
$obj->reset;
$obj->put(
	['b', 'tag1'],
	['b', 'tag2'],
	['c', ' comment '],
	['e', 'tag2'],
	['e', 'tag1'],
);
$ret = $obj->flush;
$right_ret = <<'END';
<?xml version="1.1" encoding="UTF-8"?>
<tag1><tag2><!-- comment --></tag2></tag1>
END
is($ret, $right_ret);
