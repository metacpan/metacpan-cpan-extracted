package Pcore::API::ProxyPool;

use Pcore -class;
use Pcore::API::ProxyPool::Storage;

has id => ( is => 'lazy', isa => Int, init_arg => undef );

has load_timeout          => ( is => 'ro', isa => PositiveOrZeroInt, default => 60 );     # 0 - don't re-load proxy sources
has connect_error_timeout => ( is => 'ro', isa => PositiveInt,       default => 180 );    # timeout for re-check disabled proxies
has max_connect_errors    => ( is => 'ro', isa => PositiveInt,       default => 5 );      # max. failed check attempts, after proxy will be removed
has ban_timeout           => ( is => 'ro', isa => PositiveOrZeroInt, default => 60 );
has max_threads_proxy     => ( is => 'ro', isa => PositiveOrZeroInt, default => 20 );
has max_threads_source    => ( is => 'ro', isa => PositiveOrZeroInt, default => 0 );
has maintanance_timeout   => ( is => 'ro', isa => PositiveInt,       default => 60 );

has _source => ( is => 'ro', isa => ArrayRef [ ConsumerOf ['Pcore::API::ProxyPool::Source'] ], default => sub { [] }, init_arg => undef );
has _timer => ( is => 'ro', init_arg => undef );

has list => ( is => 'ro', isa => HashRef, default => sub { {} }, init_arg => undef );
has storage => ( is => 'lazy', isa => InstanceOf ['Pcore::API::ProxyPool::Storage'], init_arg => undef );

has _waiting_callbacks => ( is => 'ro', isa => ArrayRef, default => sub { [] }, init_arg => undef );

has is_proxy_pool => ( is => 'ro', default => 1, init_arg => undef );

sub BUILD ( $self, $args ) {
    if ( $args->{source} ) {
        for my $source_args ( $args->{source}->@* ) {
            my %args = $source_args->%*;

            $args{pool} = $self;

            my $source = P->class->load( delete $args{class}, ns => 'Pcore::API::ProxyPool::Source' )->new( \%args );

            # add source to the pool
            push $self->_source->@*, $source;
        }
    }

    # create timer
    $self->{_timer} = AE::timer $self->maintanance_timeout, $self->maintanance_timeout, sub {
        $self->_maintenance;

        return;
    };

    $self->_maintenance;

    return;
}

sub _build_id ($self) {
    state $id = 0;

    return ++$id;
}

sub _build_storage ($self) {
    return Pcore::API::ProxyPool::Storage->new( { pool_id => $self->id } );
}

sub _maintenance ($self) {

    # load sources
    for my $source ( $self->_source->@* ) {
        $source->load;
    }

    my $time = time;

    my $updates_proxies = {};

    # clear connection errors
    if ( my $released_connect_error = $self->storage->release_connect_error($time) ) {
        for my $hostport ( $released_connect_error->@* ) {
            $self->{list}->{$hostport}->{connect_error} = 0;

            $updates_proxies->{$hostport} = 1;
        }
    }

    # release bans
    if ( my $released_ban = $self->storage->release_ban($time) ) {
        for my $row ( $released_ban->@* ) {
            delete $self->{list}->{ $row->{hostport} }->{_ban_list}->{ $row->{ban_id} };

            $updates_proxies->{ $row->{hostport} } = 1;
        }
    }

    for ( keys $updates_proxies->%* ) {
        $self->{list}->{$_}->_on_status_change;
    }

    return;
}

sub get_slot ( $self, $connect, @ ) {
    my $cb = $_[-1];

    my %args = (
        wait   => 0,
        ban_id => undef,    # check for ban
        splice @_, 2, -1,
    );

    # parse connect attribute
    $connect = Pcore::AE::Handle2::get_connect($connect);

    my $proxy;

    $proxy = $self->_find_proxy( $connect, $args{ban_id} ) if $self->{list}->%*;

    if ($proxy) {
        $cb->($proxy);
    }
    elsif ( !$args{wait} ) {
        $cb->(undef);
    }
    else {
        push $self->{_waiting_callbacks}->@*, [ $cb, $connect, $args{ban_id} ];
    }

    return;
}

# called when source load new proxies or from proxy on_status_change
sub _on_status_change ($self) {
    return if !$self->{_waiting_callbacks}->@*;

    my $i = 0;

    while (1) {

        # $wait_slot_cb = [ $cb, $connect, $ban_id ]
        my $wait_slot_cb = $self->{_waiting_callbacks}->[$i];

        if ( my $proxy = $self->_find_proxy( $wait_slot_cb->[1], $wait_slot_cb->[2] ) ) {
            splice $self->{_waiting_callbacks}->@*, $i, 1;

            $wait_slot_cb->[0]->($proxy);
        }
        else {
            $i++;
        }

        last if $i > $self->{_waiting_callbacks}->$#*;
    }

    return;
}

sub _find_proxy ( $self, $connect, $ban_id ) {
    my $dbh = $self->storage->dbh;

    state $q = $dbh->prepare(
        <<'SQL'
            SELECT "hostport"
            FROM "proxy"
            LEFT JOIN "proxy_connect" ON "proxy"."id" = "proxy_connect"."proxy_id"
            WHERE
                "proxy"."connect_error" = 0
                AND "proxy"."source_enabled" = 1
                AND "proxy"."weight" > 0
                AND (
                    "proxy_connect"."connect_id" IS NULL          -- not tested connection
                    OR (
                        "proxy_connect"."connect_id" = ?          -- or tested connection with required id
                        AND "proxy_connect"."proxy_type" > 0      -- and positive test result
                    )
                )
            ORDER BY "proxy"."weight" ASC
            LIMIT 1
SQL
    );

    state $q_ban_check = $dbh->prepare(
        <<'SQL'
                SELECT "hostport"
                FROM
                ( SELECT "id", "hostport", "weight"
                        FROM "proxy"
                        LEFT JOIN "proxy_connect" ON "proxy"."id" = "proxy_connect"."proxy_id"
                        WHERE
                            "proxy"."connect_error" = 0
                            AND "proxy"."source_enabled" = 1
                            AND "proxy"."weight" > 0
                            AND (
                                "proxy_connect"."connect_id" IS NULL          -- not tested connection
                                OR (
                                    "proxy_connect"."connect_id" = ?          -- or tested connection with required id
                                    AND "proxy_connect"."proxy_type" > 0      -- and positive test result
                                )
                            )
                ) "proxy"
                LEFT JOIN "proxy_ban" ON "proxy"."id" = "proxy_ban"."proxy_id"
                WHERE
                    "proxy_ban"."ban_id" IS NULL
                    OR "proxy_ban"."ban_id" != ?                               -- ban id is not match
                ORDER BY "proxy"."weight" ASC
                LIMIT 1
SQL
    );

    my $res;

    if ( defined $ban_id ) {
        $res = $dbh->selectrow( $q_ban_check, [ $self->storage->_connect_id->{ $connect->[3] }, $ban_id ] );
    }
    else {
        $res = $dbh->selectrow( $q, [ $self->storage->_connect_id->{ $connect->[3] } ] );
    }

    if ($res) {
        return $self->list->{ $res->{hostport} };
    }
    else {
        return;
    }

    return;
}

1;
## -----SOURCE FILTER LOG BEGIN-----
##
## PerlCritic profile "pcore-script" policy violations:
## +------+----------------------+----------------------------------------------------------------------------------------------------------------+
## | Sev. | Lines                | Policy                                                                                                         |
## |======+======================+================================================================================================================|
## |    3 | 208, 211             | Subroutines::ProtectPrivateSubs - Private subroutine/method used                                               |
## +------+----------------------+----------------------------------------------------------------------------------------------------------------+
##
## -----SOURCE FILTER LOG END-----
__END__
=pod

=encoding utf8

=head1 NAME

Pcore::API::ProxyPool

=head1 SYNOPSIS

=head1 DESCRIPTION

=cut
