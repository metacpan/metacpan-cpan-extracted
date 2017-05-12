package Tapper::Metadata::Query;
our $AUTHORITY = 'cpan:TAPPER';
$Tapper::Metadata::Query::VERSION = '5.0.1';
use strict;
use warnings;

use DateTime;
use Digest::MD5;

sub new {

    my ( $s_self, $hr_atts ) = @_;

    for my $s_key (qw/ config dbh /) {
        if (! $hr_atts->{$s_key} ) {
            require Carp;
            Carp::confess("missing parameter '$s_key'");
        }
    }

    return bless {
        now     => $hr_atts->{now},
        dbh     => $hr_atts->{dbh},
        cache   => $hr_atts->{cache},
        debug   => $hr_atts->{debug} || 0,
        config  => $hr_atts->{config},
    }, $s_self;

}

sub execute_query {

    my ( $or_self, $s_statement, $ar_vals ) = @_;

    $ar_vals ||= [];

    if ( $or_self->{debug} ) {
        warn $s_statement . ' (' . (join ',', @{$ar_vals}) . ')';
    }

    local $or_self->{dbh}{RaiseError} = 1;

    my $or_prepared = $or_self->{dbh}->prepare_cached( $s_statement );
    my $b_result    = $or_prepared->execute( @{$ar_vals} );

    return ( $or_prepared, $b_result );

}

sub insert {

    my ( $or_self, $s_statement, $ar_vals ) = @_;

    my ( $or_prepared, $b_result ) = $or_self->execute_query( $s_statement, $ar_vals );
                                    $or_prepared->finish();

    return $b_result;

}

sub selectrow_hashref {

    my ( $or_self, $s_statement, $ar_vals ) = @_;

    my ( $or_prepared, undef ) = $or_self->execute_query( $s_statement, $ar_vals );
    my $hr_return              = $or_prepared->fetchrow_hashref;
                                 $or_prepared->finish();

    return $hr_return;

}

sub selectrow_arrayref {

    my ( $or_self, $s_statement, $ar_vals ) = @_;

    my ( $or_prepared, undef ) = $or_self->execute_query( $s_statement, $ar_vals );
    my $hr_return              = $or_prepared->fetchrow_arrayref;
                                 $or_prepared->finish();

    return $hr_return;

}

sub selectall_arrayref {

    my ( $or_self, $s_statement, $ar_vals ) = @_;

    my ( $or_prepared, undef ) = $or_self->execute_query( $s_statement, $ar_vals );
    my $hr_return              = $or_prepared->fetchall_arrayref;
                                 $or_prepared->finish();

    return $hr_return;

}

sub selectall_hashref {

    my ( $or_self, $s_statement, $ar_vals ) = @_;

    my ( $or_prepared, undef ) = $or_self->execute_query( $s_statement, $ar_vals );
    my $hr_return              = $or_prepared->fetchall_arrayref({});
                                 $or_prepared->finish();

    return $hr_return;

}

sub last_insert_id {

    my ( $or_self, $s_table, $s_column ) = @_;

    return $or_self->{dbh}->last_insert_id(
        undef, undef, $s_table, $s_column,
    );

}

sub start_transaction {

    my ( $or_self ) = @_;

    if ( defined( $or_self->{transaction_supported} ) && !$or_self->{transaction_supported} ) {
        return 0;
    }
    if ( $or_self->{dbh}{BegunWork} || $or_self->{dbh}{AutoCommit} == 0 ) {
        return 0;
    }

    @{$or_self->{backup_attributes}}{qw/RaiseError PrintError AutoCommit/} =
        @{$or_self->{dbh}}{qw/RaiseError PrintError AutoCommit/}
    ;

    eval {
        $or_self->{dbh}{AutoCommit} = 0;
        $or_self->{dbh}{RaiseError} = 1;
        $or_self->{dbh}{PrintError} = 0;
    };
    if ( $@ ) {
        if ( $or_self->{debug} ) {
            require Carp;
            Carp::cluck('Transactions not supported by your database');
        }
        $or_self->{transaction_supported} = 0;
        return 0;
    }
    else {
        $or_self->{transaction_supported} = 1;
        return 1;
    }

}

sub finish_transaction {

    my ( $or_self, $b_started, $s_error ) = @_;

    if ( $or_self->{transaction_supported} ) {
        if ( $b_started ) {
            if ( $s_error ) {
                $or_self->{dbh}->rollback();
                @{$or_self->{dbh}}{qw/RaiseError PrintError AutoCommit/} =
                    @{$or_self->{backup_attributes}}{qw/RaiseError PrintError AutoCommit/}
                ;
                require Carp;
                Carp::confess("transaction failed: $s_error");
                return 0;
            }
            else {
                $or_self->{dbh}->commit();
                @{$or_self->{dbh}}{qw/RaiseError PrintError AutoCommit/} =
                    @{$or_self->{backup_attributes}}{qw/RaiseError PrintError AutoCommit/}
                ;
            }
        }
        else {
            if ( $s_error ) {
                require Carp;
                Carp::confess("transaction failed: $s_error");
                return 0;
            }
        }
    }

    return 1;

}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Tapper::Metadata::Query

=head1 NAME

Tapper::Metadata::Query - Base class for the database work used by Tapper::Metadata

=head1 AUTHOR

Roberto Schaefer <schaefr@amazon.com>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2016 by Amazon.com, Inc. or its affiliates.

This is free software, licensed under:

  The (two-clause) FreeBSD License

=cut
