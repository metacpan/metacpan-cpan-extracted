package Pcore::Ext::Lib::Modern::AmCharts3;

use Pcore -l10n;

sub EXT_panel : Extend('Ext.Component') : Type('widget') {
    return {
        config => {
            store       => undef,
            chartConfig => undef,
            dataHandler => undef,
        },

        layout              => 'fit',
        defaultBindProperty => 'store',

        constructor => func ['config'], <<'JS',
            this.callParent(arguments);

            this._loadCharts();
JS

        afterRender => func [], <<'JS',
            this.callParent(arguments);

            this._onReady();
JS

        updateStore => func [ 'newStore', 'oldStore' ], <<'JS',
            var me = this,
                bindEvents = Ext.apply({
                    scope: me
                }, me.getStoreListeners());

            if (oldStore && Ext.isObject(oldStore) && oldStore.isStore) {
                oldStore.un(bindEvents);
            }

            if (newStore) {
                newStore.on(bindEvents);
            }

            this._onReady();
JS

        getStoreListeners => func ['store'], <<'JS',
            return {
                load: this._onReady
                // prefetch: this.updateInfo,
                // exception: this.onTotalCountChange
            };
JS

        _loadCharts => func [], <<"JS",
            var urls = [],
                chartConfig = this.getChartConfig(),
                chartsBaseUrl = "@{[ $cdn->get_resources('amcharts3')->[0] ]}";
                mapBaseUrl = "@{[ $cdn->get_resources('ammap3')->[0] ]}";

            if (typeof AmCharts == 'undefined') {
                urls.push( chartsBaseUrl + 'amcharts.js');

                if (chartConfig.type == 'map') {
                    urls.push( mapBaseUrl + 'ammap_amcharts_extension.js');
                }
                else {
                    urls.push( chartsBaseUrl + chartConfig.type + '.js');
                }

                if (chartConfig.theme) urls.push( chartsBaseUrl + 'themes/' + chartConfig.theme + '.js');
            } else {
                if (chartConfig.type == 'map') {
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

                    if (typeof AmCharts[chartConfig.type] == 'undefined') urls.push( chartsBaseUrl + chartConfig.type + '.js');
                }

                if (chartConfig.theme && typeof AmCharts.themes[chartConfig.theme] == 'undefined') urls.push( chartsBaseUrl + 'themes/' + chartConfig.theme + '.js');
            }

            if (urls.length) {
                var me = this;

                Ext.Loader.loadScripts({
                    url: urls,
                    cache: true,
                    onLoad: function () {
                        AmCharts.AmChart.prototype.brr = function () {};

                        me.chartsLoaded = true;

                        me._onReady();
                    }
                });
            } else {
                this.chartsLoaded = true;

                this._onReady();
            }
JS

        setData => func ['data'], <<'JS',
            this._onReady();

            this.chart.dataProvider = data;

            this.chart.validateData();
JS

        _onReady => func [], <<'JS',
            if (!this.chartsLoaded) return;
            if (!this.rendered) return;

            if (!this.chart) {
                this.chart = AmCharts.makeChart(this.innerElement.dom, this.getChartConfig());

                this.chart.write(this.innerElement.dom);
            }

            if (this.getStore()) {
                var data = Ext.Array.pluck(this.getStore().data.items, 'data');

                var dataHandler = this.getDataHandler();

                if (dataHandler) {
                    this.chart.dataProvider = dataHandler.bind(this)(this.chart, data);
                }
                else {
                    this.chart.dataProvider = data;
                }

                this.chart.validateData();
            }
JS
    };
}

1;
__END__
=pod

=encoding utf8

=head1 NAME

Pcore::Ext::Lib::Modern::AmCharts3

=head1 SYNOPSIS

=head1 DESCRIPTION

=head1 ATTRIBUTES

=head1 METHODS

=head1 SEE ALSO

=cut
