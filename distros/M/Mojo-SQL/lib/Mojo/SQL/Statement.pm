package Mojo::SQL::Statement;
use Mojo::Base -base, -signatures;

use Scalar::Util qw(blessed);

has [qw(parts values)] => sub { [] };

sub parse ($self, $text, @values) {
  my $escape = "\0";
  $escape .= "\0" while index($text, $escape) >= 0;
  $text =~ s/\?\?/$escape/g;

  my @text_parts = split /\?/, $text, -1;
  @text_parts = ('') unless @text_parts;

  s/\Q$escape\E/?/g for @text_parts;

  my (@merged_parts, @merged_values);
  my $merge_next = 0;
  for my $i (0 .. $#text_parts) {
    if ($merge_next) {
      $merged_parts[-1] .= $text_parts[$i];
      $merge_next = 0;
    }
    else { push @merged_parts, $text_parts[$i] }

    next if $i == $#text_parts;

    my $value = $values[$i];
    if (blessed($value) && $value->isa('Mojo::SQL::Statement')) {
      my @value_parts = @{$value->parts};
      $merged_parts[-1] .= shift @value_parts;
      push @merged_parts,  @value_parts;
      push @merged_values, @{$value->values};
      $merge_next = 1;
    }
    else { push @merged_values, $value }
  }

  $self->{parts}  = \@merged_parts;
  $self->{values} = \@merged_values;

  return $self;
}

sub parse_unsafe ($self, $text, @values) {
  my $escape = "\0";
  $escape .= "\0" while index($text, $escape) >= 0;
  $text =~ s/\?\?/$escape/g;

  my @text_parts = split /\?/, $text, -1;
  s/\Q$escape\E/?/g for @text_parts;

  my @merged;
  for my $i (0 .. $#text_parts) {
    push @merged, $text_parts[$i];
    push @merged, $values[$i] if $i < $#text_parts;
  }
  $self->{parts}  = [join '', @merged];
  $self->{values} = [];

  return $self;
}

sub to_query ($self, $options = {}) { {text => $self->to_string($options), values => $self->values} }

sub to_array ($self, $options = {}) { [$self->to_string($options), @{$self->values}] }

sub to_list ($self, $options = {}) { @{$self->to_array($options)} }

sub to_string ($self, $options = {}) {
  my @query;
  my $placeholder = $options->{placeholder};
  my $parts       = $self->parts;
  for my $i (1 .. scalar @$parts) {
    push @query, $parts->[$i - 1];
    push @query, defined $placeholder ? $placeholder : "\$$i" if defined $parts->[$i];
  }

  return join '', @query;
}

1;

=encoding utf8

=head1 NAME

Mojo::SQL::Statement - SQL statement container

=head1 SYNOPSIS

  use Mojo::SQL::Statement;

  my $stmt  = Mojo::SQL::Statement->new->parse('SELECT * FROM users WHERE name = ?', 'sebastian');
  my $query = $stmt->to_query;

=head1 DESCRIPTION

L<Mojo::SQL::Statement> is a container for an SQL statement and its bind values. Statements are composable by passing
one as a value to another, in which case its parts and values are spliced in recursively.

=head1 ATTRIBUTES

L<Mojo::SQL::Statement> implements the following attributes.

=head2 parts

  my $parts = $stmt->parts;
  $stmt     = $stmt->parts(['SELECT * FROM users WHERE name = ', '']);

The literal SQL fragments around each placeholder, as an array reference. There is always one more fragment than
placeholder.

=head2 values

  my $values = $stmt->values;
  $stmt      = $stmt->values(['sebastian']);

The bind values for each placeholder, as an array reference.

=head1 METHODS

L<Mojo::SQL::Statement> inherits all methods from L<Mojo::Base> and implements the following new ones.

=head2 parse

  $stmt = $stmt->parse('SELECT * FROM users WHERE name = ?', 'sebastian');

Parse an SQL string with C<?> placeholders and bind values into L</"parts"> and L</"values">. L<Mojo::SQL::Statement>
values are spliced in recursively, allowing partial statements to be composed. Literal question marks can be escaped
with C<??>.

=head2 parse_unsafe

  $stmt = $stmt->parse_unsafe("AND role = 'admin'");
  $stmt = $stmt->parse_unsafe('AND ?', "role = 'admin'");

Parse an SQL string where every C<?> slot is replaced literally by the corresponding value. The result has no
placeholders or bind values; use with care, and make sure to escape values yourself with the appropriate escaping
functions for your database. Literal question marks can be escaped with C<??>.

=head2 to_array

  my $array = $stmt->to_array;
  my $array = $stmt->to_array({placeholder => '?'});

Render the statement to an array reference containing the SQL text and bind values, ready to be passed to a database
driver. Accepts the same options as L</"to_query">.

=head2 to_list

  my @list = $stmt->to_list;
  my @list = $stmt->to_list({placeholder => '?'});

Same as L</"to_array"> but returns a list.

=head2 to_query

  my $query = $stmt->to_query;
  my $query = $stmt->to_query({placeholder => '?'});

Render the statement to a query hash reference with C<text> and C<values> keys, ready to be passed to a database
driver.

These options are currently available:

=over 2

=item placeholder

  placeholder => '?'

Placeholder character to use, defaults to numbered placeholders like C<$1> and C<$2>.

=back

=head2 to_string

  my $string = $stmt->to_string;
  my $string = $stmt->to_string({placeholder => '?'});

Render just the SQL string portion of the statement. Accepts the same options as L</"to_query">.

=head1 SEE ALSO

L<Mojo::SQL>, L<Mojolicious>, L<https://mojolicious.org>.

=cut
