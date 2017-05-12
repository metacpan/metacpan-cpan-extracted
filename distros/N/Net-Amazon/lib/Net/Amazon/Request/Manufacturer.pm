######################################
package Net::Amazon::Request::Manufacturer;
######################################
use warnings;
use strict;
use base qw(Net::Amazon::Request);

######################################
sub new {
######################################
   my($class, %options) = @_;

   $class->_assert_options_defined(\%options,
                                   qw(manufacturer));

   $class->_convert_option(\%options,
                            'manufacturer',
                            'Manufacturer');

   my $self = $class->SUPER::new(%options);

   $self->_convert_itemsearch();

   bless $self, $class;   # reconsecrate
}
1;

__END__

=head1 NAME

Net::Amazon::Request::Manufacturer - Class for submitting Manufacturer requests

=head1 SYNOPSIS

  use Net::Amazon;
  use Net::Amazon::Request::Manufacturer;

  my $ua = Net::Amazon->new(
      token       => 'YOUR_AMZN_TOKEN'
  );

  my $req = Net::Amazon::Request::Manufacturer->new( 
      manufacturer  => 'Disney'
  );

    # Response is of type Net::Amazon::Response::Manufacturer
  my $resp = $ua->request($req);

=head1 DESCRIPTION

C<Net::Amazon::Request::Manufacturer> is a class used to submit 
searches for items made by a given manufacturer.

The manufacturer to search for is specified in the C<manufacturer> parameter.

Upon success, the responses' C<properties()> method will return one
or more C<Net::Amazon::Property::*> objects.

=head2 METHODS

=over 4

=item new( manufacturer => $manufacturer )

Constructs a new C<Net::Amazon::Request::Manufacturer> object, used to query
the Amazon web service for an item with the specified manufacturer name.

=back

Check L<Net::Amazon::Request> for common request parameters not listed here.

=head1 AUTHORS

Bill Fitzpatrick
Mike Schilli, E<lt>m@perlmeister.comE<gt>

=cut
