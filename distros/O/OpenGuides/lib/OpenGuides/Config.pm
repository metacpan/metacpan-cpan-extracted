package OpenGuides::Config;
use strict;
use warnings;

use vars qw( $VERSION );
$VERSION = '0.11';

use Carp qw( croak );
use Config::Tiny;

use base qw( Class::Accessor );
my @variables = qw(
   dbtype dbname dbuser dbpass dbport dbhost dbencoding
   script_name install_directory script_url
   custom_lib_path use_plucene use_lucy search_content_munger_module
   indexing_directory enable_page_deletion
   admin_pass stylesheet_url site_name navbar_on_home_page
   recent_changes_on_home_page random_page_omits_locales
   random_page_omits_categories content_above_navbar_in_html home_name
   site_desc default_city default_country contact_email
   default_language http_charset ping_services
   formatting_rules_node formatting_rules_link backlinks_in_title template_path
   custom_template_path geo_handler ellipsoid gmaps_api_key centre_long
   show_gmap_in_node_display google_analytics_key use_leaflet
   centre_lat default_gmaps_zoom default_gmaps_search_zoom force_wgs84
   licence_name licence_url licence_info_url
   moderation_requires_password moderate_whitelist
   enable_node_image enable_common_categories enable_common_locales
   spam_detector_module host_checker_module custom_macro_module
   static_path static_url
   send_moderation_notifications website_link_max_chars read_only responsive
);
my @questions = map { $_ . "__qu" } @variables;
OpenGuides::Config->mk_accessors( @variables );
OpenGuides::Config->mk_accessors( @questions );

=head1 NAME

OpenGuides::Config - Handle OpenGuides configuration variables.

=head1 DESCRIPTION

Does config stuff for OpenGuides.  Distributed and installed as part of
the OpenGuides project, not intended for independent installation.
This documentation is probably only useful to OpenGuides developers.

=head1 METHODS

=over

=item B<new>

  my $config = OpenGuides::Config->new( file => "wiki.conf" );

Initialises itself from the config file specified and environment
variables of the form OPENGUIDES_CONFIG_READ_ONLY.  Variables which
are not set in that file, and which have sensible defaults, will be
initialised as described below in ACCESSORS; others will be given a
value of C<undef>.

  my $config = OpenGuides::Config->new( vars => { dbname => "foo" } );

As above but gets variables from a supplied hashref instead.

=cut

sub new {
    my $class = shift;
    my $self = { };
    bless $self, $class;
    return $self->_init( @_ );
}

sub _init {
    my ($self, %args) = @_;

    # Here are the defaults for the variable values.
    # Don't forget to add to INSTALL when changing these.
    my %defaults = (
                     dbtype => "sqlite",
                     script_name => "wiki.cgi",
                     install_directory => "/usr/lib/cgi-bin/openguides/",
                     use_plucene => 1,
                     use_lucy => 0,
                     search_content_munger_module => "",
                     indexing_directory => "/usr/lib/cgi-bin/openguides/indexes/",
                     enable_page_deletion => 0,
                     moderation_requires_password => 1,
                     moderate_whitelist => "",
                     admin_pass => "Change This!",
                     enable_node_image => 1,
                     enable_common_categories => 0,
                     enable_common_locales => 0,
                     ping_services => "",
                     site_name => "Unconfigured OpenGuides site",
                     navbar_on_home_page => 1,
                     recent_changes_on_home_page => 1,
                     random_page_omits_locales => 0,
                     random_page_omits_categories => 0,
                     content_above_navbar_in_html => 0,
                     home_name => "Home",
                     site_desc => "A default configuration of OpenGuides",
                     default_city => "",
                     default_country => "",
                     default_language => "en",
                     http_charset => "",
                     formatting_rules_node => "Text Formatting Examples",
                     formatting_rules_link => "http://openguides.org/text_formatting",
                     backlinks_in_title => 0,
                     geo_handler => 1,
                     ellipsoid => "WGS-84",
                     use_leaflet => 0,
                     show_gmap_in_node_display => 1,
                     centre_long => 0,
                     centre_lat => 0,
                     default_gmaps_zoom => 5,
                     default_gmaps_search_zoom => 3,
                     force_wgs84 => 0,
                     licence_name => "",
                     licence_url => "",
                     licence_info_url => "",
                     spam_detector_module => "",
                     host_checker_module => "",
                     custom_macro_module => "",
                     static_path => "/usr/local/share/openguides/static",
                     send_moderation_notifications => 1,
                     website_link_max_chars => 25,
                     read_only => 0,
                     responsive => 0,
                   );

    # See if we already have some config variables set.
    my %stored;
    if ( $args{file} ) {
        my $read_config = Config::Tiny->read( $args{file} ) or
            croak "Cannot read config file '$args{file}': $Config::Tiny::errstr";
        %stored = %{$read_config->{_}};
    } elsif ( $args{vars} ) {
        %stored = %{ $args{vars} };
    }

    # Set all defaults first, then set the stored values.  This allows us
    # to make sure that the stored values override the defaults yet be sure
    # to set any variables which have stored values but not defaults.
    foreach my $var ( keys %defaults ) {
        $self->$var( $defaults{$var} );
    }
    foreach my $var ( keys %stored ) {
        if ( $self->can( $var ) ) { # handle any garbage in file gracefully
            $self->$var( $stored{$var} );
	} else {
            warn "Don't know what to do with variable '$var'";
        }
    }
    # Override config from file or defaults if an environment variable
    # is set for a variable. e.g OPENGUIDES_CONFIG_read_only
    foreach my $var ( @variables ) {
       my $envvar = "OPENGUIDES_CONFIG_" . uc ( $var );
       if ( exists $ENV{$envvar} ) {
           $self->$var ( $ENV{$envvar} );
       }
    }
    # And the questions.
    # Don't forget to add to INSTALL when changing these.
    my %questions = (
        dbtype => "What type of database do you want the site to run on?  postgres/mysql/sqlite",
        dbname => "What's the name of the database that this site runs on?",
        dbuser => "...the database user that can access that database?",
        dbpass => "...the password that they use to access the database?",
        dbhost => "...the machine that the database is hosted on? (blank if local)",
        dbport => "...the port the database is listening on? (blank if default)",
        dbencoding => "...the encoding that your database uses? (blank if default)",
        script_name => "What do you want the script to be called?",
        install_directory => "What directory should I install it in?",
        template_path => "What directory should I install the templates in?",
        custom_template_path => "Where should I look for custom templates?",
        script_url => "What URL does the install directory map to?",
        custom_lib_path => "Do you want me to munge a custom lib path into the scripts?  If so, enter it here.  Separate path entries with whitespace.",
        use_plucene => "Do you want to use Plucene for searching? (recommended, but see Changes file before saying yes to this if you are upgrading)",
        use_lucy => "Do you want to use Lucy for searching? (experimental)",
        search_content_munger_module => "What module would you like to use to munge node content before indexing for the search? (optional, only works with Plucene and Lucy)",
        indexing_directory => "What directory can I use to store indexes in for searching? ***NOTE*** This directory must exist and be writeable by the user that your script will run as.  See README for more on this.",
        enable_page_deletion => "Do you want to enable page deletion?",
        moderation_requires_password => "Is the admin password required for moderating pages?",
        admin_pass => "Please specify a password for the site admin.",
        stylesheet_url => "What's the URL of the site's stylesheet?  If you don't enter one here, the basic OpenGuides stylesheet will be used instead.",
        enable_node_image => "Should nodes be allowed to have an externally hosted image?",
        enable_common_categories => "Do you want a common list of categories shown on all node pages?",
        enable_common_locales => "Do you want a common list of locales shown on all node pages?",
        ping_services => "Which services do you wish to ping whenever you write a page? Can be pingerati, geourl, or both",
        site_name => "What's the site called? (should be unique)",
        navbar_on_home_page => "Do you want the navigation bar included on the home page?",
        recent_changes_on_home_page => "Do you want the ten most recent changes included on the home page?",
        random_page_omits_locales => "Do you want the \"Random Page\" link to avoid returning a locale page?",
        random_page_omits_categories => "Do you want the \"Random Page\" link to avoid returning a category page?",
        content_above_navbar_in_html => "Do you want the content to appear above the navbar in the HTML?",
        home_name => "What should the home page of the wiki be called?",
        site_desc => "How would you describe the site?",
        default_city => "What city is the site based in?",
        default_country => "What country is the site based in?",
        contact_email => "Contact email address for the site administrator?",
        default_language => "What language will the site be in? (Please give an ISO language code.)",
        http_charset => "What character set should we put in the http headers? (This won't change the character set internally, just what it's reported as). Leave blank for none to be sent",
        formatting_rules_node => "What's the name of the node or page to use for the text formatting rules link (this is by default an external document, but if you make formatting_rules_link empty, it will be a wiki node instead",
        formatting_rules_link => "What URL do you want to use for the text formatting rules (leave blank to use a wiki node instead)?",
        backlinks_in_title => "Make node titles link to node backlinks (C2 style)?",
        ellipsoid => "Which ellipsoid do you want to use? (eg 'Airy', 'WGS-84')",
        use_leaflet => "Do you want to use the Leaflet mapping library? (this is recommended)",
        gmaps_api_key => "Do you have a Google Maps API key to use with this guide? If so, enter it here. (Note: our Google Maps support is deprecated, and we recommend you choose to use Leaflet instead.)",
        centre_long => "What is the longitude of the centre point of a map to draw for your guide? (This question can be ignored if you aren't using Google Maps - we recommend you use Leaflet instead, as our Leaflet code will figure this out for you.) You may paste in a Google Maps URL here (hint: copy URL from 'Link to this page')",
        centre_lat => "What is the latitude of the centre point of a map to draw for your guide? (This question can be ignored if you aren't using Google Maps - we recommend you use Leaflet instead, as our Leaflet code will figure this out for you.)",
        default_gmaps_zoom => "What default zoom level shall we use for Google Maps? (This question can be ignored if you aren't using Google Maps)",
        default_gmaps_search_zoom => "What default zoom level shall we use for Google Maps in the search results? (This question can be ignored if you aren't using Google Maps)",
        show_gmap_in_node_display => "Would you like to display a map on every node that has geodata?",
        force_wgs84 => "Forcibly treat stored lat/long data as if they used the WGS84 ellipsoid?",
        google_analytics_key => "Do you have a Google Analytics key to use with this guide? If you enter it here, then Google Analytics functionality will be automatically enabled.",
        licence_name => "What licence will you use for the guide?",
        licence_url => "What is the URL to your licence?",
        licence_info_url => "What is the URL to your local page about your licensing policy?",
        spam_detector_module => "What module would you like to use for spam detection? (optional)",
        host_checker_module => "What module would you like to use to run an IP blacklist? (optional)",
        custom_macro_module => "What module would you like to use to define custom macros? (optional)",
        static_path => "What directory should we install static content (CSS, images, javascript) to?",
        static_url => "What is the URL corresponding to the static content?",
        send_moderation_notifications => "Should we send email notifications when a moderated node is edited?",
        website_link_max_chars => "How many characters of the URL of node websites should be displayed?",
        moderate_whitelist => "Enter a comma-separated list of IP addresses able to make changes to moderated nodes and have them show up immediately",
        read_only => "Should the guide be read-only (no edits permitted)?",
        responsive => "Should the site be mobile-friendly (responsive)?",
    );

    foreach my $var ( keys %questions ) {
        my $method = $var . "__qu";
        $self->$method( $questions{$var} );
    }

    return $self;
}

=back

=head1 ACCESSORS

Each of the accessors described below is read-write.  Additionally,
for each of them, there is also a read-write accessor called, for
example, C<dbname__qu>.  This will contain an English-language
question suitable for asking for a value for that variable.  You
shouldn't write to them, but this is not enforced.

The defaults mentioned below are those which are applied when
C<< ->new >> is called, to variables which are not supplied in
the config file.

=over

=item * dbname

=item * dbuser

=item * dbpass

=item * dbhost

=item * dbport

=item * dbencoding

=item * script_name (default: C<wiki.cgi>)

=item * install_directory (default: C</usr/lib/cgi-bin/openguides/>)

=item * script_url (this is constrained to always end in C</>)

=cut

sub script_url {
    my $self = shift;
    # See perldoc Class::Accessor - can't just use SUPER.
    my $url = $self->_script_url_accessor( @_ );
    $url .= "/" unless (defined $url && $url =~ /\/$/);
    return $url;
}

=item * custom_lib_path

=item * use_plucene (default: true)

=item * use_lucy (default: false)

=item * search_content_munger_module

=item * indexing_directory (default: C</usr/lib/cgi-bin/openguides/indexes>)

=item * enable_page_deletion (default: false)

=item * admin_pass (default: C<Change This!>)

=item * stylesheet_url

=item * site_name (default: C<Unconfigured OpenGuides site>)

=item * navbar_on_home_page (default: true)

=item * recent_changes_on_home_page (default: true)

=item * random_page_omits_locales (default: false)

=item * random_page_omits_categories (default: false)

=item * content_above_navbar_in_html (default: false)

=item * home_name (default: C<Home>)

=item * site_desc (default: C<A default configuration of OpenGuides>)

=item * default_city (default: C<London>)

=item * default_country (default: C<United Kingdom>)

=item * default_language (default: C<en>)

=item * http_charset

=item * contact_email

=item * formatting_rules_node (default: C<Text Formatting Examples>)

=item * formatting_rules_link (default: C<http://openguides.org/text_formatting>

=item * backlinks_in_title (default: false)

=item * geo_handler (default: C<1>)

=item * ellipsoid (default: C<WGS-84>)

=item * use_leaflet

=item * gmaps_api_key

=item * centre_long

=item * centre_lat

=item * default_gmaps_zoom

=item * default_gmaps_search_zoom

=item * show_gmap_in_node_display

=item * force_wgs84

=item * google_analytics_key

=item * licence_name

=item * licence_url

=item * licence_info_url

=item * spam_detector_module

=item * host_checker_module

=item * custom_macro_module

=item * static_path

=item * static_url (this is constrained to always end in C</>)

=cut

sub static_url {
    my $self = shift;
    # See perldoc Class::Accessor - can't just use SUPER.
    my $url = $self->_static_url_accessor( @_ );
    $url .= "/" unless (defined $url && $url =~ /\/$/);
    return $url;
}

=item * send_moderation_notifications

=item * moderate_whitelist

=item * website_link_max_chars (default: C<25>)

=item * read_only

=item * responsive

=back

=head1 AUTHOR

The OpenGuides Project (openguides-dev@lists.openguides.org)

=head1 COPYRIGHT

     Copyright (C) 2004-2020 The OpenGuides Project.  All Rights Reserved.

The OpenGuides distribution is free software; you can redistribute it
and/or modify it under the same terms as Perl itself.

=head1 SEE ALSO

L<OpenGuides>

=cut

1;
