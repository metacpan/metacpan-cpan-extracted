{
    # pcore-api
    pcore_api => sub ( $cdn, $bucket, $native, $args ) {
        if (wantarray) {
            return $cdn->get_script_tag( $bucket->("static/pcore/api.js") );
        }
        else {
            return $bucket->("static/pcore");
        }
    },

    # FontAwesome
    fa5 => sub ( $cdn, $bucket, $native, $args ) {
        my $ver = version->parse( $args->{ver} // v5.5.0 );

        state $native_prefix = 'https://use.fontawesome.com/releases';

        if (wantarray) {
            return $cdn->get_css_tag( $native ? "$native_prefix/$ver/css/all.css" : $bucket->("static/fa/$ver/css/all.min.css") );
        }
        else {
            return $native ? "$native_prefix/$ver" : $bucket->("static/fa/$ver");
        }
    },

    # jQuery3
    jquery3 => sub ( $cdn, $bucket, $native, $args ) {
        my $ver = version->parse( $args->{ver} // v3.3.1 );

        state $native_prefix = 'https://ajax.googleapis.com/ajax/libs/jquery';

        if (wantarray) {
            $cdn->get_script_tag( $native ? "$native_prefix/@{[ substr $ver, 1 ]}/jquery.min.js" : $bucket->("static/jquery/$ver/jquery.min.js") );
        }
        else {
            return $native ? "$native_prefix/" . substr $ver, 1 : $bucket->("static/jquery/$ver");
        }
    },

    # tinycolor, https://github.com/bgrins/TinyColor
    tinycolor1 => sub ( $cdn, $bucket, $native, $args ) {
        my $ver = version->parse( $args->{ver} // v1.4.1 );

        if (wantarray) {
            return $cdn->get_script_tag( $bucket->("static/tinycolor/$ver/tinycolor.js") );
        }
        else {
            return $bucket->("static/tinycolor/$ver");
        }
    },

    # froala, https://www.froala.com/wysiwyg-editor
    froala2 => sub ( $cdn, $bucket, $native, $args ) {
        my $ver = version->parse( $args->{ver} // v2.9.1 );

        if (wantarray) {
            my @res;

            push @res, $cdn->get_css_tag( $bucket->("static/froala/$ver/css/froala_editor.pkgd.min.css") );
            push @res, $cdn->get_script_tag( $bucket->("static/froala/$ver/js/froala_editor.pkgd.min.js") );

            return @res;
        }
        else {
            return $bucket->("static/unitegallery/$ver");
        }
    },

    # unitegallery, https://unitegallery.net
    unitegallery1 => sub ( $cdn, $bucket, $native, $args ) {
        my $ver = version->parse( $args->{ver} // v1.7.45 );

        if (wantarray) {
            my @res;

            push @res, $cdn->get_css_tag( $bucket->("static/unitegallery/$ver/css/unite-gallery.css") );
            push @res, $cdn->get_script_tag( $bucket->("static/unitegallery/$ver/js/unitegallery.min.js") );

            # theme
            # push @res, $cdn->get_css_tag( $bucket->("static/unitegallery/$ver/themes/default/ug-theme-default.css") );
            # push @res, $cdn->get_script_tag( $bucket->("static/unitegallery/$ver/themes/default/ug-theme-default.js") );

            return @res;
        }
        else {
            return $bucket->("static/unitegallery/$ver");
        }
    },

    # amCharts4
    amcharts4 => sub ( $cdn, $bucket, $native, $args ) {
        my $ver = version->parse( $args->{ver} // v4.0.6 );

        state $native_prefix = 'https://www.amcharts.com/lib/4';

        if (wantarray) {
            my @res;

            push @res, $cdn->get_script_tag( $native ? "$native_prefix/core.js"   : $bucket->("static/amcharts/$ver/core.js") );
            push @res, $cdn->get_script_tag( $native ? "$native_prefix/charts.js" : $bucket->("static/amcharts/$ver/charts.js") ) if $args->{charts};
            push @res, $cdn->get_script_tag( $native ? "$native_prefix/maps.js"   : $bucket->("static/amcharts/$ver/maps.js") ) if $args->{maps};

            return @res;
        }
        else {
            return $native ? $native_prefix : $bucket->("static/amcharts/$ver");
        }
    },

    # amCharts4 geodata
    amcharts4_geodata => sub ( $cdn, $bucket, $native, $args ) {
        my $ver = version->parse( $args->{ver} // v4.0.20 );

        state $native_prefix = 'https://www.amcharts.com/lib/4/geodata';

        if (wantarray) {
            die q[Invalid usage of "amcharts4_geodata" resource];
        }
        else {
            return $native ? $native_prefix : $bucket->("static/amcharts-geodata/$ver");
        }
    },

    # ExtJS
    extjs6 => sub ( $cdn, $bucket, $native, $args ) {
        my $ver = version->parse( $args->{ver} // v6.6.0 );

        if (wantarray) {
            my @res;

            my $debug = $args->{devel} ? '-debug' : '';

            # framework
            if ( $args->{type} eq 'classic' ) {
                push @res, $cdn->get_script_tag( $bucket->("static/extjs/$ver/ext-all$debug.js") );
            }
            else {
                push @res, $cdn->get_script_tag( $bucket->("static/extjs/$ver/ext-modern-all$debug.js") );
            }

            # ux
            # push @res, $cdn->get_script_tag( $bucket->("/static/extjs/$ver/packages/ux/$framework/ux$debug.js") );

            # theme
            # TODO default theme
            $args->{theme} = $args->{default_theme} if 0;

            push @res, $cdn->get_css_tag( $bucket->("static/extjs/$ver/$args->{type}/theme-$args->{theme}/resources/theme-$args->{theme}-all$debug.css") );
            push @res, $cdn->get_script_tag( $bucket->("static/extjs/$ver/$args->{type}/theme-$args->{theme}/theme-$args->{theme}$debug.js") );

            # fashion, only for modern material theme
            push @res, $cdn->get_script_tag( $bucket->("static/extjs/$ver/css-vars.js") );

            return @res;
        }
        else {
            return $bucket->("static/extjs/$ver");
        }
    },
}
## -----SOURCE FILTER LOG BEGIN-----
##
## PerlCritic profile "pcore-config" policy violations:
## +------+----------------------+----------------------------------------------------------------------------------------------------------------+
## | Sev. | Lines                | Policy                                                                                                         |
## |======+======================+================================================================================================================|
## |    3 | 1                    | Modules::ProhibitExcessMainComplexity - Main code has high complexity score (34)                               |
## +------+----------------------+----------------------------------------------------------------------------------------------------------------+
##
## -----SOURCE FILTER LOG END-----
