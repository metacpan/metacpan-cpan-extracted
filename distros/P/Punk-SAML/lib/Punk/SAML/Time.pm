package Punk::SAML::Time;

use 5.010;
use strict;
use warnings;

use Punk::SAML ();

1;

__END__

=head1 NAME

Punk::SAML::Time - xs:dateTime, both ways

=head1 DESCRIPTION

Parses and formats the timestamps SAML compares - C<NotBefore>,
C<NotOnOrAfter>, C<IssueInstant>, C<AuthnInstant> - in UTC.

Accepted: C<[-]YYYY-MM-DDThh:mm:ss[.fraction][Z|(+|-)hh:mm]>. The
fraction is parsed and discarded: assertion lifetimes are minutes, and
carrying sub-second precision would only invite a rounding difference
between the two sides of a comparison.

Refused, each with code C<bad_datetime>:

=over 4

=item * a missing timezone. C<xs:dateTime> permits one and calls the
value local, which is not a thing a protocol timestamp may be, and Core
section 1.3.3 requires UTC

=item * C<24:00> as an end-of-day

=item * a leap second, C<ss> of C<60>. No identity provider emits one,
and accepting it would mean deciding what instant it names

=item * a date that does not exist, such as the 29th of February in a
common year

=back

Comparisons are on epoch seconds. Formatting is always UTC with a
trailing C<Z> and whole seconds: the parser accepts fractions and the
writer never emits them.

=head1 AUTHOR

LNATION, C<< <email at lnation.org> >>

=head1 LICENSE AND COPYRIGHT

This software is Copyright (c) 2026 by LNATION.

This is free software, licensed under the Artistic License 2.0.

=cut
