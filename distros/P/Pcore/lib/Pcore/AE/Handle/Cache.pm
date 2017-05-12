package Pcore::AE::Handle::Cache;

use Pcore -class;
use Pcore::AE::Handle::Cache::Storage;
use Pcore::Util::Scalar qw[refaddr];

has default_keepalive_timeout => ( is => 'ro', isa => PositiveInt, default => 4 );

has handle     => ( is => 'ro', isa => HashRef, default => sub { {} }, init_arg => undef );
has connection => ( is => 'ro', isa => HashRef, default => sub { {} }, init_arg => undef );

sub clear ($self) {
    $self->{handle}->%* = ();

    $self->{connection}->%* = ();

    return;
}

sub store ( $self, $h, $keepalive_timeout = undef ) {

    # do not cache destroyed handles
    return if $h->destroyed;

    return if !$h->{persistent_id};

    my $id = refaddr $h;

    # return if handle already cached
    return if exists $self->{handle}->{$id};

    # cache handle
    $self->{handle}->{$id} = $h;

    # cache handle connections
    for my $key ( $h->{persistent_id}->@* ) {
        $self->{connection}->{$key} //= Pcore::AE::Handle::Cache::Storage->new;

        $self->{connection}->{$key}->push($id);
    }

    my $destroy = sub ( $h, @ ) {
        delete $self->{handle}->{$id};

        for my $key ( $h->{persistent_id}->@* ) {
            if ( exists $self->{connection}->{$key} ) {
                $self->{connection}->{$key}->delete($id);

                delete $self->{connection}->{$key} if !$self->{connection}->{$key}->has_items;
            }
        }

        # destroy handle
        $h->destroy;

        return;
    };

    # prepare handle for caching
    $h->on_error($destroy);
    $h->on_eof($destroy);
    $h->on_read($destroy);
    $h->on_timeout(undef);

    $h->timeout_reset;
    $h->timeout( $keepalive_timeout || $self->default_keepalive_timeout );

    return;
}

# TODO detect, if $h is not closed
sub fetch ( $self, $key ) {
    return if !exists $self->{connection}->{$key};

    my $id = $self->{connection}->{$key}->shift;

    return if !$id;

    my $h = delete $self->{handle}->{$id};

    for ( $h->{persistent_id}->@* ) {
        if ( exists $self->{connection}->{$_} ) {
            $self->{connection}->{$_}->delete($id);

            delete $self->{connection}->{$_} if !$self->{connection}->{$_}->has_items;
        }
    }

    # return if $h->destroyed;

    $h->on_error(undef);
    $h->on_eof(undef);
    $h->on_read(undef);
    $h->timeout_reset;
    $h->timeout(0);

    return $h;
}

1;
__END__
=pod

=encoding utf8

=head1 NAME

Pcore::AE::Handle::Cache

=head1 SYNOPSIS

=head1 DESCRIPTION

=head1 ATTRIBUTES

=head1 METHODS

=head1 SEE ALSO

=cut
