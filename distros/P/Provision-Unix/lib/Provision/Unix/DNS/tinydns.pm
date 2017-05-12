package Provision::Unix::DNS::tinydns;
# ABSTRACT: Provision tinydns DNS entries
$Provision::Unix::DNS::tinydns::VERSION = '1.08';
use strict;
use warnings;

use Cwd;
use English qw( -no_match_vars );
use Params::Validate qw(:all);

use lib 'lib';
use Provision::Unix::Utility;

my ( $prov, $util );

sub new {
    my $class = shift;

    my %p = validate( @_, { 'prov' => { type => OBJECT }, } );

    my $self = { prov => $p{prov}, };
    bless( $self, $class );

    $prov = $p{prov};
    $prov->audit("loaded DNS/tinydns");
    $util = $prov->get_util;

    #$self->{server}  = $self->_load_DNS_TinyDNS();
    $self->{special} = $self->_special_chars();
    return $self;
}

sub create_zone {
    my $self = shift;

    my %p = validate(
        @_,
        {   'zone'       => { type => SCALAR },
            'contact'    => { type => SCALAR | UNDEF, optional => 1 },
            'serial'     => { type => SCALAR | UNDEF, optional => 1 },
            'ttl'        => { type => SCALAR | UNDEF, optional => 1 },
            'refresh'    => { type => SCALAR | UNDEF, optional => 1 },
            'retry'      => { type => SCALAR | UNDEF, optional => 1 },
            'expire'     => { type => SCALAR | UNDEF, optional => 1 },
            'minimum'    => { type => SCALAR | UNDEF, optional => 1 },
            'nameserver' => { type => SCALAR | UNDEF, optional => 1, },
            'fatal'      => { type => BOOLEAN, optional => 1, default => 1 },
            'debug'      => { type => BOOLEAN, optional => 1, default => 1 },
        }
    );

    my $zone = $p{zone};

    $prov->audit("creating zone $zone");

    my $service_dir = $prov->{config}{tinydns}{service_dir};
    if ( $self->get_zone( zone => $zone, fatal => 0 ) ) {
        return $prov->error( "zone $zone already exists",
            fatal   => $p{fatal},
            debug   => $p{debug},
        );
    }

# publishing an explicit SOA record for every zone managed is
# a reliable way to determine if a zone is provisioned
#
# SOA, Zfqdn:mname:rname:ser:ref:ret:exp:min:ttl:timestamp:lo
#Ztesting.com:x2.nictool.com.:hostmaster.testing.com::16384:2048:1048576:2560:86400::

    my $nameserver = $self->qualify( $zone, $p{nameserver} || "a.ns" );

    my $soa = $self->{special}{SOA};

    $soa .= join(
        ":",
        $p{zone},
        $nameserver,    # mname
        $p{contact} || "hostmaster.$p{zone}",    # rname
        '',    # serial, blank lets tinydns autogenerate
        $p{refresh} || $prov->{config}{DNS}{zone_refresh},
        $p{retry}   || $prov->{config}{DNS}{zone_retry},
        $p{expire}  || $prov->{config}{DNS}{zone_expire},
        $p{minimum} || $prov->{config}{DNS}{zone_minimum},
        $p{ttl}     || $prov->{config}{DNS}{zone_ttl},
    );
    $soa .= ":";    # timestamp
    $soa .= ":";    # location (ala, split horizon)

    # append the record to $data
    $util->file_write( "$service_dir/root/data",
        lines  => [$soa],
        append => 1,
        debug  => $p{debug},
    );

    $self->compile_data_cdb();

    return 1;
}

sub create_zone_record {
    my $self = shift;
    my %p = validate(
        @_,
        {   'zone'     => { type => SCALAR },
            'zone_id'  => { type => SCALAR, optional => 1 },
            'type'     => { type => SCALAR },
            'name'     => { type => SCALAR },
            'address'  => { type => SCALAR },
            'weight'   => { type => SCALAR, optional => 1 },
            'ttl'      => { type => SCALAR, optional => 1 },
            'priority' => { type => SCALAR, optional => 1 },
            'port'     => { type => SCALAR, optional => 1 },
            'debug'    => { type => SCALAR, optional => 1, default => 1 },
            'fatal'    => { type => SCALAR, optional => 1, default => 1 },
        }
    );

    my $type = uc( $p{type} );

    $prov->audit("creating $type record in $p{zone}");

    if ( !$self->get_zone( zone => $p{zone} ) ) {
        $prov->error( "zone $p{zone} does not exist!" );
    }

    my $record
        = $type eq 'A'     ? $self->build_a( \%p )
        : $type eq 'MX'    ? $self->build_mx( \%p )
        : $type eq 'NS'    ? $self->build_ns( \%p )
        : $type eq 'PTR'   ? $self->build_ptr( \%p )
        : $type eq 'TXT'   ? $self->build_txt( \%p )
        : $type eq 'CNAME' ? $self->build_cname( \%p )
        : $type eq 'SRV'   ? $self->build_srv( \%p )
        : $type eq 'NAPTR' ? $self->build_naptr( \%p )
        : $type eq 'AAAA'  ? $self->build_aaaa( \%p )
        : $prov->error( 'invalid record type', fatal => $p{fatal} );

    my $service_dir = $prov->{config}{tinydns}{service_dir};

    # append the record to $data
    $util->file_write( "$service_dir/root/data",
        lines  => [$record],
        append => 1,
        debug  => $p{debug},
    );

    $self->compile_data_cdb();

    return $record;
}

sub build_a {
    my ( $self, $p ) = @_;

    # +fqdn:ip:ttl:timestamp:lo

    return $self->{special}{A}
     . $self->qualify( $p->{zone}, $p->{name} ) 
     . ':' . $p->{address} 
     . ':' . $p->{ttl} || $prov->{config}{DNS}{ttl}
     . '::';
}

sub build_mx {
    my ( $self, $p ) = @_;

    # @fqdn:ip:x:dist:ttl:timestamp:lo
    my $r = $self->{special}{MX};
    $r .= $self->qualify( $p->{zone}, $p->{name} ) . ":";
    $r .= ":";    # ip leave blank, defined with an A record
    $r .= $self->qualify( $p->{zone}, $p->{address} ) . ".:";
    $r .= $p->{weight} . ":";
    $r .= $p->{ttl} || $prov->{config}{DNS}{ttl};

    return $r;
}

sub build_ns {
    my ( $self, $p ) = @_;

    # &fqdn:ip:x:ttl:timestamp:lo   (NS + A)
    my $r = $self->{special}{NS};
    $r .= $self->qualify( $p->{zone}, $p->{name} ) . ":";
    $r .= ":";    # ip leave blank, defined with an A record
    $r .= $self->qualify( $p->{zone}, $p->{address} ) . ".:";
    $r .= $p->{ttl} || $prov->{config}{DNS}{ttl};

    return $r;
}

sub build_cname {
    my ( $self, $p ) = @_;

    # Cfqdn:p:ttl:timestamp:lo
    my $r = $self->{special}{CNAME};
    $r .= $self->qualify( $p->{zone}, $p->{name} ) . ":";
    $r .= $self->qualify( $p->{zone}, $p->{address} ) . ".:";
    $r .= $p->{ttl} || $prov->{config}{DNS}{ttl};

    return $r;
}

sub build_txt {
    my ( $self, $p ) = @_;

    # 'fqdn:s:ttl:timestamp:lo
    my $r = $self->{special}{TXT};
    $r .= $self->qualify( $p->{zone}, $p->{name} ) . ":";
    $r .= $self->escape( $p->{address} ) . ":";
    $r .= $p->{ttl} || $prov->{config}{DNS}{ttl};

    return $r;
}

sub build_ptr {
    my ( $self, $p ) = @_;

    # ^fqdn:p:ttl:timestamp:lo
    my $r = $self->{special}{PTR};
## TODO
    # check that our zone matches NN.in-addr.arpa and/or a pattern
    # the can be automatically expanded as such

    $r .= $self->qualify( $p->{zone}, $p->{name} ) . ":";
    $r .= $p->{address} . ":";
    $r .= $p->{ttl} || $prov->{config}{DNS}{ttl};

    return $r;
}

sub build_soa {
    my $self = shift;
    # Zfqdn:mname:rname:ser:ref:ret:exp:min:ttl:timestamp:lo
};

sub build_srv {
    my ( $self, $p ) = @_;

    # :fqdn:n:rdata:ttl:timestamp:lo (Generic record)
    my $priority = $p->{priority};
    my $weight   = $p->{weight};
    my $port     = $p->{port};

# SRV
# :sip.tcp.example.com:33:\000\001\000\002\023\304\003pbx\007example\003com\000
    if ( $priority < 0 || $priority > 65535 ) {
        $prov->error( "priority $priority not within 0 - 65535" );
    }
    if ( $weight < 0 || $weight > 65535 ) {
        $prov->error( "weight $weight not within 0 - 65535" );
    }
    if ( $port < 0 || $port > 65535 ) {
        $prov->error( "port $port not within 0 - 65535" );
    }

    $priority = escapeNumber($priority);
    $weight   = escapeNumber($weight);
    $port     = escapeNumber($port);

    my $target = "";
    my @chunks = split /\./,
        $self->qualify( $p->{zone}, $p->{address} );
    foreach my $chunk (@chunks) {
        $target .= characterCount($chunk) . $chunk;
    }

    my $service = $self->qualify( $p->{zone}, $p->{name} );
    $service = escape($service);

    my $r = ":";
    $r .= "$service:33:" . $priority . $weight . $port;
    $r .= $target . "\\000:";
    $r .= $p->{ttl} || $prov->{config}{DNS}{ttl};

    return $r;
}

sub build_aaaa {
    my ( $self, $p ) = @_;

# :fqdn:n:rdata:ttl:timestamp:lo (generic record format)
# ffff:1234:5678:9abc:def0:1234:0:0
# :example.com:28:\377\377\022\064\126\170\232\274\336\360\022\064\000\000\000\000

    my ( $a, $b, $c, $d, $e, $f, $g, $h ) = split /:/, $p->{address};
    if ( !defined $h ) {
        die "Didn't get a valid-looking IPv6 address\n";
    }

    $a = escapeHex( sprintf "%04s", $a );
    $b = escapeHex( sprintf "%04s", $b );
    $c = escapeHex( sprintf "%04s", $c );
    $d = escapeHex( sprintf "%04s", $d );
    $e = escapeHex( sprintf "%04s", $e );
    $f = escapeHex( sprintf "%04s", $f );
    $g = escapeHex( sprintf "%04s", $g );
    $h = escapeHex( sprintf "%04s", $h );

    my $r = ':';
    $r .= $self->qualify( $p->{zone}, $p->{name} ) . ':';
    $r .= '28:' . "$a$b$c$d$e$f$g$h" . ':';
    $r .= $p->{ttl} || $prov->{config}{DNS}{ttl};

    return $r;
}

sub qualify {
    my $self = shift;
    my ( $zone, $record ) = @_;

    return $record if $record =~ /\.$/;    # already ends in .

    # append the zone name if needed
    return "$record.$zone" if $record !~ /$zone$/;

    return $record;
}

sub compile_data_cdb {

    my $self = shift;

    my $service_dir = $prov->{config}{tinydns}{service_dir};
    my $data_dir    = "$service_dir/root";

    my $tdata = $util->find_bin( 'tinydns-data', debug => 0 );

    # compile the data.cdb file
    my $original_wd = getcwd;
    chdir($data_dir)
        or $prov->error( "unable to chdir to $data_dir" );
    system $tdata and $prov->error( "could not compile data" );
    chdir $original_wd;

    return 1;
}

sub get_zone {

    my $self = shift;

    my %p = validate(
        @_,
        {   'zone'  => { type => SCALAR },
            'fatal' => { type => BOOLEAN, optional => 1, default => 1 },
            'debug' => { type => BOOLEAN, optional => 1, default => 1 },
        }
    );

    my $zone = $p{zone};
    $prov->audit("getting zone $zone");

    my $service_dir = $prov->{config}{tinydns}{service_dir};
    my @lines = $util->file_read( "$service_dir/root/data" );

    @lines = grep ( /^Z$zone:/, @lines );

    #warn "matching zones:\n", join ("\n", @lines), "\n";

    if ( scalar @lines > 0 ) {
        $prov->audit( "\tfound " . substr( $lines[0], 0, 35 ) . '...' );
        return 1;
    }
    return;
}

sub delete_zone {

    my $self = shift;

    my %p = validate(
        @_,
        {   'id'   => { type => SCALAR, optional => 1 },
            'zone' => { type => SCALAR },
            'fatal' => { type => BOOLEAN, optional => 1, default => 1 },
            'debug' => { type => BOOLEAN, optional => 1, default => 1 },
        }
    );

    $prov->audit("getting zone $p{zone}");

}

sub _load_DNS_TinyDNS {

#    my $self = shift;

#    eval { require DNS::TinyDNS; };

#    if ($EVAL_ERROR) {
#        $prov->error( "could not load DNS::TinyDNS. Is it installed?" );
#    }

#    my $service_dir = $prov->{config}{tinydns}{service_dir};

#    $prov->audit("loaded DNS::TinyDNS");
#    return DNS::TinyDNS->new(
#        type => 'dnsserver',
#        dir  => $service_dir
#    );
}

sub _special_chars {
    my %special = (
        A          => '+',  # fqdn : ip : ttl:timestamp:lo
        MX         => '@',  # fqdn : ip : x:dist:ttl:timestamp:lo
        NS         => '&',  # fqdn : ip : x:ttl:timestamp:lo
        CNAME      => 'C',  # fqdn :  p : ttl:timestamp:lo
        PTR        => '^',  # fqdn :  p : ttl:timestamp:lo
        TXT        => "'",  # fqdn :  s : ttl:timestamp:lo
        SOA        => 'Z',  # fqdn:mname:rname:ser:ref:ret:exp:min:ttl:time:lo
        IGNORE     => '-',  # fqdn : ip : ttl:timestamp:lo
        'A,PTR'    => '=',  # fqdn : ip : ttl:timestamp:lo
        'SOA,NS,A' => '.',  # fqdn : ip : x:ttl:timestamp:lo
        GENERIC    => ':',  # fqdn : n  : rdata:ttl:timestamp:lo
    );
    return \%special;
}


my $stuff = <<'IGNORE'
# SPF
# ":$domain:16:" . characterCount( $text ) . escape( $text ) . ":" . $ttl;
NAPTR
# :comunip.com:35:\000\012\000\144\001u\007E2U+sip\036!^.*$!sip\072info@comunip.com.br!\000:300
    #  |-order-|-pref--|flag|-services-|---------------regexp---------------|re-| 
    if ( ( $order >= 0 && $order <= 65535 ) &&
         ( $prefrence >= 0 && $prefrence <= 65535 ) &&
         ( $flag eq "u" ) ) {
        $result = ":" . escape( $domain ) . ":35:" . escapeNumber( $order ) .
            escapeNumber( $prefrence ) . characterCount( $flag ) . $flag .
            characterCount( $services ) . escape( $services ) .
            characterCount( $regexp ) . escape( $regexp );

        if ( $replacement ne "" ) {
            $result = $result . characterCount( $replacement ) . escape( $replacement );
        }
        $result = $result . "\\000:" . $ttl;

        print $result;
    }
    else {
        print "priority, weight or port not within 0 - 65535\n";
    }
}
domainKeys
    # :joe._domainkey.anders.com:16:\341k=rsa; p=MIGfMA0GCSqGSIb3DQ ... E2hHCvoVwXqyZ/MbQIDAQAB
    #  |lt|  |typ|  |-key----------------------------------------|
    if ( $key ne "" ) {
        $key = $key;
        $key =~ s/\r//g;
        $key =~ s/\n//g;
            $line = "k=" . $encryptionType . "; p=" . $key;
        $result = ":" . escape( $domain ) . ":16:" . characterCount( $line ) . 
            escape( $line ) . ":" . $ttl;
        print $result;
    }
    else {
        print "didn't get a valid key for the key field\n";
    }
}

IGNORE
;

# based on http://www.anders.com/projects/sysadmin/djbdnsRecordBuilder/
sub escape {
    my $line = pop @_;
    my $out;

    foreach my $char ( split //, $line ) {
        if ( $char =~ /[\r\n\t: \\\/]/ ) {
            $out .= sprintf "\\%.3lo", ord $char;
        }
        else {
            $out .= $char;
        }
    }
    return $out;
}

sub escapeNumber {
    my $number     = pop @_;
    my $highNumber = 0;

    if ( $number - 256 >= 0 ) {
        $highNumber = int( $number / 256 );
        $number = $number - ( $highNumber * 256 );
    }
    my $out = sprintf "\\%.3lo", $highNumber;
    $out .= sprintf "\\%.3lo", $number;

    return $out;
}

sub escapeHex {

    # takes a 4 character hex value and converts it to two escaped numbers
    my $line = pop @_;
    my @chars = split //, $line;

    my $out = sprintf "\\%.3lo", hex "$chars[0]$chars[1]";
    $out .= sprintf "\\%.3lo", hex "$chars[2]$chars[3]";

    return ($out);
}

sub characterCount {
    my $line  = pop @_;
    my @chars = split //, $line;
    my $count = @chars;

    return ( sprintf "\\%.3lo", $count );
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Provision::Unix::DNS::tinydns - Provision tinydns DNS entries

=head1 VERSION

version 1.08

=head1 SYNOPSIS

Provision DNS entries into a tinydns DNS management system using the tinydns native API.

    use Provision::Unix::DNS::tinydns;

    my $dns = Provision::Unix::DNS::tinydns->new();
    ...

=head1 FUNCTIONS

=head1 BUGS

Please report any bugs or feature requests to C<bug-unix-provision-dns at rt.cpan.org>, or through the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Provision-Unix>.  I will be notified, and then you'll automatically be notified of progress on your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Provision::Unix::DNS::tinydns

You can also look for information at:

=over 4

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Provision-Unix>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Provision-Unix>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Provision-Unix>

=item * Search CPAN

L<http://search.cpan.org/dist/Provision-Unix>

=back

=head1 ACKNOWLEDGEMENTS

some of the record generation logic was lifted from http://www.anders.com/projects/sysadmin/djbdnsRecordBuilder/

=head1 AUTHOR

Matt Simerson <msimerson@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2015 by The Network People, Inc..

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
