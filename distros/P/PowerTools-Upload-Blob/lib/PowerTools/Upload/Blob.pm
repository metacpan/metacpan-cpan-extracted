package PowerTools::Upload::Blob;

use 5.000005;
use strict;
use warnings;
use DBI;
use File::Scan::ClamAV;

require Exporter;

our @ISA = qw(Exporter DBI);

# Items to export into callers namespace by default. Note: do not export
# names by default without a very good reason. Use EXPORT_OK instead.
# Do not simply export all your public functions/methods/constants.

# This allows declaration	use PowerTools::Upload::Blob ':all';
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

PowerTools::Upload::Blob - Additional Perl tool for Apache::ASP data uploading

=head1 SYNOPSIS

	default table

	CREATE TABLE  `files`.`file` (
	  `file_id` int(10) unsigned NOT NULL auto_increment,
	  `file_name` varchar(255) NOT NULL,
	  `file_type` varchar(255) NOT NULL,
	  `file_blob` longblob NOT NULL,
	  `file_size` int(10) unsigned NOT NULL,
	  PRIMARY KEY  (`file_id`)
	) ENGINE=InnoDB DEFAULT CHARSET=latin1;

	.asp file

	use PowerTools::Upload::Blob;

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
	my $limit = $self->{limit} || 100000000;
	my $r = $self->{request};

	my $db_user = $self->{db_user} || "root";
	my $db_pass = $self->{db_pass} || "";
	my $db_name = $self->{db_name} || "files";

	my $db_host = $self->{db_host} || "localhost";
	my $db_port = $self->{db_port} || 3306;
	my $db_type = $self->{db_type} || "mysql";

	my $dsn = "DBI:$db_type:database=$db_name;host=$db_host";

	my $dbh = DBI->connect($dsn, $db_user, $db_pass, { RaiseError => 1, AutoCommit => 1 }) || carp $DBI::errstr;

	my $tname = $self->{table_file} || 'files';

	my $fid = $self->{field_file_id} || 'file_id';

	my $fname = $self->{field_file_name} || 'file_name';
	my $ftype = $self->{field_file_type} || 'file_type';
	my $fblob = $self->{field_file_blob} || 'file_blob';
	my $fsize = $self->{field_file_size} || 'file_size';

	$self->{'filename'} = '';
	$self->{'filesize'} = '';
	$self->{'filescan'} = '';
	$self->{'filemime'} = '';
	$self->{'copytime'} = '';
	$self->{'insertid'} = '';
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

		$self->{'filename'} = $file;
		
		my $code = "OK";
		my ($virus,$var);
		binmode $fh;
		read($fh, $var, -s $fh);

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

			my $start_time = time();
			my $sql = "INSERT INTO $tname ($fname,$ftype,$fblob,$fsize) VALUES (?,?,?,?)";
			my $sth = $dbh->prepare($sql);
			$sth->execute($file,$ct,$var,$size);
			$sth->finish();
			$self->{'insertid'} = $dbh->{'mysql_insertid'};
			my $time_took = time() - $start_time;
			$self->{'copytime'} = $time_took;
			$self->{'status'} = 'OK';

		} else {
			$self->{'status'} = 'File containing virus or size overlimit';
			carp $self->{'status'};	
		}

		$dbh->disconnect;

	} else {
		$self->{'status'} = 'No request object found';
		carp $self->{'status'};
	}

	return $self;

}

1;
__END__

