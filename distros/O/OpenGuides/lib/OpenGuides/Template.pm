package OpenGuides::Template;

use strict;
use vars qw( $VERSION );
$VERSION = '0.22';

use Carp qw( croak );
use CGI; # want to get rid of this and put the burden on the templates
use OpenGuides; # for $VERSION for template variable
use OpenGuides::CGI;
use Template;
use URI::Escape;
use Data::Validate::URI qw( is_web_uri );

=head1 NAME

OpenGuides::Template - Do Template Toolkit related stuff for OpenGuides applications.

=head1 DESCRIPTION

Does all the Template Toolkit stuff for OpenGuides.  Distributed and
installed as part of the OpenGuides project, not intended for
independent installation.  This documentation is probably only useful
to OpenGuides developers.

=head1 SYNOPSIS

  use OpenGuides::Config;
  use OpenGuides::Utils;
  use OpenGuides::Template;

  my $config = OpenGuides::Config->new( file => "wiki.conf" );
  my $wiki = OpenGuides::Utils->make_wiki_object( config => $config );

  print OpenGuides::Template->output( wiki     => $wiki,
                                      config   => $config,
                                      template => "node.tt",
                                      vars     => { foo => "bar" }
  );

=head1 METHODS

=over 4

=item B<output>

  print OpenGuides::Template->output( wiki         => $wiki,
                                      config       => $config,
                                      template     => "node.tt",
                                      content_type => "text/html",
                                      cookies      => $cookie,
                                      vars         => {foo => "bar"},
                                      noheaders    => 1
  );

Returns everything you need to send to STDOUT, including the
Content-Type: header. Croaks unless C<template> is supplied.

The config object and variables supplied in C<vars> are passed through
to the template specified.  Additional Template Toolkit variables are
automatically set and passed through as well, as described below.
B<Note:> variables set in C<vars> will over-ride any variables of the
same name in the config object or the user cookies.

=over

=item * C<openguides_version>

=item * C<site_name>

=item * C<cgi_url>

=item * C<full_cgi_url>

=item * C<enable_page_deletion> (gets set to true or false - defaults to false)

=item * C<contact_email>

=item * C<stylesheet>

=item * C<home_link>

=item * C<formatting_rules_link> (unless C<omit_formatting_link> is set in user cookie)

=item * C<navbar_on_home_page>

=item * C<home_name>

=item * C<gmaps_api_key>

=item * C<licence_name>

=item * C<licence_url>

=item * C<licence_info_url>

=item * C<prefs> (the preferences from the user cookie)

=back

If C<node> is supplied:

=over

=item * C<node_name>

=item * C<node_param> (the node name escaped for use in URLs)

=back

Content-Type: defaults to C<text/html> and is omitted if the
C<content_type> arg is explicitly set to the blank string.

However, what you more often need is the C<noheaders> option,
which suppresses all HTTP headers, not just the Content-Type.

The HTTP response code may be explictly set with the C<http_status> arg.

=cut

sub output {
    my ($class, %args) = @_;
    croak "No template supplied" unless $args{template};
    my $config = $args{config} or croak "No config supplied";
    my $template_path = $config->template_path;
    my $custom_template_path = $config->custom_template_path || "";
    my $tt = Template->new(
               { INCLUDE_PATH => "$custom_template_path:$template_path" } );

    my $script_name  = $config->script_name;
    my $script_url   = $config->script_url;
    my $default_city = $config->default_city;

    # Check cookie to see if we need to set the formatting_rules_link.
    my ($formatting_rules_link, $omit_help_links);
    my $formatting_rules_node = $config->formatting_rules_node;
    $formatting_rules_link = $config->formatting_rules_link;
    my %cookie_data = OpenGuides::CGI->get_prefs_from_cookie(
                          config  => $config,
                          cookies => $args{cookies},
    );
    if ( $cookie_data{omit_help_links} ) {
        $omit_help_links = 1;
    } else {
        if (( $formatting_rules_node ) and !( $formatting_rules_link )){
            $formatting_rules_link = $script_url . $script_name . "?"
                                   . uri_escape($args{wiki}->formatter->node_name_to_node_param($formatting_rules_node));
        }
    }

    my $enable_page_deletion = 0;
    if ( $config->enable_page_deletion
         and ( lc($config->enable_page_deletion) eq "y"
               or $config->enable_page_deletion eq "1" )
       ) {
        $enable_page_deletion = 1;
    }
    my $is_admin = 0;
    if ( $cookie_data{is_admin} ) {
        $is_admin = 1;
    }

    my $tt_vars = {
        config                => $config,
        prefs                 => \%cookie_data,
        site_name             => $config->site_name,
        cgi_url               => $script_name,
        script_url            => $script_url,
        full_cgi_url          => $script_url . $script_name,
        contact_email         => $config->contact_email,
        stylesheet            => $config->stylesheet_url,
        home_link             => $script_url . $script_name,
        home_name             => $config->home_name,
        navbar_on_home_page   => $config->navbar_on_home_page,
        omit_help_links       => $omit_help_links,
        is_admin              => $is_admin,
        formatting_rules_link => $formatting_rules_link,
        formatting_rules_node => $formatting_rules_node,
        openguides_version    => $OpenGuides::VERSION,
        enable_page_deletion  => $enable_page_deletion,
        language              => $config->default_language,
        http_charset          => $config->http_charset,
        default_city          => $default_city,
        gmaps_api_key         => $config->gmaps_api_key,
        licence_name          => $config->licence_name,
        licence_url           => $config->licence_url,
        licence_info_url      => $config->licence_info_url,
        responsive            => $config->responsive,
    };

    if ($args{node}) {
        $tt_vars->{node_name} = CGI->escapeHTML($args{node});
        $tt_vars->{node_param} = OpenGuides::CGI->escape(
            $args{wiki}->formatter->node_name_to_node_param( $args{node} ) );
    }

    # Now set further TT variables if explicitly supplied - do this after the
    # above auto-setting as these override auto-set ones.
    $tt_vars = { %$tt_vars, %{ $args{vars} || {} } };

    # Finally, dig out the username from the cookie if we haven't already
    # been sent it in vars.
    if ( !$tt_vars->{username} ) {
        my %prefs = OpenGuides::CGI->get_prefs_from_cookie(config => $config);
        # If there's nothing in there, it defaults to "Anonymous".
        if ( $prefs{username} ne "Anonymous" ) {
          $tt_vars->{username} = $prefs{username};
        }
    }

    my $header = "";

    unless ( $args{noheaders} ) {
        my %cgi_header_args;

        if ( defined $args{content_type} and $args{content_type} eq "" ) {
            $cgi_header_args{'-type'} = '';
        } else {
            if ( $args{content_type} ) {
                $cgi_header_args{'-type'} = $args{content_type};
            } else {
                $cgi_header_args{'-type'} = "text/html";
            }
        }

        if ( $tt_vars->{http_charset} ) {
            $cgi_header_args{'-type'} .= "; charset=".$tt_vars->{http_charset};
        }
        $cgi_header_args{'-cookie'} = $args{cookies};

        if ( $args{http_status} ) {
            $cgi_header_args{'-status'} = $args{http_status};
        }

        $header = CGI::header( %cgi_header_args );
    }

    # vile hack
    my %field_vars = OpenGuides::Template->extract_metadata_vars(
                         wiki                 => $args{wiki},
                         config               => $config,
                         set_coord_field_vars => 1,
                         metadata => {},
                     );

    $tt_vars = { %field_vars, %$tt_vars };

    my $output;
    $tt->process( $args{template}, $tt_vars, \$output );

    my $contact_email = $config->contact_email;

    $output ||= qq(<html><head><title>ERROR</title></head><body><p>
    Sorry!  Something went wrong.  Please contact the site administrator
    at <a href="mailto:$contact_email">$contact_email</a> and quote the
    following error message:</p><blockquote>Failed to process template: )
        . $tt->error
        . qq(</blockquote></body></html>);

    return $header . $output;
}

=item B<extract_metadata_vars>

  my %node_data = $wiki->retrieve_node( "Home Page" );

  my %metadata_vars = OpenGuides::Template->extract_metadata_vars(
                          wiki     => $wiki,
                          config   => $config,
                          metadata => $node_data{metadata}
                      );

  # -- or --

  my %metadata_vars = OpenGuides::Template->extract_metadata_vars(
                          wiki     => $wiki,
                          config   => $config,
                          cgi_obj  => $q
                      );

  # -- then --

  print OpenGuides::Template->output(
            wiki     => $wiki,
            config   => $config,
            template => "node.tt",
            vars     => { foo => "bar",
                          %metadata_vars }
        );

Picks out things like categories, locales, phone number etc from
EITHER the metadata hash returned by L<Wiki::Toolkit> OR the query
parameters in a L<CGI> object, and packages them nicely for passing to
templates or storing in L<Wiki::Toolkit> datastore.  If you supply both
C<metadata> and C<cgi_obj> then C<metadata> will take precedence, but
don't do that.

The variables C<dist_field>, C<coord_field_1>, C<coord_field_1_name>,
C<coord_field_1_value>, C<coord_field_2>, C<coord_field_2_name>, and
C<coord_field_2_value>, which are used to create various forms, will
only be set if I<either> C<metadata> is supplied I<or>
C<set_coord_field_vars> is true, to prevent these values from being
stored in the database on a node commit.

=cut

sub extract_metadata_vars {
    my ($class, %args) = @_;
    my %metadata = %{$args{metadata} || {} };
    my $q = $args{cgi_obj};
    my $wiki = $args{wiki};
    my $formatter = $wiki->formatter;
    my $config = $args{config};
    my $script_name = $config->script_name;

    # Categories and locales are displayed as links in the page footer.
    # We return these twice, as eg 'category' being a simple array of
    # category names, but 'categories' being an array of hashrefs including
    # a URL too.  This is ick.
    my (@catlist, @loclist);
    if ( $args{metadata} ) {
        @catlist = sort @{ $metadata{category} || [] };
        @loclist = sort @{ $metadata{locale}   || [] };
    } else {
        my $categories_text = $q->param('categories');
        my $locales_text    = $q->param('locales');

        # Basic sanity-checking. Probably lives elsewhere.
        foreach ( $categories_text, $locales_text ) {
            s/</&lt;/g;
            s/>/&gt;/g;
            # Underscores aren't allowed in node names - change them to spaces.
            s/_+/ /g;
        }

        # Trim leading and trailing spaces, collapse internal whitespace.
        @catlist = sort grep { s/^\s+//; s/\s+$//; s/\s+/ /g; $_; }
                        split("\r\n", $categories_text);
        @loclist = sort grep { s/^\s+//; s/\s+$//; s/\s+/ /g; $_; }
                        split("\r\n", $locales_text);
    }

    # Some stuff here is copied from OpenGuides->_autoCreateCategoryLocale
    # - we should rationalise this.
    my @categories = map {
        my $param = $formatter->node_name_to_node_param( $_ );
        my $name = $_;
        $name =~ s/(.*)/\u$1/;
        $name = $wiki->formatter->_do_freeupper( "Category $name" );
        {
          name => $_,
          url  => $wiki->node_exists( $name )
                      ? "$script_name?Category_" . uri_escape( $param )
                      : "",
        };
    } @catlist;

    my @locales = map {
        my $param = $formatter->node_name_to_node_param( $_ );
        my $name = $_;
        $name =~ s/(.*)/\u$1/;
        $name = $wiki->formatter->_do_freeupper( "Locale $name" );
        {
          name => $_,
          url  => $wiki->node_exists( $name )
                      ? "$script_name?Locale_" . uri_escape( $param )
                      : "",
        };
    } @loclist;

    my $website = $args{metadata} ? $metadata{website}[0]
                                  : $q->param("website");
    # Do truncation for website name display.  Max length of field is set in
    # conf file (website_link_max_chars).  Leading http(s):// and www. are
    # stripped; trailing / is also stripped if it's the only / in the URL.
    my $formatted_website_text = "";
    if ( $website && $website ne "http://" && is_web_uri( $website ) ) {
        my $maxlen = $config->website_link_max_chars;
        my $trunc_website = $website;
        $trunc_website =~ s|https?://(www.)?||;
        if ( $trunc_website =~ tr|/|| == 1 ) {
            $trunc_website =~ s|/$||;
        }
        if ( length( $trunc_website ) > $maxlen ) {
            $trunc_website = substr( $trunc_website, 0, $maxlen - 3 ) . "...";
        }
        $formatted_website_text = '<a href="' . $website . '" class="external">'
                                  . $trunc_website . '</a>';
    }

    my $hours_text = $args{metadata} ? $metadata{opening_hours_text}[0]
                                    : $q->param("hours_text");

    my $summary = $args{metadata} ? $metadata{summary}[0]
                                  : $q->param("summary");

    my %vars = (
        categories             => \@categories,
        locales                => \@locales,
        category               => \@catlist,
        locale                 => \@loclist,
        formatted_website_text => $formatted_website_text,
        hours_text             => $hours_text,
        summary                => $summary,
    );

    if ($config->enable_node_image ) {
        foreach my $key ( qw( node_image node_image_licence node_image_url
                              node_image_copyright ) ) {
            my $value = $args{metadata} ? $metadata{$key}[0]
                                        : $q->param( $key );
            if ( $value ) {
                $value =~ s/^\s+//g;
                $value =~ s/\s+$//g;
            }
            $vars{$key} = $value if $value;
        }
    }

    if (exists $metadata{source}) {
        ($vars{source_site}) = $metadata{source}[0] =~ /^(.*?)(?:\?|$)/;
    }

    if ( $args{metadata} ) {
        foreach my $var ( qw( phone fax address postcode os_x os_y osie_x
                              osie_y latitude longitude map_link website
                              summary) ) {
            $vars{$var} = $metadata{$var}[0];
        }
        # Data for the distance search forms on the node display.
        my $geo_handler = $config->geo_handler;
        if ( $geo_handler == 1 ) {
            %vars = (
                        %vars,
                        coord_field_1       => "os_x",
                        coord_field_2       => "os_y",
                        dist_field          => "os_dist",
                        coord_field_1_name  => "OS X coordinate",
                        coord_field_2_name  => "OS Y coordinate",
                        coord_field_1_value => $metadata{os_x}[0],
                        coord_field_2_value => $metadata{os_y}[0],
                    );
        } elsif ( $geo_handler == 2 ) {
            %vars = (
                        %vars,
                        coord_field_1       => "osie_x",
                        coord_field_2       => "osie_y",
                        dist_field          => "osie_dist",
                        coord_field_1_name
                                       => "Irish National Grid X coordinate",
                        coord_field_2_name
                                       =>"Irish National Grid Y coordinate",
                        coord_field_1_value => $metadata{osie_x}[0],
                        coord_field_2_value => $metadata{osie_y}[0],
                    );
        } else {
            my $lat_text = "Latitude (" . $config->ellipsoid . " decimal)";
            my $long_text = "Longitude (" . $config->ellipsoid . " decimal)";
            %vars = (
                        %vars,
                        coord_field_1       => "latitude",
                        coord_field_2       => "longitude",
                        dist_field          => "latlong_dist",
                        coord_field_1_name  => $lat_text,
                        coord_field_2_name  => $long_text,
                        coord_field_1_value => $metadata{latitude}[0],
                        coord_field_2_value => $metadata{longitude}[0],
                    );
        }
    } else {
        foreach my $var ( qw( phone fax address postcode map_link website
                              summary) ) {
            $vars{$var} = $q->param($var);
        }

        # Trim leading and trailing whitespace from the fax field - some
        # guides use this to store the Twitter username, so whitespace will
        # mess things up when this is turned into a URL.
        $vars{fax} =~ s/^\s+//g;
        $vars{fax} =~ s/\s+$//g;

        my $geo_handler = $config->geo_handler;
        if ( $geo_handler == 1 ) {
            require Geo::Coordinates::OSGB;

            my $os_x   = $q->param("os_x");
            my $os_y   = $q->param("os_y");
            my $lat    = $q->param("latitude");
            my $long   = $q->param("longitude");

            # Trim whitespace - trailing whitespace buggers up the
            # integerification by postgres and it's an easy mistake to
            # make when typing into a form.
            $os_x =~ s/\s+//g;
            $os_y =~ s/\s+//g;

            # If we were sent x and y, work out lat/long; and vice versa.
            if ( defined $os_x && length $os_x
                   && defined $os_y && length $os_y ) {
                ( $lat, $long ) = Geo::Coordinates::OSGB::grid_to_ll(
                                      $os_x, $os_y );
                $lat  = sprintf( "%.6f", $lat );
                $long = sprintf( "%.6f", $long );
            } elsif ( defined $lat && length $lat
                        && defined $long && length $long ) {
                ( $os_x, $os_y ) = Geo::Coordinates::OSGB::ll_to_grid(
                                       $lat, $long );
                $os_x = sprintf( "%d", $os_x );
                $os_y = sprintf( "%d", $os_y );
            }

            if ( defined $os_x && length $os_x
                   && defined $os_y && length $os_y ) {
                %vars = (
                            %vars,
                            latitude  => $lat,
                            longitude => $long,
                            os_x      => $os_x,
                            os_y      => $os_y,
                        );
            }
            if ( $args{set_coord_field_vars} ) {
                %vars = (
                            %vars,
                            coord_field_1       => "os_x",
                            coord_field_2       => "os_y",
                            dist_field          => "os_dist",
                            coord_field_1_name  => "OS X coordinate",
                            coord_field_2_name  => "OS Y coordinate",
                            coord_field_1_value => $os_x,
                            coord_field_2_value => $os_y,
                        );
            }
        } elsif ( $geo_handler == 2 ) {
            require Geo::Coordinates::ITM;

            my $osie_x = $q->param("osie_x");
            my $osie_y = $q->param("osie_y");
            my $lat    = $q->param("latitude");
            my $long   = $q->param("longitude");

            # Trim whitespace.
            $osie_x =~ s/\s+//g;
            $osie_y =~ s/\s+//g;

            # If we were sent x and y, work out lat/long; and vice versa.
            if ( defined $osie_x && length $osie_x
                   && defined $osie_y && length $osie_y ) {
                ( $lat, $long ) = Geo::Coordinates::ITM::grid_to_ll(
                                      $osie_x, $osie_y );
                $lat  = sprintf( "%.6f", $lat );
                $long = sprintf( "%.6f", $long );
            } elsif ( defined $lat && length $lat && defined $long
                        && length $long ) {
                ( $osie_x, $osie_y ) = Geo::Coordinates::ITM::ll_to_grid(
                                           $lat, $long );
                $osie_x = sprintf( "%d", $osie_x );
                $osie_y = sprintf( "%d", $osie_y );
            }
            if ( defined $osie_x && length $osie_x
                   && defined $osie_y && length $osie_y ) {
                %vars = (
                            %vars,
                            latitude  => $lat,
                            longitude => $long,
                            osie_x    => $osie_x,
                            osie_y    => $osie_y,
                        );
            }
            if ( $args{set_coord_field_vars} ) {
                %vars = (
                            %vars,
                            coord_field_1       => "osie_x",
                            coord_field_2       => "osie_y",
                            dist_field          => "osie_dist",
                            coord_field_1_name
                                         => "Irish National Grid X coordinate",
                            coord_field_2_name
                                         => "Irish National Grid Y coordinate",
                            coord_field_1_value => $osie_x,
                            coord_field_2_value => $osie_y,
                        );
            }
        } elsif ( $geo_handler == 3 ) {
            require Geo::Coordinates::UTM;
            my $lat    = $q->param("latitude");
            my $long   = $q->param("longitude");

            if ( defined $lat && length $lat
                   && defined $long && length $long ) {
                # Trim whitespace.
                $lat =~ s/\s+//g;
                $long =~ s/\s+//g;
                my ($zone, $easting, $northing) =
                 Geo::Coordinates::UTM::latlon_to_utm( $config->ellipsoid,
                                                       $lat, $long );
                $easting  =~ s/\..*//; # chop off decimal places
                $northing =~ s/\..*//; # - metre accuracy enough
                %vars = (
                            %vars,
                            latitude  => $lat,
                            longitude => $long,
                            easting   => $easting,
                            northing  => $northing,
                        );
             }
             if ( $args{set_coord_field_vars} ) {
                %vars = (
                            %vars,
                            coord_field_1       => "latitude",
                            coord_field_2       => "longitude",
                            dist_field          => "latlong_dist",
                            coord_field_1_name  => "Latitude (decimal)",
                            coord_field_2_name  => "Longitude (decimal)",
                            coord_field_1_value => $lat,
                            coord_field_2_value => $long,
                        );
             }
        }
    }

    # Check whether we need to munge lat and long.
    # Store them unmunged as well so commit_node can get hold of them.
    my %prefs = OpenGuides::CGI->get_prefs_from_cookie( config => $config );
    if ( $prefs{latlong_traditional} ) {
        foreach my $var ( qw( latitude longitude ) ) {
            next unless defined $vars{$var} && length $vars{$var};
            $vars{$var."_unmunged"} = $vars{$var};
            $vars{$var} = _deg2string($vars{$var});
        }
    }

    return %vars;
}

# Slightly modified from the no-longer-available Geography::NationalGrid
# module, which was written by P Kent and distributed under the Artistic
# Licence.
sub _deg2string {
    my $degrees = shift;

    # make positive
    my $isneg = 0;
    if ($degrees < 0) {
        $isneg = 1;
        $degrees = abs( $degrees );
    } elsif ($degrees == 0) {
        return '0d 0m 0s';
    }

    my $d = int( $degrees );
    $degrees -= $d;
    $degrees *= 60;
    my $m = int( $degrees );
    $degrees -= $m;
    my $s = $degrees * 60;

    return sprintf("%s%dd %um %.2fs", ($isneg?'-':''), $d, $m, $s);
}

=back

=head1 AUTHOR

The OpenGuides Project (openguides-dev@lists.openguides.org)

=head1 COPYRIGHT

  Copyright (C) 2003-2013 The OpenGuides Project.  All Rights Reserved.

This module is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

1;
