use strict;
use warnings;

use Tags::Output::Indent;
use Test::More 'tests' => 10;

# Test.
my $obj = Tags::Output::Indent->new(
	'xml' => 1,
);
$obj->put(
	['c', 'comment'],
	['c', ' comment '],
);
my $ret = $obj->flush;
my $right_ret = <<'END';
<!--comment-->
<!-- comment -->
END
chomp $right_ret;
is($ret, $right_ret, 'Test simple comment with and without spaces.');

# Test.
$obj->reset;
$obj->put(
	['c', 'comment-'],
);
$ret = $obj->flush;
$right_ret = '<!--comment- -->';
is($ret, $right_ret, 'Test comment with dash on the end.');

# Test.
$obj->reset;
$obj->put(
	['c', '<tag>comment</tag>'],
);
$ret = $obj->flush;
$right_ret = '<!--<tag>comment</tag>-->';
is($ret, $right_ret, 'Test comment with elements.');

# Test.
$obj->reset;
$obj->put(
	['b', 'tag'],
	['c', '<tag>comment</tag>'],
	['e', 'tag'],
);
$ret = $obj->flush;
$right_ret = <<'END';
<tag>
  <!--<tag>comment</tag>-->
</tag>
END
chomp $right_ret;
is($ret, $right_ret, 'Test element with another element commented.');

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
<tag par="val">
  <!--<tag>comment</tag>-->
</tag>
END
chomp $right_ret;
is($ret, $right_ret, 'Test element+params with another element commented.');

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
<!--<tag>comment</tag>-->
<tag par="val">
  data
</tag>
END
chomp $right_ret;
is($ret, $right_ret, 'Test comment between element and params.');

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
<oo>
  <!--<tag>comment</tag>-->
  <tag par="val">
    data
  </tag>
</oo>
END
chomp $right_ret;
is($ret, $right_ret, 'Test comment between element and params - advanced version.');

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
<!--<tag>comment</tag>-->
<tag par="val">
  <![CDATA[data]]>
</tag>
END
chomp $right_ret;
is($ret, $right_ret, 'Test comment between element and params - with cdata inside.');

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
<!--<tag>comment</tag>-->
<tag par="val" />
END
chomp $right_ret;
is($ret, $right_ret, 'Test comment between element and param - simple element.');

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
<tag1>
  <tag2>
    <!-- comment -->
  </tag2>
</tag1>
END
chomp $right_ret;
is($ret, $right_ret, 'Test comment between two elements.');
