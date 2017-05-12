package Net::Radio::Modem::Adapter;

use 5.010;

use strict;
use warnings;

=head1 NAME

Net::Radio::Modem::Adapter - base class for adapters to access radio network modems

=head1 METHODS

=cut

our $VERSION = '0.002';
my %aliases = (
                MNC    => 'MobileNetworkCode',
                MCC    => 'MobileCountryCode',
                IMSI   => 'InternationalMobileSubscriberIdentity',
                SNR    => 'SerialNumber',
                LAC    => 'LocationAreaCode',
                MSISDN => 'MobileSubscriberISDN',
                CI     => 'CellId',
              );

=head2 get_aliases

Returns the associative list of known aliases.

C<Net::Radio::Modem::Adapter> known only abbreviations:

    MNC    => 'MobileNetworkCode',
    MCC    => 'MoileCountryCode',
    IMSI   => 'InternationalMobileSubscriberIdentity',
    SNR    => 'SerialNumber',
    LAC    => 'LocationAreaCode',
    MSISDN => 'MobileSubscriberISDN',
    CI     => 'CellId',

But derived classes may know more.

=cut

sub get_aliases { return %aliases; }

=head2 get_alias_for($property)

Returns the alias for given property if known, the property (name) otherwise.

  $adapter->get_alias_for('MNC'); # returns MobileNetworkCode
  $adapter->get_alias_for('CellId'); # returns CellId

=cut

sub get_alias_for
{
    my %a = $_[0]->get_aliases();
    defined $a{ $_[1] } and return $a{ $_[1] };
    return $_[1];
}

=head2 new

Placeholder for initalization routine / constructor for derived N:R:M:A

Throws "unimplemented".

=cut

sub new
{
    die "unimplemented";    # with v5.12 we can use ...
}

=head2 get_modems

Placeholder for method returning the list of known modems.

Throws "unimplemented".

=cut

sub get_modems
{
    die "unimplemented";    # with v5.12 we can use ...
}

=head2 get_modem_property

Placeholder for method returning the value of named property for specified
modem device.

Throws "unimplemented".

=cut

sub get_modem_property
{
    die "unimplemented";    # with v5.12 we can use ...
}

=head1 BUGS

Please report any bugs or feature requests to C<bug-net-radio-modem at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Net-Radio-Modem>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

If you think you've found a bug then please read "How to Report Bugs
Effectively" by Simon Tatham:
L<http://www.chiark.greenend.org.uk/~sgtatham/bugs.html>.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Net::Radio::Modem

You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Net-Radio-Modem>

If you think you've found a bug then please read "How to Report Bugs
Effectively" by Simon Tatham:
L<http://www.chiark.greenend.org.uk/~sgtatham/bugs.html>.

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Net-Radio-Modem>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Net-Radio-Modem>

=item * Search CPAN

L<http://search.cpan.org/dist/Net-Radio-Modem/>

=back

=head2 Where can I go for help with a concrete version?

Bugs and feature requests are accepted against the latest version
only. To get patches for earlier versions, you need to get an
agreement with a developer of your choice - who may or not report the
issue and a suggested fix upstream (depends on the license you have
chosen).

=head2 Business support and maintenance

For business support you can contact Jens via his CPAN email
address rehsackATcpan.org. Please keep in mind that business
support is neither available for free nor are you eligible to
receive any support based on the license distributed with this
package.

=head1 ACKNOWLEDGEMENTS

=head1 AUTHOR

Jens Rehsack, C<< <rehsack at cpan.org> >>

=head1 LICENSE AND COPYRIGHT

Copyright 2012 Jens Rehsack.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.

=cut

1;
