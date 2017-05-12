package Regexp::Common::IRC;
$VERSION = 0.04;
use strict;
use Regexp::Common qw(pattern clean no_defaults);

=pod 

=head1 NAME

Regexp::Common::IRC - provide patterns for parsing IRC messages

=head1 SYNOPSIS

	use Regexp::Common qw(IRC);
	
	sub trigger {
        	my ($self, $msg) = @_;
        	my $CMD = qr/^summon[:,]?
                	     \s*$RE{IRC}{nick}{-keep}\s*
                     	     (?:to\s*$RE{IRC}{channel}{-keep})?
                     	     [?.!]*
                   	   /ix;
        	if ($msg =~ $CMD) {
                	$self->{who} = $1;
                	$self->{to} = $2;
                	return 1;
        	}
        	return 0;
	} 
 
=head1 EBNF for IRC

based upon Section 2.3.1 of RFC 2812
(L<http://www.irchelp.org/irchelp/rfc/rfc2812.txt>)

    target     =  nickname / server
    msgtarget  =  msgto *( "," msgto )
    msgto      =  channel / ( user [ "%" host ] "@" servername )
    msgto      =/ ( user "%" host ) / targetmask
    msgto      =/ nickname / ( nickname "!" user "@" host )
    channel    =  ( "#" / "+" / ( "!" channelid ) / "&" ) chanstring
                  [ ":" chanstring ]
    servername =  hostname
    host       =  hostname / hostaddr
    hostname   =  shortname *( "." shortname )
    shortname  =  ( letter / digit ) *( letter / digit / "-" )
                 *( letter / digit ); as specified in RFC 1123 [HNAME]
    hostaddr   =  ip4addr / ip6addr
    ip4addr    =  1*3digit "." 1*3digit "." 1*3digit "." 1*3digit
    ip6addr    =  1*hexdigit 7( ":" 1*hexdigit ) / "0:0:0:0:0:" ( "0" / "FFFF" ) ":" ip4addr
    
    nickname   =  ( letter / special ) *8( letter / digit / special / "-" )
    targetmask =  ( "$" / "#" ) mask; see details on allowed masks in section 3.3.1
    chanstring =  %x01-07 / %x08-09 / %x0B-0C / %x0E-1F / %x21-2B / %x2D-39 / %x3B-FF
              ; any octet except NUL, BELL, CR, LF, " ", "," and ":"
    channelid  = 5( %x41-5A / digit )   ; 5( A-Z / 0-9 )
    user       =  1*( %x01-09 / %x0B-0C / %x0E-1F / %x21-3F / %x41-FF )
              ; any octet except NUL, CR, LF, " " and "@"
    key        =  1*23( %x01-05 / %x07-08 / %x0C / %x0E-1F / %x21-7F )
              ; any 7-bit US_ASCII character,
              ; except NUL, CR, LF, FF, h/v TABs, and " "
    letter     =  %x41-5A / %x61-7A       ; A-Z / a-z
    digit      =  %x30-39                 ; 0-9
    hexdigit   =  digit / "A" / "B" / "C" / "D" / "E" / "F"
    special    =  %x5B-60 / %x7B-7D
               ; "[", "]", "\", "`", "_", "^", "{", "|", "}"

=cut

my $letter = '[A-Za-z]';
pattern
  name   => [qw(IRC letter -keep)],
  create => qq/(?k:$letter)/,
  ;

my $digit = '[0-9]';
pattern
  name   => [qw(IRC digit -keep)],
  create => qq/(?k:$digit)/,
  ;

my $hexdigit = "(?:$digit|[A-F])";
pattern
  name   => [qw(IRC hexdigit -keep)],
  create => qq/(?k:$hexdigit)/,
  ;

my $special = '[\x{5B}-\x{60}\x{7B}\x{7D}]';
pattern
  name   => [qw(IRC special -keep)],
  create => qq/(?k:$special)/,
  ;

my $user =
  '(?:[\x{01}-\x{09}\x{0B}-\x{0C}\x{0E}-\x{1F}\x{21}-\x{3F}\x{41}-\x{FF}])?';
pattern
  name   => [qw(IRC user -keep)],
  create => qq/(?k:$user)/,
  ;

my $key =
  '(?:[\x{01}-\x{05}\x{07}-\x{08}\x{0C}\x{0E}-\x{1F}\x{21}-\x{7F}]{1,23})';
pattern
  name   => [qw(IRC key -keep)],
  create => qq/(?k:$key)/,
  ;

my $chanstring =
  '[\x{01}-\x{07}\x{08}-\x{09}\x{0B}-\x{0C}\x{0E}-\x{1F}\x{21}-\x{2B}';
$chanstring .= '\x{2D}-\x{39}\x{3B}-\x{FF}]{1,29}';
pattern
  name   => [qw(IRC chanstring -keep)],
  create => qq/(?k:$chanstring)/,
  ;

my $channelid = "(?:[A-Z]|$digit){5}";
pattern
  name   => [qw(IRC channelid -keep)],
  create => qq/(?k:$channelid)/,
  ;

my $nowild = "(?:[\x{01}-\x{29}\x{2B}-\x{3E}\x{40}-\x{FF}])";
pattern
  name   => [qw(IRC mask nowild -keep)],
  create => qq/(?k:$nowild)/,
  ;

my $noesc = "[\x{01}-\x{5B}\x{5D}-\x{FF}]";
pattern
  name   => [qw(IRC mask noesc -keep)],
  create => qq/(?k:$noesc)/,
  ;

my $wildone = "[\x{3F}]";
pattern
  name   => [qw(IRC mask wildone -keep)],
  create => qq/(?k:$wildone)/,
  ;

my $wildmany = "[\x{2A}]";
pattern
  name   => [qw(IRC mask wildmany -keep)],
  create => qq/(?k:$wildmany)/,
  ;

my $mask = "(?:$nowild|$noesc|$wildone|$noesc$wildmany)*";
pattern
  name   => [qw(IRC mask -keep)],
  create => qq/(?k:$mask)/,
  ;

my $targetmask = "(?:\$|\#)$mask";
pattern
  name   => [qw(IRC targetmask -keep)],
  create => qq/(?k:$targetmask)/,
  ;

my $nick = "(?:$letter|$special)(?:$letter|$digit|$special|-){0,19}";
pattern
  name   => [qw(IRC nick -keep)],
  create => qq/(?k:$nick)/,
  ;

my $shortname = "(?:$letter|$digit)(?:$letter|$digit|\-)*(?:$letter|$digit)*";
pattern
  name   => [qw(IRC shortname -keep)],
  create => qq/(?k:$shortname)/,
  ;

my $hostname = "$shortname(?:\.$shortname)*";
pattern
  name   => [qw(IRC hostname -keep)],
  create => qq/(?k:$hostname)/,
  ;

my $ip4addr =
  "(?:$digit){1,3}\.(?:$digit){1,3}\.(?:$digit){1,3}\.(?:$digit){1,3}";
pattern
  name   => [qw(IRC ip4addr -keep)],
  create => qq/(?k:$ip4addr)/,
  ;

my $ip6addr = "(?:$hexdigit(?:\:$hexdigit){7})";
$ip6addr .= "|(?:0\:0\:0\:0\:0\:(?:0|FFFF)\:$ip4addr)";
pattern
  name   => [qw(IRC ip6addr -keep)],
  create => qq/(?k:$ip6addr)/,
  ;

my $hostaddr = "(?:$ip4addr|$ip6addr)";
pattern
  name   => [qw(IRC hostaddr -keep)],
  create => qq/(?k:$hostaddr)/,
  ;

my $host = "$hostname|$hostaddr";
pattern
  name   => [qw(IRC host -keep)],
  create => qq/(?k:$host)/,
  ;

my $server = $hostname;
pattern
  name   => [qw(IRC server -keep)],
  create => qq/(?k:$server)/,
  ;

my $channel = "(?:[#+&]|!$channelid)$chanstring(?:\:$chanstring)?";
pattern
  name   => [qw(IRC channel -keep)],
  create => qq/(?k:$channel)/,
  ;

my $msgto = "(?:$channel|$user\[\%$host\]\@$server)";
$msgto .= "|$user\%$host|$targetmask";
$msgto .= "|(?:$nick|$nick!$user\@$host)";
pattern
  name   => [qw(IRC msgto -keep)],
  create => qq/(?k:$msgto/,
  ;

my $msgtarget = "(?:$msgto(?:,$msgto)*)";
pattern
  name   => [qw(IRC msgtarget -keep)],
  create => qq/(?k:$msgtarget)/,
  ;

my $target = "(?:$nick|$server)";
pattern
  name   => [qw(IRC target -keep)],
  create => qq/(?k:$target)/,
  ;

=head1 SEE ALSO

L<Regexp::Common> for a general description of how to use this interface.

=head1 MAINTAINANCE

This package is maintained by Chris Prather S<(I<cpan@prather.org>)>.

=head1 COPYRIGHT

Copyright (c) 2005, Chris Prather. All Rights Reserved. 
This module is free software. It may be used, redistributed
and/or modified under the terms of the Perl Artistic License (see
L<http://www.perl.com/perl/misc/Artistic.html>)

=cut

1;
