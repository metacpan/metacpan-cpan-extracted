=head1 Download accelerator

Simple downloader capable to download a file using multiple connections.

=cut
#!/usr/bin/perl
#
use strict;
use warnings;
use Net::Curl::Simple::UserAgent;
use IO::Handle; # for STDOUT->flush

my $width = 80;
my $uri = shift @ARGV or die "Usage: $0 URI [num connections]\n";
my $threads = shift @ARGV || 0;
$threads = $threads >= 1 ? int $threads : 3;

# we'll disguise as chrome
my $chrome = Net::Curl::Simple::UserAgent->new(
	useragent => 'Mozilla/5.0 (Windows NT 5.1) AppleWebKit/534.24 (KHTML, like Gecko) Chrome/11.0.696.60 Safari/534.24',
	httpheader => [
		'Connection: keep-alive',
		'Cache-Control: max-age=0',
		'Accept: text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8',
		'Accept-Language: en-US,en;q=0.8',
		'Accept-Charset: ISO-8859-1,utf-8;q=0.7,*;q=0.3',
	],
	connecttimeout => 30,
);


# get some basic information about the download
my $size;
my $fulluri;
my $filename;
{
	# test this uri
	my $curl = $chrome->curl->head( $uri,
		# check whether server supports resume
		resume_from_large => 1,
		# no callback here so it will block
		undef );

	# make sure there were no errors
	die "HEAD failed: ${ \$curl->code }: ${ \$curl->error }\n"
		if $curl->code;

	( $size, $fulluri, my $code ) = $curl->getinfos(
		'content_length_download',
		'effective_url',
		'response_code',
	);

	# 206 -- partial content (http)
	# 350 -- Restarting at (ftp)
	die "Cannot download, code $code\n"
		unless $code == 206 or $code == 350;

	# we started at 1, so the reported size is wrong
	$size += 1;

	# extract output file name
	# decoding Content-Disposition to complicated to bother
	$fulluri =~ m#.*/(.*)#;
	$filename = $1;
}

# align sizes, optional
my $alignsize = 1024;
my $maxthreads = 1 + int ( $size / $alignsize / 4 );
$threads = $maxthreads if $threads > $maxthreads;
my $partsize = $alignsize * int ( $size / ( $alignsize * $threads ) );

# progress display information
my $partwidth = int ( $width / $threads );
my @display = ( 0 ) x $threads;
my $lastupdate = 0;


print "Downloading $filename ($size bytes, $threads connections):\n";
die "ERROR: File exists\n" if -f $filename;

foreach my $part ( 0 .. ( $threads - 1 ) ) {
	my $resume_from = $part * $partsize;

	open my $fout, '+>', $filename
		or die "Cannot save to $filename: $!\n";
	seek $fout, $resume_from, 0;

	my $easy = $chrome->curl;
	$easy->{file} = $fout;
	$easy->{part} = $part;
	# last part may be larger
	$easy->{partsize} = $part != $threads - 1 ?
		$partsize : $size - $resume_from;

	$easy->get( $uri,
		# where we want to resume
		resume_from_large => $resume_from,
		# header will tell us where we really have to resume
		headerfunction => \&cb_header,
		# write to file handle directly
		writedata => $fout,
		# enable progress callback
		noprogress => 0,
		progressfunction => \&cb_progress,
		sub { update_display( $_[0]->{part}, 1 ) }
	);
}

# start download and wait for all threads to finish
1 while Net::Curl::Simple->join;

# update display one last time
$lastupdate = 0;
update_display( 0, 1 );
print "\nFinished\n";

exit 0;

sub cb_header
{
	my ( $easy, $data, $uservar ) = @_;
	push @{ $easy->{headers} }, $data;
	if ( $data =~ /^Content-Range:\s*bytes\s+(\d+)/ ) { # HTTP
		seek $easy->{file}, $1, 0;
	} elsif ( $data =~ /^350 Restarting at (\d+)/ ) { # FTP
		seek $easy->{file}, $1, 0;
	}
	return length $data;
}

sub update_display
{
	$display[ $_[0] ] = $_[1];
	my $time = time;
	return if $time == $lastupdate;
	$lastupdate = $time;

	print join '', "\r", map { $_ >= $partwidth ? "*" x $partwidth
		: "#" x $_ . "_" x ($partwidth - $_) }
		map { int $_ * $partwidth } @display;
	STDOUT->flush;
}

sub cb_progress
{
	my $curl = $_[0];
	update_display( $curl->{part}, $_[2] / $curl->{partsize} );
	# abort if we've got what we wanted
	return 1 if $_[2] > $curl->{partsize};

	return 0;
}

# vim: ts=4:sw=4
