package NET::IPFilter;

use Carp;
use strict;
# use 5.008008;
use HTTP::Request;
use LWP::UserAgent;
use Compress::Zlib;
use Fcntl ':flock';
# use Math::BigInt;
# use warnings;
# use Data::Dumper;

require Exporter;

our @ISA = qw(Exporter);

# Items to export into callers namespace by default. Note: do not export
# names by default without a very good reason. Use EXPORT_OK instead.
# Do not simply export all your public functions/methods/constants.

# This allows declaration	use NET::IPFilter ':all';
# If you do not need this, moving things directly into @EXPORT or @EXPORT_OK
# will save memory.
our %EXPORT_TAGS = ( 'all' => [ qw(
	beautifyRawIPfromIPFilter
	readIPFilterFile
	httpGetStore
	_ip2long
	_long2ip
	isValid
	gunzip
	_init
) ] );

our @EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );

our @EXPORT = qw(
	beautifyRawIPfromIPFilter
	readIPFilterFile
	httpGetStore
	_ip2long
	_long2ip
	isValid
	gunzip
	_init
);

our $VERSION = '1.2';


######
my $MaxFileSizeOfWebDocument	= (50 * 1024 * 1024);	# 5mb
my $MaxRedirectRequests		= 15;
my $AuthorEmail			= 'yourname@cpan.org';
my $Timeout			= 25;
my $CrawlDelay			= int(rand(3));
my $Referer			= "http://www.google.com/";
my $DEBUG			= 1;
# IPFilter.dat: http://www.bluetack.co.uk/forums/index.php
######


sub new(){

	my $class   	= shift;
	my %args 	= ref($_[0])?%{$_[0]}:@_;
	my $self 	= \%args;
	bless $self, $class;
	$self->_init();
	return $self;
		
}; # sub new(){


sub isValid(){

	my $self 		= shift;
	my $IPtoCheck		= $self->_ip2long(shift); 
	my $RangesArrayRef	= $self->{'_IPRANGES_ARRAY_REF'};
	my $howmany		= scalar( @{$RangesArrayRef} );
	
	# $IPtoCheck 		= Math::BigInt->new($IPtoCheck);

	for ( my $count=0; $count<=$howmany; $count++) {
		
		my ($RangFrom, $RangTo) = split("-", $RangesArrayRef->[$count]);
	
		if ( $IPtoCheck >= $RangFrom && $IPtoCheck <= $RangTo ) {
			return 0;
		};

	}; # for ( my $count=0; $count<=$howmany; $count++) {

	return 1;	# if ip not found in ipfilter.dat its valid

}; # sub isValid(){




sub readIPFilterFile(){

	my $self		= shift;
	my $IPFilterDatFile	= shift;

	my @IP_Ranges		= ();

	open(RH,"<$IPFilterDatFile") or croak("$self -> _readIPFilterFile( $IPFilterDatFile ) Reading Failed");
	while (defined( my $entry = <RH>)) {
		chomp($entry);
		
		next if ( $entry =~ /^#/g || $entry =~ /#/g );
		my ($IPRange, undef, $DESC) 	= split(",", $entry);
		next if ( $DESC =~ /\[BG\]FreeSP/ig );	# ignore not used ips
		my ($IP_Start,$IP_End) 		= split("-", $IPRange );
		
		$IP_Start =~ s/^\s+//;
		$IP_Start =~ s/\s+$//;	
		$IP_End =~ s/^\s+//;
		$IP_End =~ s/\s+$//;				
		
		# beautifyRawIPfromIPFilter is not needed
	#	my $IPStart 		= $self->beautifyRawIPfromIPFilter( $IP_Start );
	#	my $IPEnd		= $self->beautifyRawIPfromIPFilter( $IP_End );
		
		my $IPStart 		= $self->_ip2long( $IP_Start );
		my $IPEnd		= $self->_ip2long( $IP_End );

	#	$IPStart		= Math::BigInt->new($IPStart);
	#	$IPEnd			= Math::BigInt->new($IPEnd);

		# print "$IP_Start und $IP_End\n";
		push(@IP_Ranges, "$IPStart-$IPEnd");


	}; # while (defined( my $entry = <RH>)) {
	close RH;

	$self->{'_IPRANGES_ARRAY_REF'} = \@IP_Ranges;

	return $self;

}; # sub _readIPFilterFile(){


sub beautifyRawIPfromIPFilter(){

	my $self		= shift;
	my $RawIP		= shift;
	my ($a,$b,$c,$d) 	= split(/\./, $RawIP );
	my @tmp			= ($a, $b, $c, $d); 
	my %IP			= ();
	my $tmp;
	
	for (my $i=0; $i<=$#tmp; $i++ ){
		
		my ($one, $two, $thr) = split("", $tmp[$i]);
		
		if ( $one == 0 && $two == 0 && $thr == 0 ){
			# 000->0
			$IP{$i} = 0;	
		} elsif ( $one == 0 && $two == 0 && $thr != 0 ){
			# 001->1
			$IP{$i} = $thr;	
		} elsif ( $one == 0 && $two != 0 && $thr != 0){
			# 0XY->XY
			$IP{$i} = $two.$thr;	
		} elsif ( $one != 0 && $two != 0 && $thr != 0 ){
			# XYZ->XYZ
			$IP{$i} = $tmp[$i]; 
		} else {
			# rest
			$IP{$i} = $tmp[$i]; 
		}; # if ( $one == 0 && $two == 0 && $thr == 0 ){

	}; # for (my $i=1; $i<=$#tmp; $i++ ){

	return $IP{0} . "." . $IP{1} . "." . $IP{2} . "." . $IP{3};

}; # sub _BeautifyRawIPfromIPFilter(){


sub _ip2long(){

	my $self 	= shift;
	my $ip		= shift;
	my @numbers	= split(/\./,$ip);
	return ($numbers[0] * 16777216) + ($numbers[1] * 65536) + ($numbers[2] * 256) + ($numbers[3]);

}; # sub  ip2long() {


sub _long2ip(){

	use Socket qw ( inet_ntoa );

	my $self = shift;
	my $long = shift;
	return inet_ntoa(pack("N*", $long));

}; # sub long2ip(){


sub httpGetStore(){
	
	my $self	= shift;
	my $url		= shift;
	my $storePath	= shift;

	my $UA		= LWP::UserAgent->new( keep_alive => 1 );
	
		$UA->agent("Mozilla/4.0 (compatible; MSIE 7.0; Windows NT 5.1; YPC 3.0.1; .NET CLR 1.1.4322; .NET CLR 2.0.50727)");
	#	$UA->agent("wget");
		$UA->timeout( $Timeout );
		$UA->max_size( $MaxFileSizeOfWebDocument );
		$UA->from( $AuthorEmail );
		$UA->max_redirect( $MaxRedirectRequests );
		$UA->parse_head( 1 );
		$UA->protocols_allowed( [ 'http', 'https', 'ftp', 'ed2k'] );
		$UA->protocols_forbidden( [ 'file', 'mailto'] );
		$UA->requests_redirectable( [ 'HEAD', 'GET', 'POST'] );

		#	$ua->credentials( $netloc, $realm, $uname, $pass )
		#	$ua->proxy(['http', 'ftp'], 'http://proxy.sn.no:8001/');	# f�r protokollschema http und ftp benutze proxy ...
		# $ua->env_proxy ->  wais_proxy=http://proxy.my.place/ -> export gopher_proxy wais_proxy no_proxy
  
	sleep $CrawlDelay;

	my $req = HTTP::Request->new( GET => $url );
	$req->referer($Referer);

	my $res = $UA->request($req);

	if ( $res->is_success ) {

	#	open(WH,">$storePath") or die "$self -> _httpGetStore() - I/O Error!\n";
	#	flock(WH,LOCK_EX);
	#		print WH $res->content;
	#	flock(WH,LOCK_UN);	
	#	close WH;
		
		$self->saveFile( $storePath, $res->content , ">");	# '>' - perl file handle openening type
	
  	} else {

		croak("$self -> _httpGetStore() -http-Get Request Failed: $res->status_line\n");

	}; # if ($res->is_success) {

	return 1;

}; # sub _httpGetStore(){


sub gunzip(){

	my $self		= shift;
	my $ZippedFile		= shift;
	my $UnzippedFile	= shift;
	
	no strict 'subs';

	my $gzerrno;
	my $buffer;
	my $gz 			= undef;
	my $success 		= 1;

	if (! open FH, ">$UnzippedFile") {
		$success = 0;
	#	print "Unable to write to '$outfile'\n";
	} else {
		
		binmode FH;
		flock(FH,LOCK_EX);

		if ($gz = gzopen($ZippedFile, "rb")) {

			while ($gz->gzread($buffer) > 0) {
				print FH $buffer;
			}; # while ($gz->gzread($buffer) > 0) {

			if ($gzerrno != Z_STREAM_END) {
				$success = 0;
			#	print "ZLib Error: reading $outfile - $gzerrno: $!\n";
			} else {
				$success = 1;
			}; # if ($gzerrno != Z_STREAM_END) {

			$gz->gzclose;

		} else {

			$success = 0;
		#	print "ZLib Error: opening $infile - $gzerrno: $!\n";

		}; # if ($gz = gzopen($infile, "rb")) {

		close FH;
		flock(FH,LOCK_UN);
	
	}; # if (! open FH, ">$UnzippedFile") {

	if ( $success == 0 ) {
		
		system("/bin/mv $ZippedFile $UnzippedFile");
		system("/bin/gunzip $UnzippedFile") && system("/usr/bin/gunzip $UnzippedFile");

	}; # if ( $success == 0 ) {

	use strict;
	return 1;

}; # sub _gunzip(){


sub saveFile(){

	my $self	= shift;
	my $File	= shift;
	my $refContent	= shift;
	my $oberator	= shift || ">";

	open(FILE, $oberator . $File) or croak "$self->_saveFile(): Open Error: $!\n";
		binmode(FILE);
		flock(FILE,LOCK_EX);
			
		if ( ref($refContent) eq 'ARRAY' ) {

			for ( my $i=0; $i<=$#{$refContent}; $i++ ) {
				print FILE $refContent->[$i];
			}; # for ( my $i=0; ... 

		} elsif ( ref($refContent) eq 'HASH' ) {

			my $keys = keys( %{$refContent} );
			for ( my $i=0; $i<=$keys; $i++ ) {
				print FILE $refContent->{$i};
			}; # for ( my $i=0; ...	

		} elsif ( ref($refContent) eq 'SCALAR' ) {
			print FILE ${$refContent};

		} elsif ( ref($refContent) eq '' ) {	# normaler scalar senden
			print FILE $refContent;

		} else {

			# code oder glob ref
			croak "CODE or GLOB Ref - not supported\n";
			flock(FILE,LOCK_UN);	
			close FILE;
			return -1;

		}; # if ( ref($refContent) eq 'ARRAY' ) {
	
	flock(FILE,LOCK_UN);	
	close FILE;

	return $File;

}; # sub _saveFile(){


sub _init(){

	my $self 		= shift;
	
	my $ipfilter_file 	= $self->{'ipfilter'};
	my $tmp_dir		= $self->{'tmpdir'};
	my $force_init		= $self->{'force_init'};
	mkdir $tmp_dir || system("/bin/mkdir $tmp_dir");
	
	my $IPFilerFile		= "$tmp_dir/ipfilter.dat";
	my $IPFilerFileGZ	= "$tmp_dir/ipfilter.dat.gz";	

	# Delete Files if force init == 1 resulting in recreation of ipfilter files
	if ( $force_init == 1 ) {

		unlink $IPFilerFile || system("/bin/rm -f $IPFilerFile");
		unlink $IPFilerFileGZ || system("/bin/rm -f $IPFilerFileGZ");
		
	}; # if ( $force_init == 1 ) {

	# File doesnt exsits so we need to download it
	if ( ( !-e $ipfilter_file && !-f $ipfilter_file ) || ( !-e $IPFilerFile && !-f $IPFilerFile ) ){

		if ( $ipfilter_file =~ /^http:\/\//i  ) {
			
			my @tmp		= split('/', $ipfilter_file);
			my $FileName	= $tmp[$#tmp];
			my ( $OnlyFileName , $OnlyFileTyp ) = split(/(\.([^.]+?)$)/i, $FileName );	# working correctly for "TEST.JPEG.bmp
			
			# todo: later bzip2|rar support
			if ( $OnlyFileTyp eq 'gz' || $OnlyFileTyp =~ /gz/i ) {
				
				print "Downloading gzip file $ipfilter_file \n " if $DEBUG == 1;

				# Download and Save file
				$self->httpGetStore($ipfilter_file, $IPFilerFileGZ);		
	
				print "Unzipping gzip file $ipfilter_file \n " if $DEBUG == 1;

				# gunzip file
				$self->gunzip($IPFilerFileGZ, $IPFilerFile);

				# read file	
				$self->readIPFilterFile( $IPFilerFile );
				return $self;

			} else { # asume txt file
	
				print "Downloading txt file $ipfilter_file \n " if $DEBUG == 1;
				# Download and Save file
				$self->httpGetStore($ipfilter_file, $IPFilerFile);	

				$self->readIPFilterFile( $IPFilerFile );	
				return $self;

			}; # if ( $OnlyFileTyp eq 'gz' || $OnlyFileTyp =~ /gz/i ) {
			
		}; # if ( $ipfilter_file =~ /^http:\/\//i ) {

	}; # if ( ! -e $IPFilerFile && ! -f $IPFilerFile ){

	$self->readIPFilterFile( $ipfilter_file );
	return $self;

}; # sub _init(){



# Preloaded methods go here.

return 1;
__END__
# Below is stub documentation for your module. You'd better edit it!

=head1 NAME

NET::IPFilter - Perl extension for Accessing eMule / Bittorrent IPFilter.dat Files and checking a given IP against this ipfilter.dat IP Range. IT uses conversion from IP to long integers in Perl and afterwards compairing these long integer
ranges against the calculated number of the given IP

Warning: Please Update your Sources. Current Version fixed a very critical bug that prevents Program from working correctly.

=head1 SYNOPSIS

  use NET::IPFilter;

 my $ipfilter = '/home/user/files/ipfilter.dat';
 my $IP = "3.3.19.81"; # :)

 my $obj = NET::IPFilter->new(	ipfilter	=> $ipfilter,
				tmpdir		=> '/var/tmp',
				force_init	=> '0'
);

 my $isValid 	= $obj->isValid($IP);	#  1 not to be blocked | 0 to be blocked
print $isValid;

=head1 DESCRIPTION

my $obj = NET::IPFilter->new(	ipfilter	=> $ipfilter,
				tmpdir		=> '/var/tmp',
				force_init	=> '0'
);

ipfilter can be an absolute file in the filesystem or an uri. the uri filename can be a normal textfile
or a gzip compressed file 

tmpdir classifies a folder where to store some temporary files

force_init can be 0 or 1 where 1 means that all files are downloaded again ( if uri is an http-link )

This current version is intended to be used on Linux/Unix OS System. My new Version NET::IPFilterSimple will be
usable for both Linux/Unix and Windows. As i have no solaris or MAC i dont know how to fix the module to bring it to
life on that mashines

=head2 DEPENDENCIE

use Carp;
use strict;
use 5.008008;
use HTTP::Request;
use LWP::UserAgent;
use Compress::Zlib;
use Fcntl ':flock';


=head2 EXPORT


	beautifyRawIPfromIPFilter - this function beautifies ips in the form of 222.223.208.000 to 222.223.208.0 - not used in programm

	readIPFilterFile - this is the function that reads and simply preparses the ipfilter.dat file
	
	httpGetStore - function that downloads the ipfilter.dat file if the uri is an http link
	
	_ip2long - transfers an ip to a long var ( in perl its a long integer )

	_long2ip - transfers an long integer back to an ip adress - not used in programm

	isValid - checks a given ip against the ipfilter.dat file

	gunzip - uncompression of an gzipped/zipped ipfilter.dat file in the form of ipfilter.dat.gz

	_init - initialising functions


=head1 SEE ALSO TORRENT

eMule | BitTorrent | Torrent Sites using ipfilter.dat perl modules 

http://www.zoozle.net

http://www.zoozle.org

http://www.zoozle.biz

http://search.cpan.org/author/SENGER/

NET::IPFilterSimple

=head1 AUTHOR

Sebastian Enger, bigfish82 |ät! gmail?com

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2008 by Sebastian Enger

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.8 or,
at your option, any later version of Perl 5 you may have available.

If you find an algorithm that is faster then mine than please send it to my 
email address.

Currently i am going to release a module NET::IPFilterSimple that i hope is some ms faster than NET::IPFilter
=cut
