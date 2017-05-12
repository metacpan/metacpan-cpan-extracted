package Net::Radio::oFono::NetworkOperator;

use 5.010;
use strict;
use warnings;

=head1 NAME

Net::Radio::oFono::NetworkOperator - provide NetworkOperator API for objects managed by NetworkRegistration

=cut

our $VERSION = '0.001';

use Net::DBus qw(:typing);

# R/O
use base
  qw(Net::Radio::oFono::Helpers::EventMgr Net::Radio::oFono::Roles::RemoteObj Net::Radio::oFono::Roles::Properties);

=head1 SYNOPSIS

  my $oFono = Net::Location::oFono->new();
  my @modems = Net::Location::oFono->get_modems();
  foreach my $modem_path (@modems) {
    my $simmgr = Net::Location::oFono->get_modem_interface($modem_path, "SimManager");
    $simmgr->GetProperty("SubscriberIdentity") eq $cfg{IMSI} # identify right one
      or next;
    my $netreg = Net::Location::oFono->get_modem_interface($modem_path, "NetworkRegistration");
    my %operators = $netreg->GetOperators();
    foreach my $oper_path (keys %operators) {
      my $oper = $netreg->GetOperator($oper_path);
      if( $oper->GetProperty("Name") =~ $pref ) {
	$oper->Register();
	last;
      }
    }
  }

=head1 DESCRIPTION

This class provide NetworkOperator API for objects managed by
L<Net::Radio::oFono::NetworkRegistration|NetworkRegistration>.

=head1 INHERITANCE

  Net::Radio::oFono::NetworkOperator
  ISA Net::Radio::oFono::Helpers::EventMgr
  DOES Net::Radio::oFono::Roles::RemoteObj
  DOES Net::Radio::oFono::Roles::Properties

=head1 METHODS

See C<ofono/doc/network-api.txt> for valid properties and detailed
action description and possible errors.

=head2 new

=cut

sub new
{
    my ( $class, $obj_path, %events ) = @_;

    my $self = $class->SUPER::new(%events);

    bless( $self, $class );

    $self->_init($obj_path);
    $self->GetProperties(1);

    return $self;
}

sub _init
{
    my ( $self, $obj_path ) = @_;

    ( my $interface = ref($self) ) =~ s/Net::Radio::oFono:://;

    # initialize roles
    $self->Net::Radio::oFono::Roles::RemoteObj::_init( $obj_path, "org.ofono.$interface" );
    $self->Net::Radio::oFono::Roles::Properties::_init();

    return;
}

sub DESTROY
{
    my $self = $_[0];

    # destroy roles
    $self->Net::Radio::oFono::Roles::Properties::DESTROY();
    $self->Net::Radio::oFono::Roles::RemoteObj::DESTROY();

    # destroy base class
    $self->Net::Radio::oFono::Helpers::EventMgr::DESTROY();

    return;
}

=head2 Register()

Attempts to register to this network operator.

The method will return immediately, the result should be observed by
tracking the NetworkRegistration Status property.

=cut

sub Register
{
    my ($self) = @_;

    $self->{remote_obj}->Register();

    return;
}

=head1 BUGS

Please report any bugs or feature requests to C<bug-net-radio-ofono at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Net-Radio-oFono>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

If you think you've found a bug then please read "How to Report Bugs
Effectively" by Simon Tatham:
L<http://www.chiark.greenend.org.uk/~sgtatham/bugs.html>.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Net::Radio::oFono

You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Net-Radio-oFono>

If you think you've found a bug then please read "How to Report Bugs
Effectively" by Simon Tatham:
L<http://www.chiark.greenend.org.uk/~sgtatham/bugs.html>.

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Net-Radio-oFono>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Net-Radio-oFono>

=item * Search CPAN

L<http://search.cpan.org/dist/Net-Radio-oFono/>

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

At first the guys from the oFono-Team shall be named: Marcel Holtmann and
Denis Kenzior, the maintainers and all the people named in ofono/AUTHORS.
Without their effort, there would no need for a Net::Radio::oFono module.

Further, Peter "ribasushi" Rabbitson helped a lot by providing hints
and support how to make this API accessor a valuable CPAN module.

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
