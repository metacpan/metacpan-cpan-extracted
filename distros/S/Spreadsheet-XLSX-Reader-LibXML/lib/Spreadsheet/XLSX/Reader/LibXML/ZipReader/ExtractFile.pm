package Spreadsheet::XLSX::Reader::LibXML::ZipReader::ExtractFile;
our $AUTHORITY = 'cpan:JANDREW';
use version; our $VERSION = version->declare('v0.44.6');
###LogSD	warn "You uncovered internal logging statements for Spreadsheet::XLSX::Reader::LibXML::ZipReader::ExtractFile-$VERSION";

use	Moose::Role;
requires qw( _member_named );

#########1 Dispatch Tables    3#########4#########5#########6#########7#########8#########9



#########1 Public Attributes  3#########4#########5#########6#########7#########8#########9



#########1 Public Methods     3#########4#########5#########6#########7#########8#########9

sub extract_file{
    my ( $self, $file ) = ( @_ );
	###LogSD	my	$phone = Log::Shiras::Telephone->new( name_space =>
	###LogSD			$self->get_all_space . '::extract_file', );
	###LogSD		$phone->talk( level => 'trace', message =>[
	###LogSD			'Arrived at extract_file for the workbook general settings:', $file ] );
	my $zip_member = $self->_member_named( $file );
	###LogSD	$phone->talk( level => 'debug', message =>[ 'zip member:', $zip_member	] );
	if( $zip_member ){
		my $workbook_fh = IO::File->new_tmpfile;
		$workbook_fh->binmode();
		$zip_member->extractToFileHandle( $workbook_fh );
		$workbook_fh->seek( 0, 0 );
		###LogSD	$phone->talk( level => 'debug', message =>[
		###LogSD		'succesfully built the zip sub file:', $workbook_fh ] );
		return $workbook_fh;
	}else{
		###LogSD	$phone->talk( level => 'debug', message =>[ "no zip file for: $file"	] );
		return undef;
	}
}

#########1 Private Attributes 3#########4#########5#########6#########7#########8#########9



#########1 Private Methods    3#########4#########5#########6#########7#########8#########9



#########1 Phinish            3#########4#########5#########6#########7#########8#########9

no Moose::Role;
1;

#########1 Documentation      3#########4#########5#########6#########7#########8#########9
__END__

=head1 NAME

Spreadsheet::XLSX::Reader::LibXML::ZipReader::ExtractFile - ZipReader file extractor

=head1 DESCRIPTION

Not written yet!

=head1 SEE ALSO

=over

L<Spreadsheet::ParseExcel> - Excel 2003 and earlier

L<Spreadsheet::ParseXLSX> - 2007+

L<Spreadsheet::Read> - Generic

L<Spreadsheet::XLSX> - 2007+

L<Log::Shiras|https://github.com/jandrew/Log-Shiras>

=over

All lines in this package that use Log::Shiras are commented out

=back

=back

=cut

#########1#########2 main pod documentation end  5#########6#########7#########8#########9