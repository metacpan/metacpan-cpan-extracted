package Pcore::API::ProxyPool::Source;

use Pcore -role;
use Pcore::API::ProxyPool::Proxy;

requires qw[load];

has pool => ( is => 'ro', isa => InstanceOf ['Pcore::API::ProxyPool'], required => 1, weak_ref => 1 );
has id => ( is => 'lazy', isa => Int, init_arg => undef );

has load_timeout          => ( is => 'lazy', isa => PositiveOrZeroInt );
has connect_error_timeout => ( is => 'lazy', isa => PositiveInt );
has max_connect_errors    => ( is => 'lazy', isa => PositiveInt );
has max_threads_proxy     => ( is => 'lazy', isa => PositiveOrZeroInt );
has max_threads_source    => ( is => 'lazy', isa => PositiveOrZeroInt );
has is_multiproxy         => ( is => 'ro',   isa => Bool, default => 0 );    # proxy can not be banned

has threads => ( is => 'ro', default => 0, init_arg => undef );              # current threads (running request through this source)
has total_threads => ( is => 'ro', isa => Int, default => 0, init_arg => undef );    # total connections was made through this source

has _load_next_time   => ( is => 'ro', init_arg => undef );
has _load_in_progress => ( is => 'ro', init_arg => undef );

around load => sub ( $orig, $self ) {

    # reload in progress
    return if $self->{_load_in_progress};

    # not reloadable and already was loaded
    return if !$self->load_timeout && $self->{_load_next_time};

    # timeout reached
    return if $self->{_load_next_time} && time < $self->{_load_next_time};

    $self->{_load_in_progress} = 1;

    $self->$orig( sub ($uris) {
        my $pool = $self->pool;

        my $has_new_proxies;

        for my $uri ( $uris->@* ) {
            my $proxy = Pcore::API::ProxyPool::Proxy->new( $uri, $self );

            # proxy object wasn't created, generally due to uri parsing errors
            next if !$proxy;

            # proxy already exists
            next if exists $pool->{list}->{ $proxy->hostport };

            $has_new_proxies = 1;

            # add proxy to the list
            $pool->list->{ $proxy->hostport } = $proxy;

            # add proxy to the storage
            $pool->storage->add_proxy($proxy);
        }

        # update next source load timeout
        $self->{_load_next_time} = time + $self->load_timeout;

        $self->{_load_in_progress} = 0;

        # throw pool on status change event if has new proxies added
        # waiting threads can start immediately
        $pool->_on_status_change if $has_new_proxies;

        return;
    } );

    return;
};

# BUILDERS
sub _build_id ($self) {
    state $id = 0;

    return ++$id;
}

sub _build_load_timeout ($self) {
    return $self->pool->load_timeout;
}

sub _build_connect_error_timeout ($self) {
    return $self->pool->connect_error_timeout;
}

sub _build_max_connect_errors ($self) {
    return $self->pool->max_connect_errors;
}

sub _build_max_threads_proxy ($self) {
    return $self->pool->max_threads_proxy;
}

sub _build_max_threads_source ($self) {
    return $self->pool->max_threads_source;
}

# METHODS
sub can_connect ($self) {
    return 0 if $self->max_threads_source && $self->{threads} >= $self->max_threads_source;

    return 1;
}

sub start_thread ($self) {
    $self->{threads}++;

    $self->{total_threads}++;

    # disable source if max. source threads limit exceeded
    $self->pool->storage->update_source_status( $self, 0 ) if !$self->can_connect;

    return;
}

# TODO how to throw source unlock event???
sub finish_thread ($self) {
    my $old_can_connect = $self->can_connect;

    $self->{threads}--;

    my $can_connect = $self->can_connect;

    if ( $can_connect && $can_connect != $old_can_connect ) {

        # enable source, if was disabled previously
        $self->pool->storage->update_source_status( $self, 1 );
    }

    return;
}

1;
__END__
=pod

=encoding utf8

=head1 NAME

Pcore::API::ProxyPool::Source

=head1 SYNOPSIS

=head1 DESCRIPTION

=cut
