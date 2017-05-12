package Tapper::Model;
# git description: v5.0.1-1-g08fbd72

our $AUTHORITY = 'cpan:TAPPER';
$Tapper::Model::VERSION = '5.0.2';
# ABSTRACT: Tapper - Context sensitive connected DBIC schema

use strict;
use warnings;

use 5.010;

# avoid these warnings
#   Subroutine initialize redefined at /2home/ss5/perl510/lib/site_perl/5.10.0/Class/C3.pm line 70.
#   Subroutine uninitialize redefined at /2home/ss5/perl510/lib/site_perl/5.10.0/Class/C3.pm line 88.
#   Subroutine reinitialize redefined at /2home/ss5/perl510/lib/site_perl/5.10.0/Class/C3.pm line 101.
# by forcing correct load order.

use English;
use Class::C3;
use MRO::Compat;
use Tapper::Config;
use parent 'Exporter';
use Tapper::Schema::TestrunDB;

my $or_testrundb_schema;
our @EXPORT_OK = qw(model get_hardware_overview);


sub model {
    return $or_testrundb_schema //= Tapper::Schema::TestrunDB->connect(
        @{Tapper::Config->subconfig->{database}{TestrunDB}}{qw/ dsn username password /},{},
    );
}


sub get_or_create_owner {

        my ($login) = @_;

        return model('TestrunDB')
            ->resultset('Owner')
            ->find_or_create({ login => $login },{ login => $login })
            ->id()
        ;

}


sub get_hardware_overview {

        my ($host_id) = @_;

        my $host = model('TestrunDB')
                ->resultset('Host')
                ->search({ 'me.id' => $host_id }, { prefetch => 'features' })
                ->first()
        ;

        if (! $host ) {
                return qq(Host with id '$host_id' not found);
        }

        return { map { $_->entry => $_->value } $host->features };

}


my @a_supported_storage_engines = qw/ mysql SQLite Pg /;

my $fn_execute_raw_sql = sub {

    my ( $or_schema, $hr_params ) = @_;

    if (! $hr_params->{query_name} ) {
        die 'missing query name';
    }

    require Module::Load;
    return $or_schema->storage->dbh_do(
        sub {
            my ( $or_storage, $or_dbh, $hr_params ) = @_;

            my ( $s_query_ns, $s_query_sub ) = ( $hr_params->{query_name} =~ /(.*)::(.*)/ );
            my $s_storage_engine             = ( split /::/, ref $or_storage         )[-1];
            my $s_schema                     = ( split /::/, ref $or_storage->schema )[-1];

            if ( scalar(grep {$_ eq $s_storage_engine} @a_supported_storage_engines) < 1 ) {
                die 'storage engine not supported';
            }

            my $s_module = 'Tapper::RawSQL::' . $s_schema . '::' . $s_query_ns;

            Module::Load::load( $s_module );
            if ( my $fh_query_sub = $s_module->can($s_query_sub) ) {

                my $hr_query_vals = $hr_params->{query_vals};
                my $hr_query      = $fh_query_sub->( $hr_query_vals );

                if ( my $s_sql = $hr_query->{$s_storage_engine} || $hr_query->{default} ) {

                    # replace own placeholer with sql placeholder ("?")
                    my @a_vals;
                    $s_sql =~ s/
                        \$(.+?)\$
                    /
                        ref $hr_query_vals->{$1} eq 'ARRAY'
                            ? ( push( @a_vals, @{$hr_query_vals->{$1}} ) && join ',', map { q#?# } @{$hr_query_vals->{$1}} )
                            : ( push( @a_vals,   $hr_query_vals->{$1}  ) &&                 q#?#                           )
                    /egx;

                    if ( $hr_params->{debug} ) {
                        require Carp;
                        Carp::cluck( $s_sql . '(' . join( q#,#, @a_vals ) . ')' );
                    }

                    if ( $hr_params->{fetch_type} ) {
                        if ( $hr_params->{fetch_type} eq q|$$| ) {
                            return $or_dbh->selectrow_arrayref( $s_sql, { Columns => [ 0 ] }, @a_vals )->[0]
                        }
                        elsif ( $hr_params->{fetch_type} eq q|$@| ) {
                            return $or_dbh->selectrow_arrayref( $s_sql, {}, @a_vals )
                        }
                        elsif ( $hr_params->{fetch_type} eq q|$%| ) {
                            return $or_dbh->selectrow_hashref ( $s_sql, {}, @a_vals )
                        }
                        elsif ( $hr_params->{fetch_type} eq q|@$| ) {
                            return $or_dbh->selectcol_arrayref( $s_sql, {}, @a_vals )
                        }
                        elsif ( $hr_params->{fetch_type} eq q|@@| ) {
                            return $or_dbh->selectall_arrayref( $s_sql, {}, @a_vals )
                        }
                        elsif ( $hr_params->{fetch_type} eq q|@%| ) {
                            return $or_dbh->selectall_arrayref( $s_sql, { Slice => {} }, @a_vals )
                        }
                        else {
                            die 'unknown fetch type'
                        }
                    }

                }
                else {
                    die "raw sql statement isn't supported for storage engine '$s_storage_engine'";
                }
            }
            else {
                die 'named query does not exist';
            }

        },
        $hr_params,
    );

    return;

};

sub fetch_raw_sql {
    my ( $or_schema, $s_name, $s_fetch_type, $ar_vals ) = @_;
    return $fn_execute_raw_sql->( $or_schema, $s_name, $s_fetch_type, $ar_vals )
}

sub execute_raw_sql {
    my ( $or_schema, $s_name, $ar_vals ) = @_;
    return $fn_execute_raw_sql->( $or_schema, $s_name, undef, $ar_vals )
}

1; # End of Tapper::Model

__END__

=pod

=encoding UTF-8

=head1 NAME

Tapper::Model - Tapper - Context sensitive connected DBIC schema

=head1 SYNOPSIS

    use Tapper::Model 'model';
    my $testrun = model('TestrunDB')->schema('Testrun')->find(12);
    my $testrun = model('TestrunDB')->schema('Report')->find(7343);

=head2 model

Returns a connected schema, depending on the environment (live,
development, test).

@param 1. $schema_basename - optional, default is "Tests", meaning the
          Schema "Tapper::Schema::Tests"

@return $schema

=head2 get_or_create_owner

Search a owner based on login name. Create a owner with this login name if
not found.

@param string - login name

@return success - id (primary key of owner table)
@return error   - undef

=head2 get_hardware_overview

Returns an overview of a given machine revision.

@param int - machine lid

@return success - hash ref
@return error   - undef

=head1 AUTHORS

=over 4

=item *

AMD OSRC Tapper Team <tapper@amd64.org>

=item *

Tapper Team <tapper-ops@amazon.com>

=back

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2016 by Advanced Micro Devices, Inc..

This is free software, licensed under:

  The (two-clause) FreeBSD License

=cut
