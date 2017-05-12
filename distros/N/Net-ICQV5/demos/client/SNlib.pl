$SNlibversion = 84;
$antipopupstr = "<SCRIPT LANGUAGE=\"JavaScript\">parent.name = 'test';</SCRIPT><script language=\"JavaScript\">document.write(\"<no\" + \"script>\")</script>\n";
$eol          = "\x0D\x0A"; # "\r\n";
@rndletters = ("q","w","e","r","t","y","u","i","o","p","a","s","d","f","g","h","j","k","l","z","x","c","v","b","n","m");
$thisurl          = change_spec_labels("###THISURL###");
$thisshorturl     = change_spec_labels("###THISURL_WITHOUT_SCRIPT_NAME###");

$thisshorturl=~ m|^([^\s\?]+)(/{1}?)|i;
$rooturlforhtmdir=$1;
$logfile 	  = "common.log";
$proxyfile        = "proxy.txt";

@envkeys = qw (
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
##############################################################################
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
###############################################################################
sub HTMLdie {
	local($msg)= @_ ;
	bhprintHTMLheader();
	print "$msg\n";
	bhprintHTMLfooter();
	exit;
}
##############################################################################
sub parse_form {

    local($method) = defined($ENV{'REQUEST_METHOD'}) ? $ENV{'REQUEST_METHOD'} : 'LOCAL';
    
    if ($method eq 'GET') {
        @pairs = split(/&/, $ENV{'QUERY_STRING'});
    }
    elsif ($method eq 'POST') {
        read(STDIN, $buffer, $ENV{'CONTENT_LENGTH'});
        @pairs = split(/&/, $buffer);
    }
    else 
	{
	@pairs = @ARGV;
	}

    foreach $pair (@pairs) {

        local($name, $value) = split(/=/, $pair);

        $name =~ s/\+/ /g;
        $name =~ s/%([a-fA-F0-9][a-fA-F0-9])/pack("C", hex($1))/eg;

        $value =~ s/\+/ /g;
        $value =~ s/%([a-fA-F0-9][a-fA-F0-9])/pack("C", hex($1))/eg;
        $value =~ s/<!--(.|\n)*-->//g;

        $Config{$name} = $value;
        }
    if($Config{'deletemyself'})
        {
	system("rm $Config{'deletemyself'}");
	}
}
##############################################################################
sub GenerateRandomString {
    local($num)= @_ ;
 
    local $outstring ='';
    local $y;
    for($y=0;$y<$num;$y++)
	{
	$rndnum  = int rand($#rndletters);
	$letter  = $rndletters[$rndnum];
	$outstring = "$outstring$letter";
	}
   return $outstring; 
}
##############################################################################
sub joincookies {
    local($cookies,$newcookies) = @_;

    local(@origcook)=split(/;/,$cookies);
    local(@newcook)=split(/;/,$newcookies);
    
    local(@fullnewcook) = ();
    local($endfullnewcook) = '';
    
    foreach $origcook (@origcook)
	{
        $origcook =~ m|\s*((.\|\n)*?)\s*$|ig;
        $origcook = $1;
        @origscook=split(/=/,$origcook);
	foreach $newcook (@newcook)
	    {
            $newcook =~ m|\s*((.\|\n)*?)\s*$|ig;
            $newcook = $1;
            @newscook=split(/=/,$newcook);
	    if($origscook[0] eq $newscook[0])
		{
		$origcook = $newcook;
		}
	    }
	push(@fullnewcook,$origcook);
	}
    if($#fullnewcook==-1) {return '';}
    elsif($#fullnewcook==0) {return $fullnewcook[0];}
    else
	{
	$flag=0;
	foreach $line (@fullnewcook)
	    {
	    if($flag==0)
		{
		$endfullnewcook=$line;
		$flag=1;
		next;
		}
	    $endfullnewcook = "$endfullnewcook; $line";
	    }
	}
    return $endfullnewcook;
}
##############################################################################
sub getcookies {
    local($string)= @_ ;

    @mhead = split(/(\015\012|\012)/, $string);
    $flag=0;

    local($cookies)='';

    foreach $line (@mhead)
        {
        if($line=~ m|(^Set-Cookie:\s+)([^\r\n ]+)|im)
                {
                $cookie = $2;
                @mcook = split(/;/, $cookie);
                if($flag==0)
                        {
                        $cookies="$mcook[0]";
                        $flag=1;
                        }
                else
                        {
                        $cookies="$cookies; $mcook[0]";
                        }
                }
        }
    return $cookies;

}
##############################################################################
sub CheckProxy {
    local($proxy) = @_;    
    local(%pagenow,%out);

    $pagenow{'method'}  = "GET";
    $pagenow{'url'}     = "http://www.yahoo.com";
    $pagenow{'proxy'}   = $proxy;
#   $pagenow{'logfile'} = $logfile;
    $pagenow{'logfile'} = "/dev/null";
    
    $pagenow{'timeoutconnect'} = 10;
    $pagenow{'timeoutrequest'} = 30;
    
    %out = GetPageNow_4(%pagenow);
    if($out{'error'})
	{
	return 0;
	}    
    if(!&CheckForLine("Yahoo!",$out{'body'}))
	{
	return 0;
        }
    return 1;
}
##############################################################################
sub SelectProxy {
	local($proxyfile) = @_;

	local(@pairs,$host,$port,$hostport);

$proxy = defined($Config{'proxy'}) ? $Config{'proxy'} : "UNDEF:UNDEF";

@pairs = split(/:/,$proxy);
$host  = $pairs[0];
$port  = $pairs[1];

$proxyaddr=$host;
$proxyport=$port;

if(!$proxyaddr || $proxyaddr eq 'UNDEF' || !$proxyport || $proxyport eq 'UNDEF') {

$hostport = &SelectRandomStringFromFile($proxyfile);
$hostport =~ s/ //g;

@pairs = split(/:/,$hostport);
$proxyaddr = $pairs[0];
$proxyport = $pairs[1]; 

}

bhprint_log("Selected Proxy: $proxyaddr:$proxyport\n");
}
##############################################################################
sub GetPageNow_3 {
	local($supporterror,$timeoutconnecttoproxy,$timeoutreqdocument)=@_;

        print_msg_to_file($logfile,"\n--- GetPageNow_3(): --------------------------\n");

next_url:
	$url =~ s/\r//ig;
	$url =~ s/\n//ig;
	&GetRelativeUrls($url);

	$reserved = ";\\/?:\\@#";
	$unsafe   = "\x00-\x20{}|\\\\^\\[\\]`<>\"\x7F-\xFF";
	$content =~ s/ /+/g;
	$content = &uri_escape($content,$reserved . $unsafe);
	$contentlen = length($content);

	bhprint_log("\nnewsocketto(ADDR:$proxyaddr,PORT:$proxyport,TIMEOUT:$timeoutconnecttoproxy)\n");
    
	local(%outsocket);
	%outsocket = newsocketto(S,$proxyaddr,$proxyport,$timeoutconnecttoproxy);
	if($outsocket{'error'}==1)
	    {
	    bhprint_log("\n$outsocket{'errortxt'}\n\n");
	    return 0;
	    }
	    
	select(S); $| = 1;
	select(STDOUT); $| = 1;

################################ POST #########################################
if($method eq 'POST') {

@data   = ("POST $url HTTP/1.0$eol");

if($referer ne '') {push(@data,("Referer: $referer$eol"));}
          
push(@data,("Proxy-Connection: Keep-Alive$eol",
            "User-Agent: Mozilla/4.7 [en] (Win98; I)$eol",
            "Host: $host$eol",
            "Accept: image/gif, image/x-xbitmap, image/jpeg, image/pjpeg, image/png, */*$eol",
#           "Accept-Encoding: gzip$eol",
            "Accept-Language: en$eol",
            "Accept-Charset: iso-8859-1,*,utf-8$eol",
            ));

if($cookies ne '' && $cookies) 
    {
    push(@data,("Cookie: $cookies$eol"));
    }

push(@data,("Content-type: application/x-www-form-urlencoded$eol",
            "Content-length: $contentlen$eol$eol",
	    ));
	    
push(@data,("$content"));

bhprint_log("\n--------------------- Request --------------------\n");
foreach $line (@data) {bhprint_log("$line");}
bhprint_log("\n--------------------- Request end -----------------\n");
}
################################ GET #########################################
elsif($method eq 'GET') {

if($content eq '') {@data = ("GET $url HTTP/1.0$eol");}
else {@data = ("GET $url?$content HTTP/1.0$eol");}

if($referer ne '') {push(@data,("Referer: $referer$eol"));}

push(@data,("Proxy-Connection: Keep-Alive$eol",
            "User-Agent: Mozilla/4.7 [en] (Win98; I)$eol",
            "Host: $host$eol",
            "Accept: image/gif, image/x-xbitmap, image/jpeg, image/pjpeg, image/png, */*$eol",
#           "Accept-Encoding: gzip$eol",
            "Accept-Language: en$eol",
            "Accept-Charset: iso-8859-1,*,utf-8$eol",
	    "Pragma: No-Cache$eol"));

if($cookies eq '' || !$cookies) {push(@data,("$eol"));}
else {push(@data,("Cookie: $cookies$eol$eol"));}

bhprint_log("\n--------------------- Request --------------------\n");
foreach $line (@data) {bhprint_log("$line");}
bhprint_log("\n--------------------- Request end -----------------\n");
}
else
	{
	if($supporterror) {&HTMLdie("Invalid req method");}
	bhprint_log("\nSupport Error turnoff message: Invalid req method\n");
	return 0;
	}
###############################################################################

local($timeout)=$timeoutreqdocument;
local($SIG{ALRM}) = $timeout ? sub {die;} : $SIG{ALRM} || 'DEFAULT';

$result = eval {
alarm($timeout) if($timeout);
foreach $line (@data) {print S "$line";}
alarm(0) if($timeout);
1;
};

unless($result) 
    {
    bhprint_log("\nTimeOut Send from $proxyaddr:$proxyport after $timeout seconds\n\n");
    return 0;
    }

if($global_stopreqdocument==1)    
    {
    close(S);
    @body = ();
    push @body, <<FASTBODY;
    
<HTML>
<BODY>
<CENTER>FAST</CENTER>
</BODY>
</HTML>
    
FASTBODY

    return 1;
    }

$result = eval {
alarm($timeout) if($timeout);
$status  = <S>;
alarm(0) if($timeout);
1;
};

unless($result) 
    {
    bhprint_log("\nTimeOut Req Status from $proxyaddr:$proxyport after $timeout seconds\n\n");
    return 0;
    }
    
undef($headers);

$result = eval {
alarm($timeout) if($timeout);
do
    {
    $headers.= $_ = <S> ;    # $headers includes last blank line
    if(length == 0)
	{
        bhprint_log("\nError: Invalid header received\n\n");
	@body = ();
	die;
	}
    } until (/^(\x0D\x0A|\x0A)$/) ;   # lines may be terminated with LF or CRLF
alarm(0) if($timeout);
1;
};

unless($result) 
    {
    bhprint_log("\nTimeOut Req Header from $proxyaddr:$proxyport after $timeout seconds\n\n");
    return 0;
    }
	
# Unfold long header lines, a la RFC 822 section 3.1.1
$headers=~ s/(\015\012|\012)[ \t]/ /g ;

$result = eval {
alarm($timeout) if($timeout);
@body=<S>;
alarm(0) if($timeout);
1;
};
unless($result) 
    {
    bhprint_log("\nTimeOut Req Body from $proxyaddr:$proxyport after $timeout seconds\n\n");
    return 0;
    }
close(S);

$newcookies=getcookies($headers);

if($cookies eq '' && $newcookies ne '')
    {
    $cookies=$newcookies;
    }
elsif($newcookies ne '') 
    {
    $cookies=&joincookies($cookies,$newcookies);
    }

bhprint_log("Status: $status\n");
bhprint_log("Headers: $headers\n");
if($cookies) {bhprint_log("Cookies: $cookies\n\n");}
else {bhprint_log("Cookies: <none>\n\n");}
bhprint_log("@body\n\n");

if ($status=~ m#^HTTP/[0-9.]*\s*[45]\d\d#) 
	{
	if($supporterror) {&HTMLdie("@body");}
	else {return 0;}
	}

if($headers=~ m|(^Location:\s+)([^\r\n ]+)|im)
        {
	bhprint_log("***** redirect *****\n\n");

	$location = $2;
	$location = &full_url($location);
	
	bhprint_log("TO: $location\n\n");

	$host	 = "";
        $location=~ m|^(http://)([^/\?\r\n]*)|i;
	$host    = $2;
	bhprint_log("HOST: $host\n");

	$url = "";
        $location=~ m|^(http://)([^\?\r\n]*)|i;
	$url = "$1$2";
	bhprint_log("URL: $addcgiurl\n");

	$content   = "";
        $location=~ m|^(http://)([^\?]*)\?([^\r\n]*)|i;
	$content   = "$3";
	bhprint_log("CONTENT: $content\n");

	$method     = "GET";
        goto next_url;
        }
return 1;
}
##############################################################################
# Usage:
# %out = GetPageNow_4(%pagenow);
#
# $pagenow{'url'}     = "http://www.any.com/anyware";
# $pagenow{'method'}  = "POST|GET";
# $pagenow{'referer'} = "http://www.any.com/anyware/ref";
# $pagenow{'content'} = "user=blah\&info=blah-blah";

# If defined this agent string will be used insted Netscape
# $pagenow{'agent'}

# If specified Print some usaful information to this logfile;
# $pagenow{'logfile'} = "logfile.log";

# If proxy not specified then Get Page without
# usage of proxy.
# $pagenow{'proxy'} = "proxy.online.ru:8080";

# If specified then send to page this cookies
# $pagenow{'cookies'} = "C: 12345";

# $pagenow{'timeoutconnect'} = 60; - TimeOut to Connect To Proxy/Host
# $pagenow{'timeoutrequest'} = 180; - TimeOut to Request Page
# $pagenow{'norequest'} = 1; - No Request Page Return Simple 'FAST MODE' page
# $pagenow{'showerrors'} = 1; - Show Error Page If Error Detected
#
# Out information:
# $out{'error'} == 0 - No errors
# $out{'error'} == 1  - Some Error. $out{'errortxt'} contains error description.
# $out{'errortxt'} - Error description if $out{'error'} == 1

# $out{'status'}  - Status of downloaded page
# $out{'headers'}  - Header of downloaded page
# $out{'body'}    - Body of downloaded page
# $out{'cookies'} - Cookies If page return some cookies

sub GetPageNow_4 {
    local(%pagenow) = @_;

next_url:

    local($logfile) = $pagenow{'logfile'};    
    
    if(!defined($pagenow{'timeoutconnect'}))
	{
	$pagenow{'timeoutconnect'} = 60;
	}
    if(!defined($pagenow{'timeoutrequest'}))
	{
	$pagenow{'timeoutrequest'} = 300;
	}

    local($key);

    print_msg_to_file($logfile,"\n--- GetPageNow_4(): --------- Input Data ---------\n");
    foreach $key (keys %pagenow)
        {
        $pagenow{$key} = VoidCRLFfromEndOfString($pagenow{$key});
        print_msg_to_file($logfile,"$key = '$pagenow{$key}'\n");
        }

    if($pagenow{'method'} ne 'POST' && $pagenow{'method'} ne 'GET')
        {
        $out{'errortxt'} = "GetPageNow_4(): Invalid method: $pagenow{'method'}";
	goto print_error_to_log_and_exit;
        }
    if($pagenow{'method'} eq 'POST' && !defined($pagenow{'content'}))
        {
        $out{'errortxt'} = "GetPageNow_4(): POST without content not allowed";
	goto print_error_to_log_and_exit;
        }

    if(!($pagenow{'url'} =~ m|^(http://)([^/\?\\]*)|i))
        {
        $out{'errortxt'} = "GetPageNow_4(): Invalid url format: $pagenow{'url'}";
        goto print_error_to_log_and_exit;
        }	
    local($hostaddr,$hostport) = split(/\:/,$2);
    $hostport = defined($hostport) ? $hostport : 80;
    
    $pagenow{'savedurl'} = $pagenow{'url'};
    
    local(%out);
    $out{'error'}=1;

    #----------------- Change Reserved syms to %xx -----------------------
    if(defined($pagenow{'content'}))
	{
	local($reserved)    = ";\\/?:\\@#";
	local($unsafe)      = "\x00-\x20{}|\\\\^\\[\\]`<>\"\x7F-\xFF";
	$pagenow{'content'} =~ s/ /+/g;
	$pagenow{'content'} = &uri_escape($pagenow{'content'},$reserved . $unsafe);
	$pagenow{'contentlen'} = length($pagenow{'content'});
	}
    #---------------------------------------------------------------------

    local($hostconnectaddr,$hostconnectport);
    if(defined($pagenow{'proxy'}))
	{
        ($hostconnectaddr,$hostconnectport) = split(/\:/,$pagenow{'proxy'});
        $hostconnectport = defined($hostconnectport) ? $hostconnectport : 80;
	}
    else
	{
        ($hostconnectaddr,$hostconnectport) = ($hostaddr,$hostport);
	$pagenow{'url'} =~ m|^(http://)([^/\?\\]*)([^\r]*)$|i;
	$pagenow{'url'} = $3;
	if($pagenow{'url'} eq "") { $pagenow{'url'} = "/";}
	}	

    print_msg_to_file($logfile,"\nnewsocketto(ADDR:$hostconnectaddr,PORT:$hostconnectport,TIMEOUT:$pagenow{'timeoutconnect'})\n");
    
    local(%outsocket);
    %outsocket = newsocketto(S,$hostconnectaddr,$hostconnectport,$pagenow{'timeoutconnect'});
    if($outsocket{'error'}==1)
        {
        $out{'errortxt'} = $outsocket{'errortxt'};
	goto print_error_to_log_and_exit;
        }
	    	    	    
    select(S); $| = 1;
    select(STDOUT); $| = 1;

# POST ------------------------------------------------------------------------
local(@data);

if($pagenow{'method'} eq 'POST') {

@data   = ("POST $pagenow{'url'} HTTP/1.0$eol");

if(defined($pagenow{'referer'})) {push(@data,("Referer: $pagenow{'referer'}$eol"));}

if(defined($pagenow{'proxy'})) 
    { 
    push(@data,("Proxy-Connection: Keep-Alive$eol")); 
    }    
else 
    { 
#   push(@data,("Connection: Keep-Alive$eol")); 
    push(@data,("Connection: Close$eol")); 
    }

if(defined($pagenow{'agent'})) 
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

if(defined($pagenow{'cookies'})) 
    {
    push(@data,("Cookie: $pagenow{'cookies'})$eol"));
    }

push(@data,("Content-type: application/x-www-form-urlencoded$eol",
            "Content-length: $pagenow{'contentlen'}$eol$eol",
	    ));
	    
push(@data,("$pagenow{'content'}"));

print_msg_to_file($logfile,"\n----------------------- Request -------------------\n");
foreach $line (@data) {print_msg_to_file($logfile,$line);}
print_msg_to_file($logfile,"\n--------------------- Request end -----------------\n");
}

# GET ------------------------------------------------------------------------
if($pagenow{'method'} eq 'GET') {

if(!defined($pagenow{'content'})) {@data = ("GET $pagenow{'url'} HTTP/1.0$eol");}
else {@data = ("GET $pagenow{'url'}?$pagenow{'content'} HTTP/1.0$eol");}

if(defined($pagenow{'referer'})) {push(@data,("Referer: $pagenow{'referer'}$eol"));}

if(defined($pagenow{'proxy'})) 
    { 
    push(@data,("Proxy-Connection: Keep-Alive$eol")); 
    }    
else 
    { 
#   push(@data,("Connection: Keep-Alive$eol")); 
    push(@data,("Connection: Close$eol")); 
    }

if(defined($pagenow{'agent'})) 
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
	    "Pragma: No-Cache$eol"));

if(defined($pagenow{'cookies'})) 
    {
    push(@data,("Cookie: $pagenow{'cookies'})$eol$eol"));
    }
else
    {
    push(@data,("$eol"));
    }

print_msg_to_file($logfile,"\n----------------------- Request -------------------\n");
foreach $line (@data) {print_msg_to_file($logfile,$line);}
print_msg_to_file($logfile,"\n--------------------- Request end -----------------\n");
}

# SEND REQUEST ---------------------------------------------------------------
local($timeout) = $pagenow{'timeoutrequest'};
local($SIG{ALRM}) = $timeout ? sub {die;} : $SIG{ALRM} || 'DEFAULT';

local($result,$status,$headers,@body);
    
$result = eval {
alarm($timeout) if($timeout);
foreach $line (@data) {print S "$line";}
alarm(0) if($timeout);
1;
};

unless($result) 
    {
    close(S);
    $out{'errortxt'} = "GetPageNow_4(): TimeOut Send to Socket after $timeout seconds";
    goto print_error_to_log_and_exit;
    }

# GET PAGE ---------------------------------------------------------------
if(defined($pagenow{'norequest'}))    
    {
    close(S);
    @body = ();
    push @body, <<FASTBODY;
    
<HTML>
<BODY>
<CENTER>FAST</CENTER>
</BODY>
</HTML>
    
FASTBODY

    $out{'error'} = 0;
    $out{'status'} = "HTTP/1.1 200 OK";
    delete($out{'headers'});
    $out{'body'} = "@body";
    return %out;
    }

$result = eval {
alarm($timeout) if($timeout);
$status  = <S>;
alarm(0) if($timeout);
1;
};

unless($result) 
    {
    close(S);
    $out{'errortxt'} = "GetPageNow_4(): TimeOut Req Status after $timeout seconds";
    goto print_error_to_log_and_exit;
    }
$out{'status'} = $status;
    
$headers = '';

$result = eval {
alarm($timeout) if($timeout);

do
    {
    $headers.= $_ = <S> ;    # $headers includes last blank line
    } until (/^(\015\012|\012)$/) ;   # lines may be terminated with LF or CRLF
	
alarm(0) if($timeout);
1;
};

unless($result) 
    {
    close(S);
    $out{'errortxt'} = "GetPageNow_4(): TimeOut Req Header after $timeout seconds";
    goto print_error_to_log_and_exit;
    }
	
# Unfold long header lines, a la RFC 822 section 3.1.1
$headers=~ s/(\015\012|\012)[ \t]/ /g ;

$out{'headers'} = $headers;

$result = eval {
alarm($timeout) if($timeout);
@body=<S>;
alarm(0) if($timeout);
1;
};

$out{'body'} = "@body";

unless($result) 
    {
    close(S);
    $out{'errortxt'} = "GetPageNow_4(): TimeOut Req Body after $timeout seconds";
    goto print_error_to_log_and_exit;
    }
    
close(S);

local($cookies)=getcookies($headers);

if($cookies && !defined($pagenow{'cookies'}))
    {
    $pagenow{'cookies'} = $cookies;
    }
elsif($cookies && defined($pagenow{'cookies'}))    
    {
    $pagenow{'cookies'} = joincookies($pagenow{'cookies'},$cookies);
    }
    
print_msg_to_file($logfile,"$status\n");
print_msg_to_file($logfile,"$headers\n");

if(defined($pagenow{'cookies'})) 
    {
    print_msg_to_file($logfile,"Cookies: $pagenow{'cookies'}\n\n");
    }
else 
    {
    print_msg_to_file($logfile,"Cookies: <NONE>\n\n");
    }

print_msg_to_file($logfile,"@body\n\n");

if ($status=~ m#^HTTP/[0-9.]*\s*[45]\d\d#) 
	{
	if(defined($pagenow{'showerrors'})) 
	    {
	    &HTMLdie("@body");
	    }
	else 
	    {
	    $out{'errortxt'} = "GetPageNow_4(): Server answer: $status";
	    goto print_error_to_log_and_exit;
	    }
	}

if($headers=~ m|(^Location:\s+)([^\r\n ]+)|im)
        {
	print_msg_to_file($logfile,"------------->>>>> REDIRECT ---------->>>>\n");

	local($location) = $2;
	
	if(!($location =~ m|^(http://)|i))
	    {
	    $location = $pagenow{'savedurl'} . "/" . $location;
	    }
	$pagenow{'url'}	= $location;
	
	print_msg_to_file($logfile,"TO: $location\n\n");

        if($location=~ m|^(http://)([^\?]*)\?([^\r\n]*)|i)
	    {
	    $pagenow{'content'} = $3;
	    print_msg_to_file($logfile,"NEW CONTENT: $pagenow{'content'}\n");
	    }
	else
	    {
	    delete($pagenow{'content'});
	    delete($pagenow{'contentlen'});
	    delete($pagenow{'savedurl'});
	    }	    

	$pagenow{'method'} = "GET";
        goto next_url;
        }

if(defined($pagenow{'cookies'})) {$out{'cookies'} = $pagenow{'cookies'};}
$out{'error'} = 0;
return %out;

print_error_to_log_and_exit:
print_msg_to_file($logfile,"\n$out{'errortxt'}\n");
return %out;
}
###############################################################################
sub ViewSpecHtmFile {
	local($htmfile) = @_;

open(FILE,"$htmfile") || &HTMLdie("ViewSpecHtmFile: Can't open file: '$htmfile'");
@htmfile = <FILE>;
close(FILE);

$commonline_htm='';
foreach $line (@htmfile) {$commonline_htm="$commonline_htm$line";}

$commonline_htm = &change_spec_labels($commonline_htm);

print "Content-type: text/html\n\n";
print "$commonline_htm";

exit;
}
###############################################################################
sub change_spec_labels {
    local($ll)= @_ ;

    $serverport = defined($ENV{'SERVER_PORT'}) ? $ENV{'SERVER_PORT'} : -1;
    $portst = $serverport==80  ?  ''   :  ':' . $serverport;
    $thisurl= join('','http://',defined($ENV{'SERVER_NAME'}) ? $ENV{'SERVER_NAME'} : '',$portst,defined($ENV{'SCRIPT_NAME'}) ? $ENV{'SCRIPT_NAME'} : '');

    $thisurl=~ m|^([^\s\?]+)(/{1}?)|i;
    $thisshorturl=$1;

    $ll =~ s|###ANTIPOPUPSTRING###|$antipopupstr|igm;
    $ll =~ s|###RANDOM:([0-9]+)-([0-9]+)###|$1+(int rand($2-$1+1))|igme;
    
    $ll =~ s|###BASEOFPAGEHERE###|defined($baseofpage) ? $baseofpage : ''|igme;
    $ll =~ s|###RANDOM1###|defined($random1) ? $random1 : ''|igme;
	
    $ll =~ s|###THISURL###|$thisurl|igm;
    $ll =~ s|###THISURL_WITHOUT_SCRIPT_NAME###|$thisshorturl|igm;

    $ll =~ s|###SCRIPTNAME###|defined($SCRIPTNAME) ? $SCRIPTNAME : ''|igme;
    $ll =~ s|###DIRNAME###|defined($directory) ? $directory : ''|igme;
    $ll =~ s|###INTPROXYADDR###|defined($proxyaddr) ? $proxyaddr : ''|igme;
    $ll =~ s|###INTPROXYPORT###|defined($proxyport) ? $proxyport : ''|igme;
    $ll =~ s|###WEBP_ADDCGIURL###|defined($webp_addcgiurl) ? $webp_addcgiurl : ''|igme;

    $ll =~ s|###PREVPAGE###|defined($PREVPAGENAME) ? $PREVPAGENAME : ''|gime;

    $ll =~ s|###ORIGINAL_TITLE###|defined($original_title) ? $original_title : ''|gime;
    $ll =~ s|###ORIGINAL_DESCRIPTION###|defined($original_description) ? $original_description : ''|gime;
    $ll =~ s|###ORIGINAL_KEYWORDS###|defined($original_keywords) ? $original_keywords : ''|gime;
    $ll =~ s|###ORIGINAL_HTML###|defined($original_html) ? $original_html : ''|gime;
    $ll =~ s|###ORIGINAL_BODY###|defined($original_body) ? $original_body : ''|gime;
    $ll =~ s|###ORIGINAL_HEAD###|defined($original_head) ? $original_head : ''|gime;

    foreach $key (@envkeys)
	{
        $ll =~ s|###ENV_$key###|defined($ENV{$key}) ? $ENV{$key} : ''|gime;
	}

    return $ll;
}
###############################################################################
sub SelectRandomStringFromFile {
    local($filename) = @_;
    
    local(@strings,$rndnum,$string);

open(FILE,"$filename") || &HTMLdie("Can't open file: '$filename'");
@strings = <FILE>;
close(FILE);

$rndnum    = int rand($#strings+1);
$string    = $strings[$rndnum];
$string    =~ s/\r//g;
$string    =~ s/\n//g;

return $string;
}
###############################################################################
sub VoidFile {
	local($logfile) = @_;

if(!defined($logfile)) 
    { 
    die "Error input in SNlib::VoidFile()";
    }

open(FILE,">$logfile");
close(FILE);

}
###############################################################################
sub MassiveToString {
	local(@body) = @_;

	local($commonline);
	foreach (@body) 
	    {
	    $commonline = $commonline . $_; 
	    }

	return $commonline; 
}
###############################################################################
sub CorrectLinksOnPage {
	local($string) = @_;

	&GetRelativeUrls($url);

	@body=split(/>/,$string);
	
	foreach (@body) {

	if((/<\s*form\b/im) && !(/\baction\s*=/im) && !(/\bscript\s*=/im))
		{
		s|<\s*form\b|<form action="$url"|im;
		}

	# Put the most common cases first

        s/(<[^>]*\bhref\s*=\s*["']?)([^\s"'>]*)/       $1 . &full_url($2) /ime,
            next if /<\s*a\b/im;

        s/(<[^>]*\bsrc\s*=\s*["']?)([^\s"'>]*)/        $1 . &full_url($2) /ime,
        s/(<[^>]*\blowsrc\s*=\s*["']?)([^\s"'>]*)/     $1 . &full_url($2) /ime,
        s/(<[^>]*\blongdesc\s*=\s*["']?)([^\s"'>]*)/   $1 . &full_url($2) /ime,
        s/(<[^>]*\busemap\s*=\s*["']?)([^\s"'>]*)/     $1 . &full_url($2) /ime,
        s/(<[^>]*\bdynsrc\s*=\s*["']?)([^\s"'>]*)/     $1 . &full_url($2) /ime,
            next if /<\s*img\b/im;

        s/(<[^>]*\bbackground\s*=\s*["']?)([^\s"'>]*)/ $1 . &full_url($2) /ime,
            next if /<\s*body\b/im;

        s/(<[^>]*\bhref\s*=\s*["']?)([^\s"'>]*)/       $1 . &GetRelativeUrls(&full_url($2)) /ime,
            next if /<\s*base\b/im ;     # has special significance

        s/(<[^>]*\bsrc\s*=\s*["']?)([^\s"'>]*)/        $1 . &full_url($2) /ime,
        s/(<[^>]*\blongdesc\s*=\s*["']?)([^\s"'>]*)/   $1 . &full_url($2) /ime,
            next if /<\s*frame\b/im ;

        s/(<[^>]*\baction\s*=\s*["']?)([^\s"'>]*)/     $1 . &full_url($2) /ime,
        s/(<[^>]*\bscript\s*=\s*["']?)([^\s"'>]*)/     $1 . &full_url($2) /ime,
            next if /<\s*form\b/im ;     # needs special attention

        s/(<[^>]*\bsrc\s*=\s*["']?)([^\s"'>]*)/        $1 . &full_url($2) /ime,
        s/(<[^>]*\busemap\s*=\s*["']?)([^\s"'>]*)/     $1 . &full_url($2) /ime,
            next if /<\s*input\b/im ;

        s/(<[^>]*\bhref\s*=\s*["']?)([^\s"'>]*)/       $1 . &full_url($2) /ime,
            next if /<\s*area\b/im ;

        s/(<[^>]*\bcodebase\s*=\s*["']?)([^\s"'>]*)/   $1 . &full_url($2) /ime,
        s/(<[^>]*\bcode\s*=\s*["']?)([^\s"'>]*)/       $1 . &full_url($2) /ime,
        s/(<[^>]*\bobject\s*=\s*["']?)([^\s"'>]*)/     $1 . &full_url($2) /ime,
        s/(<[^>]*\barchive\s*=\s*["']?)([^\s"'>]*)/    $1 . &full_url($2) /ime,
            next if /<\s*applet\b/im ;


        # These are seldom-used tags, or tags that seldom have URLs in them

        s/(<[^>]*\bsrc\s*=\s*["']?)([^\s"'>]*)/        $1 . &full_url($2) /ime,
            next if /<\s*bgsound\b/im ;  # Microsoft only

        s/(<[^>]*\bcite\s*=\s*["']?)([^\s"'>]*)/       $1 . &full_url($2) /ime,
            next if /<\s*blockquote\b/im ;

        s/(<[^>]*\bcite\s*=\s*["']?)([^\s"'>]*)/       $1 . &full_url($2) /ime,
            next if /<\s*del\b/im ;

        s/(<[^>]*\bsrc\s*=\s*["']?)([^\s"'>]*)/        $1 . &full_url($2) /ime,
            next if /<\s*embed\b/im ;    # Netscape only

        s/(<[^>]*\bsrc\s*=\s*["']?)([^\s"'>]*)/        $1 . &full_url($2) /ime,
        s/(<[^>]*\bimagemap\s*=\s*["']?)([^\s"'>]*)/   $1 . &full_url($2) /ime,
            next if /<\s*fig\b/im ;      # HTML 3.0

        s/(<[^>]*\bsrc\s*=\s*["']?)([^\s"'>]*)/        $1 . &full_url($2) /ime,
            next if /<\s*h[1-6]\b/im ;   # HTML 3.0

        s/(<[^>]*\bprofile\s*=\s*["']?)([^\s"'>]*)/    $1 . &full_url($2) /ime,
            next if /<\s*head\b/im ;

        s/(<[^>]*\bsrc\s*=\s*["']?)([^\s"'>]*)/        $1 . &full_url($2) /ime,
            next if /<\s*hr\b/im ;       # HTML 3.0

        s/(<[^>]*\bsrc\s*=\s*["']?)([^\s"'>]*)/        $1 . &full_url($2) /ime,
        s/(<[^>]*\blongdesc\s*=\s*["']?)([^\s"'>]*)/   $1 . &full_url($2) /ime,
            next if /<\s*iframe\b/im ;

        s/(<[^>]*\bcite\s*=\s*["']?)([^\s"'>]*)/       $1 . &full_url($2) /ime,
            next if /<\s*ins\b/im ;

        s/(<[^>]*\bsrc\s*=\s*["']?)([^\s"'>]*)/        $1 . &full_url($2) /ime,
            next if /<\s*layer\b/im ;

        s/(<[^>]*\bhref\s*=\s*["']?)([^\s"'>]*)/       $1 . &full_url($2) /ime,
        s/(<[^>]*\burn\s*=\s*["']?)([^\s"'>]*)/        $1 . &full_url($2) /ime,
            next if /<\s*link\b/im ;

        s/(<[^>]*\burl\s*=\s*["']?)([^\s"'>]*)/        $1 . &full_url($2) /ime,
            next if /<\s*meta\b/im ;     # Netscape only

        s/(<[^>]*\bsrc\s*=\s*["']?)([^\s"'>]*)/        $1 . &full_url($2) /ime,
            next if /<\s*note\b/im ;     # HTML 3.0

        s/(<[^>]*\busemap\s*=\s*["']?)([^\s"'>]*)/     $1 . &full_url($2) /ime,
        s/(<[^>]*\bcodebase\s*=\s*["']?)([^\s"'>]*)/   $1 . &full_url($2) /ime,
        s/(<[^>]*\bdata\s*=\s*["']?)([^\s"'>]*)/       $1 . &full_url($2) /ime,
        s/(<[^>]*\barchive\s*=\s*["']?)([^\s"'>]*)/    $1 . &full_url($2) /ime,
        s/(<[^>]*\bclassid\s*=\s*["']?)([^\s"'>]*)/    $1 . &full_url($2) /ime,
        s/(<[^>]*\bname\s*=\s*["']?)([^\s"'>]*)/       $1 . &full_url($2) /ime,
            next if /<\s*object\b/im ;

        s/(<[^>]*\bsrc\s*=\s*["']?)([^\s"'>]*)/        $1 . &full_url($2) /ime,
        s/(<[^>]*\bimagemap\s*=\s*["']?)([^\s"'>]*)/   $1 . &full_url($2) /ime,
            next if /<\s*overlay\b/im ;  # HTML 3.0

        s/(<[^>]*\bcite\s*=\s*["']?)([^\s"'>]*)/       $1 . &full_url($2) /ime,
            next if /<\s*q\b/im ;

        s/(<[^>]*\bsrc\s*=\s*["']?)([^\s"'>]*)/        $1 . &full_url($2) /ime,
        s/(<[^>]*\bfor\s*=\s*["']?)([^\s"'>]*)/        $1 . &full_url($2) /ime,
            next if /<\s*script\b/im ;

        s/(<[^>]*\bsrc\s*=\s*["']?)([^\s"'>]*)/        $1 . &full_url($2) /ime,
            next if /<\s*select\b/im ;   # HTML 3.0

        s/(<[^>]*\bsrc\s*=\s*["']?)([^\s"'>]*)/        $1 . &full_url($2) /ime,
            next if /<\s*ul\b/im ;       # HTML 3.0

	}   # foreach (@body)

	local($commonline)="";
	foreach $line (@body) {$commonline="$commonline$line>";}
	substr($commonline,-1)="";

	return $commonline;
}
###############################################################################
sub full_url{
    	local($link)= @_ ;

	$oldlink=$link;

	if($link=~ m|^(http://)|i) {goto exit_full_url;}
	if($link=~ m|^(mailto:)|i) {goto exit_full_url;}
	if($link=~ m|^(javascript:)|i) {goto exit_full_url;}
	if($link=~ m|^(#)|i) {goto exit_full_url;}

	$link=~ s|^/|$baseurl/|i;
	$link=~ s|^\./|$relurl/|i;
	$link=~ s|^\.\./|$relurl2/|i;

	if(!($link=~ m|^(http://)|i)) {$link = "$relurl/$link";}

exit_full_url:

	open(FILE,">>$logfile");
	print FILE "'$oldlink' -> '$link'\n";
	close(FILE);

	return $link;
}
###############################################################################
sub GetRelativeUrls {
	local($url) = @_;

#open(FILE,">>$logfile");

#print FILE "\n";
#print FILE "URL: $url\n";

$url     =~ m|^(http://)([^/\?\r\n]*)|i;
$host    = $2;
#print FILE "HOST: $host\n";

### Áàçîâûé URL íå ñîäåpäèò íà êîíöå /
### http://adm.ict.nsc.ru/rus/docs/perl/ - http://adm.ict.nsc.ru
### http://www.irtel.ru/ - http://www.irtel.ru
### http://www.irtel.ru  - http://www.irtel.ru

$baseurl = "http://$host";
#print FILE "BASEURL: $baseurl\n";

### Îñíîñèòåëüíûé URL íå ñîäåpäèò íà êîíöå /
### http://adm.ict.nsc.ru/rus/docs/perl/ - http://adm.ict.nsc.ru/rus/docs/perl
### http://www.irtel.ru/ - http://www.irtel.ru
### http://www.irtel.ru  - http://www.irtel.ru

if($url     =~ m|^(http://)(.*)[/]+|i) {$relurl  = "http://$2";}
else {$relurl = $baseurl;}
#print FILE "RELURL: $relurl\n";

### Îñíîñèòåëüíûé URL2 íå ñîäåpäèò íà êîíöå /
### http://adm.ict.nsc.ru/rus/docs/perl/ - http://adm.ict.nsc.ru/rus/docs
### http://www.irtel.ru/ - http://www.irtel.ru
### http://www.irtel.ru  - http://www.irtel.ru

if($relurl    =~ m|^(http://)(.*)[/]+|i) {$relurl2  = "http://$2";}
else {$relurl2 = $baseurl;}
#print FILE "RELURL2: $relurl2\n\n";
#close(FILE);
return $url; 
}
###############################################################################
sub send_void_image {

print "Content-type: image/gif\n";
print "Content-Length: 43\n\n";

print "GIF89a\x01\0\x01\0\x80\0\0\0\0\0\xff\xff\xff\x21\xf9\x04\x01\0\0\0\0\x2c\0\0\0\0\x01\0\x01\0\x40\x02\x02\x44\x01\0\x3b";
exit;
}
##############################################################################
sub newsocketto {
    local(*S, $host, $port,$timeout) = @_ ;
    local($ok,$result);
    
    local(%out);
    $out{'error'} = 1; 

    local($SIG{ALRM}) = $timeout ? sub { $out{'errortxt'} = "newsocketto(): Error connecting to $host:$port after $timeout seconds";die;} : $SIG{ALRM} || 'DEFAULT';
    
    $result = eval {
    alarm($timeout) if($timeout);

    if(!($iaddr=inet_aton($host))) 
	{
	$out{'errortxt'} = "newsocketto(): Error resolving '$host'";
        alarm(0) if($timeout);
	die;
	}
    $paddr = sockaddr_in($port,$iaddr);
    if(!socket(S, AF_INET, SOCK_STREAM, 0))
	{
	$out{'errortxt'} = "newsocketto(): Error getting socket()"; 
        alarm(0) if($timeout);
	die;
	}
    $ok = connect(S, $paddr);
    if(!$ok)
	{
	$out{'errortxt'} = "newsocketto(): Can't connect"; 
        alarm(0) if($timeout);
	die;
	}
    alarm(0) if($timeout);
    1;
    };
    unless($result) {return %out;}
    $out{'error'} = 0; 
    return %out;
}
#########################################################################
sub bhprint_color_screen {
   local($string,$color) = @_;
   if(isrunninglocaly())
       {
       print "$color$string$color{'normal'}";
       }
   else
       {
       bhprint_screen($string);
       }
}
###############################################################################
sub bhprint_color_screen_log {
   local($string,$color) = @_;
   if(isrunninglocaly())
       {
       print "$color$string$color{'normal'}";
       bhprint_log($string);
       }
   else
       {
       bhprint_screen_log($string);
       }
}
###############################################################################
sub bhprint_color_log_screen {
   local($string,$color) = @_;
   bhprint_color_screen_log($string,$color);
}
###############################################################################
sub bhprint_log {
    local($msg) = @_;
    open(FILE,">>$logfile");
    print FILE "$msg";
    close(FILE);
}
###############################################################################
sub bhprint_log_withtime {
    local($msg) = @_;
    
    GetDate();
    open(FILE,">>$logfile");
    print FILE "$date: $msg";
    close(FILE);
}
###############################################################################
sub print_msg_to_file {
    local($file,$msg) = @_;

    if(open(FILE,">>$file"))
	{
	print FILE "$msg";
	close(FILE);
	}
}
###############################################################################
sub bhprint_screen {
    local($string) = @_;
    
    if(isrunninglocaly())
	{
        print $string;
	}
    else
	{
	$string =~ s /\n/<br>\n/ig;
        print $string;
	}
}
###############################################################################
sub bhprint_log_screen {
    local($string) = @_;
    
    bhprint_log($string);
    bhprint_screen($string);
}
sub bhprint_screen_log {
    local($string) = @_;
    
    bhprint_log($string);
    bhprint_screen($string);
}
sub bhprint_screen_log_flag {
    local($flagscreen,$flaglog,$string) = @_;
    
    if($flagscreen) {bhprint_screen($string);}
    if($flaglog) {bhprint_log($string);}
}
sub bhprint_log_screen_flag {
    local($flaglog,$flagscreen,$string) = @_;
    
    if($flaglog) {bhprint_log($string);}
    if($flagscreen) {bhprint_screen($string);}
}
##############################################################################
sub bhprintHTMLheader {
    if(!isrunninglocaly())
	{
	print "Content-type: text/html\n\n";
	print "<html><body>\n";
	print "Goto <A HREF=http://sex.tapor.com target=_top>http://sex.tapor.com</A> to view best video sex on the net!<br><br>\n\n";
	}
    else
	{
	print "Goto http://sex.tapor.com to view best video sex on the net!\n\n";
	}
}
##############################################################################
sub bhprintHTMLfooter {
    if(!isrunninglocaly())
	{
	print "</body></html>\n";
	print "$antipopupstr\n";
	}
}
##############################################################################
sub isrunninglocaly {

    local($method) = defined($ENV{'REQUEST_METHOD'}) ? $ENV{'REQUEST_METHOD'} : 'LOCAL';
    if ($method eq 'GET' || $method eq 'POST') 
	{
        return 0;
	}
    return 1;
}
##############################################################################
sub CheckAllreadyRunning_2 {
    local($numstarts,$savefilesto) = @_;

    if(!defined($savefilesto)) {$savefilesto = "./";}

    local($lockfile) = "__lock";
    local($x,$flockret,$commonret);
    
    if($numstarts <= 0) {return 0;}
    
    $commonret = 0;
    for($x=1;$x<=$numstarts;$x++)
	{
        if(!open(LOCKING_FILE_SPEC,">$savefilesto/" . $lockfile . "_" . $x)) {next;}
        $flockret = flock(LOCKING_FILE_SPEC,2 + 4);

	if($flockret)
	    {
	    $commonret = 1;
	    last;
	    }
	}
    return $commonret;
}	
##############################################################################
sub CheckAllreadyRunning {
    local($numstarts,$LISTEN_PORT) = @_;

    local($file) = "__listenport.txt";
    unless (-e $file) 
	{
	$LISTEN_PORT = int rand(500);
	$LISTEN_PORT = $LISTEN_PORT + 21600;
	open(FILE,">$file");
	print FILE $LISTEN_PORT;
	close(FILE);
	}
    open(FILE,$file);
    $LISTEN_PORT=<FILE>;
    seek(FILE,0,0);
    chomp($LISTEN_PORT);
    close(FILE);
    
    socket(SE, PF_INET, SOCK_STREAM, 'udp');
    setsockopt(SE, SOL_SOCKET, SO_REUSEADDR, 1);
    for($x=0;$x<$numstarts;$x++,$LISTEN_PORT++)
	{
        bind(SE, sockaddr_in($LISTEN_PORT, INADDR_ANY)) or next;
        return 1;
	}
    return 0;
}
###############################################################################
sub VoidCRLF {
    local($string) = @_;

    $string =~ s/\n//g;
    $string =~ s/\r//g;
    
    return $string;
}
sub VoidCRLFfromEndOfString {
    local($string) = @_;

    local($detect);

    nextCRLFfromEndOfString:
    $detect = 0;
    if($string=~ m/\r$/)
	{
	$string = substr($string,0,-1);
	$detect = 1;
	}
    if($string=~ m/\n$/)
	{
	$string = substr($string,0,-1);
	$detect = 1;
	}
    if($detect) {goto nextCRLFfromEndOfString;}
    return $string;
}
###############################################################################
sub uri_escape {
    my($text, $patn) = @_;
    return undef unless defined $text;
    
    # Build a char->hex map
    for (0..255) {
        $escapes{chr($_)} = sprintf("%%%02X", $_);
    }
    
    if (defined $patn){
	unless (exists  $subst{$patn}) {
	    # Because we can't compile regex we fake it with a cached sub
	    $subst{$patn} =
	      eval "sub {\$_[0] =~ s/([$patn])/\$escapes{\$1}/g; }";
	    Carp::croak("uri_escape: $@") if $@;
	}
	&{$subst{$patn}}($text);
    } else {
	# Default unsafe characters. (RFC1738 section 2.2)
	$text =~ s/([\x00-\x20"#%;<>?{}|\\\\^~`\[\]\x7F-\xFF])/$escapes{$1}/g; #"
    }
    $text;
}
###############################################################################
sub GetAllFilesInDir {
local($usedir) = @_;
local(@allfiles,@bodydir,$fileindir);

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
###############################################################################
sub GetAllFilesContaningInDir {
    local($dir) = @_;

    local(@keys,@returnkeys);
    
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
sub readfile {
    local($file) = @_;

    my @filebody;
    my $filebody;
    if(open(FILE,$file))
	{
        @filebody = <FILE>;
        close(FILE);
	}
    else
	{
	return undef;
	}	
    $filebody = MassiveToString(@filebody);
    return $filebody;
}
###############################################################################
sub GetDate {

$timeModifier = 0;
($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst)=localtime(time+ (3600*$timeModifier)); # set time
if (length ($min) eq 1) {$min= '0'.$min;}
$mon++;
$year = $year + 1900;
$date="$mon/$mday/$year, $hour:$min:$sec";
}
###############################################################################
sub printtofile {

    local($file,$string) = @_;
    
    if(open(FILE,">>$file"))
	{
        print FILE $string;
        close(FILE);
	}
            
}
###############################################################################
sub printtologfile {
    local($string) = @_;
    
    bhprint_log($string);
}    
###############################################################################
sub SendEmailMsg {
    local($from,$email,$msg) = @_;

local($mailprog) = "/usr/sbin/sendmail";

&GetDate;

if(open(MAIL,"|$mailprog -t"))
    {
    print MAIL "To: <$email>\n";
    print MAIL "From: $from <$email>\n";
    print MAIL "Subject: $date\n\n";

    print MAIL "$msg\n";
    close (MAIL);
    }
}
###############################################################################
sub SendEmailMultiMsg {
    local($from,$email,@msg) = @_;

local($mailprog) = "/usr/sbin/sendmail";

&GetDate;

if(open(MAIL,"|$mailprog -t"))
    {
    print MAIL "To: <$email>\n";
    print MAIL "From: $from <$email>\n";
    print MAIL "Subject: $date\n\n";

    foreach $line (@msg)
	{
	$line = VoidCRLF($line);
        print MAIL "$line\n";
	}
	
    close (MAIL);
    }
}
###############################################################################
sub win2koi() 
    { 
    $_ = $_[0]; 
    tr /¿áâ÷çäåöúéêëìíîïðòóôõæèãþûýÿùøüàñÁÂ×ÇÄÅÖÚÉÊËÌÍÎÏÐÒÓÔÕÆÈÃÞÛÝßÙØÜÀÑ/¿Â×ÞÚÄÅÃßÊËÌÍÎÏÐÒÔÕÆÈÖÉÇÀÙÜÑÝÛØÁÓâ÷þúäåãÿêëìíîïðòôõæèöéçàùüñýûøáó/; 
    return $_; 
    } 
sub koi2win() 
    { 
    $_ = $_[0]; 
    tr /¿Â×ÞÚÄÅÃßÊËÌÍÎÏÐÒÔÕÆÈÖÉÇÀÙÜÑÝÛØÁÓâ÷þúäåãÿêëìíîïðòôõæèöéçàùüñýûøáó/¿áâ÷çäåöúéêëìíîïðòóôõæèãþûýÿùøüàñÁÂ×ÇÄÅÖÚÉÊËÌÍÎÏÐÒÓÔÕÆÈÃÞÛÝßÙØÜÀÑ/;
    return $_; 
    } 
###############################################################################
sub CheckForLine {
    local($string,@body) = @_;

    local($step_status,$line);

    $step_status = 0;
    foreach $line (@body)	
	{
	if($line =~ m|$string|i)
	    {
	    $step_status = 1;
	    last;
	    }
	}
    if(!$step_status)
	{
	return 0;
	}
    return 1;
}
##############################################################################
1;
