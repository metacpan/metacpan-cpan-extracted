package SPVM::JSON;

our $VERSION = "1.001002";

1;

=head1 NAME

SPVM::JSON - JSON

=head1 Description

The JSON class of L<SPVM> has methods to manipulate L<JSON|https://en.wikipedia.org/wiki/JSON>.

=head1 Usage

  use JSON;
  
  # new
  my $json = JSON->new;
  
  # decode
  my $spvm_data = $json->decode($json_data);
  
  # encode
  my $json_data = $json->encode($spvm_data);

=head1 Class Methods

=head2 new

  static method new : JSON ();

Creates a new L<JSON|SPVM::JSON> object.

=head1 Instance Methods

=head2 encode

  method encode : string ($spvm_data : object);

Converts the SPVM data $spvm_data to a JSON data.

A SPVM C<undef> is converted to a JSON C<null>.

A L<Bool|SPVM::Bool> object with the C<value> field of 1 is converted to JSON C<true>.

A L<Bool|SPVM::Bool> object with the C<value> field of 0 is converted to a JSON C<false>.

A SPVM string is converted to a JSON string. C</> in a SPVM string is escaped to C<\/> in a JSON string.

A L<Byte|SPVM::Byte> object is converted to a JSON number.

A L<Short|SPVM::Short> object is converted to a JSON number.

A L<Int|SPVM::Int> object is converted to a JSON number.

A L<Long|SPVM::Long> object is converted to a JSON number.

A L<Float|SPVM::Float> object is converted to a JSON number.

A L<Double|SPVM::Double> object is converted to a JSON number.

A L<List|SPVM::List> object is converted to a JSON array.

A L<Hash|SPVM::Hash> object is converted to a JSON object. The keys are sorted by dictionaly order asc.

Exceptions:

The $spvm_data cannot contain a NaN float value. If so, an exception is thrown.

The $spvm_data cannot contain an inifinity float value. If so, an exception is thrown.

The $spvm_data cannot contain a NaN double value. If so, an exception is thrown.

The $spvm_data cannot contain an inifinity double value. If so, an exception is thrown.

If the $spvm_data contains a value of an invalid type, an exception is thrown.

=head2 decode

  method decode : object ($json_data : string);

Converts the JSON data $json_data to a SPVM data.

A JSON C<null> is converted to a SPVM C<undef>.

A JSON C<true> is converted to a L<Bool|SPVM::Bool> object with the C<value> field of 1.

A JSON C<false> is converted to a L<Bool|SPVM::Bool> object with the C<value> field of 0.

A JSON string is converted to a SPVM string.

A JSON number is converted to a L<Double|SPVM::Double> object. Accuracy may be reduced.

A JSON array is converted to a L<List|SPVM::List> object.

A JSON object is converted to a L<Hash|SPVM::Hash> object.

Exceptions:

If the decoding of the $json_data failed, an exception is thrwon with one of the following messages adding the line number and the column number.

Expected character: "%s". (%s is a string)

Expected token: "%s". (%s is a string)

Invalid string.

Invalid number.

=head1 Repository

L<SPVM::JSON - Github|https://github.com/yuki-kimoto/SPVM-JSON>

=head1 Copyright & License

Copyright (c) 2023 Yuki Kimoto

MIT License
