package SNMP::Effective::Dispatch;

=head1 NAME

SNMP::Effective::Dispatch - Base class for SNMP::Effective

=head1 DESCRIPTION

L<SNMP::Effective> inherit from this class. The methods here are
separated out just for convenience.

=head1 PACKAGE VARIABLES

=head2 %METHOD

This hash contains a mapping between

    $effective->add($key => [...]);
    SNMP::Effective::Dispatch::_$key();
    SNMP::$value();

This means that you can add your custom SNMP method if you like.

The C<SNMP::Effective::Dispatch::_walk()> method, is a working example on this,
since it's actually a series of getnext, seen from L<SNMP>'s perspective.

Example:

    $SNMP::Effective::Dispatch::METHOD{'foo'} = 'get';
    *SNMP::Effective::Dispatch::_foo = sub {
        my($self, $host) = @_;

        # do stuff...

        return $self->_end($host);
    };

    my $effective = SNMP::Effective->new(
                        foo => [$oid],
                        # ...
                    );

    # execute() will then call $effective->_foo($host) when
    # $host answer with data
    $effective->execute;

=cut

use strict;
use warnings;
use constant DEBUG => $ENV{'SNMP_EFFECTIVE_DEBUG'} ? 1 : 0;

our %METHOD = (
    get => 'get',
    getnext => 'getnext',
    walk => 'getnext',
    set => 'set',
);

=head1 METHODS

=head2 dispatch

This method does the actual fetching, and is called by
L<SNMP::Effective/execute>.

=cut

sub dispatch {
    my $self = shift;
    my $host = shift;
    my $hostlist = $self->hostlist;
    my($request, $req_id, $snmp_method);

    $self->_wait_for_lock;

    HOST:
    while($self->{'_sessions'} < $self->max_sessions or $host) {

        unless($host) {
            $host = $hostlist->shift or last HOST;
            $host->pre_collect_callback->($host, $self);
        }

        $request = shift @$host or next HOST;
        $snmp_method = $METHOD{ $request->[0] };
        $req_id = undef;

        # fetch or create snmp session
        unless($$host) {
            next HOST unless($$host = $self->_create_session($host));
            $self->{'_sessions'}++;
        }

        # ready request
        if($$host->can($snmp_method) and $self->can("_$request->[0]")) {
            $req_id = $$host->$snmp_method(
                          $request->[1],
                          [ "_$request->[0]", $self, $host, $request->[1] ]
                      );

            warn "\$self->_$request->[0]( ${host}->$snmp_method(...) )" if DEBUG;
        }

        # something went wrong
        unless($req_id) {
            warn "Method $request->[0] failed \@ $host" if DEBUG;
            next HOST;
        }
    }
    continue {
        if(ref $$host and !ref $request) {
            warn "Completed $host" if DEBUG;
            $self->{'_sessions'}--;
        }
        if($req_id or @$host == 0) {
            $host->post_collect_callback->($host, $self);
            $host = undef;
        }
    }

    warn sprintf "Sessions/max-sessions: %i<%i", $self->{'_sessions'}, $self->max_sessions if DEBUG;

    unless($hostlist->length or $self->{'_sessions'}) {
        warn "SNMP::finish() is next up" if DEBUG;
        SNMP::finish();
    }

    $self->_unlock;

    return $hostlist->length || $self->{'_sessions'};
}

sub _set {
    my $self = shift;
    my $host = shift;
    my $request = shift;
    my $response = shift;

    return $self->_end($host, 'Timeout') unless(ref $response);

    for my $r (grep { ref $_ } @$response) {
        my $cur_oid = SNMP::Effective::make_numeric_oid($r->name);
        $host->data($r, $cur_oid);
    }

    return $self->_end($host);
}

sub _get {
    my $self = shift;
    my $host = shift;
    my $request = shift;
    my $response = shift;

    return $self->_end($host, 'Timeout') unless(ref $response);

    for my $r (grep { ref $_ } @$response) {
        my $cur_oid = SNMP::Effective::make_numeric_oid($r->name);
        $host->data($r, $cur_oid);
    }

    return $self->_end($host);
}

sub _getnext {
    my $self = shift;
    my $host = shift;
    my $request = shift;
    my $response = shift;

    return $self->_end($host, 'Timeout') unless(ref $response);

    for my $r (grep { ref $_ } @$response) {
        my $cur_oid = SNMP::Effective::make_numeric_oid($r->name);
        $host->data($r, $cur_oid);
    }

    return $self->_end($host);
}

sub _walk {
    my $self = shift;
    my $host = shift;
    my $request = shift;
    my $response = shift;
    my $i = 0;

    return $self->_end($host, 'Timeout') unless(ref $response);

    while($i < @$response) {
        my $splice = 2;

        if(my $r = $response->[$i]) {
            my($cur_oid, $ref_oid) = SNMP::Effective::make_numeric_oid($r->name, $request->[$i]->name);
            my $oid_match = SNMP::Effective::match_oid($cur_oid, $ref_oid);
            my $data_type = $r->[3] || 'UNDEF';

            $r->[0] = $cur_oid;
            $splice--;

            # valid oid
            if(defined $oid_match and $data_type ne 'NULL') {
                $host->data($r, $ref_oid);
                $splice--;
                $i++;
            }
        }

        if($splice) {
            splice @$request, $i, 1;
            splice @$response, $i, 1;
        }
    }

    if(@$response) {
        $$host->getnext($response, [ \&_walk, $self, $host, $request ]);
        return;
    }
    else {
        return $self->_end($host);
    }
}

sub _end {
    my $self = shift;
    my $host = shift;
    my $error = shift;

    warn "Calling callback for $host..." if DEBUG;

    $host->callback->($host, $error);
    $host->clear_data;

    return $self->dispatch($host)
}

=head1 AUTHOR

=head1 ACKNOWLEDGEMENTS

=head1 COPYRIGHT & LICENSE

See L<SNMP::Effective>

=cut

1;
