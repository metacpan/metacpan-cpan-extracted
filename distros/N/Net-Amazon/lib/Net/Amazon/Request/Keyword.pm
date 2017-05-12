######################################################################
package Net::Amazon::Request::Keyword;
######################################################################
use warnings;
use strict;
use base qw(Net::Amazon::Request);

##################################################
sub new {
##################################################
    my($class, %options) = @_;

    $class->_assert_options_defined(\%options, 
                                    qw(keyword));

    $class->_convert_option(\%options,
                            'keyword',
                            'Keywords');

    my $self = $class->SUPER::new(%options);

    $self->_convert_itemsearch();

    bless $self, $class;   # reconsecrate
}

1;

__END__

=head1 NAME

Net::Amazon::Request::Keyword - request class for keyword search

=head1 SYNOPSIS

  use Net::Amazon;
  use Net::Amazon::Request::Keyword;

  my $ua = Net::Amazon->new(
      token       => 'YOUR_AMZN_TOKEN'
  );

  my $req = Net::Amazon::Request::Keyword->new( 
      keyword  => 'Zwan',
      mode     => 'books'
  );

    # Response is of type Net::Amazon::Response::Keyword
  my $resp = $ua->request($req);

=head1 DESCRIPTION

C<Net::Amazon::Request::Keyword> is a class used to submit keyword search
requests to the Amazon web service.

The keyword to search for is specified in the C<keyword> parameter.

The catalog to search in is specified in the C<mode> parameter,
typical values are C<books>, C<music>, C<classical> or C<electronics>.

Upon success, the responses' C<properties()> method will return a list of
C<Net::Amazon::Property::*> objects.

=head2 METHODS

=over 4

=item new( keyword => $keyword, mode => $mode )

Constructs a new C<Net::Amazon::Request::Keyword> object, used to query
the Amazon web service for items matching a given keyword in the 
mode (catalog) specified.

=back

Check L<Net::Amazon::Request> for common request parameters not listed here.

=head1 AUTHOR

Mike Schilli, E<lt>m@perlmeister.comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright 2003 by Mike Schilli E<lt>m@perlmeister.comE<gt>

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself. 

=cut
