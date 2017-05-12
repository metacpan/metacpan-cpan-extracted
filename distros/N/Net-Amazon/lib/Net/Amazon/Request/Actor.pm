######################################################################
package Net::Amazon::Request::Actor;
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
                                   'actor');

    $class->_convert_option(\%options,
                            'actor',
                            'Actor');

    my $self = $class->SUPER::new(%options);

    $self->_convert_itemsearch();

    bless $self, $class;   # reconsecrate
}

1;

__END__

=head1 NAME

Net::Amazon::Request::Actor - Class for submitting Actor requests

=head1 SYNOPSIS

  use Net::Amazon;
  use Net::Amazon::Request::Actor;

  my $ua = Net::Amazon->new(
      token       => 'YOUR_AMZN_TOKEN'
  );

  my $req = Net::Amazon::Request::Actor->new( 
      actor => 'Adam Sandler'
  );

    # Response is of type Net::Amazon::Response::Actor
  my $resp = $ua->request($req);

=head1 DESCRIPTION

C<Net::Amazon::Request::Actor> is a class used to submit Actor search
requests to the Amazon web service.

The actor to search for is specified in the C<actor> parameter.

Upon success, the responses' C<properties()> method will return a list of
C<Net::Amazon::Property::DVD> objects.

Check L<Net::Amazon::Request> for common request parameters not listed here.

=head2 METHODS

=over 4

=item new( actor => $actor )

Constructs a new C<Net::Amazon::Request::Actor> object, used to query
the Amazon web service for items of a given actor.

=back

=head1 AUTHORS

Christopher Boumenot, E<lt>boumenot@gmail.comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright 2006 by Christopher Boumenot, E<lt>boumenot@gmail.comE<gt>

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself. 

=cut
