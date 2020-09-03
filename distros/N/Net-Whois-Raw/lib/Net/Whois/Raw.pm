package Net::Whois::Raw;
$Net::Whois::Raw::VERSION = '2.99031';
# ABSTRACT: Get Whois information of domains and IP addresses.

require 5.008_001;
use Net::Whois::Raw::Common ();
use Net::Whois::Raw::Data ();

use warnings;
use strict;

use Carp;
use IO::Socket::IP;
use Encode;
use utf8;

our @EXPORT = qw( whois get_whois );

our ($OMIT_MSG, $CHECK_FAIL, $CHECK_EXCEED, $CACHE_DIR, $TIMEOUT, $DEBUG) = (0) x 7;

our $CACHE_TIME = 60;
our $SET_CODEPAGE = '';
our $SILENT_MODE = 0;
our $QUERY_SUFFIX = '';

our (%notfound, %strip, @SRC_IPS, %POSTPROCESS);

# internal variable, used for save whois_server->ip relations
my $_IPS = {};

our $class = __PACKAGE__;

my $last_cache_clear_time;

sub whois_config {
    my ($par) = @_;
    my @parnames = qw(OMIT_MSG CHECK_FAIL CHECK_EXCEED CACHE_DIR CACHE_TIME TIMEOUT @SRC_IPS);
    foreach my $parname (@parnames) {
        if (exists($par->{$parname})) {
            no strict 'refs';
            ${$parname} = $par->{$parname};
        }
    }
}

sub whois_config_data {
    my $net_whois_raw_data = shift;

    no strict 'refs';

    foreach my $k (keys %$net_whois_raw_data) {
        %{'Net::Whois::Raw::Data::'.$k} = (
            %{'Net::Whois::Raw::Data::'.$k},
            %{ $net_whois_raw_data->{ $k } || {} },
        );
    }
}

# get cached whois
sub whois {
    my ($dom, $server, $which_whois) = @_;

    $which_whois ||= 'QRY_LAST';

    my $res = Net::Whois::Raw::Common::get_from_cache( "$dom-$which_whois", $CACHE_DIR, $CACHE_TIME );

    my ($res_text, $res_srv, $res_text2);

    if ($res) {
        if ($which_whois eq 'QRY_FIRST') {
            $res_text = $res->[0]->{text};
            $res_srv  = $res->[0]->{srv};
        } elsif ($which_whois eq 'QRY_LAST' || !defined($which_whois)) {
            $res_text = $res->[-1]->{text};
            $res_srv  = $res->[-1]->{srv};
        } elsif ($which_whois eq 'QRY_ALL') {
            return $res;
        }  
    }
    else {
        ($res_text, $res_srv) = get_whois($dom, $server, $which_whois);
    }

    $res_srv = '' if $res_srv && $res_srv eq 'www_whois';

    if ( defined $res_text && $which_whois ne 'QRY_ALL' ) {
        utf8::decode( $res_text ); # Perl whyly loss utf8 flag

        $res_text = encode( $SET_CODEPAGE, $res_text ) if $SET_CODEPAGE;
    }

    return wantarray ? ($res_text, $res_srv) : $res_text;
}

# obtain whois
sub get_whois {
    my ($dom, $srv, $which_whois) = @_;
    $which_whois ||= 'QRY_LAST';

    my $whois = get_all_whois( $dom, $srv, $which_whois eq 'QRY_FIRST' )
        or return undef;

    Net::Whois::Raw::Common::write_to_cache( "$dom-$which_whois", $whois, $CACHE_DIR );

    if ($which_whois eq 'QRY_LAST') {
        my $thewhois = $whois->[-1];
        return wantarray ? ($thewhois->{text}, $thewhois->{srv}) : $thewhois->{text};
    }
    elsif ($which_whois eq 'QRY_FIRST') {
        my $thewhois = $whois->[0];
        return wantarray ? ($thewhois->{text}, $thewhois->{srv}) : $thewhois->{text};
    }
    else {
        return $whois;
    }
}

sub get_all_whois {
    my ($dom, $srv, $norecurse) = @_;

    my $is_ns = 0;
    $is_ns = 1  if $dom =~ s/[.]NS$//i;

    $srv ||= Net::Whois::Raw::Common::get_server( $dom, $is_ns );

    if ($srv eq 'www_whois') {
        my ($responce, $ishtml) = www_whois_query( $dom );
        return $responce ? [ { text => $responce, srv => $srv } ] : $responce;
    }

    my @whois = recursive_whois( $dom, $srv, [], $norecurse, $is_ns );

    my $whois_answers = process_whois_answers( \@whois, $dom );

    return $whois_answers;
}

sub process_whois_answers {
    my ( $raw_whois, $dom ) = @_;

    my @processed_whois;

    my $level = 0;
    for my $whois_rec ( @$raw_whois ) {
        $whois_rec->{level} = $level;
        my ( $text, $error ) = Net::Whois::Raw::Common::process_whois(
            $dom,
            $whois_rec->{srv},
            $whois_rec->{text},
            $CHECK_FAIL, $OMIT_MSG, $CHECK_EXCEED,
        );

        die $error  if $error && $error eq 'Connection rate exceeded'
            && ( $level == 0 || $CHECK_EXCEED == 2 );

        if ( $text || $level == 0 ) {
            $whois_rec->{text} = $text;
            push @processed_whois, $whois_rec;
        }
        $level++;
    }

    return \@processed_whois;
}

sub _referral_server {
    /ReferralServer:\s*r?whois:\/\/([-.\w]+(?:\:\d+)?)/
}

sub recursive_whois {
    my ( $dom, $srv, $was_srv, $norecurse, $is_ns ) = @_;

    my $lines = whois_query( $dom, $srv, $is_ns );
    my $whois = join '', @$lines;

    my ( $newsrv, $registrar );
    for ( @$lines ) {
        $registrar ||= /Registrar/ || /Registered through/;

        # Skip urls as recursive whois servers
        if ( $registrar && !$norecurse && /whois server:\s*([a-z0-9\-_\.]+)\b/i ) {
            $newsrv = lc $1;
        }
        elsif ( $whois =~ /To single out one record, look it up with \"xxx\",/s ) {
            return recursive_whois( "=$dom", $srv, $was_srv );
        }
        elsif ( !$norecurse && ( my ( $rs ) = _referral_server() ) ) {
            $newsrv = $rs;
            last;
        }
        elsif ( /Contact information can be found in the (\S+)\s+database/ ) {
            $newsrv = $Net::Whois::Raw::Data::ip_whois_servers{ $1 };
        }
        elsif ( ( /OrgID:\s+(\w+)/ || /descr:\s+(\w+)/ ) && Net::Whois::Raw::Common::is_ipaddr( $dom ) ) {
            my $val = $1;
            if ( $val =~ /^(?:RIPE|APNIC|KRNIC|LACNIC)$/ ) {
                $newsrv = $Net::Whois::Raw::Data::ip_whois_servers{ $val };
                last;
            }
        }
        elsif ( /^\s+Maintainer:\s+RIPE\b/ && Net::Whois::Raw::Common::is_ipaddr( $dom ) ) {
            $newsrv = $Net::Whois::Raw::Data::servers{RIPE};
        }
        elsif ( $is_ns && $srv ne $Net::Whois::Raw::Data::servers{NS} ) {
            $newsrv = $Net::Whois::Raw::Data::servers{NS};
        }
    }

    if (
        defined $newsrv && (
            # Bypass recursing to custom servers
            $Net::Whois::Raw::Data::whois_servers_no_recurse{ $newsrv }
            # Bypass recursing to WHOIS servers with no IDN support
            || $dom =~ /^xn--/i && $newsrv && $Net::Whois::Raw::Data::whois_servers_with_no_idn_support{ $newsrv }
        )
    ) {
        $newsrv = undef;
    }

    my @whois_recs = ( { text => $whois, srv => $srv } );
    if ( $newsrv && $newsrv ne $srv ) {
        warn "recurse to $newsrv\n" if $DEBUG;

        return () if grep { $_ eq $newsrv } @$was_srv;

        my @new_whois_recs = eval { recursive_whois( $dom, $newsrv, [ @$was_srv, $srv ], 0, $is_ns ) };
        my $new_whois = scalar @new_whois_recs ? $new_whois_recs[0]->{text} : '';
        my $notfound = $Net::Whois::Raw::Data::notfound{ $newsrv };

        if ( $new_whois && !$@ && not ( $notfound && $new_whois =~ /$notfound/im ) ) {
            if ( $is_ns ) {
                unshift @whois_recs, @new_whois_recs;
            }
            else {
                push @whois_recs, @new_whois_recs;
            }
        }
        else {
            warn "recursive query failed\n" if $DEBUG;
        }
    }

    return @whois_recs;
}

sub whois_query {
    my ($dom, $srv, $is_ns) = @_;

    # Prepare query
    my $whoisquery = Net::Whois::Raw::Common::get_real_whois_query($dom, $srv, $is_ns);

    # Prepare for query

    my (@sockparams, $sock);
    my (undef, $tld) = Net::Whois::Raw::Common::split_domain($dom);

    $tld = uc $tld;
    my $rotate_reference = undef;

    ### get server for query
    my $server4query = Net::Whois::Raw::Common::get_server($dom);

    if ( Net::Whois::Raw::Common::is_ip6addr( $srv ) ) {
        $srv = "[$srv]";
    }

    my $srv_and_port = $srv =~ /\:\d+$/ ? $srv : "$srv:43";
    if ($class->can('whois_query_sockparams')) {
        @sockparams = $class->whois_query_sockparams ($dom, $srv);
    }
    # hook for outside defined socket
    elsif ($class->can('whois_query_socket')) {
        $sock = $class->whois_query_socket ($dom, $srv);
    }
    elsif (my $ips_arrayref = get_ips_for_query($server4query)) {
        $rotate_reference = $ips_arrayref;
    }
    elsif (scalar(@SRC_IPS)) {
        $rotate_reference = \@SRC_IPS;
    }
    else {
        @sockparams = $srv_and_port;
    }


    if ($rotate_reference) {
        my $src_ip = $rotate_reference->[0];
        push @$rotate_reference, shift @$rotate_reference; # rotate ips
        @sockparams = (PeerAddr => $srv_and_port, LocalAddr => $src_ip);
    }

    print "QUERY: $whoisquery; SRV: $srv, ".
            "OMIT_MSG: $OMIT_MSG, CHECK_FAIL: $CHECK_FAIL, CACHE_DIR: $CACHE_DIR, ".
            "CACHE_TIME: $CACHE_TIME, TIMEOUT: $TIMEOUT\n" if $DEBUG >= 2;

    my $prev_alarm = undef;
    my $t0 = time();

    my @lines;

    # Make query

    {
        local $SIG{'ALRM'} = sub { die "Connection timeout to $srv" };
        eval {

            $prev_alarm = alarm $TIMEOUT if $TIMEOUT;

            unless ( $sock ) {
                $sock = IO::Socket::IP->new( @sockparams )
                    or die "$srv: $!: " . join( ', ', @sockparams );
            }

            if ($class->can ('whois_socket_fixup')) {
                my $new_sock = $class->whois_socket_fixup ($sock);
                $sock = $new_sock if $new_sock;
            }

            if ($DEBUG > 2) {
                require Data::Dumper;
                print "Socket: ". Data::Dumper::Dumper($sock);
            }

            if ($QUERY_SUFFIX) {
                $whoisquery .= $QUERY_SUFFIX;
            }

            $sock->print( $whoisquery, "\r\n" );
            # TODO: $soc->read, parameters for read chunk size, max content length
            # Now you can redefine SOCK_CLASS::getline method as you want
            while (my $str = $sock->getline) {
                push @lines, $str;
            }
            $sock->close;
        };
        {
            local $@; # large code block below, so preserve previous exception.
            if (defined $prev_alarm) { # if we ever set new alarm
                if ($prev_alarm == 0) { # there was no alarm previously
                    alarm 0; # clear it
                } else { # there was an alarm previously
                    $prev_alarm -= (time()- $t0); # try best to substract time elapsed
                    $prev_alarm = 1 if $prev_alarm < 1; # we still need set it to something non-zero
                    alarm $prev_alarm; # set it
                }
            }
        }
        Carp::confess $@ if $@;
    }

    foreach (@lines) { s/\r//g; }

    print "Received ".scalar(@lines)." lines\n" if $DEBUG >= 2;

    return \@lines;
}

sub www_whois_query {
    my ($dom) = (lc shift);

    my ($resp, $url);
    my ($name, $tld) = Net::Whois::Raw::Common::split_domain( $dom );

    my $http_query_urls = Net::Whois::Raw::Common::get_http_query_url($dom);

    foreach my $qurl ( @{$http_query_urls} ) {

        # load-on-demand
        unless ($INC{'LWP/UserAgent.pm'}) {
            require LWP::UserAgent;
            require HTTP::Request;
            require HTTP::Headers;
            require URI::URL;
            import LWP::UserAgent;
            import HTTP::Request;
            import HTTP::Headers;
            import URI::URL;
        }

        my $referer = delete $qurl->{form}{referer} if $qurl->{form} && defined $qurl->{form}{referer};
        my $method = ( $qurl->{form} && scalar(keys %{$qurl->{form}}) ) ? 'POST' : 'GET';

    my $ua;

    # hook for outside defined lwp
    if ($class->can ('whois_query_ua')) {
        $ua = $class->whois_query_ua ($dom);
    }

    unless($ua){
        $ua = new LWP::UserAgent( parse_head => 0 );
        $ua->agent('Mozilla/5.0 (X11; U; Linux i686; ru; rv:1.9.0.5) Gecko/2008121622 Fedora/3.0.5-1.fc10 Firefox/3.0.5');
    }
        my $header = HTTP::Headers->new;
        $header->header('Referer' => $referer) if $referer;
        my $req = new HTTP::Request $method, $qurl->{url}, $header;

        if ($method eq 'POST') {
            require URI::URL;
            import URI::URL;

            my $curl = url("http:");
            $req->content_type('application/x-www-form-urlencoded');
            $curl->query_form( %{$qurl->{form}} );
            $req->content( $curl->equery );
        }

        $resp = eval {
            local $SIG{ALRM} = sub { die "www_whois connection timeout" };
            alarm 10;
            $ua->request($req)->content;
        };
        alarm 0;

        if ( !$resp || $@ || $resp =~ /www_whois connection timeout/ || $resp =~ /^500 Can\'t connect/ ) {
            undef $resp;
        }
        else {
            $url = $qurl->{url};
            last;
        }
    }

    return undef unless $resp;

    chomp $resp;
    $resp =~ s/\r//g;

    my $ishtml;

    $resp = Net::Whois::Raw::Common::parse_www_content($resp, $tld, $url, $CHECK_EXCEED);

    return wantarray ? ($resp, $ishtml) : $resp;
}


sub import {
    my $mypkg = shift;
    my $callpkg = caller;

    no strict 'refs';

    # export subs
    *{"$callpkg\::$_"} = \&{"$mypkg\::$_"} foreach ((@EXPORT, @_));
}


sub set_ips_for_server {
    my ($server, $ips) = @_;

    croak "Missing params" if (!$ips || !$server);

    $server = lc $server;
    $_IPS->{$server} = $ips;
}


sub get_ips_for_query {
    my ($server) = @_;

    $server = lc $server;
    if ($_IPS->{$server}) {
        return $_IPS->{$server};
    }
    return undef;
}


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Net::Whois::Raw - Get Whois information of domains and IP addresses.

=head1 VERSION

version 2.99031

=head1 SYNOPSIS

    use Net::Whois::Raw;

    $dominfo = whois('perl.com');
    ($dominfo, $whois_server) = whois('funet.fi');
    $reginfo = whois('REGRU-REG-RIPN', 'whois.ripn.net');

    $arrayref = get_whois('yahoo.co.uk', undef, 'QRY_ALL');
    $text = get_whois('yahoo.co.uk', undef, 'QRY_LAST');
    ($text, $srv) = get_whois('yahoo.co.uk', undef, 'QRY_FIRST');

    $Net::Whois::Raw::OMIT_MSG = 1;
        # This will attempt to strip several known copyright
        # messages and disclaimers sorted by servers.
        # Default is to give the whole response.

    $Net::Whois::Raw::CHECK_FAIL = 1;
        # This will return undef if the response matches
        # one of the known patterns for a failed search,
        # sorted by servers.
        # Default is to give the textual response.

    $Net::Whois::Raw::CHECK_EXCEED = 0 | 1 | 2;
        # When this option is true, "die" will be called
        # if connection rate to specific whois server have been
        # exceeded.
        # If set to 2, will die in recursive queries too.

    $Net::Whois::Raw::CACHE_DIR = "/var/spool/pwhois/";
        # Whois information will be
        # cached in this directory. Default is no cache.

    $Net::Whois::Raw::CACHE_TIME = 60;
        # Cache files will be cleared after not accessed
        # for a specific number of minutes. Documents will not be
        # cleared if they keep get requested for, independent
        # of disk space.

    $Net::Whois::Raw::TIMEOUT = 10;
        # Cancel the request if connection is not made within
        # a specific number of seconds.

    @Net::Whois::Raw::SRC_IPS = (11.22.33.44);
        # List of local IP addresses to
        # use for WHOIS queries. Addresses will be used used
        # successively in the successive queries

    $Net::Whois::Raw::POSTPROCESS{whois.crsnic.net} = \&my_func;
        # Call to a user-defined subroutine on whois result,
        # depending on whois-server.
        # Above is equil to:
        # ($text, $srv) = whois('example.com');
        # $text = my_func($text) if $srv eq 'whois.crsnic.net';

    $Net::Whois::Raw::QUERY_SUFFIX = '/e';
        # This will add specified suffix to whois query.
        # It may be used for english output forcing.

=head1 DESCRIPTION

Net::Whois::Raw queries WHOIS servers about domains.
The module supports recursive WHOIS queries.
Also queries via HTTP is supported for some TLDs.

Setting the variables $OMIT_MSG and $CHECK_FAIL will match the results
against a set of known patterns. The first flag will try to omit the
copyright message/disclaimer, the second will attempt to determine if
the search failed and return undef in such a case.

B<IMPORTANT>: these checks merely use pattern matching; they will work
on several servers but certainly not on all of them.

=head1 NAME

Net::Whois::Raw — Get Whois information of domains and IP addresses.

=head1 FUNCTIONS

=over 3

=item whois( DOMAIN [, SRV [, WHICH_WHOIS]] )

Returns Whois information for C<DOMAIN> in punycode.
Without C<SRV> argument default Whois server for specified domain name
zone will be used. Use 'www_whois' as server name to force
WHOIS querying via HTTP (only few TLDs are supported in HTTP queries).
Caching is supported: if $CACHE_DIR variable is set and there is cached
entry for that domain - information from the cache will be used.
C<WHICH_WHOIS> argument - look get_whois docs below.

=item get_whois( DOMAIN [, SRV [, WHICH_WHOIS]] )

Lower-level function to query Whois information for C<DOMAIN>.
Caching IS NOT supported (caching is implemented only in higher-level
C<whois> function).
Without C<SRV> argument default Whois server for specified domain name
zone will be used.
C<WHICH_WHOIS> argument is used to access a results if recursive queries;
possible values:

C<'QRY_FIRST'> -
    returns results of the first query. Non't make recursive queries.
    In scalar context returns just whois text.
    In list context returns two values: whois text and whois server
    which was used to make query).

C<'QRY_LAST'> -
    returns results of the last query.
    In scalar context returns just whois text.
    In list context returns two values: whois text and whois server
    which was used to make query).
    This is the default option.

C<'QRY_ALL'> -
    returns results of the all queries of the recursive chain.
    Reference to array of references to hashes is returned.
    Hash keys: C<text> - result of whois query, C<srv> -
    whois server which was used to make query.

=back

=head1 USER DEFINED FUNCTIONS

=over 3

=item whois_query_sockparams( DOMAIN, SRV )

You can set your own IO::Socket::INET params like this:

    *Net::Whois::Raw::whois_query_sockparams = sub {
        my $class  = shift;
        my $domain = shift;
        my $name   = shift;

        return (
            PeerAddr => $name,
            PeerPort => 43,
            # LocalHost => ,
            # LocalPort =>
        );
    };

=item whois_query_socket( DOMAIN, SRV )

You can set your own IO::Socket::INET like this:

    *Net::Whois::Raw::whois_query_socket = sub {
        my $class  = shift;
        my $domain = shift;
        my $name   = shift;

        $name .= ':43';
        return IO::Socket::INET->new();
    };

=item whois_query_ua( DOMAIN, SRV )

You can set your own LWP::UserAgent like this:

    *Net::Whois::Raw::whois_query_ua = sub {
        my $class  = shift;
        my $domain = shift;

        return LWP::UserAgent->new();
    };

=item set_ips_for_server('whois.ripn.net', ['127.0.0.1']);

You can specify IPs list which will be used for queries to desired whois server.
It can be useful if you have few interfaces, but you need to access whois server
from specified ips.

=back

=head1 AUTHOR

Original author Ariel Brosh B<schop@cpan.org>,
Inspired by jwhois.pl available on the net.

Since Ariel has passed away in September 2002:

Past maintainers Gabor Szabo B<gabor@perl.org.il>,
Corris Randall B<corris@cpan.org>,
Walery Studennikov B<despair@cpan.org>

Current Maintainer: Alexander Nalobin B<nalobin@cpan.org>

=head1 CREDITS

See file "Changes" in the distribution for the complete list of contributors.

=head1 CHANGES

See file "Changes" in the distribution

=head1 NOTE

Some users complained that the B<die> statements in the module make their
CGI scripts crash. Please consult the entries on B<eval> and
B<die> on L<perlfunc> about exception handling in Perl.

=head1 COPYRIGHT

Copyright 2000--2002 Ariel Brosh.
Copyright 2003--2003 Gabor Szabo.
Copyright 2003--2003 Corris Randall.
Copyright 2003--now() Walery Studennikov

This package is free software. You may redistribute it or modify it under
the same terms as Perl itself.

I apologize for any misunderstandings caused by the lack of a clear
licence in previous versions.

=head1 COMMERCIAL SUPPORT

Not available anymore.

=head1 LEGAL

Notice that registrars forbid querying their whois servers as a part of
a search engine, or querying for a lot of domains by script.
Also, omitting the copyright information (that was requested by users of this
module) is forbidden by the registrars.

=head1 SEE ALSO

L<pwhois>, L<whois>.

=head1 AUTHOR

Alexander Nalobin <alexander@nalobin.ru>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2002-2020 by Alexander Nalobin.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
