package Pcore::AE::Handle::Cache;

use Pcore -class;
use Pcore::Util::Scalar qw[refaddr];

has handle     => ();    # ( is => 'ro', isa => HashRef, default => sub { {} }, init_arg => undef );
has connection => ();    # ( is => 'ro', isa => HashRef, default => sub { {} }, init_arg => undef );

sub clear ($self) {
    $self->{handle}->%* = ();

    $self->{connection}->%* = ();

    return;
}

sub store ( $self, $h, $timeout ) {

    # do not cache destroyed handles
    return if $h->destroyed;

    return unless my $persistent = $h->{persistent};

    my $id = refaddr $h;

    # return if handle already cached
    return if exists $self->{handle}->{$id};

    # cache handle
    $self->{handle}->{$id} = $h;

    # cache handle connections
    push $self->{connection}->{$persistent}->@*, $id;

    my $destroy = sub ( $h, @ ) {
        delete $self->{handle}->{$id};

        for ( my $i = $self->{connection}->{$persistent}->$#*; $i >= 0; $i-- ) {
            if ( $self->{connection}->{$persistent}->[$i] == $id ) {
                splice $self->{connection}->{$persistent}->@*, $i, 1;

                last;
            }
        }

        delete $self->{connection}->{$persistent} if !$self->{connection}->{$persistent}->@*;

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
    $h->timeout($timeout);

    return;
}

sub fetch ( $self, $key ) {
    return if !exists $self->{connection}->{$key};

    while (1) {
        my $id = shift $self->{connection}->{$key}->@*;

        if ( !$id ) {
            delete $self->{connection}->{$key};

            return;
        }

        my $h = delete $self->{handle}->{$id};

        next if $h->destroyed;

        $h->on_error(undef);
        $h->on_eof(undef);
        $h->on_read(undef);
        $h->timeout_reset;
        $h->timeout(0);

        return $h;
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
## |    2 | 38                   | ControlStructures::ProhibitCStyleForLoops - C-style "for" loop used                                            |
## +------+----------------------+----------------------------------------------------------------------------------------------------------------+
##
## -----SOURCE FILTER LOG END-----
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
