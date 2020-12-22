use strict;
use lib "lib";

eval {
    require Config::Tiny;
    # OpenGuides::Build and OpenGuides::Config both use Config::Tiny.
    require OpenGuides::Build;
    require OpenGuides::Config;
};

die "Problem loading OpenGuides module or a missing module\n\n$@.\n" if $@;

# Create the build object.
my $build = OpenGuides::Build->new(
    sign => 1,
    dist_name => "OpenGuides",
    dist_abstract => "A complete web application for managing a collaboratively-written guide to a city or town.",
    module_name => "OpenGuides",
    dist_version_from => "wiki.cgi",
    license => "perl",
    build_requires => {
        'Module::Build' => '0.26', # API change for accessing config data
        'Class::Accessor'                     => 0,
        'Config::Tiny'                        => 0,
        'Data::Dumper'                        => 0,
        'File::Path'                          => 0,
    },
    configure_requires => {
        'Config::Tiny'                        => 0,
        'Class::Accessor'                     => 0,
        'Module::Build' => '0.26', # API change for accessing config data
    },
    recommends => {
        'DBD::SQLite'                         => 0, # for testing
        'Test::HTML::Content'                 => 0, # for testing, oddly enough
        'Test::JSON'                  => 0, # for testing, oddly enough
        'Wiki::Toolkit::Plugin::Ping' => 0, # for pinging external services
        'Geo::HelmertTransform'  => 0,      # for correct WGS84 lat/long
        'Test::Pod'                           => 0,
    },
    meta_merge     => {
        resources => {
            MailingList => 'openguides-dev@lists.openguides.org',
            homepage => 'http://openguides.org',
            bugtracker => 'https://github.com/OpenGuides/OpenGuides/issues',
            repository  => 'git://github.com/OpenGuides/OpenGuides.git',
            x_IRC => 'irc://irc.perl.org/#openguides',
        }
    },
    dynamic_config => 1,
    create_makefile_pl => "passthrough"
);

my %args = $build->args;
my $force = exists $args{force};

unless ($force || $ENV{'AUTOMATED_TESTING'}) {
	print <<EOF;

Beginning install process... if you already have an OpenGuides
configuration file and you don't want to have to type in all your config
parameters over again, abort this process now, copy that file to this
directory, and start again.

EOF

my $continue = Module::Build->y_n("Continue with install?", "y");
exit 0 unless $continue;
}

my $existing_config_file = 'wiki.conf';
my $existing_config;

if (-f $existing_config_file) {
    $existing_config = OpenGuides::Config->new(file => $existing_config_file);
} else {
    print <<EOF;
No existing configuration file found; assuming this is a new install.
See the message above if this isn't correct.

EOF
    $existing_config = OpenGuides::Config->new();
}

my %yn_vars = map { $_ => 1 }
   qw(use_plucene enable_page_deletion navbar_on_home_page backlinks_in_title
      moderation_requires_password enable_node_image enable_common_categories
      enable_common_locales recent_changes_on_home_page use_leaflet
      random_page_omits_locales random_page_omits_categories use_lucy
      content_above_navbar_in_html show_gmap_in_node_display force_wgs84
      send_moderation_notifications read_only responsive);

my $skip_config = $force || $ENV{AUTOMATED_TESTING} ? 'y' : Module::Build->y_n("Skip OpenGuides configuration?", "n");
if ( $skip_config ) {
    print <<EOF;
===========================================================================
Skipping OpenGuides configuration - any configuration options previously
saved will be used instead.  You may tweak your configuration now by
editing the 'wiki.conf' file produced by this script.
===========================================================================
EOF
}

my @answers;

# It is an ancient Configurer, and he chooseth one of three.
my $dbtype;
my $dbtype_qu = $existing_config->dbtype__qu;
if ( $skip_config ) {
    $dbtype = $existing_config->dbtype;
} else {
    until ( $dbtype ) {
        my $def = $existing_config->dbtype;
        $dbtype = Module::Build->prompt("\n$dbtype_qu", $def);
        $dbtype = lc($dbtype);
        $dbtype =~ s/^\s*//;
        $dbtype =~ s/\s*$//;
        unless ( $dbtype eq "postgres" or $dbtype eq "mysql"
                 or $dbtype eq "sqlite" ) {
            undef $dbtype;
        }
    }
}

# Check they have the relevant DBD driver installed.
my %drivers = ( postgres => "DBD::Pg",
                mysql    => "DBD::mysql",
                sqlite   => "DBD::SQLite",
              );
eval "require $drivers{$dbtype}";
warn "$drivers{$dbtype} is needed to run a $dbtype database" if $@;

push @answers, { question => $dbtype_qu,
                 variable => "dbtype",
                 value    => $dbtype };

my $install_directory; # used to suggest template paths
my $use_plucene = 1; # keep track of this so we know what to put in prereqs
my $use_lucy = 0;
my $use_leaflet; # if true, we skip the GMaps questions
my %gmaps_vars = map { $_ => 1 } qw( gmaps_api_key centre_long centre_lat
                                default_gmaps_zoom default_gmaps_search_zoom );
my $centre_lat = ''; # contains centre lat derived from Google Maps URL
foreach my $var ( qw(
   dbname dbuser dbpass dbhost dbport script_name
   install_directory template_path custom_template_path script_url
   custom_lib_path use_lucy use_plucene indexing_directory
   search_content_munger_module enable_page_deletion
   admin_pass stylesheet_url site_name navbar_on_home_page
   recent_changes_on_home_page random_page_omits_locales
   random_page_omits_categories content_above_navbar_in_html home_name
   site_desc default_city default_country contact_email default_language
   formatting_rules_node backlinks_in_title use_leaflet gmaps_api_key
   centre_long centre_lat show_gmap_in_node_display default_gmaps_zoom
   default_gmaps_search_zoom force_wgs84 google_analytics_key
   licence_name licence_url licence_info_url moderation_requires_password
   enable_node_image enable_common_categories enable_common_locales
   spam_detector_module host_checker_module static_path static_url
   send_moderation_notifications read_only responsive custom_macro_module
   website_link_max_chars
  ) ) {
    my $q_method = $var . "__qu";
    my $qu  = $existing_config->$q_method;
    my $type = $yn_vars{$var} ? "y_n" : "";
    my $def = $existing_config->$var;
    my $val = $def;

    # Override dbname question for SQLite only.
    if ( $dbtype eq "sqlite" and $var eq "dbname" ) {
        $qu = "what's the full filename of the SQLite database this site runs on?";
    }

    if ( $dbtype eq "sqlite" and
         ( $var eq "dbuser" or $var eq "dbpass" or $var eq "dbhost" or
           $var eq "dbport")
       ) {
        print "$var not relevant for SQLite... skipping...\n"
            unless $skip_config;
        push @answers, { question => $qu,
                            variable => $var,
                         value    => "not-used" };
        next;
    }

    # Don't ask about Plucene if we've said to use Lucy.  If we haven't said
    # to use Lucy, ask about Plucene only for existing installs, since the old
    # Search::InvertedIndex method is deprecated.
    if ( $var eq "use_plucene" ) {
        if ( $use_lucy ) {
            print "Skipping question about Plucene - we're using Lucy.\n"
                unless $skip_config;
            push @answers, { question => $qu,
                             variable => $var,
                             value => 0 };
            next;
        } elsif ( $existing_config->$var == 1 ) {
            print "Skipping question about Plucene - we'll use it by "
                  . "default.\n"
                unless $skip_config;
            push @answers, { question => $qu,
                             variable => $var,
                             value => 1 };
            next;
        }
    }

    # If we're using Leaflet, we can skip the GMaps stuff.  Don't erase any
    # previous answers from their config file though.
    if ( $use_leaflet && $gmaps_vars{$var} ) {
        push @answers, { question => $qu,
                         variable => $var,
                         value => $val };
        next;
    }

    # Make sensible suggestions for template paths if we don't already
    # have them stored.  Not really a default, but a useful hint/shortcut.
    if ( $var eq "template_path" && !defined $existing_config->$var ) {
        $def = $install_directory;
        $def .= "/" unless $def =~ m|/$|;
        $def .= "templates";
    }
    if ( $var eq "custom_template_path" && !defined $existing_config->$var ) {
        $def = $install_directory;
        $def .= "/" unless $def =~ m|/$|;
        $def .= "custom-templates";
    }

    # If a Google Maps URL was provided last time we know the centre_lat
    if ( $var eq 'centre_lat' && $centre_lat ) {
        $val = $centre_lat;
        next;
    }

    # Here is where we actually ask the questions.
    unless ( $skip_config ) {
        if ( $type eq "y_n" ) {
            # may be stored as true/false integer value
            if ( $def =~ /^\d+$/ ) {
                $def = $def ? "y" : "n";
            }
            $val = Module::Build->y_n("\n$qu ", $def);
        } else {
            $val = Module::Build->prompt("\n$qu ", $def);
        }
    }

    # Allow user to use a Google Maps URL rather than enter lat/long by hand.
    # We assume centre_long is being asked for first; ensure so in big list above.
    if ( $var eq 'centre_long' ) {
        if ( $val =~ /ll=([-\d.]+),([-\d.]+)/ ) {
            print "Got a Google Maps URL with centre long,lat: [$1, $2]\n";
            $val = $1;
            $centre_lat = $2;
        }
    }

    # Store install_directory so we can use it to suggest template paths.
    $install_directory = $val if $var eq "install_directory";

    # Keep track of chosen search method so we know what to put in prereqs.
    # From Module::Build docs: ->y_n returns a Perl boolean true or false.
    $use_lucy = 1 if $var eq "use_lucy" and $val;
    $use_plucene = 1 if $var eq "use_plucene" and $val;

    # If they've just chosen to use Leaflet, we won't need to ask any of the
    # GMaps questions.
    $use_leaflet = 1 if $var eq "use_leaflet" and $val;

    # Make sure that script_url ends in a /
    if ( $var eq "script_url" and $val !~ /\/$/ ) {
        $val .= "/";
    }

    push @answers, { question => $qu,
                     variable => $var,
                     value    => $val };
}

# Now deal with the geo stuff.
my $geo_handler;
my $geo_handler_qu = "Distance calculation methods available are:"
                   . "\n  1) British National Grid"
                   . "\n  2) Irish National Grid"
                   . "\n  3) UTM ellipsoid"
                   . "\nWhich would you like to use?";

if ( $skip_config ) {
    # We default to GB National Grid for historical reasons.
    $geo_handler = $existing_config->geo_handler;
} else {
    my $choice;
    until ( $choice ) {
        my $def = $existing_config->geo_handler;
        $choice = Module::Build->prompt("\n".$geo_handler_qu, $def);
        $choice =~ s/^\s*//;
        $choice =~ s/\s*$//;
        unless ( $choice eq "1" or $choice eq "2" or $choice eq "3" ) {
            undef $choice;
        }
    }
    $geo_handler = $choice;
}

$geo_handler_qu =~ s/\n//gs;
push @answers, {
                 question => $geo_handler_qu,
                 variable => "geo_handler",
                 value    => $geo_handler,
               };

if ( $geo_handler eq "3" ) {
    my $qu = $existing_config->ellipsoid__qu;
    my $ellipsoid;
    if ( $skip_config ) {
        $ellipsoid = $existing_config->ellipsoid;
    } else {
        my $def = $existing_config->ellipsoid;
        $ellipsoid = Module::Build->prompt("\n".$qu, $def);
        $ellipsoid =~ s/^\s*//;
        $ellipsoid =~ s/\s*$//;
    }
    push @answers, {
                     question => $qu,
                     variable => "ellipsoid",
                     value    => $ellipsoid,
                   };
}

# Create a user-friendly config file from answers to prompts.
open FILE, ">wiki.conf" or die "Can't open wiki.conf for writing: $!";
foreach my $ans (@answers) {
    print FILE "# $ans->{question}\n";
    print FILE "$ans->{variable} = $ans->{value}\n\n";
}
close FILE or die "Can't close wiki.conf: $!";

# We currently only support Plucene for new installs, but may support
# others in future
my $search_module = $use_plucene ? "Plucene" : "Search::InvertedIndex";

$build->requires({
    'Algorithm::Diff'                     => '0.13',  # for sdiff
    'CGI'                                 => '4.08',  # use multi_param
    'CGI::Carp'                           => 0,
    'CGI::Cookie'                         => 0,
    'Wiki::Toolkit'                       => '0.86',
    'Wiki::Toolkit::Feed::Atom'           => 0,
    'Wiki::Toolkit::Feed::RSS'            => 0,
    'Wiki::Toolkit::Formatter::UseMod'    => 0.25, # for escape_url_commas
    'Wiki::Toolkit::Plugin::Categoriser'  => 0,
    'Wiki::Toolkit::Plugin::Diff'         => 0,
    'Wiki::Toolkit::Plugin::JSON'         => '0.05',
    'Wiki::Toolkit::Plugin::Locator::Grid'=> 0,
    'Class::Accessor'                     => 0,
    'Config::Tiny'                        => 0,
    'Data::Dumper'                        => 0,
    $drivers{$dbtype}                     => 0,
    'File::Spec::Functions'               => 0,
    'File::Temp'                          => 0,
    'HTML::Entities'                      => 0,
    'JSON'                                => 0, # W::T::P::JSON uses anyway
    'LWP::Simple'                         => 0,
    'MIME::Lite'                          => 0,
    'Parse::RecDescent'                   => 0,
    $search_module                        => 0,
    'POSIX'                               => 0,
    'Template'                            => '2.24', # for .lower vmethod
    'Template::Plugin::JSON::Escape'      => 0,
    'Time::Piece'                         => 0,
    'URI::Escape'                         => 0,
    'XML::RSS'                            => 0,
    'Data::Validate::URI'                 => 0,
    'Net::Netmask'                        => 0,
    'List::Util'                          => 0,
    'Geo::Coordinates::UTM'               => 0,
    'Geo::Coordinates::OSGB'              => 0,
    'Geo::Coordinates::ITM'               => 0,
});

$build->add_to_cleanup( "t/indexes/" );
$build->add_to_cleanup( "t/node.db" );
$build->add_to_cleanup( "t/prefs.db" );
$build->add_to_cleanup( "t/templates/tmp/" );

# Tell OpenGuides::Build which additional scripts and templates to install.
$build->config_data( __extra_scripts =>
                      [ "wiki.conf", "preferences.cgi", "search.cgi",
                        "newpage.cgi" ] );
$build->config_data( __templates     => [
                      "admin_home.tt",
                      "admin_revert_user.tt",
                      "autocreate_content.tt",
                      "backlink_results.tt",
                      "banner.tt",
                      "blacklisted_host.tt",
                      "delete_confirm.tt",
                      "delete_done.tt",
                      "delete_password_wrong.tt",
                      "differences.tt",
                      "display_metadata.tt",
                      "json_index.tt",
                      "metadata.tt",
                      "edit_form.tt",
                      "edit_form_actions.tt",
                      "edit_form_preview.tt",
                      "error.tt",
                      "footer.tt",
                      "header.tt",
                      "home_node.tt",
                      "index_form.tt",
                      "map_index.tt",
                      "map_index_leaflet.tt",
                      "missing_metadata.tt",
                      "moderate_confirm.tt",
                      "moderate_password_wrong.tt",
                      "navbar.tt",
                      "navbar_categories.tt",
                      "navbar_locales.tt",
                      "navbar_help.tt",
                      "navbar_admin.tt",
                      "navbar_home_link.tt",
                      "navbar_options.tt",
                      "navbar_revision_info.tt",
                      "navbar_search.tt",
                      "navbar_this_page.tt",
                      "navbar_tools.tt",
                      "needing_moderation.tt",
                      "newpage.tt",
                      "node.tt",
                      "node_history.tt",
                      "node_image.tt",
                      "node_image_fields.tt",
                      "node_photo_notes.tt",
                      "node_location_search.tt",
                      "node_rdf.tt",
                      "openguides_information_boxes.tt",
                      "preferences.tt",
                      "random_page_failure.tt",
                      "rdf_index.tt",
                      "read_only.tt",
                      "recent_changes.tt",
                      "search_results.tt",
                      "search_results_leaflet.tt",
                      "site_index.tt",
                      "search.tt",
                      "spam_detected.tt",
                      "userstats.tt",
                      "wanted_pages.tt"
    ] );

$build->config_data( __static_files => [
        "map-leaflet.js",
        "openguides-base.css",
    ] );

# Finally write the build script.
$build->create_build_script;
