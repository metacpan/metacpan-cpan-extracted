package Pcore::DBH::DDL::pgsql;

use Pcore -class;

with qw[Pcore::DBH::DDL];

sub schema_info_sql ($self) {
    my $table = $self->_schema_info_table;

    my $sql = <<"SQL";
        CREATE TABLE IF NOT EXISTS "$table" (
            "component" VARCHAR PRIMARY KEY NOT NULL,
            "changeset" INTEGER NULL DEFAULT NULL
        );
SQL

    return \$sql;
}

1;
__END__
=pod

=encoding utf8

=head1 NAME

Pcore::DBH::DDL::pgsql

=head1 SYNOPSIS

=head1 DESCRIPTION

=cut
