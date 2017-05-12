package Net::DNS::AutoDNS;

use strict;
use warnings;

use Net::DNS;
use XML::LibXML;
use Carp ();
use Net::DNS::AutoDNS::Zone;
use LWP::Simple qw($ua);

# ABSTRACT: Generates XML and communicates with AutoDNS

our $VERSION = '0.1'; # VERSION


my $XMLH = qq[<?xml version="1.0" encoding="utf-8"?>\n];

# RFC 1035 <character-string>
sub _escape {
    my ($string) = @_;
    return $string if not $string =~ /["\s]/;
    $string =~ s/(["\\])/\\$1/g;
    return qq["$string"];
}

# Poor XML generator because real XML is so inconvenient.

sub _xml_escape {
    my ($string) = @_;
    $string = "" if not defined $string;
    $string =~ s/([<>"'&\x7F-\xFF\x00-\x1F])/sprintf "&#%d;", ord $1/ge;
    return $string;
}

sub _xmlify {

    # @contents is key/value, where key is an element name or a reference to
    # literal XML, and value is one of:
    # array reference  ==> key/value pairs for nesting/recursion
    # scalar reference ==> literal XML to include
    # text             ==> text to escape and include
    my ($element, @contents) = @_;
    my $xml = "<$element>";
    if (@contents == 1) {
        my $c = $contents[0];
        return _xmlify($element, @$c) if ref($c) eq 'ARRAY';
        $xml .= $$c if ref($c) eq 'SCALAR';
        $xml .= _xml_escape($c) if not ref $c;
    }
    else {
        while (@contents) {
            if (ref($contents[0]) eq 'SCALAR') {
                $xml .= ${ shift @contents };
            }
            else {
                $xml .= _xmlify(splice @contents, 0, 2);
            }
        }
    }
    $xml .= "</$element>\n";
    return $xml;
}


sub new {
    my ($class, %args) = @_;
    my $self = bless {}, $class;

            $self->{gateway} = delete $args{gateway}
        and $self->{user}     = delete $args{user}
        and $self->{password} = delete $args{password}
        and $self->{context}  = delete $args{context}
        and keys(%args) == 0
        or Carp::croak(
        "Usage: $class->new(NAMED: gateway, user, password, context)");

    $self->{xmlparser} = XML::LibXML->new;

    return $self;
}

sub _request_xml {
    my ($self, $code, @contents) = @_;
    return $XMLH
        . _xmlify(
        "request",
        auth => [
            user     => $self->{user},
            password => $self->{password},
            context  => $self->{context},
        ],
        task => [
            code => $code,
            @contents,
        ]);
}


sub request {
    my ($self, $code, @contents) = @_;
    my $xml = $self->_request_xml($code, @contents);

    print STDERR $xml . $/;    #debug
    my $response = $ua->post($self->{gateway}, Content => $xml);
    if (not $response->is_success) {
        Carp::croak("Received HTTP error from AutoDNS ("
                . $response->status_line
                . ")");
    }

    $xml = $response->content;
    print STDERR $xml . $/;    #debug
    Carp::croak("Received empty document from AutoDNS.") if not length $xml;

    my $doc = eval { $self->{xmlparser}->parse_string($xml) };
    Carp::croak("Could not parse response from AutoDNS: $@") if $@;

    $code = join "", map { $_->textContent } $doc->findnodes('//status/code');

    if ($code =~ /^E/) {
        my $text = join "",
            map { $_->textContent } $doc->findnodes('//status/text');
        Carp::croak("Received error code $code from AutoDNS ($text)");
    }

    return $xml, $doc if wantarray;    # my ($xml, $doc) = $foo->request
    return $xml;                       # my $xml = $foo->request
}


sub get_zone_list {
    my ($self) = @_;

    my (undef, $doc) = $self->request('0205', view => [ offset => 0 ]);

    return map { $_->textContent } $doc->findnodes('//zone/name');
}


sub get_zone_xml {
    my ($self, $name) = @_;

    return $self->request('0205', zone => [ name => $name ]);
}


sub get_zone {
    my ($self, $name) = @_;

    my $xml = $self->get_zone_xml($name);

    return Net::DNS::AutoDNS::Zone->new_from_xml($xml, $self->{xmlparser});
}


sub create_zone {
    my ($self, $zone) = @_;

    $zone->isa('Net::DNS::AutoDNS::Zone') or Carp::croak();

    return $self->request('0201', \$zone->xml);
}


sub update_zone {
    my ($self, $zone) = @_;

    $zone->isa('Net::DNS::AutoDNS::Zone') or Carp::croak();

    return $self->request('0202', \$zone->xml);
}


sub delete_zone {
    my ($self, $name) = @_;

    if ($name->isa('Net::DNS::AutoDNS::Zone')) {
        $name = $name->{name};    # XXX
    }

    return $self->request('0203', zone => [ name => $name ]);
}

# Inject methods into alien namespaces

sub Net::DNS::RR::SOA::autodns_xml {
    my ($self) = @_;
    my $email = $self->rname;

    # AutoDNS wants one @. Pointless but let's comply.
    # XXX Resulting value is not necessarily a valid addr.
    $email =~ s/\./\@/ unless $email =~ m/@/;

    return _xmlify(
        "soa",
        refresh => $self->refresh,
        retry   => $self->retry,
        expire  => $self->expire,
        ttl     => $self->minimum,
        email   => $email,
    );
}

my $generic = sub {
    my ($self) = @_;

    my $type = $self->type;
    my $name = $self->name;
    $name =~ s/\.?XXORIGINXX\.?$//;
    my $ttl = $self->ttl;
    $ttl ||= "";

    if ($name eq '' and $type eq 'A') {

        # Special case for main IP. AutoDNS only supports zero or one;
        # external check required to ensure a second one isn't used.
        return _xmlify(
            "main",
            value => $self->address,
            ttl   => $ttl,
        );
    }

    if ($name eq '' and $type eq 'NS') {

        # Special case for zone nameservers. AutoDNS supports 1 to 7;
        # whatever calls this method should check for this.
        return _xmlify(
            "nserver",
            name => $self->nsdname,
            ttl  => $ttl,
        );
    }

    my @extra;
    push @extra, pref => $self->preference if $type eq 'MX';
    push @extra, pref => $self->priority   if $type eq 'SRV';
    push @extra, pref => $self->order      if $type eq 'NAPTR';

    my $value = (
          $type eq 'A'     ? $self->address
        : $type eq 'AAAA'  ? $self->address
        : $type eq 'CNAME' ? $self->cname . "."
        : $type eq 'NS'    ? $self->nsdname . "."
        : $type eq 'MX'    ? $self->exchange . "."
        : $type eq 'PTR'   ? $self->ptrdname . "."
        : $type eq 'TXT'   ? $self->txtdata
        : $type eq 'SRV'
        ? join(" ", map { $self->$_ } qw/weight port target/) . "."
        : $type eq 'NAPTR' ? join(
            " ",
            map { _escape($self->$_) }
                qw(
                preference flags service regexp replacement
                ))
        : $type eq 'HINFO' ? join(
            " ",
            map { _escape($self->$_) }
                qw(
                cpu os
                ))
        : die "Unknown value type for type $type"
    );

    return _xmlify(
        "rr",
        type  => $type,
        name  => $name,
        ttl   => $ttl,
        value => $value,
        @extra,
    );
};

*Net::DNS::RR::A::autodns_xml     = $generic;
*Net::DNS::RR::CNAME::autodns_xml = $generic;
*Net::DNS::RR::AAAA::autodns_xml  = $generic;
*Net::DNS::RR::NS::autodns_xml    = $generic;
*Net::DNS::RR::MX::autodns_xml    = $generic;
*Net::DNS::RR::PTR::autodns_xml   = $generic;
*Net::DNS::RR::TXT::autodns_xml   = $generic;
*Net::DNS::RR::SRV::autodns_xml   = $generic;
*Net::DNS::RR::NAPTR::autodns_xml = $generic;
*Net::DNS::RR::HINFO::autodns_xml = $generic;


1;

__END__

=pod

=head1 NAME

Net::DNS::AutoDNS - Generates XML and communicates with AutoDNS

=head1 VERSION

version 0.1

=head1 SYNOPSIS

    use Net::DNS::AutoDNS;

    my $autodns = Net::DNS::AutoDNS->new(
        gateway  => 'http://autodns.example.org/gateway/',
        user     => '...',
        password => '...',
        context  => '...',
    );

    my $xml_snippet = $rr->autodns_xml;

=head1 DESCRIPTION

This module adds methods to several Net::DNS::RR classes (by boldly invading
their namespaces) and provides a simple interface to the AutoDNS gateway.
This module doesn't quite really support UTF-8, and apparently neither does
AutoDNS, but its documentation states that encoding="utf-8" is required.

=head1 METHODS

=head2 new (gateway => $gateway, user => $user, password => $password,
context => $context)

Creates a new AutoDNS object and returns it. C<$context> is part of the
authentication information, not related to Perl's use of the word "context".

=head2 request ($code, element => contents, ...)

Sends a request to AutoDNS. In scalar context, returns the response XML text.
In list context, returns the XML text and an XML document object.

Request codes are documented in the AutoDNS Interface Documentation. The codes
must be passed as strings, including leading C<0>'s.

The contents are a key/value list, where the value is a string or an ARRAY
reference with another key/value list. These can be nested.

For example, this list:

    '1234', root => [
        a => "Example",
        b => "Voorbeeld",
        c => [
            d => "More",
        ],
    ];

will result in the following XML to be submitted:

    <?xml...?>
    <request>
        <auth>...</auth>
        <task>
            <code>1234</code>
            <a>Example</a>
            <b>Voorbeeld</b>
            <c>
                <d>More</d>
            </c>
        </task>
    </request>

In the key/value list, references to strings of literal XML may be passed at
any position. They are mixed into the request string without verification.

On failure, an exception is thrown.

=head2 get_zone_list

Issues request 0205. Retuns a list of zone names.

=head2 get_zone_xml ($name)

Issues request 0205 to request a single zone. Returns the response XML document
as a string and/or a document object, like the C<request> method.

=head2 get_zone ($name)

Issues request 0205 to request a single zone. Returns a Net::DNS::AutoDNS::Zone
object.

=head2 create_zone ($zone)

Issues request 0201 to create a zone. Requires a Net::DNS::AutoDNS::Zone object.
Returns what the C<request> method returns.

=head2 update_zone ($zone)

Issues request 0202 to update a zone. Requires a Net::DNS::AutoDNS::Zone object.
Returns what the C<request> method returns.

=head2 delete_zone ($name)

Issues request 0203 to delete a zone. Requires a Net::DNS::AutoDNS::Zone object
or the name of a zone. Returns what the C<request> method returns.

=head1 Other classes

=head2 Net::DNS::AutoDNS::Zone

Class for objects representing zones in AutoDNS. See L<Net::DNS::AutoDNS::Zone>.

=head1 Monkeypatched methods

=head2 Net::DNS::RR::<type>::autodns_xml

Returns a piece of XML representing the RR in AutoDNS format. To check if a
certain RR type is supported by this module, you can use:

    if ($rr->can('autodns_xml')) { print $rr->autodns_xml; }

As of december 2009, the following record types are supported by AutoDNS and
this module: A, MX, CNAME, NS, PTR, HINFO, TXT, AAAA, SRV, NAPTR.

Note that AutoDNS mutilates records by removing C<"> characters, making it
impossible to use whitespace in values.

Absolute hostnames have their origin replaced by C<XXORIGINXX.> in the value.

=head1 CAVEATS

SSL CERTIFICATES ARE ACCEPTED WITHOUT VERIFICATION. Vulnerable to MITM attacks
and DNS/resolver (cache) poisoning/hijacking. (The underlying SSL module may
implement checks. See L<LWP> for a list of supported modules, and their
respective manuals.)

XML entities emitted are numeric (decimal).

Validity and wellformedness are not verified.

Behaviour for non-ASCII data is undefined.

=head1 SEE ALSO

L<Net::DNS::AutoDNS::Zone>, L<Net::DNS>

L<http://www.cpanel.com/>, L<http://www.autodns.com/>

AutoDNS Interface Documentation

=head1 AUTHOR

Juerd Waalboer <juerd@tnx.nl>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2013 by Juerd Waalboer.

This is free software, licensed under:

  The (three-clause) BSD License

=cut
