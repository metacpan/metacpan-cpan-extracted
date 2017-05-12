function get_chart_point_url ( $chart ) {

    var chart_point_url =
          '/tapper/metareports/get_chart_points?'
        + 'json=1'
        + '&amp;graph_width=' + $chart.width()
    ;

    var chart_tiny_url_id = $('#hd_chart_tiny_url_idx').val();
    if ( chart_tiny_url_id ) {

        chart_point_url += '&amp;chart_tiny_url=' + chart_tiny_url_id;

    }
    else {

        var offset           = $('#hd_offset_idx').val();
        var $chart_box       = $chart.closest('div.chart_boxs');
        var chart_version    = $chart_box.attr('chart_version');
        var pager_direction  = $('#hd_pager_direction_idx').val();

        if ( chart_version ) {
            chart_point_url += '&amp;chart_version='    + chart_version;
        }
        if ( pager_direction ) {
            chart_point_url += '&amp;pager_direction='  + pager_direction;
        }
        if ( offset ) {
            chart_point_url += '&amp;offset='           + offset;
        }

        chart_point_url     += '&amp;chart_id=' + $chart_box.attr('chart');

    }

    return chart_point_url;

}

function showTooltip( x, y, data, id ) {

    var contents  = "";
        contents += "y-value: "     + ( data.yo ) + "<br />";
        contents += "x-value: "     + ( data.xo ) + "<br />"
    ;

    $.each( Object.keys(data.additionals).sort(), function(index,key) {
        var val   = data.additionals[key];
        var value = val[0];
        if ( val[1] != null ) {
            value = '<a href="' + val[1].replace(/\$value\$/g, value) + '">' + value + '</a>';
        }
        contents += key + ": " + value + "<br />";
    });

    $('<div id="'+id+'">' + contents + '</div>').css( {
        position: 'absolute',
        display: 'none',
        top: y + 5,
        left: x + 5,
        border: '1px solid #fdd',
        padding: '2px',
        'background-color': '#fee',
        opacity: 0.90
    }).appendTo("body").fadeIn(200);

}

function create_search_url( $act_chart ){
    var url =
          '/tapper/metareports/detail?offset='
        + $('#hd_offset_idx').val()
        + '&amp;chart_tag='
        + $('#idx_chart_tag').val()
        + '&amp;chart_id='
        + $act_chart.closest('div.chart_boxs').attr('chart')
    ;
    return url;
}

function get_chart_points ( $act_chart, params ) {

    var chart_id = $act_chart.closest('div.chart_boxs').attr('chart');

    if ( chart_id ) {

        if (! params.detail ) {
           $act_chart.click(function(){
               location.href = '/tapper/metareports/detail?chart_tag='+$('#idx_chart_tag').val()+'&amp;chart_id='+$(this).closest('div.chart_boxs').attr('chart');
           });
        }

        $.ajax({
            method   : 'GET',
            dataType : 'json',
            url      : get_chart_point_url($act_chart),
            error    : function () {
                $act_chart.html('<span class="chart_error">aborted</span>');
                return 0;
            },
            success  : function ( chart_data ) {

                var notification;
                var overview_identifier = "#overviewchart_" + chart_id;

                if ( chart_data.error ) {
                    notification = '<span class="chart_error">'+chart_data.error+'</span>';
                }
                else if ( chart_data.series.length < 1 ) {
                    notification = '<span class="chart_info">no data found</span>';
                }
                if ( notification ) {
                    $act_chart.html(notification);
                    if ( params.detail ) {
                        $(overview_identifier).html('');
                    }
                    return 0;
                }

                var options = {
                    legend      : { position    : "nw" },
                    points      : { show        : true },
                    xaxis       : { show        : true },
                    yaxis       : { show        : true },
                    selection   : { mode        : "xy" },
                    grid        : { borderWidth : 1 }
                };
                var options_overview = {
                    legend      : { show: false },
                    xaxis       : { show: false },
                    yaxis       : { show: false },
                    selection   : { mode: "xy" },
                    grid        : { borderWidth: 1 }
                };

                if ( chart_data.chart_type == 'points' ) {
                    options_overview.points = { show: true };
                }
                else if ( chart_data.chart_type == 'lines' ) {
                    if (! params.detail ) {
                        options.points.show = false;
                    }
                    options.lines          = { show: true };
                    options_overview.lines = { show: true };
                }

                if ( params.detail ) {
                    options.xaxis.ticks = Math.floor( $act_chart.width() / 22 );
                    options.grid        = {
                        hoverable: true,
                        clickable: true
                    };
                    if ( chart_data.order_by_x_axis == 1 && chart_data.order_by_y_axis == 2 ) {
                        options.yaxis.show  = false;
                    }
                    else if ( chart_data.order_by_x_axis == 2 && chart_data.order_by_y_axis == 1 ) {
                        options.xaxis.show  = false;
                    }
                }
                else {
                    options.xaxis.show  = false;
                    options.yaxis.show  = false;
                }

                var last_ranges;
                var x_axis_labels           = [];
                var y_axis_labels           = [];
                var choiceContainer         = $("#choices");
                var chart_identifier        = "#mainchart_" + chart_id;
                var chart_identifier_height = $(chart_identifier).height();

                if ( chart_data.xaxis_type == 'date' ) {
                    options.xaxis.mode       = "time";
                    options.xaxis.timeformat = "%Y-%m-%d %H:%M:%S";
                }
                if ( chart_data.yaxis_type == 'date' ) {
                    options.yaxis.mode       = "time";
                    options.yaxis.timeformat = "%Y-%m-%d %H:%M:%S";
                }

                if ( chart_data.xaxis_alphas.length > 0 ) {
                    options.xaxis.ticks = chart_data.xaxis_alphas;
                }
                if ( chart_data.yaxis_alphas.length > 0 ) {
                    options.yaxis.ticks = chart_data.yaxis_alphas;
                }

                function getData() {

                    var x1, x2;
                    var returner = { chart : [] };

                    if ( last_ranges ) {
                       x1 =  last_ranges.xaxis.from;
                       x2 =  last_ranges.xaxis.to;
                    }

                    SERIES:
                    for ( var i = 0; i < chart_data.series.length; i++ ) {

                        var line = {
                            color : i,
                            label : chart_data.series[i].label,
                            data  : []
                        };
                        if ( choiceContainer.length > 0 ) {
                            if ( choiceContainer.find("input[line='"+i+"']:checked").length == 0 ) {
                                continue SERIES;
                            }
                        }
                        for ( var j = 0; j < chart_data.series[i].data.length; j++ ) {
                            if ( ( !x1 && !x2 ) || ( x1 < chart_data.series[i].data[j].x && chart_data.series[i].data[j].x < x2 ) ) {
                                line.data.push([
                                    chart_data.series[i].data[j].x,
                                    chart_data.series[i].data[j].y,
                                    chart_data.series[i].data[j]
                                ]);
                            }
                            if ( returner.min_x_value == undefined ) {
                                returner.min_x_value = chart_data.series[i].data[j].x;
                            }
                            else if ( chart_data.series[i].data[j].x_value < returner.min_x_value ) {
                                returner.min_x_value = chart_data.series[i].data[j].x;
                            }
                            if ( returner.max_x_value == undefined ) {
                                returner.max_x_value = chart_data.series[i].data[j].x;
                            }
                            else if ( chart_data.series[i].data[j].x_value > returner.max_x_value ) {
                                returner.max_x_value = chart_data.series[i].data[j].x;
                            }
                        }
                        returner.chart.push(line);
                    }

                    return returner;

                }

                // insert warnings if exists
                if ( chart_data.warnings && chart_data.warnings.length > 0 ) {
                    var $heading = $act_chart.closest('div.chart_boxs').find('div.chart_headers div.text font.title');
                    $heading.html(
                          $heading.text()
                        + '<font class="chart_error">('
                        + (chart_data.warnings.length)
                        + ' chart data points ignored)'
                        + '</font>'
                    );
                }

                if ( params.detail ) {

                    var plot;
                    var $overview;

                    // insert checkboxes
                    $.each( chart_data.series, function( key, val ) {
                        choiceContainer.append(
                            '<br/><input type="checkbox" checked="checked" line="'+key+'" id="id' + key + '">' +
                            '<label for="id' + key + '">' +
                            val.label + '</label>'
                        );
                    });

                    function plotAccordingToChoices() {
                        var data = getData();
                        if ( data.chart.length > 0 ) {
                            if (! options.grid ) {
                                options.grid = {};
                            }
                            if (! options.grid.markings ) {
                                options.grid.markings = [];
                            }

                            $('#idx_marking_area').html('<legend>markings</legend>');
                            $.each(chart_data.markings, function( index, marking ){

                                // set marking legend
                                $('#idx_marking_area').append(
                                      "<div style='background-color:#"
                                    + marking.chart_marking_color
                                    + ";'></div>"
                                    + marking.chart_marking_name
                                    + "<br />"
                                );

                                // set markings inside options
                                options.grid.markings.push({
                                    color : '#'+marking.chart_marking_color,
                                    yaxis : {
                                        from : marking.chart_marking_y_from,
                                        to   : marking.chart_marking_y_to
                                    },
                                    xaxis : {
                                        from : marking.chart_marking_x_from,
                                        to   : marking.chart_marking_x_to
                                    }
                                });

                            });

                            // set original height
                            $(chart_identifier).height(chart_identifier_height);
                            var $extend;
                            if ( last_ranges ) {
                                $.extend(true, {}, options, {
                                    xaxis: { min: last_ranges.xaxis.from, max: last_ranges.xaxis.to },
                                    yaxis: { min: last_ranges.yaxis.from, max: last_ranges.yaxis.to }
                                });
                            }
                            plot = $.plot( chart_identifier, data.chart, options, $extend );
                            set_plot_height( chart_identifier );
                            if (! $overview) {
                                $overview = $.plot( overview_identifier, data.chart, options_overview );
                            }

                        }

                    }

                    var max_series_length = 0;
                    for ( var i = 0; i < chart_data.series.length; i = i + 1 ) {
                        if ( chart_data.series[i].data.length > max_series_length ) {
                            max_series_length = chart_data.series[i].data.length;
                        }
                    }
                    if ( Math.floor( $act_chart.width() / 4 ) == max_series_length ) {
                        $('#dv_searchleft_idx').click(function(){
                            location.href = create_search_url($act_chart) + '&amp;pager_direction=prev';
                        }).css('cursor','pointer');
                    } else {
                        $('#dv_searchleft_idx').css('visibility', 'hidden');
                    }
                    if (
                           $('#hd_offset_idx').val() != 0
                        && $('#hd_offset_idx').val() != ( 2 * chart_data.offset )
                    ) {
                        $('#dv_searchright_idx').click(function(){
                            location.href = create_search_url($act_chart) + '&amp;pager_direction=next';
                        }).css('cursor','pointer');
                    } else {
                        $('#dv_searchright_idx').css('visibility', 'hidden');
                    }

                    $(chart_identifier).bind("plotselected", function (event, ranges) {

                        // clamp the zooming to prevent eternal zoom
                        if (ranges.xaxis.to - ranges.xaxis.from < 0.00001) {
                            ranges.xaxis.to = ranges.xaxis.from + 0.00001;
                        }
                        if (ranges.yaxis.to - ranges.yaxis.from < 0.00001) {
                            ranges.yaxis.to = ranges.yaxis.from + 0.00001;
                        }

                        last_ranges = ranges;

                        // set original height
                        $(chart_identifier).height(chart_identifier_height);

                        plotAccordingToChoices();

                        // don't fire event on the overview to prevent eternal loop
                        $overview.setSelection(ranges, true);

                    });
                    $(overview_identifier).bind("plotselected", function (event, ranges) {
                        plot.setSelection(ranges);
                    });
                    $(overview_identifier).bind("plotunselected", function (event, ranges) {
                        last_ranges = null;
                        plotAccordingToChoices();
                    });

                    var previousPointHover = null;
                    $(chart_identifier).bind("plothover", function (event, pos, item) {
                        if ( item ) {
                            if ( previousPointHover != item.dataIndex ) {
                                previousPointHover = item.dataIndex;
                                $("#hovertip").remove();
                                var x    = item.datapoint[0].toFixed(2),
                                    y    = item.datapoint[1].toFixed(2),
                                    data = item.series.data[item.dataIndex][2]
                                ;
                                showTooltip( item.pageX, item.pageY, data, 'hovertip' );
                            }
                        }
                        else {
                            $("#hovertip").remove();
                            previousPointHover = null;
                        }
                    });

                    var previousPointClick = null;
                    $(chart_identifier).bind("plotclick", function (event, pos, item) {
                        if ( item ) {
                            if ( previousPointClick != item.dataIndex ) {
                                previousPointClick = item.dataIndex;
                                $("#clicktip").remove();
                                var x    = item.datapoint[0].toFixed(2),
                                    y    = item.datapoint[1].toFixed(2),
                                    data = item.series.data[item.dataIndex][2]
                                ;
                                showTooltip( item.pageX, item.pageY, data, 'clicktip' );
                            }
                        }
                        else {
                            $("#clicktip").remove();
                            previousPointClick = null;
                        }
                    });

                    $('#hd_offset_idx').val( chart_data.offset );
                    $('#bt_create_static_url_idx').click(function(){
                        $(this)
                            .attr('disabled','disabled')
                            .val('Saving ...')
                        ;
                        var ids = [];
                        for ( var i = 0; i < chart_data.series.length; i = i + 1 ) {
                            ids[i] = {
                                data          : [],
                                chart_line_id : chart_data.series[i].chart_line_id
                            };
                            for ( var j = 0; j < chart_data.series[i].data.length; j = j + 1 ) {
                                ids[i].data[j] = chart_data.series[i].data[j].additionals.VALUE_ID[0];
                            }
                        }

                        $.ajax({
                            method   : 'POST',
                            dataType : 'json',
                            url      : '/tapper/metareports/create_static_url',
                            data     : {
                                'json'      : 1,
                                'ids'       : $.toJSON( ids ),
                                'chart_tag' : $('#idx_chart_tag').val()
                            },
                            success  : function ( data ) {
                                $('#bt_create_static_url_idx').replaceWith(
                                      '<a href="/tapper/metareports/detail?chart_tiny_url='
                                    + data.chart_tiny_url_id
                                    + '&amp;chart_tag='
                                    + $('#idx_chart_tag').val()
                                    + '">'
                                    + 'Go to static URL'
                                    + '</a>'
                                );
                            }
                        });
                    });

                    choiceContainer.find("input").click( plotAccordingToChoices );
                    plotAccordingToChoices();

                }
                else {
                   var serialized = getData();
                   $.plot( chart_identifier, serialized.chart, options );
                }

            },
        });
    }
}

function set_plot_height( identifier ) {
    // get width of text
    var width = 0;
    $('div.xAxis > div.tickLabel').each(function(){
        var label = $('<font>' + $(this).text() + '</font>').appendTo("body");
        if ( width < label.width() ) {
            width = label.width();
        }
        label.remove();
    });
    $(identifier).css( 'height', $(identifier).height() + Math.floor(width/2) );
}

$(document).ready(function(){
    var version = $('#idx_chart_version').val();
    var version_param = (typeof version === "undefined" ? '' : '&amp;chart_version='+version);

    $('#columnA_2columns img.imgdel').click(function(){
        if ( confirm("Really delete chart?") == true ) {
            location.href = '/tapper/metareports/delete_chart?chart_tag='+$('#idx_chart_tag').val()+"&amp;chart_id="+$(this).closest('.chart_boxs').attr('chart');
        }
    });
    $('#columnA_2columns img.imgedit').click(function(){
        location.href = '/tapper/metareports/edit_chart?chart_tag='+$('#idx_chart_tag').val()+version_param+'&amp;chart_id='+$(this).closest('.chart_boxs').attr('chart');
    });
    $('#columnA_2columns img.imgeditasnew').click(function(){
        location.href = '/tapper/metareports/edit_chart?chart_tag='+$('#idx_chart_tag').val()+'&amp;asnew=1&amp;chart_id='+$(this).closest('.chart_boxs').attr('chart');
    });
    $('#columnA_2columns img.imgjson').click(function(){
        location.href = get_chart_point_url($(this).closest('div.chart_boxs').find('div.charts'));
    });
});
