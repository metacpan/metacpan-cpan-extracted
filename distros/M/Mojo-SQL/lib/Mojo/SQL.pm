package Mojo::SQL;
use Mojo::Base 'Exporter', -signatures;

use Mojo::SQL::Statement;

our $VERSION = '0.02';

our @EXPORT_OK = qw(escape_identifier escape_literal sql sql_unsafe);

sub escape_identifier ($identifier) {
  my $string = "$identifier";
  $string =~ s/"/""/g;
  return qq{"$string"};
}

sub escape_literal ($literal) {
  my $string = "$literal";
  my $escape = $string =~ /\\/ ? 1 : 0;
  $string =~ s/\\/\\\\/g;
  $string =~ s/'/''/g;
  return $escape ? qq{ E'$string'} : qq{'$string'};
}

sub sql ($text, @values) { Mojo::SQL::Statement->new->parse($text, @values) }

sub sql_unsafe ($text, @values) { Mojo::SQL::Statement->new->parse_unsafe($text, @values) }

1;

=encoding utf8

=head1 NAME

Mojo::SQL - Safely generate and compose SQL statements

=head1 SYNOPSIS

  use Mojo::SQL qw(sql);

  # {text => 'SELECT * FROM users WHERE name = $1', values => ['sebastian']}
  my $query = sql('SELECT * FROM users WHERE name = ?', 'sebastian')->to_query;

=head1 DESCRIPTION

L<Mojo::SQL> safely generates and composes SQL statements. To prevent SQL injection attacks, every C<?> in the input
becomes a placeholder in the generated query, with the corresponding value bound to it. Partial statements can be
composed recursively to build more complex queries.

Literal question marks can be escaped with C<??>.

  use Mojo::SQL qw(sql);

  my $role    = 'admin';
  my $partial = sql('AND role = ?', $role);
  my $name    = 'root';

  # {text => 'SELECT * FROM users WHERE name = $1 AND role = $2', values => ['root', 'admin']}
  my $query = sql('SELECT * FROM users WHERE name = ? ?', $name, $partial)->to_query;

Make partial statements optional to dynamically generate C<WHERE> clauses.

  my $optional = $foo ? sql('AND foo IS NOT NULL') : sql('');
  my $query    = sql('SELECT * FROM users WHERE name = ? ?', 'sebastian', $optional)->to_query;

If you need a little more control over the generated SQL query, you can also bypass safety features with
L</"sql_unsafe">. But make sure to handle unsafe values yourself with appropriate escaping functions for your database.
For PostgreSQL there are L</"escape_literal"> and L</"escape_identifier"> functions included with this module.

  use Mojo::SQL qw(sql sql_unsafe escape_literal);

  my $role    = 'role = ' . escape_literal('power user');
  my $partial = sql_unsafe 'AND ?', $role;
  my $name    = 'root';

  # {text => "SELECT * FROM users WHERE name = \$1 AND role = 'power user'", values => ['root']}
  my $query = sql('SELECT * FROM users WHERE name = ? ?', $name, $partial)->to_query;

For databases that do not support numbered placeholders like C<$1> and C<$2>, you can set a custom character with the
C<placeholder> option.

  # {text => 'SELECT * FROM users WHERE name = ?', values => ['root']}
  my $query = sql('SELECT * FROM users WHERE name = ?', 'root')->to_query({placeholder => '?'});

=head1 FUNCTIONS

L<Mojo::SQL> implements the following functions, which can be imported individually.

=head2 escape_identifier

  my $escaped = escape_identifier('some_table');

Escape an identifier (only the PostgreSQL format is currently supported).

=head2 escape_literal

  my $escaped = escape_literal('some value');

Escape a literal (only the PostgreSQL format is currently supported).

=head2 sql

  my $stmt = sql('SELECT * FROM users WHERE name = ?', 'sebastian');

Create a new L<Mojo::SQL::Statement> from an SQL string. Each C<?> in the string becomes a placeholder, and the
corresponding value is bound to it. L<Mojo::SQL::Statement> values are spliced in recursively, so partial statements
can be composed to build more complex queries. Literal question marks can be escaped with C<??>.

=head2 sql_unsafe

  my $stmt = sql_unsafe 'SELECT * FROM users WHERE name = ?', 'sebastian';

Create a new L<Mojo::SQL::Statement> without safe placeholders. Each C<?> in the string is replaced literally by the
corresponding value. Literal question marks can be escaped with C<??>. Use with care.

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2026, Sebastian Riedel.

This program is free software, you can redistribute it and/or modify it under the terms of the MIT license.

=head1 SEE ALSO

L<Mojo::SQL::Statement>, L<Mojolicious>, L<https://mojolicious.org>.

=cut
