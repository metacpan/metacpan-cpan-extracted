package Pcore::DBH::DDL;

use Pcore -role;
use Pcore::DBH::DDL::ChangeSet;

requires qw[schema_info_sql];

has dbh => ( is => 'ro', isa => ConsumerOf ['Pcore::DBH'], required => 1 );

has _schema_info_table => ( is => 'lazy', isa => Str, default => '_schema_info', init_arg => undef );
has _changesets => ( is => 'lazy', isa => HashRef, default => sub { {} }, init_arg => undef );

# TODO
# revert all changes if one changeset failed
# upgrade db to specified version, including downgrade - need to specify revert sql code

sub add_changeset ( $self, %args ) {
    my $cset = Pcore::DBH::DDL::ChangeSet->new( \%args );

    my $id = $cset->component . $cset->id;

    die qq[DDL changeset id "@{[$cset->id]}" for component "@{[$cset->component]}" already exists] if exists $self->_changesets->{$id};

    $self->_changesets->{$id} = $cset;

    return $cset;
}

sub upgrade ($self) {
    $self->_create_schema_info;

    my $dbh = $self->dbh;

    my $info = $dbh->selectall_hashref( [ 'SELECT * FROM', [ $self->_schema_info_table ] ], key_cols => 'component' ) // {};

    for my $cset ( sort { $a->id <=> $b->id } values $self->_changesets->%* ) {

        # create component record
        $dbh->do( [ 'INSERT INTO', [ $self->_schema_info_table ], VALUES => { component => $cset->component } ] ) if !exists $info->{ $cset->component };

        if ( !exists $info->{ $cset->component } || !defined $info->{ $cset->component }->{changeset} || $info->{ $cset->component }->{changeset} < $cset->id ) {
            $dbh->begin_work if $cset->transaction;

            eval {
                if ( ref $cset->sql eq 'CODE' ) {
                    die qq[Changeset "@{[$cset->id]}" for component "@{[$cset->component]}" did not return true value] if !$cset->sql->( $cset, $dbh );
                }
                else {
                    $dbh->do( $self->_get_changeset_query($cset), cache => 0 );
                }

                $dbh->commit if $cset->transaction;
            };

            if ($@) {
                $@->sendlog;

                $dbh->rollback if $cset->transaction;

                die qq[Failed to apply changeset "@{[$cset->id]}" for component "@{[$cset->component]}"];
            }

            # update schema info
            $dbh->do( [ UPDATE => [ $self->_schema_info_table ], SET => { changeset => $cset->id }, 'WHERE component =', \$cset->component ] );

            $info->{ $cset->component }->{changeset} = $cset->id;
        }
    }

    return;
}

sub _create_schema_info ($self) {
    return $self->dbh->do( $self->schema_info_sql->$*, cache => 0 );
}

sub _get_changeset_query ( $self, $cset ) {
    return $self->dbh->query( $self->_get_cset_sql($cset) );
}

sub _get_cset_sql ( $self, $cset ) {
    return $cset->sql;
}

1;
## -----SOURCE FILTER LOG BEGIN-----
##
## PerlCritic profile "pcore-script" policy violations:
## +------+----------------------+----------------------------------------------------------------------------------------------------------------+
## | Sev. | Lines                | Policy                                                                                                         |
## |======+======================+================================================================================================================|
## |    3 | 44                   | ErrorHandling::RequireCheckingReturnValueOfEval - Return value of eval not tested                              |
## +------+----------------------+----------------------------------------------------------------------------------------------------------------+
##
## -----SOURCE FILTER LOG END-----
__END__
=pod

=encoding utf8

=head1 NAME

Pcore::DBH::DDL - database schema versioning subsystem

=head1 SYNOPSIS

    my $ddl = $dbh->ddl;

    $ddl->add_changeset(
        id        => 1,
        component => undef,
        sql       => q[CREATE TABLE ...],
    );

    ...

    $ddl->upgrade;

=head1 DESCRIPTION

=cut
