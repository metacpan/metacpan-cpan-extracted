######################################################################
package Net::Amazon::Request::Author;
######################################################################
use warnings;
use strict;
use base qw(Net::Amazon::Request);

##################################################
sub new {
##################################################
    my($class, %options) = @_;

    $class->_assert_options_defined(\%options,
                                   'author');

    $class->_convert_option(\%options,
                            'author',
                            'Author');
    
    my $self = $class->SUPER::new(%options);

    $self->_convert_itemsearch();

    bless $self, $class;   # reconsecrate
}

1;

__END__

=head1 NAME

Net::Amazon::Request::Author - Class for submitting Author requests

=head1 SYNOPSIS

  use Net::Amazon;
  use Net::Amazon::Request::Author;

  my $ua = Net::Amazon->new(
      token       => 'YOUR_AMZN_TOKEN'
  );

  my $req = Net::Amazon::Request::Author->new( 
      author => 'James Patterson'
  );

  # Response is of type Net::Amazon::Response::Author
  my $resp = $ua->request($req);

=head1 DESCRIPTION

C<Net::Amazon::Request::Author> is a class used to submit Author search
requests to the Amazon web service.

The author to search for is specified in the C<author> parameter.

Upon success, the responses' C<properties()> method will return a list of
C<Net::Amazon::Property::Book> objects.

Check L<Net::Amazon::Request> for common request parameters not listed here.

=head2 METHODS

=over 4

=item new( author => $author )

Constructs a new C<Net::Amazon::Request::Author> object, used to query
the Amazon web service for items of a given author.

=back

=head1 AUTHORS

Christopher Boumenot, E<lt>boumenot@gmail.comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright 2006 by Christopher Boumenot, E<lt>boumenot@gmail.comE<gt>

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself. 

=cut
