use testrundb;

UPDATE testrundb.chart_line_axis_columns
SET chart_line_axis_column = 'CREATED'
WHERE chart_line_axis_column = 'bench_date'
;
UPDATE `testrundb`.`chart_line_additionals`
SET chart_line_additional_column = 'CREATED'
WHERE chart_line_additional_column = 'bench_date'
;

UPDATE testrundb.chart_line_axis_columns
SET chart_line_axis_column = 'VALUE'
WHERE chart_line_axis_column = 'bench_value'
;
UPDATE `testrundb`.`chart_line_additionals`
SET chart_line_additional_column = 'VALUE'
WHERE chart_line_additional_column = 'bench_value'
;

UPDATE testrundb.chart_line_axis_columns
SET chart_line_axis_column = 'NAME'
WHERE chart_line_axis_column = 'bench'
;
UPDATE `testrundb`.`chart_line_additionals`
SET chart_line_additional_column = 'NAME'
WHERE chart_line_additional_column = 'bench'
;

UPDATE testrundb.chart_line_axis_columns
SET chart_line_axis_column = 'UNIT'
WHERE chart_line_axis_column = 'bench_unit'
;
UPDATE `testrundb`.`chart_line_additionals`
SET chart_line_additional_column = 'UNIT'
WHERE chart_line_additional_column = 'bench_unit'
;

UPDATE testrundb.chart_line_axis_columns
SET chart_line_axis_column = 'VALUE_ID'
WHERE chart_line_axis_column = 'bench_value_id'
;
UPDATE `testrundb`.`chart_line_additionals`
SET chart_line_additional_column = 'VALUE_ID'
WHERE chart_line_additional_column = 'bench_value_id'
;

UPDATE
    chart_lines
SET
    chart_line_statement = REPLACE(
        REPLACE(
            REPLACE(
                REPLACE(
                    REPLACE(
                            chart_line_statement,
                        '"bench"',
                        '"NAME"'
                    ),
                    '"bench_value"',
                    '"VALUE"'
                ),
                '"bench_unit"',
                '"UNIT"'
            ),
            '"bench_value_id"',
            '"VALUE_ID"'
        ),
        '"bench_date"',
        '"CREATED"'
    )
;