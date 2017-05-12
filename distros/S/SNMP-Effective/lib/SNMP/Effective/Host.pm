package SNMP::Effective::Host;

=head1 NAME

SNMP::Effective::Host - A SNMP::Effective host class

=head1 DESCRIPTION

A host object holds all the information pr. host
L<SNMP::Effective> requires. This C<$host> object
is available in L<SNMP::Effective/THE CALLBACK METHOD>.

=cut

use warnings;
use strict;
use SNMP::Effective::VarList;
use Carp qw/ cluck confess /;

use overload '""' => sub { shift->{'_address'} };
use overload '${}' => sub { shift->{'_session'} };
use overload '@{}' => sub { shift->{'_varlist'} };

=head1 ATTRIBUTES

=head2 address

Get host address, also overloaded by "$self".

=head2 session

Get L<SNMP::Session>, also overloaded by $$self.

=head2 sesssion

Alias for L</session> (because of previous typo). Will be deprecated.

=head2 varlist

The remaining OIDs to get/set, also overloaded by @$self.

=head2 callback

Get a ref to the callback method.

=head2 heap

Get/set any data you like. By default, it returns a hash-ref, so you can do:

    $host->heap->{'mykey'} = "remember this";
 
=head2 pre_collect_callback

Holds a callback which will be called right before the first request is sent
to the target host. The callback recevies L<$self|SNMP::Effective::Host> as
the first argument and the L<SNMP::Effective> object as the second.

=head2 post_collect_callback

Holds a callback which will be called after L<SNMP::Effective> is done with
the C<$host> object. The callback recevies L<$self|SNMP::Effective::Host> as
the first argument and the L<SNMP::Effective> object as the second.

=cut

BEGIN {
    no strict 'refs';
    my %sub2key = qw/
                      address   _address
                      session   _session
                      varlist   _varlist
                      callback  _callback
                      heap      _heap
                      pre_collect_callback _pre_collect_callback
                      post_collect_callback _post_collect_callback
                  /;

    for my $subname (keys %sub2key) {
        *$subname = sub {
            my($self, $set) = @_;
            $self->{ $sub2key{$subname} } = $set if(defined $set);
            $self->{ $sub2key{$subname} };
        }
    }

    *sesssion = sub {
        cluck "->sesssion() will be deprecated. Use ->session()> instead";
        return shift->session(@_);
    };
}

=head2 arg

Get/set L<SNMP::Session> args.

=cut

sub arg {
    my $self = shift;
    my $arg = shift;

    if(ref $arg eq 'HASH') {
        $self->{'_arg'}{$_} = $arg->{$_} for(keys %$arg);
    }

    return %{$self->{'_arg'}}, DestHost => "$self" if(wantarray);
    return $self->{'_arg'};
}

=head2 data

    $hash_ref = $self->data;
    $hash_ref = $self->data(\@data0, $ref_oid0, ...);

Get the retrieved data or add more data to the host cache.

C<@data0> looks like: C<[ $oid0, $iid0, $value0, $type0 ]>, where
C<$ref_oid0> is used to figure out the C<$iid> unless specified
in C<@data0>. C<$iid0> will fallback to "1", if everything fails.

=cut

sub data {
    my $self = shift;

    if(@_) {
        my $r = shift;
        my $ref_oid = shift || '';
        my $iid = $r->[1]
               || SNMP::Effective::match_oid($r->[0], $ref_oid)
               || 1;

        $ref_oid =~ s/^\.//mx;

        $self->{'_data'}{$ref_oid}{$iid} = $r->[2];
        $self->{'_type'}{$ref_oid}{$iid} = $r->[3];
    }

    return $self->{'_data'};
}

=head1 METHODS

=head2 new

    $self = $class->new($address);

Object constructor. C<$address> can also be an ip-address.

=cut

sub new {
    my $class = shift;
    my $args = shift;
    my $log = shift;
    my($session, @varlist);

    tie @varlist, "SNMP::Effective::VarList";

    $args = { address => $args } unless(ref $args eq 'HASH');
    $args->{'address'} or confess 'Usage: $class->new(\%args)';

    return bless {
        _address => $args->{'address'},
        _arg => $args->{'arg'} || {},
        _callback => $args->{'callback'} || sub {},
        _data => {},
        _heap => $args->{'heap'},
        _session => \$session,
        _varlist => \@varlist,
        _pre_collect_callback => $args->{'pre_collect_callback'} || sub {},
        _post_collect_callback => $args->{'post_collect_callback'} || sub {},
    }, $class;
}

=head2 clear_data

Remove data from the host cache. Will make C</data> return an
empty hash-ref.

=cut

sub clear_data {
    my $self = shift;

    $self->{'_data'} = {};
    $self->{'_type'} = {};

    return;
}

=head1 AUTHOR

=head1 ACKNOWLEDGEMENTS

=head1 COPYRIGHT & LICENSE

See L<SNMP::Effective>

=cut

1;
