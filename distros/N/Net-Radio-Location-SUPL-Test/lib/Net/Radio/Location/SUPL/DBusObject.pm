package Net::Radio::Location::SUPL::DBusObject;

use strict;
use warnings;

use 5.010;

our $VERSION = 0.001;

use base qw(Net::DBus::Object);

=head1 NAME

Net::Radio::Location::SUPL::DBusObject - Base class of all SUPL DBus Objects and configuration handler

=head1 DESCRIPTION

This module manages right dbus initialisation for derived interfaces

=head1 METHODS

=cut

my %config;
my %services;

=head2 new

Instantiates new DBusObject. Typically invoked by a derived class like:

    my ($class, %cfg) = @_;
    my $self = $class->SUPER::new(%cfg);

    bless( $self, $class );

    Net::Radio::Location::SUPL::MainLoop->add($self);

    return $self;

Arguments:

=over 8

=item bus-name

name in the d-bus system on session bus to bind the service on

=item object-path

object path where the instance is reachable

=back

=cut

sub new
{
    my ( $class, %cfg ) = @_;
    my $service = _service(%cfg);
    my $self = $class->SUPER::new( $service, _object_path(%cfg) );

    bless( $self, $class );

    $self->{config} = \%cfg;

    return $self;
}

sub _bus_name
{
    my %cfg = @_;
    return $cfg{'bus-name'} // $config{'bus-name'} // "org.vfnet.supl";
}

sub _service
{
    my $bus_name = _bus_name(@_);
    unless ( defined( $services{$bus_name} ) )
    {
        my $bus = Net::DBus->find();
        $services{$bus_name} = Net::DBus::Service->new( $bus, $bus_name );
    }

    return $services{$bus_name};
}

sub _object_path
{
    my %cfg = @_;
    return $cfg{'object-path'} // $config{'object-path'} // "/org/vfnet/supl";
}

=head2 set_default_config

Takes the given configuration and stores it as default configuration.
Overrides built-in configuration.

=cut

sub set_default_config
{
    %config = @_;
}

=head1 BUGS

Please report any bugs or feature requests to
C<bug-supl-test at rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=SUPL-Test>.
I will be notified, and then you'll automatically be notified of progress
on your bug as I make changes.

If you think you've found a bug then please read "How to Report Bugs
Effectively" by Simon Tatham:
L<http://www.chiark.greenend.org.uk/~sgtatham/bugs.html>.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Net::Radio::Location::SUPL::Test

You can also look for information at:

=over 4

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=SUPL-Test>

If you think you've found a bug then please read "How to Report Bugs
Effectively" by Simon Tatham:
L<http://www.chiark.greenend.org.uk/~sgtatham/bugs.html>.

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/SUPL-Test>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/SUPL-Test>

=item * Search CPAN

L<http://search.cpan.org/dist/SUPL-Test/>

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
