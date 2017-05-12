package PowerTools::Upload::File;

use 5.008008;
use strict;
use warnings;
use Carp;
use File::Scan::ClamAV;

require Exporter;

our @ISA = qw(Exporter);

# Items to export into callers namespace by default. Note: do not export
# names by default without a very good reason. Use EXPORT_OK instead.
# Do not simply export all your public functions/methods/constants.

# This allows declaration	use PowerTools::Upload::File ':all';
# If you do not need this, moving things directly into @EXPORT or @EXPORT_OK
# will save memory.
our %EXPORT_TAGS = ( 'all' => [ qw(upload
	
) ] );

our @EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );

our @EXPORT = qw(
	upload
);

our $VERSION = '0.03';


# Below is stub documentation for your module. You'd better edit it!

=head1 NAME

PowerTools::Upload::File - Additional Perl tool for Apache::ASP data uploading

=head1 SYNOPSIS

	use PowerTools::Upload::File;

	my $up = PowerTools::Upload::File->new(			# Create new object
		path => 'E:/instale/test', 			# Path to directory where files will be stored (default: '/tmp')
		field => 'plik',				# Form field name (<input type"file" name="plik">, default: 'file')
		limit => $Server->Config("FileUploadMax"),	# File size limit (default 100000000)
		request => $Request,				# Request object
		clamav => 1,					# Scan with ClamAV when uploading (0 -> no / 1 -> yes, default: 0)
		overwrite => 0					# Overwrite file (0 -> no / 1 -> yes, default: 1)
		);

	my $ret = $up->upload();				# Upload file
	print $ret->{'filename'}."<br>";			# Returns filename
	print $ret->{'filesize'}."<br>";			# Returns filesize
	print $ret->{'filepath'}."<br>";			# Returns filepath
	print $ret->{'filescan'}."<br>";			# Returns filescan
	print $ret->{'filemime'}."<br>";			# Returns filemime
	print $ret->{'copytime'}."<br>";			# Returns copytime
	print $ret->{'status'};					# Returns upload status


=head1 AUTHOR

Piotr Ginalski, E<lt>office@gbshouse.comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2007 by Piotr Ginalski

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.8 or,
at your option, any later version of Perl 5 you may have available.


=cut

sub new {
	my $class = shift;
	my (%options) = @_;
	return bless \%options, $class;
}

sub upload {
	my $self = shift;

	my $field = $self->{field} || "file";
	my $path = $self->{path} || "/tmp";
	my $limit = $self->{limit} || 100000000;
	my $r = $self->{request};
	my $owerwrite = $self->{overwrite} || 1;

	$self->{'filename'} = '';
	$self->{'filesize'} = '';
	$self->{'filepath'} = '';
	$self->{'filescan'} = '';
	$self->{'filemime'} = '';
	$self->{'copytime'} = '';

	$self->{'status'} = '';

	if($r) {

		my $ct = $r->FileUpload( $field, 'ContentType');
		my $bf = $r->FileUpload( $field, 'BrowserFile');
		my $fh = $r->FileUpload( $field, 'FileHandle');
		my $mh = $r->FileUpload( $field, 'Mime-Header');
		my $tf = $r->FileUpload( $field, 'TempFile');

		$self->{'filemime'} = $ct;

		my $file = $bf;
		$file =~ s/.*[\/\\](.*)/$1/;
		my $filepath = $path."\\".$file;

		$self->{'filename'} = $file;
		$self->{'filepath'} = $filepath;
		
		my $code = "OK";
		my ($var, $virus);

		my $size = -s $fh;
		$self->{'filesize'} = $size;

		if($self->{clamav} == 1) {
			my $av = new File::Scan::ClamAV(port => 3310);
			if($av->ping){
				my ($code,$virus) = $av->streamscan($var);
				$self->{'filescan'} = $code;
			}
		}

		if( ($code eq 'OK') && ($size <= $limit) ) {

			if( ($owerwrite == 0) && (-e $filepath) ) {
				return $self;
			} else {
				my $start_time = time();
				open(TMP,">$filepath") or carp "Can't open filepath $filepath";
				my ($bytes,$buffer,$tempsize);
				while($bytes = read($fh,$buffer,1024) ) {
					$tempsize += $bytes;
					binmode TMP;
					print TMP $buffer;			
				}
				close(TMP);
				my $time_took = time() - $start_time;
				$self->{'copytime'} = $time_took;

				if(-e $filepath) {
					$self->{'status'} = 'OK';
				} else {
					$self->{'status'} = 'Error writing file';
					carp $self->{'status'};
				}
			}

		} else {
			$self->{'status'} = 'File containing virus or size overlimit';
			carp $self->{'status'};	
		}
	} else {
		$self->{'status'} = 'No request object found';
		carp $self->{'status'};
	}

	return $self;

}

1;
__END__

