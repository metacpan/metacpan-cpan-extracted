######################################################################
package Net::Amazon::Request::ISBN;
######################################################################
use warnings;
use strict;
use base qw(Net::Amazon::Request);

##################################################
sub new {
##################################################
    my($class, %options) = @_;

    $class->_assert_options_defined(\%options, qw(isbn));

    $class->_convert_option(\%options, 
                            'isbn', 
                            'ItemId');

	$options{'IdType'} = 'ISBN';
	$options{'SearchIndex'} = 'Books';

    my $self = $class->SUPER::new(%options);

    bless $self, $class;   # reconsecrate
}

1;

__END__

=head1 NAME

Net::Amazon::Request::ISBN- request class for ISBN search

=head1 SYNOPSIS

  use Net::Amazon;
  use Net::Amazon::Request::ISBN;

  my $ua = Net::Amazon->new(
      token       => 'YOUR_AMZN_TOKEN'
  );

  my $req = Net::Amazon::Request::ISBN->new( 
      isbn => '9783570009222',
  );

    # Response is of type Net::Amazon::Response::ISBN
  my $resp = $ua->request($req);

=head1 DESCRIPTION

C<Net::Amazon::Request::ISBN> is a class used to submit ISBN (International
Standard Book Number) search requests to the Amazon web service.

The ISBN number to search for is specified in the C<ISBN> parameter.

Upon success, the response's C<properties()> method will return a single
C<Net::Amazon::Property::Book> object.

=head2 METHODS

=over 4

=item new(isbn => $isbn)

Constructs a new C<Net::Amazon::Request::ISBN> object, used to query the Amazon
web service for an item with the given ISBN number.  As of 2007-01-17 Amazon
supports 13-digit ISBNs.  To construct a 13-digit ISBN from a 10-digit ISBN
simply prepended 978 to the ISBN.  The ISBN must not contain hyphens.

It appears that not all 10-digit ISBNs can be turned into 13-digit ISBNs by
prepending 978.  Amazon lists the 13-digit ISBN alongside 10-digit ISBN.

=back

=head1 AUTHOR

Christopher Boumenot, E<lt>boumenot@gmail.comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright 2007 by Christopher Boumenot E<lt>boumenot@gmail.comE<gt>

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself. 

=cut
