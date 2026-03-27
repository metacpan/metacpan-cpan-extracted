package TOON::Error;

use v5.40;
use feature 'signatures';
use overload '""' => 'as_string', fallback => 1;

our $VERSION = '0.0.1';

sub new ($class, %args) {
  return bless {
    message => $args{message} // 'Unknown TOON error',
    line    => $args{line}    // 1,
    column  => $args{column}  // 1,
    offset  => $args{offset}  // 0,
  }, $class;
}

sub message ($self) { return $self->{message} }
sub line    ($self) { return $self->{line} }
sub column  ($self) { return $self->{column} }
sub offset  ($self) { return $self->{offset} }

sub as_string ($self, @) {
  return sprintf '%s at line %d, column %d',
    $self->{message}, $self->{line}, $self->{column};
}

1;

__END__

=head1 NAME

TOON::Error - Exception object for TOON parse and encode errors

=head1 SYNOPSIS

  use TOON;

  eval { TOON->new->decode($bad_input) };
  if (my $err = $@) {
    printf "Error: %s\n",    $err->message;
    printf "  at line %d, column %d (offset %d)\n",
      $err->line, $err->column, $err->offset;
  }

=head1 DESCRIPTION

TOON::Error is thrown by L<TOON> and L<TOON::PP> whenever a parse or
encode error is encountered. The object stringifies to a human-readable
message of the form:

  <message> at line <line>, column <column>

=head1 METHODS

=head2 new

  my $err = TOON::Error->new(
    message => 'Unexpected character',
    line    => 3,
    column  => 7,
    offset  => 42,
  );

Creates and returns a new TOON::Error object. All parameters are
optional and default to sensible values (message: C<'Unknown TOON
error'>, line: C<1>, column: C<1>, offset: C<0>).

=head2 message

  my $msg = $err->message;

Returns the human-readable description of the error.

=head2 line

  my $line = $err->line;

Returns the 1-based line number in the input at which the error
occurred.

=head2 column

  my $col = $err->column;

Returns the 1-based column number in the input at which the error
occurred.

=head2 offset

  my $offset = $err->offset;

Returns the 0-based character offset in the input at which the error
occurred.

=head2 as_string

  my $str = "$err";   # or $err->as_string

Returns a string representation of the error in the form
C<< <message> at line <line>, column <column> >>. This method is also
invoked automatically when the object is used in a string context.

=head1 AUTHOR

Dave Cross <dave@perlhacks.com>

=cut
