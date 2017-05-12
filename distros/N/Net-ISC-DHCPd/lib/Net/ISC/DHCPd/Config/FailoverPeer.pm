package Net::ISC::DHCPd::Config::FailoverPeer;

=head1 NAME

Net::ISC::DHCPd::Config::FailoverPeer - Failover Peer Configuration

=head1 DESCRIPTION

See L<Net::ISC::DHCPd::Config::Role> for methods and attributes without
documentation.

An instance from this class, comes from / will produce the block below:

    $name_attribute_value $value_attribute_value;

    failover peer "$name" {
        $primary;
        address dhcp-primary.example.com;
        port 519;
        peer address dhcp-secondary.example.com;
        peer port 520;
        max-response-delay 60;
        max-unacked-updates 10;
        mclt 3600;
        split 128;
        load balance max seconds 3;
    }

=head1 SYNOPSIS

See L<Net::ISC::DHCPd::Config/SYNOPSIS>.

=cut

use Moose;

with 'Net::ISC::DHCPd::Config::Role';

=head1 ATTRIBUTES

=head2 name

Name of the key - See L</DESCRIPTION> for details.

=head2 arguments

This is an array of arguments supplied to the failover peer.

=cut

has arguments => (
    traits => ['Hash'],
    is => 'ro',
    isa => 'HashRef',
    default => sub {
        {
        port      => { "text" => "port %s", regex => qr/^ \s+ port \s+ (\d+);/x },
        peer_port => { "text" => "peer port %s", regex => qr/^ \s+ peer \s+ port \s+ (\d+);/x },
        address   => { "text" => "address %s", regex => qr/^ \s+ address \s+ (\S+);/x },
        peer_address => { "text" => "peer address %s", regex => qr/^ \s+ peer \s+ address \s+ (\S+);/x },
        type => { "text" => "%s", regex => qr/^ \s+ (primary|secondary);/x },
        max_response_delay => { "text" => "max-response-delay %s", regex => qr/^ \s+ max-response-delay \s+ (\d+);/x },
        max_unacked_updates => { "text" => "max-unacked-updates %s", regex => qr/^ \s+ max-unacked-updates \s+ (\d+);/x },
        lb_max_seconds => { "text" => "load balance max seconds %s", regex => qr/^ \s+ load\s+balance\s+max\s+seconds \s+ (\d+);/x },
        mclt => { "text" => "mclt %s", regex => qr/^ \s+ mclt \s+ (\d+);/x },
        split => { "text" => "split %s", regex => qr/^ \s+ split \s+ (\d+);/x },
        }
    },
);

has _order => (
    traits => ['Array'],
    is => 'rw',
    isa => 'ArrayRef',
    default => sub { [] },
);

has [qw/ peer_port port mclt split lb_max_seconds max_response_delay max_unacked_updates /] => (
    is => 'rw',
    isa => 'Int',
);

has [qw/ name type address peer_address /] => (
    is => 'rw',
    isa => 'Str',
);

=head2 regex

See L<Net::ISC::DHCPd::Config::Role/regex>.

=cut
our $regex = qr{^\s* failover \s+ peer \s+ ("?)(\S+)(\1) }x;

=head1 METHODS

=head2 slurp

This method is used by L<Net::ISC::DHCPd::Config::Role/parse>, and will
slurp the content of the function, instead of trying to parse the
statements.

=cut

sub slurp {
    my($self, $line) = @_;

    while(my ($name, $value) = each (%{$self->arguments})) {
        my $regex = $value->{regex};
        if ($line =~ $regex) {
            $self->$name($1);
            push(@{$self->_order}, $name);
        }
    }

    return 'last' if($line =~ /^\s*}/);
    return 'next';
}

=head2 captured_to_args

See L<Net::ISC::DHCPd::Config::Role/captured_to_args>.

=cut

sub captured_to_args {
    return { name => $_[1] }; # $_[0] == quote or empty string
}

=head2 generate

See L<Net::ISC::DHCPd::Config::Role/generate>.

=cut

sub generate {
    my $self = shift;

    my $return = sprintf('failover peer "%s" {', $self->name);
    $return .= "\n";

    for(@{$self->_order}) {
        $return .= sprintf('    '. $self->arguments->{$_}->{text} . ";\n", $self->$_);
    }

    $return .= "}\n";

    return($return);
}

=head1 COPYRIGHT & LICENSE

=head1 AUTHOR

See L<Net::ISC::DHCPd>.

=cut
__PACKAGE__->meta->make_immutable;
1;
