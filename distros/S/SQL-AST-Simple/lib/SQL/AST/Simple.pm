package SQL::AST::Simple;

use 5.042;
use warnings;
use FFI::Platypus 2.00;
use JSON::MaybeXS ();
use Carp qw( croak );
use Ref::Util qw( is_plain_arrayref is_plain_hashref );
use Exporter qw( import );

# ABSTRACT: Parse SQL into a plain Perl data structure and back again
our $VERSION = '0.01'; # VERSION


our @EXPORT_OK = qw( parse unparse parse_expr unparse_expr );

my $ffi = FFI::Platypus->new(
    api => 2,
    lang => 'Rust',
);
$ffi->mangler(sub ($name) { "sql_ast_simple$name" });
$ffi->bundle;

my $json = JSON::MaybeXS->new( utf8 => 1 );

$ffi->attach( _free         => ['opaque']                      => 'void'   );
$ffi->attach( _parse        => ['string', 'string', 'opaque*'] => 'opaque' );
$ffi->attach( _parse_expr   => ['string', 'string', 'opaque*'] => 'opaque' );
$ffi->attach( _unparse      => ['string', 'bool',   'opaque*'] => 'opaque' );
$ffi->attach( _unparse_expr => ['string',           'opaque*'] => 'opaque' );

# Copy a Rust allocated C string into a Perl byte string and release it.
sub _take ($ptr) {
    my $str = $ffi->cast( 'opaque' => 'string', $ptr );
    _free($ptr);
    return $str;
}

sub _call ($xsub, @args) {
    my $err;
    my $ptr = $xsub->(@args, \$err);
    unless(defined $ptr) {
        my $msg = defined $err ? _take($err) : 'unknown error';
        utf8::decode($msg);
        croak($msg);
    }
    return _take($ptr);
}

sub _parse_with ($xsub, $sql, %opt) {
    my $dialect = delete $opt{dialect} // 'generic';
    croak("unknown options: @{[ sort keys %opt ]}") if %opt;
    croak("sql must be defined") unless defined $sql;
    utf8::encode($sql);
    return $json->decode(_call($xsub, $dialect, $sql));
}

sub parse ($sql, %opt) {
    return _parse_with(\&_parse, $sql, %opt);
}

sub parse_expr ($sql, %opt) {
    return _parse_with(\&_parse_expr, $sql, %opt);
}

sub unparse ($ast, %opt) {
    my $pretty = delete $opt{pretty} // 0;
    croak("unknown options: @{[ sort keys %opt ]}") if %opt;
    $ast = [$ast] if is_plain_hashref $ast;
    croak("ast must be an array or hash reference") unless is_plain_arrayref $ast;
    my $sql = _call(\&_unparse, $json->encode($ast), !!$pretty);
    utf8::decode($sql);
    return $sql;
}

sub unparse_expr ($expr, %opt) {
    croak("unknown options: @{[ sort keys %opt ]}") if %opt;
    croak("expr must be a hash reference") unless is_plain_hashref $expr;
    my $sql = _call(\&_unparse_expr, $json->encode($expr));
    utf8::decode($sql);
    return $sql;
}

__END__

=pod

=encoding UTF-8

=head1 NAME

SQL::AST::Simple - Parse SQL into a plain Perl data structure and back again

=head1 VERSION

version 0.01

=head1 SYNOPSIS

 use SQL::AST::Simple qw( parse unparse parse_expr unparse_expr );

 my $ast = parse('SELECT a, b FROM t WHERE a > 1', dialect => 'postgresql');

 # $ast is an array reference of statements, each a tree of plain
 # hashes, arrays and scalars.  Poke at it however you like:
 $ast->[0]{Query}{body}{Select}{from}[0]{relation}{Table}{name}[0]{Identifier}{value} = 'u';

 say unparse($ast);   # SELECT a, b FROM u WHERE a > 1

 # Expressions can be handled on their own, without a statement around them:
 $ast->[0]{Query}{body}{Select}{selection} = parse_expr('a > 1 AND b = 2');
 say unparse_expr($ast->[0]{Query}{body}{Select}{selection});   # a > 1 AND b = 2

=head1 DESCRIPTION

This module provides Perl bindings for the Rust
L<sqlparser|https://crates.io/crates/sqlparser> crate.  It
exposes two operations: turning SQL text into the parser's abstract syntax
tree as an ordinary Perl data structure, and turning such a data structure
back into SQL text.  Each comes in a form for whole statements and a form
for a lone expression.  There is no object layer; the tree is what
the crate's serde serialization produces, decoded from JSON.  That keeps
the module small and makes every node the crate knows about available
without any wrapping, at the cost of a somewhat verbose structure.

Nothing is exported by default.

=head1 FUNCTIONS

=head2 parse

 my $ast = parse($sql);
 my $ast = parse($sql, dialect => $name);

Parses C<$sql>, which may contain several semicolon separated statements,
and returns an array reference with one element per statement.  Throws an
exception with the parser's message, including line and column, if the
text cannot be parsed.

Options:

=over 4

=item dialect

Which SQL dialect to parse with.  Defaults to C<generic>, which is the
most permissive.  Recognized names (case insensitive) are C<generic>,
C<ansi>, C<postgresql> (or C<postgres>), C<mysql>, C<sqlite>, C<mssql>,
C<oracle>, C<snowflake>, C<bigquery>, C<redshift>, C<clickhouse>,
C<duckdb>, C<databricks>, C<hive>, C<spark> (or C<sparksql>) and
C<teradata>.

=back

=head2 parse_expr

 my $expr = parse_expr($sql);
 my $expr = parse_expr($sql, dialect => $name);

Parses C<$sql> as a single expression, such as the condition of a C<WHERE>
clause, and returns it as a hash reference.  The whole of C<$sql> must be
consumed by the expression; a leading C<WHERE> keyword or anything left
over after the expression is an error.  Takes the same C<dialect> option
as L</parse>.

The result is exactly what appears inside a statement wherever the crate
expects an expression, so it can be spliced into a tree from L</parse>,
for instance as the C<selection> of a C<SELECT>.

=head2 unparse

 my $sql = unparse($ast);
 my $sql = unparse($ast, pretty => 1);

Takes an array reference of statements as returned by L</parse>, or a
single statement hash reference, and returns the SQL text.  Multiple
statements are joined with C<"; ">.  Throws an exception if the structure
does not deserialize into a valid AST.

Options:

=over 4

=item pretty

If true, statements are formatted with indentation and newlines rather
than on a single line, and are joined with C<";\n">.

=back

=head2 unparse_expr

 my $sql = unparse_expr($expr);

Takes an expression hash reference, as returned by L</parse_expr> or
lifted out of a statement, and returns the SQL text.  Throws an exception
if the structure does not deserialize into a valid expression.  There is
no C<pretty> option; expressions are always rendered on one line.

=head1 THE DATA STRUCTURE

The tree mirrors the Rust types of the C<sqlparser> crate one to one, as
serialized by serde.  A few rules of thumb cover most of it:

=over 4

=item *

Rust enums are "externally tagged": a hash with a single key naming the
variant, whose value is the payload.  A C<SELECT> statement is
C<< { Query => {...} } >>, a column reference in an expression is
C<< { Identifier => {...} } >>, a literal is C<< { Value => {...} } >>.
Variants without payload are plain strings.

=item *

Rust structs are hashes keyed by field name; C<Option> fields that are
absent are C<undef>; C<Vec> fields are array references.

=item *

Booleans come back as JSON boolean objects.  When you set a boolean field
yourself use C<\1> or C<\0> (or the C<true>/C<false> constants from your
JSON module).  A plain Perl C<1> would be encoded as a number and rejected
by L</unparse>.

=item *

Numeric literals are kept as strings, exactly as they appeared in the
source, so that precision is never lost.  Any field that holds a string
must be given a Perl string; if you have computed a number, stringify it
first.

=item *

Most nodes carry a C<span> hash recording where they appeared in the
source.  L</unparse> ignores the contents but requires the field to be
present, so the easiest way to build a new node is to parse a small
snippet (with L</parse_expr> for an expression) and lift the piece you
need out of the result, rather than constructing hashes by hand.

=back

The easiest way to learn the shape for a given construct is to parse an
example and dump it.  The exact shape depends on the version of the
crate the bindings are built against, which is pinned in the
distribution's C<ffi/Cargo.toml>; a release that bumps it may change the
structure and will say so in the change log.

=head1 CAVEATS

The parser is syntactic only and deliberately permissive.  It will accept
some SQL that a given database would reject, and occasionally reject
vendor syntax it does not yet know.  Round tripping is not byte for byte:
comments are dropped, keywords are upper cased, and whitespace is
normalized.

Building this distribution requires a Rust toolchain (C<cargo>) at
install time.

=head1 SEE ALSO

=over 4

=item L<https://crates.io/crates/sqlparser>

The parser this module wraps.

=back

=head1 AUTHOR

Graham Ollis <plicease@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2026 by Graham Ollis.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
