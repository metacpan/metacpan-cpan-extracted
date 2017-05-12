package Net::Async::HTTP::DAV::Response;
$Net::Async::HTTP::DAV::Response::VERSION = '0.001';
use strict;
use warnings;

use XML::SAX;
use XML::LibXML::SAX::ChunkParser;
use Net::Async::HTTP::DAV::XML;
use Scalar::Util qw(weaken);

sub new {
	my $class = shift;
	my %args = @_;
	my $self = bless { }, $class;
	my $ws = $self;
	weaken $ws;
	$self->{xml_handler} = Net::Async::HTTP::DAV::XML->new(
		dav	=> $ws,
		path	=> $args{path},
		map { $_ => $args{$_} } grep /^on_/, keys %args
	);
	{
		local $XML::SAX::ParserPackage = 'XML::LibXML::SAX::ChunkParser';
		$self->{sax} = XML::SAX::ParserFactory->parser(Handler => $self->{xml_handler}) or die "No SAX parser could be found";
	};

	return $self;
}

sub parse_chunk { shift->{sax}->parse_chunk(@_) }

1;

__END__

=head1 AUTHOR

Tom Molesworth <cpan@perlsite.co.uk>

=head1 LICENSE

Copyright Tom Molesworth 2011-2014. Licensed under the same terms as Perl itself.

