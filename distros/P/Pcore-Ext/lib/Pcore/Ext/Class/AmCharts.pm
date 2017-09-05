package Pcore::Ext::Class::AmCharts;

use Pcore -class;
use Pcore::Share::WWW;

our $EXT_MAP = {    #
    panel => 'Ext.panel.Panel',
};

sub EXT_panel ($ext) {
    return {
        mixins => ['Ext.util.StoreHolder'],

        config => {
            data        => undef,
            chartConfig => undef,
        },

        layout              => 'fit',
        defaultBindProperty => 'store',

        initComponent => $ext->js_func(
            <<'JS'
                this.bindStore(this.store || 'ext-empty-store', true);

                this.callParent(arguments);
JS
        ),

        onBindStore => $ext->js_func(
            [ 'store', 'initial' ], <<'JS'
                if (this.rendered) this.onStorerefresh();
JS
        ),

        getStoreListeners => $ext->js_func(
            ['store'], <<'JS'
                return {
                    load: this.onStorerefresh,
                    // prefetch: this.updateInfo,
                    // exception: this.onTotalCountChange
                };
JS
        ),

        setData => $ext->js_func(
            ['data'], <<'JS'
                if (this.chart) {
                    this.chart.dataProvider = data;

                    this.chart.validateData();
                }
JS
        ),

        onStorerefresh => $ext->js_func(
            <<'JS'
                if (this.chart) {
                    var store = this.getStore();

                    this.setData(Ext.Array.pluck(store.data.items, 'data'));
                }
JS
        ),

        _loadCharts => $ext->js_func(
            <<"JS"
                var urls = [];

                var chartsBaseUrl = '/static/amcharts/$Pcore::Share::WWW::VER->{amcharts}/';
                var mapBaseUrl = '/static/ammap/$Pcore::Share::WWW::VER->{ammap}/';

                if (typeof AmCharts == 'undefined') {
                    urls.push( chartsBaseUrl + 'amcharts.js');

                    if (this.chartConfig.type == 'map') {
                        urls.push( mapBaseUrl + 'ammap_amcharts_extension.js');
                    }
                    else {
                        urls.push( chartsBaseUrl + this.chartConfig.type + '.js');
                    }

                    if (this.chartConfig.theme) urls.push( chartsBaseUrl + 'themes/' + this.chartConfig.theme + '.js');
                } else {
                    if (this.chartConfig.type == 'map') {
                        if (typeof AmCharts.AmMap == 'undefined') urls.push( mapBaseUrl + 'ammap_amcharts_extension.js');
                    }
                    else {
                        var map = {
                            serial: 'AmSerialChart',
                            pie: 'AmPieChart',
                            xy: 'AmXYChart',
                            radar: 'AmRadarChart',
                            funnel: 'AmFunnelChart',
                            gauge: 'GaugeAxis',
                            stock: 'AmStockChart'
                        };

                        if (typeof AmCharts[this.chartConfig.type] == 'undefined') urls.push( chartsBaseUrl + this.chartConfig.type + '.js');
                    }

                    if (this.chartConfig.theme && typeof AmCharts.themes[this.chartConfig.theme] == 'undefined') urls.push( chartsBaseUrl + 'themes/' + this.chartConfig.theme + '.js');
                }

                if (urls.length) {
                    var me = this;

                    Ext.Loader.loadScripts({
                        url: urls,
                        cache: true,
                        onLoad: function () {
                            AmCharts.AmChart.prototype.brr = function () {};

                            me._renderCharts();
                        }
                    });
                } else {
                    this._renderCharts();
                }
JS
        ),

        _renderCharts => $ext->js_func(
            <<'JS'
                this.chart = AmCharts.makeChart(this.getTargetEl().dom, this.chartConfig);

                this.chart.write(this.getTargetEl().dom);
JS
        ),

        afterRender => $ext->js_func(
            <<'JS'
                this.callParent(arguments);

                this._loadCharts();
JS
        ),
    };
}

1;
__END__
=pod

=encoding utf8

=head1 NAME

Pcore::Ext::Class::AmCharts

=head1 SYNOPSIS

=head1 DESCRIPTION

=head1 ATTRIBUTES

=head1 METHODS

=head1 SEE ALSO

=cut
