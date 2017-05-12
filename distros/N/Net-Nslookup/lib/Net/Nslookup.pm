package Net::Nslookup;

# -------------------------------------------------------------------
# Net::Nslookup - Provide nslookup(1)-like capabilities
# Copyright (C) 2002-2013 darren chamberlain <darren@cpan.org>
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License as
# published by the Free Software Foundation; version 2.
#
# This program is distributed in the hope that it will be useful, but
# WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
# General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program; if not, write to the Free Software
# Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA
# 02111-1307  USA
# -------------------------------------------------------------------

use strict;
use vars qw($VERSION $DEBUG @EXPORT $TIMEOUT $WIN32);
use base qw(Exporter);

$VERSION    = "2.04";
@EXPORT     = qw(nslookup);
$DEBUG      = 0 unless defined $DEBUG;
$TIMEOUT    = 15 unless defined $TIMEOUT;
$WIN32      = $^O =~ /win32/i; 

use Exporter;

my %_methods = qw(
    A       address
    CNAME   cname
    MX      exchange
    NS      nsdname
    PTR     ptrdname
    TXT     rdatastr
    SOA     dummy
    SRV     target
);

# ----------------------------------------------------------------------
# nslookup(%args)
#
# Does the actual lookup, deferring to helper functions as necessary.
# ----------------------------------------------------------------------
sub nslookup {
    my $options = isa($_[0], 'HASH') ? shift : @_ % 2 ? { 'host', @_ } : { @_ };
    my ($term, $type, @answers);

    # Some reasonable defaults.
    $term = lc ($options->{'term'} ||
                $options->{'host'} ||
                $options->{'domain'} || return);
    $type = uc ($options->{'type'} ||
                $options->{'qtype'} || "A");
    $options->{'server'} ||= '';
    $options->{'recurse'} ||= 0;

    $options->{'timeout'} = $TIMEOUT
        unless defined $options->{'timeout'};

    $options->{'debug'} = $DEBUG 
        unless defined $options->{'debug'};

    eval {
        local $SIG{ALRM} = sub { die "alarm\n" };
        alarm $options->{'timeout'} unless $WIN32;

        my $meth = $_methods{ $type } || die "Unknown type '$type'";
        my $res = ns($options->{'server'});

        if ($options->{'debug'}) {
            warn "Performing `$type' lookup on `$term'\n";
        }

        if (my $q = $res->search($term, $type)) {
            if ('SOA' eq $type) {
                my $a = ($q->answer)[0];
                @answers = (join " ", map { $a->$_ }
                    qw(mname rname serial refresh retry expire minimum));
            }
            else {
                @answers = map { $_->$meth() } grep { $_->type eq $type } $q->answer;
            }

            # If recurse option is set, for NS, MX, and CNAME requests,
            # do an A lookup on the result.  False by default.
            if ($options->{'recurse'}   &&
                (('NS' eq $type)        ||
                 ('MX' eq $type)        ||
                 ('CNAME' eq $type)
                )) {

                @answers = map {
                    nslookup(
                        host    => $_,
                        type    => "A",
                        server  => $options->{'server'},
                        debug   => $options->{'debug'}
                    );
                } @answers;
            }
        }

        alarm 0 unless $WIN32;
    };

    if ($@) {
        die "nslookup error: $@"
            unless $@ eq "alarm\n";
        warn qq{Timeout: nslookup("type" => "$type", "host" => "$term")};
    }

    return $answers[0] if (@answers == 1);
    return (wantarray) ? @answers : $answers[0];
}

{
    my %res;
    sub ns {
        my $server = shift || "";

        unless (defined $res{$server}) {
            require Net::DNS;
            import Net::DNS;
            $res{$server} = Net::DNS::Resolver->new;

            # $server might be empty
            if ($server) {
                if (ref($server) eq 'ARRAY') {
                    $res{$server}->nameservers(@$server);
                }
                else {
                    $res{$server}->nameservers($server);
                }
            }
        }

        return $res{$server};
    }
}

sub isa { &UNIVERSAL::isa }

1;
__END__

=head1 NAME

Net::Nslookup - Provide nslookup(1)-like capabilities

=head1 SYNOPSIS

  use Net::Nslookup;
  my @addrs = nslookup $host;

  my @mx = nslookup(type => "MX", domain => "perl.org");

=head1 DESCRIPTION

C<Net::Nslookup> provides the capabilities of the standard UNIX
command line tool F<nslookup(1)>. C<Net::DNS> is a wonderful and
full featured module, but quite often, all you need is `nslookup
$host`.  This module provides that functionality.

C<Net::Nslookup> exports a single function, called C<nslookup>.
C<nslookup> can be used to retrieve A, PTR, CNAME, MX, NS, SOA, 
TXT, and SRV records.

  my $a  = nslookup(host => "use.perl.org", type => "A");

  my @mx = nslookup(domain => "perl.org", type => "MX");

  my @ns = nslookup(domain => "perl.org", type => "NS");

  my $name = nslookup(host => "206.33.105.41", type => "PTR");

  my @srv = nslookup(term => "_jabber._tcp.gmail.com", type => "SRV");

C<nslookup> takes a hash of options, one of which should be I<term>,
and performs a DNS lookup on that term.  The type of lookup is
determined by the I<type> argument.  If I<server> is specified (it
should be an IP address, or a reference to an array of IP
addresses), that server(s) will be used for lookups.

If only a single argument is passed in, the type defaults to I<A>,
that is, a normal A record lookup.

If C<nslookup> is called in a list context, and there is more than
one address, an array is returned.  If C<nslookup> is called in a
scalar context, and there is more than one address, C<nslookup>
returns the first address.  If there is only one address returned,
then, naturally, it will be the only one returned, regardless of the
calling context.

I<domain> and I<host> are synonyms for I<term>, and can be used to
make client code more readable.  For example, use I<domain> when
getting NS records, and use I<host> for A records; both do the same
thing.

I<server> should be a single IP address or a reference to an array
of IP addresses:

  my @a = nslookup(host => 'example.com', server => '4.2.2.1');

  my @a = nslookup(host => 'example.com', server => [ '4.2.2.1', '128.103.1.1' ])

By default, when doing CNAME, MX, and NS lookups, C<nslookup>
returns names, not addresses.  This is a change from versions prior
to 2.0, which always tried to resolve names to addresses.  Pass the
I<recurse =E<gt> 1> flag to C<nslookup> to have it follow CNAME, MX,
and NS lookups.  Note that this usage of "recurse" is not consistent
with the official DNS meaning of recurse.

    # returns soemthing like ("mail.example.com")
    my @mx = nslookup(domain => 'example.com', type => 'MX');

    # returns soemthing like ("127.0.0.1")
    my @mx = nslookup(domain => 'example.com', type => 'MX', recurse => 1);

SOA lookups return the SOA record in the same format as the `host`
tool:

    print nslookup(domain => 'example.com', type => 'SOA');
    dns1.icann.org. hostmaster.icann.org. 2011061433 7200 3600 1209600 3600

=head1 TIMEOUTS

Lookups timeout after 15 seconds by default, but this can be configured
by passing I<timeout =E<gt> X> to C<nslookup>.

=head1 DEBUGGING

Pass I<debug =E<gt> 1> to C<nslookup> to emit debugging messages to STDERR.

=head1 AUTHOR

darren chamberlain <darren@cpan.org>

