######################################################################
package Net::Amazon::Request::Similar;
######################################################################
use warnings;
use strict;
use base qw(Net::Amazon::Request);

our $AMZN_XML_URL     = "http://xml.amazon.com/onca/xml3";

##################################################
sub amzn_xml_url {
##################################################
    return $AMZN_XML_URL;
}

##################################################
sub new {
##################################################
    my($class, %options) = @_;

    # For backwards compatibility
    $class->_convert_option(\%options, 'asin', 'similar');

    $class->_assert_options_defined(\%options, 'similar');

    $class->_convert_option(\%options,
                            'similar',
                            'ItemId');

    my $self = $class->SUPER::new(%options);

    bless $self, $class;   # reconsecrate
}

1;

__END__

=head1 NAME

Net::Amazon::Request::Similar - request class for 'Similarities Search'

=head1 SYNOPSIS

  use Net::Amazon;
  use Net::Amazon::Request::Similar;

  my $ua = Net::Amazon->new(
      token       => 'YOUR_AMZN_TOKEN'
  );

  my $req = Net::Amazon::Request::Similar->new( 
      similar => 'B00005B6TL',
  );

    # Response is of type Net::Amazon::Response::Similar
  my $resp = $ua->request($req);

=head1 DESCRIPTION

C<Net::Amazon::Request::Similar> is a class used to request
so-called I<Similarities Searches> from the Amazon web service.

The C<asin> parameter specifies the ASIN of the item which you want
to get similar items for.

Upon success, the response's C<properties()> method will return a list
of C<Net::Amazon::Property::*> objects.

=head2 METHODS

=over 4

=item new(similar => $asin)

Constructs a new C<Net::Amazon::Request::Similar> object.

=back

Check L<Net::Amazon::Request> for common request parameters not listed here.

=head1 AUTHOR

Mike Schilli, E<lt>m@perlmeister.comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright 2003 by Mike Schilli E<lt>m@perlmeister.comE<gt>

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself. 

=cut
