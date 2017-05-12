package Tapper::Metadata::Query::SQLite;
our $AUTHORITY = 'cpan:TAPPER';
$Tapper::Metadata::Query::SQLite::VERSION = '5.0.1';
use strict;
use warnings;
use base 'Tapper::Metadata::Query::default';

sub insert_addtype {

    my ( $or_self, @a_vals ) = @_;

    my $s_primary = $or_self->{config}{tables}{additional_type_table}{primary};

    $or_self->insert( "
        INSERT OR IGNORE INTO $or_self->{config}{tables}{additional_type_table}{name}
            ( bench_additional_type, created_at )
        VALUES
            ( ?, ? )
    ", [ @a_vals, $or_self->{now} ]);

    my $i_bench_additional_type_id =
           $or_self->last_insert_id(
               $or_self->{config}{tables}{additional_type_table}{name},
               $or_self->{config}{tables}{additional_type_table}{primary},
           )
        || $or_self->select_addtype_by_name( @a_vals )
    ;

    if ( $i_bench_additional_type_id && $or_self->{cache} ) {
        $or_self->{cache}->set(
            "addtype||$a_vals[0]" => $i_bench_additional_type_id,
        );
    }

    return $i_bench_additional_type_id;

}

sub insert_addvalue {

    my ( $or_self, @a_vals ) = @_;

    my $s_primary = $or_self->{config}{tables}{additional_value_table}{primary};

    $or_self->insert( "
        INSERT OR IGNORE INTO $or_self->{config}{tables}{additional_value_table}{name}
            ( bench_additional_type_id, bench_additional_value )
        VALUES
            ( ?, ? )
    ", [ @a_vals ]);

    my $i_addvalue_id =
           $or_self->last_insert_id(
               $or_self->{config}{tables}{additional_value_table}{name},
               $or_self->{config}{tables}{additional_value_table}{primary},
           )
        || $or_self->select_addvalue_id( @a_vals )
    ;

    if ( $i_addvalue_id && $or_self->{cache} ) {
        $or_self->{cache}->set(
            "addvalue||$a_vals[0]||$a_vals[1]" => $i_addvalue_id,
        );
    }

    return $i_addvalue_id;

}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Tapper::Metadata::Query::SQLite

=head1 NAME

Tapper::Metadata::Query::SQLite - Base class for the database work used by Tapper::Metadata when SQLite is used

=head1 AUTHOR

Roberto Schaefer <schaefr@amazon.com>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2016 by Amazon.com, Inc. or its affiliates.

This is free software, licensed under:

  The (two-clause) FreeBSD License

=cut
