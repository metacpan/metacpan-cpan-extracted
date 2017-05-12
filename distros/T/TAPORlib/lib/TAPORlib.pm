package TAPORlib;

=head1 NAME

C<TAPORlib> - TAPORlib is a Perl module that contains some useful functions.

=head1 DESCRIPTION

This library used by some great modules as WWW::Promotion, etc.
It is provided by TAPOR, Inc.

=cut

##############################################################################
use strict;
use vars qw($VERSION 
	    @ISA 
	    @EXPORT 
	    @EXPORT_OK 
	    %countrycodes 
	    %countrycodesbyname
	    %operation_systems
	    %monthbynumber
	    %monthbyname
	    %color
	    @rndletters 
	    $eol
	    );

require Exporter;

use IO::Socket;
use IO::Select;
use Socket;
use Carp;
use POSIX;

@ISA = qw(Exporter);
@EXPORT = qw(&Delete_CRLF_from_End_Of_String
	     &add_string_to_file
             &add_string_to_file_spec_output
	     &GetAllFilesInDir
	     &GetAllFilesContaningInDir
	     &GetPageNow_4
	     &uri_escape
	     &HTMLdie
	     &isrunninglocaly
	     &newsocketto
	     &GenerateRandomString	     
	     &SelectRandomStringFromFile
	     &CreateAndSendOutHtmlPage
	     &CheckForDomain
	     &SendToDomainIfNotThisDomain
	     &MassiveToString
	     &CheckProxy
	     &win2koi
	     &koi2win
	     &GetScriptName
	     &SetScriptDirAsCurrent
	     &IsDateValid
	     &parse_form_2
	     &GetDate_2
	     &GetDateRus_2
	     &SendEmailMsg
	     &SendEmailMultiMsg
	     &getcookies
	     &joincookies
	     &joincookiesinhash
	     &create_error_string
	     &LimitMassive
	     &GetTops
	     &IsSearchEngine
	     &DetectOperationSystem
	     &IsAllreadyRunning
	     &IsAllreadyRunning_2
	     &change_spec_labels
	     &ViewSpecHtmFile
	     &SelectRandomProxyServerFromFile
	     &CorrectLinksOnPage
	     &send_null_image
	     %countrycodes
	     %countrycodesbyname
	     %operation_systems
	     %monthbynumber
	     %monthbyname
	     %color
	     @rndletters 
	     $eol
	     );

# create_error_string - /No desc
# change_spec_labels - /No desc
# ViewSpecHtmFile - /No desc
# CorrectLinksOnPage - /No desc

@EXPORT_OK = qw();

$VERSION = "8.70";

##############################################################################

=head1 IMPORTED FUNCTIONS/VARS

=head1

=head2 $eol
 
 Description:

 $eol        = "\x0D\x0A";

=cut  

$eol        = "\x0D\x0A"; # "\r\n";

##############################################################################

=head2 @rndletters
 
 Description:

 @rndletters = qw(q w e r t y u i o p a s d f g h j k l z x c v b n m);

=cut  

@rndletters = qw(q w e r t y u i o p a s d f g h j k l z x c v b n m);

##############################################################################

=head2 %countrycodes / %countrycodesbyname
 
 Description:

 %countrycodes = (
    'ca' => 'Canada',
    'af' => 'Afghanistan',
    'al' => 'Albania',
    'dz' => 'Algeria',
    ...
    );

 %countrycodesbyname = reverse %countrycodes;

=cut  

%countrycodes = (
    'ca' => 'Canada',
    'af' => 'Afghanistan',
    'al' => 'Albania',
    'dz' => 'Algeria',
    'as' => 'American Samoa',
    'ad' => 'Andorra',
    'ao' => 'Angola',
    'ai' => 'Anguilla',
    'aq' => 'Antarctica',
    'ag' => 'Antigua and Barbuda',
    'ar' => 'Argentina',
    'am' => 'Armenia',
    'aw' => 'Aruba',
    'au' => 'Australia',
    'at' => 'Austria',
    'az' => 'Azerbaijan',
    'bs' => 'Bahamas',
    'bh' => 'Bahrain',
    'bd' => 'Bangladesh',
    'bb' => 'Barbados',
    'by' => 'Belarus',
    'be' => 'Belgium',
    'bz' => 'Belize',
    'bj' => 'Benin',
    'bm' => 'Bermuda',
    'bt' => 'Bhutan',
    'bo' => 'Bolivia',
    'ba' => 'Bosnia and Herzegovina',
    'bw' => 'Botswana',
    'bv' => 'Bouvet Island',
    'br' => 'Brazil',
    'io' => 'British Indian Ocean Territory',
    'vg' => 'British Virgin Islands',
    'bn' => 'Brunei',
    'bg' => 'Bulgaria',
    'bf' => 'Burkina Faso',
    'bi' => 'Burundi',
    'kh' => 'Cambodia',
    'cm' => 'Cameroon',
    'cv' => 'Cape Verde',
    'ky' => 'Cayman Islands',
    'cf' => 'Central African Republic',
    'td' => 'Chad',
    'cl' => 'Chile',
    'cn' => 'China',
    'cx' => 'Christmas Island',
    'cc' => 'Cocos Islands',
    'co' => 'Colombia',
    'km' => 'Comoros',
    'cg' => 'Congo',
    'ck' => 'Cook Islands',
    'cr' => 'Costa Rica',
    'hr' => 'Croatia',
    'cu' => 'Cuba',
    'cy' => 'Cyprus',
    'cz' => 'Czech Republic',
    'dk' => 'Denmark',
    'dj' => 'Djibouti',
    'dm' => 'Dominica',
    'do' => 'Dominican Republic',
    'tp' => 'East Timor',
    'ec' => 'Ecuador',
    'eg' => 'Egypt',
    'sv' => 'El Salvador',
    'gq' => 'Equatorial Guinea',
    'er' => 'Eritrea',
    'ee' => 'Estonia',
    'et' => 'Ethiopia',
    'fk' => 'Falkland Islands',
    'fo' => 'Faroe Islands',
    'fj' => 'Fiji',
    'fi' => 'Finland',
    'fr' => 'France',
    'gf' => 'French Guiana',
    'pf' => 'French Polynesia',
    'tf' => 'French Southern Territories',
    'ga' => 'Gabon',
    'gm' => 'Gambia',
    'ge' => 'Georgia',
    'de' => 'Germany',
    'gh' => 'Ghana',
    'gi' => 'Gibraltar',
    'gr' => 'Greece',
    'gl' => 'Greenland',
    'gd' => 'Grenada',
    'gp' => 'Guadeloupe',
    'gu' => 'Guam',
    'gt' => 'Guatemala',
    'gn' => 'Guinea',
    'gw' => 'Guinea-Bissau',
    'gy' => 'Guyana',
    'ht' => 'Haiti',
    'hm' => 'Heard and McDonald Islands',
    'hn' => 'Honduras',
    'hk' => 'Hong Kong',
    'hu' => 'Hungary',
    'is' => 'Iceland',
    'in' => 'India',
    'id' => 'Indonesia',
    'ir' => 'Iran',
    'iq' => 'Iraq',
    'ie' => 'Ireland',
    'il' => 'Israel',
    'it' => 'Italy',
    'ci' => 'Ivory Coast',
    'jm' => 'Jamaica',
    'jp' => 'Japan',
    'jo' => 'Jordan',
    'kz' => 'Kazakhstan',
    'ke' => 'Kenya',
    'ki' => 'Kiribati',
    'kp' => 'Korea, North',
    'kr' => 'Korea, South',
    'kw' => 'Kuwait',
    'kg' => 'Kyrgyzstan',
    'la' => 'Laos',
    'lv' => 'Latvia',
    'lb' => 'Lebanon',
    'ls' => 'Lesotho',
    'lr' => 'Liberia',
    'ly' => 'Libya',
    'li' => 'Liechtenstein',
    'lt' => 'Lithuania',
    'lu' => 'Luxembourg',
    'mo' => 'Macau',
    'mk' => 'Macedonia, Former Yugoslav Republic of',
    'mg' => 'Madagascar',
    'mw' => 'Malawi',
    'my' => 'Malaysia',
    'mv' => 'Maldives',
    'ml' => 'Mali',
    'mt' => 'Malta',
    'mh' => 'Marshall Islands',
    'mq' => 'Martinique',
    'mr' => 'Mauritania',
    'mu' => 'Mauritius',
    'yt' => 'Mayotte',
    'mx' => 'Mexico',
    'fm' => 'Micronesia, Federated States of',
    'md' => 'Moldova',
    'mc' => 'Monaco',
    'mn' => 'Mongolia',
    'ms' => 'Montserrat',
    'ma' => 'Morocco',
    'mz' => 'Mozambique',
    'mm' => 'Myanmar',
    'na' => 'Namibia',
    'nr' => 'Nauru',
    'np' => 'Nepal',
    'nl' => 'Netherlands',
    'an' => 'Netherlands Antilles',
    'nc' => 'New Caledonia',
    'nz' => 'New Zealand',
    'ni' => 'Nicaragua',
    'ne' => 'Niger',
    'ng' => 'Nigeria',
    'nu' => 'Niue',
    'nf' => 'Norfolk Island',
    'mp' => 'Northern Mariana Islands',
    'no' => 'Norway',
    'om' => 'Oman',
    'pk' => 'Pakistan',
    'pw' => 'Palau',
    'pa' => 'Panama',
    'pg' => 'Papua New Guinea',
    'py' => 'Paraguay',
    'pe' => 'Peru',
    'ph' => 'Philippines',
    'pn' => 'Pitcairn Island',
    'pl' => 'Poland',
    'pt' => 'Portugal',
    'pr' => 'Puerto Rico',
    'qa' => 'Qatar',
    're' => 'Reunion',
    'ro' => 'Romania',
    'ru' => 'Russia',
    'rw' => 'Rwanda',
    'gs' => 'S. Georgia and S. Sandwich Isls.',
    'kn' => 'Saint Kitts & Nevis',
    'lc' => 'Saint Lucia',
    'vc' => 'Saint Vincent and The Grenadines',
    'ws' => 'Samoa',
    'sm' => 'San Marino',
    'st' => 'Sao Tome and Principe',
    'sa' => 'Saudi Arabia',
    'sn' => 'Senegal',
    'sc' => 'Seychelles',
    'sl' => 'Sierra Leone',
    'sg' => 'Singapore',
    'sk' => 'Slovakia',
    'si' => 'Slovenia',
    'so' => 'Somalia',
    'za' => 'South Africa',
    'es' => 'Spain',
    'lk' => 'Sri Lanka',
    'sh' => 'St. Helena',
    'pm' => 'St. Pierre and Miquelon',
    'sd' => 'Sudan',
    'sr' => 'Suriname',
    'sj' => 'Svalbard and Jan Mayen Islands',
    'sz' => 'Swaziland',
    'se' => 'Sweden',
    'ch' => 'Switzerland',
    'sy' => 'Syria',
    'tw' => 'Taiwan',
    'tj' => 'Tajikistan',
    'tz' => 'Tanzania',
    'th' => 'Thailand',
    'tg' => 'Togo',
    'tk' => 'Tokelau',
    'to' => 'Tonga',
    'tt' => 'Trinidad and Tobago',
    'tn' => 'Tunisia',
    'tr' => 'Turkey',
    'tm' => 'Turkmenistan',
    'tc' => 'Turks and Caicos Islands',
    'tv' => 'Tuvalu',
    'um' => 'U.S. Minor Outlying Islands',
    'ug' => 'Uganda',
    'ua' => 'Ukraine',
    'ae' => 'United Arab Emirates',
    'uk' => 'United Kingdom',
    'us' => 'United States of America',
    'uy' => 'Uruguay',
    'uz' => 'Uzbekistan',
    'vu' => 'Vanuatu',
    'va' => 'Vatican City',
    've' => 'Venezuela',
    'vn' => 'Vietnam',
    'vi' => 'Virgin Islands',
    'wf' => 'Wallis and Futuna Islands',
    'eh' => 'Western Sahara',
    'ye' => 'Yemen',
    'yu' => 'Yugoslavia (Former)',
    'zr' => 'Zaire',
    'zm' => 'Zambia',
    'zw' => 'Zimbabwe',
);

%countrycodesbyname = reverse %countrycodes;

##############################################################################

=head2 %operation_systems
 
 Description:

 %operation_systems = (
    'Windows 98'     => 'Windows 98',
    'Win98'          => 'Windows 98',
    'Windows 95'     => 'Windows 95',
    'Win95'          => 'Windows 95',
    'Mozilla/3.01 (compatible;)' => 'Windows 95',

=cut  

%operation_systems = (
    'Windows 98'     => 'Windows 98',
    'Win98'          => 'Windows 98',
    'Windows 95'     => 'Windows 95',
    'Win95'          => 'Windows 95',
    'Mozilla/3.01 (compatible;)' => 'Windows 95',
    'Windows NT 5.0' => 'Windows NT 5.0',
    'Windows NT 4.0' => 'Windows NT 4.0',
    'Windows NT'     => 'Windows NT 4.0',
    'WinNT'          => 'Windows NT 4.0',
    'Mac_PowerPC'    => 'Macintosh',
    'Mac_PPC'        => 'Macintosh',
    'Macintosh'      => 'Macintosh',
    'Mac_68000'      => 'Macintosh',
    'Linux'          => 'Linux',
    'FreeBSD'        => 'FreeBSD',
    'Windows 2000'   => 'Windows 2000',
    'Win2000'        => 'Windows 2000',
    'Windows ME'     => 'Windows ME',
    'WinME'          => 'Windows ME',
    'Konqueror'      => 'Linux',
    'Windows 3.1'    => 'Windows 3.1',
    'Win3.1'         => 'Windows 3.1',
    'SunOS'          => 'SunOS',
    'Irix'           => 'Unix',
    'Unix'           => 'Unix',
);

##############################################################################

=head2 %monthbynumber / %monthbyname
 
 Description:

 %monthbynumber = (
    '1'  => "January",
    '2'  => "February",
    '3'  => "March",
    '4'  => "April",
    ...);
    
 %monthbyname = reverse %monthbynumber;

=cut  

%monthbynumber = (
    '1'  => "January",
    '2'  => "February",
    '3'  => "March",
    '4'  => "April",
    '5'  => "May",
    '6'  => "June",
    '7'  => "July",
    '8'  => "August",
    '9'  => "September",
    '10' => "October",
    '11' => "November",
    '12' => "December",
);
%monthbyname = reverse %monthbynumber;

##############################################################################

=head2 %color
 
 Description:

 %color =(
    'normal'     => "[0;37m",
    'black'      => "[0;30m",
    'red'        => "[0;31m" ,
    'ligthred'   => "[1;31m",
    ...
    );
    
=cut  

%color =(
    'normal'     => "[0;37m",
    'black'      => "[0;30m",
    'red'        => "[0;31m" ,
    'ligthred'   => "[1;31m",
    'green'      => "[0;32m",
    'ligthgreen' => "[1;32m",
    'blue'       => "[0;34m",
    'ligthblue'  => "[1;34m",
    'white'      => "[0;38m",
    'yelow'      => "[1;33m" ,
    'yellow'      => "[1;33m" ,
    '0' => "[0;30m",
    '1' => "[0;31m",
    '2' => "[0;32m",
    '3' => "[0;33m",
    '4' => "[0;34m",
    '5' => "[0;35m",
    '6' => "[0;36m",
    '7' => "[0;37m",
    '8' => "[0;38m",
    '9' => "[0;39m",
    'sim' => "[5m",
);

##############################################################################

=head2 $string = &Delete_CRLF_from_End_Of_String($string);
 
 Description:

 Function removes trailing "r" and "\n" from end of $string.

=cut  

sub Delete_CRLF_from_End_Of_String {
    local($_) = shift;
    
    while(1)
	{
	if(/\r$/) { $_ = substr($_,0,-1); }
	elsif(/\n$/) { $_ = substr($_,0,-1); }
	else { return $_ };
	}
}
###############################################################################

=head2 &add_string_to_file("filename",$string);

 Description:

 This function adds $string to the end of file "filename".

=cut  

sub add_string_to_file {
    my ($file,$data) = @_;
    
    if(open(FILE,">>$file"))
	{
        print FILE $data;
        close(FILE);
	}
}

=head2 &add_string_to_file_spec_output("filename",$who,$string,$end);

 Description:

 This function makes special output to "filename".
 String shows like this:
 
 --- $who ---------------- $string --------------------$end

=cut  

sub add_string_to_file_spec_output {
    my ($file,$who,$data,$end) = @_;

    # Create string
 
    my $maxtotal = 70;
    my $body = "-";
    my $prefix = $body . $body . $body;
                                                        
    my $len  = (length($prefix) + 1 + length($who) + 3 + length($data) + 2);

    if($len >= ($maxtotal-1))
	{
        add_string_to_file($file,"$prefix $who $body $data $body" . $end);
	}
    else
	{
        my $len1 = int(($maxtotal - $len)/2);
        my $len2 = $maxtotal - $len - $len1;

        my $string1;
        my $string2;

        while(length($string1)<$len1) { $string1 = $string1 . $body;};
        while(length($string2)<$len2) { $string2 = $string2 . $body;};
        add_string_to_file($file,"$prefix $who $string1 $data $string2" . $end);
	}
}
###############################################################################

=head2 @allfiles = &GetAllFilesInDir($dirname);

 Description:

 This function returns massive that contains filenames with 
 path in directory $dirname and filenames with path in subdirs also.

=cut  

sub GetAllFilesInDir {
my($usedir) = @_;
my(@allfiles,@bodydir,$fileindir);

@allfiles = ();
if(opendir(DIR,$usedir))
    {
    @bodydir = readdir(DIR);
    close(DIR);
    foreach $fileindir (@bodydir)
    	{
	if($fileindir eq '.' || $fileindir eq '..') {next;}
	if(-d $usedir . "/" . $fileindir)
	    {
	    push(@allfiles,&GetAllFilesInDir("$usedir/$fileindir"));
	    }
	else
	    {
	    push(@allfiles,"$usedir/$fileindir");
	    }
	}
    }
return @allfiles;
}
##############################################################################

=head2 @allfilescontents = &GetAllFilesContaningInDir($dirname);

 Description:

 This function returns massive that contains content of all
 files in directory $dirname (subdirs also).

=cut  

sub GetAllFilesContaningInDir {
    my($dir) = @_;

    my(@keys,@returnkeys);
    
    foreach (GetAllFilesInDir($dir))
	{
	if(!($_)) {next;}
	if(open(FILE,$_))
	    {
	    @keys = <FILE>;
	    close(FILE);
	    foreach (@keys)
		{
		$_ = VoidCRLF($_);
		if(!($_)) {next;}
        	push(@returnkeys,$_);
		}
	    }
	}
    return @returnkeys;
}	
###############################################################################

=head2 %out = &GetPageNow_4(%pagenow);

 Description:
 
 Use this function to get page from website. 

 Usage:

 $pagenow{'url'}     = "http://www.any.com/anyware";
 $pagenow{'method'}  = "POST|GET";
 $pagenow{'referer'} = "http://www.any.com/anyware/ref";
 $pagenow{'content'} = "user=blah\&info=blah-blah";

 # If defined this agent string will be used insted Netscape
 $pagenow{'agent'}  = "My AGENT";

 # If specified Print some useful information to this logfile;
 $pagenow{'logfile'} = "logfile.log";

 # If proxy not specified then Get Page without usage of proxy.
 $pagenow{'proxy'} = "proxy.online.ru:8080";

 # If specified then send to page this cookies:
 $pagenow{'cookies'} = "C=12345; F=1";

 # TimeOut to Connect To Proxy/Host. Default: 60
 $pagenow{'timeoutconnect'} = 60;

 # TimeOut to Request Page. Default: 300
 $pagenow{'timeoutrequest'} = 180;

 # No Request. GetPageNow_4() returns simple 'FAST MODE' page.
 $pagenow{'norequest'} = 1;

 # Show Error Page If Error Detected
 $pagenow{'showerrors'} = 1;

 %out = &GetPageNow_4(%pagenow);

 Output:
 
 $out{'error'} == 0 - No errors
 $out{'error'} == 1 - Some Error.
 $out{'errortxt'}   - Error description if $out{'error'} == 1
 $out{'status'}  - Status of downloaded page
 $out{'headers'} - Header of downloaded page
 $out{'body'}    - Body of downloaded page
 $out{'cookies'} - Cookies If page returns some cookies

=cut

sub GetPageNow_4 {
    my(%pagenow) = @_;
    my(%out);

    my($logfile) = $pagenow{'logfile'}; # // ?
    
    $pagenow{'timeoutconnect'} = 60 if(!$pagenow{'timeoutconnect'});
    $pagenow{'timeoutrequest'} = 300 if(!$pagenow{'timeoutrequest'});

    add_string_to_file($logfile,"\n");
    add_string_to_file_spec_output($logfile,"TAPORlib::GetPageNow_4()","Input Data","\n");

    foreach (sort keys %pagenow)
        {
        $pagenow{$_} = Delete_CRLF_from_End_Of_String($pagenow{$_});
        add_string_to_file($logfile,"\$pagenow{'$_'} = '$pagenow{$_}'\n");
        }

     # Checking input data

    if($pagenow{'method'} ne 'POST' && $pagenow{'method'} ne 'GET')
        {
        $out{'errortxt'} = create_error_string("TAPORlib::GetPageNow_4()","Invalid method: '$pagenow{'method'}'");
	goto print_error_to_log_and_exit;
        }
    if($pagenow{'method'} eq 'POST' && !$pagenow{'content'})
        {
        $out{'errortxt'} = create_error_string("TAPORlib::GetPageNow_4()","POST without content not allowed");
	goto print_error_to_log_and_exit;
        }
    if($pagenow{'url'} !~ m|^(http://)([^/\?\\]+)|i)
        {
        $out{'errortxt'} = create_error_string("TAPORlib::GetPageNow_4()","Invalid url format: '$pagenow{'url'}'");
        goto print_error_to_log_and_exit;
        }	
    my($hostaddr,$hostport) = split(/\:/,$2);
    if($hostport && $hostport !~ m/^[0-9]+$/)
	{
        $out{'errortxt'} = create_error_string("TAPORlib::GetPageNow_4()","Invalid host/port format: '$pagenow{'url'}'");
        goto print_error_to_log_and_exit;
	}
    $hostport = $hostport ? $hostport : 80;
    add_string_to_file($logfile,"Host: '$hostaddr' Port: '$hostport'\n");
    
    $pagenow{'savedurl'} = $pagenow{'url'};
    
    $out{'error'}=1;

    #----------------- Change Reserved syms to %xx -----------------------
    if($pagenow{'content'})
	{
	my($reserved)    = ";\\/?:\\@#";
	my($unsafe)      = "\x00-\x20{}|\\\\^\\[\\]`<>\"\x7F-\xFF";
	$pagenow{'content'} =~ s/ /+/g;
	$pagenow{'content'} = &uri_escape($pagenow{'content'},$reserved . $unsafe);
	$pagenow{'contentlen'} = length($pagenow{'content'});
	}
    #---------------------------------------------------------------------

    my($hostconnectaddr,$hostconnectport);
    
    if($pagenow{'proxy'})
	{
        ($hostconnectaddr,$hostconnectport) = split(/\:/,$pagenow{'proxy'});
    	if($hostconnectport && $hostconnectport !~ m/^[0-9]+$/)
	   {
           $out{'errortxt'} = create_error_string("TAPORlib::GetPageNow_4()","Invalid host/port format for proxy: '$pagenow{'proxy'}'");
           goto print_error_to_log_and_exit;
	   }
        $hostconnectport = $hostconnectport ? $hostconnectport : 80;
    	add_string_to_file($logfile,"ProxyHost: '$hostconnectaddr' ProxyPort: '$hostconnectport'\n");
	}
    else
	{
        ($hostconnectaddr,$hostconnectport) = ($hostaddr,$hostport);
	$pagenow{'url'} =~ m|^(http://)([^/\?\\]*)([^\s\r\n]*)$|i;
	$pagenow{'url'} = $3;
	if(!$pagenow{'url'}) { $pagenow{'url'} = "/";}
    	add_string_to_file($logfile,"New \$pagenow{'url'} = '$pagenow{'url'}' (because no proxy)\n");
	}	

    # Connecting

    my $sock  = IO::Socket->new(Timeout => $pagenow{'timeoutconnect'});
    
    $sock->socket(AF_INET, SOCK_STREAM, 0);
    if(!$sock)
	{
        $out{'errortxt'} = create_error_string("TAPORlib::GetPageNow_4()","Error in socket()");
	goto print_error_to_log_and_exit;
	}
    
    my $iaddr = inet_aton($hostconnectaddr);
    if(!$iaddr)
	{
        $out{'errortxt'} = create_error_string("TAPORlib::GetPageNow_4()","Error resolving host '$hostconnectaddr'");
	goto print_error_to_log_and_exit;
	}
	
    my $paddr = sockaddr_in($hostconnectport,$iaddr);
    
    $sock->connect($paddr);
    
    if($@) 
	{
	if($@ =~ /timeout/i)
	    {
            $out{'errortxt'} = create_error_string("TAPORlib::GetPageNow_4()","Error connecting to $hostconnectaddr:$hostconnectport after $pagenow{'timeoutconnect'} seconds");
	    goto print_error_to_log_and_exit;
	    }
        $out{'errortxt'} = create_error_string("TAPORlib::GetPageNow_4()",$@);
        goto print_error_to_log_and_exit;
        }    

    add_string_to_file($logfile,"Connected to: '$hostconnectaddr:$hostconnectport'\n");
	    	    	    
# POST ------------------------------------------------------------------------
my(@data);

if($pagenow{'method'} eq 'POST') {

@data   = ("POST $pagenow{'url'} HTTP/1.0$eol");

if($pagenow{'referer'}) {push(@data,("Referer: $pagenow{'referer'}$eol"));}

if($pagenow{'proxy'}) 
    { 
    push(@data,("Proxy-Connection: Keep-Alive$eol")); 
    }    
else 
    { 
#   push(@data,("Connection: Keep-Alive$eol")); 
    push(@data,("Connection: Close$eol")); 
    }

if($pagenow{'agent'}) 
    {
    push(@data,("User-Agent: $pagenow{'agent'}$eol"));
    }
else    
    {
    push(@data,("User-Agent: Mozilla/4.7 [en] (Win98; I)$eol"));
    }

if($hostport==80)
    {
    push(@data,("Host: $hostaddr$eol"));
    }
else
    {
    push(@data,("Host: $hostaddr:$hostport$eol"));
    }    

push(@data,("Accept: image/gif, image/x-xbitmap, image/jpeg, image/pjpeg, image/png, */*$eol",
#           "Accept-Encoding: gzip$eol",
            "Accept-Language: en$eol",
            "Accept-Charset: iso-8859-1,*,utf-8$eol",
            ));

if($pagenow{'cookies'}) 
    {
    push(@data,("Cookie: $pagenow{'cookies'}$eol"));
    }

push(@data,("Content-type: application/x-www-form-urlencoded$eol",
            "Content-length: $pagenow{'contentlen'}$eol$eol",
	    ));
	    
push(@data,("$pagenow{'content'}"));

}

# GET ------------------------------------------------------------------------
if($pagenow{'method'} eq 'GET') {

if(!$pagenow{'content'}) {@data = ("GET $pagenow{'url'} HTTP/1.0$eol");}
else {@data = ("GET $pagenow{'url'}?$pagenow{'content'} HTTP/1.0$eol");}

if($pagenow{'referer'}) {push(@data,("Referer: $pagenow{'referer'}$eol"));}

if($pagenow{'proxy'}) 
    { 
    push(@data,("Proxy-Connection: Keep-Alive$eol")); 
    }    
else 
    { 
#   push(@data,("Connection: Keep-Alive$eol")); 
    push(@data,("Connection: Close$eol")); 
    }

if($pagenow{'agent'}) 
    {
    push(@data,("User-Agent: $pagenow{'agent'}$eol"));
    }
else    
    {
    push(@data,("User-Agent: Mozilla/4.7 [en] (Win98; I)$eol"));
    }

if($hostport==80)
    {
    push(@data,("Host: $hostaddr$eol"));
    }
else
    {
    push(@data,("Host: $hostaddr:$hostport$eol"));
    }    

push(@data,("Accept: image/gif, image/x-xbitmap, image/jpeg, image/pjpeg, image/png, */*$eol",
#           "Accept-Encoding: gzip$eol",
            "Accept-Language: en$eol",
            "Accept-Charset: iso-8859-1,*,utf-8$eol",
	    "Pragma: No-Cache$eol"));

if($pagenow{'cookies'}) 
    {
    push(@data,("Cookie: $pagenow{'cookies'}$eol$eol"));
    }
else
    {
    push(@data,("$eol"));
    }

}


# REQUEST TO LOG ---

add_string_to_file($logfile,"\n");
add_string_to_file_spec_output($logfile,"TAPORlib::GetPageNow_4()","Request (AS-IS)","\n");
foreach (@data) {add_string_to_file($logfile,$_);}
add_string_to_file($logfile,"\n");
add_string_to_file_spec_output($logfile,"TAPORlib::GetPageNow_4()","Request End","\n");

# SEND REQUEST ---

my($timeout) = $pagenow{'timeoutrequest'};

my $select = IO::Select->new();
$select->add($sock);

if(!$select->can_write($timeout))
    {
    $out{'errortxt'} = create_error_string("TAPORlib::GetPageNow_4()","Timeout sending request after $timeout seconds");
    goto print_error_to_log_and_exit;
    }

print $sock @data;

my(@body);
    
# GET PAGE ---------------------------------------------------------------
if($pagenow{'norequest'})
    {
    $sock->close();

    add_string_to_file($logfile,"\n");
    add_string_to_file_spec_output($logfile,"TAPORlib::GetPageNow_4()",">>> FASTMODE[tm] >>>","\n");

    @body = ();
    push @body, <<FASTBODY;
    
<HTML>
<BODY>
<CENTER>FAST</CENTER>
</BODY>
</HTML>
    
FASTBODY

    $out{'error'} = 0;
    $out{'status'} = "HTTP/1.1 200 OK";
    delete($out{'headers'});
    $out{'body'} = &MassiveToString(@body);
    return %out;
    }

# Status ----------------------------------------------------------------------
$out{'status'} = undef;

if(!$select->can_read($timeout))
    {
    $out{'errortxt'} = create_error_string("TAPORlib::GetPageNow_4()","Timeout recv status after $timeout seconds");
    goto print_error_to_log_and_exit;
    }
$out{'status'}  = <$sock>;

# Headers ---

$out{'headers'} = undef;

do
    {
    if(!$select->can_read($timeout))
	{
        $out{'errortxt'} = create_error_string("TAPORlib::GetPageNow_4()","TimeOut recv headers after $timeout seconds");
	goto print_error_to_log_and_exit;
	}
    $out{'headers'} .= $_ = <$sock> ;         # $headers includes last blank line
    } until (/^(\015\012|\012)$/) ;   # lines may be terminated with LF or CRLF

# Unfold long header lines, a la RFC 822 section 3.1.1

$out{'headers'} =~ s/(\015\012|\012)[ \t]/ /g ;

if(!$select->can_read($timeout))
    {
    $out{'errortxt'} = create_error_string("TAPORlib::GetPageNow_4()","TimeOut recv body after $timeout seconds");
    goto print_error_to_log_and_exit;
    }

@body=<$sock>;

$out{'body'} = "@body";

$sock->close();

my($cookies)=getcookies($out{'headers'});

if($cookies && !$pagenow{'cookies'})
    {
    $pagenow{'cookies'} = $cookies;
    }
elsif($cookies && $pagenow{'cookies'})
    {
    $pagenow{'cookies'} = joincookies($pagenow{'cookies'},$cookies);
    }
    
add_string_to_file($logfile,"STATUS:\n$out{'status'}\n");
add_string_to_file($logfile,"HEADERS:\n$out{'headers'}\n");

if($pagenow{'cookies'}) 
    {
    add_string_to_file($logfile,"Cookies: '$pagenow{'cookies'}'\n\n");
    }
else 
    {
    add_string_to_file($logfile,"Cookies: <NONE>\n\n");
    }

#add_string_to_file($logfile,"@body\n\n");
add_string_to_file($logfile,">--- BODY ---<\n\n");

if ($out{'status'} =~ m#^HTTP/[0-9.]*\s*[45]\d\d#) 
	{
	if($pagenow{'showerrors'})
	    {
	    &HTMLdie("@body");
	    }
	else 
	    {
            $out{'errortxt'} = create_error_string("TAPORlib::GetPageNow_4()","Server answer: $out{'status'}");
	    goto print_error_to_log_and_exit;
	    }
	}

# If REDIRECT

if($out{'headers'} =~ m|^(Location:\s+)(.+?)[\s\r\n]*$|im)
        {
	add_string_to_file_spec_output($logfile,"TAPORlib::GetPageNow_4()",">>>> REDIRECT >>>>","\n\n");

	my($location) = $2;
	
	if($location !~ m|^(http://)|i)
	    {
	    $location = $pagenow{'savedurl'} . "/" . $location;
	    }
	$pagenow{'url'}	= $location;
	
        # if (http://)(some.host/test/)?(content=content)
        #    $1       $2                $3 

        if($location=~ m|^(http://)([^\?]+)\?(.*?)[\s\r\n]*$|i)
	    {
	    $pagenow{'url'}	= $1 . $2;
	    $pagenow{'content'} = $3;
	    add_string_to_file($logfile,"NEW URL: '$pagenow{'url'}'\n");
	    add_string_to_file($logfile,"NEW CONTENT: '$pagenow{'content'}'\n");
	    }
	else
	    {
	    delete($pagenow{'content'});
	    add_string_to_file($logfile,"NEW URL: '$pagenow{'url'}'\n");
	    }	    

        delete($pagenow{'contentlen'});
	delete($pagenow{'savedurl'});

	$pagenow{'method'} = "GET";
	return GetPageNow_4(%pagenow);
        }

if($pagenow{'cookies'}) {$out{'cookies'} = $pagenow{'cookies'};}
$out{'error'} = 0;
return %out;

print_error_to_log_and_exit:
add_string_to_file($logfile,"\n$out{'errortxt'}\n");
return %out;
}
###############################################################################

=head2 $text = &uri_escape($text,$pattern);

 Description:

 This function escapes url, commonly used to changes 
 special symbols in url.

 Usage:

 $text    = "sss"
 $pattern = "\x00-\xFF";
 $text = &uri_escape($text,$pattern);
 
 Output:
 
 $text = "%73%73%73";

=cut  

sub uri_escape {
    my($text,$patn) = @_;
    return undef unless defined $text;

    my %escapes;
    # Build a char->hex map
    for (0..255) 
	{
        $escapes{chr($_)} = sprintf("%%%02X", $_);
	}

    my %subst;
    if(defined $patn)
	{
	unless (exists $subst{$patn}) 
	    {
	    # Because we can't compile regex we fake it with a cached sub
	    $subst{$patn} =
	      eval "sub {\$_[0] =~ s/([$patn])/\$escapes{\$1}/g; }";
	      Carp::croak("uri_escape: $@") if $@;
	    }
	&{$subst{$patn}}($text);
	} 
    else 
	{
	# Default unsafe characters. (RFC1738 section 2.2)
	$text =~ s/([\x00-\x20"#%;<>?{}|\\\\^~`\[\]\x7F-\xFF])/$escapes{$1}/g; #"
	}
    return $text;
}
###############################################################################

=head2 &HTMLdie($text);

 Description:

 Send HTML page with $text to STDOUT and exit program.

=cut  

sub HTMLdie {
	my($msg)= @_ ;
	print "Content-type: text/html\n\n";
	print "<html><body>\n";
	print "$msg\n";
	print "</body></html>\n";
	exit;
}
##############################################################################

=head2 &isrunninglocaly()

 Description:

 Function returns TRUE if script executed in console, FALSE 
 otherwise, e.g. when running under Apache.

=cut  

sub isrunninglocaly {
    my($method) = defined($ENV{'REQUEST_METHOD'}) ? $ENV{'REQUEST_METHOD'} : 'LOCAL';
    
    if ($method eq 'GET' || $method eq 'POST') 
	{
        return 0;
	}
    return 1;
}
##############################################################################

=head2 $cookies = &getcookies($headers)

 Example:
  
 $headers = "Server: Netscape-Enterprise/2.01
Date: Thu, 29 Nov 2001 08:28:33 GMT
Set-Cookie: registered=no; path=/; domain=.excite.com; expires=Wednesday, 31-Dec-2010 12:00:00 GMT
Set-Cookie: UID=35813BB13C05F10C; path=/; domain=.excite.com; expires=Wednesday, 31-Dec-2010 12:00:00 GMT
Location: http://www.excite.com/info/add_url/thanks/?url=&email=&country=&brand=excite
X-Cache: MISS from ns.ahxk.ru
Proxy-Connection: close";
 
   $cookies = &getcookies($headers);
   print "$cookies\n";

   Output:

   UID=35813BB13C05F10C; registered=no

=cut  

sub getcookies {
    my($headers)= @_ ;

    my %totalcookies = ();

    while($headers =~ m|^(Set-Cookie:\s+)(.*?)[\r\n\s]*$|img)
	{
        my @cookies = split(/;/,$2);
	$cookies[0] =~ /^\s*(.*?)\s*$/i;
	$cookies[0] = $1;
        $cookies[0] =~ m/^(.*?)=(.*)$/;
	$totalcookies{$1} = $2;
	}

    return joincookiesinhash(%totalcookies);
}
##############################################################################

=head2 $cookies = &joincookies($cookies,$newcookies)

   Example:

   $cookies = joincookies("C=1; D=2","D=3; F=2");
   print "$cookies\n";

   Output:

   C=1; D=3; F=2

=cut  

sub joincookies {
    my($cookies,$newcookies) = @_;

    my(@cookies)=split(/;/,$cookies);
    my(@newcookies)=split(/;/,$newcookies);

    my %totalcookies = ();

    foreach (@cookies)
	{
        # Removing spaces from begin/end of string.
	$_ =~ /^\s*(.*?)\s*$/i;
	$_ = $1;
        my @pairs = split(/=/,$_);
        $totalcookies{$pairs[0]} = $pairs[1];
	}

    foreach (@newcookies)
	{
        # Removing spaces from begin/end of string.
	$_ =~ /^\s*(.*?)\s*$/i;
	$_ = $1;
        my @pairs = split(/=/,$_);
        $totalcookies{$pairs[0]} = $pairs[1];
	}
    return joincookiesinhash(%totalcookies);
}
##############################################################################

=head2 $cookies = &joincookiesinhash(%cookies)

   Example:

   %cookies = (D => 1,
               F => 2);
  
   $cookies = &joincookiesinhash(%cookies);
   print "$cookies\n";

   Output:

   D=1; F=2

=cut  

sub joincookiesinhash {
    my(%totalcookies) = @_;

    my $totalcookies = undef;
    my $cookiescount = 0;

    foreach (keys %totalcookies)
	{
	$cookiescount++;
	}

    if($cookiescount>=1)
	{
    	foreach (keys %totalcookies)
		{
		$totalcookies = "$_=$totalcookies{$_}";
		delete($totalcookies{$_});
		last;
		}
	}
    if($cookiescount>1)
	{
    	foreach (keys %totalcookies)
		{
		$totalcookies = $totalcookies . "; $_=$totalcookies{$_}";
		}
	}
    return $totalcookies;
}
##############################################################################

=head2 $rndstring = &GenerateRandomString($number);

 Description:

 This function returns string with $number random chars.
 
=cut  

sub GenerateRandomString {
    my($num)= @_ ;
 
    my $outstring ='';
    my $y;
    for($y=0;$y<$num;$y++)
	{
	my $rndnum  = int rand($#rndletters);
	my $letter  = $rndletters[$rndnum];
	$outstring = "$outstring$letter";
	}
   return $outstring; 
}
##############################################################################

=head2 $rndstring = &SelectRandomStringFromFile($file);

 Description:

 This function returns random string selected from text file $text.
 Returns undef if no selection available.
 
=cut  

sub SelectRandomStringFromFile {
    local($_) = shift;
    
    my(@strings);

    if(!open(FILE,$_)) { return undef; }
    @strings = <FILE>;
    close(FILE);

    $_ = $strings[int(rand(@strings))];
    $_ = &Delete_CRLF_from_End_Of_String($_);
    
    return $_;
}
##############################################################################

=head2 &CreateAndSendOutHtmlPage($a,$type);

 Description:

 This function will create HTML page, print it to stdout and exit.
 $type may be:
 1 - CreateAndSendOutHtmlPage() will execute script in
     $a path, print it output to stdout and exit.
 2 - CreateAndSendOutHtmlPage() will read file $a,
     print it contents to stdout and exit.
 3 - CreateAndSendOutHtmlPage() will print string
     "Location: $a\n\n" to stdout and exit.

 Examples:
 CreateAndSendOutHtmlPage("/path/index.cgi",1);
 CreateAndSendOutHtmlPage("/path/index.html",2);
 CreateAndSendOutHtmlPage("http://www.tapor.com",3);
 
=cut  

sub CreateAndSendOutHtmlPage {
    my($a,$type)= @_ ;

    my $output;
    
    if($type == 1)
	{
	$output = `$a`;
	print $output;
	exit;
	}

    my @body;

    if($type == 2)
	{
	if(open(FILE,$a))
	    {
	    @body = <FILE>;
	    close(FILE);
	    }
    
	print "Content-type: text/html\n\n";
	print @body;
	exit;
	}

    if($type == 3)
	{
	print "Location: http://$a\n\n";
	exit;
	}
	
}
##############################################################################

=head2 &CheckForDomain($domain);

 Description:
 
 This function does very simple task, it compare $domain with $ENV{'HTTP_HOST'}.
 If equal function returns TRUE otherwise it returns FALSE.

=cut  
 
sub CheckForDomain {
    my($domain)= @_;
    
    if($domain ne $ENV{'HTTP_HOST'}) {return 0;}

    return 1;
}
###############################################################################

=head2 &SendToDomainIfNotThisDomain($domain);

 Description:

 This function resend Web user to new location if domain not $domain.
 See previous function description.

=cut  

sub SendToDomainIfNotThisDomain {
    my($domain)= @_;

    if(!&CheckForDomain($domain))
	{
	print "Location: http://$domain\n\n";
	exit;
	}
}
###############################################################################

=head2 $string = &MassiveToString(@massive);

 Description:
 
 This function does very simple task, it convert massive @massive to string
 $string.

=cut  

sub MassiveToString {
	my(@body) = @_;
	my($commonline);
	
	foreach (@body) { $commonline = $commonline . $_; }
	return $commonline; 
}
###############################################################################

=head2 %out = &newsocketto(*S,$host,$port,$timeoutconnect);

 Description:

 This function returns connected socket to $host:$port if no error.
 $timeoutconnect is timeout to connect to $host:$port.
 
 Usage:

 %out = &newsocketto(*S,$host,$port,$timeoutconnect);
 
 Output:

 $out{'error'} == 0 - No errors
 $out{'error'} == 1 - Some Error.
 $out{'errortxt'}   - Error description if $out{'error'} == 1
 S - connected socket to $host:$port.

=cut  

sub newsocketto {
    local(*S) = shift;
    my($host,$port,$timeout) = @_;
    my($ok,$result);
    
    my(%out);
    $out{'error'} = 1;
    
    local($SIG{ALRM});
    
    if ($^O ne 'MSWin32') 
	{
	$SIG{ALRM} = sub { $out{'errortxt'} = create_error_string("TAPORlib::newsocketto()","Error connecting to $host:$port after $timeout seconds"); die;} if $timeout;
	}

    $result = eval {
    if ($^O ne 'MSWin32') {alarm($timeout) if ($timeout);}

    my $iaddr;
    if(!($iaddr=inet_aton($host)))
	{
        $out{'errortxt'} = create_error_string("TAPORlib::newsocketto()","Error resolving '$host'");
        if ($^O ne 'MSWin32') {alarm(0) if($timeout);}
	die;
	}
    my $paddr = sockaddr_in($port,$iaddr);
    if(!socket(S, AF_INET, SOCK_STREAM, 0))
	{
        $out{'errortxt'} = create_error_string("TAPORlib::newsocketto()","Error getting socket()");
        if ($^O ne 'MSWin32') {alarm(0) if($timeout);}
	die;
	}
    $ok = connect(S, $paddr);
    if(!$ok)
	{
        $out{'errortxt'} = create_error_string("TAPORlib::newsocketto()","Can't connect to '$host'");
        if ($^O ne 'MSWin32') {alarm(0) if($timeout);}
	die;
	}
    if ($^O ne 'MSWin32') {alarm(0) if($timeout);}
    1;
    };
    unless($result) {return %out;}
    $out{'error'} = 0; 
    return %out;
}
###############################################################################

=head2 &CheckProxy($proxy);

 Description:

 This function checks for proxy server.
 $proxy server must be passed in the following format:
 129.168.1.1:80
 
 Output:
 
 TRUE if proxy server is valid.
 FALSE if proxy server is invalid.

=cut  

sub CheckProxy {
    my($proxy,$logfile) = @_;    
    my(%pagenow,%out);

    $pagenow{'method'}  = "GET";
    $pagenow{'url'}     = "http://www.yahoo.com";
    $pagenow{'proxy'}   = $proxy;
    $pagenow{'logfile'} = $logfile ? $logfile : "/dev/null";
    
    $pagenow{'timeoutconnect'} = 5;
    $pagenow{'timeoutrequest'} = 30;
    
    my @body;
    
    %out = GetPageNow_4(%pagenow);
    if($out{'error'}) { return 0; }    
    
    @body = $out{'body'};
    
    foreach (@body) { if(/Yahoo!/i) { return 1; } }
    
    return 1;
}
##############################################################################

=head2 $text_t=&win2koi($text) and $text_t=&koi2win($text)

 Description:
 
 Functions does Win -> Koi and Koi -> Win translation.

=cut  
 
sub win2koi() 
    { 
    local($_) = shift; 
    tr /¿áâ÷çäåöúéêëìíîïðòóôõæèãþûýÿùøüàñÁÂ×ÇÄÅÖÚÉÊËÌÍÎÏÐÒÓÔÕÆÈÃÞÛÝßÙØÜÀÑ/¿Â×ÞÚÄÅÃßÊËÌÍÎÏÐÒÔÕÆÈÖÉÇÀÙÜÑÝÛØÁÓâ÷þúäåãÿêëìíîïðòôõæèöéçàùüñýûøáó/; 
    return $_; 
    } 
sub koi2win() 
    { 
    local($_) = shift; 
    tr /¿Â×ÞÚÄÅÃßÊËÌÍÎÏÐÒÔÕÆÈÖÉÇÀÙÜÑÝÛØÁÓâ÷þúäåãÿêëìíîïðòôõæèöéçàùüñýûøáó/¿áâ÷çäåöúéêëìíîïðòóôõæèãþûýÿùøüàñÁÂ×ÇÄÅÖÚÉÊËÌÍÎÏÐÒÓÔÕÆÈÃÞÛÝßÙØÜÀÑ/;
    return $_; 
    } 

##############################################################################

=head2 $scriptname = &GetScriptName();

 Description:
 
 Function returns current script name.

=cut  

sub GetScriptName {

    if(isrunninglocaly()) { $_ = $ENV{'_'}; }
    else { $_ = $ENV{'SCRIPT_FILENAME'}; }	
	
    /([^\r\n]*\/)([^\/]*)/;
    $_ = $2;
    
    return $_;
}
###############################################################################

=head2 &SetScriptDirAsCurrent();

 Description:
 
 Function sets current directory to script directory.

=cut  

sub SetScriptDirAsCurrent {

    if(isrunninglocaly()) { $_ = $ENV{'_'}; }
    else { $_ = $ENV{'SCRIPT_FILENAME'}; }	
	
    $_ =~ m/([^\r\n]*\/)[^\/]*/;
    $_ = $1;
    
    chdir($_);
}
###############################################################################

=head2 &send_null_image();

 Description:
 
 Sends NULL GIF image to client browser and exit.

=cut  

sub send_null_image {

print "Content-type: image/gif\n";
print "Content-Length: 43\n\n";

print "GIF89a\x01\0\x01\0\x80\0\0\0\0\0\xff\xff\xff\x21\xf9\x04\x01\0\0\0\0\x2c\0\0\0\0\x01\0\x01\0\x40\x02\x02\x44\x01\0\x3b";
exit;
}
##############################################################################

=head2 &IsDateValid($day,$month,$year);

 Description:

 If date invalid function returns FALSE, otherwise TRUE.

=cut  

sub IsDateValid {
    my($day,$month,$year) = @_;

    my %daysinmonth   = (
	1  => 31,
        2  => 28,
        3  => 31,
        4  => 30,
        5  => 31,
        6  => 30,
	7  => 31,
        8  => 31,
        9  => 30,
        10  => 31,
        11  => 30,
        12  => 31,
	);
    
    if($month < 1 || $month >12) { return 0;}

    if(int($year/4)*4 == $year) {$daysinmonth{'2'} = 29;}
    if(int($year/100)*100 == $year) {$daysinmonth{'2'} = 28;}
    if($day < 1 || $day > $daysinmonth{$month}) { return 0;}
    
    return 1;
}    
###############################################################################

=head2 %Config = &parse_form_2();

 Description:

 Parse forms content and returns it as hash %Config.

=cut  

sub parse_form_2 {

    my($method) = defined($ENV{'REQUEST_METHOD'}) ? $ENV{'REQUEST_METHOD'} : 'LOCAL';
    
    my(@pairs,$buffer,%Config);
    
    if ($method eq 'GET') {
        @pairs = split(/&/, $ENV{'QUERY_STRING'});
    }
    elsif ($method eq 'POST') {
        read(STDIN, $buffer, $ENV{'CONTENT_LENGTH'});
        @pairs = split(/&/, $buffer);
    }
    else 
	{ @pairs = @ARGV; }

    foreach my $pair (@pairs) {

        my($name, $value) = split(/=/, $pair);

        $name =~ s/\+/ /g;
        $name =~ s/%([a-fA-F0-9][a-fA-F0-9])/pack("C", hex($1))/eg;

        $value =~ s/\+/ /g;
        $value =~ s/%([a-fA-F0-9][a-fA-F0-9])/pack("C", hex($1))/eg;
        $value =~ s/<!--(.|\n)*-->//g;

        $Config{$name} = $value;
        }

    return %Config;
}
##############################################################################

=head2 $date = &GetDate_2();

 Description:

 Returns $date in string format.
 For Russian users also GetDateRus_2() function available.

=cut  

sub GetDate_2 {
    my($timemodifier) = @_;

if(!$timemodifier) {$timemodifier = 0;}

my ($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst)=localtime(time + $timemodifier*3600);

if (length ($min) eq 1) {$min= '0'.$min;}

$mon ++;
$year = $year + 1900;

my $date = "$mon/$mday/$year, $hour:$min:$sec";
my $daterus = "$mday/$mon/$year, $hour:$min:$sec";

    return ($daterus,$date);
}
sub GetDateRus_2 {
    my($timemodifier) = @_;
    
    return (GetDate_2($timemodifier))[0];
}
##############################################################################

=head2 $flag = &SendEmailMsg($from,$email,$msg);

 Example:
 
 $flag = &SendEmailMsg("from@tapor.com","to@tapor.com","test message");
 if(!$flag)
    {
    print "Can't e-mail to to@tapor.com :(\n";
    }

=cut  

sub SendEmailMsg {
    my($from,$email,$msg) = @_;

my($mailprog) = "/usr/sbin/sendmail";

my $date = &GetDate_2;

if(open(MAIL,"|$mailprog -t"))
    {
    print MAIL "To: <$email>\n";
    print MAIL "From: $from <$email>\n";
    print MAIL "Subject: $date\n\n";

    print MAIL "$msg\n";
    close (MAIL);
    return 1;
    }
return 0;
}
###############################################################################

=head2 $flag = &SendEmailMultiMsg($from,$email,@msg);

 Example:
 
 $flag = &SendEmailMultiMsg("from@tapor.com","to@tapor.com",("test message","2 line"));
 if(!$flag)
    {
    print "Can't e-mail to to@tapor.com :(\n";
    }

=cut  

sub SendEmailMultiMsg {
    my($from,$email,@msg) = @_;

my($mailprog) = "/usr/sbin/sendmail";

my $date = &GetDate_2;

if(open(MAIL,"|$mailprog -t"))
    {
    print MAIL "To: <$email>\n";
    print MAIL "From: $from <$email>\n";
    print MAIL "Subject: $date\n\n";

    foreach my $line (@msg)
	{
	$line = Delete_CRLF_from_End_Of_String($line);
        print MAIL "$line\n";
	}
	
    close (MAIL);
    return 1;
    }
return 0;
}
###############################################################################
sub create_error_string {
    my ($who,$error,$end) = @_;

    return "$who error - \"$error\"" . $end;    
}
###############################################################################

=head2 @cuttedmsv = &LimitMassive(10,@msv);

 Description:

 Function will cut massive @msv to size 10. 

=cut  

sub LimitMassive {
    my($limit,@msv) = @_;

    if(($#msv+1)>$limit) { $#msv = ($limit - 1); };
    return @msv;
}
###############################################################################

=head2 @tops = &GetTops(@msv);

 Example:
 
 @msv = qw(test
           test
	   test
	   test2
	   test2
	   );
 @tops = &GetTops(@msv); 

 Output:
 
 @tops = ("test - 3","test2 - 2"); 

=cut  

sub GetTops {
    my(@Keys) = @_;

    my(%Tops,@Tops);
    
    foreach (@Keys)
	{
	if(!$_) {next;}
	
	if($Tops{$_})  {  $Tops{$_}++;  }
	else { $Tops{$_} = 1; }
	}

    foreach (keys %Tops) { $Tops{$_} = "$Tops{$_}:$_"; }

    %Tops = reverse %Tops;

    foreach (sort {$a <=> $b} keys %Tops)
	{
	$_ =~ m/([0-9]+):(.*)/;
	push(@Tops,"$Tops{$_} - $1");
	}
    
    return reverse @Tops;
}
###############################################################################

=head2 &IsSearchEngine("./robots");

 Description:
 
 Function will test visitor of your page. 
 It will return Search Engine Name if visitor is Serch Engine.
 It will return FALSE if visitor is surfer.
 The "./robots" is directory. See "./txt/robots" in the package.
 
=cut  

sub IsSearchEngine {
    my($enginelistdir) = (@_);

#------------------------------------------------------------------------------
my $gethost    = $ENV{'REMOTE_HOST'};
my $getaddr    = $ENV{'REMOTE_ADDR'};
my $getagent   = $ENV{'HTTP_USER_AGENT'};
my $getreferer = $ENV{'HTTP_REFERER'};

if(!$gethost) { $gethost = $getaddr; }

my @exclude = ("204.123.9.65",  # @exclude is for certain applications
             "204.123.9.66",    # sponsored by search engines such
             "204.123.9.67",    # as Babelfish that translate pages into
             "204.123.9.68",    # other languages and display them. You
             "204.123.9.106",   # don't want humans seeing this, so I
             "204.123.9.107",   # made an exclude list.
             "204.152.191.27",
             "204.152.191.28",
             "204.152.191.29",
             "204.152.190.27",
             "204.152.190.28",
             "204.152.190.29",
             "204.152.190.37",
             "204.152.190.154",
             "204.162.96.104",
             "204.162.96.154",
             "204.162.96.176",
             "209.247.194.100",);

#------------------------------------------------------------------------------
my $count;
my (@enginelist1,@enginelist2,@enginelist3,@enginelist4,@enginelist5);
my (@enginelist6,@enginelist7,@enginelist8,@enginelist9);

#------------------------------------------------------------------------------
# Openning
for ($count=1; $count<=9; $count++)
    {
    open (ENGINELIST, "$enginelistdir/$count" . ".list");
    flock(ENGINELIST, 2);
    @enginelist1 =<ENGINELIST> if $count eq 1;
    @enginelist2 =<ENGINELIST> if $count eq 2;
    @enginelist3 =<ENGINELIST> if $count eq 3;
    @enginelist4 =<ENGINELIST> if $count eq 4;
    @enginelist5 =<ENGINELIST> if $count eq 5;
    @enginelist6 =<ENGINELIST> if $count eq 6;
    @enginelist7 =<ENGINELIST> if $count eq 7;
    @enginelist8 =<ENGINELIST> if $count eq 8;
    @enginelist9 =<ENGINELIST> if $count eq 9;
    flock(ENGINELIST, 8);
    close (ENGINELIST);
    }

#------------------------------------------------------------------------------
# Checking
my @list;
my ($robotname,$isRobot);

for ($count=1;$count<=9;$count++)
    {
    @list = @enginelist1 if $count eq 1;   # Infoseek
    @list = @enginelist2 if $count eq 2;   # Alta Vista
    @list = @enginelist3 if $count eq 3;   # Lycos
    @list = @enginelist4 if $count eq 4;   # Inktomi
    @list = @enginelist5 if $count eq 5;   # Excite
    @list = @enginelist6 if $count eq 6;   # Google
    @list = @enginelist7 if $count eq 7;   # Northern Light
    @list = @enginelist8 if $count eq 8;   # Misc
    @list = @enginelist9 if $count eq 9;   # Custom 1

    $robotname = undef;
    foreach my $line (@list) 
	{
        chomp $line;
        $line =~ s/ //g;
        next if (!$line);
        if($line =~ /^\#/)
	    {
	    $robotname = $line;
	    next;
	    }
        if (($gethost =~ /$line/i) || ($getaddr =~ /$line/i)) 
	    {
    	    $isRobot = $count;
            if ($gethost =~ /babelfish/i) { $isRobot = 0; }
            foreach my $ip (@exclude) 
		    {
                    if ($getaddr =~ /$ip/i) { $isRobot = 0; }
            	    }
            }
        last if $isRobot eq $count;
        }
    last if $isRobot eq $count;
    }

if($isRobot) { return $robotname; }

#------------------------------------------------------------------------------
my @ROBOTS;

open (FILE,"$enginelistdir/robots.txt");
@ROBOTS=<FILE>;
close FILE;
chomp (@ROBOTS);

foreach (@ROBOTS) 
    {
    my ($robotname,$AGENT,$IP)=split(/\|/,$_);
    if ($ENV{'REMOTE_ADDR'} =~ /$IP/i) { return $robotname; }
    }
#------------------------------------------------------------------------------
my @useragents = ("Mozilla/",
	          "Opera/",
	          "Lynx/");

foreach (@useragents)
    {
    if($getagent =~ m/^$_/i) { return undef; }
    }
return "UnknownRobot";
}
###############################################################################

=head2 $os = &DetectOperationSystem($ENV{'HTTP_USER_AGENT'});

 Description:
 
 Function returns operation system which visitor is uses.
 
=cut  

sub DetectOperationSystem {
    my($agent) = @_;

    foreach (keys %operation_systems)
	{
	if($agent =~ m/$_/) { return $operation_systems{$_}; }
	}
    return "UNKNOWN";
}
##############################################################################

=head2 &IsAllreadyRunning($numstarts); / &IsAllreadyRunning_2($numstarts); 

 Description:

 Functions checks if script allready executed.
 If script allready executed functions returns TRUE, otherwise FALSE.
 $numstarts defines what maximum executions are allowed.
 We recomend you to use IsAllreadyRunning_2() function.
 
=cut  

sub IsAllreadyRunning {
    my($numstarts,$LISTEN_PORT) = @_;

    my($file) = "__listenport.txt";
    
    unless (-e $file) 
	{
	if(!$LISTEN_PORT)
	    {
	    $LISTEN_PORT = int rand(500);
	    $LISTEN_PORT = $LISTEN_PORT + 21600;
	    }
	open(FILE,">$file");
	print FILE $LISTEN_PORT;
	close(FILE);
	}
    open(FILE,$file);
    $LISTEN_PORT = <FILE>;
    chomp($LISTEN_PORT);
    close(FILE);
    
    socket(SE, PF_INET, SOCK_STREAM, 'udp');
    setsockopt(SE, SOL_SOCKET, SO_REUSEADDR, 1);
    
    my $x;
    
    for($x=0;$x<$numstarts;$x++,$LISTEN_PORT++)
	{
        bind(SE, sockaddr_in($LISTEN_PORT, INADDR_ANY)) or next;
        return 0;
	}
    return 1;
}

sub IsAllreadyRunning_2 {
    my($numstarts,$savefilesto) = @_;

    if(!defined($savefilesto)) {$savefilesto = "./";}

    my($lockfile) = "__lock";
    my($x,$flockret,$commonret);
    
    if($numstarts <= 0) {return 1;}
    
    $commonret = 1;
    for($x=1;$x<=$numstarts;$x++)
	{
        if(!open(LOCKING_FILE_SPEC,">$savefilesto/" . $lockfile . "_" . $x)) {next;}
        $flockret = flock(LOCKING_FILE_SPEC,2 + 4);

	if($flockret)
	    {
	    $commonret = 0;
	    last;
	    }
	}
    return $commonret;
}	
##############################################################################
sub change_spec_labels {
    my($ll)= @_ ;

my @envkeys = qw (
    HTTP_USER_AGENT
    HTTP_REFERER
    SERVER_SOFTWARE
    SERVER_NAME
    GATEWAY_INTERFACE
    SERVER_NAME
    SERVER_PROTOCOL
    SERVER_PORT
    REQUEST_METHOD
    HTTP_ACCEPT
    PATH_INFO
    PATH_TRANSLATED
    SCRIPT_NAME
    QUERY_STRING
    REMOTE_HOST
    REMOTE_ADDR
    REMOTE_USER
    AUTH_TYPE
    CONTENT_TYPE
    CONTENT_LENGTH
    HTTP_FROM
    REMOTE_IDENT
    );

    my $serverport = defined($ENV{'SERVER_PORT'}) ? $ENV{'SERVER_PORT'} : undef;
    my $portst  = $serverport==80  ?  ''   :  ':' . $serverport;
    
    my $thisurl = join('','http://',defined($ENV{'SERVER_NAME'}) ? $ENV{'SERVER_NAME'} : '',$portst,defined($ENV{'SCRIPT_NAME'}) ? $ENV{'SCRIPT_NAME'} : '');
    $thisurl =~ m|^([^\s\?]+)(/{1}?)|i;
    my $thisshorturl = $1;
    
    $ll =~ s|###RANDOM:([0-9]+)-([0-9]+)###|$1+(int rand($2-$1+1))|igme;
    $ll =~ s|###THISURL###|defined($thisurl) ? $thisurl : ''|igse;
    $ll =~ s|###THISURL_WITHOUT_SCRIPT_NAME###|defined($thisshorturl) ? $thisshorturl : ''|igse;

    foreach (@envkeys)
	{
        $ll =~ s|###ENV_$_###|defined($ENV{$_}) ? $ENV{$_} : ''|gise;
	}

    return $ll;
}
##############################################################################
sub ViewSpecHtmFile {
	my($htmfile) = @_;

open(FILE,"$htmfile") || &HTMLdie("ViewSpecHtmFile: Can't open file: '$htmfile'");
my @htmfile = <FILE>;
close(FILE);

my $commonline_htm = MassiveToString(@htmfile);
$commonline_htm = &change_spec_labels($commonline_htm);

print "Content-type: text/html\n\n";
print "$commonline_htm";

exit;
}
###############################################################################

=head2 ($proxyaddr,$proxyport) = &SelectRandomProxyServerFromFile($proxy);

 Description:

 This function returns random proxy server selected from file $proxy.
 
=cut  

sub SelectRandomProxyServerFromFile {
    my($proxyfile) = @_;

my $hostport = &SelectRandomStringFromFile($proxyfile);
if(!$hostport) { return (undef,undef); }
$hostport = Delete_CRLF_from_End_Of_String($hostport);
$hostport =~ s/ //g;

my (@pairs,$proxyaddr,$proxyport);

@pairs = split(/:/,$hostport);

    return ($pairs[0],$pairs[1]);
}
###############################################################################
sub CorrectLinksOnPage {
	my($string,$url) = @_;
	
	if(!$string || !$url) { return undef;};

	my ($baseurl,$relurl,$relurl2) = GetRelativeUrls($url);

	my @body = split(/>/,$string);
	
	foreach (@body) {

	if((/<\s*form\b/im) && !(/\baction\s*=/im) && !(/\bscript\s*=/im))
		{
		s|<\s*form\b|<form action="$url"|im;
		}

	# Put the most common cases first

        s/(<[^>]*\bhref\s*=\s*["']?)([^\s"'>]*)/       $1 . &full_url($2,$url) /ime,
            next if /<\s*a\b/im;

        s/(<[^>]*\bsrc\s*=\s*["']?)([^\s"'>]*)/        $1 . &full_url($2,$url) /ime,
        s/(<[^>]*\blowsrc\s*=\s*["']?)([^\s"'>]*)/     $1 . &full_url($2,$url) /ime,
        s/(<[^>]*\blongdesc\s*=\s*["']?)([^\s"'>]*)/   $1 . &full_url($2,$url) /ime,
        s/(<[^>]*\busemap\s*=\s*["']?)([^\s"'>]*)/     $1 . &full_url($2,$url) /ime,
        s/(<[^>]*\bdynsrc\s*=\s*["']?)([^\s"'>]*)/     $1 . &full_url($2,$url) /ime,
            next if /<\s*img\b/im;

        s/(<[^>]*\bbackground\s*=\s*["']?)([^\s"'>]*)/ $1 . &full_url($2,$url) /ime,
            next if /<\s*body\b/im;

        s/(<[^>]*\bhref\s*=\s*["']?)([^\s"'>]*)/       $1 . &GetRelativeUrls(&full_url($2,$url)) /ime,
            next if /<\s*base\b/im ;     # has special significance

        s/(<[^>]*\bsrc\s*=\s*["']?)([^\s"'>]*)/        $1 . &full_url($2,$url) /ime,
        s/(<[^>]*\blongdesc\s*=\s*["']?)([^\s"'>]*)/   $1 . &full_url($2,$url) /ime,
            next if /<\s*frame\b/im ;

        s/(<[^>]*\baction\s*=\s*["']?)([^\s"'>]*)/     $1 . &full_url($2,$url) /ime,
        s/(<[^>]*\bscript\s*=\s*["']?)([^\s"'>]*)/     $1 . &full_url($2,$url) /ime,
            next if /<\s*form\b/im ;     # needs special attention

        s/(<[^>]*\bsrc\s*=\s*["']?)([^\s"'>]*)/        $1 . &full_url($2,$url) /ime,
        s/(<[^>]*\busemap\s*=\s*["']?)([^\s"'>]*)/     $1 . &full_url($2,$url) /ime,
            next if /<\s*input\b/im ;

        s/(<[^>]*\bhref\s*=\s*["']?)([^\s"'>]*)/       $1 . &full_url($2,$url) /ime,
            next if /<\s*area\b/im ;

        s/(<[^>]*\bcodebase\s*=\s*["']?)([^\s"'>]*)/   $1 . &full_url($2,$url) /ime,
        s/(<[^>]*\bcode\s*=\s*["']?)([^\s"'>]*)/       $1 . &full_url($2,$url) /ime,
        s/(<[^>]*\bobject\s*=\s*["']?)([^\s"'>]*)/     $1 . &full_url($2,$url) /ime,
        s/(<[^>]*\barchive\s*=\s*["']?)([^\s"'>]*)/    $1 . &full_url($2,$url) /ime,
            next if /<\s*applet\b/im ;


        # These are seldom-used tags, or tags that seldom have URLs in them

        s/(<[^>]*\bsrc\s*=\s*["']?)([^\s"'>]*)/        $1 . &full_url($2,$url) /ime,
            next if /<\s*bgsound\b/im ;  # Microsoft only

        s/(<[^>]*\bcite\s*=\s*["']?)([^\s"'>]*)/       $1 . &full_url($2,$url) /ime,
            next if /<\s*blockquote\b/im ;

        s/(<[^>]*\bcite\s*=\s*["']?)([^\s"'>]*)/       $1 . &full_url($2,$url) /ime,
            next if /<\s*del\b/im ;

        s/(<[^>]*\bsrc\s*=\s*["']?)([^\s"'>]*)/        $1 . &full_url($2,$url) /ime,
            next if /<\s*embed\b/im ;    # Netscape only

        s/(<[^>]*\bsrc\s*=\s*["']?)([^\s"'>]*)/        $1 . &full_url($2,$url) /ime,
        s/(<[^>]*\bimagemap\s*=\s*["']?)([^\s"'>]*)/   $1 . &full_url($2,$url) /ime,
            next if /<\s*fig\b/im ;      # HTML 3.0

        s/(<[^>]*\bsrc\s*=\s*["']?)([^\s"'>]*)/        $1 . &full_url($2,$url) /ime,
            next if /<\s*h[1-6]\b/im ;   # HTML 3.0

        s/(<[^>]*\bprofile\s*=\s*["']?)([^\s"'>]*)/    $1 . &full_url($2,$url) /ime,
            next if /<\s*head\b/im ;

        s/(<[^>]*\bsrc\s*=\s*["']?)([^\s"'>]*)/        $1 . &full_url($2,$url) /ime,
            next if /<\s*hr\b/im ;       # HTML 3.0

        s/(<[^>]*\bsrc\s*=\s*["']?)([^\s"'>]*)/        $1 . &full_url($2,$url) /ime,
        s/(<[^>]*\blongdesc\s*=\s*["']?)([^\s"'>]*)/   $1 . &full_url($2,$url) /ime,
            next if /<\s*iframe\b/im ;

        s/(<[^>]*\bcite\s*=\s*["']?)([^\s"'>]*)/       $1 . &full_url($2,$url) /ime,
            next if /<\s*ins\b/im ;

        s/(<[^>]*\bsrc\s*=\s*["']?)([^\s"'>]*)/        $1 . &full_url($2,$url) /ime,
            next if /<\s*layer\b/im ;

        s/(<[^>]*\bhref\s*=\s*["']?)([^\s"'>]*)/       $1 . &full_url($2,$url) /ime,
        s/(<[^>]*\burn\s*=\s*["']?)([^\s"'>]*)/        $1 . &full_url($2,$url) /ime,
            next if /<\s*link\b/im ;

        s/(<[^>]*\burl\s*=\s*["']?)([^\s"'>]*)/        $1 . &full_url($2,$url) /ime,
            next if /<\s*meta\b/im ;     # Netscape only

        s/(<[^>]*\bsrc\s*=\s*["']?)([^\s"'>]*)/        $1 . &full_url($2,$url) /ime,
            next if /<\s*note\b/im ;     # HTML 3.0

        s/(<[^>]*\busemap\s*=\s*["']?)([^\s"'>]*)/     $1 . &full_url($2,$url) /ime,
        s/(<[^>]*\bcodebase\s*=\s*["']?)([^\s"'>]*)/   $1 . &full_url($2,$url) /ime,
        s/(<[^>]*\bdata\s*=\s*["']?)([^\s"'>]*)/       $1 . &full_url($2,$url) /ime,
        s/(<[^>]*\barchive\s*=\s*["']?)([^\s"'>]*)/    $1 . &full_url($2,$url) /ime,
        s/(<[^>]*\bclassid\s*=\s*["']?)([^\s"'>]*)/    $1 . &full_url($2,$url) /ime,
        s/(<[^>]*\bname\s*=\s*["']?)([^\s"'>]*)/       $1 . &full_url($2,$url) /ime,
            next if /<\s*object\b/im ;

        s/(<[^>]*\bsrc\s*=\s*["']?)([^\s"'>]*)/        $1 . &full_url($2,$url) /ime,
        s/(<[^>]*\bimagemap\s*=\s*["']?)([^\s"'>]*)/   $1 . &full_url($2,$url) /ime,
            next if /<\s*overlay\b/im ;  # HTML 3.0

        s/(<[^>]*\bcite\s*=\s*["']?)([^\s"'>]*)/       $1 . &full_url($2,$url) /ime,
            next if /<\s*q\b/im ;

        s/(<[^>]*\bsrc\s*=\s*["']?)([^\s"'>]*)/        $1 . &full_url($2,$url) /ime,
        s/(<[^>]*\bfor\s*=\s*["']?)([^\s"'>]*)/        $1 . &full_url($2,$url) /ime,
            next if /<\s*script\b/im ;

        s/(<[^>]*\bsrc\s*=\s*["']?)([^\s"'>]*)/        $1 . &full_url($2,$url) /ime,
            next if /<\s*select\b/im ;   # HTML 3.0

        s/(<[^>]*\bsrc\s*=\s*["']?)([^\s"'>]*)/        $1 . &full_url($2,$url) /ime,
            next if /<\s*ul\b/im ;       # HTML 3.0

	}   # foreach (@body)

	my ($commonline) = undef;
	foreach (@body) {$commonline = $commonline . $_ . ">";}
	substr($commonline,-1) = "";

	return $commonline;
}
###############################################################################
sub full_url{
    	my($link,$url)= @_ ;

	my $oldlink=$link;

	my ($baseurl,$relurl,$relurl2) = GetRelativeUrls($url);

	if($link=~ m|^(http://)|i) {goto exit_full_url;}
	if($link=~ m|^(mailto:)|i) {goto exit_full_url;}
	if($link=~ m|^(javascript:)|i) {goto exit_full_url;}
	if($link=~ m|^(#)|i) {goto exit_full_url;}

	$link=~ s|^/|$baseurl/|i;
	$link=~ s|^\./|$relurl/|i;
	$link=~ s|^\.\./|$relurl2/|i;

	if(!($link=~ m|^(http://)|i)) {$link = "$relurl/$link";}

exit_full_url:

	return $link;
}
###############################################################################
sub GetRelativeUrls {
	my($url) = @_;

$url     =~ m|^(http://)([^/\?\r\n]*)|i;
my $host    = $2;

### http://adm.ict.nsc.ru/rus/docs/perl/ - http://adm.ict.nsc.ru
### http://www.irtel.ru/ - http://www.irtel.ru
### http://www.irtel.ru  - http://www.irtel.ru

my $baseurl = "http://$host";

### http://adm.ict.nsc.ru/rus/docs/perl/ - http://adm.ict.nsc.ru/rus/docs/perl
### http://www.irtel.ru/ - http://www.irtel.ru
### http://www.irtel.ru  - http://www.irtel.ru

my $relurl;

if($url     =~ m|^(http://)(.*)[/]+|i) {$relurl  = "http://$2";}
else {$relurl = $baseurl;}

### http://adm.ict.nsc.ru/rus/docs/perl/ - http://adm.ict.nsc.ru/rus/docs
### http://www.irtel.ru/ - http://www.irtel.ru
### http://www.irtel.ru  - http://www.irtel.ru

my $relurl2;

if($relurl    =~ m|^(http://)(.*)[/]+|i) {$relurl2  = "http://$2";}
else {$relurl2 = $baseurl;}

return ($baseurl,$relurl,$relurl2);
}
###############################################################################

=head1 COPYRIGHT

Copyright (c) 2000-2001 TAPOR, Inc. All rights reserved.
This program is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

http://www.tapor.com/TAPORlib/

=cut
