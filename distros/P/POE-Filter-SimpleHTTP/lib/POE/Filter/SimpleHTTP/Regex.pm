package POE::Filter::SimpleHTTP::Regex;
our $VERSION = '0.091710';


use warnings;
use strict;

use bytes;
use Regexp::Common('URI');

sub quote_it
{
    $_[0] =~ s/([^[:alnum:][:cntrl:][:space:]])/\\$1/g;
	
	if($_[0] =~ /-/)
	{
		$_[0] =~ s/-//g;
		$_[0] .= '-';
	}

	return $_[0];
}

sub gen_char
{
    return '[' . quote_it( join('', map { chr($_) } 0..127) ) . ']';
}

sub exclude
{
    my ($pattern, $fromwhat) = @_;

    $fromwhat = substr($fromwhat, 1, length($fromwhat) - 2);

    $fromwhat =~ s/$pattern//g;

    return "[$fromwhat]";
}

sub gen_ctrl
{
    return '[' . quote_it( join '', map { chr($_) } (0..31, 127) ) . ']';
}

sub gen_octet
{
    return '[' . quote_it( join('', map { chr($_) } 0..255) ) . ']';
}

sub gen_separators
{
	return join 
	(
		'|',
		( 
			map { chr(92).$_ }
			(
				split
				(
					/\s/,
				 	'( ) < > @ , ; : \ " / [ ] ? = { }'.' '.chr(32).' '.chr(9)
				)
			)
		)
	);
}

my $oct			= gen_octet();
my $char		= gen_char();
my $upalpha		= '[A-Z]';
my $loalpha		= '[a-z]';
my $mark        = q|[_.!~*'()-]|;
my $digit		= '[0-9]';
my $hex			= "[a-fA-F]|$digit]";
my $alpha		= "(?:$upalpha|$loalpha)";
my $alphanum    = "(?:$alpha|$digit)";
my $unreserved  = "(?:$alphanum|$mark)";
my $escaped     = "(?:%$hex+)";
my $pchar       = "(?:$unreserved|$escaped|".'[:@&=+$,])';
my $segment     = "(?:$pchar*(?:;$pchar)*)";
my $path_segs   = "(?:$segment(?:/$segment)*)";
my $abs_path    = "(?:/$path_segs)";
my $ctrl		= gen_ctrl();
my $cr			= chr(13);
my $lf			= chr(10);
my $sp			= chr(32);
my $ht			= chr(9);
my $dq			= chr(34);
my $crlf		= "(?:$cr$lf)";
my $lws			= "(?:$crlf*(?:$sp|$ht)+)";
my $text		= exclude($ctrl,$oct);
my $separators 	= gen_separators();
my $token		= exclude( $ctrl, exclude( $separators, $char ) );
my $ctext		= exclude( "[()]", $text );
my $quot_pair	= "\\$char";
my $comment		= "(?:\((?:$ctext|$quot_pair|\1)*\))";
my $qdtext		= exclude( q/"/, $text );
my $quot_str   	= "(?:\"(?:$qdtext|$quot_pair)*\")";

my $httpvers	= "HTTP\/$digit+\.$digit+";

my $f_content	= "$text|$token|$separators|$quot_str";
my $f_value		= "(?:(?:$f_content+)|$lws)";

my $header		= "($token+):($f_value*)";
my $method 		= "OPTIONS|GET|HEAD|POST|PUT|DELETE|CONNECT|$token";
my $req_line	= "($method)$sp(" . $RE{'URI'}{'HTTP'}.'|'. $abs_path. ")$sp($httpvers)$crlf*";
my $resp_code	= $digit . '{3}';
my $resp_line	= "($httpvers)$sp($resp_code)$sp($text)*$crlf*";

our $RESPONSE = qr/$resp_line/;
our $REQUEST = qr/$req_line/;
our $HEADER = qr/$header/;
our $PROTOCOL = qr/$httpvers/;
our $METHOD = qr/$method/;
our $URI = qr/$RE{'URI'}{'HTTP'}|$abs_path/;

#my $HTTP = 'HTTP/1.1';
#my $CODE = '200';
#my $MESSAGE = 'OK';
#
#if($HTTP =~ /(?:$httpvers)/)
#{
#	warn 'PASSED HTTP';
#}
#
#if($CODE =~ /(?:$resp_code)/)
#{
#	warn 'PASSED RESPONSE CODE';
#}
#
#if($MESSAGE =~ /(?:$text)/)
#{
#	warn 'PASSED MESSAGE TEXT';
#}
#
#my $COMBINED = "$HTTP $CODE $MESSAGE\x0D\x0A";
#
#if($COMBINED =~ /(?:$httpvers)$sp(?:$resp_code)$sp(?:$text)*$crlf/)
#{
#	warn 'PASSED RESPONSE LINE';
#}
#
#my $HEAD1 = "Server: Apache/1.3.37 (Unix) mod_perl/1.29";
#
#if($HEAD1 =~ /(?:$token):(?:$f_value)*/)
#{
#	warn 'PASSED HEADER 1 ';
#}
#
#my $HEAD2 = "Date: Sun, 05 Aug 2007 18:46:50 GMT";
#
#if($HEAD2 =~ $POE::Filter::SimpleHTTP::Regex::HEADER)
#{
#    warn 'PASSED HEADER2';
#	warn $1;
#	warn $2;
#}
#
#my $COMB_REQ = "GET / $HTTP";
#
#if($COMB_REQ =~ $POE::Filter::SimpleHTTP::Regex::REQUEST)
#{
#    warn 'PASSED REQUEST';
#}

#warn $POE::Filter::SimpleHTTP::Regex::REQUEST;

#$string =~ s/[[:cntrl:]]//g;
#$string =~ s/(?<!\\)(\()(?!\?:)/\n$1\n/g;
#$string =~ s/(?<!\\)(\()(?=\?:)/\n\t$1/g;
#$string =~ s/(?<!\\)(\))/\n$1\n/g;
#$string =~ s/$crlf//g;
#$string =~ s/$lws//g;
#warn $string;

1;
