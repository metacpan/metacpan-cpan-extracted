######################################################################
package Net::Amazon::Request::All;
######################################################################
use warnings;
use strict;
use base qw(Net::Amazon::Request);

##################################################
sub new {
##################################################
    my($class, %options) = @_;

    $class->_assert_options_defined(\%options, 'all');

    $options{'SearchIndex'} = 'All';
    $class->_convert_option(\%options,
                            'all',
                            'Keywords');

    my $self = $class->SUPER::new(%options);

    bless $self, $class;   # reconsecrate
}

1;

__END__

=head1 NAME

Net::Amazon::Request::All - request class for 'All Search'

=head1 SYNOPSIS

  use Net::Amazon;
  use Net::Amazon::Request::All;

  my $ua = Net::Amazon->new(
      token       => 'YOUR_AMZN_TOKEN'
  );

  my $req = Net::Amazon::Request::All->new( 
      all => 'perl'
  );

  # Response is of type Net::Amazon::Response::All
  my $resp = $ua->request($req);

=head1 DESCRIPTION

C<Net::Amazon::Request::All> is a class used to request
I<All Searches> from the Amazon web service.

The C<blended> parameter specifies the keyword search string
for the blended query. C<mode> is not applicable to blended
searches which returns books, music, etc all at once.

Upon success, the response's C<properties()> method will return a list
of C<Net::Amazon::Property::*> objects.

=head2 METHODS

=over 4

=item new(keyword => $search_string)

Constructs a new C<Net::Amazon::Request::All> object.

See the "Amazon Web Services 2.1 API and Integration Guide" for details.

=back

Check L<Net::Amazon::Request> for common request parameters not listed here.

=head1 AUTHORS

Robert Graff, E<lt>rgraff@workingdemo.comE<gt>
Yuichi Tateno, E<lt>hotchpotch@gmail.comE<gt>

=cut
