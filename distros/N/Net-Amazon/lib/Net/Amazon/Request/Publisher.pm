######################################################################
package Net::Amazon::Request::Publisher;
######################################################################
use warnings;
use strict;
use base qw(Net::Amazon::Request);

##################################################
sub new {
##################################################
    my($class, %options) = @_;

    $class->_assert_options_defined(\%options,
                                   'publisher');

    $class->_convert_option(\%options,
                            'publisher',
                            'Publisher');

    my $self = $class->SUPER::new(%options);

    $self->_convert_itemsearch();

    bless $self, $class;   # reconsecrate
}

1;

__END__

=head1 NAME

Net::Amazon::Request::Publisher - Class for submitting Publisher requests

=head1 SYNOPSIS

  use Net::Amazon;
  use Net::Amazon::Request::Publisher;

  my $ua = Net::Amazon->new(
      token       => 'YOUR_AMZN_TOKEN'
  );

  my $req = Net::Amazon::Request::Publisher->new( 
      publisher => 'Black Belt Communications'
  );

    # Response is of type Net::Amazon::Response::Publisher
  my $resp = $ua->request($req);

=head1 DESCRIPTION

C<Net::Amazon::Request::Publisher> is a class used to submit Publisher search
requests to the Amazon web service.

The publisher to search for is specified in the C<publisher> parameter.

Upon success, the responses' C<properties()> method will return a list of
C<Net::Amazon::Property::Book> objects.

Check L<Net::Amazon::Request> for common request parameters not listed here.

=head2 METHODS

=over 4

=item new( publisher => $publisher )

Constructs a new C<Net::Amazon::Request::Publisher> object, used to query
the Amazon web service for items of a given publisher.

=back

=head1 AUTHOR

Christopher Boumenot, E<lt>boumenot@gmail.comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright 2006 by Christopher Boumenot, E<lt>boumenot@gmail.comE<gt>

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself. 

=cut
