package Net::Radio::Modem::Adapter::Static;

use 5.010;

use strict;
use warnings;

use Carp qw(croak);

=head1 NAME

Net::Radio::Modem::Adapter::Static - static modem information adapter

=head1 DESCRIPTION

Allows mocking by defining static information for radio modems.

=head1 SYNOPSIS

  use Net::Radio::Modem;
  my $modem = Net::Radio::Modem->new('Static',
      '/test_0' => {
	  MNC => '262', MCC => '02', IMSI => '262020555017753',
	  LAC => ...},
      '/test_1' => { ... } ... );
  my @modems = $modem->get_modems(); # returns ('/test_0', 'test_1', ...)
  my $local_modem = grep {
         $modem->get_modem_property($_, 'MobileCountryCode') == 364
     } @modems; # find the one for Bahamas

To fill in reasonable value, see

=over 4

=item *

L<http://en.wikipedia.org/wiki/List_of_mobile_country_codes>

=item *

L<http://en.wikipedia.org/wiki/Mobile_Network_Code>

=back

=cut

our $VERSION = '0.002';
use base qw(Net::Radio::Modem::Adapter);

=head1 METHODS

=head2 new

Instantiates new static modem adapter.

B<TODO>: clone (depending on refcount?) provided information to allow
further modification in caller.

=cut

sub new
{
    my $class = shift;
    my %params;

    if ( scalar(@_) == 1 and ref( $_[0] ) eq "HASH" )
    {
        %params = %{ $_[0] };
    }
    elsif ( 0 == ( scalar(@_) % 2 ) )
    {
        %params = @_;
    }
    else
    {
        croak("Expecting hash or hash reference as argument(s)");
    }

    my %info;
    foreach my $modem ( keys %params )
    {
        foreach my $property ( keys %{ $params{$modem} } )
        {
            my $value = $params{$modem}->{$property};
	    $property = __PACKAGE__->get_alias_for($property);
            $info{$modem}->{$property} = $value;
        }
    }

    return bless( { config => \%info }, $class );
}

=head2 get_modems

Returns the keys of given initialisation hash as list of known modems.

=cut

sub get_modems
{
    return keys %{ $_[0]->{config} };
}

=head2 get_modem_property

Return the specified modem property, when known. Empty value otherwise.

=cut

sub get_modem_property
{
    my ( $self, $modem, $property ) = @_;

    defined( $self->{config}->{$modem} )
      and defined( $self->{config}->{$modem}->{$property} )
      and return $self->{config}->{$modem}->{$property};

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
