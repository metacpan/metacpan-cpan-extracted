######################################################################
package Net::Amazon::Request::Seller;
######################################################################
use base qw(Net::Amazon::Request);

##################################################
sub new {
##################################################
    my($class, %options) = @_;

    $class->_assert_options_defined(\%options,
                                   'seller');

    $class->_convert_option(\%options,
                            'seller',
                            'SellerId');

#    $options{IdType} = "Listing";

    my $self = $class->SUPER::new(%options);

    bless $self, $class;   # reconsecrate
}

1;

__END__

=head1 NAME

Net::Amazon::Request::Seller - Class for submitting Seller requests

=head1 SYNOPSIS

  use Net::Amazon;
  use Net::Amazon::Request::Seller;

  my $ua = Net::Amazon->new(
      token       => 'YOUR_AMZN_TOKEN'
  );

  my $req = Net::Amazon::Request::Seller->new( 
      seller  => 'A23JJ2BNHZMFCO'
  );

    # Response is of type Net::Amazon::Response::Seller
  my $resp = $ua->request($req);

=head1 DESCRIPTION

C<Net::Amazon::Request::Seller> is a class used to submit Seller search
requests to the Amazon web service.

The seller to search for is specified in the C<seller> parameter, which
contains the seller's ID (not the seller's nickname!).

Upon success, the responses' C<result()> method will return a single
C<Net::Amazon::Result::Seller> object.

Check L<Net::Amazon::Request> for common request parameters not listed here.

=head2 METHODS

=over 4

=item new( seller => $seller_id )

Constructs a new C<Net::Amazon::Request::Seller> object, used to query
the Amazon web service with the given seller id, and listing id.  As of
AWS4 listing id is a mandatory parameter.

=back

=head1 AUTHOR

Mike Schilli, E<lt>m@perlmeister.comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright 2004 by Mike Schilli E<lt>m@perlmeister.comE<gt>

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself. 

=cut
