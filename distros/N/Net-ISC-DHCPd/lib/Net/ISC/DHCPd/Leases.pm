package Net::ISC::DHCPd::Leases;

=head1 NAME

Net::ISC::DHCPd::Leases - Parse ISC DHCPd leases

=head1 SYNOPSIS

    my $leases = Net::ISC::DHCPd::Leases->new(
                     file => '/var/lib/dhcp3/dhcpd.leases',
                 );

    # parse the leases file
    $leases->parse;

    for my $lease ($leases->leases) {
        say "lease has ended" if($lease->ends < time);
    }

    if(my $n = $leases->find_leases({ ends => time }) {
        say "$n lease(s) has expired now";
    }

=head1 DESCRIPTION

An object constructed from this class represents a leases file for
the dhcpd server. It is read-only, so changes to the leases file
must be done through a running server, using L<Net::ISC::DHCPd::OMAPI>.

The object has one important attribute, which is L</leases>. This
attribute holds a list of L<Net::ISC::DHCPd::Leases::Lease> objects
constructed from all the leases found in the leases file.

=cut

use Moose;
use Net::ISC::DHCPd::Leases::Lease;
use MooseX::Types::Path::Class 0.05 qw(File);
use Time::Local;

=head1 ATTRIBUTES

=head2 leases

Holds a list of all the leases found after reading the leases file.

=cut

has leases => (
    is => 'ro',
    isa => 'ArrayRef',
    auto_deref => 1,
    default => sub { [] },
);

=head2 file

This attribute holds a L<Path::Class::File> object to the leases file.
It is read-write and the default value is "/var/lib/dhcp3/dhcpd.leases".

=cut

has file => (
    is => 'rw',
    isa => File,
    coerce => 1,
    default => sub {
        Path::Class::File->new('', 'var', 'lib', 'dhcp3', 'dhcpd.leases');
    },
);

has fh => (
    is => 'rw',
    isa => 'FileHandle',
    required => 0,
);

has _filehandle => (
    is => 'ro',
    lazy_build => 1,
);

sub _build__filehandle {
    my $self = shift;
    if ($self->fh) {
        return $self->fh;
    }

    $self->file->openr;
}

__PACKAGE__->meta->add_method(filehandle => sub {
    Carp::cluck('->filehandle is replaced with private attribute _filehandle');
    shift->_filehandle;
});

=head1 METHODS

=head2 parse

Read lines from L</file>, and parses every lease it can find.
Returns the number of leases found. Will add each found lease to
L</leases>.

=cut

our $DATE    = qr# (\d{4})/(\d\d)/(\d\d) \s (\d\d):(\d\d):(\d\d) #mxo;
our $START   = qr#^ lease \s ([\d\.]+) \s \{ #mxo;
our $END     = qr# } [\n\r]+ #mxo;
our $PARSER  = qr / (?| (starts) \s\d+\s (.+?)
                    | (ends)    \s\d+\s (.+?)
                    | ^\s*binding \s (state) \s (\S+)
                    | ^\s*(next) \s binding \s state \s (\S+)
                    | hardware \s (ethernet) \s (\S+)
                    | option \s agent.(remote-id) \s (.+?)
                    | option \s agent.(circuit-id) \s (.+?)
                    | client-(hostname) \s "([^"]+)"
                    ) /mxo;


sub _done {
    my ($self, $lease) = @_;

    for my $k (qw/starts ends/) {
        next unless($lease->{$k});
        if(my @values = $lease->{$k} =~ $DATE) {
            $values[1]--; # decrease month
            $lease->{$k} = timelocal(reverse @values);
        }
    }

    # rather than doing this map, we need to see if we can make Moose use
    # aliases and accept the alternate names on instantiation.  We also should
    # be able to do the mac address cleanup and validation in the
    # Net::ISC::DHCPd::Leases::Lease->new

    my %map = (
        'circuit-id' => 'circuit_id',
        'remote-id'  => 'remote_id',
        ip           => 'ip_address',
        hostname     => 'client_hostname',
        ethernet     => 'hardware_address',
    );

    for my $key (keys %map) {
        if(defined $lease->{$key}) {
            $lease->{ $map{$key} } = delete $lease->{$key};
        }
    }
    return $lease;

}

sub parse {
    my $self = shift;
    my $fh = $self->_filehandle;

    sysread $fh, my $buffer, -s $fh or die "Couldn't read file: $!";
    my $lines = 0;
    my $lease;
    while(1) {
        my $string;
        # look for lines with \r\n endings
        if($buffer =~ /^(.*?\x0d?\x0a)/s) {
            my $length = length $1;
            $string = substr($buffer,0,$length,'');
        }

        last unless $string;
        ++$lines;

        if ($lease) {
            if ($string =~ /$PARSER;/) {
                $lease->{$1} =  $2;
            } elsif($string =~ /.*?$END/) {
                # just removing this class object cuts our time in half..
                # the coercion checks and things slow us down a bunch.
                push @{$self->leases}, Net::ISC::DHCPd::Leases::Lease->new($self->_done($lease));
                #push @{$self->leases}, $self->_done($lease);
                $lease = undef;
                next;
            }
        } elsif(!$lease and $string =~ /$START/) {
            $lease = { ip => $1 };
        }
    }

    return $lines;
}

=head2 find_leases

This method will return zero or more L<Net::ISC::DHCPd::Leases::Lease>
objects as a list. It takes a hash-ref which will be matched against
the attributes of the child leases.

=cut

sub find_leases {
    my $self = shift;
    my $query = shift or return;
    my @leases;

    LEASE:
    for my $lease ($self->leases) {
        for my $key (keys %$query) {
            next LEASE unless($lease->$key eq $query->{$key});
        }
        push @leases, $lease;
    }

    return @leases;
}

=head1 COPYRIGHT & LICENSE

=head1 AUTHOR

See L<Net::ISC::DHCPd>.

=cut

1;
