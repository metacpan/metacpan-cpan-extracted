######################################################################
package Net::Amazon::Request::Artist;
######################################################################
use warnings;
use strict;
use base qw(Net::Amazon::Request);

##################################################
sub new {
##################################################
    my($class, %options) = @_;

    $class->_assert_options_defined(\%options, 
                                    qw(artist));

    $class->_convert_option(\%options,
                            'artist',
                            'Artist');

    my $self = $class->SUPER::new(%options);

    $self->_convert_itemsearch();

    bless $self, $class;   # reconsecrate
}

1;

__END__

=head1 NAME

Net::Amazon::Request::Artist - Class for submitting Artist requests

=head1 SYNOPSIS

  use Net::Amazon;
  use Net::Amazon::Request::Artist;

  my $ua = Net::Amazon->new(
      token       => 'YOUR_AMZN_TOKEN'
  );

  my $req = Net::Amazon::Request::Artist->new( 
      artist  => 'Zwan'
  );

    # Response is of type Net::Amazon::Response::Artist
  my $resp = $ua->request($req);

=head1 DESCRIPTION

C<Net::Amazon::Request::Artist> is a class used to submit Artist search
requests to the Amazon web service.

The artist to search for is specified in the C<artist> parameter.

Upon success, the responses' C<properties()> method will return a list of
C<Net::Amazon::Property::Music> objects.

Check L<Net::Amazon::Request> for common request parameters not listed here.

=head2 METHODS

=over 4

=item new( artist => $artist )

Constructs a new C<Net::Amazon::Request::Artist> object, used to query
the Amazon web service for items of a given artist.

=back

=head1 AUTHOR

Mike Schilli, E<lt>m@perlmeister.comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright 2003 by Mike Schilli E<lt>m@perlmeister.comE<gt>

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself. 

=cut
