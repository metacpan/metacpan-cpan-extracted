package Net::ISC::DHCPd::Types;

=head1 NAME

Net::ISC::DHCPd::Types - Moose type constraint declaration

=head1 SYNOPSIS

 use Net::ISC::DHCPd::Types @types;
 has foo => ( isa => SomeType, ... );

=cut

use Moose;
use MooseX::Types;
use MooseX::Types::Moose ':all';

my @type_list;
my @failover_states = (
    "na",                     "partner down",
    "normal",                 "communications interrupted",
    "resolution interrupted", "potential conflict",
    "recover",                "recover done",
    "shutdown",               "paused",
    "startup",                "recover wait",
);
my @states = qw/
    na free active expired released
    abandoned reset backup reserved bootp
/;

BEGIN {
    MooseX::Types->import(-declare => [@type_list = qw/
        HexInt Ip Mac State Time Statements FailoverState
        ConfigObject LeasesObject OMAPIObject ProcessObject
    /]);
}

my $MAC_REGEX = '^'. join(':', (q{[0-9a-f]{1,2}}) x 6) . '$';

=head1 TYPES

=head2 HexInt

=head2 Ip

=head2 Mac

=head2 State

=head2 Time

=cut

subtype State, as Str,
    where { my $s = $_; return grep { $s eq $_ } @states };
subtype FailoverState, as Str,
    where { my $s = $_; return grep { $s eq $_ } @failover_states };
subtype HexInt, as Int;
subtype Ip, as Str,
    where { /^[\d.]+$/ };
subtype Mac, as Str,
    where { /$MAC_REGEX/i };

subtype Time, as Int;

coerce State, (
    from Str, via { /(\d+)$/ ? $states[$1] : undef }
);

=head2 from_State

=cut

sub from_State {
    my $self = shift;
    my $attr = shift;
    my $value = $self->$attr or return 0;

    for my $i (0..@states) {
        return $i if($states[$i] eq $value);
    }

    return 0;
}

coerce FailoverState, (
    from Str
);

=head2 from_FailoverState

=cut

sub from_FailoverState {
    my $self = shift;
    my $attr = shift;
    my $value = $self->$attr or return 0;

    for my $i (0..@failover_states) {
        return $i if($failover_states[$i] eq $value);
    }

    return 0;
}

coerce HexInt, (
    from Str, via { s/://g; hex $_ },
);

coerce Ip, (
    from Str, via { join '.', map { hex $_ } split /:/ },
);

coerce Mac, (
    from Str, via {
            my @mac = split /[\-\.:]/;
            my $format = scalar @mac == 3 ? '%04s' : '%02s';
            my $str = join '', map { sprintf $format, $_ } @mac; # fix single digits 0:x:ff:00:00:01
            # the following line handles mac addresses in the format of 123456789101
            # or any other weirdness the above didn't take care of.
            $_ = $str;
            return join ':', /(\w\w)/g; # rejoin with colons
    },
);

coerce Time, (
    from Str, via { s/://g; hex $_ },
);

=head2 Statements

=cut

subtype Statements, as Str, where { /^[\w,]+$/ };

coerce Statements, (
    from Str, via { s/\s+/,/g; $_; },
    from ArrayRef, via { join ",", @$_ },
);

=head2 ConfigObject

=head2 LeasesObject

=head2 OMAPIObject

=head2 ProcessObject

=cut

subtype ConfigObject, as Object;
subtype LeasesObject, as Object;
subtype OMAPIObject, as Object;
subtype ProcessObject, as Object;

coerce ConfigObject, from HashRef, via {
    eval "require Net::ISC::DHCPd::Config" or confess $@;
    Net::ISC::DHCPd::Config->new($_);
};
coerce LeasesObject, from HashRef, via {
    eval "require Net::ISC::DHCPd::Leases" or confess $@;
    Net::ISC::DHCPd::Leases->new($_);
};
coerce OMAPIObject, from HashRef, via {
    eval "require Net::ISC::DHCPd::OMAPI" or confess $@;
    Net::ISC::DHCPd::OMAPI->new($_);
};
coerce ProcessObject, from HashRef, via {
    eval "require Net::ISC::DHCPd::Process" or confess $@;
    Net::ISC::DHCPd::Process->new($_);
};

=head2 get_type_list

 @names = $class->get_type_list;

Returns the types defined in this package.

=cut

sub get_type_list {
    return @type_list;
}

=head1 COPYRIGHT & LICENSE

=head1 AUTHOR

See L<Net::ISC::DHCPd>.

=cut
__PACKAGE__->meta->make_immutable;
1;
