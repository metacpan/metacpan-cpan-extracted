package Pcore::Ext::Lib::AmCharts4;

use Pcore -l10n;

sub EXT_panel : Extend('Ext.Component') : Type('widget') {
    return {
        config => {
            store => undef,    # bindable

            useCharts => \1,
            useMaps   => \0,

            chartTheme      => 'material',
            chartDarkMode   => undef,            # bindable
            chartLightTheme => 'dataviz',
            chartDarkTheme  => 'amchartsdark',

            chartThemeAnimated => \1,
            chartConfig        => undef,

            onChartInit      => undef,           # onChartInit(view)
            chartInitialized => undef,

            onChartCreate    => undef,           # onChartCreate(view, chart)
            chartDataHandler => undef,           # chartDataHandler(view, chart, data)

            scope => undef,
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
                dataChanged: this._onReady,
            };
JS

        _loadCharts => func <<"JS",
            var urls = [],
                chartTheme = this.getChartTheme(),
                chartLightTheme = this.getChartLightTheme(),
                chartDarkTheme = this.getChartDarkTheme(),
                chartThemeAnimated = this.getChartThemeAnimated(),
                chartsBaseUrl = "@{[ $cdn->get_resource_root('amcharts4') ]}",
                geoDataBaseUrl = "@{[ $cdn->get_resource_root('amcharts4_geodata') ]}";

            if (!window.am4core) urls.push( chartsBaseUrl + '/core.js');
            if (this.getUseCharts() && !window.am4charts) urls.push( chartsBaseUrl + '/charts.js');
            if (this.getUseMaps() && !window.am4maps) urls.push( chartsBaseUrl + '/maps.js');

            if (chartThemeAnimated && !window.am4themes_animated) urls.push( chartsBaseUrl + '/themes/animated.js');
            if (chartTheme && !window["am4themes_" + chartTheme]) urls.push( chartsBaseUrl + '/themes/' + chartTheme + '.js');
            if (chartLightTheme && !window["am4themes_" + chartLightTheme]) urls.push( chartsBaseUrl + '/themes/' + chartLightTheme + '.js');
            if (chartDarkTheme && !window["am4themes_" + chartDarkTheme]) urls.push( chartsBaseUrl + '/themes/' + chartDarkTheme + '.js');

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

        updateChartTheme => func [ 'newTheme', 'oldTheme' ], <<'JS',
            if (!this.chart) return;

            this.chart.dispose();

            this.chart = null;

            this._loadCharts();
JS

        updateChartDarkMode => func [ 'newVal', 'oldVal' ], <<'JS',
            this.setChartTheme(newVal ? this.getChartDarkTheme() : this.getChartLightTheme());
JS

        _onReady => func <<'JS',
            if (!this.chartsLoaded) return;
            if (!this.rendered) return;

            if (!this.chart) {
                am4core.options.commercialLicense = true;

                var onChartInit = this.getOnChartInit();

                if (onChartInit && !this.getChartInitialized()) {
                    this.setChartInitialized(1);

                    Ext.callback(onChartInit, this.getScope(), [this], 0, this);
                }

                var config = this.getChartConfig(),
                    chartTheme = this.getChartTheme(),
                    chartThemeAnimated = this.getChartThemeAnimated(),
                    onChartCreate = this.getOnChartCreate();



                // apply themes
                am4core.unuseAllThemes();
                if (chartThemeAnimated) am4core.useTheme(am4themes_animated);
                if (chartTheme) am4core.useTheme(window["am4themes_" + chartTheme]);

                this.chart = am4core.createFromConfig(JSON.parse(JSON.stringify(config)), this.innerElement.dom);

                if (onChartCreate) {
                    Ext.callback(onChartCreate, this.getScope(), [this, this.chart], 0, this);
                }
            }

            if (this.getStore()) {
                let data = Ext.Array.pluck(this.getStore().data.items, 'data');

                let chartDataHandler = this.getChartDataHandler();

                if (chartDataHandler) {
                    this.chart.data = Ext.callback(chartDataHandler, this.getScope(), [this, this.chart, data], 0, this);
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

Pcore::Ext::Lib::AmCharts4

=head1 SYNOPSIS

=head1 DESCRIPTION

=head1 ATTRIBUTES

=head1 METHODS

=head1 SEE ALSO

=cut
