package OpenGuides::CGI;
use strict;
use vars qw( $VERSION );
$VERSION = '0.13';

use Carp qw( croak );
use CGI;
use CGI::Cookie;

=head1 NAME

OpenGuides::CGI - An OpenGuides helper for CGI-related things.

=head1 DESCRIPTION

Does CGI stuff for OpenGuides.  Distributed and installed as part of
the OpenGuides project, not intended for independent installation.
This documentation is probably only useful to OpenGuides developers.

=head1 SYNOPSIS

Saving preferences in a cookie:

  use OpenGuides::CGI;
  use OpenGuides::Config;
  use OpenGuides::Template;
  use OpenGuides::Utils;

  my $config = OpenGuides::Config->new( file => "wiki.conf" );

  my $cookie = OpenGuides::CGI->make_prefs_cookie(
      config                     => $config,
      username                   => "Kake",
      include_geocache_link      => 1,
      preview_above_edit_box     => 1,
      latlong_traditional        => 1,
      omit_help_links            => 1,
      show_minor_edits_in_rc     => 1,
      default_edit_type          => "tidying",
      cookie_expires             => "never",
      track_recent_changes_views => 1,
      display_google_maps        => 1,
      is_admin                   => 1
  );

  my $wiki = OpenGuides::Utils->make_wiki_object( config => $config );
  print OpenGuides::Template->output( wiki     => $wiki,
                                      config   => $config,
                                      template => "preferences.tt",
                                      cookies  => $cookie
  );

  # and to retrive prefs later:
  my %prefs = OpenGuides::CGI->get_prefs_from_cookie(
      config => $config
  );

Tracking visits to Recent Changes:

  use OpenGuides::CGI;
  use OpenGuides::Config;
  use OpenGuides::Template;
  use OpenGuides::Utils;

  my $config = OpenGuides::Config->new( file => "wiki.conf" );

  my $cookie = OpenGuides::CGI->make_recent_changes_cookie(
      config => $config,
  );

=head1 METHODS

=over 4

=item B<extract_node_param>

    my $config_file = $ENV{OPENGUIDES_CONFIG_FILE} || "wiki.conf";
    my $config = OpenGuides::Config->new( file => $config_file );
    my $guide = OpenGuides->new( config => $config );
    my $wiki = $guide->wiki;

    my $q = CGI->new;

    my $node_param = OpenGuides::CGI->extract_node_param(
                        wiki => $wiki, cgi_obj => $q );

Returns the title, id, or keywords parameter from the URL.  Normally
this will be something like "British_Museum", i.e. with underscores
instead of spaces.  However if the URL does contain spaces (encoded as
%20 or +), the return value will be e.g. "British Museum" instead.

Croaks unless a L<Wiki::Toolkit> object is supplied as C<wiki> and a
L<CGI> object is supplied as C<cgi_obj>.

=cut

sub extract_node_param {
    my ($class, %args) = @_;
    my $wiki = $args{wiki} or croak "No wiki supplied";
    croak "wiki not a Wiki::Toolkit object"
        unless UNIVERSAL::isa( $wiki, "Wiki::Toolkit" );
    my $q = $args{cgi_obj} or croak "No cgi_obj supplied";
    croak "cgi_obj not a CGI object"
        unless UNIVERSAL::isa( $q, "CGI" );

    # Note $q->param( "keywords" ) gives you the entire param string.
    # We need this to do URLs like foo.com/wiki.cgi?This_Page
    my $param = $q->param( "id" )
                || $q->param( "title" )
                || join( " ", $q->multi_param( "keywords" ) )
                || "";
    $param =~ s/%20/ /g;
    $param =~ s/\+/ /g;
    return $param;
}

=item B<extract_node_name>

    my $config_file = $ENV{OPENGUIDES_CONFIG_FILE} || "wiki.conf";
    my $config = OpenGuides::Config->new( file => $config_file );
    my $guide = OpenGuides->new( config => $config );
    my $wiki = $guide->wiki;

    my $q = CGI->new;

    my $node_name = OpenGuides::CGI->extract_node_name(
                        wiki => $wiki, cgi_obj => $q );

Returns the name of the node the user wishes to display/manipulate, as
we expect it to be stored in the database.  Normally this will be
something like "British Museum", i.e. with spaces in.  Croaks unless a
L<Wiki::Toolkit> object is supplied as C<wiki> and a L<CGI> object is
supplied as C<cgi_obj>.

=cut

sub extract_node_name {
    my ($class, %args) = @_;
    # The next call will validate our args for us and croak if necessary.
    my $param = $class->extract_node_param( %args );

    # Sometimes people type spaces instead of underscores.
    $param =~ s/ /_/g;
    $param =~ s/%20/_/g;
    $param =~ s/\+/_/g;

    my $formatter = $args{wiki}->formatter;
    return $formatter->node_param_to_node_name( $param );
}

=item B<check_spaces_redirect>

    my $config_file = $ENV{OPENGUIDES_CONFIG_FILE} || "wiki.conf";
    my $config = OpenGuides::Config->new( file => $config_file );
    my $guide = OpenGuides->new( config => $config );

    my $q = CGI->new;

    my $url = OpenGuides::CGI->check_spaces_redirect(
                                 wiki => $wiki, cgi_obj => $q );

If the user seems to have typed a URL with spaces in the node param
instead of underscores, this method will return the URL with the
underscores put in.  Otherwise, it returns false.

=cut

sub check_spaces_redirect {
    my ($class, %args) = @_;
    my $wiki = $args{wiki};
    my $q = $args{cgi_obj};

    my $name = $class->extract_node_name( wiki => $wiki, cgi_obj => $q );
    my $param = $class->extract_node_param( wiki => $wiki, cgi_obj => $q );

    # If we can't figure out the name or param, it's safest to do nothing.
    if ( !$name || !$param ) {
        return 0;
    }

    # If the name has no spaces in, or the name and param differ, we're
    # probably OK.
    if ( ( $name !~ / / ) || ( $name ne $param ) ) {
        return 0;
    }

    # Make a new CGI object to manipulate, to avoid action-at-a-distance.
    my $new_q = CGI->new( $q );
    my $formatter = $wiki->formatter;
    my $real_param = $formatter->node_name_to_node_param( $name );

    if ( $q->param( "id" ) ) {
        $new_q->param( -name => "id", -value => $real_param );
    } elsif ( $q->param( "title" ) ) {
        $new_q->param( -name => "title", -value => $real_param );
    } else {
        # OK, we have the keywords case; the entire param string is the
        # node param.  So just delete all existing parameters and stick
        # the node param back in.
        $new_q->delete_all();
        $new_q->param( -name => "id", -value => $real_param );
    }

    my $url = $new_q->self_url;

    # Escaped commas are ugly.
    $url =~ s/%2C/,/g;
    return $url;
}

=item B<make_prefs_cookie>

  my $cookie = OpenGuides::CGI->make_prefs_cookie(
      config                     => $config,
      username                   => "Kake",
      include_geocache_link      => 1,
      preview_above_edit_box     => 1,
      latlong_traditional        => 1,
      omit_help_links            => 1,
      show_minor_edits_in_rc     => 1,
      default_edit_type          => "tidying",
      cookie_expires             => "never",
      track_recent_changes_views => 1,
      display_google_maps        => 1,
      is_admin                   => 1
  );

Croaks unless an L<OpenGuides::Config> object is supplied as C<config>.
Acceptable values for C<cookie_expires> are C<never>, C<month>,
C<year>; anything else will default to C<month>.

=cut

sub make_prefs_cookie {
    my ($class, %args) = @_;
    my $config = $args{config} or croak "No config object supplied";
    croak "Config object not an OpenGuides::Config"
        unless UNIVERSAL::isa( $config, "OpenGuides::Config" );
    my $cookie_name = $class->_get_cookie_name( config => $config );
    my $expires;
    if ( $args{cookie_expires} and $args{cookie_expires} eq "never" ) {
        # Gosh, a hack.  YES I AM ASHAMED OF MYSELF.
        # Putting no expiry date means cookie expires when browser closes.
        # Putting a date later than 2037 makes it wrap round, at least on Linux
        # I will only be 62 by the time I need to redo this hack, so I should
        # still be alive to fix it.
        $expires = "Thu, 31-Dec-2037 22:22:22 GMT";
    } elsif ( $args{cookie_expires} and $args{cookie_expires} eq "year" ) {
        $expires = "+1y";
    } else {
        $args{cookie_expires} = "month";
        $expires = "+1M";
    }
    # Supply 'default' values to stop CGI::Cookie complaining about
    # uninitialised values.  *Real* default should be applied before
    # calling this method.
    my $cookie = CGI::Cookie->new(
        -name  => $cookie_name,
	-value => { user       => $args{username} || "",
		    gclink     => $args{include_geocache_link} || 0,
                    prevab     => $args{preview_above_edit_box} || 0,
                    lltrad     => $args{latlong_traditional} || 0,
                    omithlplks => $args{omit_help_links} || 0,
                    rcmined    => $args{show_minor_edits_in_rc} || 0,
                    defedit    => $args{default_edit_type} || "normal",
                    exp        => $args{cookie_expires},
                    trackrc    => $args{track_recent_changes_views} || 0,
                    gmaps      => $args{display_google_maps} || 0,
                    admin      => $args{is_admin} || 0
                  },
        -expires => $expires,
    );
    return $cookie;
}

=item B<get_prefs_from_cookie>

  my %prefs = OpenGuides::CGI->get_prefs_from_cookie(
      config => $config,
      cookies => \@cookies
  );

Croaks unless an L<OpenGuides::Config> object is supplied as C<config>.
Returns default values for any parameter not specified in cookie.

If C<cookies> is provided, and includes a preferences cookie, this overrides
any preferences cookie submitted by the browser.

=cut

sub get_prefs_from_cookie {
    my ($class, %args) = @_;
    my $config = $args{config} or croak "No config object supplied";
    croak "Config object not an OpenGuides::Config"
        unless UNIVERSAL::isa( $config, "OpenGuides::Config" );
    my $cookie_name = $class->_get_cookie_name( config => $config );
    my %cookies;
    if ( my $cookies = $args{cookies} ) {
        if (ref $cookies ne 'ARRAY') {
            $cookies = [ $cookies ];
        }
        %cookies = map { $_->name => $_ } @{ $cookies };
    }
    if ( !$cookies{$cookie_name} ) {
        my %stored_cookies = CGI::Cookie->fetch;
        $cookies{$cookie_name} = $stored_cookies{$cookie_name};
    }
    my %data;
    if ( $cookies{$cookie_name} ) {
        %data = $cookies{$cookie_name}->value; # call ->value in list context
    }

    my %long_forms = (
                       user       => "username",
                       gclink     => "include_geocache_link",
                       prevab     => "preview_above_edit_box",
                       lltrad     => "latlong_traditional",
                       omithlplks => "omit_help_links",
                       rcmined    => "show_minor_edits_in_rc",
                       defedit    => "default_edit_type",
                       exp        => "cookie_expires",
                       trackrc    => "track_recent_changes_views",
                       gmaps      => "display_google_maps",
                       admin      => "is_admin",
                     );
    my %long_data = map { $long_forms{$_} => $data{$_} } keys %long_forms;

    return $class->get_prefs_from_hash( %long_data );
}

sub get_prefs_from_hash {
    my ($class, %data) = @_;
    my %defaults = (
                     username                   => "Anonymous",
                     include_geocache_link      => 0,
                     preview_above_edit_box     => 0,
                     latlong_traditional        => 0,
                     omit_help_links            => 0,
                     # This has been set to 1 to work around
                     # Wiki::Toolkit bug #41 - consider reverting this
                     # when that bug gets fixed
                     show_minor_edits_in_rc     => 1,
                     default_edit_type          => "normal",
                     cookie_expires             => "never",
                     track_recent_changes_views => 0,
                     display_google_maps        => 1,
                     is_admin                   => 0,
                   );
    my %return;
    foreach my $key ( keys %data ) {
        $return{$key} = defined $data{$key} ? $data{$key} : $defaults{$key};
    }

    return %return;
}


=item B<make_recent_changes_cookie>

  my $cookie = OpenGuides::CGI->make_recent_changes_cookie(
      config => $config,
  );

Makes a cookie that stores the time now as the time of the latest
visit to Recent Changes.  Or, if C<clear_cookie> is specified and
true, makes a cookie with an expiration date in the past:

  my $cookie = OpenGuides::CGI->make_recent_changes_cookie(
      config       => $config,
      clear_cookie => 1,
  );

=cut

sub make_recent_changes_cookie {
    my ($class, %args) = @_;
    my $config = $args{config} or croak "No config object supplied";
    croak "Config object not an OpenGuides::Config"
        unless UNIVERSAL::isa( $config, "OpenGuides::Config" );
    my $cookie_name = $class->_get_rc_cookie_name( config => $config );
    # See explanation of expiry date hack above in make_prefs_cookie.
    my $expires;
    if ( $args{clear_cookie} ) {
        $expires = "-1M";
    } else {
        $expires = "Thu, 31-Dec-2037 22:22:22 GMT";
    }
    my $cookie = CGI::Cookie->new(
        -name  => $cookie_name,
	-value => {
                    time => time,
                  },
        -expires => $expires,
    );
    return $cookie;
}


=item B<get_last_recent_changes_visit_from_cookie>

  my %prefs = OpenGuides::CGI->get_last_recent_changes_visit_from_cookie(
      config => $config
  );

Croaks unless an L<OpenGuides::Config> object is supplied as C<config>.
Returns the time (as seconds since epoch) of the user's last visit to
Recent Changes.

=cut

sub get_last_recent_changes_visit_from_cookie {
    my ($class, %args) = @_;
    my $config = $args{config} or croak "No config object supplied";
    croak "Config object not an OpenGuides::Config"
        unless UNIVERSAL::isa( $config, "OpenGuides::Config" );
    my %cookies = CGI::Cookie->fetch;
    my $cookie_name = $class->_get_rc_cookie_name( config => $config );
    my %data;
    if ( $cookies{$cookie_name} ) {
        %data = $cookies{$cookie_name}->value; # call ->value in list context
    }
    return $data{time};
}


sub _get_cookie_name {
    my ($class, %args) = @_;
    my $site_name = $args{config}->site_name
        or croak "No site name in config";
    return $site_name . "_userprefs";
}

sub _get_rc_cookie_name {
    my ($class, %args) = @_;
    my $site_name = $args{config}->site_name
        or croak "No site name in config";
    return $site_name . "_last_rc_visit";
}

=item B<make_index_form_dropdowns>

    my @dropdowns = OpenGuides::CGI->make_index_form_dropdowns (
        guide    => $guide,
        selected => [
                      { type => "category", value => "pubs" },
                      { type => "locale", value => "holborn" },
                    ],
    );
    %tt_vars = ( %tt_vars, dropdowns => \@dropdowns );

    # In the template
    [% FOREACH dropdown = dropdowns %]
      [% dropdown.type.ucfirst | html %]:
      [% dropdown.html %]
      <br />
    [% END %]

Makes HTML dropdown selects suitable for passing to an indexing template.

The C<selected> argument is optional; if supplied, it gives default values
for the dropdowns.  At least one category and one locale dropdown will be
returned; if no defaults are given for either then they'll default to
everything/everywhere.

=cut

sub make_index_form_dropdowns {
    my ( $class, %args ) = @_;
    my @selected = @{$args{selected} || [] };
    my $guide = $args{guide};
    my @dropdowns;
    my ( $got_cat, $got_loc );
    foreach my $criterion ( @selected ) {
        my $type = $criterion->{type} || "";
        my $value = $criterion->{value} || "";
        my $html;
        if ( $type eq "category" ) {
            $html = $class->_make_dropdown_html(
                        %$criterion, guide => $guide );
            $got_cat = 1;
        } elsif ( $type eq "locale" ) {
            $html = $class->_make_dropdown_html(
                        %$criterion, guide => $guide );
            $got_loc = 1;
        } else {
            warn "Unknown or missing criterion type: $type";
        }
        if ( $html ) {
            push @dropdowns, { type => $type, html => $html };
        }
    }
    if ( !$got_cat ) {
        push @dropdowns, { type => "category", html =>
            $class->_make_dropdown_html( type => "category", guide => $guide )
        };
    }
    if ( !$got_loc ) {
        push @dropdowns, { type => "locale", html =>
            $class->_make_dropdown_html( type => "locale", guide => $guide )
        };
    }
    # List the category dropdowns before the locale dropdowns, for consistency.
    @dropdowns = sort { $a->{type} cmp $b->{type} } @dropdowns;
    return @dropdowns;
}

sub _make_dropdown_html {
    my ( $class, %args ) = @_;
    my ( $field_name, $any_label );

    if ( $args{type} eq "locale" ) {
        $args{type} = "locales"; # hysterical raisins
        $any_label = " -- anywhere -- ";
        $field_name = "loc";
    } else {
        $any_label = " -- anything -- ";
        $field_name = "cat";
    }

    my @options = $args{guide}->wiki->list_nodes_by_metadata(
        metadata_type => "category",
        metadata_value => $args{type},
        ignore_case => 1,
    );
    @options = map { s/^Category //; s/^Locale //; $_ } @options;
    my %labels = map { lc( $_ ) => $_ } @options;
    my @values = sort keys %labels;
    my $default = lc( $args{value} || "");

    my $q = CGI->new( "" );
    return $q->popup_menu( -name => $field_name,
                           -class => "$args{type}_index",
                           -values => [ "", @values ],
                           -labels => { "" => $any_label, %labels },
                           -default => $default );
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

