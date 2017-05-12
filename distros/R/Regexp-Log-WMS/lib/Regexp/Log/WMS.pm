package Regexp::Log::WMS;

use strict;
use base qw( Regexp::Log );
use vars qw( $VERSION %DEFAULT %FORMAT %REGEXP );

$VERSION = 0.02;


=head1 NAME

Regexp::Log::WMS - A regular expression parser for WMS
log format.

=head1 SYNOPSIS

    my $foo = Regexp::Log::Common->new(
        format  => 'custom %date %cs_uri_stem',
        capture => [qw( date request )],
    );

    # the format() and capture() methods can be used to set or get
    $foo->format('custom %date %cs_uri_stem %c_rate %c_status');
    $foo->capture(qw( date cs_uri_stem ));

    # this is necessary to know in which order
    # we will receive the captured fields from the regexp
    my @fields = $foo->capture;

    # the all-powerful capturing regexp :-)
    my $re = $foo->regexp;

    while (<>) {
        my %data;
        @data{@fields} = /$re/;    # no need for /o, it's a compiled regexp

        # now munge the fields
        ...
    }

=head1 DESCRIPTION

Regexp::Log::WMS uses Regexp::Log as a base class, to generate regular
expressions for performing the usual data munging tasks on log files that
cannot be simply split().

This specific module enables the computation of regular expressions for
parsing the log files created by WMS.

For more information on how to use this module, please see Regexp::Log.

=head1 ABSTRACT

Regexp::Log::WMS enables simple parsing of log files created by WMS.

=cut


# default values
%DEFAULT = ( format => ( '%c_ip %date %c_dns %cs_uri_stem %c_starttime '.
			 '%x_duration %c_rate %c_status %c_playerid %c_playerversion '.
			 '%c_playerlanguage %cs_user_agent %cs_referer %c_hostexe '.
			 '%c_hostexever %c_os %c_osversion %c_cpu %filelength %filesize '.
			 '%avgbandwidth %protocol %transport %audiocodec %videocodec '.
			 '%channelURL %sc_bytes %c_bytes %s_pkts_sent %c_pkts_received '.
			 '%c_pkts_lost_client %c_pkts_lost_net %c_pkts_lost_cont_net '.
			 '%c_resendreqs %c_pkts_recovered_ECC %c_pkts_recovered_resent '.
			 '%c_buffercount %c_totalbuffertime %c_quality %s_ip %s_dns '.
			 '%s_totalclients %s_cpu_util'),

	    capture => [qw(c_ip date c_dns cs_uri_stem
			   c_starttime x_duration c_rate c_status c_playerid
			   c_playerversion c_playerlanguage cs_user_agent cs_referer
			   c_hostexe c_hostexever c_os c_osversion c_cpu filelength
			   filesize avgbandwidth protocol transport audiocodec
			   videocodec channelURL sc_bytes c_bytes s_pkts_sent
			   c_pkts_received c_pkts_lost_client c_pkts_lost_net
			   c_pkts_lost_cont_net c_resendreqs c_pkts_recovered_ECC
			   c_pkts_recovered_resent c_buffercount c_totalbuffertime
			   c_quality s_ip s_dns s_totalclients s_cpu_util)] );


# predefined format strings
%FORMAT = (
	':default'  => $DEFAULT{format},
	':common'   => $DEFAULT{format},
);

# the regexps that match the various fields
%REGEXP = ( '%c_ip' => '(?#=c_ip)\S+(?#!c_ip)',
	    '%date' => '(?#=date)\d{4}-\d{2}-\d{2} \d{2}:\d{2}:\d{2}(?#!date)',
	    '%c_dns' => '(?#=c_dns).*?(?#!c_dns)',
	    '%cs_uri_stem' => '(?#=cs_uri_stem).*?(?#!cs_uri_stem)',
	    '%c_starttime' => '(?#=c_starttime).*?(?#!c_starttime)',
	    '%x_duration' => '(?#=x_duration).*?(?#!x_duration)',
	    '%c_rate' => '(?#=c_rate).*?(?#!c_rate)',
	    '%c_status' => '(?#=c_status).*?(?#!c_status)',
	    '%c_playerid' => '(?#=c_playerid).*?(?#!c_playerid)',
	    '%c_playerversion' => '(?#=c_playerversion).*?(?#!c_playerversion)',
	    '%c_playerlanguage' => '(?#=c_playerlanguage).*?(?#!c_playerlanguage)',
	    '%cs_user_agent' => '(?#=cs_user_agent).*?(?#!cs_user_agent)',
	    '%cs_referer' => '(?#=cs_referer).*?(?#!cs_referer)',
	    '%c_hostexe' => '(?#=c_hostexe).*?(?#!c_hostexe)',
	    '%c_hostexever' => '(?#=c_hostexever).*?(?#!c_hostexever)',
	    '%c_os' => '(?#=c_os).*?(?#!c_os)',
	    '%c_osversion' => '(?#=c_osversion).*?(?#!c_osversion)',
	    '%c_cpu' => '(?#=c_cpu).*?(?#!c_cpu)',
	    '%filelength' => '(?#=filelength).*?(?#!filelength)',
	    '%filesize' => '(?#=filesize).*?(?#!filesize)',
	    '%avgbandwidth' => '(?#=avgbandwidth).*?(?#!avgbandwidth)',
	    '%protocol' => '(?#=protocol).*?(?#!protocol)',
	    '%transport' => '(?#=transport).*?(?#!transport)',
	    '%audiocodec' => '(?#=audiocodec).*?(?#!audiocodec)',
	    '%videocodec' => '(?#=videocodec).*?(?#!videocodec)',
	    '%channelURL' => '(?#=channelURL).*?(?#!channelURL)',
	    '%sc_bytes' => '(?#=sc_bytes).*?(?#!sc_bytes)',
	    '%c_bytes' => '(?#=c_bytes).*?(?#!c_bytes)',
	    '%s_pkts_sent' => '(?#=s_pkts_sent).*?(?#!s_pkts_sent)',
	    '%c_pkts_received' => '(?#=c_pkts_received).*?(?#!c_pkts_received)',
	    '%c_pkts_lost_client' => '(?#=c_pkts_lost_client).*?(?#!c_pkts_lost_client)',
	    '%c_pkts_lost_net' => '(?#=c_pkts_lost_net).*?(?#!c_pkts_lost_net)',
	    '%c_pkts_lost_cont_net' => '(?#=c_pkts_lost_cont_net).*?(?#!c_pkts_lost_cont_net)',
	    '%c_resendreqs' => '(?#=c_resendreqs).*?(?#!c_resendreqs)',
	    '%c_pkts_recovered_ECC' => '(?#=c_pkts_recovered_ECC).*?(?#!c_pkts_recovered_ECC)',
	    '%c_pkts_recovered_resent' => '(?#=c_pkts_recovered_resent).*?(?#!c_pkts_recovered_resent)',
	    '%c_buffercount' => '(?#=c_buffercount).*?(?#!c_buffercount)',
	    '%c_totalbuffertime' => '(?#=c_totalbuffertime).*?(?#!c_totalbuffertime)',
	    '%c_quality' => '(?#=c_quality).*?(?#!c_quality)',
	    '%s_ip' => '(?#=s_ip).*?(?#!s_ip)',
	    '%s_dns' => '(?#=s_dns).*?(?#!s_dns)',
	    '%s_totalclients' => '(?#=s_totalclients).*?(?#!s_totalclients)',
	    '%s_cpu_util' => '(?#=s_cpu_util).*?(?#!s_cpu_util)' );


1;

__END__

=head1 LOG FORMAT

=head2 WMS Log Format

    my $foo = Regexp::Log::WMS->new( format  => ':common' );

The WMS Log Format is made up of several fields, each delimited by a single
space.

=over 4

=item * Fields:

  c_ip date c_dns cs_uri_stem c_starttime x_duration c_rate c_status
  c_playerid c_playerversion c_playerlanguage cs_user_agent cs_referer
  c_hostexe c_hostexever c_os c_osversion c_cpu filelength filesize
  avgbandwidth protocol transport audiocodec videocodec channelURL
  sc_bytes c_bytes s_pkts_sent c_pkts_received c_pkts_lost_client
  c_pkts_lost_net c_pkts_lost_cont_net c_resendreqs
  c_pkts_recovered_ECC c_pkts_recovered_resent c_buffercount
  c_totalbuffertime c_quality s_ip s_dns s_totalclients s_cpu_util

=back

=head1 BUGS, PATCHES & FIXES

This is a very early release of this module, so maybe you will find
some bugs there, report them to me (including a patch if possible) and I
will try to correct it as soon as possible.

The regular expresions generated are not specially efficient.


=head1 SEE ALSO

L<Regexp::Log>, L<Regexp::Log::Common>, L<Regexp::Log::RealServer>


=head1 AUTHOR

Salvador FandiE<ntilde>o E<lt>sfandino@yahoo.comE<gt>.

Based on Regexp::Log::Common by Barbie E<lt>barbie@cpan.orgE<gt>


=head1 COPYRIGHT AND LICENSE

Copyrigth (c) 2005 by Salvador FandiE<ntilde>o. All rights reserved.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

