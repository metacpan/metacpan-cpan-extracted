package Net::Radio::oFono::Roles::RemoteObj;

use 5.010;
use strict;
use warnings;

=head1 NAME

Net::Radio::oFono::Roles::RemoteObj - lifecycle management for remote oFono objects

=head1 DESCRIPTION

This package provides a role for being added to classes which need to access
remote dbus objects of oFono.

=cut

our $VERSION = '0.001';

# Must be a base class of target
# use base qw(Net::Radio::oFono::Helpers::EventMgr);

use Net::DBus qw(:typing);

use Log::Any qw($log);

=head1 SYNOPSIS

Provides remote object lifecycle control for oFono objects/interfaces.

    package Net::Radio::oFono::NewInterface;

    use base qw(Net::Radio::oFono::Helpers::EventMgr? Net::Radio::oFono::Roles::RemoteObj ...);

    use Net::DBus qw(:typing);

    sub new
    {
	my ( $class, %events ) = @_;

	my $self = $class->SUPER::new(%events); # SUPER::new finds first - so EventMgr::new

	bless( $self, $class );

	$self->_init();

	return $self;
    }

    sub _init
    {
	my $self = $_[0];

	# initialize roles
	$self->Net::Radio::oFono::Roles::RemoteObj::_init( "/modem_0", "org.ofono.NewInterface" ); # must be first one
	...

	return;
    }

    sub DESTROY
    {
	my $self = $_[0];

	# destroy roles
	...
	$self->Net::Radio::oFono::Roles::RemoteObj::DESTROY(); # must be last one

	# destroy base class
	$self->Net::Radio::oFono::Helpers::EventMgr::DESTROY();

	return;
    }

=head1 METHODS

=head2 _init

Called to initialize the object. Expects remote object path and interface
name (like L<Net::DBus::RemoteObject>).

=cut

sub _init
{
    my ( $self, $obj_path, $iface ) = @_;

    my $bus = Net::DBus->system();

    $self->{obj_path} = $obj_path;
    $self->{remote_obj} = $bus->get_service("org.ofono")->get_object( $obj_path, $iface );

    return;
}

=head2 obj_path

Returns the DBus object path of the managed remote object

=cut

sub obj_path
{
    return $_[0]->{obj_path};
}

sub DESTROY
{
    my $self = $_[0];

    undef $self->{remote_obj};
    undef $self->{obj_path};

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
