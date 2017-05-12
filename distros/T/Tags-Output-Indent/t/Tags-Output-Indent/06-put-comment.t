# Pragmas.
use strict;
use warnings;

# Modules.
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
is($ret, $right_ret);

# Test.
$obj->reset;
$obj->put(
	['c', 'comment-'],
);
$ret = $obj->flush;
$right_ret = '<!--comment- -->';
is($ret, $right_ret);

# Test.
$obj->reset;
$obj->put(
	['c', '<tag>comment</tag>'],
);
$ret = $obj->flush;
$right_ret = '<!--<tag>comment</tag>-->';
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
<tag>
  <!--<tag>comment</tag>-->
</tag>
END
chomp $right_ret;
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
<tag par="val">
  <!--<tag>comment</tag>-->
</tag>
END
chomp $right_ret;
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
<!--<tag>comment</tag>-->
<tag par="val">
  data
</tag>
END
chomp $right_ret;
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
<oo>
  <!--<tag>comment</tag>-->
  <tag par="val">
    data
  </tag>
</oo>
END
chomp $right_ret;
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
<!--<tag>comment</tag>-->
<tag par="val">
  <![CDATA[data]]>
</tag>
END
chomp $right_ret;
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
<!--<tag>comment</tag>-->
<tag par="val" />
END
chomp $right_ret;
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
<tag1>
  <tag2>
    <!-- comment -->
  </tag2>
</tag1>
END
chomp $right_ret;
is($ret, $right_ret);
