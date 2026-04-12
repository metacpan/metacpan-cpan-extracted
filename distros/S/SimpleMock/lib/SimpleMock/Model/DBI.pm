package SimpleMock::Model::DBI;
use strict;
use warnings;
use DBI;
use Storable qw(dclone);
use Data::Dumper;

use SimpleMock::Util qw(
    generate_args_sha
);

our $VERSION = '0.01';

our $drh = DBI->install_driver('SimpleMock');

our @valid_global_meta_keys = (
    # 0|1 allow queries that are not mocked to run with a default empty result set
    'allow_unmocked_queries',

    # 0|1 if true, then $dbh->connect returns undef (use for error checking tests)
    'connect_fail',

    # 0|1 if true, then $dbh->prepare fails with invalid SQL error
    'prepare_fail',

    # 0|1 if true, then $sth->execute returns undef (use for error checking tests)
    'execute_fail',
);

our %valid_global_meta_keys_lookup;
undef @valid_global_meta_keys_lookup{ @valid_global_meta_keys };

# lowercase and remove double spaces - I know some DBs are case sensitive, but
# this can simplify catching typos in tests
sub _normalize_sql {
    my ($sql) = @_;
    $sql = lc($sql);
    $sql =~ s/ +/ /g;
    return $sql;
}

sub validate_mocks {
    my $mocks_data = shift;

    my $new_mocks = {};

    my $meta = $mocks_data->{META} || {};
    # only one option initially, but add more as needed
    META: foreach my $key (keys %$meta) {
        die "unknown meta key: $key" unless exists $valid_global_meta_keys_lookup{$key};
        $new_mocks->{DBI}->{_meta}->{$key} = $meta->{$key};
    }

    my $queries = $mocks_data->{QUERIES} || [];

    QUERY: foreach my $query (@$queries) {
        my $normalized_sql = _normalize_sql($query->{sql});
        my $cols = $query->{cols} || [];
        RESULT: foreach my $result (@{$query->{results} || []}) {
            my $data = $result->{data} || [[]];
            my $sha = generate_args_sha($result->{args});
            my $mock = {
                data => $data,
                cols => $cols,
                args => $result->{args} || [],
            };
            $new_mocks->{DBI}->{$normalized_sql}->{$sha} = dclone($mock);
        }
    }
    return $new_mocks;
}

sub _get_dbi_meta {
    my $key = shift;
    for my $layer (reverse @SimpleMock::MOCK_STACK) {
        return $layer->{DBI}{_meta}{$key}
            if exists $layer->{DBI}{_meta}{$key};
    }
    return undef;
}

sub _get_mock_for {
    my ($sql, $args) = @_;
    my $normalized = _normalize_sql($sql);
    my $sha        = generate_args_sha($args);

    for my $layer (reverse @SimpleMock::MOCK_STACK) {
        my $dbi = $layer->{DBI} or next;
        my $mock = $dbi->{$normalized}{$sha} || $dbi->{$normalized}{'_default'};
        return dclone($mock) if $mock;
    }

    # allow_unmocked_queries can be set in any layer
    for my $layer (reverse @SimpleMock::MOCK_STACK) {
        return dclone({ data => [[]] }) if $layer->{DBI}{_meta}{allow_unmocked_queries};
    }

    die "No mock data found for '$normalized' with args: " . Dumper($args);
}

1;

=head1 NAME

SimpleMock::Model::DBI - A mock model for DBI queries

=head1 DESCRIPTION

This module provides a mock model for DBI queries, allowing you to register
mock queries and their results. It normalizes queries and handles argument-based mocking.

Metadata can be set to control behavior such as allowing unmocked queries, or to force
failure on certain operations like `prepare`, `execute` or `connect`.

=head1 USAGE

You probably won't want to use this module directly, but rather use the SimpleMock
module in your tests instead:

    use SimpleMock qw(register_mocks);

    register_mocks(
        DBI => {
            # all meta values default to false if not explicitly set
            META => {
                # 0|1 allow queries that are not mocked to run with a default empty result set
                'allow_unmocked_queries' => 1,

                # 0|1 if true, then $dbh->connect returns undef (use for error checking tests)
                'connect_fail' => 0,

                # 0|1 if true, then $dbh->prepare fails with invalid SQL error
                'prepare_fail' => 0,
            
                # 0|1 if true, then $sth->execute returns undef (use for error checking tests)
                'execute_fail' => 0,
            },
            # QUERIES is an array of individual sql statements and what to return when executed
            # with specific args
            QUERIES => [
                {
                    sql => 'SELECT name, email FROM users WHERE id = ?',
                    results => [

                        # specific result data for arg sent
                        { args => [1],
                          data => [ ['Alice', 'alice@example.com'] ] },

                        # specific result data for arg sent
                        { args => [2],
                          data => [ ['Bob', 'bob@example.com'] ] },

                        # result data for all other args
                        { data => [ ['Default', 'default@example.com'] ] },

                    ],
                },
            ],
        },
    );

For each query, specify the SQL statement. Then, in the results array, provide the 
placeholder args and data to return for each, and an optional default result that only
has a data element to use as a default for query executions where there is no args match

=cut
