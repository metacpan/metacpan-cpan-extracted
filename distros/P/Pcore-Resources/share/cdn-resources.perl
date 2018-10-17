{    #
    fa             => sub ( $cdn, $ver = 'v5.4.1' )  { [ $cdn->get_css_tag("/static/fa-$ver/css/all.min.css") ] },    #
    jquery3        => sub ( $cdn, $ver = 'v3.3.1' )  { [ $cdn->get_script_tag("/static/jquery-$ver.min.js") ] },
    united_gallery => sub ( $cdn, $ver = 'v1.7.45' ) { [                                                              #
        $cdn->get_script_tag("/static/unitegallery-$ver/js/unitegallery.min.js"),
        $cdn->get_css_tag("/static/unitegallery-$ver/css/unite-gallery.css"),

        # theme
        # $cdn->get_script_tag("/static/unitegallery-$ver/themes/default/ug-theme-default.js"),
        # $cdn->get_css_tag("/static/unitegallery-$ver/themes/default/ug-theme-default.css"),
    ] },

    amcharts3_base => sub ( $cdn, $ver = 'v3.21.14' ) { $cdn->("/static/amcharts-$ver/") },    #
    ammap3_base    => sub ( $cdn, $ver = 'v3.21.14' ) { $cdn->("/static/ammap-$ver/") },

    amcharts4_base         => sub ( $cdn, $ver = 'v4.0.0.b56' ) { $cdn->("/static/amcharts-$ver/") },           #
    amcharts4_geodata_base => sub ( $cdn, $ver = 'v4.0.13' )    { $cdn->("/static/amcharts-geodata-$ver/") },

    ext => sub ( $cdn, $ver, $type, $theme, $default_theme, $debug = undef ) {
        $ver ||= 'v6.6.0';

        $debug = $debug ? '-debug' : q[];

        my @resources;

        # framework
        if ( $type eq 'classic' ) {
            push @resources, $cdn->get_script_tag("/static/ext-$ver/ext-all$debug.js");
        }
        else {
            push @resources, $cdn->get_script_tag("/static/ext-$ver/ext-modern-all$debug.js");
        }

        # ux
        # push @resources, $cdn->get_script_tag("/static/ext-$ver/packages/ux/${framework}/ux${debug}.js");

        # theme
        # TODO default theme
        $theme = $default_theme if 0;

        push @resources, $cdn->get_css_tag("/static/ext-$ver/$type/theme-$theme/resources/theme-$theme-all$debug.css");
        push @resources, $cdn->get_script_tag("/static/ext-$ver/$type/theme-$theme/theme-${theme}$debug.js");

        # fashion, only for modern material theme
        push @resources, $cdn->get_script_tag("/static/ext-$ver/css-vars.js");

        return \@resources;
    },
}
