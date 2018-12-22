package Pcore::Ext::Lib::Modern::AmCharts4;

use Pcore -l10n;

sub EXT_panel : Extend('Ext.Component') : Type('widget') {
    return {
        config => {
            store              => undef,
            useCharts          => \1,
            useMaps            => \0,
            chartTheme         => 'material',
            chartThemeAnimated => \0,
            chartConfig        => undef,
            chartInit          => undef,        # this.chartInit(chart)
            chartDataHandler   => undef,        # this.chartDataHandler(chart, data)
        },

        layout              => 'fit',
        defaultBindProperty => 'store',

        constructor => func ['config'], <<'JS',
            this.callParent(arguments);

            this._loadCharts();
JS

        afterRender => func <<'JS',
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

        _loadCharts => func <<"JS",
            var urls = [],
                chartTheme = this.getChartTheme(),
                chartThemeAnimated = this.getChartThemeAnimated(),
                chartsBaseUrl = "@{[ $cdn->get_resource_root('amcharts4') ]}",
                geoDataBaseUrl = "@{[ $cdn->get_resource_root('amcharts4_geodata') ]}";

            if (!window.am4core) urls.push( chartsBaseUrl + '/core.js');
            if (this.getUseCharts() && !window.am4charts) urls.push( chartsBaseUrl + '/charts.js');
            if (this.getUseMaps() && !window.am4maps) urls.push( chartsBaseUrl + '/maps.js');

            if (chartThemeAnimated && !window.am4themes_animated) urls.push( chartsBaseUrl + '/themes/animated.js');
            if (chartTheme && !window["am4themes_" + chartTheme]) urls.push( chartsBaseUrl + '/themes/' + chartTheme + '.js');

            if (urls.length) {
                var me = this;

                Ext.Loader.loadScripts({
                    url: urls,
                    cache: true,
                    onLoad: function () {
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

            if (!this.chart) return;

            this.chart.data = data;
JS

        _onReady => func <<'JS',
            if (!this.chartsLoaded) return;
            if (!this.rendered) return;

            if (!this.chart) {
                am4core.options.commercialLicense = true;

                var config = this.getChartConfig(),
                    chartTheme = this.getChartTheme(),
                    chartThemeAnimated = this.getChartThemeAnimated(),
                    chartInit = this.getChartInit();

                // apply themes
                am4core.unuseAllThemes();
                if (chartThemeAnimated) am4core.useTheme(am4themes_animated);
                if (chartTheme) am4core.useTheme(window["am4themes_" + chartTheme]);

                this.chart = am4core.createFromConfig(config, this.innerElement.dom);

                if (chartInit) chartInit.bind(this)(this.chart);
            }

            if (this.getStore()) {
                var data = Ext.Array.pluck(this.getStore().data.items, 'data');

                var chartDataHandler = this.getChartDataHandler();

                if (chartDataHandler) {
                    this.chart.data = chartDataHandler.bind(this)(this.chart, data);
                }
                else {
                    this.chart.data = data;
                }
            }
JS
    };
}

1;
__END__
=pod

=encoding utf8

=head1 NAME

Pcore::Ext::Lib::Modern::AmCharts4

=head1 SYNOPSIS

=head1 DESCRIPTION

=head1 ATTRIBUTES

=head1 METHODS

=head1 SEE ALSO

=cut
