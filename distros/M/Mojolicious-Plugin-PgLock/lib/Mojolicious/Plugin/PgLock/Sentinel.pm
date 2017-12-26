package Mojolicious::Plugin::PgLock::Sentinel;

use Mojo::Base '-base';

use Digest::Crc32;

has app    => undef;
has db     => undef;
has name   => undef;
has id     => sub { my $self = shift; Digest::Crc32->new->strcrc32( $self->name // '' ) };
has shared => undef;
has wait   => undef;

sub DESTROY {
    my ($self) = @_;
    $self->unlock while $self->{unlock_stack} and @{ $self->{unlock_stack} };
}

sub lock {
    my ($self) = @_;
    my $try    = $self->wait ? '1, pg_' : 'pg_try_';
    my $shared = $self->shared ? '_shared' : '';

    my $lock_sql = "select ${try}advisory_lock${shared}(?)";
    $self->app->log->debug( sprintf "Obtaining lock for id: %s, name: %s, q: %s", $self->id, $self->name, $lock_sql );

    if ( $self->db->query( $lock_sql, $self->id )->array->[0] ) {
        push @{ $self->{unlock_stack} }, [ "select pg_advisory_unlock${shared}(?)", $self->id ];
        $self->app->log->debug( sprintf "Got lock for id: %s", $self->id );
        return $self;
    }
    $self->app->log->debug( sprintf "Can't get lock for id: %s", $self->id );
    return;
}

sub unlock {
    my ($self) = @_;
    if ( @{ $self->{unlock_stack} } ) {
        $self->app->log->debug( sprintf "'%s', %s", @{ $self->{unlock_stack}[-1] } );
        $self->db->query( @{ pop @{ $self->{unlock_stack} } } )
    }
}

1;
__END__

=encoding utf-8

=head1 NAME

Mojolicious::Plugin::PgLock::Sentinel - postgres advisory lock holder object

