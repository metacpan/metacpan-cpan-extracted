package Net::Radio::Modem::Adapter::Null;

use 5.010;

use strict;
use warnings;

=head1 NAME

Net::Radio::Modem::Adapter::Null - Null modem adapter

=head1 DESCRIPTION

This radio modem adapter doesn't provide any information.
It simply returns empty results on all requests.

=head1 SYNOPSIS

  use Net::Radio::Modem;
  my $null_modem = Net::Radio::Adapter->new("Null");
  my @empty_list = $null_modem->get_modems();

Sure, it would be easier to get an empty list. But TIAMTWTDO ;)

=cut

our $VERSION = '0.002';
use base qw(Net::Radio::Modem::Adapter);

=head1 METHODS

=head2 new

Initializes Net::Radio::Modem::Adapter::Null object.

=cut

sub new
{
    my $class = shift;
    return bless( {}, $class );
}

=head2 get_modems

Returns an empty list of known modems.

=cut

sub get_modems
{
    return;
}

=head2 get_modem_property

Returns an empty value for the request to the property of not existing modem.

=cut

sub get_modem_property
{
    return;
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
