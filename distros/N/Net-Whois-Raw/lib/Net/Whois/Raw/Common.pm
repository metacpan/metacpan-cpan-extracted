package Net::Whois::Raw::Common;
$Net::Whois::Raw::Common::VERSION = '2.99031';
# ABSTRACT: Helper for Net::Whois::Raw.

use Encode;
use warnings;
use strict;
use Regexp::IPv6 qw($IPv6_re);
use Net::Whois::Raw::Data ();
use Net::Whois::Raw ();

use utf8;

# func prototype
sub untaint(\$);

# get whois from cache
sub get_from_cache {
    my ($query, $cache_dir, $cache_time) = @_;

    return undef unless $cache_dir;
    mkdir $cache_dir unless -d $cache_dir;

    my $now = time;
    # clear the cache
    foreach my $fn ( glob("$cache_dir/*") ) {
        my $mtime = ( stat($fn) )[9] or next;
        my $elapsed = $now - $mtime;
        untaint $fn; untaint $elapsed;
        unlink $fn if ( $elapsed / 60 >= $cache_time );
    }

    my $result;
    if ( -e "$cache_dir/$query.00" ) {
        my $level = 0;
        while ( open( my $cache_fh, '<', "$cache_dir/$query.".sprintf( "%02d", $level ) ) ) {
            $result->[$level]->{srv} = <$cache_fh>;
            chomp $result->[$level]->{srv};
            $result->[$level]->{text} = join "", <$cache_fh>;
            if ( !$result->[$level]->{text} and $Net::Whois::Raw::CHECK_FAIL ) {
                $result->[$level]->{text} = undef ;
            }
            else {
                $result->[$level]->{text} = decode_utf8( $result->[$level]->{text} );
            }
            $level++;
            close $cache_fh;
        }
    }

    return $result;
}

# write whois to cache
sub write_to_cache {
    my ($query, $result, $cache_dir) = @_;

    return unless $cache_dir && $result;
    mkdir $cache_dir unless -d $cache_dir;

    untaint $query; untaint $cache_dir;

    my $level = 0;
    foreach my $res ( @{$result} ) {
        local $res->{text} = $res->{whois} if not exists $res->{text};

        next if defined $res->{text} && !$res->{text} || !defined $res->{text};
        my $enc_text = $res->{text};
        utf8::encode( $enc_text );
        my $postfix = sprintf("%02d", $level);
        if ( open( my $cache_fh, '>', "$cache_dir/$query.$postfix" ) ) {
            print $cache_fh $res->{srv} ? $res->{srv} :
                ( $res->{server} ? $res->{server} : '')
                , "\n";

            print $cache_fh $enc_text ? $enc_text : '';

            close $cache_fh;
            chmod 0666, "$cache_dir/$query.$postfix";
        }
        $level++;
    }

}

# remove copyright messages, check for existance
sub process_whois {
    my ( $query, $server, $whois, $CHECK_FAIL, $OMIT_MSG, $CHECK_EXCEED ) = @_;

    $server = lc $server;
    my ( $name, $tld ) = split_domain( $query );

    # use string as is
    no utf8;

    if ( $CHECK_EXCEED ) {
        my $exceed = $Net::Whois::Raw::Data::exceed{ $server };

        if ( $exceed && $whois =~ /$exceed/s) {
            return $whois, 'Connection rate exceeded';
        }
    }

    $whois = _strip_trailer_lines( $whois )  if $OMIT_MSG;

    if ( $CHECK_FAIL || $OMIT_MSG ) {

        my $notfound = $Net::Whois::Raw::Data::notfound{ $server };
        my $strip = $Net::Whois::Raw::Data::strip{ $server };
        my @strip = $strip ? @$strip : ();
        my @lines;

        MAIN:
        for ( split /\n/, $whois ) {
            if ( $CHECK_FAIL && $notfound && /$notfound/ ) {
                return undef, "Not found";
            }

            if ( $OMIT_MSG ) {
                for my $re ( @strip ) {
                    next MAIN  if /$re/;
                }
            }

            push @lines, $_;
        }

        $whois = join "\n", @lines, '';

        if ( $OMIT_MSG ) {
            $whois =~ s/(?:\s*\n)+$/\n/s;
            $whois =~ s/^\n+//s;
            $whois =~ s|\n{3,}|\n\n|sg;
        }
    }

    if ( defined $Net::Whois::Raw::Data::postprocess{ $server } ) {
        $whois = $Net::Whois::Raw::Data::postprocess{ $server }->( $whois );
    }

    if ( defined $Net::Whois::Raw::POSTPROCESS{ $server } ) {
        $whois = $Net::Whois::Raw::POSTPROCESS{ $server }->( $whois );
    }

    if ( defined $Net::Whois::Raw::Data::codepages{ $server } ) {
        $whois = decode( $Net::Whois::Raw::Data::codepages{ $server }, $whois );
    }
    else {
        utf8::decode( $whois );
    }

    return $whois, undef;
}

# Tries to strip trailer lines of whois
sub _strip_trailer_lines {
    my ( $whois ) = @_;

    for my $re ( @Net::Whois::Raw::Data::strip_regexps ) {
        $whois =~ s/$re//;
    }

    return $whois;
}

# get whois-server for domain / tld
sub get_server {
    my ( $dom, $is_ns, $tld ) = @_;

    $tld ||= get_dom_tld( $dom );
    $tld = uc $tld;

    if ( grep { $_ eq $tld } @Net::Whois::Raw::Data::www_whois ) {
        return 'www_whois';
    }

    if ( $is_ns ) {
        return $Net::Whois::Raw::Data::servers{ $tld . '.NS' }
            || $Net::Whois::Raw::Data::servers{ 'NS' };
    }

    return lc( $Net::Whois::Raw::Data::servers{ $tld } || "whois.nic.$tld" );
}

sub get_real_whois_query{
    my ( $whoisquery, $srv, $is_ns ) = @_;

    $srv .= '.ns'  if $is_ns;

    if ( $srv eq 'whois.crsnic.net' && domain_level( $whoisquery ) == 2 ) {
        return "domain $whoisquery";
    }
    elsif ( $Net::Whois::Raw::Data::query_prefix{ $srv } ) {
        return $Net::Whois::Raw::Data::query_prefix{ $srv } . $whoisquery;
    }

    return $whoisquery;
}

# get domain TLD
sub get_dom_tld {
    my ($dom) = @_;

    my $tld;
    if ( is_ipaddr($dom) || is_ip6addr($dom) ) {
        $tld = "IP";
    }
    elsif ( domain_level($dom) == 1 ) {
        $tld = "NOTLD";
    }
    else {
        my @tokens = split( /\./, $dom );
        
        # try to get the longest known tld for this domain
        for my $i ( 1..$#tokens ) {
            my $tld_try = join '.', @tokens[$i..$#tokens];
            if ( exists $Net::Whois::Raw::Data::servers{ uc $tld_try } ) {
                $tld = $tld_try;
                last;
            }
        }
        
        $tld = $tokens[-1] unless $tld;
    }

    return $tld;
}

# get URL for query via HTTP
# %param: domain*
sub get_http_query_url {
    my ($domain) = @_;

    my ($name, $tld) = split_domain($domain);
    my @http_query_data;
    # my ($url, %form);

    if ($tld eq 'ru' || $tld eq 'su') {
        my $data = {
            url  => "http://www.nic.ru/whois/?domain=$name.$tld",
            form => '',
        };
        push @http_query_data, $data;
    }
    elsif ($tld eq 'ip') {
        my $data = {
            url  => "http://www.nic.ru/whois/?ip=$name",
            form => '',
        };
        push @http_query_data, $data;
    }
    elsif ($tld eq 'ws') {
        my $data = {
            url  => "http://worldsite.ws/utilities/lookup.dhtml?domain=$name&tld=$tld",
            form => '',
        };
        push @http_query_data, $data;
    }
    elsif ($tld eq 'kz') {
        my $data = {
            url  => "http://www.nic.kz/cgi-bin/whois?query=$name.$tld&x=0&y=0",
            form => '',
        };
        push @http_query_data, $data;
    }
    elsif ($tld eq 'vn') {
        # VN doesn't have web whois at the moment...
        my $data = {
            url  => "http://www.tenmien.vn/jsp/jsp/tracuudomain1.jsp",
            form => {
                cap2        => ".$tld",
                referer     => 'http://www.vnnic.vn/english/',
                domainname1 => $name,
            },
        };
        push @http_query_data, $data;
    }
    elsif ($tld eq 'ac') {
        my $data = {
            url  => "http://nic.ac/cgi-bin/whois?query=$name.$tld",
            form => '',
        };
        push @http_query_data, $data;
    }
    elsif ($tld eq 'bz') {
        my $data = {
            url  => "http://www.test.bz/Whois/index.php?query=$name&output=nice&dotname=.$tld&whois=Search",
        };
        push @http_query_data, $data;
    }
    elsif ($tld eq 'tj') {
        #my $data = {
        #    url  => "http://get.tj/whois/?lang=en&domain=$domain",
        #    from => '',
        #};
        #push @http_query_data, $data;

        # first level on nic.tj
        #$data = {
        #    url  => "http://www.nic.tj/cgi/lookup2?domain=$name",
        #    from => '',
        #};
        #push @http_query_data, $data;

        # second level on nic.tj
        my $data = {
            url  => "http://www.nic.tj/cgi/whois?domain=$name",
            from => '',
        };
        push @http_query_data, $data;

        #$data = {
        #    url  => "http://ns1.nic.tj/cgi/whois?domain=$name",
        #    from => '',
        #};
        #push @http_query_data, $data;

        #$data = {
        #    url  => "http://62.122.137.16/cgi/whois?domain=$name",
        #    from => '',
        #};
        #push @http_query_data, $data;
    }

    # return $url, %form;
    return \@http_query_data;
}

sub have_reserve_url {
    my ( $tld ) = @_;

    my %tld_list = (
        'tj' => 1,
    );

    return defined $tld_list{$tld};
}

# Parse content received from HTTP server
# %param: resp*, tld*
sub parse_www_content {
    my ($resp, $tld, $url, $CHECK_EXCEED) = @_;

    chomp $resp;
    $resp =~ s/\r//g;

    my $ishtml;

    if ( $tld eq 'ru' || $tld eq 'su' ) {

        $resp = decode( 'koi8-r', $resp );

        (undef, $resp) = split('<script>.*?</script>',$resp);
        ($resp) = split('</td></tr></table>', $resp);
        $resp =~ s/&nbsp;/ /gi;
        $resp =~ s/<([^>]|\n)*>//gi;

        return 0 if $resp=~ m/Доменное имя .*? не зарегистрировано/i;

        $resp = 'ERROR' if $resp =~ m/Error:/i || $resp !~ m/Информация о домене .+? \(по данным WHOIS.RIPN.NET\):/;
        #TODO: errors

    }
    elsif ($tld eq 'ip') {

        $resp = decode_utf8( $resp );

        return 0 unless $resp =~ m|<p ID="whois">(.+?)</p>|s;

        $resp = $1;

        $resp =~ s|<a.+?>||g;
        $resp =~ s|</a>||g;
        $resp =~ s|<br>||g;
        $resp =~ s|&nbsp;| |g;

    }
    elsif ($tld eq 'ws') {

        $resp = decode_utf8( $resp );

        if ($resp =~ /Whois information for .+?:(.+?)<table>/s) {
            $resp = $1;
            $resp =~ s|<font.+?>||isg;
            $resp =~ s|</font>||isg;

            $ishtml = 1;
        }
        else {
            return 0;
        }

    }
    elsif ($tld eq 'kz') {

        $resp = decode_utf8( $resp );

        if ($resp =~ /Domain Name\.{10}/s && $resp =~ /<pre>(.+?)<\/pre>/s) {
            $resp = $1;
        }
        else {
            return 0;
        }
    }
    elsif ($tld eq 'vn') {

        $resp = decode_utf8( $resp );

        if ($resp =~ /\(\s*?(Domain .+?:\s*registered)\s*?\)/i )  {
            $resp = $1;
        }
        else {
            return 0;
        }

        #
        # if ($resp =~/#ENGLISH.*?<\/tr>(.+?)<\/table>/si) {
        #    $resp = $1;
        #    $resp =~ s|</?font.*?>||ig;
        #    $resp =~ s|&nbsp;||ig;
        #    $resp =~ s|<br>|\n|ig;
        #    $resp =~ s|<tr>\s*<td.*?>\s*(.*?)\s*</td>\s*<td.*?>\s*(.*?)\s*</td>\s*</tr>|$1 $2\n|isg;
        #    $resp =~ s|^\s*||mg;
        #
    }
    elsif ($tld eq 'ac') {

        $resp = decode_utf8( $resp );

        if ($CHECK_EXCEED && $resp =~ /too many requests/is) {
            die "Connection rate exceeded";
        }
        elsif ($resp =~ /<!--- Start \/ Domain Info --->(.+?)<!--- End \/ Domain Info --->/is) {
            $resp = $1;
            $resp =~ s|</?table.*?>||ig;
            $resp =~ s|</?b>||ig;
            $resp =~ s|</?font.*?>||ig;
            $resp =~ s|<tr.*?>\s*<td.*?>\s*(.*?)\s*</td>\s*<td.*?>\s*(.*?)\s*</td>\s*</tr>|$1 $2\n|isg;
            $resp =~ s|</?tr>||ig;
            $resp =~ s|</?td>||ig;
            $resp =~ s|^\s*||mg;
        }
        else {
            return 0;
        }

    }
    elsif ($tld eq 'bz') {

        $resp = decode_utf8( $resp );

        if ( $resp =~ m{
                <blockquote>
                (.+)
                </blockquote>
            }xms )
        {
            $resp = $1;
            if ( $resp =~ /NOT\s+FOUND/ || $resp =~ /No\s+Domain/ ) {
                # Whois info not found
                return 0;
            }

            $resp =~ s|<[^<>]+>||ig;
        }
        else {
            return 0;
        }
    }
    elsif ( $tld eq 'tj' && $url =~ m|^http\://get\.tj| ) {
        $resp = decode_utf8( $resp );

        if ($resp =~ m|<!-- Content //-->\n(.+?)<!-- End Content //-->|s ) {
            $resp = $1;
            $resp =~ s|<[^<>]+>||ig;
            $resp =~ s|Whois\n|\n|s;

            return 0 if $resp =~ m|Domain \S+ is free|s;

            $resp =~ s|Domain \S+ is already taken\.\n|\n|s;
            $resp =~ s|&nbsp;| |ig;
            $resp =~ s|&laquo;|"|ig;
            $resp =~ s|&raquo;|"|ig;
            $resp =~ s|\n\s+|\n|sg;
            $resp =~ s|\s+\n|\n|sg;
            $resp =~ s|\n\n|\n|sg;
        }
        else {
            return 0;
        }

    }
    elsif ( $tld eq 'tj' && $url =~ m|\.nic\.tj/cgi/lookup| ) {

        $resp = decode_utf8( $resp );

        if ($resp =~ m|<div[0-9a-z=\" ]*>\n?(.+?)\n?</div>|s) {
            $resp = $1;

            return 0 if $resp =~ m|may be available|s;

            $resp =~ s|\n\s+|\n|sg;
            $resp =~ s|\s+\n|\n|sg;
            $resp =~ s|\n\n|\n|sg;
            $resp =~ s|<br.+||si;
        }
        else {
            return 0;
        }

    }
    elsif ( $tld eq 'tj' && $url =~ m|\.nic\.tj/cgi/whois| || $url =~ m|62\.122\.137\.16| ) {
        $resp = decode_utf8( $resp );

        if ( $resp =~ m{ <table [^>]*? > (.+) (:? </table> ) }sxmi ) {
            $resp = $1;
            $resp =~ s|</?tr>||ig;
            $resp =~ s|<td>| |ig;
            $resp =~ s|</?td[0-9a-z=\" ]*>||ig;
            $resp =~ s|</?col[0-9a-z=\" ]*>||ig;
            $resp =~ s|&laquo;|"|ig;
            $resp =~ s|&raquo;|"|ig;
            $resp =~ s|&nbsp;| |ig;
            $resp =~ s|\n\s+|\n|sg;
            $resp =~ s|\s+\n|\n|sg;
            $resp =~ s|\n\n|\n|sg;
        }
        else {
            return 0;
        }

    }
    else {
        return 0;
    }

    return $resp;
}

# check, if it's IP-address?
sub is_ipaddr {
    $_[0] =~ /^\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3}$/;
}

# check, if it's IPv6-address?
sub is_ip6addr {
    my ( $ip ) = @_;

    return 0 unless defined $ip;

    return $ip =~ /^$IPv6_re$/;
}

# get domain level
sub domain_level {
    my ($str) = @_;

    my $dotcount = $str =~ tr/././;

    return $dotcount + 1;
}

# split domain on name and TLD
sub split_domain {
    my ($dom) = @_;

    my $tld = get_dom_tld( $dom );

    my $name;
    if (uc $tld eq 'IP' || $tld eq 'NOTLD') {
        $name = $dom;
    }
    else {
        $name = substr( $dom, 0, length($dom) - length($tld) - 1 );
    }

    return ($name, $tld);
}

#
sub dlen {
    my ($str) = @_;

    return length($str) * domain_level($str);
}

# clear the data's taintedness
sub untaint (\$) {
    my ($str) = @_;

    $$str =~ m/^(.*)$/;
    $$str = $1;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Net::Whois::Raw::Common - Helper for Net::Whois::Raw.

=head1 VERSION

version 2.99031

=head1 AUTHOR

Alexander Nalobin <alexander@nalobin.ru>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2002-2020 by Alexander Nalobin.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
