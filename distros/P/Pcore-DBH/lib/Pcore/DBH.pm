package Pcore::DBH v0.3.0;

use Pcore -dist, -role;
use DBI;
use Pcore::Util::Text qw[escape_scalar];

with qw[Pcore::Handle Pcore::DBH::DBI];

has on_connect => ( is => 'ro', isa => Maybe [CodeRef] );

has _query_class => ( is => 'lazy', isa => Str, init_arg => undef );
has _ddl_class   => ( is => 'lazy', isa => Str, init_arg => undef );

has max_conn  => ( is => 'ro', isa => PositiveInt,       default => 20 );                              # max. allowed numer of connections
has _dbh_conn => ( is => 'ro', isa => PositiveOrZeroInt, default => 0, init_arg => undef );
has _dbh_pool => ( is => 'ro', isa => ArrayRef,          default => sub { [] }, init_arg => undef );
has _dbh_req  => ( is => 'ro', isa => ArrayRef,          default => sub { [] }, init_arg => undef );

# get DBH async
sub dbh ( $self, $cb ) {
    if ( my $dbh = shift $self->{_dbh_pool}->@* ) {
        $cb->($dbh);
    }
    else {
        push $self->{_dbh_req}->@*, $cb;

        # create new dbh
        if ( $self->{_dbh_conn} < $self->{max_conn} ) {
            my $dbh = Pcore::DBH::SQLite->new(
                {   _dbh        => $self->{_dbh}->clone,
                    _parent_dbh => $self,
                }
            );

            $self->_on_connect($dbh);

            $self->{_dbh_conn}++;

            $self->push_dbh($dbh);
        }
    }

    return;
}

sub push_dbh ( $self, $dbh ) {
    if ( my $cb = shift $self->{_dbh_req}->@* ) {
        $cb->($dbh);
    }
    else {
        push $self->{_dbh_pool}->@*, $dbh;
    }

    return;
}

# TODO remove connection from pool when dbh is disconnected
sub destroy_dbh ( $self, $dbh ) {
    $self->{_dbh_conn}--;

    return;
}

sub default_dbi_attr($self) {
    state $attr = {
        Warn        => 1,
        PrintWarn   => 1,
        PrintError  => 0,
        RaiseError  => 1,
        HandleError => sub {
            my $msg = shift;

            escape_scalar $msg;

            die $msg;
        },
        ShowErrorStatement => 1,
        AutoCommit         => 1,
        Callbacks          => {
            connected => sub {
                P->log->sendlog( 'Pcore-DBH', 'Connected to: ' . $_[1] );

                return;
            },
            prepare => sub {
                return;
            },
            do => sub {
                P->log->sendlog( 'Pcore-DBH', 'Do: ' . $_[1] );

                return;
            },
            ChildCallbacks => {
                execute => sub {
                    P->log->sendlog( 'Pcore-DBH', 'Execute: ' . $_[0]->{Statement} );

                    return;
                }
            }
        }
    };

    return $attr;
}

sub _build__query_class ($self) {
    return P->class->load( $self->uri->scheme, ns => 'Pcore::DBH::Query' );
}

sub _build__ddl_class ($self) {
    return P->class->load( $self->uri->scheme, ns => 'Pcore::DBH::DDL' );
}

# SQL QUERY BUILDER
sub query ( $self, @args ) {
    my $class = $self->_query_class;

    my $query = $class->new( { dbh => $self } );

    $query->_build_query(@args);

    return $query;
}

# DDL
sub ddl ( $self) {
    my $class = $self->_ddl_class;

    return $class->new( { dbh => $self } );
}

1;
__END__
=pod

=encoding utf8

=head1 NAME

Pcore::DBH

=head1 SYNOPSIS

=head1 DESCRIPTION

=head1 ATTRIBUTES

=head1 METHODS

=head1 SEE ALSO

=cut
