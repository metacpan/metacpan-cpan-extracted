######################################################################
package Net::Amazon::Request::MP3Downloads;
######################################################################
use warnings;
use strict;
use base qw(Net::Amazon::Request);

##################################################
sub new {
##################################################
    my($class, %options) = @_;
    
    $options{'SearchIndex'} = 'MP3Downloads';

    my $self = $class->SUPER::new(%options);

    bless $self, $class;   # reconsecrate
}

1;

__END__

=head1 NAME

Net::Amazon::Request::MP3Downloads - Class for submitting MP3 downloads search requests

=head1 SYNOPSIS

  use Net::Amazon;
  use Net::Amazon::Request::MP3Downloads;

  my $ua = Net::Amazon->new(
      token       => 'YOUR_AMZN_TOKEN'
  );

  my $req = Net::Amazon::Request::MP3Downloads->new( 
      tile => 'hand in my pocket'
  );

  # Response is of type Net::Amazon::Response::MP3Downloads
  my $resp = $ua->request($req);

=head1 DESCRIPTION

C<Net::Amazon::Request::MP3Downloads> is a class used to submit MP3 download search
requests to the Amazon web service.

The title to search for is specified by the C<title> parameter.

Upon success, the responses' C<properties()> method will return a list of
C<Net::Amazon::Property::MP3> objects.

Check L<Net::Amazon::Request> for common request parameters not listed here.

=head2 METHODS

=over 4

=item new( title => $title )

Constructs a new C<Net::Amazon::Request::MP3Downloads> object, used to query
the Amazon web service for items of a given MP3 download.

=back

=head1 AUTHORS

Christopher Boumenot, E<lt>boumenot+na@gmail.comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright 2009 by Christopher Boumenot, E<lt>boumenot+na@gmail.comE<gt>

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself. 

=cut
