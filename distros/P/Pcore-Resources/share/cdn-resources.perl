{
    # https://use.fontawesome.com/releases/v5.5.0/css/all.css
    fa => sub ( $cdn, $ver = 'v5.5.0' ) { [ $cdn->get_css_tag("/static/fa-$ver/css/all.min.css") ] },

    # https://ajax.googleapis.com/ajax/libs/jquery/3.3.1/jquery.min.js
    jquery3 => sub ( $cdn, $ver = 'v3.3.1' ) { [ $cdn->get_script_tag("/static/jquery-$ver.min.js") ] },

    united_gallery => sub ( $cdn, $ver = 'v1.7.45' ) { [    #
        $cdn->get_script_tag("/static/unitegallery-$ver/js/unitegallery.min.js"),
        $cdn->get_css_tag("/static/unitegallery-$ver/css/unite-gallery.css"),

        # theme
        # $cdn->get_script_tag("/static/unitegallery-$ver/themes/default/ug-theme-default.js"),
        # $cdn->get_css_tag("/static/unitegallery-$ver/themes/default/ug-theme-default.css"),
    ] },

    amcharts3_path => sub ( $cdn, $ver = 'v3.21.14' ) { $cdn->("/static/amcharts-$ver/") },    #
    ammap3_path    => sub ( $cdn, $ver = 'v3.21.14' ) { $cdn->("/static/ammap-$ver/") },

    # https://www.amcharts.com/lib/4/
    amcharts4_path => sub ( $cdn, $ver = 'v4.0.3' ) { $cdn->("/static/amcharts-$ver/") },      #

    # https://www.amcharts.com/lib/4/geodata/
    amcharts4_geodata_path => sub ( $cdn, $ver = 'v4.0.20' ) { $cdn->("/static/amcharts-geodata-$ver/") },

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
