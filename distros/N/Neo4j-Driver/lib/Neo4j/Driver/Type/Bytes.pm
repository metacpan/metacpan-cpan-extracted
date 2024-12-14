use v5.12;
use warnings;

package Neo4j::Driver::Type::Bytes 1.02;
# ABSTRACT: Represents a Neo4j byte array


# For documentation, see Neo4j::Driver::Types.


use parent 'Neo4j::Types::ByteArray';
use overload '""' => \&_overload_stringify, fallback => 1;


sub as_string {
	return ${+shift};
}


sub _overload_stringify {
	warnings::warnif misc => 'Use as_string() to access byte array values';
	overload::StrVal(shift)
}


1;
