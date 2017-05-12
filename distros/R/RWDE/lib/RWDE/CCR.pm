package RWDE::CCR;

use strict;
use warnings;
use Error qw(:try);

use RWDE::Exceptions;

use Digest::MD5 qw(md5_hex);

use vars qw($VERSION);
$VERSION = sprintf "%d", q$Revision: 558 $ =~ /(\d+)/;

=pod

=head1 RWDE::CCR

Base object to add methods for CCR verification

=cut

=head2 get_ccrcontext()

Return back the class declared ccrcontext if it exists, otherwise generate one from the class name.

We use a pretty general hashing scheme here, it's suggested that this be replaced.

ccrcontext is ultimately used to generate web-safe ids that can't easily be guessed by web robots (or jerks) - although
depending on your hashing scheme you could make this pretty strong, but that has the cost of tying up the webserver
if you frequently end up using these ids in the application.

=cut

sub get_ccrcontext {
  my ($self, $params) = @_;

  my $ccrcontext;

  if (defined($self->{_ccrcontext})) {
    $ccrcontext = $self->{_ccrcontext};
  }
  else {
    $ccrcontext = join '', map ord($_), split //, ref $self;
  }

  return $ccrcontext;
}

=head2 fetch_by_id()

This method is a macro for fetching a single record from the database using either id.enc or ccr. 
This could manually be done using more complicated methods found within the items class, which 
is probably what you want to do if you are trying to do anything fancy.

=cut

sub fetch_by_id {
  my ($self, $params) = @_;

  #this element is used to lookup static variables from the give type
  my $term = $self->new();

  my $id;

  if (defined $$params{ $term->get_id_name() }) {
    $id = $$params{ $term->get_id_name() };
  }

  elsif (defined $$params{ $term->get_ccr_name() }) {
    $id = $term->ccr_to_id($$params{ $term->get_ccr_name() });
    throw RWDE::DevelException({ info => "ID hasn't passed the ccr check (check ccr_context): " . $$params{$term->get_ccr_name()} })
    	unless defined $id;

  }

  elsif (defined($$params{ $term->get_enc_name() })) {
    $id = $term->decode($$params{ $term->get_enc_name() });
    throw RWDE::DevelException({ info => "ID hasn't passed the ccr or decode check: " . $$params{ $term->get_enc_name() } })
    	unless defined $id;

  }

  else {
    throw RWDE::DevelException({ info => 'Called with no initialization parameter (has to be one of: id, ccr or enc)' });
  }



  return $term->_fetch_by_id({ $term->get_id_name() => $id });
}

=head2 append_ccr($integer[,$context])

Append the check-character to the integer and return the result.
Verify by calling the verify_ccr() method.  Zero-pads the integer to a
five character minimum length string.

The C<$context> parameter acts as a salt to change the code based on
context such as owner ID, user ID, etc.

=cut

sub append_ccr {
  my $self    = shift;
  my $int     = shift;
  my $context = shift || 0;

  my $code = '0' x (5 - length($int)) . $int;

  my $ccr = _compute_ccr($code, $context);
  $ccr = lc($ccr) unless $ccr eq 'L';    # help make sure it is easy to read
  return $code . $ccr;
}

=head2 verify_ccr($string[,$context])

Compares the check-character (last character) of C<$string> to a new
one computed against the remaining digits.  Returns $string without
CCR if they match or undef if not.  C<$string> should be of the form
C<\d+[A-Z]> and C<$context> is as above.

=cut

sub verify_ccr {
  my $self    = shift;
  my $str     = shift;
  my $context = shift || 0;

  return
    unless $str;

  my $check = uc(chop($str));    # last character, force upper case.

  # not valid unless within [A..Z]
  return
    if (ord($check) < ord('A') or ord($check) > ord('Z'));

  return $check eq _compute_ccr($str, $context) ? $str : undef;
}

=head2 _compute_ccr($string[,$context])

Internal routine to do the math to compute the Character Checksum characteR
(ccr) code for a string.

Basically multiplies the ordinal value of each character of the string by
an exponential weight based on its position in the string, and keeps the
sum of these modulo 26.  Returns the letter corresponding to that value.

The intent of this encoding as opposed to the encode() methods above
is to provide a check to prevent typos and quick hack attempts on simple
email messages involving the user/owner ID values.

The $context parameter acts as a salt to change the code based on context
such as owner ID, user ID, etc.

=cut

sub _compute_ccr {
  my $s = shift;
  my $context = shift || 0;

  use integer;

  my $c = 17 + $context;    # some random value
  my $m = 1;                # multiplier weight.
  foreach my $d (split //, $s) {
    $c += ord($d) * $m;
    $c %= 26;
    $m *= 2;
  }

  return chr(ord('A') + $c);
}

=head2 compute_security_code($string)

Method to do the math to compute the MD5 checksum for a string, and
return the last 8 characters to use as a "security" code for
verifying some data.

The $context parameter acts as a salt to change the code based on context
such as owner ID, user ID, etc.

=cut

sub compute_security_code {
  my $self    = shift;
  my $s       = shift;
  my $context = shift || 'aVmK';

  return substr(md5_hex($context, $s), -8);
}

=head2 ccr_to_id($string)

Convert the string to an id number.  Returns undef on failure.

=cut

sub ccr_to_id {
  my $self   = shift;
  my $string = shift;

  use integer;

  $string = $self->verify_ccr($string, $self->get_ccrcontext()) or return;

  my $i = $string;

  $string = ($i - 6_000_000) / 42 - 1;

  $string =~ s/^\+//;    # remove leading "+" from BigInt.

  return $string;
}

=head2 get_ccr()

Returns the encoded value of the derived objects id

=cut

sub get_ccr {
  use integer;
  my ($self) = @_;

  if (!$self->{ccr}) {
    my $id = $self->{_data}->{ $self->{_id} };

    $id = ($id + 1) * 42 + 6_000_000;
    $id =~ s/^\+//;    # remove leading "+" from BigInt.
    $self->{ccr} = $self->append_ccr($id, $self->get_ccrcontext);
  }

  return $self->{ccr};
}

=head2 encode($string)

Returns the value with CCR appended and a hash both based on
$ccrcontext appended to that.  Useful for passing information from form
to form via hidden fields that need to be secured from tampering.  The
string may B<not> contain a dash (-) or comma character.

This produces a shorter encoded result without funny characters in it
that may cause the longer form to break, so is useful for creating
links that people may need to cut-and-paste.

=cut

sub encode {
  my ($self, $val) = @_;

  $val = $self->append_ccr($val, $self->get_ccrcontext);

  return "$val-" . $self->compute_security_code($val, $self->get_ccrcontext);
}

=head2 get_enc()

Returns the encoded value of the derived objects id

=cut

sub get_enc {
  my ($self) = @_;
  if (!$self->{enc}) {
    $self->{enc} = $self->encode($self->{_data}->{ $self->{_id} });
  }
  return $self->{enc};
}

=head2 decode($encodedString)

Return the value decoded from the return value of the encode method.  
Throws 'undef' exception if fails.

=cut

sub decode ($) {
  my ($self, $code) = @_;

  throw RWDE::DataMissingException({ info => 'No code provided.' }) unless $code;

  my ($id, $hash) = split /-/, $code;

  throw RWDE::DevelException({ info => "Malformed code hash instantiated from $self string: $code" })
    unless (defined $id and defined $hash);

  if (  $self->compute_security_code($id, $self->get_ccrcontext) eq $hash
    and $id = $self->verify_ccr($id, $self->get_ccrcontext)) {
    return $id + 0;
  }
  else {
    throw RWDE::DevelException({ info => "Cannot decode '$code'" });
  }
}


=head2 get_ccr_name()

Determine the exact label used within the object for storing the ccr value. By convention it's a variation
on the class id label.

=cut

sub get_ccr_name {
  my ($self, $params) = @_;

  my $id_name = $self->get_id_name();

  $id_name =~ s/_id/_ccr/;

  return $id_name;
}

=head2 get_enc_name()

Determine the exact label used within the object for storing the enc value. By convention it's a variation
on the class id label.

=cut

sub get_enc_name {
  my ($self, $params) = @_;

  my $id_name = $self->get_id_name();

  $id_name =~ s/_id/_enc/;

  return $id_name;
}

=head2 compute_md5_rand($string)

Method to do the math to evenly distribute a non-uniformly distributed string input for use as in cases
where we want to randomly select based on a non-random input (ip address for example).
  
=cut
  
sub compute_md5_rand {
  my ($params) = @_;

  #generate hex encoded version
  my $encoded = md5_hex($$params{string});

  #extract first digit
  my $digit;
  if ($encoded =~ m/(\d)/) {
   $digit = $1;
  }

  return $digit;
}

1;
