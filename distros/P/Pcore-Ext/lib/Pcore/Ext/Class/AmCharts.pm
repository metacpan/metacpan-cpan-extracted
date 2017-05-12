package Pcore::Ext::Class::AmCharts;

use Pcore -class;

our $EXT_MAP = {    #
    panel => 'Ext.panel.Panel',
};

sub EXT_panel ($ext) {
    return {
        chartConfig => undef,

        viewModel => {},

        defaultListenerScope => \1,

        header => {
            items => [
                {   xtype    => 'tool',
                    type     => 'refresh',
                    tooltip  => 'Refresh',
                    callback => 'onStoreRefresh',
                }
            ]
        },

        initComponent => $ext->js_func(
            <<'JS'
                this.callParent();

                this.getViewModel().setStores({
                    store: {
                        // autoLoad: true,
                        model: Ext.create(this.model),
                        listeners: {
                            scope: this,
                            load: 'onStoreLoad'
                        }
                    }
                });
JS
        ),

        onStoreRefresh => $ext->js_func(
            <<'JS'
                var store = this.getViewModel().getStore('store');

                store.reload();
JS
        ),

        onStoreLoad => $ext->js_func(
            <<'JS'
                if (this.chart) {
                    var store = this.getViewModel().getStore('store');

                    this.chart.dataProvider = Ext.pluck(store.data.items, 'data');

                    this.chart.validateData();
                }
JS
        ),

        _attachCharts => $ext->js_func(
            <<'JS'
                var me = this;

                var urls = [];
                var AmChartsUndefined;

                if (typeof (AmCharts) == 'undefined') {
                    AmChartsUndefined = 1;
                    AmCharts = {
                        themes: {}
                    };

                    urls.push('/static/amcharts-v3.21.1/amcharts.js');
                } else {
                    AmChartsUndefined = 0;
                }

                if (this.chartConfig.type == 'serial' && typeof (AmCharts.AmSerialChart) == 'undefined') urls.push('/static/amcharts-v3.21.1/serial.js');
                if (this.chartConfig.type == 'pie' && typeof (AmCharts.AmPieChart) == 'undefined') urls.push('/static/amcharts-v3.21.1/pie.js');
                if (this.chartConfig.type == 'xy' && typeof (AmCharts.AmXYChart) == 'undefined') urls.push('/static/amcharts-v3.21.1/xy.js');
                if (this.chartConfig.type == 'radar' && typeof (AmCharts.AmRadarChart) == 'undefined') urls.push('/static/amcharts-v3.21.1/radar.js');
                if (this.chartConfig.type == 'funnel' && typeof (AmCharts.AmFunnelChart) == 'undefined') urls.push('/static/amcharts-v3.21.1/funnel.js');
                if (this.chartConfig.type == 'gauge' && typeof (AmCharts.GaugeAxis) == 'undefined') urls.push('/static/amcharts-v3.21.1/gauge.js');
                if (this.chartConfig.type == 'map' && typeof (AmCharts.AmMap) == 'undefined') urls.push('/static/ammap-v3.21.1/ammap_amcharts_extension.js');
                if (this.chartConfig.type == 'stock' && typeof (AmCharts.AmStockChart) == 'undefined') urls.push('/static/amcharts-v3.21.1/stock.js');

                if (this.chartConfig.theme == 'black' && typeof (AmCharts.themes.black) == 'undefined') urls.push('/static/amcharts-v3.21.1/themes/black.js');
                if (this.chartConfig.theme == 'chalk' && typeof (AmCharts.themes.chalk) == 'undefined') urls.push('/static/amcharts-v3.21.1/themes/chalk.js');
                if (this.chartConfig.theme == 'dark' && typeof (AmCharts.themes.dark) == 'undefined') urls.push('/static/amcharts-v3.21.1/themes/dark.js');
                if (this.chartConfig.theme == 'light' && typeof (AmCharts.themes.light) == 'undefined') urls.push('/static/amcharts-v3.21.1/themes/light.js');
                if (this.chartConfig.theme == 'patterns' && typeof (AmCharts.themes.patterns) == 'undefined') urls.push('/static/amcharts-v3.21.1/themes/patterns.js');

                if (AmChartsUndefined) AmCharts = undefined;

                if (urls.length) {
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

        listeners => {
            afterRender => $ext->js_func(
                ['me'], <<'JS'
                    me._attachCharts();
JS
            ),
            resize => $ext->js_func(
                <<'JS'
                    if (this.chart) this.chart.invalidateSize();
JS
            ),
        }
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
