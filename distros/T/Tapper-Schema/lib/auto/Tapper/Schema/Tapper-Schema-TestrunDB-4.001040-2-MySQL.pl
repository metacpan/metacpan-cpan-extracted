#!/usr/bin/env perl

use strict;
use warnings;

require JSON::XS;
require Tapper::Model;

my $or_dbh         = Tapper::Model::model()->storage->dbh;
my $ar_chart_lines = $or_dbh->selectall_arrayref(
    '
        SELECT
            chart_line_id,
            chart_line_statement
        FROM
            testrundb.chart_lines
    ',
    { Slice => {} },
);
my $or_prep_insert_restriction = $or_dbh->prepare('
    INSERT INTO testrundb.chart_line_restrictions
        (
            chart_line_id,
            chart_line_restriction_operator,
            chart_line_restriction_column,
            is_template_restriction,
            created_at
        )
    VALUES
        ( ?, ?, ?, ?, NOW() )
');
my $or_prep_insert_restriction_value = $or_dbh->prepare('
    INSERT INTO testrundb.chart_line_restriction_values
        (
            chart_line_restriction_id,
            chart_line_restriction_value
        )
    VALUES
        ( ?, ? )
');

for my $hr_chart_line ( @{$ar_chart_lines} ) {

    my $hr_json;
    eval {
        $hr_json = JSON::XS::decode_json( $hr_chart_line->{chart_line_statement} );
    };
    if ( $@ ) {
        warn "cannot parse json string: $@";
    }
    else {
        if ( $hr_json->{where} ) {
            for my $ar_where_clause ( @{$hr_json->{where}} ) {

                my $s_operator = shift @{$ar_where_clause};
                my $s_column   = shift @{$ar_where_clause};

                eval {

                    $or_prep_insert_restriction->execute(
                        $hr_chart_line->{chart_line_id}, $s_operator, $s_column, 0,
                    );

                    my $i_chart_line_restriction_id = $or_dbh->{mysql_insertid};

                    for my $s_value ( @{$ar_where_clause} ) {
                        $or_prep_insert_restriction_value->execute(
                            $i_chart_line_restriction_id, $s_value,
                        );
                    }

                };
                if ( $@ ) {
                    warn "cannot add chart line restriction: $@";
                }

            }
        }
    }

}

1;