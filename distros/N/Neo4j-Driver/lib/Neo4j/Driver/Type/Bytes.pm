use 5.010;
use strict;
use warnings;
use utf8;

package Neo4j::Driver::Type::Bytes;
# ABSTRACT: Represents a Neo4j byte array
$Neo4j::Driver::Type::Bytes::VERSION = '0.48';

# For documentation, see Neo4j::Driver::Types.


use parent -norequire, 'Neo4j::Types::ByteArray';
use overload '""' => \&_overload_stringify, fallback => 1;


sub as_string {
	return ${+shift};
}


sub _overload_stringify {
	warnings::warnif deprecated => "Direct scalar access is deprecated; use as_string()";
	return ${+shift};
}


package # Compatibility with Neo4j::Types v1
        Neo4j::Types::ByteArray;


1;
