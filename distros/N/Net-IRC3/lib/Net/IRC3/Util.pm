package Net::IRC3::Util;
use strict;
no warnings;
use Exporter;
our @ISA = qw/Exporter/;
our @EXPORT_OK =
   qw(mk_msg parse_irc_msg split_prefix prefix_nick
      decode_ctcp encode_ctcp filter_ctcp_text_attr prefix_user prefix_host
      rfc_code_to_name filter_colors);

=head1 NAME

Net::IRC3::Util - Common utilities that help with IRC protocol handling

=head1 SYNOPSIS

   use Net::IRC3 qw/parse_irc_msg mk_msg/;

   my $msgdata = mk_msg (undef, PRIVMSG => "my hands glow!", "mcmanus");

=head1 FUNCTIONS

These are some utility functions that might come in handy when
handling the IRC protocol.

You can export these with eg.:

   use Net::IRC3 qw/parse_irc_msg/;

=over 4

=item B<parse_irc_msg ($ircline)>

This method parses the C<$ircline>, which is one line of the IRC protocol
without the trailing "\015\012".

It returns a hash which has the following entrys:

=over 4

=item prefix

The message prefix.

=item command

The IRC command.

=item params

The parameters to the IRC command in a array reference,
this includes the trailing parameter (the one after the ':' or
the 14th parameter).

=item trailing

This is set if there was a trailing parameter (the one after the ':' or
the 14th parameter).

=back

=cut

sub parse_irc_msg {
  my ($msg) = @_;

  my $cmd;
  my $pref;
  my $t;
  my @a;

  my $p = $msg =~ s/^(:([^ ]+)[ ])?([A-Za-z]+|\d{3})//;
  $pref = $2;
  $cmd = $3;

  my $i = 0;

  while ($msg =~ s/^[ ]([^ :\015\012\0][^ \015\012\0]*)//) {

    push @a, $1 if defined $1;
    if (++$i > 13) { last; }
  }

  if ($i == 14) {

    if ($msg =~ s/^[ ]:?([^\015\012\0]*)//) {
      $t = $1 if $1 ne "";
    }

  } else {

    if ($msg =~ s/^[ ]:([^\015\012\0]*)//) {
      $t = $1 if $1 ne "";
    }
  }

  push @a, $t if defined $t;

  my $m = { prefix => $pref, command => $cmd, params => \@a, trailing => $t };
  return $p ? $m : undef;
}

=item B<mk_msg ($prefix, $command, $trailing, @params)>

This function assembles a IRC message. The generated
message will look like (pseudo code!)

   :<prefix> <command> <params> :<trail>

Please refer to RFC 2812 how IRC messages normally look like.

The prefix and the trailing string will be omitted if they are C<undef>.

EXAMPLES:

   mk_msg (undef, "PRIVMSG", "you suck!", "magnus");
   # will return: "PRIVMSG magnus :you suck!\015\012"

   mk_msg (undef, "JOIN", undef, "#test");
   # will return: "JOIN #test\015\012"

=cut

sub mk_msg {
  my ($prefix, $command, $trail, @params) = @_;
  my $msg = "";

  $msg .= defined $prefix ? ":$prefix " : "";
  $msg .= "$command";

  # FIXME: params must be counted, and if > 13 they have to be
  # concationated with $trail
  map { $msg .= " $_" } @params;

  $msg .= defined $trail ? " :$trail" : "";
  $msg .= "\015\012";

  return $msg;
}

my @_ctcp_lowlevel_escape = ("\000", "0", "\012", "n", "\015", "r", "\020", "\020");

sub unescape_lowlevel {
   my ($data) = @_;
   my %map = reverse @_ctcp_lowlevel_escape;
   $data =~ s/\020(.)/defined $map{$1} ? $map{$1} : $1/ge;
   $data
}

sub escape_lowlevel {
   my ($data) = @_;
   my %map = @_ctcp_lowlevel_escape;
   $data =~ s/([\000\012\015\020])/"\020$map{$1}"/ge;
   $data
}

sub unescape_ctcp {
   my ($data) = @_;
   $data =~ s/\\(.)/$1 eq 'a' ? "\001" : ($1 eq "\\" ? "\\" : $1)/eg;
   $data
}

sub escape_ctcp {
   my ($data) = @_;
   $data =~ s/([\\\001])/$1 eq "\001" ? "\\a" : "\\\\"/eg;
   $data
}

=item B<decode_ctcp ($trailing)>

This function decodes the C<$trailing> part of an IRC message.
It will first unescape the lower layer, extract CTCP messages
and then return a list with two elements: the line without the ctcp messages
and an array reference which contains array references of CTCP messages.
Those CTCP message array references will have the CTCP message tag as
first element (eg. "VERSION") and the rest of the CTCP message as the second
element.

=cut

sub decode_ctcp {
   my ($line) = @_;

   $line = unescape_lowlevel ($line);
   my @ctcp;
   while ($line =~ /\G\001([^\001]*)\001/g) {
      my $msg = unescape_ctcp ($1);
      my ($tag, $data) = split / /, $msg, 2;
      push @ctcp, [$tag, $data];
   }

   $line =~ s/\001[^\001]*\001//g;

   return ($line, \@ctcp)
}

=item B<encode_ctcp (@msg)>

This function encodes a ctcp message for the trailing part of a NOTICE
or PRIVMSG. C<@msg> is an array of strings or array references.
If an array reference occurs in the C<@msg> array it's first
element will be interpreted as CTCP TAG (eg. one of PING, VERSION, .. whatever)
the rest of the array ref will be appended to the tag and seperated by
spaces.

All parts of the message will be contatenated and lowlevel quoted.
That means you can embed _any_ character from 0 to 255 in this message (thats
what the lowlevel quoting allows).

=cut

sub encode_ctcp {
   my (@args) = @_;
   escape_lowlevel (
      join "", map {
         ref $_
            ? "\001" . escape_ctcp (join " ", @$_) . "\001"
            : $_
      } @args
   )
}

=item B<filter_colors ($line)>

This function will filter out any mIRC colors and (most) ansi escape sequences.
Unfortunately the mIRC color coding will destroy improper colored numbers. So this
function may destroy the message in some occasions a bit.

=cut

sub filter_colors($) {
   my ($line) = @_;
   $line =~ s/\x1B\[.*?[\x00-\x1F\x40-\x7E]//g; # see ECMA-48 + advice by urxvt author
   $line =~ s/\x03\d\d?(?:,\d\d?)?//g;          # see http://www.mirc.co.uk/help/color.txt
   $line =~ s/[\x03\x16\x02\x1f\x0f]//g;        # see some undefined place :-)
   $line
}


# implemented after the below CTCP spec, but
# doesnt seem to be used by anyone... so it's untested.
sub filter_ctcp_text_attr_bogus {
   my ($line, $cb) = @_;
   return unless $cb;
   $line =~ s/\006([BVUSI])/{warn "FIL\n"; my $c = $cb->($1); defined $c ? $c : "\006$1"}/ieg;
   $line =~ s/\006CA((?:I[0-9A-F]|#[0-9A-F]{3}){2})/{my $c = $cb->($1); defined $c ? $c : "\006CA$1"}/ieg;
   $line =~ s/\006C([FB])(I[0-9A-F]|#[0-9A-F]{3})/{my $c = $cb->($1, $2); defined $c ? $c : "\006C$1$2"}/ieg;
   $line =~ s/\006CX([AFB])/{my $c = $cb->($1); defined $c ? $c : "\006CX$1"}/ieg;
   return $line;
}

=item B<split_prefix ($prefix)>

This function splits an IRC user prefix as described by RFC 2817
into the three parts: nickname, user and host. Which will be
returned as a list with that order.

C<$prefix> can also be a hash like it is returned by C<parse_irc_msg>.

=cut

sub split_prefix {
   my ($prfx) = @_;

   if (ref ($prfx) eq 'HASH') {
      $prfx = $prfx->{prefix};
   }

   # this splitting does indeed use the servername as nickname, but there
   # is no way for a client to distinguish.
   $prfx =~ m/^\s*([^!]*)(?:!([^@]*))?(?:@(.*?))?\s*$/;
   return ($1, $2, $3);
}

=item B<prefix_nick ($prefix)>

A shortcut to extract the nickname from the C<$prefix>.

C<$prefix> can also be a hash like it is returned by C<parse_irc_msg>.

=cut

sub prefix_nick {
   my ($prfx) = @_;
   return (split_prefix ($prfx))[0];
}

=item B<prefix_user ($prefix)>

A shortcut to extract the username from the C<$prefix>.

C<$prefix> can also be a hash like it is returned by C<parse_irc_msg>.

=cut

sub prefix_user {
   my ($prfx) = @_;
   return (split_prefix ($prfx))[1];
}

=item B<prefix_host ($prefix)>

A shortcut to extract the hostname from the C<$prefix>.

C<$prefix> can also be a hash like it is returned by C<parse_irc_msg>.

=cut

sub prefix_host {
   my ($prfx) = @_;
   return (split_prefix ($prfx))[2];
}


=item B<rfc_code_to_name ($code)>

This function is a interface to the internal mapping or numeric
replies to the reply name in RFC 2812 (which you may also consult).

C<$code> is returned if no name for C<$code> exists
(as some server may extended the protocol).

=back

=cut

our %RFC_NUMCODE_MAP = (
   '001' => 'RPL_WELCOME',
   '002' => 'RPL_YOURHOST',
   '003' => 'RPL_CREATED',
   '004' => 'RPL_MYINFO',
   '005' => 'RPL_BOUNCE',
   '200' => 'RPL_TRACELINK',
   '201' => 'RPL_TRACECONNECTING',
   '202' => 'RPL_TRACEHANDSHAKE',
   '203' => 'RPL_TRACEUNKNOWN',
   '204' => 'RPL_TRACEOPERATOR',
   '205' => 'RPL_TRACEUSER',
   '206' => 'RPL_TRACESERVER',
   '207' => 'RPL_TRACESERVICE',
   '208' => 'RPL_TRACENEWTYPE',
   '209' => 'RPL_TRACECLASS',
   '210' => 'RPL_TRACERECONNECT',
   '211' => 'RPL_STATSLINKINFO',
   '212' => 'RPL_STATSCOMMANDS',
   '219' => 'RPL_ENDOFSTATS',
   '221' => 'RPL_UMODEIS',
   '233' => 'RPL_SERVICE',
   '234' => 'RPL_SERVLIST',
   '235' => 'RPL_SERVLISTEND',
   '242' => 'RPL_STATSUPTIME',
   '243' => 'RPL_STATSOLINE',
   '250' => 'RPL_STATSDLINE',
   '251' => 'RPL_LUSERCLIENT',
   '252' => 'RPL_LUSEROP',
   '253' => 'RPL_LUSERUNKNOWN',
   '254' => 'RPL_LUSERCHANNELS',
   '255' => 'RPL_LUSERME',
   '256' => 'RPL_ADMINME',
   '257' => 'RPL_ADMINLOC1',
   '258' => 'RPL_ADMINLOC2',
   '259' => 'RPL_ADMINEMAIL',
   '261' => 'RPL_TRACELOG',
   '262' => 'RPL_TRACEEND',
   '263' => 'RPL_TRYAGAIN',
   '301' => 'RPL_AWAY',
   '302' => 'RPL_USERHOST',
   '303' => 'RPL_ISON',
   '305' => 'RPL_UNAWAY',
   '306' => 'RPL_NOWAWAY',
   '311' => 'RPL_WHOISUSER',
   '312' => 'RPL_WHOISSERVER',
   '313' => 'RPL_WHOISOPERATOR',
   '314' => 'RPL_WHOWASUSER',
   '315' => 'RPL_ENDOFWHO',
   '317' => 'RPL_WHOISIDLE',
   '318' => 'RPL_ENDOFWHOIS',
   '319' => 'RPL_WHOISCHANNELS',
   '321' => 'RPL_LISTSTART',
   '322' => 'RPL_LIST',
   '323' => 'RPL_LISTEND',
   '324' => 'RPL_CHANNELMODEIS',
   '325' => 'RPL_UNIQOPIS',
   '331' => 'RPL_NOTOPIC',
   '332' => 'RPL_TOPIC',
   '341' => 'RPL_INVITING',
   '342' => 'RPL_SUMMONING',
   '346' => 'RPL_INVITELIST',
   '347' => 'RPL_ENDOFINVITELIST',
   '348' => 'RPL_EXCEPTLIST',
   '349' => 'RPL_ENDOFEXCEPTLIST',
   '351' => 'RPL_VERSION',
   '352' => 'RPL_WHOREPLY',
   '353' => 'RPL_NAMREPLY',
   '364' => 'RPL_LINKS',
   '365' => 'RPL_ENDOFLINKS',
   '366' => 'RPL_ENDOFNAMES',
   '367' => 'RPL_BANLIST',
   '368' => 'RPL_ENDOFBANLIST',
   '369' => 'RPL_ENDOFWHOWAS',
   '371' => 'RPL_INFO',
   '372' => 'RPL_MOTD',
   '374' => 'RPL_ENDOFINFO',
   '375' => 'RPL_MOTDSTART',
   '376' => 'RPL_ENDOFMOTD',
   '381' => 'RPL_YOUREOPER',
   '382' => 'RPL_REHASHING',
   '383' => 'RPL_YOURESERVICE',
   '384' => 'RPL_MYPORTIS',
   '391' => 'RPL_TIME',
   '392' => 'RPL_USERSSTART',
   '393' => 'RPL_USERS',
   '394' => 'RPL_ENDOFUSERS',
   '395' => 'RPL_NOUSERS',
   '401' => 'ERR_NOSUCHNICK',
   '402' => 'ERR_NOSUCHSERVER',
   '403' => 'ERR_NOSUCHCHANNEL',
   '404' => 'ERR_CANNOTSENDTOCHAN',
   '405' => 'ERR_TOOMANYCHANNELS',
   '406' => 'ERR_WASNOSUCHNICK',
   '407' => 'ERR_TOOMANYTARGETS',
   '408' => 'ERR_NOSUCHSERVICE',
   '409' => 'ERR_NOORIGIN',
   '411' => 'ERR_NORECIPIENT',
   '412' => 'ERR_NOTEXTTOSEND',
   '413' => 'ERR_NOTOPLEVEL',
   '414' => 'ERR_WILDTOPLEVEL',
   '415' => 'ERR_BADMASK',
   '421' => 'ERR_UNKNOWNCOMMAND',
   '422' => 'ERR_NOMOTD',
   '423' => 'ERR_NOADMININFO',
   '424' => 'ERR_FILEERROR',
   '431' => 'ERR_NONICKNAMEGIVEN',
   '432' => 'ERR_ERRONEUSNICKNAME',
   '433' => 'ERR_NICKNAMEINUSE',
   '436' => 'ERR_NICKCOLLISION',
   '437' => 'ERR_UNAVAILRESOURCE',
   '441' => 'ERR_USERNOTINCHANNEL',
   '442' => 'ERR_NOTONCHANNEL',
   '443' => 'ERR_USERONCHANNEL',
   '444' => 'ERR_NOLOGIN',
   '445' => 'ERR_SUMMONDISABLED',
   '446' => 'ERR_USERSDISABLED',
   '451' => 'ERR_NOTREGISTERED',
   '461' => 'ERR_NEEDMOREPARAMS',
   '462' => 'ERR_ALREADYREGISTRED',
   '463' => 'ERR_NOPERMFORHOST',
   '464' => 'ERR_PASSWDMISMATCH',
   '465' => 'ERR_YOUREBANNEDCREEP',
   '466' => 'ERR_YOUWILLBEBANNED',
   '467' => 'ERR_KEYSET',
   '471' => 'ERR_CHANNELISFULL',
   '472' => 'ERR_UNKNOWNMODE',
   '473' => 'ERR_INVITEONLYCHAN',
   '474' => 'ERR_BANNEDFROMCHAN',
   '475' => 'ERR_BADCHANNELKEY',
   '476' => 'ERR_BADCHANMASK',
   '477' => 'ERR_NOCHANMODES',
   '478' => 'ERR_BANLISTFULL',
   '481' => 'ERR_NOPRIVILEGES',
   '482' => 'ERR_CHANOPRIVSNEEDED',
   '483' => 'ERR_CANTKILLSERVER',
   '484' => 'ERR_RESTRICTED',
   '485' => 'ERR_UNIQOPPRIVSNEEDED',
   '491' => 'ERR_NOOPERHOST',
   '492' => 'ERR_NOSERVICEHOST',
   '501' => 'ERR_UMODEUNKNOWNFLAG',
   '502' => 'ERR_USERSDONTMATCH',
);

sub rfc_code_to_name {
   my ($code) = @_;
   return $RFC_NUMCODE_MAP{$code} || $code;
}

=head1 AUTHOR

Robin Redeker, C<< <elmex@ta-sa.org> >>

=head1 SEE ALSO

Internet Relay Chat Client To Client Protocol from February 2, 1997
http://www.invlogic.com/irc/ctcp.html

RFC 2812 - Internet Relay Chat: Client Protocol

=head1 COPYRIGHT & LICENSE

Copyright 2006 Robin Redeker, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

1;
