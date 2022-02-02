package SPVM::JSON;

our $VERSION = '0.01';

1;

=head1 NAME

SPVM::JSON - JSON serializing/deserializing

=head1 SYNOPSYS

B<SPVM:>

  use JSON;

  # new
  my $json = JSON->new;

  # decode
  $json->decode($json_text);

  # set the canonical flag on
  $json->set_canonical(1);

  # encode
  my $encoded_json = $json->encode($spvm_data);

B<Perl:>

  use SPVM 'JSON';

  # new
  my $json = SPVM::JSON->new;

  # decode
  $json->decode($json_text);

  # set the canonical flag on
  $json->set_canonical(1);

  # encode
  my $encoded_json = $json->encode($spvm_data);

=head1 DESCRIPTION

B<SPVM::JSON> converts SPVM data structures to JSON and vice versa.

B<SPVM::JSON> is a L<SPVM> module.

B<SPVM is yet before 1.0 released. SPVM is changed without warnings. There will be quite a lot of changes.>

=head1 CLASS METHODS

=head2 new

  static method new : SPVM::JSON ()

Create new L<SPVM::JSON> object that can be used to de/encode JSON strings.

=head1 INSTANCE METHODS

=head2 encode

  method encode : string ($object : object)

Converts the given SPVM data structure (undef or a object of numeric,
L<string>, L<SPVM::JSON::Bool>, L<SPVM::Hash> or L<SPVM::ObjectList>)
to its JSON representation.

=head2 decode

  method decode : object ($json : string)

The opposite of encode: expects a JSON text and tries to parse it, returning
the resulting object. Dies on error. Numbers in a JSON text are converted
to L<SPVM::Double>.

=head2 set_canonical

  method set_canonical : void ($enable : byte)

If C<$enable> is true, then the encode method will output JSON objects by
sorting their keys. This is adding a comparatively high overhead.

=head2 canonical

  method canonical : byte ()

Get the canonical flag.
