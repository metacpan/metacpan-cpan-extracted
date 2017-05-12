######################################################################
package Net::Amazon::Request::UPC;
######################################################################
use warnings;
use strict;
use base qw(Net::Amazon::Request);

##################################################
sub new {
##################################################
    my($class, %options) = @_;

    $class->_assert_options_defined(\%options, qw(upc));

    $class->_convert_option(\%options, 
                            'upc', 
                            'ItemId');

	$options{'IdType'} = 'UPC';

    my $self = $class->SUPER::new(%options);

    $self->_convert_itemsearch();

    bless $self, $class;   # reconsecrate
}

1;

__END__

=head1 NAME

Net::Amazon::Request::UPC - request class for UPC search

=head1 SYNOPSIS

  use Net::Amazon;
  use Net::Amazon::Request::UPC;

  my $ua = Net::Amazon->new(
      token       => 'YOUR_AMZN_TOKEN'
  );

  my $req = Net::Amazon::Request::UPC->new( 
      upc  => '724381198421',
      mode => 'music',        

  );

    # Response is of type Net::Amazon::Response::UPC
  my $resp = $ua->request($req);

=head1 DESCRIPTION

C<Net::Amazon::Request::UPC> is a class used to submit UPC (product barcode) 
search requests to the Amazon web service.

The UPC number to search for is specified in the C<upc> parameter.
It currently works with the following values of the C<mode> parameter:
C<music>, 
C<classical>,
C<software>,
C<dvd>, 
C<video>,
C<vhs>, 
C<electronics>,
C<pc-hardware>, and 
C<photo>.

Upon success, the response's C<properties()> method will return a single
C<Net::Amazon::Property::Music> object.

=head2 METHODS

=over 4

=item new(upc => $upc)

Constructs a new C<Net::Amazon::Request::UPC> object, used to query
the Amazon web service for an item with the given UPC number.

=back

=head1 AUTHOR

Mike Schilli, E<lt>m@perlmeister.comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright 2003 by Mike Schilli E<lt>m@perlmeister.comE<gt>

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself. 

=cut
