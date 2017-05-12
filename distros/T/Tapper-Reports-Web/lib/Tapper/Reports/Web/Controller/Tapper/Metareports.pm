package Tapper::Reports::Web::Controller::Tapper::Metareports;
our $AUTHORITY = 'cpan:TAPPER';
$Tapper::Reports::Web::Controller::Tapper::Metareports::VERSION = '5.0.13';
# ABSTRACT: Tapper - Catalyst Controller Metareports

use strict;
use warnings;
use parent 'Tapper::Reports::Web::Controller::Base';

use Try::Tiny;
use List::MoreUtils qw( any );

use 5.010;

sub index :Path :Args() {

    my ( $self, $c, @args ) = @_;

    $c->go('/tapper/metareports/chart_overview');

}

sub auto : Private {

   my ( $self, $or_c ) = @_;

    # set js, csss file
    push @{$or_c->stash->{js_files}}, '/tapper/static/js/metareports.js';
    push @{$or_c->stash->{css_files}}, '/tapper/static/css/metareports/default.css';

    $or_c->forward('/tapper/metareports/prepare_navi');
}

sub hr_get_search : Private {

    my ( $or_schema, $hr_params ) = @_;

    my ( $hr_search, $ar_join ) = ({},[]);
    if ( $hr_params->{chart_tiny_url} ) {
        $hr_search->{chart_tiny_url_id} = $hr_params->{chart_tiny_url};
        push @{$ar_join}, { 'chart_lines' => 'chart_tiny_url_lines' };
    }
    elsif ( $hr_params->{chart_id} ) {
        if (! $hr_params->{chart_version} ) {
            $hr_params->{chart_version} = $or_schema->resultset('ChartVersions')
                ->search({
                    chart_id => $hr_params->{chart_id}
                })
                ->get_column('chart_version')
                ->max();
        }
        $hr_search->{'me.chart_id'}      = $hr_params->{chart_id}     ;
        $hr_search->{'me.chart_version'} = $hr_params->{chart_version};
    }
    else {
        return;
    }

    return ( $hr_search, $ar_join );

}

sub detail : Local {

    my ( $or_self, $or_c ) = @_;

    $or_c->stash->{head_overview} = 'Metareports - Detail';

    # set css file
    push @{$or_c->stash->{css_files}},
          '/tapper/static/css/metareports/detail.css',
        , '/tapper/static/css/jquery-ui/jquery.ui.css'
        , '/tapper/static/css/jquery-ui/jquery.ui.core.css'
        , '/tapper/static/css/jquery-ui/jquery.ui.datepicker.css'
    ;

    # set js file
    push @{$or_c->stash->{js_files}},
          '/tapper/static/js/jquery-ui/jquery.ui.core.js'
        , '/tapper/static/js/jquery-ui/jquery.ui.effect.js'
        , '/tapper/static/js/jquery-ui/jquery.ui.datepicker.js'
        , '/tapper/static/js/jquery-ui/jquery.ui.effect-slide.js'
        , '/tapper/static/js/metareports.js'
        , '/tapper/static/js/jquery-plugins/jquery.json.js'
        , '/tapper/static/js/jquery-plugins/jquery.flot.js'
        , '/tapper/static/js/jquery-plugins/jquery.flot.time.js'
        , '/tapper/static/js/jquery-plugins/jquery.flot.selection.js'
        , '/tapper/static/js/jquery-plugins/jquery.timepicker.js'
    ;

    my $hr_params = $or_c->req->params;
    my $or_schema = $or_c->model('TestrunDB');

    my ( $hr_search, $ar_join ) = hr_get_search( $or_schema, $hr_params );
    if ( $hr_search ) {

        $or_c->stash->{chart} = $or_schema
            ->resultset('ChartVersions')
            ->search(
                $hr_search,
                {
                    join     => $ar_join,
                    prefetch => [
                        {
                            'chart_lines' => {
                                'chart_line_restrictions' => 'chart_line_restriction_values',
                            },
                        },{
                            'chart' => [
                                'chart_versions',
                                { 'chart_tag_relations' => 'chart_tag', },
                            ],
                        },
                    ],
                }
            )
            ->first()
        ;

        # check for template parameter
        my %h_restriction_values;
        for my $or_chart_line ( $or_c->stash->{chart} ? $or_c->stash->{chart}->chart_lines : () ) {
            for my $or_restriction ( $or_chart_line->chart_line_restrictions ) {
                if ( $or_restriction->is_template_restriction ) {
                    my $s_restricted_value =
                        ($or_restriction->chart_line_restriction_values)[0]->chart_line_restriction_value
                    ;
                    if ( $hr_params->{$s_restricted_value} ) {
                        $h_restriction_values{$s_restricted_value} = $hr_params->{$s_restricted_value};
                    }
                    else {
                        $or_c->stash->{error} = "Missing restricted value '$s_restricted_value'";
                    }
                }
            }
        }
        if ( %h_restriction_values ) {
            $or_c->stash->{parameter_restriction_values} = \%h_restriction_values;
        }

    }

    return 1;

}

sub chart_overview : Local {

    my ( $or_self, $or_c ) = @_;

    # set css file
    push @{$or_c->stash->{css_files}},
          '/tapper/static/css/metareports/chart_overview.css'
    ;

    # set js file
    push @{$or_c->stash->{js_files}},
          '/tapper/static/js/metareports.js'
        , '/tapper/static/js/jquery-plugins/jquery.flot.js'
        , '/tapper/static/js/jquery-plugins/jquery.flot.time.js'
    ;

    my $hr_where = {
        'me.active'                     => 1,
        'chart_versions.chart_version'  => \" = (
            SELECT MAX(cv.chart_version)
            FROM chart_versions cv
            WHERE cv.chart_id = chart_versions.chart_id
        )",
    };
    my $hr_options = {
        order_by => {
            -asc => 'chart_versions.chart_name'
        },
        join => [
            {
                'chart_versions' => {
                    'chart_lines' => {
                        'chart_line_restrictions' => 'chart_line_restriction_values',
                    },
                },
            },
        ],
        prefetch => {
            'chart_versions' => {
                'chart_lines' => {
                    'chart_line_restrictions' => 'chart_line_restriction_values',
                },
            },
        },
    };

    my $i_chart_tag = $or_c->req->params->{chart_tag};
    if ( defined($i_chart_tag) && $i_chart_tag ne '0' ) {
        $hr_where->{'chart_tag_relations.chart_tag_id'} = $i_chart_tag;
        push @{$hr_options->{join}}, 'chart_tag_relations';
    }

    $or_c->stash->{head_overview}   = 'Metareports - Overview';
    $or_c->stash->{charts}          = [
        $or_c->model('TestrunDB')->resultset('Charts')->search(
            $hr_where, $hr_options,
        )
    ];

    return 1;

}

sub get_chart_points : Local {

    my ( $or_self, $or_c ) = @_;

    my %h_params  = %{$or_c->req->params};
    my $or_schema = $or_c->model('TestrunDB');

    # get chart information
    my ( $hr_search, $ar_join ) = hr_get_search( $or_schema, \%h_params );
    if (! $hr_search ) {
        $or_c->res->status( 500 );
        $or_c->stash->{content} = { error => 'cannot create search condition' };
    }

    my $or_chart  = $or_schema->resultset('ChartVersions')->search(
        $hr_search,
        {
            join     => $ar_join,
            prefetch => [
                {
                    'chart_lines' => [
                        'chart_additionals',
                        {
                            'chart_line_restrictions' => 'chart_line_restriction_values',
                        },
                        {
                            'chart_axis_elements' => [
                                'axis_column',
                                'axis_separator',
                            ],
                        },
                    ],
                },
                'chart_markings',
                'chart_axis_type_x',
                'chart_axis_type_y',
                'chart_type',
            ],
        }
    )->first();

    my %h_axis = ( x => {}, y => {}, );
    my ( @a_first, @a_last, @a_result, @a_markings, @a_chart_line_point_warnings );

    # update tiny url counter if exists
    my $or_tiny_url;
    my $NOW = DateTime->now();
    if ( my $i_chart_tiny_url_id = $h_params{chart_tiny_url} ) {
        $or_tiny_url = $or_schema
            ->resultset('ChartTinyUrls')
            ->search({
                'me.chart_tiny_url_id' => $i_chart_tiny_url_id,
            },{
                rows     => 1,
                prefetch => {
                    chart_tiny_url_line => 'chart_tiny_url_relation'
                },
            })
            ->first()
        ;
        if ($or_tiny_url) {
        $or_tiny_url->visit_count( $or_tiny_url->visit_count() + 1 );
        $or_tiny_url->last_visited($NOW);
        $or_tiny_url->update();
        $or_c->stash->{tiny_url_count} = $or_tiny_url->visit_count;
        }
    }

    if ( my @a_chart_lines = $or_chart->chart_lines ) {

        require JSON::XS;
        require YAML::Syck;
        require Tapper::Config;
        require BenchmarkAnything::Storage::Frontend::Lib;

        my $balib = BenchmarkAnything::Storage::Frontend::Lib->new
          (cfgfile => Tapper::Config->subconfig->{_last_used_tapper_config_file});

        require DateTime;
        require DateTime::Format::Epoch;
        require DateTime::Format::Strptime;
        my $formatter = DateTime::Format::Epoch->new(
            epoch               => DateTime->new( year => 1970, month => 1, day => 1 ),
            unit                => 'milliseconds',
            type                => 'int',    # or 'float', 'bigint'
            skip_leap_seconds   => 1,
            start_at            => 0,
            local_epoch         => undef,
        );

        my %h_counter       = (
            x   => 0 ,
            y   => 0,
        );
        my %h_axis_type     = (
            x   => $or_chart->chart_axis_type_x->chart_axis_type_name,
            y   => $or_chart->chart_axis_type_y->chart_axis_type_name,
        );
        my %h_label_type    = (
            x   => $h_axis_type{x} eq 'alphanumeric' || $or_chart->order_by_x_axis == 2 && $or_chart->order_by_y_axis == 1 ? 'list' : 'auto',
            y   => $h_axis_type{y} eq 'alphanumeric' || $or_chart->order_by_y_axis == 2 && $or_chart->order_by_x_axis == 1 ? 'list' : 'auto',
        );

        $h_params{limit} ||= $h_params{graph_width} ? int( $h_params{graph_width} / 4 ) : 100;

        if ( $h_params{pager_direction} ) {
            if ( $h_params{pager_direction} eq 'prev' ) {
                $h_params{offset} = $h_params{offset};
            }
            else {
                $h_params{offset} = $h_params{offset} - ( $h_params{limit} * 2 );
            }
        }
        else {
            $h_params{offset} = 0;
        }

        CHART_LINE: for my $or_chart_line ( @a_chart_lines ) {

            my @a_additionals;
            my $b_value_id_exists = 0;
            for my $or_additional_column ( $or_chart_line->chart_additionals ) {
                if ( $or_additional_column->chart_line_additional_column eq 'VALUE_ID' ) {
                    $b_value_id_exists = 1;
                }
                push @a_additionals, [
                    $or_additional_column->chart_line_additional_column,
                    $or_additional_column->chart_line_additional_url,
                ];
            }
            if ( !$b_value_id_exists ) {
                unshift @a_additionals, ['VALUE_ID'];
            }

            my $hr_chart_search           = {};
               $hr_chart_search->{limit}  = $h_params{limit};
               $hr_chart_search->{offset} = $h_params{offset};

            for my $s_axis (qw/ x y /) {
                for my $or_element ( sort { $a->chart_line_axis_element_number <=> $b->chart_line_axis_element_number } $or_chart_line->chart_axis_elements ) {
                    if ( $or_element->chart_line_axis eq $s_axis && $or_element->axis_column ) {
                        push @{$hr_chart_search->{order_by}}, [
                            $or_element->axis_column->chart_line_axis_column,
                            'DESC',
                            { numeric   => $h_axis_type{$s_axis} eq 'numeric' },
                        ];
                    }
                }
            }

            my @a_chart_line_points;
            LOADING_DATA: {

                # set where clause with bench_value_id for tiny url
                if ( $or_tiny_url ) {
                    my $or_chart_tiny_url_line;
                    for my $or_act_line ( $or_tiny_url->chart_tiny_url_line ) {
                        if ( $or_act_line->chart_line_id == $or_chart_line->chart_line_id ) {
                            $or_chart_tiny_url_line = $or_act_line;
                        }
                    }
                    my @a_bench_value_ids = $or_chart_tiny_url_line
                        ->chart_tiny_url_relation
                        ->get_column('bench_value_id')
                        ->all
                    ;
                    if ( @a_bench_value_ids ) {
                        $hr_chart_search->{where} = [[
                            '=',
                            'VALUE_ID',
                            @a_bench_value_ids,
                        ]];
                    }
                    else {
                        last LOADING_DATA;
                    }
                }
                # set where clause
                elsif ( $or_chart_line->chart_line_restrictions ) {
                    $hr_chart_search->{where} ||= [];
                    for my $or_chart_line_restriction ( $or_chart_line->chart_line_restrictions ) {
                        my @a_chart_line_restriction_value;
                        if ( $or_chart_line_restriction->is_template_restriction ) {
                            my ( $s_restriction_value_identifier )
                                = ($or_chart_line_restriction->chart_line_restriction_values)[0]->chart_line_restriction_value
                            ;
                            if ( defined $h_params{$s_restriction_value_identifier} ) {
                                @a_chart_line_restriction_value = @{toarrayref( $h_params{$s_restriction_value_identifier} )};
                            }
                            else {
                                $or_c->stash->{content} = {
                                    error => "missing template parameter '$s_restriction_value_identifier'",
                                };
                                return 0;
                            }
                        }
                        else {
                            @a_chart_line_restriction_value = map {
                                $_->chart_line_restriction_value
                            } $or_chart_line_restriction->chart_line_restriction_values;
                        }
                        push @{$hr_chart_search->{where}}, [
                            $or_chart_line_restriction->chart_line_restriction_operator,
                            $or_chart_line_restriction->chart_line_restriction_column,
                            @a_chart_line_restriction_value,
                        ];
                    }
                }
                else {
                    last LOADING_DATA;
                }

                # set select columns
                my %h_chart_search_select = map { $_ => 1 }
                            (
                                map { $_->axis_column->chart_line_axis_column }
                                grep { $_->axis_column }
                                $or_chart_line->chart_axis_elements
                            ), (
                                map { $_->[0] } @a_additionals
                            );
                $hr_chart_search->{select} = [
                    keys %h_chart_search_select
                ];

                my $ar_chart_points = $balib->search( $hr_chart_search );

                if ( $ar_chart_points && @{$ar_chart_points} ) {

                    for my $or_element ( sort { $a->chart_line_axis_element_number <=> $b->chart_line_axis_element_number } $or_chart_line->chart_axis_elements ) {
                        if ( $or_element->axis_column ) {
                            push @a_first, [ $or_element->axis_column->chart_line_axis_column, $ar_chart_points->[-1]{$or_element->axis_column->chart_line_axis_column} ];
                            push @a_last , [ $or_element->axis_column->chart_line_axis_column, $ar_chart_points->[ 0]{$or_element->axis_column->chart_line_axis_column} ];
                        }
                    }

                    for my $hr_point ( @{$ar_chart_points} ) {

                        eval {

                            my $hr_chart_point = { x => q##, y => q##, additionals => {} };
                            for my $or_element ( sort { $a->chart_line_axis_element_number <=> $b->chart_line_axis_element_number } $or_chart_line->chart_axis_elements ) {
                                if ( $or_element->axis_column ) {
                                    if ( defined $hr_point->{$or_element->axis_column->chart_line_axis_column} ) {
                                        $hr_chart_point->{$or_element->chart_line_axis} .= $hr_point->{$or_element->axis_column->chart_line_axis_column};
                                    }
                                    else {
                                        die 'missing value for ' . $or_element->chart_line_axis . "-axis\n";
                                    }
                                }
                                else {
                                    $hr_chart_point->{$or_element->chart_line_axis} .= $or_element->axis_separator->chart_line_axis_separator;
                                }
                            }

                            my ( %h_strp );
                            if ( $or_chart->chart_axis_type_x->chart_axis_type_name eq 'date' ) {
                                if ( my $dt_format = $or_chart_line->chart_axis_x_column_format ) {
                                    require DateTime::Format::Strptime;
                                    $h_strp{x} = DateTime::Format::Strptime->new( pattern => $dt_format );
                                }
                                else {
                                    $or_c->response->status( 500 );
                                    $or_c->body('xaxis type is date but no date format is given for "' . $or_chart_line->chart_line_name . '"');
                                    return 1;
                                }
                            }
                            if ( $or_chart->chart_axis_type_y->chart_axis_type_name eq 'date' ) {
                                if ( my $dt_format = $or_chart_line->chart_axis_y_column_format ) {
                                    require DateTime::Format::Strptime;
                                    $h_strp{y} = DateTime::Format::Strptime->new( pattern => $dt_format );
                                }
                                else {
                                    $or_c->response->status( 500 );
                                    $or_c->body('yaxis type is date but no date format is given for "' . $or_chart_line->chart_line_name . '"');
                                    return 1;
                                }
                            }

                            for my $s_axis (qw/ x y /) {
                                $hr_chart_point->{$s_axis.'o'} = $hr_chart_point->{$s_axis};
                                if ( $h_strp{$s_axis} ) {
                                    $hr_chart_point->{$s_axis} = $formatter->format_datetime(
                                        $h_strp{$s_axis}->parse_datetime( $hr_chart_point->{$s_axis.'o'} )
                                    );
                                }
                            }

                            if ( $or_chart->order_by_x_axis == 1 && $or_chart->order_by_y_axis == 2 ) {
                                $hr_chart_point->{'yh'} = $hr_chart_point->{'x'}.'|-|'.$hr_chart_point->{'y'};
                            }
                            elsif ( $or_chart->order_by_x_axis == 2 && $or_chart->order_by_y_axis == 1 ) {
                                $hr_chart_point->{'xh'} = $hr_chart_point->{'y'}.'|-|'.$hr_chart_point->{'x'};
                            }

                            for my $s_axis (qw/ x y /) {
                                if ( $h_label_type{$s_axis} eq 'list' ) {
                                    $hr_chart_point->{$s_axis.'h'} //= $hr_chart_point->{$s_axis.'o'};
                                    $hr_chart_point->{$s_axis}       = $h_axis{$s_axis}{$hr_chart_point->{$s_axis.'h'}} //= $h_counter{$s_axis}++;
                                }
                            }

                            for my $ar_chart_line_addition ( @a_additionals ) {
                                $hr_chart_point->{additionals}{$ar_chart_line_addition->[0]} = [
                                    $hr_point->{$ar_chart_line_addition->[0]},
                                ];
                                if ( $ar_chart_line_addition->[1] ) {
                                    $hr_chart_point->{additionals}{$ar_chart_line_addition->[0]}[1] =
                                        $ar_chart_line_addition->[1];
                                }
                            }

                            if (( defined $hr_chart_point->{x} ) && ( defined $hr_chart_point->{y} )) {
                                push @a_chart_line_points, $hr_chart_point;
                            }

                        };
                        if ( $@ ) {
                            push @a_chart_line_point_warnings, $@;
                        }

                    }

                }

            } # LOADING_DATA

            push @a_result, {
                data          => \@a_chart_line_points,
                label         => $or_chart_line->chart_line_name,
                chart_line_id => $or_chart_line->chart_line_id,
            };

        }

        my %h_sort_function = (
            date                  => sub { $_[0] <=> $_[1] },
            numeric               => sub { $_[0] <=> $_[1] },
            alphanumeric          => sub { $_[0] cmp $_[1] },
        );

        $h_sort_function{x_first_array} =  sub {
               $h_sort_function{$h_axis_type{x}}->( $_[0]->[0], $_[1]->[0] )
            || $h_sort_function{$h_axis_type{y}}->( $_[0]->[1], $_[1]->[1] )
        };
        $h_sort_function{y_first_array} =  sub {
               $h_sort_function{$h_axis_type{y}}->( $_[0]->[0], $_[1]->[0] )
            || $h_sort_function{$h_axis_type{x}}->( $_[0]->[1], $_[1]->[1] )
        };
        $h_sort_function{x_first_hash} =  sub {
              $_[0]->{x} <=> $_[1]->{x}
           || $_[0]->{y} <=> $_[1]->{y}
        };
        $h_sort_function{y_first_hash} =  sub {
               $_[0]->{y} <=> $_[1]->{y}
            || $_[0]->{x} <=> $_[1]->{x}
        };

        # sortiere die Labels
        if ( $h_label_type{x} eq 'list' ) {
            my $i_counter = 0;
            if ( $or_chart->order_by_x_axis == 2 && $or_chart->order_by_y_axis == 1 ) {
                for my $ar_key ( sort { $h_sort_function{'y_first_array'}->( $a, $b ) } map {[split /\|-\|/, $_]} keys %{$h_axis{x}} ) {
                    $h_axis{x}{join '|-|', @{$ar_key}} = $i_counter++;
                }
            }
            else {
                for my $s_key ( sort { $h_sort_function{$h_axis_type{x}}->( $a, $b ) } keys %{$h_axis{x}} ) {
                    $h_axis{x}{$s_key} = $i_counter++;
                }
            }
        }
        if ( $h_label_type{y} eq 'list' ) {
            my $i_counter = 0;
            if ( $or_chart->order_by_x_axis == 1 && $or_chart->order_by_y_axis == 2 ) {
                for my $ar_key ( sort { $h_sort_function{'x_first_array'}->( $a, $b ) } map {[split /\|-\|/, $_]} keys %{$h_axis{y}} ) {
                    $h_axis{y}{join '|-|', @{$ar_key}} = $i_counter++;
                }
            }
            else {
                for my $s_key ( sort { $h_sort_function{$h_axis_type{y}}->( $a, $b ) } keys %{$h_axis{y}} ) {
                    $h_axis{y}{$s_key} = $i_counter++;
                }
            }
        }
        # setze die richtigen Label-Verknüpfungen nach der sortierung
        for my $hr_line ( @a_result ) {
            for my $hr_point ( @{$hr_line->{data}} ) {
                for my $s_axis (qw/ x y /) {
                    if ( $h_label_type{$s_axis} eq 'list' ) {
                        $hr_point->{$s_axis} = $h_axis{$s_axis}{delete $hr_point->{$s_axis.'h'}};
                    }
                }
            }
        }
        # sortiere die Datenpunkte
        AXIS: for my $s_axis (qw/ x y /) {
            if ( $or_chart->get_column('order_by_'.$s_axis.'_axis') == 1 ) {
                for my $hr_line ( @a_result ) {
                    @{$hr_line->{data}} = sort { $h_sort_function{$s_axis.'_first_hash'}->( $a, $b ) } @{$hr_line->{data}};
                }
                last AXIS;
            }
        } # AXIS

        # set chart markings
        for my $or_marking ( $or_chart->chart_markings ) {
            push @a_markings, {
                chart_marking_name      => $or_marking->chart_marking_name,
                chart_marking_color     => $or_marking->chart_marking_color,
                chart_marking_x_from    => $or_marking->chart_marking_x_from,
                chart_marking_x_to      => $or_marking->chart_marking_x_to,
                chart_marking_y_from    => $or_marking->chart_marking_y_from,
                chart_marking_y_to      => $or_marking->chart_marking_y_to,
            };
            if ( $a_markings[-1]{chart_marking_x_from} || $a_markings[-1]{chart_marking_x_to} ) {
                if ( $or_chart->chart_axis_type_x->chart_axis_type_name eq 'date' ) {
                    if ( my $dt_format = $or_marking->chart_marking_x_format ) {
                        require DateTime::Format::Strptime;
                        my $or_format_x = DateTime::Format::Strptime->new( pattern => $dt_format );
                        $a_markings[-1]{chart_marking_x_from} &&= $formatter->format_datetime($or_format_x->parse_datetime($a_markings[-1]{chart_marking_x_from}));
                        $a_markings[-1]{chart_marking_x_to}   &&= $formatter->format_datetime($or_format_x->parse_datetime($a_markings[-1]{chart_marking_x_to}));
                    }
                    else {
                        $or_c->response->status( 500 );
                        $or_c->body('xaxis type is date but no date format is given for marking "' . $or_marking->chart_marking_name . '"');
                        return 1;
                    }
                }
            }
            if ( $a_markings[-1]{chart_marking_y_from} || $a_markings[-1]{chart_marking_y_to} ) {
                if ( $or_chart->chart_axis_type_y->chart_axis_type_name eq 'date' ) {
                    if ( my $dt_format = $or_marking->chart_marking_y_format ) {
                        require DateTime::Format::Strptime;
                        my $or_format_y = DateTime::Format::Strptime->new( pattern => $dt_format );
                        $a_markings[-1]{chart_marking_y_from} &&= $formatter->format_datetime($or_format_y->parse_datetime($a_markings[-1]{chart_marking_y_from}));
                        $a_markings[-1]{chart_marking_y_to}   &&= $formatter->format_datetime($or_format_y->parse_datetime($a_markings[-1]{chart_marking_y_to}));
                    }
                    else {
                        $or_c->response->status( 500 );
                        $or_c->body('yaxis type is date but no date format is given for marking "' . $or_marking->chart_marking_name . '"');
                        return 1;
                    }
                }
            }
        }

    }

    $or_c->stash->{content} = {
        chart_type      => $or_chart->chart_type->chart_type_flot_name,
        xaxis_alphas    => [ map { [ $h_axis{x}{$_}, $_ ] } keys %{$h_axis{x}} ],
        yaxis_alphas    => [ map { [ $h_axis{y}{$_}, $_ ] } keys %{$h_axis{y}} ],
        xaxis_type      => $or_chart->chart_axis_type_x->chart_axis_type_name,
        yaxis_type      => $or_chart->chart_axis_type_y->chart_axis_type_name,
        order_by_x_axis => $or_chart->order_by_x_axis,
        order_by_y_axis => $or_chart->order_by_y_axis,
        offset          => ($h_params{offset} || 0) + ($h_params{limit} || 0),
        warnings        => \@a_chart_line_point_warnings,
        markings        => \@a_markings,
        series          => \@a_result,
    };

    return 1;

}

sub create_static_url : Local {

    my ( $or_self, $or_c ) = @_;

    my $i_chart_tiny_url_id;
    my $or_schema = $or_c->model('TestrunDB');
    my $hr_params = $or_c->req->params;

    try {
        $or_schema->txn_do(sub {

            if ( $hr_params->{ids} ) {

                require JSON::XS;
                my $ar_ids = JSON::XS::decode_json( $hr_params->{ids} );

                require DateTime;
                my $or_chart_tiny_url = $or_schema->resultset('ChartTinyUrls')->new({
                    created_at   => DateTime->now(),
                });
                $or_chart_tiny_url->insert();

                if ( $i_chart_tiny_url_id = $or_chart_tiny_url->chart_tiny_url_id ) {
                    for my $hr_chart_line ( @{$ar_ids} ) {
                        if ( $hr_chart_line->{chart_line_id} ) {

                            my $or_chart_tiny_url_line = $or_schema->resultset('ChartTinyUrlLines')->new({
                                chart_tiny_url_id => $i_chart_tiny_url_id,
                                chart_line_id     => $hr_chart_line->{chart_line_id},
                            });
                            $or_chart_tiny_url_line->insert();

                            if ( my $i_chart_tiny_url_line_id = $or_chart_tiny_url_line->chart_tiny_url_line_id ) {

                                my @a_relations;
                                for my $i_bench_value_id ( @{$hr_chart_line->{data}} ) {
                                    push @a_relations, {
                                        chart_tiny_url_line_id => $or_chart_tiny_url_line->chart_tiny_url_line_id,
                                        bench_value_id         => $i_bench_value_id,
                                    };
                                }

                                $or_schema->resultset('ChartTinyUrlRelations')->populate(
                                    \@a_relations
                                );

                            }
                            else {
                                die "error: cannot insert tiny url line";
                            }

                        }
                        else {
                            die "error: cannot find chart line id";
                        }
                    }
                }
                else {
                    die "error: cannot insert tiny url";
                }
            }

            $or_c->stash->{content} = {
                chart_tiny_url_id => $i_chart_tiny_url_id,
            };

        });
    }
    catch {
        $or_c->res->status( 500 );
        $or_c->response->body( "Transaction failed: $_" );
    };

    return 1;

}

sub get_columns : Private {

    my ( $or_self, $or_c ) = @_;

    require Tapper::Config;
    require BenchmarkAnything::Storage::Frontend::Lib;

    my $balib = BenchmarkAnything::Storage::Frontend::Lib->new
      (cfgfile => Tapper::Config->subconfig->{_last_used_tapper_config_file});

    my @a_columnlist = @{$balib->listkeys};
    push @a_columnlist, keys %{$balib->_default_additional_keys}; # TODO: too much unrequested data from this?

    return \@a_columnlist;

}

sub is_column : Private {

    my ( $or_self, $or_c, $s_column ) = @_;

    require Tapper::Config;
    require BenchmarkAnything::Storage::Frontend::Lib;

    my $balib = BenchmarkAnything::Storage::Frontend::Lib->new
      (cfgfile => Tapper::Config->subconfig->{_last_used_tapper_config_file});

    my $hr_columns = $balib->_default_additional_keys;

    return 1 if $hr_columns->{$s_column};

    my @a_columnlist = $balib->_get_additional_key_id($s_column);

    return @a_columnlist ? 1 : 0;

}

sub edit_chart : Local {

    my ( $or_self, $or_c ) = @_;

    # set css file
    push @{$or_c->stash->{css_files}},
          '/tapper/static/css/metareports/edit.css'
        , '/tapper/static/css/jquery-ui/jquery.ui.css'
    ;

    # set js file
    push @{$or_c->stash->{js_files}}, '/tapper/static/js/jquery-ui/jquery-ui-autocomplete.js';

    my $or_schema = $or_c->model('TestrunDB');
    if (! $or_c->stash->{chart} ) {
        if ( $or_c->req->params->{chart_id} ) {
            $or_c->stash->{chart} = get_edit_page_chart_hash_by_chart_id(
                $or_c->req->params,
                $or_schema,
            );
        }
        else {
            $or_c->stash->{chart} = {};
        }
    }

    $or_c->stash->{columns}       = $or_self->get_columns( $or_c );
    $or_c->stash->{head_overview} = 'Metareports - Edit' . ( $or_c->req->params->{asnew} ? ' as New' : q## );

    return 1;

}

sub get_edit_page_chart_hash_by_chart_id {

    my ( $hr_params, $or_schema ) = @_;

    my ( $hr_search, $ar_join ) = hr_get_search( $or_schema, $hr_params );
    my $or_chart = $or_schema->resultset('ChartVersions')->search(
        $hr_search,
        {
            join     => $ar_join,
            prefetch => {
                'chart'       => {
                    'chart_tag_relations' => 'chart_tag',
                },
                'chart_lines' => 'chart_additionals',
                'chart_lines' => {
                    'chart_axis_elements' => [
                        'axis_column',
                        'axis_separator',
                    ],
                },
            },
        },
    )->first();

    my $hr_chart = {
        chart_id                => $or_chart->chart_id,
        chart_version           => $or_chart->chart_version,
        chart_version_id        => $or_chart->chart_version_id,
        chart_name              => $or_chart->chart_name,
        chart_type_id           => $or_chart->chart_type_id,
        chart_axis_type_x_id    => $or_chart->chart_axis_type_x_id,
        chart_axis_type_y_id    => $or_chart->chart_axis_type_y_id,
        order_by_x_axis         => $or_chart->order_by_x_axis,
        order_by_y_axis         => $or_chart->order_by_y_axis,
        chart_lines             => [],
        chart_tag_new           => [
            map {
                $_->chart_tag->chart_tag
            } $or_chart->chart->chart_tag_relations
        ],
        chart_markings          => [
            map {{
                chart_marking_name       => $_->chart_marking_name,
                chart_marking_color      => $_->chart_marking_color,
                chart_marking_x_format   => $_->chart_marking_x_format,
                chart_marking_x_from     => $_->chart_marking_x_from,
                chart_marking_x_to       => $_->chart_marking_x_to,
                chart_marking_y_format   => $_->chart_marking_y_format,
                chart_marking_y_from     => $_->chart_marking_y_from,
                chart_marking_y_to       => $_->chart_marking_y_to,
            }} $or_chart->chart_markings
        ],
    };

    for my $or_line ( $or_chart->chart_lines ) {
        my ( %h_chart_elements );
        for my $or_element (
            sort {
                  $a->chart_line_axis_element_number <=> $b->chart_line_axis_element_number
            } $or_line->chart_axis_elements
        ) {
            push @{$h_chart_elements{$or_element->chart_line_axis} ||= []},
                $or_element->axis_column
                    ? [ 'column'   , $or_element->axis_column->chart_line_axis_column      , ]
                    : [ 'separator', $or_element->axis_separator->chart_line_axis_separator, ]
            ;
        }
        push @{$hr_chart->{chart_lines}}, {
            chart_line_name         => $or_line->chart_line_name,
            chart_line_restrictions => [map {{
                is_template_restriction         => $_->is_template_restriction,
                is_numeric_restriction          => $_->is_numeric_restriction,
                chart_line_restriction_column   => $_->chart_line_restriction_column,
                chart_line_restriction_operator => $_->chart_line_restriction_operator,
                chart_line_restriction_values   => [map {
                    $_->chart_line_restriction_value
                } $_->chart_line_restriction_values],
            }} $or_line->chart_line_restrictions],
            chart_line_x_column     => $h_chart_elements{x},
            chart_line_x_format     => $or_line->chart_axis_x_column_format(),
            chart_line_y_column     => $h_chart_elements{y},
            chart_line_y_format     => $or_line->chart_axis_y_column_format(),
            chart_additionals       => [],
        };
        for my $or_add ( $or_line->chart_additionals ) {
            push @{$hr_chart->{chart_lines}[-1]{chart_additionals}}, {
                chart_line_additional_column    => $or_add->chart_line_additional_column,
                chart_line_additional_url       => $or_add->chart_line_additional_url,
            };
        }
    }

    return $hr_chart;

}

sub get_undef_on_empty_string {
    return defined $_[0] && $_[0] eq q## ? undef : $_[0];
}

sub get_edit_page_chart_hash_by_params : Private {

    my ( $or_self, $or_c, $hr_params, $or_schema ) = @_;

    my @a_chart_marking_name     = @{toarrayref($hr_params->{chart_marking_name})};
    my @a_chart_marking_color    = @{toarrayref($hr_params->{chart_marking_color})};
    my @a_chart_marking_x_from   = @{toarrayref($hr_params->{chart_marking_x_from})};
    my @a_chart_marking_x_to     = @{toarrayref($hr_params->{chart_marking_x_to})};
    my @a_chart_marking_x_format = @{toarrayref($hr_params->{chart_marking_x_format})};
    my @a_chart_marking_y_from   = @{toarrayref($hr_params->{chart_marking_y_from})};
    my @a_chart_marking_y_to     = @{toarrayref($hr_params->{chart_marking_y_to})};
    my @a_chart_marking_y_format = @{toarrayref($hr_params->{chart_marking_y_format})};

    my $hr_chart = {
        chart_id                => $hr_params->{chart_id},
        chart_version           => $hr_params->{chart_version},
        chart_version_id        => $hr_params->{chart_version_id},
        chart_name              => $hr_params->{chart_name},
        chart_type_id           => $hr_params->{chart_type},
        chart_axis_type_x_id    => $hr_params->{chart_axis_type_x},
        chart_axis_type_y_id    => $hr_params->{chart_axis_type_y},
        order_by_x_axis         => $hr_params->{order_by_x_axis},
        order_by_y_axis         => $hr_params->{order_by_y_axis},
        chart_lines             => [],
        chart_tag_new           => [
            grep { $_ } @{toarrayref($hr_params->{chart_tag_new})}
        ],
        chart_markings          => [map{{
            chart_marking_name      => $_,
            chart_marking_color     => shift @a_chart_marking_color,
            chart_marking_x_from    => get_undef_on_empty_string( shift @a_chart_marking_x_from ),
            chart_marking_x_to      => get_undef_on_empty_string( shift @a_chart_marking_x_to ),
            chart_marking_x_format  => get_undef_on_empty_string( shift @a_chart_marking_x_format ),
            chart_marking_y_from    => get_undef_on_empty_string( shift @a_chart_marking_y_from ),
            chart_marking_y_to      => get_undef_on_empty_string( shift @a_chart_marking_y_to),
            chart_marking_y_format  => get_undef_on_empty_string( shift @a_chart_marking_y_format ),
        }} @a_chart_marking_name],
    };

    # column values for chart lines
    my @a_chart_line_names          = @{toarrayref($hr_params->{chart_line_name})};
    my @a_chart_line_x_columns      = @{toarrayref($hr_params->{chart_axis_x_column})};
    my @a_chart_line_y_columns      = @{toarrayref($hr_params->{chart_axis_y_column})};
    my @a_chart_line_x_counters     = @{toarrayref($hr_params->{chart_axis_x_counter})};
    my @a_chart_line_y_counters     = @{toarrayref($hr_params->{chart_axis_y_counter})};
    my @a_chart_line_x_formats      = @{toarrayref($hr_params->{chart_axis_x_format})};
    my @a_chart_line_y_formats      = @{toarrayref($hr_params->{chart_axis_y_format})};

    # column values chart line statements
    my @a_chart_where_counter       = @{toarrayref($hr_params->{chart_where_counter})};
    my @a_chart_where_column        = @{toarrayref($hr_params->{chart_line_where_column})};
    my @a_chart_where_operator      = @{toarrayref($hr_params->{chart_line_where_operator})};
    my @a_chart_value_counter       = @{toarrayref($hr_params->{chart_line_where_counter})};
    my @a_chart_where_value         = @{toarrayref($hr_params->{chart_line_where_value})};
    my @a_chart_line_where_template = @{toarrayref($hr_params->{chart_line_where_template})};
    my @a_chart_line_where_numeric  = @{toarrayref($hr_params->{chart_line_where_numeric})};

    # additional column data
    my @a_chart_add_counter         = @{toarrayref($hr_params->{chart_additional_counter})};
    my @a_chart_add_columns         = @{toarrayref($hr_params->{chart_additional_column})};
    my @a_chart_add_urls            = @{toarrayref($hr_params->{chart_additional_url})};

    # get default columns for check
    while ( my $s_chart_line_name = shift @a_chart_line_names ) {

        my $s_chart_line_x_format   = shift @a_chart_line_x_formats;
        my $s_chart_line_y_format   = shift @a_chart_line_y_formats;
        my $i_chart_where_counter   = shift @a_chart_where_counter;
        my $i_chart_add_counter     = shift @a_chart_add_counter;
        my $i_chart_line_x_counter  = shift @a_chart_line_x_counters;
        my $i_chart_line_y_counter  = shift @a_chart_line_y_counters;

        my @a_act_chart_line_x_columns;
        for my $i_chart_line_x_counter ( 1..$i_chart_line_x_counter ) {
            my $s_chart_line_x_column = shift @a_chart_line_x_columns;
            if ( $or_self->is_column( $or_c, $s_chart_line_x_column ) ) {
                push @a_act_chart_line_x_columns, [ 'column', $s_chart_line_x_column ];
            }
            else {
                push @a_act_chart_line_x_columns, [ 'separator', $s_chart_line_x_column ];
            }
        }

        my @a_act_chart_line_y_columns;
        for my $i_chart_line_y_counter ( 1..$i_chart_line_y_counter ) {
            my $s_chart_line_y_column = shift @a_chart_line_y_columns;
            if ( $or_self->is_column( $or_c, $s_chart_line_y_column ) ) {
                push @a_act_chart_line_y_columns, [ 'column', $s_chart_line_y_column ];
            }
            else {
                push @a_act_chart_line_y_columns, [ 'separator', $s_chart_line_y_column ];
            }
        }

        my @a_chart_line_restriction;
        for my $i_where_counter ( 1..$i_chart_where_counter ) {
            my $i_chart_value_counter = shift @a_chart_value_counter;
            push @a_chart_line_restriction, {
                is_template_restriction         => shift @a_chart_line_where_template,
                is_numeric_restriction          => shift @a_chart_line_where_numeric,
                chart_line_restriction_operator => shift @a_chart_where_operator,
                chart_line_restriction_column   => shift @a_chart_where_column,
                chart_line_restriction_values   => [map { shift @a_chart_where_value } 1..$i_chart_value_counter],
            };
        }

        push @{$hr_chart->{chart_lines}}, {
            chart_line_name         => $s_chart_line_name,
            chart_line_x_column     => \@a_act_chart_line_x_columns,
            chart_line_x_format     => $s_chart_line_x_format || undef,
            chart_line_y_column     => \@a_act_chart_line_y_columns,
            chart_line_y_format     => $s_chart_line_y_format || undef,
            chart_line_restrictions => \@a_chart_line_restriction,
            chart_additionals       => [],
        };

        for my $i_add_counter ( 1..$i_chart_add_counter ) {
            push @{$hr_chart->{chart_lines}[-1]{chart_additionals}}, {
                chart_line_additional_column => shift @a_chart_add_columns,
                chart_line_additional_url    => shift @a_chart_add_urls,
            };
        }

    }

    return $hr_chart;

}

sub save_chart : Local {

    my ( $or_self, $or_c ) = @_;

    my $or_schema       = $or_c->model('TestrunDB');
    my $hr_params       = $or_c->req->params;
    my $hr_search_param = {
        'chart.active'  => 1,
        'chart_name'    => $hr_params->{chart_name},
        'chart_version' => \'>= (
            SELECT MAX(cv.chart_version)
            FROM chart_versions cv
            WHERE cv.chart_id = me.chart_id
        )',
    };

    if ( $hr_params->{chart_id} ) {
        if (! $hr_params->{asnew} ) {
            $hr_search_param->{-not} = { 'me.chart_id' => $hr_params->{chart_id} };
        }
    }

    # serialize input data
    $or_c->stash->{chart} = $or_self->get_edit_page_chart_hash_by_params(
        $or_c, $hr_params, $or_schema,
    );

    my @a_charts = $or_schema->resultset('ChartVersions')->search( $hr_search_param, { join => 'chart' } );
    if ( @a_charts ) {
        $or_c->stash->{error} = 'chart name already exists';
        $or_c->go('/tapper/metareports/edit_chart');
    }

    my $i_chart_id;
    try {
        $or_schema->txn_do(sub {
            if ( $hr_params->{chart_version_id} ) {
                $or_c->stash->{error} = $or_self->remove_chart_version(
                    $hr_params->{chart_version_id}, $or_schema
                );
            }
            $or_self->insert_chart( $or_c, $or_schema );
            $or_self->insert_chart_tags( $or_c, $or_schema );
            $or_self->insert_chart_markings( $or_c, $or_schema, );
        });
    }
    catch {
        $or_c->stash->{error} = "Transaction failed: $_";
        $or_c->go('/tapper/metareports/edit_chart');
    };

    $or_c->redirect(
          '/tapper/metareports/detail?chart_tag='
        . $or_c->req->params->{chart_tag}
        . '&amp;chart_id='
        . $or_c->stash->{chart}{chart_id}
    );
    $or_c->detach();

    return 1;

}

sub toarrayref : Private {

    my ( $value ) = @_;

    if ( not defined $value ) {
        return [];
    }
    elsif ( ref( $value ) ne 'ARRAY' ) {
        return [ $value ];
    }

    return $value;

}

sub delete_chart : Local {

    my ( $or_self, $or_c ) = @_;

    my $or_schema = $or_c->model('TestrunDB');

    try {
        $or_schema->txn_do(sub {
            if (
                my $s_error = $or_self->remove_chart(
                    $or_c->req->params->{chart_id}, $or_schema
                )
            ) {
                die "Transaction failed: $s_error";
            }
        });
    }
    catch {
        $or_c->stash->{error} = "Transaction failed: $_";
    };

    if (! $or_c->stash->{error} ) {
        $or_c->stash->{message} = 'Chart successfully deleted';
    }

    $or_c->redirect('/tapper/metareports/chart_overview?chart_tag=' . $or_c->req->params->{chart_tag});
    $or_c->detach();

    return 1;

}

sub insert_chart : Private {

    my ( $or_self, $or_c, $or_schema ) = @_;

    my $hr_params  = $or_c->stash->{chart};
    my $i_chart_id = $hr_params->{chart_id};

    my $NOW = DateTime->now();
    if (! $i_chart_id ) {
        my $or_chart = $or_schema->resultset('Charts')->new({
            active      => 1,
            created_at  => $NOW,
        });
        $or_chart->insert();
        $i_chart_id = $or_chart->chart_id;
    }

    my $or_chart_version = $or_schema->resultset('ChartVersions')->new({
        chart_id                => $i_chart_id,
        chart_type_id           => $hr_params->{chart_type_id},
        chart_axis_type_x_id    => $hr_params->{chart_axis_type_x_id},
        chart_axis_type_y_id    => $hr_params->{chart_axis_type_y_id},
        chart_version           => $hr_params->{chart_id}
            ? $or_schema
                ->resultset('ChartVersions')
                ->search({ chart_id => $i_chart_id })
                ->get_column('chart_version')
                ->max + 1
            : 1,
        chart_name              => $hr_params->{chart_name},
        order_by_x_axis         => $hr_params->{order_by_x_axis},
        order_by_y_axis         => $hr_params->{order_by_y_axis},
        created_at              => $NOW,
    });
    $or_chart_version->insert();

    if ( my $i_chart_version_id = $or_chart_version->chart_version_id() ) {

        my $ar_columns = $or_self->get_columns( $or_c );
        for my $hr_chart_line ( @{$hr_params->{chart_lines}} ) {

            my $or_chart_line = $or_c->model('TestrunDB')->resultset('ChartLines')->new({
                chart_version_id            => $i_chart_version_id,
                chart_line_name             => $hr_chart_line->{chart_line_name},
                chart_axis_x_column_format  => $hr_chart_line->{chart_line_x_format} || undef,
                chart_axis_y_column_format  => $hr_chart_line->{chart_line_y_format} || undef,
                created_at                  => $NOW,
            });
            $or_chart_line->insert();

            if ( my $i_chart_line_id = $or_chart_line->chart_line_id ) {
                for my $s_axis (qw/ x y /) {
                    my $i_chart_line_number = 0;
                    for my $ar_element ( @{$hr_chart_line->{'chart_line_' . $s_axis . '_column'}} ) {
                        my $or_chart_element = $or_c->model('TestrunDB')->resultset('ChartLineAxisElements')->new({
                            chart_line_id                  => $i_chart_line_id,
                            chart_line_axis                => $s_axis,
                            chart_line_axis_element_number => ++$i_chart_line_number,
                        });
                        $or_chart_element->insert();
                        if ( my $i_element_id = $or_chart_element->chart_line_axis_element_id ) {
                            if ( $ar_element->[0] eq 'column' ) {
                                $or_c->model('TestrunDB')->resultset('ChartLineAxisColumns')->new({
                                    chart_line_axis_element_id => $i_element_id,
                                    chart_line_axis_column     => $ar_element->[1],
                                })->insert();
                            }
                            else {
                                $or_c->model('TestrunDB')->resultset('ChartLineAxisSeparators')->new({
                                    chart_line_axis_element_id => $i_element_id,
                                    chart_line_axis_separator  => $ar_element->[1],
                                })->insert();
                            }
                        }
                        else {
                            die 'cannot insert chart line element';
                        }
                    }
                }

                for my $hr_additionals ( @{$hr_chart_line->{chart_additionals}} ) {
                    $or_c->model('TestrunDB')->resultset('ChartLineAdditionals')->new({
                        chart_line_id                => $i_chart_line_id,
                        chart_line_additional_column => $hr_additionals->{chart_line_additional_column},
                        chart_line_additional_url    => $hr_additionals->{chart_line_additional_url} || undef,
                        created_at                   => $NOW,
                    })->insert();
                }

                for my $hr_chart_line_restriction ( @{$hr_chart_line->{chart_line_restrictions}} ) {

                    my $or_chart_line_restriction = $or_c->model('TestrunDB')->resultset('ChartLineRestrictions')->new({
                        chart_line_id                   => $i_chart_line_id,
                        chart_line_restriction_column   => $hr_chart_line_restriction->{chart_line_restriction_column},
                        chart_line_restriction_operator => $hr_chart_line_restriction->{chart_line_restriction_operator},
                        is_template_restriction         => $hr_chart_line_restriction->{is_template_restriction},
                        is_numeric_restriction          => $hr_chart_line_restriction->{is_numeric_restriction},
                        created_at                      => $NOW,
                    });
                    $or_chart_line_restriction->insert();

                    for my $s_chart_line_restriction_value ( @{$hr_chart_line_restriction->{chart_line_restriction_values}} ) {
                        $or_c->model('TestrunDB')->resultset('ChartLineRestrictionValues')->new({
                            chart_line_restriction_id    => $or_chart_line_restriction->chart_line_restriction_id(),
                            chart_line_restriction_value => $s_chart_line_restriction_value,
                        })->insert();
                    }

                }

                # set new chart_id and chart_version_id for later use
                $hr_params->{chart_id}         = $i_chart_id;
                $hr_params->{chart_version_id} = $i_chart_version_id;

            }
            else {
                die 'cannot insert chart line'
            }

        }

    }
    else {
        die 'cannot insert chart';
    }

    return 1;

}

sub insert_chart_markings : Private {

    my ( $or_self, $or_c, $or_schema ) = @_;

    my $hr_params = $or_c->stash->{chart};
    for my $hr_marking ( @{$hr_params->{chart_markings}} ) {
        $or_schema
            ->resultset('ChartMarkings')
            ->new({ chart_version_id => $hr_params->{chart_version_id}, %{$hr_marking} })
            ->insert()
        ;
    }

    return 1;

}

sub insert_chart_tags : Private {

    my ( $or_self, $or_c, $or_schema ) = @_;

    my $hr_params    = $or_c->stash->{chart};
    my @a_chart_tags = $or_schema
        ->resultset('ChartTagRelations')
        ->search(
            { chart_id => $hr_params->{chart_id} },
            { prefetch => 'chart_tag' },
        )
    ;

    my %h_chart_tags_new = map { $_ => 1 } @{$hr_params->{chart_tag_new}};
    for my $or_chart_tag ( @a_chart_tags ) {
        if ( $h_chart_tags_new{$or_chart_tag->chart_tag->chart_tag} ) {
            delete $h_chart_tags_new{$or_chart_tag->chart_tag->chart_tag};
        }
        else {
            $or_chart_tag->delete();
        }
    }

    my $NOW = DateTime->now();
    for my $s_chart_tag ( keys %h_chart_tags_new ) {
        $or_schema
            ->resultset('ChartTagRelations')
            ->find_or_create({
                chart_id     => $hr_params->{chart_id},
                chart_tag_id => $or_schema
                    ->resultset('ChartTags')
                    ->find_or_create(
                        { chart_tag => $s_chart_tag, created_at => $NOW },
                        { key       => 'ux_chart_tags_01'                   },
                    )->chart_tag_id
                ,
                created_at   => $NOW,
            })
        ;
    }

    return 1;

}

sub remove_chart : Private {

    my ( $or_self, $i_chart_id, $or_schema ) = @_;

    if (! $i_chart_id ) {
        return 'chart_id is missing';
    }

    my $or_chart = $or_schema->resultset('Charts')->find(
        $i_chart_id,
    );

    my $NOW = DateTime->now();
    $or_chart->active(0);
    $or_chart->updated_at($NOW);
    $or_chart->update();

    return q##;

}

sub remove_chart_version : Private {

    my ( $or_self, $i_chart_version_id, $or_schema ) = @_;

    if (! $i_chart_version_id ) {
        return 'chart_version_id is missing';
    }

    my $or_chart = $or_schema->resultset('ChartVersions')->find(
        $i_chart_version_id
    );

    my $NOW = DateTime->now();
    $or_chart->active(0);
    $or_chart->updated_at($NOW);
    $or_chart->update();

    return q##;

}

sub get_benchmark_operators : Private {

    my ( $or_self, $or_c ) = @_;

    require Tapper::Config;
    require BenchmarkAnything::Storage::Frontend::Lib;

    my $balib = BenchmarkAnything::Storage::Frontend::Lib->new
      (cfgfile => Tapper::Config->subconfig->{_last_used_tapper_config_file});

    return @{$balib->_get_benchmark_operators || []};

}

sub base : Chained PathPrefix CaptureArgs(0) {
    my ( $self, $c ) = @_;
    my $rule =  File::Find::Rule->new;
    $c->stash(rule => $rule);
}

sub prepare_navi : Private {
    my ( $self, $c ) = @_;

    $c->stash->{navi} = [
        {
            title  => "Metareports",
            href => "/tapper/metareports/",
        },
    ];

}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Tapper::Reports::Web::Controller::Tapper::Metareports - Tapper - Catalyst Controller Metareports

=head1 AUTHORS

=over 4

=item *

AMD OSRC Tapper Team <tapper@amd64.org>

=item *

Tapper Team <tapper-ops@amazon.com>

=back

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2017 by Advanced Micro Devices, Inc..

This is free software, licensed under:

  The (two-clause) FreeBSD License

=cut
