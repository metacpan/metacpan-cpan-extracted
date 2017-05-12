package Net::IDN::Nameprep;

use strict;
use utf8;
use warnings;

our $VERSION = "1.102";
$VERSION = eval $VERSION;

require Exporter;
our @ISA    = qw(Exporter);
our @EXPORT = qw(nameprep);

use Unicode::Stringprep 1.1;

use Unicode::Stringprep::Mapping;
use Unicode::Stringprep::Prohibited;

our $_nameprep_stored;
our $_nameprep_query;

sub nameprep {
  my ($input, %param) = @_;
  if (
      !exists($param{'AllowUnassigned'})
   || $param{'AllowUnassigned'}
  ) {
    goto &$_nameprep_query;
  } else {
    goto &$_nameprep_stored;
  }
}

BEGIN {
  my @_common_args = (
    3.2,
    [
      @Unicode::Stringprep::Mapping::B1,
      @Unicode::Stringprep::Mapping::B2
    ],
    'KC',
    [
      @Unicode::Stringprep::Prohibited::C12,
      @Unicode::Stringprep::Prohibited::C22,
      @Unicode::Stringprep::Prohibited::C3,
      @Unicode::Stringprep::Prohibited::C4,
      @Unicode::Stringprep::Prohibited::C5,
      @Unicode::Stringprep::Prohibited::C6,
      @Unicode::Stringprep::Prohibited::C7,
      @Unicode::Stringprep::Prohibited::C8,
      @Unicode::Stringprep::Prohibited::C9
    ],
    1,
  );

  our $_nameprep_stored = Unicode::Stringprep->new(
    @_common_args,
    1,
  );

  our $_nameprep_query = Unicode::Stringprep->new(
    @_common_args,
    0,
  );
}

1;
__END__

=encoding UTF-8

=head1 NAME

Net::IDN::Nameprep - A Stringprep Profile for Internationalized Domain Names (S<RFC 3491>)

=head1 SYNOPSIS

  use Net::IDN::Nameprep;
  $output = nameprep $input;

=head1 DESCRIPTION

This module implements the I<nameprep> specification, which describes how to
prepare internationalized domain name (IDN) labels in order to increase the
likelihood that name input and name comparison work in ways that make sense for
typical users throughout the world.  Nameprep is a profile of the stringprep
protocol and is used as part of a suite of on-the-wire protocols for
internationalizing the Domain Name System (DNS).

=head1 FUNCTIONS

This module implements a single function, C<nameprep>, which is exported by default.

=over

=item nameprep( $input [, AllowUnassigned => 1 ] )

Processes C<$input> according to the I<nameprep> specification and
returns the result.

If C<$input> contains characters not allowed for I<nameprep>, it
throws an exception (so use C<eval> if necessary).

This function takes the following optional parameter:

=over

=item AllowUnassigned

(boolean) If set to a false value, unassigned code points in C<$input> are not allowed.

False MUST be used for I<stored strings>.

True MAY be used for I<queries>.

The default is true (backwards compatibility).

=back

=back

=head1 AUTHOR

Claus FE<auml>rber <CFAERBER@cpan.org>

Previous versions written by Tatsuhiko Miyagawa E<lt>miyagawa@bulknews.netE<gt>

=head1 LICENSE

Copyright 2007-2015 Claus FE<auml>rber.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 SEE ALSO

L<Unicode::Stringprep>, S<RFC 3491> (L<http://www.ietf.org/rfc/rfc3491.txt>)

=cut
