######################################################################
package Net::Amazon::Request::Exchange;
######################################################################
use warnings;
use strict;
use base qw(Net::Amazon::Request);

##################################################
sub new {
##################################################
    my($class, %options) = @_;

    $class->_assert_options_defined(\%options,
                                   'exchange');

    $options{IdType} = "Exchange";
    $class->_convert_option(\%options,
                            'exchange',
                            'Id');

   my $self = $class->SUPER::new(%options);

   bless $self, $class;   # reconsecrate
}

1;

__END__

=head1 NAME

Net::Amazon::Request::Exchange - Class for submitting Exchange requests

=head1 SYNOPSIS

  use Net::Amazon;
  use Net::Amazon::Request::Exchange;

  my $ua = Net::Amazon->new(
      token       => 'YOUR_AMZN_TOKEN'
  );

  my $req = Net::Amazon::Request::Exchange->new( 
      exchange  => 'Y04Y3424291Y2398445'
  );

    # Response is of type Net::Amazon::Response::Seller
  my $resp = $ua->request($req);

=head1 DESCRIPTION

C<Net::Amazon::Request::Exchange> is a class used to submit Exchange search
requests to the Amazon web service. Exchange requests send an item's 
exchange ID and retrieve a description of the item, offered by a third
party seller on Amazon.

Upon success, the responses' C<result()> method will return a single
C<Net::Amazon::Result::Seller::Listing> object.

Check L<Net::Amazon::Request> for common request parameters not listed here.

=head2 METHODS

=over 4

=item new( exchange => $exchange_id )

Constructs a new C<Net::Amazon::Request::Exchange> object, used to query
the Amazon web service with the given seller id.

=back

=head1 AUTHOR

Mike Schilli, E<lt>m@perlmeister.comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright 2005 by Mike Schilli E<lt>m@perlmeister.comE<gt>

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself. 

=cut
