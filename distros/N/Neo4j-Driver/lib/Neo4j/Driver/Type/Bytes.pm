use 5.010;
use strict;
use warnings;
use utf8;

package Neo4j::Driver::Type::Bytes;
# ABSTRACT: Represents a Neo4j byte array
$Neo4j::Driver::Type::Bytes::VERSION = '0.46';

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

__END__

=pod

=encoding UTF-8

=head1 NAME

Neo4j::Driver::Type::Bytes - Represents a Neo4j byte array

=head1 VERSION

version 0.46

=head1 AUTHOR

Arne Johannessen (L<AJNN|https://metacpan.org/author/AJNN>)

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2016-2024 by Arne Johannessen.

This is free software; you can redistribute it and/or modify it under
the terms of the Artistic License 2.0 or (at your option) the same terms
as the Perl 5 programming language system itself.

=cut
