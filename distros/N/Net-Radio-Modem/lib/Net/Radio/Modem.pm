package Net::Radio::Modem;

use 5.010;

use strict;
use warnings;

=head1 NAME

Net::Radio::Modem - Independently access radio network modems (such as 3GPP)

=cut

our $VERSION = '0.002';

=head1 SYNOPSIS

  use Net::Radio::Modem;
  my $modem = Net::Radio::Modem->new('Static', '/test_0' => {
      MNC => '262', MCC => '02', IMSI => '262020555017753',
      LAC => ...}, '/test_1' => { ... } ... );
  my @modems = $modem->get_modems(); # returns ('/test_0', 'test_1', ...)
  my $local_modem = grep {
         $modem->get_modem_property($_, 'MobileCountryCode') == 364
     } @modems; # find the one for Bahamas

  my $real_m = Net::Radio::Modem->new('oFono', {
      dbus_main_runs => 0 # fetch values, don't rely on dbus-signals
  });
  my @rm = $real_m->get_modems();
  my $o2sim = grep {
	 $real_m->get_modem_property($_, 'MCC') == 262 # Germany
     and $real_m->get_modem_property($_, 'MNC') ~~ qw(07 08 11) # O2
     } @rf;

=head1 METHODS

=head2 new($imp;@impl_args)

Instantiates new modem accessor from package C<Net::Radio::Modem::Adapter::$impl>.
If no package C<Net::Radio::Modem::Adapter::$impl> is available,
C<Net::Radio::Modem::Adapter::Null> is used.

C<@impl_args> are passed to the initialisation of the implementation class.

=cut

sub new
{
    my ( $class, $impl, @args ) = @_;

    my $self = bless( {}, $class );

    my $impl_class = _load_plugin($impl);
    $impl_class //= _load_plugin("Net::Radio::Modem::Adapter::Null");

    $self->{impl_class} = $impl_class;
    $self->{impl}       = $impl_class->new(@args);

    return $self;
}

sub _load_plugin
{
    my $plugin = shift;

    $plugin->isa("Net::Radio::Modem::Adapter") and return $plugin;

    ( my $module_file = "$plugin.pm" ) =~ s{::}{/}g;
    defined $INC{$module_file} and return;

    eval { require $module_file; };
    if ($@)
    {
        $plugin =~ m/Net::Radio::Modem::Adapter/
          or return _load_plugin("Net::Radio::Modem::Adapter::$plugin");
    }
    else
    {
        $plugin->isa("Net::Radio::Modem::Adapter") and return $plugin;
    }

    return;
}

=head2 get_modems()

Provides a list of modems available.

=cut

sub get_modems
{
    return $_[0]->{impl}->get_modems();
}

=head2 get_modem_property($modem,$property)

Provides the value of given property for specified modem.
Property can be an L<Net::Radio::Modem::Adapter/Alias|alias name>.

=cut

sub get_modem_property
{
    my $self     = $_[0];
    my $modem    = $_[1];
    my $property = $self->{impl}->get_alias_for( $_[2] );
    $self->{impl}->get_modem_property( $modem, $property );
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

=head1 ROADMAP

Following things will be nice to have:

=over 4

=item *

List of features useful in a perl module (excluding NIH features)

=item *

Class hierarchy with wrapper implementation of required functions
using a configurable adapter class hierarchy.

=item *

Implement I<Composite> and I<Mediator> pattern to allow mocking
of specific values and/or fallback values ...

=item *

Patches

=back

=head1 AUTHOR

Jens Rehsack, C<< <rehsack at cpan.org> >>

=head1 LICENSE AND COPYRIGHT

Copyright 2012 Jens Rehsack.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.


=cut

1;    # End of Net::Radio::Modem
