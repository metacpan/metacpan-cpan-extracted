######################################################################
package Net::Amazon::Request::TextStream;
######################################################################
use warnings;
use strict;
use base qw(Net::Amazon::Request);

##################################################
sub new {
##################################################
    my($class, %options) = @_;

    $class->_assert_options_defined(\%options,
                                    qw(textstream));

    $class->_convert_option(\%options,
                            'textstream',
                            'TextStream');

    my $self = $class->SUPER::new(%options);

    $self->_convert_itemsearch();

    bless $self, $class;   # reconsecrate
}

1;

__END__

=head1 NAME

Net::Amazon::Request::TextStream - request class for text stream search

=head1 SYNOPSIS

  use Net::Amazon;
  use Net::Amazon::Request::TextStream;

  my $ua = Net::Amazon->new(
      token       => 'YOUR_AMZN_TOKEN'
  );

  my $req = Net::Amazon::Request::TextStream->new( 
      textstream => 'Here is some text that mentions the Rolling Stones.',
  );

  # Response is of type Net::Amazon::Response::TextStream
  my $resp = $ua->request($req);

=head1 DESCRIPTION

C<Net::Amazon::Request::TextStream> is a class used to perform a search on
a block of text. Amazon extracts keywords from the given block of text,
but note that conjunctions and helper words, such as "and", "or", "the",
etc. are not excluded, so strip them out yourself if need be.

TextStream searching is only available for the US service.

Upon success, the response's C<properties()> method will return a list
of C<Net::Amazon::Property::*> objects.

=head2 METHODS

=over 4

=item new(textstream => $text)

Constructs a new C<Net::Amazon::Request::TextStream> object, used to query
the Amazon web service with a block of text.

=back

Check L<Net::Amazon::Request> for common request parameters not listed here.

=head1 SEE ALSO

=cut
