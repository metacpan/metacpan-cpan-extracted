package MySQL::Warmer;
use 5.008001;
use strict;
use warnings;

our $VERSION = "0.02";

use DBIx::Inspector;

use Moo;

has dbh => (
    is      => 'ro',
    isa     => sub { shift->isa('DBI::db') },
    lazy    => 1,
    default => sub {
        require DBI;
        DBI->connect(@{ shift->dsn });
    },
);

has dsn => (
    is  => 'ro',
    isa => sub { ref $_[0] eq 'ARRAY' },
);

has dry_run => (
    is      => 'ro',
    default => sub { 0 },
);

has _inspector => (
    is   => 'ro',
    lazy => 1,
    default => sub {
        DBIx::Inspector->new(dbh => shift->dbh)
    },
);

no Moo;

sub run {
    my $self = shift;

    my $inspector = $self->_inspector;
    for my $table ($inspector->tables) {

        my $indexes = $self->statistics_info(table => $table->name, schema => $table->schema);
        my %indexes;

        for my $index_column (@$indexes) {
            $indexes{ $index_column->{index_name} } ||= [];
            push @{ $indexes{ $index_column->{index_name} } }, $index_column->{column_name};
        }

        my @indexes = exists $indexes{PRIMARY} ? delete $indexes{PRIMARY} : ();
        push @indexes, values(%indexes);
        for my $cols (@indexes) {
            my @selectee;
            my @quoted_cols;
            for my $col (@$cols) {
                my $index_column = $table->column($col);

                my $data_type_name = uc $index_column->type_name;
                if ($data_type_name =~ /(?:INT(?:EGER)?|FLOAT|DOUBLE|DECI(?:MAL)?)$/) {
                    push @selectee, sprintf "SUM(`%s`)", $index_column->name;
                }
                elsif ($data_type_name =~ /(?:DATE|TIME)/) {
                    push @selectee, sprintf "SUM(UNIX_TIMESTAMP(`%s`))", $index_column->name;
                }
                else {
                    push @selectee, sprintf "SUM(LENGTH(`%s`))", $index_column->name;
                }
                push @quoted_cols, sprintf "`%s`", $col;
            }

            my $query = sprintf 'SELECT %s FROM (SELECT %s FROM `%s` ORDER BY %s) as t1;',
                join(', ', @selectee), join(', ', @quoted_cols), $table->name, join(', ', @quoted_cols);

            print "$query";
            unless ($self->dry_run) {
                $self->dbh->do($query);
                print " ...done!";
            }
            print "\n";
        }
    }
}

sub statistics_info {
    my ($self, %args) = @_;
    my $table     = $args{table};
    my $schema    = $args{schema};
    my $dbh       = $self->dbh;

    my $sql = <<'...';
SELECT
    index_name,
    column_name
FROM Information_schema.STATISTICS
WHERE
    table_schema = ? AND
    table_name   = ?
ORDER BY table_schema, table_name, seq_in_index;
...

    my $sth = $dbh->prepare($sql);
    $sth->execute($schema, $table);
    $sth->fetchall_arrayref(+{});
}

1;
__END__
=for stopwords InnoDB

=encoding utf-8

=head1 NAME

MySQL::Warmer - execute warming up queries for InnoDB

=head1 SYNOPSIS

    use MySQL::Warmer;
    MySQL::Warmer->new(dbh => $dbh)->run;

=head1 DESCRIPTION

MySQL::Warmer is to execute warming up queries on cold DB server.

I consulted following entry about warming up strategy of this module.

L<http://labs.cybozu.co.jp/blog/kazuho/archives/2007/10/innodb_warmup.php>

=head1 SEE ALSO

L<mysql-warmup>

=head1 LICENSE

Copyright (C) Songmu.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 AUTHOR

Songmu E<lt>y.songmu@gmail.comE<gt>

=cut

