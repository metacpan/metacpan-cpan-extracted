package Pcore::Handle::pgsql;

use Pcore -class;
use DBD::Pg qw[:async];
use Pcore::DBH::PgSQL;

with qw[Pcore::DBH];

has '+async' => ( default => 1 );

sub BUILD ( $self, $args ) {
    my $attr = P->hash->merge(
        $self->default_dbi_attr,
        {   pg_server_prepare => 1,
            pg_enable_utf8    => 1,
        }
    );

    my $params = {
        host => $self->uri->path eq q[/] ? $self->uri->host : $self->uri->path,
        port => $self->uri->port || 5432,
        database => $self->uri->query_params->{db},
        options  => '--client-min-messages=warning',
    };

    die q[Host is required] if !$params->{host};

    die q[Database is required] if !$params->{database};

    $self->{_dbh} = DBI->connect( 'DBI:Pg:' . join( q[;], map {qq[$_=$params->{$_}]} sort keys $params->%* ), $self->uri->username, $self->uri->password, $attr );

    $self->_on_connect($self);

    $self->{_dbh}->disconnect;

    return;
}

sub _on_connect ( $self, $dbh ) {
    $self->on_connect->($dbh) if $self->on_connect;

    return;
}

1;
__END__
=pod

=encoding utf8

=head1 NAME

Pcore::Handle::pgsql

=head1 SYNOPSIS

=head1 DESCRIPTION

=head1 ATTRIBUTES

=head1 METHODS

=head1 SEE ALSO

=cut
