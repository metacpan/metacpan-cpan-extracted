#!perl

use strict;
use warnings;

sub fixture_tags_foo_bar_xml {
	<<'EOXML',
<Tagging xmlns="http://s3.amazonaws.com/doc/2006-03-01/">
	<TagSet>
		<Tag>
			<Key>bar</Key>
			<Value>baz</Value>
		</Tag>
		<Tag>
			<Key>foo</Key>
			<Value>bar</Value>
		</Tag>
	</TagSet>
</Tagging>
EOXML
}

sub fixture_tags_foo_bar_hashref {
	+{ foo => 'bar', 'bar' => 'baz' },
}


1;
