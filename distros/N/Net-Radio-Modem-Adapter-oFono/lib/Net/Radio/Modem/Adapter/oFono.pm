package Net::Radio::Modem::Adapter::oFono;

use 5.010;

use strict;
use warnings;

use Net::Radio::oFono;

=head1 NAME

Net::Radio::Modem::Adapter::oFono - Adapter to use oFono controlled modems from Net::Radio::Modem

=cut

our $VERSION = '0.001';
use base qw(Net::Radio::Modem::Adapter);

=head1 SYNOPSIS

  use Net::Radio::Modem;
  my $modem = Net::Radio::Modem->new('oFono');
  my @devs = $modem->get_modems();
  my %modem_info => map {
      $_ => {
	  'MNC' => $modem->get_modem_property($_, 'MNC'),
	  'MCC' => $modem->get_modem_property($_, 'MCC'),
	  'IMSI' => $modem->get_modem_property($_, 'IMSI'),
      }
  } @devs;

=head1 METHODS

=head2 new(;\%params)

Instantiates new object proxying between L<Net::Radio::Modem> and
L<Net::Radio::oFono>.

Supported paramaters:

=over 8

=item dbus_main_runs

When set to a false value, all requests to Net::Radio::oFono are
done with enabled force flag. Otherwise the force flag is omitted
or set to a false value.

=back

=cut

sub new
{
    my ( $class, $params ) = @_;
    my %instance;

    @instance{qw(dbus_main_runs serial_number path_pattern)} =
      @$params{qw(dbus_main_runs serial_number path_pattern)};
    $instance{ofono} = Net::Radio::oFono->new();

    return bless( \%instance, $class );
}

=head2 get_modems

Returns list of modems by object path known by oFono.

=cut

sub get_modems
{
    my $self = $_[0];
    return $self->{ofono}->get_modems( !( !$self->{dbus_main_runs} ) );   # avoid vim understands !! as m!!
}

my %oFonoAliases = (
    InternationalMobileSubscriberIdentity => 'SubscriberIdentity',
    MobileSubscriberISDN                  => 'SubscriberNumbers',
    IMSI                                  => 'SubscriberIdentity',
    MSISDN                                => 'SubscriberNumbers',

                   );

=head2 get_aliases

Returns the associative list of known aliases.

Overrides:

    InternationalMobileSubscriberIdentity => 'SubscriberIdentity',
    MobileSubscriberISDN                  => 'SubscriberNumbers',

=cut

sub get_aliases { return ( $_[0]->SUPER::get_aliases(), %oFonoAliases ); }

=head2 get_modem_property

Returns specified property for given modem object path. Following modem
interfaces are queried (in that order): C<NetworkRegistration>,
C<SimManager>, C<Modem>.

=cut

sub get_modem_property
{
    my ( $self, $modem, $property ) = @_;

    for my $if_name (qw(NetworkRegistration SimManager Modem))
    {
        my $value;
        my $if = $self->{ofono}->get_modem_interface( $modem, $if_name );
        $if and $value = $if->GetProperty($property) and return $value;
    }

    return;
}

=head1 BUGS

Please report any bugs or feature requests to
C<bug-net-radio-modem-adapter-ofono at rt.cpan.org>, or through the web
interface at
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Net-Radio-Modem-Adapter-oFono>.
I will be notified, and then you'll automatically be notified of progress on
your bug as I make changes.

If you think you've found a bug then please read "How to Report Bugs
Effectively" by Simon Tatham:
L<http://www.chiark.greenend.org.uk/~sgtatham/bugs.html>.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Net::Radio::Modem::Adapter::oFono

You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Net-Radio-Modem-Adapter-oFono>

If you think you've found a bug then please read "How to Report Bugs
Effectively" by Simon Tatham:
L<http://www.chiark.greenend.org.uk/~sgtatham/bugs.html>.

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Net-Radio-Modem-Adapter-oFono>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Net-Radio-Modem-Adapter-oFono>

=item * Search CPAN

L<http://search.cpan.org/dist/Net-Radio-Modem-Adapter-oFono/>

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

1;    # End of Net::Radio::Modem::Adapter::oFono
