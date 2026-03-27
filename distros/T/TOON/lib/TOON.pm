package TOON;

use v5.40;
use feature 'signatures';

use Exporter 'import';
use TOON::PP ();

our $VERSION   = '0.0.1';
our @EXPORT_OK = qw(
  encode_toon decode_toon
  to_toon from_toon
);

sub encode_toon ($data, %opts) {
  return TOON::PP->new(%opts)->encode($data);
}

sub decode_toon ($text, %opts) {
  return TOON::PP->new(%opts)->decode($text);
}

sub to_toon   ($data, %opts) { return encode_toon($data, %opts) }
sub from_toon ($text, %opts) { return decode_toon($text, %opts) }

sub new ($class, %opts) {
  return bless {
    pretty    => $opts{pretty}    // 0,
    canonical => $opts{canonical} // 0,
    indent    => $opts{indent}    // 2,
  }, $class;
}

sub encode ($self, $data) {
  return TOON::PP->new(%$self)->encode($data);
}

sub decode ($self, $text) {
  return TOON::PP->new(%$self)->decode($text);
}

sub pretty ($self, $value = 1) {
  $self->{pretty} = $value;
  return $self;
}

sub canonical ($self, $value = 1) {
  $self->{canonical} = $value;
  return $self;
}

sub indent ($self, $value) {
  $self->{indent} = $value if defined $value;
  return $self;
}

1;

__END__

=head1 NAME

TOON - Token-Oriented Object Notation for Perl

=head1 SYNOPSIS

  use TOON qw(encode_toon decode_toon);

  my $text = encode_toon({ answer => 42, active => 1 });
  my $data = decode_toon($text);

=head1 DESCRIPTION

This is a small pure-Perl starter implementation of a TOON encoder/decoder
with an interface inspired by JSON.

This version supports a pragmatic TOON syntax:

=over 4

=item * scalars: null, true, false, numbers, quoted strings

=item * arrays: [ ... ]

=item * objects: { key: value }

=item * bareword object keys consisting of C<[A-Za-z_][A-Za-z0-9_\-]*>

=back

Quoted strings use JSON-style escapes.

=head1 METHODS

=head2 new

  my $toon = TOON->new(%opts);

Creates and returns a new TOON object. Accepts the following optional
named parameters:

=over 4

=item pretty

Boolean. When true, output is formatted with newlines and indentation.
Defaults to C<0>.

=item canonical

Boolean. When true, hash keys are sorted alphabetically in output.
Defaults to C<0>.

=item indent

Integer. Number of spaces per indentation level when C<pretty> is
enabled. Defaults to C<2>.

=back

=head2 encode

  my $text = $toon->encode($data);

Encodes the given Perl data structure into a TOON string and returns it.

=head2 decode

  my $data = $toon->decode($text);

Parses the given TOON string and returns the corresponding Perl data
structure. Throws a L<TOON::Error> exception if the input is invalid.

=head2 pretty

  $toon->pretty;        # enable pretty printing
  $toon->pretty(1);     # enable pretty printing
  $toon->pretty(0);     # disable pretty printing

Enables or disables pretty-printed output. When called without an
argument (or with a true argument), pretty printing is enabled.
Returns the TOON object so that calls can be chained.

=head2 canonical

  $toon->canonical;     # enable canonical output
  $toon->canonical(1);  # enable canonical output
  $toon->canonical(0);  # disable canonical output

Enables or disables canonical (sorted-key) output. Returns the TOON
object so that calls can be chained.

=head2 indent

  $toon->indent(4);

Sets the number of spaces used per indentation level when pretty
printing is enabled. Returns the TOON object so that calls can be
chained.

=head1 FUNCTIONS

=head2 encode_toon

  use TOON qw(encode_toon);
  my $text = encode_toon($data, %opts);

Functional interface to encoding. Encodes the given Perl data structure
into a TOON string and returns it. Accepts the same options as L</new>.

=head2 decode_toon

  use TOON qw(decode_toon);
  my $data = decode_toon($text, %opts);

Functional interface to decoding. Parses the given TOON string and
returns the corresponding Perl data structure. Throws a L<TOON::Error>
exception if the input is invalid. Accepts the same options as L</new>.

=head2 to_toon

  use TOON qw(to_toon);
  my $text = to_toon($data, %opts);

An alias for L</encode_toon>.

=head2 from_toon

  use TOON qw(from_toon);
  my $data = from_toon($text, %opts);

An alias for L</decode_toon>.

=head1 AUTHOR

Dave Cross <dave@perlhacks.com>

=cut
