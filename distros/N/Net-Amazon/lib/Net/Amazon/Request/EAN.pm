######################################################################
package Net::Amazon::Request::EAN;
######################################################################
use warnings;
use strict;
use base qw(Net::Amazon::Request);

##################################################
sub new {
##################################################
    my($class, %options) = @_;

    $class->_assert_options_defined(\%options, qw(ean));

    $class->_convert_option(\%options, 
                            'ean', 
                            'ItemId');

	$options{'IdType'} = 'EAN';

    my $self = $class->SUPER::new(%options);
    
    $self->_convert_itemsearch();

    bless $self, $class;   # reconsecrate
}

1;

__END__

=head1 NAME

Net::Amazon::Request::EAN - request class for EAN search

=head1 SYNOPSIS

  use Net::Amazon;
  use Net::Amazon::Request::EAN;

  my $ua = Net::Amazon->new(
      token       => 'YOUR_AMZN_TOKEN'
  );

  my $req = Net::Amazon::Request::EAN->new( 
      ean => '5035822647633',
  );

    # Response is of type Net::Amazon::Response::EAN
  my $resp = $ua->request($req);

=head1 DESCRIPTION

C<Net::Amazon::Request::EAN> is a class used to submit EAN search requests to
the Amazon web service.

The EAN number to search for is specified in the C<EAN> parameter.

Upon success, the response's C<properties()> method will return a single
C<Net::Amazon::Property> object.

According to the Amazon E-Commerce Service Developer's Guide (2007-01-15) EAN
searches are only valid in DE, JP, and CA only.  This is patently false.  I
think this is a documenation bug, and is actually for valid for non-US only.

=head2 METHODS

=over 4

=item new(ean => $ean)

Constructs a new C<Net::Amazon::Request::EAN> object, used to query the Amazon
web service for an item with the given EAN number.

=back

=head1 AUTHOR

Christopher Boumenot, E<lt>boumenot@gmail.comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright 2007 by Christopher Boumenot E<lt>boumenot@gmail.comE<gt>

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself. 

=cut
