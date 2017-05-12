######################################################################
package Net::Amazon::Request::MusicLabel;
######################################################################
use warnings;
use strict;
use base qw(Net::Amazon::Request);

##################################################
sub new {
##################################################
    my($class, %options) = @_;

    $class->_assert_options_defined(\%options,
                                   'musiclabel');

    $class->_convert_option(\%options,
                            'musiclabel',
                            'MusicLabel');

    my $self = $class->SUPER::new(%options);

    $self->_convert_itemsearch();

    bless $self, $class;   # reconsecrate
}

1;

__END__

=head1 NAME

Net::Amazon::Request::MusicLabel - Class for submitting MusicLabel requests

=head1 SYNOPSIS

  use Net::Amazon;
  use Net::Amazon::Request::MusicLabel;

  my $ua = Net::Amazon->new(
      token       => 'YOUR_AMZN_TOKEN'
  );

  my $req = Net::Amazon::Request::MusicLabel->new( 
      MusicLabel => 'James Patterson'
  );

    # Response is of type Net::Amazon::Response::MusicLabel
  my $resp = $ua->request($req);

=head1 DESCRIPTION

C<Net::Amazon::Request::MusicLabel> is a class used to submit MusicLabel search
requests to the Amazon web service.

The MusicLabel to search for is specified in the C<MusicLabel> parameter.

Upon success, the responses' C<properties()> method will return a list of
C<Net::Amazon::Property::Music> objects.

Check L<Net::Amazon::Request> for common request parameters not listed here.

=head2 METHODS

=over 4

=item new( MusicLabel => $MusicLabel )

Constructs a new C<Net::Amazon::Request::MusicLabel> object, used to query
the Amazon web service for items of a given MusicLabel.

=back

=head1 AUTHORS

Christopher Boumenot, E<lt>boumenot@gmail.comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright 2006 by Christopher Boumenot, E<lt>boumenot@gmail.comE<gt>

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself. 

=cut
