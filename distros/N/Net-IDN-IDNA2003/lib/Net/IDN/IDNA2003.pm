package Net::IDN::IDNA2003;

use strict;
use utf8;
use warnings;

our $VERSION = "1.000";
$VERSION = eval $VERSION;

use Carp;
use Exporter;

use Net::IDN::Nameprep 1.1 ();
use Net::IDN::Punycode 1 ();

our @ISA = ('Exporter');
our @EXPORT = ();
our @EXPORT_OK = (
  'idna2003_to_ascii', 
  'idna2003_to_unicode',
);
our %EXPORT_TAGS = ( 'all' => \@EXPORT_OK );

our $IDNA_prefix;
*IDNA_prefix = \'xn--';

sub idna2003_to_ascii {
  use bytes;
  no warnings qw(utf8); # needed for perl v5.6.x

  my ($label,%param) = @_;

  $param{'AllowUnassigned'} = 0 unless exists $param{'AllowUnassigned'};
  $param{'UseSTD3ASCIIRules'} = 1 unless exists $param{'UseSTD3ASCIIRules'};

  if($label =~ m/[^\x00-\x7F]/) {
    $label = Net::IDN::Nameprep::nameprep($label,%param);
  }

  if($param{'UseSTD3ASCIIRules'}) {
    croak 'Invalid label (toASCII, step 3)' if
      $label =~ m/^-/ ||
      $label =~ m/-$/ ||
      $label =~ m/[\x00-\x2C\x2E-\x2F\x3A-\x40\x5B-\x60\x7B-\x7F]/;
  }

  if($label =~ m/[^\x00-\x7F]/) {
    croak 'Invalid label (toASCII, step 5)' if $label =~ m/^$IDNA_prefix/io;
    $label = $IDNA_prefix.(Net::IDN::Punycode::encode_punycode($label));
  }

  croak 'Invalid label length (toASCII, step 8)' if
    length($label) < 1 ||
    length($label) > 63;

  return $label;
}

sub idna2003_to_unicode {
  use bytes;

  my ($label,%param) = @_;
  my $orig = $label;

  $param{'AllowUnassigned'} = 0 unless exists $param{'AllowUnassigned'};
  $param{'UseSTD3ASCIIRules'} = 1 unless exists $param{'UseSTD3ASCIIRules'};

  return eval {
    if($label =~ m/[^\x00-\x7F]/) {
      $label = Net::IDN::Nameprep::nameprep($label,%param);
    }

    my $save3 = $label;
    croak 'Missing IDNA prefix (ToUnicode, step 3)'
      unless $label =~ s/^$IDNA_prefix//io;
    $label = Net::IDN::Punycode::decode_punycode($label);

    my $save6 = to_ascii($label,%param);

    croak 'Invalid label (ToUnicode, step 7)' unless uc($save6) eq uc($save3);

    $label;
  } || $orig;
}

*to_unicode = \&idna2003_to_unicode;
*to_ascii = \&idna2003_to_ascii;

1;

__END__

=encoding utf8

=head1 NAME

Net::IDN::IDNA2003 - Internationalizing Domain Names in Applications (2003) (S<RFC 3490>)

=head1 SYNOPSIS

  use Net::IDN::IDNA2003 ':all';
  my $a = idna2003_to_ascii("müller");

=head1 DESCRIPTION

This module implements the original IDNA standard defined in S<RFC 3490> and
related documents (IDNA2003). You should use this module if you want an exact
implementation of the original IDNA specification.

However, if you just want to convert domain names and don't care which standard
is used internally, you should use L<Net::IDN::Encode> instead.

=head1 FUNCTIONS

By default, this module does not export any subroutines. You may
use the C<:all> tag to import everything.

You can omit the C<'idna2003_'> prefix when accessing the functions with a
full-qualified module name (e.g. you can access C<idna2003_to_unicode> as
C<Net::IDN::IDNA2003::idna2003_to_unicode> or C<Net::IDN::IDNA2003::to_unicode>. 

The following functions are available:

=over

=item idna2003_to_ascii( $label, %param )

This function implements the C<ToASCII> operation from S<RFC 3490>. It converts
a single label C<$label> to ASCII and throws an exception on invalid input. 

This function takes the following optional parameters:

=over

=item AllowUnassigned

(boolean) If set to a false value, unassigned code points in the label are not allowed.

The default is false.

=item UseSTD3ASCIIRules

(boolean) If set to a true value, checks the label for compliance with S<STD 3>
(S<RFC 1123>) syntax for host name parts.

The default is true.

=back

This function does not handle strings that consist of multiple labels (such as
domain names).

=item idna2003_to_unicode( $label, %param )

This function implements the C<ToUnicode> operation from S<RFC 3490>. It
converts a single label C<$label> to Unicode. It will never fail but return the
string as-is if it cannot be converted.

Converts a single label C<$label> to Unicode. to_unicode never fails.

This function takes the same optional parameters as C<to_ascii>,
with the same defaults.

This function does not try to handle strings that consist of multiple labels
(such as domain names).

=back

=head1 AUTHOR

Claus FE<auml>rber <CFAERBER@cpan.org>

=head1 LICENSE

Copyright 2007-2011 Claus FE<auml>rber.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 SEE ALSO

L<Net::IDN::Encode>, L<Net::IDN::Nameprep>, L<Net::IDN::Punycode>, S<RFC 3490>
(L<http://www.ietf.org/rfc/rfc3490.txt>)

=cut
