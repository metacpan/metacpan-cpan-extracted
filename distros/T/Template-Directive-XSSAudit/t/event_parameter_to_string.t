use Test::More;

use Template::Directive::XSSAudit;

my @tests = (
    sub {
        my $t = "on_error string format - no filters";

        my $context = {
            'variable_name' => 'my_variable',
            'filtered_by'   => [],
            'file_name' => '/template.tt',
            'file_line' => 1
        };

        my $out = Template::Directive::XSSAudit->event_parameter_to_string(
            $context,
            'on_error'
        );

        ok( $out eq "/template.tt\tNO_FILTERS\tline:1\tmy_variable", $t );

    },
    sub {
        my $t = "on_error string format - no file_line";

        my $context = {
            'variable_name' => 'my_variable',
            'filtered_by'   => [],
            'file_name' => '/template.tt',
            'file_line' => ''
        };

        my $out = Template::Directive::XSSAudit->event_parameter_to_string(
            $context,
            'on_error'
        );

        ok( $out eq "/template.tt\tNO_FILTERS\tline:0\tmy_variable", $t );

    },
    sub {
        my $t = "on_error string format - no file_name";

        my $context = {
            'variable_name' => 'my_variable',
            'filtered_by'   => [],
            'file_name' => '',
            'file_line' => '1'
        };

        my $out = Template::Directive::XSSAudit->event_parameter_to_string(
            $context,
            'on_error'
        );

        ok( $out eq "<unknown_file>\tNO_FILTERS\tline:1\tmy_variable", $t );

    },
    sub {
        my $t = "on_error string format - 1 filter";

        my $context = {
            'variable_name' => 'my_variable',
            'filtered_by'   => [ 'date' ],
            'file_name' => '/template.tt',
            'file_line' => 1
        };

        my $out = Template::Directive::XSSAudit->event_parameter_to_string(
            $context,
            'on_error'
        );

        ok( $out eq "/template.tt\tNO_SAFE_FILTER\tline:1\tmy_variable\tdate", $t );

    },
    sub {
        my $t = "on_error string format - 2 filter";

        my $context = {
            'variable_name' => 'my_variable',
            'filtered_by'   => [ 'date', 'date2' ],
            'file_name' => '/template.tt',
            'file_line' => 1
        };

        my $out = Template::Directive::XSSAudit->event_parameter_to_string(
            $context,
            'on_error'
        );

        ok( $out eq "/template.tt\tNO_SAFE_FILTER\tline:1\tmy_variable\tdate,date2", $t );

    },
    sub {
        my $t = "on_filtered string format - 1 filter";

        my $context = {
            'variable_name' => 'my_variable',
            'filtered_by'   => [ 'html' ],
            'file_name' => '/template.tt',
            'file_line' => 1
        };

        my $out = Template::Directive::XSSAudit->event_parameter_to_string(
            $context,
            'on_filtered'
        );

        ok( $out eq "/template.tt\tOK\tline:1\tmy_variable\thtml", $t );

    },
    sub {
        my $t = "on_filtered string format - 2 filter";

        my $context = {
            'variable_name' => 'my_variable',
            'filtered_by'   => [ 'uri','html' ],
            'file_name' => '/template.tt',
            'file_line' => 1
        };

        my $out = Template::Directive::XSSAudit->event_parameter_to_string(
            $context,
            'on_filtered'
        );

        ok( $out eq "/template.tt\tOK\tline:1\tmy_variable\turi,html", $t );

    },
);

plan tests => scalar @tests;

$_->() for @tests;
