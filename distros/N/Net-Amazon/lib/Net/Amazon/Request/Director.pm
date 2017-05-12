######################################################################
package Net::Amazon::Request::Director;
######################################################################
use warnings;
use strict;
use base qw(Net::Amazon::Request);

use Net::Amazon::Validate::ItemSearch;

##################################################
sub new {
##################################################
    my($class, %options) = @_;
    
    $class->_assert_options_defined(\%options,
                                   'director');

    $class->_convert_option(\%options,
                            'director',
                            'Director');

    my $self = $class->SUPER::new(%options);

    $self->_convert_itemsearch();

    bless $self, $class;   # reconsecrate
}

1;

__END__

=head1 NAME

Net::Amazon::Request::Director - Class for submitting Director requests

=head1 SYNOPSIS

  use Net::Amazon;
  use Net::Amazon::Request::Director;

  my $ua = Net::Amazon->new(
      token       => 'YOUR_AMZN_TOKEN'
  );

  my $req = Net::Amazon::Request::Director->new( 
      director => 'Adam Sandler'
  );

    # Response is of type Net::Amazon::Response::Director
  my $resp = $ua->request($req);

=head1 DESCRIPTION

C<Net::Amazon::Request::Director> is a class used to submit Director search
requests to the Amazon web service.

The director to search for is specified in the C<director> parameter.

Upon success, the responses' C<properties()> method will return a list of
C<Net::Amazon::Property::DVD> objects.

Check L<Net::Amazon::Request> for common request parameters not listed here.

=head2 METHODS

=over 4

=item new( director => $director )

Constructs a new C<Net::Amazon::Request::Director> object, used to query
the Amazon web service for items of a given director.

=back

=head1 AUTHORS

Carl Franks, E<lt>fireartist@gmail.comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright 2007 by Carl Franks, E<lt>fireartist@gmail.comE<gt>

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself. 

=cut
