package Net::DNS::AutoDNS::Zone;

use strict;
use warnings;

use XML::LibXML;
use Net::DNS::Zone::ParserX;
use File::Temp ();
use Carp       ();

# ABSTRACT: Class to represent one zone in AutoDNS


my @attributes = qw(
    name ns_action allow_transfer_from allow_transfer internal_ns
    www_include
);


sub rr { return shift->{rr} }    ## no critic


sub name { return shift->{name} }    ## no critic


sub ns_action {                      ## no critic
    return @_ > 1 ? shift->{ns_action} = pop() : shift->{ns_action};
}


sub allow_transfer_from {            ## no critic
    return @_ > 1
        ? shift->{allow_transfer_from} = pop()
        : shift->{allow_transfer_from};
}


sub allow_transfer {                 ## no critic
    return @_ > 1 ? shift->{allow_transfer} = pop() : shift->{allow_transfer};
}


sub internal_ns {                    ## no critic
    return @_ > 1 ? shift->{internal_ns} = pop() : shift->{internal_ns};
}


sub www_include {                    ## no critic
    return @_ > 1 ? shift->{www_include} = pop() : shift->{www_include};
}


sub new {
    my ($class, $name) = @_;
    my $self = bless {}, $class;
    $self->{name}      = $name;
    $self->{ns_action} = 'complete';

    return $self;
}


sub clone {
    my ($self, $name) = @_;
    my $clone = bless {%$self}, ref $self;
    $clone->{name} = $name if defined $name;

    # Clone RR records via string dump + parse
    $clone->{rr} = [ map { Net::DNS::RR->new($_->string) } @${ $self->{rr} } ];
    return $clone;
}


sub new_from_zonefile {
    my ($class, $name, $zonefile) = @_;

    my $self = $class->new($name);
    $self->read_rr_from_zonefile($zonefile);

    return $self;
}


sub new_from_xml {
    my ($class, $xml, $parser) = @_;

    $parser ||= XML::LibXML->new;
    my $doc = $parser->parse_string($xml);

    my $self = $class->new("");    # name is updated later

    $self->{$_} = join "", map { $_->textContent } $doc->findnodes("//zone/$_")
        for @attributes;

    my $rr = $self->{rr} = [];

    for my $node ($doc->findnodes("//zone/soa")) {
        my %attr;
        $attr{ $_->nodeName } = $_->textContent for $node->childNodes;
        my $email = $attr{email};
        my $ns =
               $self->{internal_ns}
            || $doc->findvalue("//zone/nserver[1]/name")
            || 'intentionally.invalid';
        $email =~ s/\@/./;
        push @$rr,
            Net::DNS::RR->new(qq[XXORIGINXX. SOA $ns $email (]
                . time
                . qq[ $attr{refresh} $attr{retry} $attr{expire} $attr{ttl})]);
    }

    for my $node ($doc->findnodes("//zone/nserver")) {
        my %attr;
        $attr{ $_->nodeName } = $_->textContent for $node->childNodes;
        push @$rr,
            Net::DNS::RR->new(
            type    => 'NS',
            name    => 'XXORIGINXX',
            ttl     => $attr{ttl},
            nsdname => $attr{name},
            );
    }

    for my $node ($doc->findnodes("//zone/main")) {
        my %attr;
        $attr{ $_->nodeName } = $_->textContent for $node->childNodes;
        push @$rr,
            Net::DNS::RR->new(
            type    => 'A',
            name    => 'XXORIGINXX',
            ttl     => $attr{ttl},
            address => $attr{value},
            );
    }

    for my $node ($doc->findnodes("//zone/rr")) {
        my %attr;
        $attr{ $_->nodeName } = $_->textContent for $node->childNodes;

        utf8::encode($_) for values %attr;   # work around WEIRD bug in Net::DNS
          # Somehow, the following fails if the name has the UTF8 flag set, even
          # if there are only ASCII characters:
          # Net::DNS::RR->new(type => "NAPTR", name => "naptr.XXORIGINXX",
          # qw(order 10 preference 20 flags u service E2U+sip regexp !x!i
          # replacement hostname)

        my $type  = uc $attr{type};
        my $pref  = $attr{pref};
        my $name  = $attr{name};
        my $value = $attr{value};
        my $ttl   = $attr{ttl};

        $value =~ s/\Q$self->{name}\E\.$/XXORIGINXX./;

        my @value = split " ", $value;

        $name = $name ? "$name.XXORIGINXX" : "XXORIGINXX";

        if ($type eq 'TXT') {

            # Special case for TXT because it won't be created from a hash
            $value =~ s/([\"])/\\$1/g;
            push @$rr,
                Net::DNS::RR->new(qq[$name.XXORIGINXX. $ttl TXT "$value"]);
            next;
        }
        push @$rr,
            Net::DNS::RR->new(
            name => $name,
            ttl  => $ttl,
            type => $type,
            $type   eq 'A'     ? (address => $value)
            : $type eq 'AAAA'  ? (address => $value)
            : $type eq 'CNAME' ? (cname   => $value)
            : $type eq 'NS'    ? (nsdname => $value)
            : $type eq 'MX' ? (exchange => $value, preference => $pref)
            : $type eq 'PTR' ? (ptrdname => $value)
            : $type eq 'HINFO' ? (cpu => $value[0], os => $value[1])
            : $type eq 'SRV' ? (
                priority => $pref,
                weight   => $value[0],
                port     => $value[1],
                target   => $value[2])
            : $type eq 'NAPTR' ? (
                order       => $pref,
                preference  => $value[0],
                flags       => $value[1],
                service     => $value[2],
                regexp      => $value[3],
                replacement => $value[4])
            : die "Unsupported RR type, $type"
            );
    }

    for my $node ($doc->findnodes("//zone/free")) {
        my $free = $node->textContent;
        $free =~ s/\.\Q$self->{name}\E\.(?=\s)/.XXORIGINXX./;
        push @$rr, Net::DNS::RR->new($node->textContent);
    }

    return $self;
}


sub read_rr_from_zonefile {
    my ($self, $zonefile) = @_;

    $zonefile =~
        s/((?<!\S)(?:\S+\.)?)\Q$self->{name}\E\.(?=$|\s)/${1}XXORIGINXX./mg;

    my $tmp = File::Temp->new(UNLINK => 0);
    print {$tmp} $zonefile;
    close $tmp or die "Could not write to temporary file: $!";

    my $parser = Net::DNS::Zone::ParserX->new;
    my $error  = $parser->read(
        $tmp->filename, {
            CREATE_RR => 1,
            ORIGIN    => "XXORIGINXX.",
        });

    unlink $tmp or 1;
    Carp::croak($error) if $error;

    $self->{rr} = $parser->get_array;

    return;
}


sub zonefile {
    my ($self) = @_;

    my @zonefile = map { $_->string . "\n" } @{ $self->{rr} };
    s/XXORIGINXX\./$self->{name}./g for @zonefile;
    s/^(?=\s)/\@/g                  for @zonefile;

    return join "", @zonefile;
}


sub xml {
    my ($self) = @_;

    my $records = "";
    my %seen;
    for (@{ $self->{rr} }) {
        my $record = $_->autodns_xml;

        # Silently discard excess records, beyond AutoDNS' artificial limits
        $records .= $record
            unless $record =~ /<main>/ and ++$seen{main} > 1
                or $record =~ /<nserver>/ and ++$seen{nserver} > 7;
    }

    my $xml =
        Net::DNS::AutoDNS::_xmlify("zone",
        (map { $_ => $self->{$_} } @attributes), \$records);
    $xml =~ s/XXORIGINXX\.?/$self->{name}./g;

    return $xml;
}


1;

__END__

=pod

=head1 NAME

Net::DNS::AutoDNS::Zone - Class to represent one zone in AutoDNS

=head1 VERSION

version 0.1

=head1 SYNOPSIS

    use Net::DNS::AutoDNS;
    use File::Slurp;

    my $autodns = Net::DNS::AutoDNS->new(...);
    my $zone = $autodns->get_zone("example.org");
    my $contents = read_file "example.org.new";
    $zone->read_rr_from_zonefile($contents);
    $autodns->update($zone);

=head1 DESCRIPTION

By internally keeping records as Net::DNS::RR objects as an in-between format,
this module intends to bridge between AutoDNS and regular zonefiles.

However, directly converting between the two is possibly lossy. This module
does not attempt to translate records of types that AutoDNS does not support.

The functionality is very limited; only what was needed to implement Cpanel
support was implemented.

=head1 ATTRIBUTES

=head2 rr

reference to the array of record objects.

=head2 name

string; required. Read-only.

=head2 ns_action ($new_value)

Attribute; string; optional. Note: semantics ignored.

Should be C<complete> or C<primary>.

=head2 allow_transfer_from ($new_value)

string; optional.

=head2 allow_transfer ($new_value);

0 or 1; optional.

=head2 internal_ns ($new_value);

string; optional.

=head2 www_include ($new_value);

0 or 1; optional.

=head1 METHODS

=head2 new ($name)

Create a new, empty, zone object for the origin C<$name>.

=head2 clone ($name)

Given the name of the new zone, returns a new zone object, copying the
attributes of the source.

=head2 new_from_zonefile ($name, $zonefile)

Combines C<new> with C<read_rr_from_zonefile> in one call.

=head2 new_from_xml ($xml, $xmlparser)

Parses an existing AutoDNS XML document, where C<$xml> is the document itself.

C<$xmlparser> is an optional XML::LibXML instance. If none is given, a new
one will be created and discarded after use.

=head2 read_rr_from_zonefile ($zonefile)

Parses a zonefile where C<$zonefile> is the zonefile data itself, not a
filename.

=head2 zonefile

Returns the zone in zonefile format.

=head2 xml

Returns the zone in the AutoDNS XML format.

=head1 CAVEATS

This module does not validate data.

Behaviour for non-ASCII data is undefined.

AutoDNS supports extra meta-information for DNS zones. When updating an existing
zone with regular zonefile data, it is recommended that you retrieve the zone
from AutoDNS, then update the records, and then submit the zone back. If you
create a new object, information like the C<ns_action> and
C<allow_transfer_from> may be lost.

Internally, the origin is always called C<XXORIGINXX>. This renders using this
as part of a hostname impossible.

Email addresses are only interpreted correctly if they do not contain any
C<.> before the C<@>. Because DNS doesn't support the C<@>, the C<@> is
converted to a C<.>. However, because AutoDNS needs the C<@>, the first C<.> is
converted back to an C<@>. This results in C<j.doe@example.org> being
transformed to C<j@doe.example.org>, while C<john@example.org> remains
unchanged.

Relative hostnames on the right hand side may not round-trip correctly. This
is currently considered unimportant because AutoDNS will make them absolute.

=head2 Caveats for C<new_from_zonefile> and C<read_rr_from_zonefile>

The behaviour for zonefiles including $-statements like C<$ORIGIN> and
C<$INCLUDE> and C<$GENERATE> is undefined. The current implementation does
handle them (and $INCLUDE does read arbitrary files!) but a future
implementation may use a different parser.

Unsupported records are silently discarded.

The C<ignore> attribute of C<SOA> records is B<silently discarded>, as is the
C<serial>.

=head2 Caveats for C<new_from_xml>

While unknown records are B<silently discarded> from zonefiles, records of the
C<< <free> >> type from AutoDNS are passed B<as is> when converting to
zonefiles. This means that after a round trip, records of unsupported types are
gone, and records of supported types are converted to their respective
non-freeform syntaxes.

=head2 Caveats for C<zonefile> output

The C<serial> of the C<SOA> is always 0.

The C<nameserver> field of the C<SOA> is always C<intentionally.invalid>.

=head2 Caveats for C<xml> output

AutoDNS supports only one A record for the origin itself. Additional such
records are silently discarded.

AutoDNS supports up to 7 NS records for the origin itself. Additional such
records are silently discarded.

=head1 SEE ALSO

L<Net::DNS::AutoDNS>, L<Net::DNS>

=head1 AUTHOR

Juerd Waalboer <juerd@tnx.nl>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2013 by Juerd Waalboer.

This is free software, licensed under:

  The (three-clause) BSD License

=cut
