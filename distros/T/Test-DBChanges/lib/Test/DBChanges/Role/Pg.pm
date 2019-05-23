package Test::DBChanges::Role::Pg;
use Moo::Role;
use 5.024;
use namespace::autoclean;

with 'Test::DBChanges::Role::Base',
    'Test::DBChanges::Role::Triggers',
    'Test::DBChanges::Role::JSON';

our $VERSION = '1.0.0'; # VERSION
# ABSTRACT: installs triggers for PostgreSQL


sub maybe_prepare_db {
    my ($self) = @_;

    my $prefix = $self->db_item_prefix;
    my $tablename = $self->_table_name;
    $self->_db_do(<<"SQL");
CREATE TABLE IF NOT EXISTS ${tablename} (
 id SERIAL PRIMARY KEY,
 table_name VARCHAR NOT NULL,
 operation VARCHAR NOT NULL,
 data JSONB NOT NULL,
 done_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT now()
)
SQL

    my $procname = "${prefix}_proc";
    my $already_there = $self->_db_fetch(<<'SQL',$procname);
SELECT 1 AS ok
FROM information_schema.routines
WHERE routine_name = ?;
SQL

    unless ($already_there->[0]{ok}) {
        $self->_db_do(<<"SQL");
CREATE FUNCTION ${procname}() RETURNS TRIGGER AS \$\$
BEGIN
  IF (TG_OP = 'DELETE') THEN
    INSERT INTO ${tablename} (table_name,operation,data)
    VALUES (TG_TABLE_NAME,TG_OP,row_to_json(OLD));
  ELSE
    INSERT INTO ${tablename} (table_name,operation,data)
    VALUES (TG_TABLE_NAME,TG_OP,row_to_json(NEW));
  END IF;
  RETURN NULL;
END;
\$\$ LANGUAGE plpgsql
SQL
    }

    # notice that, since we install all triggers we need that are not
    # already there, multiple instances of DBChanges should co-exist
    # peacefully in the same schema
    for my $table (sort keys $self->_table_source_map->%*) {
        my $trigger_name = "${prefix}_${table}_trig";
        my $already_there = $self->_db_fetch(<<'SQL',$trigger_name, $table);
SELECT 1 AS ok
FROM information_schema.triggers
WHERE trigger_name = ? AND event_object_table = ?
SQL
        next if $already_there->[0]{ok};

        $self->_db_do(<<"SQL");
CREATE TRIGGER ${trigger_name}
AFTER INSERT OR UPDATE OR DELETE ON ${table}
FOR EACH ROW EXECUTE PROCEDURE ${procname}();
SQL
    }
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Test::DBChanges::Role::Pg - installs triggers for PostgreSQL

=head1 VERSION

version 1.0.0

=head1 DESCRIPTION

This role implements change tracking for PostgreSQL by installing a
set of triggers that record changes as JSONB into a dedicated table.

=for Pod::Coverage maybe_prepare_db

=head1 AUTHOR

Gianni Ceccarelli <gianni.ceccarelli@broadbean.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2019 by BroadBean UK, a CareerBuilder Company.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
