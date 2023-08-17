package Net::Bot::IRC::NumericCodes;

use strict;
use warnings;

use Carp;

=head1 NAME

Net::Bot::IRC::NumericCodes - A module for abstracting IRC numeric codes.

=head1 VERSION

Version 1.0.0

=cut

our $VERSION = '1.0.0';

=head1 SYNOPSIS

    use Net::Bot::IRC::NumericCodes;

    my $nc = IRC::NumericCodes->new();

    # Lookup the numeric based on the code string.
    if ($code == $nc->str2num("RPL_WELCOME")) {
        # Do something.
    }

    # Look up the code string based on the numeric code.
    if ($strcode eq $nc->num2str(001)) {
        # Do some other stuff.
    }

For a full list of codes please read L<< http://tools.ietf.org/html/rfc2812 >>.

=head1 FUNCTIONS

=head2 new()

=cut

sub new {
    my $class = shift;
    my $self  = {};

    # Numeric codes as defined in RFC 2812
    $self->{_messages}->{RPL_WELCOME}            = 001;
    $self->{_messages}->{RPL_YOURHOST}           = 002;
    $self->{_messages}->{RPL_CREATED}            = 003;
    $self->{_messages}->{RPL_MYINFO}             = 004;
    $self->{_messages}->{RPL_BOUNCE}             = 005;
    $self->{_messages}->{RPL_TRACELINK}          = 200;
    $self->{_messages}->{RPL_TRACECONNECTING}    = 201;
    $self->{_messages}->{RPL_TRACEHANDSHAKE}     = 202;
    $self->{_messages}->{RPL_TRACEUNKNOWN}       = 203;
    $self->{_messages}->{RPL_TRACEOPERATOR}      = 204;
    $self->{_messages}->{RPL_TRACEUSER}          = 205;
    $self->{_messages}->{RPL_TRACESERVER}        = 206;
    $self->{_messages}->{RPL_TRACESERVICE}       = 207;
    $self->{_messages}->{RPL_TRACENEWTYPE}       = 208;
    $self->{_messages}->{RPL_TRACECLASS}         = 209;
    $self->{_messages}->{RPL_TRACERECONNECT}     = 210;
    $self->{_messages}->{RPL_STATSLINKINFO}      = 211;
    $self->{_messages}->{RPL_STATSCOMMANDS}      = 212;
    $self->{_messages}->{RPL_STATSCLINE}         = 213;
    $self->{_messages}->{RPL_STATSNLINE}         = 214;
    $self->{_messages}->{RPL_STATSILINE}         = 215;
    $self->{_messages}->{RPL_STATSKLINE}         = 216;
    $self->{_messages}->{RPL_STATSQLINE}         = 217;
    $self->{_messages}->{RPL_STATSYLINE}         = 218;
    $self->{_messages}->{RPL_ENDOFSTATS}         = 219;
    $self->{_messages}->{RPL_UMODEIS}            = 221;
    $self->{_messages}->{RPL_SERVICEINFO}        = 231;
    $self->{_messages}->{RPL_ENDOFSERVICES}      = 232;
    $self->{_messages}->{RPL_SERVICE}            = 233;
    $self->{_messages}->{RPL_SERVLIST}           = 234;
    $self->{_messages}->{RPL_SERVLISTEND}        = 235;
    $self->{_messages}->{RPL_STATSVLINE}         = 240;
    $self->{_messages}->{RPL_STATSLLINE}         = 241;
    $self->{_messages}->{RPL_STATSUPTIME}        = 242;
    $self->{_messages}->{RPL_STATSOLINE}         = 243;
    $self->{_messages}->{RPL_STATSHLINE}         = 244;
    $self->{_messages}->{RPL_STATSSLINE}         = 244;
    $self->{_messages}->{RPL_STATSPING}          = 246;
    $self->{_messages}->{RPL_STATSBLINE}         = 247;
    $self->{_messages}->{RPL_STATSDLINE}         = 250;
    $self->{_messages}->{RPL_LUSERCLIENT}        = 251;
    $self->{_messages}->{RPL_LUSEROP}            = 252;
    $self->{_messages}->{RPL_LUSERUNKNOWN}       = 253;
    $self->{_messages}->{RPL_LUSERCHANNELS}      = 254;
    $self->{_messages}->{RPL_LUSERME}            = 255;
    $self->{_messages}->{RPL_ADMINME}            = 256;
    $self->{_messages}->{RPL_ADMINLOC1}          = 257;
    $self->{_messages}->{RPL_ADMINLOC2}          = 258;
    $self->{_messages}->{RPL_ADMINEMAIL}         = 259;
    $self->{_messages}->{RPL_TRACELOG}           = 261;
    $self->{_messages}->{RPL_TRACEEND}           = 262;
    $self->{_messages}->{RPL_TRYAGAIN}           = 263;
    $self->{_messages}->{RPL_NONE}               = 300;
    $self->{_messages}->{RPL_AWAY}               = 301;
    $self->{_messages}->{RPL_USERHOST}           = 302;
    $self->{_messages}->{RPL_ISON}               = 303;
    $self->{_messages}->{RPL_UNAWAY}             = 305;
    $self->{_messages}->{RPL_NOWAWAY}            = 306;
    $self->{_messages}->{RPL_WHOISUSER}          = 311;
    $self->{_messages}->{RPL_WHOISSERVER}        = 312;
    $self->{_messages}->{RPL_WHOISOPERATOR}      = 313;
    $self->{_messages}->{RPL_WHOWASUSER}         = 314;
    $self->{_messages}->{RPL_ENDOFWHO}           = 315;
    $self->{_messages}->{RPL_WHOISCHANOP}        = 316;
    $self->{_messages}->{RPL_WHOISIDLE}          = 317;
    $self->{_messages}->{RPL_ENDOFWHOIS}         = 318;
    $self->{_messages}->{RPL_WHOISCHANNELS}      = 319;
    $self->{_messages}->{RPL_LISTSTART}          = 321;
    $self->{_messages}->{RPL_LIST}               = 322;
    $self->{_messages}->{RPL_LISTEND}            = 323;
    $self->{_messages}->{RPL_CHANNELMODEIS}      = 324;
    $self->{_messages}->{RPL_UNIQOPIS}           = 325;
    $self->{_messages}->{RPL_NOTOPIC}            = 331;
    $self->{_messages}->{RPL_TOPIC}              = 332;
    $self->{_messages}->{RPL_INVITING}           = 341;
    $self->{_messages}->{RPL_SUMMONING}          = 342;
    $self->{_messages}->{RPL_INVITELIST}         = 346;
    $self->{_messages}->{RPL_ENDOFINVITELIST}    = 347;
    $self->{_messages}->{RPL_EXCEPTLIST}         = 348;
    $self->{_messages}->{RPL_ENDOFEXCEPTLIST}    = 349;
    $self->{_messages}->{RPL_VERSION}            = 351;
    $self->{_messages}->{RPL_WHOREPLY}           = 352;
    $self->{_messages}->{RPL_NAMREPLY}           = 353;
    $self->{_messages}->{RPL_KILLDONE}           = 361;
    $self->{_messages}->{RPL_CLOSING}            = 362;
    $self->{_messages}->{RPL_CLOSEEND}           = 363;
    $self->{_messages}->{RPL_LINKS}              = 364;
    $self->{_messages}->{RPL_ENDOFLINKS}         = 365;
    $self->{_messages}->{RPL_ENDOFNAMES}         = 366;
    $self->{_messages}->{RPL_BANLIST}            = 367;
    $self->{_messages}->{RPL_ENDOFBANLIST}       = 368;
    $self->{_messages}->{RPL_ENDOFWHOWAS}        = 369;
    $self->{_messages}->{RPL_INFO}               = 371;
    $self->{_messages}->{RPL_MOTD}               = 372;
    $self->{_messages}->{RPL_INFOSTART}          = 373;
    $self->{_messages}->{RPL_ENDOFINFO}          = 374;
    $self->{_messages}->{RPL_MOTDSTART}          = 375;
    $self->{_messages}->{RPL_ENDOFMOTD}          = 376;
    $self->{_messages}->{RPL_YOUREOPER}          = 381;
    $self->{_messages}->{RPL_REHASHING}          = 382;
    $self->{_messages}->{RPL_YOURESERVICE}       = 383;
    $self->{_messages}->{RPL_MYPORTIS}           = 384;
    $self->{_messages}->{RPL_TIME}               = 391;
    $self->{_messages}->{RPL_USERSSTART}         = 392;
    $self->{_messages}->{RPL_USERS}              = 393;
    $self->{_messages}->{RPL_ENDOFUSERS}         = 394;
    $self->{_messages}->{RPL_NOUSERS}            = 395;

    bless $self, $class;
    return $self;
}

=head2 num2str($numericCode)

=cut

sub num2str {
    my $self = shift;
    my $num  = shift;

    if (! $num) {
        croak "No number was passed as an argument.";
    }

    # Iterate through and try to find the corresponding string.
    foreach my $str (keys(%{ $self->{_messages} })) {
        if ($self->{_messages}->{$str} == $num) {
            return $str;
        }
    }

    # If we get here then we couldn't resolve the numeric code.
    croak "Unable to resolve numeric: $num.";
}

=head2 str2num($strCode)

=cut

sub str2num {
    my $self = shift;
    my $str  = shift;

    if (! $str) {
        croak "No string was passed as an argument.";
    }

    if (exists $self->{_messages}->{$str}) {
        return $self->{_messages}->{$str};
    }
    else {
        croak "Unable to resolve the numeric code for \"$str\".";
    }
}

=head1 AUTHOR

Caudill, Mark, L<< mailto:mcaudillATcpan.org >>

=head1 BUGS

Please report any bugs or feature requests to the maintainer.


=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Net::Bot::IRC::NumericCodes

=head1 DEVELOPMENT

You can find the current sources for this at L<< git://github.com/markcaudill/Net-Bot-IRC-NumericCodes.git >>.

=head1 COPYRIGHT & LICENSE

Copyright 2023 Caudill, Mark.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.


=cut

1; # End of Net::Bot::IRC::NumericCodes.
