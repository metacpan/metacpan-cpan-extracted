package Symantec::PCAnywhere::Profile::CIF;

use strict;
use warnings;

=head1 NAME

Symantec::PCAnywhere::Profile::CIF - Encodes and decodes Symantec pcAnywhere connection
profiles

=head1 SYNOPSIS

	use Symantec::PCAnywhere::Profile::CIF;
	
	# Load CIF file from file
	my $cif = new Symantec::PCAnywhere::Profile::CIF(filename => $filename);
	
	# Load CIF data directly
	my $cif = new Symantec::PCAnywhere::Profile::CIF(data => $data);
	
	my %results = $cif->get_attrs(
		CallerName,
		CallerPassword,
		DisplayName
	);
	while (my ($attr, $value) = each (%results)) {
		print "$attr\t= $value\n";
	}
	
	# Create an empty CIF
	my $cif = new Symantec::PCAnywhere::Profile::CIF;
	$cif->set_attrs(
		CallerName	=> 'JohnDoe',
		CallerPassword	=> 'acw938nrh!'
	);
	
	# Print the binary CIF file
	print $cif->encode;


=head1 DESCRIPTION

This module is responsible for decoding of a pcAnywhere .CIF file that
describes a caller that can connect to a pcAnywhere Host. CIF files seem to
always be the same size (10504 bytes), which is helpful for decoding.

See this module's base class (L<Symantec::PCAnywhere::Profile>) for more
information on the decoding mechanism.

=head1 VERSION

Version 0.06

=cut

our $VERSION = '0.06';

use base qw(Symantec::PCAnywhere::Profile);
use Compress::Zlib;
use MIME::Base64;

# Compressed and encoded template CIF
my $cif_template = uncompress(decode_base64(<<'TEMPLATE'));
eJztzrENQGAAhNFDYxMxhig0CisodCprGZI/ZpCI5L1Lrv7OK2n7pCqbu2QZh4zrvm9H+IX6+SnN
xx3Ab1R18XUEAAAAAAAAAAC84wYJxwXN
TEMPLATE

my %FIELDS_CIF = (
	#                      off  len type
	#                     ----  --- ----
	DisplayName      => [   16, 186, 0 ],
	FilePassword     => [  280, 128, 0 ],
	CallerName       => [  460, 128, 0 ],
	CallerPassword   => [  589, 128, 0 ],
);

=head1 METHODS

Here is the public API; see this module's base class documentation for more
information on the inner workings of the encoding and decoding process, as well
as additional useful methods.

=over 4

=item new

	my $cif = new Symantec::PCAnywhere::Profile::CIF;
	my $cif = new Symantec::PCAnywhere::Profile::CIF(-filename => $filename);
	my $cif = new Symantec::PCAnywhere::Profile::CIF(filename => $filename);
	my $cif = new Symantec::PCAnywhere::Profile::CIF(-data => $cifdata);
	my $cif = new Symantec::PCAnywhere::Profile::CIF(data => $cifdata);

The "new" constructor takes any number of arguments and sets the appropriate
flags internally before returning a new object. The arguments are considered as
a list of key-value pairs which are inserted into the object data.

=cut

sub new {
	my $type = shift;
	my %defaults = (
		fields		=> \%FIELDS_CIF,
		template	=> $cif_template,
	);

	my $self = $type->SUPER::new(%defaults, @_);
	return $self;
}

=item _decode_pca_file

Provided with XOR-encoded CIF data, un-obscure the whole
thing into the "clear" format. The return value is the same
length as the input string, but after XOR decoding.

=cut

sub _decode_pca_file ($$) {
	my $self = shift;
	my $rawdata = $self->{data};

	my $part1 = substr($rawdata, 0, 444);
	my $part2 = substr($rawdata, 444);

	return $self->_rawdecode(255, 0,    $part1)
	     . $self->_rawdecode(255, 0x54, $part2);

}

=item _encode_pca_file

Provided with XOR-unencoded CIF data, obscure the whole
thing into the "encrypted" format. The return value is the
same length as the input string, but after XOR encoding.

=cut

sub _encode_pca_file ($$) {
	my $self = shift;
	my $rawdata = $self->{decoded};

	my $part1 = substr($rawdata, 0, 444);
	my $part2 = substr($rawdata, 444);

	return $self->_rawencode(255, 0,    $part1)
	     . $self->_rawencode(255, 0x54, $part2);
}

=back

=head1 SEE ALSO

This module is based very heavily on the work of Stephen Friedl at
http://www.unixwiz.net/tools/pcainfo.htmlZ<>.

=head1 TO DO

Based on http://www.cpan.org/modules/00modlist.long.html#ID2_GuidelinesfZ<>,
refactor code to pass references to lists instead of lists.

=head1 BUGS / CAVEATS

They're in there somewhere. Let me know what you find.

=head1 AUTHOR

Darren Kulp, E<lt>kulp@thekulp.comE<gt>, based on code from
Stephen J. Friedl, (http://unixwiz.net/)

=head1 COPYRIGHT AND LICENSE

This code is in the public domain. Contains code placed in the public domain
2002 by Stephen Friedl.

"Symantec" and "pcAnywhere" are trademarks of Symantec Corp.

=cut

1;
__END__

