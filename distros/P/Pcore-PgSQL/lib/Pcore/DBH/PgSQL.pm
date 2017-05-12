package Pcore::DBH::PgSQL;

use Pcore -class;
use DBD::Pg qw[:async];
use Symbol;
use if $MSWIN, 'Win32API::File';

with qw[Pcore::DBH::DBI];

has '+_dbh' => ( is => 'ro', isa => InstanceOf ['DBI::db'], required => 1, init_arg => '_dbh' );
has _parent_dbh => ( is => 'ro', isa => InstanceOf ['Pcore::Handle::pg'], required => 1 );

has '+async'  => ( default => 1 );
has _async_fh => ( is      => 'lazy', isa => GlobRef, clearer => 1, init_arg => undef );
has _async_io => ( is      => 'ro', isa => InstanceOf ['EV::IO'], clearer => 1, init_arg => undef );

sub DEMOLISH ( $self, $global ) {
    if ( !$global ) {
        push $self->{_parent_dbh}->push_dbh($self);
    }

    return;
}

sub dbh ($self) {
    return $self;
}

sub _build__async_fh ($self) {
    my $fh;

    if ($MSWIN) {
        $fh = Symbol::gensym;

        Win32API::File::OsFHandleOpen( $fh, $self->{_dbh}->{pg_socket}, 'r' ) or die $!;
    }
    else {
        open $fh, '<&=', $self->{_dbh}->{pg_socket} or die $!;    ## no critic qw[InputOutput::RequireBriefOpen]
    }

    return $fh;
}

sub execute_async ( $self, $query, $bind, $args, $cb ) {
    my $sth;

    # prepare sth
    if ( $args->{cache} ) {
        if ( ref $query eq 'DBI::st' ) {
            $sth = $self->{_dbh}->prepare_cached( $query->{Statement}, { pg_async => PG_ASYNC } );
        }
        else {
            $sth = $self->{_dbh}->prepare_cached( "$query", { pg_async => PG_ASYNC } );
        }
    }
    else {
        if ( ref $query eq 'DBI::st' ) {

            # NOTE currently it is impossible to detect is $sth was prepared with pg_async or not, so we prepare statement on each call
            # if the future we can use something like $sth->async_flag, when it will be available
            # https://rt.cpan.org/Ticket/Display.html?id=116172
            $sth = $self->{_dbh}->prepare( $query->{Statement}, { pg_async => PG_ASYNC } );
        }
        else {
            $sth = $self->{_dbh}->prepare( "$query", { pg_async => PG_ASYNC } );
        }
    }

    # execute query
    $sth->execute( $bind ? $bind->@* : () ) or die $sth->errstr;

    # start async socket I/O listener
    $self->{_async_io} = AE::io $self->_async_fh, 0, sub {
        undef $self->{_async_io};

        # say $dbh1->pg_ready ? 1 : 0;

        $cb->( $args, $self->{_dbh}->pg_result, $sth );

        return;
    };

    return;
}

1;
__END__
=pod

=encoding utf8

=head1 NAME

Pcore::DBH::PgSQL

=head1 SYNOPSIS

=head1 DESCRIPTION

=head1 ATTRIBUTES

=head1 METHODS

=head1 SEE ALSO

=cut
