#!/usr/local/bin/perl

use Net::UPnP::ControlPoint;
use Net::UPnP::AV::MediaServer;

use Shell qw(curl ffmpeg);

#curl('--version');
#ffmpeg('-version');

#------------------------------
# program info
#------------------------------

$program_name = 'DLNA Media Sever 2 Vodcast';
$copy_right = 'Copyright (c) 2005 Satoshi Konno';
$script_name = 'dms2vodcast.pl';
$script_version = '1.0.3';

#------------------------------
# global variables
#------------------------------

@dms_content_list = ();

#------------------------------
# command option
#------------------------------

$rss_file_name = "";
$base_directory = "./";
$rss_base_url= "http://localhost";
$rss_description = "CyberGarage Vodcast";
$rss_language = "";
$rss_link= "";
$rss_title = "CyberGarage";
$requested_count = 0;
$mp4_format = 'ipod';
$title_regexp = "";
 
@command_opt = (
['-b', '--base-url', '<url>', 'Set the base url in the item link property of the output RSS file'],
['-B', '--base-directory', '<url>', 'Set the base directory to output the RSS file and the MPEG4 files'],
['-d', '--rss-description', '<description>', 'Set the description tag in the output RSS file'],
['-g', '--rss-language', '<language>', 'Set the language tag in the output RSS file'],
['-h', '--help', '', 'This is help text.'],
['-l', '--rss-link', '<link>', 'Set the link tag in the output RSS file'],
['-r', '--requested-count', '<url>', 'Set the max request count to the media server contents'],
['-t', '--rss-title', '<file>', 'Set the title tag in the output RSS file'],
['-f', '--mp4-format', '<ipod | psp>', 'Set the MPEG4 format'],
['-s', '--search-title', '<regular expression>', 'Set the regular expression of the content titles by UTF-8'],
);

sub is_command_option {
	($opt) = @_;
	for ($n=0; $n<@command_opt; $n++) {
		if ($opt eq $command_opt[$n][0] || $opt eq $command_opt[$n][1]) {
			return $n;
		}
	}
	return -1;
}

#------------------------------
# main (pase command line)
#------------------------------

for ($i=0; $i<(@ARGV); $i++) {
	$opt = $ARGV[$i];
	$opt_num = is_command_option($opt);
	$opt_short_name = '';
	if ($opt_num < 0) {
		if ($opt =~ m/^-/) {
			print "$script_name : option $opt is unknown\n";
			print "$script_name : try \'$script_name --help\' for more information	\n";
			exit 1;
		}
	}
	else {
			$opt_short_name = $command_opt[$opt_num][0];
	}
	if ($opt_short_name eq '-h') {
		print "Usage : $script_name [options...] <output RSS file name>\n";
		print "Options : \n";
		$max_opt_output_len = 0;
		for ($n=0; $n<@command_opt; $n++) {
			$opt_output_len = length("$command_opt[$n][0]\/$command_opt[$n][1] $command_opt[$n][2]");
			if ($max_opt_output_len <= $opt_output_len) {
				$max_opt_output_len = $opt_output_len;
			}
		}
		for ($n=0; $n<@command_opt; $n++) {
			$opt_output_str = "$command_opt[$n][0]\/$command_opt[$n][1] $command_opt[$n][2]";
			print $opt_output_str;
			for ($j=0; $j<($max_opt_output_len-length($opt_output_str)); $j++) {
				print " ";
			}
			print " $command_opt[$n][3]\n";
		}
		exit 1;
	} elsif ($opt_short_name eq '-b') {
		$rss_base_url = $ARGV[++$i];
	} elsif ($opt_short_name eq '-B') {
		$base_directory = $ARGV[++$i];
	} elsif ($opt_short_name eq '-d') {
		$rss_description = $ARGV[++$i];
	} elsif ($opt_short_name eq '-g') {
		$rss_language = $ARGV[++$i];
	} elsif ($opt_short_name eq '-l') {
		$rss_link = $ARGV[++$i];
	} elsif ($opt_short_name eq '-r') {
		$requested_count = $ARGV[++$i];
	} elsif ($opt_short_name eq '-t') {
		$rss_title = $ARGV[++$i];
	} elsif ($opt_short_name eq '-f') {
		$mp4_format = $ARGV[++$i];
		if ($mp4_format ne 'ipod' && $mp4_format ne 'psp') {
			print "Unkown MPEG4 format : $mp4_format !!\n";
			exit 1;
		}
	} elsif ($opt_short_name eq '-s') {
		$title_regexp = $ARGV[++$i];
	} else {
		$rss_file_name = $opt;
	}
}

if (length($rss_file_name) <= 0) {
	print "$script_name : Must specify a output RSS file name\n";
	print "$script_name : try \'$script_name --help\' for more information	\n";
	exit 1	;
}

print "$program_name (v$script_version), $copy_right\n";
print "Output RSS file name = $rss_file_name\n";
print "  title : $rss_title\n";
print "  description : $rss_description\n";
print "  language : $rss_language\n";
print "  base url : $rss_base_url\n";
print "  base directory : $base_directory\n";
print "  requested_count : $requested_count\n";
print "  mp4_format : $mp4_format\n";
print "  search regexp : $title_regexp\n";

#------------------------------
# main
#------------------------------

my $obj = Net::UPnP::ControlPoint->new();

$retry_cnt = 0;
@dev_list = ();
while (@dev_list <= 0 || $retry_cnt > 5) {
#	@dev_list = $obj->search(st =>'urn:schemas-upnp-org:device:MediaServer:1', mx => 10);
	@dev_list = $obj->search(st =>'upnp:rootdevice', mx => 3);
	$retry_cnt++;
} 

$devNum= 0;
foreach $dev (@dev_list) {
	$device_type = $dev->getdevicetype();
	if  ($device_type ne 'urn:schemas-upnp-org:device:MediaServer:1') {
		next;
	}
	unless ($dev->getservicebyname('urn:schemas-upnp-org:service:ContentDirectory:1')) {
		next;
	}
	print "[$devNum] : " . $dev->getfriendlyname() . "\n";
	$mediaServer = Net::UPnP::AV::MediaServer->new();
	$mediaServer->setdevice($dev);
	#@content_list = $mediaServer->getcontentlist(ObjectID => 0, RequestedCount => $requested_count);
	@content_list = $mediaServer->getcontentlist(ObjectID => 0);
	#print "content_list = @content_list\n";
	foreach $content (@content_list) {
		parse_content_directory($mediaServer, $content);
	}
	$devNum++;
}

#------------------------------
# Output RSS file
#------------------------------

if (@dms_content_list <= 0) {
	print "Couldn't find video contents !!\n";
	exit 1;
}

$output_rss_filename = $base_directory . $rss_file_name;

open(RSS_FILE, ">$output_rss_filename") || die "Couldn't open the specifed output file($output_rss_filename)\n";

$rss_header = <<"RSS_HEADER";
<?xml version="1.0" encoding="utf-8"?>
<rss xmlns:itunes="http://www.itunes.com/DTDs/Podcast-1.0.dtd" version="2.0">
<channel>
<title>$rss_title</title>
<language>$rss_language</language>
<description>$rss_description</description>
<link>$rss_link</link>
RSS_HEADER
print RSS_FILE $rss_header;

foreach $content (@dms_content_list){
	$title = $content->{'title'};	
	$fname = $content->{'file_name'};
	$fsize = $content->{'file_size'};

$mp4_link = $rss_base_url . $fname;
$mp4_item = <<"RSS_MP4_ITEM";
<item>
<title>$title</title>
<guid isPermalink="false">$mp4_link</guid>
<enclosure url="$mp4_link" length="$fsize" type="video/mp4" />
</item>
RSS_MP4_ITEM
	print RSS_FILE $mp4_item;
}

$rss_footer = <<"RSS_FOOTER";
</channel>
</rss>
RSS_FOOTER
print RSS_FILE $rss_footer;

	close(RSS_FILE);

$rss_outputed_items = @dms_content_list;
print "Outputed $rss_outputed_items RSS items to $output_rss_filename\n";

#------------------------------
# parse_content_directory
#------------------------------

sub parse_content_directory {
	($mediaServer, $content) = @_;
	my $objid = $content->getid();

	if ($content->isitem()) {
		my $title = $content->gettitle();
		my $mime = $content->getcontenttype();
		if ( ($mime =~ m/video/) && ( (length($title_regexp) == 0) || ($title =~ m/$title_regexp/) ) ) {
			my $dms_content_count = @dms_content_list;
			if ($requested_count == 0 || $dms_content_count < $requested_count) {
				my $mp4_content = mpeg2tompeg4($mediaServer, $content);
				if (defined($mp4_content)) {
					push(@dms_content_list, $mp4_content);
				}
			}
		}
	}
	
	unless ($content->iscontainer()) {
		return;
	}

	my @child_content_list = $mediaServer->getcontentlist(ObjectID => $objid );
	
	if (@child_content_list <= 0) {
		return;
	}
	
	foreach my $child_content (@child_content_list) {
		parse_content_directory($mediaServer, $child_content);
	}
}

#------------------------------
# mpeg2tompeg4
#------------------------------

sub mpeg2tompeg4 {
	($mediaServer, $content) = @_;
	my $objid = $content->getid();
	my $title = $content->gettitle();
	my $url = $content->geturl();
	
	print "[$objid] $title ($url)\n";
	
	my $dev = $mediaServer->getdevice();
	my $dev_friendlyname = $dev->getfriendlyname();
	my $dev_udn = $dev->getudn();
	$dev_udn =~ s/:/-/g;
	
	my $filename_body = $dev_friendlyname . "_" . $dev_udn . "_" . $objid;
	$filename_body =~ s/ //g;
	$filename_body =~ s/\//-/g;
	
	my $mpeg2_file_name = $filename_body . ".mpeg";
	my $mpeg4_file_name = $filename_body . "_" . $mp4_format . ".m4v";
	my $output_mpeg4_file_name = $base_directory . $mpeg4_file_name;

	if (!(-e $output_mpeg4_file_name)) {	
		$curl_opt = "\"$url\" -o \"$mpeg2_file_name\"";
		print "curl $curl_opt\n";
		curl($curl_opt);

		if ($mp4_format eq 'psp') {	
			$ffmpeg_opt = "-y -i \"$mpeg2_file_name\" -bitexact -fixaspect -s 320x240 -r 29.97 -b 768 -ar 24000 -ab 32 -f psp \"$output_mpeg4_file_name\"";
		}
		else {
			$ffmpeg_opt = "-y -i \"$mpeg2_file_name\" -bitexact -fixaspect -s 320x240 -r 29.97 -b 850 -acodec aac -ac 2 -ar 44100 -ab 64 -f mp4 \"$output_mpeg4_file_name\"";
		}
	
		print "ffmpeg $ffmpeg_opt\n";
		ffmpeg($ffmpeg_opt);
		
		unlink($mpeg2_file_name);
	}
		
	if (!(-e $output_mpeg4_file_name)) {	
		return undef;
	}
	
	my $mpeg4_file_size = -s $output_mpeg4_file_name;
	
	if ($mpeg4_file_size <= 0) {
		return undef;
	}
		
	my %info = (
		'objid' => $objid,
		'title' => $title,
		'file_name' => $mpeg4_file_name,
		'file_size' => $mpeg4_file_size,
	);
	
	return \%info;
}

exit 0;

