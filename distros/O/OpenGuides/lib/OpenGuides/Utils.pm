package OpenGuides::Utils;

use strict;
use vars qw( $VERSION );
$VERSION = '0.20';

use Carp qw( croak );
use Wiki::Toolkit;
use Wiki::Toolkit::Formatter::UseMod;
use URI::Escape;
use MIME::Lite;
use Net::Netmask;
use List::Util qw( first );
use Data::Validate::URI qw( is_web_uri );

=head1 NAME

OpenGuides::Utils - General utility methods for OpenGuides scripts.

=head1 DESCRIPTION

Provides general utility methods for OpenGuides scripts.  Distributed
and installed as part of the OpenGuides project, not intended for
independent installation.  This documentation is probably only useful
to OpenGuides developers.

=head1 SYNOPSIS

  use OpenGuide::Config;
  use OpenGuides::Utils;

  my $config = OpenGuides::Config->new( file => "wiki.conf" );
  my $wiki = OpenGuides::Utils->make_wiki_object( config => $config );

=head1 METHODS

=over 4

=item B<make_wiki_object>

  my $config = OpenGuides::Config->new( file => "wiki.conf" );
  my $wiki = OpenGuides::Utils->make_wiki_object( config => $config );

Croaks unless an C<OpenGuides::Config> object is supplied.  Returns a
C<Wiki::Toolkit> object made from the given config file on success,
croaks if any other error occurs.

The config file needs to define at least the following variables:

=over

=item *

dbtype - one of C<postgres>, C<mysql> and C<sqlite>

=item *

dbname

=item *

indexing_directory - for the L<Search::InvertedIndex>, L<Plucene>,
or C<Lucy> files to go in

=back

=cut

sub make_wiki_object {
    my ($class, %args) = @_;
    my $config = $args{config} or croak "No config param supplied";
    croak "config param isn't an OpenGuides::Config object"
	unless UNIVERSAL::isa( $config, "OpenGuides::Config" );

    # Require in the right database module.
    my $dbtype = $config->dbtype;

    my %wiki_toolkit_exts = (
                          postgres => "Pg",
		          mysql    => "MySQL",
                          sqlite   => "SQLite",
                        );

    my $wiki_toolkit_module = "Wiki::Toolkit::Store::" . $wiki_toolkit_exts{$dbtype};
    eval "require $wiki_toolkit_module";
    croak "Can't 'require' $wiki_toolkit_module.\n" if $@;

    # Make store.
    my $store = $wiki_toolkit_module->new(
        dbname  => $config->dbname,
        dbuser  => $config->dbuser,
        dbpass  => $config->dbpass,
        dbhost  => $config->dbhost,
        dbport  => $config->dbport,
        charset => $config->dbencoding,
    );

    # Make search.
    my $search;
    if ( $config->use_lucy ) {
        $search = $class->make_lucy_searcher( config => $config );
    } elsif ( $config->use_plucene
         && ( lc($config->use_plucene) eq "y"
              || $config->use_plucene == 1 )
       ) {
        require Wiki::Toolkit::Search::Plucene;
        my %plucene_args = ( path => $config->indexing_directory );
        my $munger = $config->search_content_munger_module;
        if ( $munger ) {
            eval {
                eval "require $munger";
                $plucene_args{content_munger} = sub {
                    my $content = shift;
                    return $munger->search_content_munger( $content );
                };
            };
        }
        $search = Wiki::Toolkit::Search::Plucene->new( %plucene_args );
    } else {
        require Wiki::Toolkit::Search::SII;
        require Search::InvertedIndex::DB::DB_File_SplitHash;
        my $indexdb = Search::InvertedIndex::DB::DB_File_SplitHash->new(
            -map_name  => $config->indexing_directory,
            -lock_mode => "EX"
        );
        $search = Wiki::Toolkit::Search::SII->new( indexdb => $indexdb );
    }

    # Make formatter.
    my $script_name = $config->script_name;
    my $search_url = $config->script_url . "search.cgi";

    my %macros = (
        '@SEARCHBOX' =>
            qq(<form action="$search_url" method="get"><input type="text" size="20" name="search"><input type="submit" name="Go" value="Search"></form>),
        qr/\@INDEX_LINK\s+\[\[(Category|Locale)\s+([^\]|]+)\|?([^\]]+)?\]\]/ =>
            sub {
                  # We may be being called by Wiki::Toolkit::Plugin::Diff,
                  # which doesn't know it has to pass us $wiki - and
                  # we don't use it anyway.
                  if ( UNIVERSAL::isa( $_[0], "Wiki::Toolkit" ) ) {
                      shift; # just throw it away
                  }
                  my $type = ( lc( $_[0] ) eq "category" ) ? "cat" : "loc";
                  my $link_title = $_[2] || "View all pages in $_[0] $_[1]";
                  return qq(<a href="$script_name?action=index;$type=) . uri_escape( lc( $_[1] ) ) . qq(">$link_title</a>);
                },
        qr/\@INDEX_LIST\s+\[\[(Category|Locale)\s+([^\]]+)]]/ =>
             sub {
                   my ($wiki, $type, $value) = @_;
                   return $class->do_index_list_macro(
                       wiki => $wiki, type => $type, value => $value,
                       include_prefix => 1 );
                 },
        qr/\@INDEX_LIST_NO_PREFIX\s+\[\[(Category|Locale)\s+([^\]]+)]]/ =>
             sub {
                   my ($wiki, $type, $value) = @_;
                   return $class->do_index_list_macro(
                       wiki => $wiki, type => $type, value => $value );
                 },
         qr/\@NODE_COUNT\s+\[\[(Category|Locale)\s+([^\]]+)]]/ =>
             sub {
                   my ($wiki, $type, $value) = @_;
                   return $class->do_node_count(
                       wiki => $wiki, type => $type, value => $value );
                 },
        qr/\@MAP_LINK\s+\[\[(Category|Locale)\s+([^\]|]+)\|?([^\]]+)?\]\]/ =>
                sub {
                      if ( UNIVERSAL::isa( $_[0], "Wiki::Toolkit" ) ) {
                          shift; # don't need $wiki
                      }

                      my $type = ( lc( $_[0] ) eq "category" ) ? "cat" : "loc";
                      my $link_title = $_[2]
                                       || "View map of pages in $_[0] $_[1]";
                      return qq(<a href="$script_name?action=index;format=map;$type=) . uri_escape( lc( $_[1] ) ) . qq(">$link_title</a>);
                },
        qr/\@RANDOM_PAGE_LINK(?:\s+\[\[(Category|Locale)\s+([^\]|]+)\|?([^\]]+)?\]\])?/ =>
                sub {
                      if ( UNIVERSAL::isa( $_[0], "Wiki::Toolkit" ) ) {
                          shift; # don't need $wiki
                      }
                      my ( $type, $value, $link_title ) = @_;
                      my $link = "$script_name?action=random";

                      if ( $type && $value ) {
                          $link .= ";" . lc( uri_escape( $type ) ) . "="
                                . lc( uri_escape( $value ) );
                          $link_title ||= "View a random page in $type $value";
                      } else {
                          $link_title ||= "View a random page on this guide";
                      }
                      return qq(<a href="$link">$link_title</a>);
                },
        qr/\@INCLUDE_NODE\s+\[\[([^\]|]+)\]\]/ =>
            sub {
                  my ($wiki, $node) = @_;
                  my %node_data = $wiki->retrieve_node( $node );
                  return $node_data{content};
                },
    );

    my $custom_macro_module = $config->custom_macro_module;
    if ( $custom_macro_module ) {
        eval {
            eval "require $custom_macro_module";
            %macros = $custom_macro_module->custom_macros(macros => \%macros);
        };
    }

    my $formatter = Wiki::Toolkit::Formatter::UseMod->new(
        extended_links      => 1,
        implicit_links      => 0,
        allowed_tags        => [qw(a p b strong i em pre small img table td
                                   tr th br hr ul li center blockquote kbd
                                   div code span strike sub sup font dl dt dd
                                  )],
        macros              => \%macros,
        pass_wiki_to_macros => 1,
        node_prefix         => "$script_name?",
        edit_prefix         => "$script_name?action=edit;id=",
        munge_urls          => 1,
        external_link_class => "external",
        escape_url_commas   => 0,
    );

    my %conf = ( store     => $store,
                 search    => $search,
                 formatter => $formatter );

    my $wiki = Wiki::Toolkit->new( %conf );
    return $wiki;
}

sub make_lucy_searcher {
    my ( $class, %args ) = @_;
    require Wiki::Toolkit::Search::Lucy;
    my $config = $args{config};
    my %lucy_args = (
             path => $config->indexing_directory,
             metadata_fields => [ qw( address category locale ) ],
             boost => { title => 10 }, # empirically determined (test t/306)
    );
    my $munger = $config->search_content_munger_module;
    if ( $munger ) {
        eval {
            eval "require $munger";
            $lucy_args{content_munger} = sub {
                my $content = shift;
                return $munger->search_content_munger( $content );
            };
        };
    }
    return Wiki::Toolkit::Search::Lucy->new( %lucy_args );
}

sub do_index_list_macro {
    my ( $class, %args ) = @_;
    my ( $wiki, $type, $value, $include_prefix )
        = @args{ qw( wiki type value include_prefix ) };

    # We may be being called by Wiki::Toolkit::Plugin::Diff,
    # which doesn't know it has to pass us $wiki
    if ( !UNIVERSAL::isa( $wiki, "Wiki::Toolkit" ) ) {
        if ( $args{include_prefix} ) {
            return "(unprocessed INDEX_LIST macro)";
        } else {
            return "(unprocessed INDEX_LIST_NO_PREFIX macro)";
        }
    }

    my @nodes = sort $wiki->list_nodes_by_metadata(
        metadata_type  => $type,
        metadata_value => $value,
        ignore_case    => 1,
    );
    unless ( scalar @nodes ) {
        return "\n* No pages currently in " . lc($type) . " $value\n";
    }
    my $return = "\n";
    foreach my $node ( @nodes ) {
        my $title = $node;
        $title =~ s/^(Category|Locale) // unless $args{include_prefix};
        $return .= "* "
                . $wiki->formatter->format_link( wiki => $wiki,
                                                 link => "$node|$title" )
                . "\n";
    }
    # URI::Escape escapes commas in URLs.  This is annoying.
    $return =~ s/%2C/,/gs;
    return $return;
}
sub do_node_count {
    my ( $class, %args ) = @_;
    my ( $wiki, $type, $value )
        = @args{ qw( wiki type value ) };

    # We may be being called by Wiki::Toolkit::Plugin::Diff,
    # which doesn't know it has to pass us $wiki
    if ( !UNIVERSAL::isa( $wiki, "Wiki::Toolkit" ) ) {
            return "(unprocessed NODE_COUNT macro)";
        }

    my $num_nodes = scalar $wiki->list_nodes_by_metadata(
        metadata_type  => $type,
        metadata_value => $value,
        ignore_case    => 1,
    );
    return $num_nodes;
}
=item B<get_wgs84_coords>

Returns coordinate data suitable for use with Google Maps (and other GIS
systems that assume WGS-84 data).

    my ($wgs84_long, $wgs84_lat) = OpenGuides::Utils->get_wgs84_coords(
                                        longitude => $longitude,
                                        latitude => $latitude,
                                        config => $config
                                   );

=cut

sub get_wgs84_coords {
    my ($self, %args) = @_;
    my ($longitude, $latitude, $config) = ($args{longitude}, $args{latitude},
                                           $args{config})
       or croak "No longitude supplied to get_wgs84_coords";
    croak "geo_handler not defined!" unless $config->geo_handler;

    if ($config->force_wgs84) {
        # Only as a rough approximation, good enough for large scale guides
        return ($longitude, $latitude);
    }

    # If we don't have a lat and long, return undef right away
    unless($args{longitude} || $args{latitude}) {
        return undef;
    }

    # Try to load a provider of Helmert Transforms
    my $helmert;
    # First up, try the MySociety Geo::HelmertTransform
    unless($helmert) {
        eval {
            require Geo::HelmertTransform;
            $helmert = sub($$$) {
                my ($datum,$oldlat,$oldlong) = @_;
                if ($datum eq 'Airy') {
                    $datum = 'Airy1830';
                }
                my $datum_helper = new Geo::HelmertTransform::Datum(Name=>$datum);
                my $wgs84_helper = new Geo::HelmertTransform::Datum(Name=>'WGS84');
                unless($datum_helper) {
                    croak("No convertion helper for datum '$datum'");
                    return undef;
                }

                my ($lat,$long,$h) =
                    Geo::HelmertTransform::convert_datum($datum_helper,$wgs84_helper,$oldlat,$oldlong,0);
                return ($long,$lat);
            };
        };
    }
    # Give up, return undef
    unless($helmert) {
       return undef;
    }


    if ($config->geo_handler == 1) {
        # Do conversion here
        return &$helmert('Airy1830',$latitude,$longitude);
    } elsif ($config->geo_handler == 2) {
        # Do conversion here
        return &$helmert('Airy1830Modified',$latitude,$longitude);
    } elsif ($config->geo_handler == 3) {
        if ($config->ellipsoid eq "WGS-84") {
            return ($longitude, $latitude);
        } else {
            # Do conversion here
            return &$helmert($config->ellipsoid,$latitude,$longitude);
        }
    } else {
        croak "Invalid geo_handler config option $config->geo_handler";
    }
}

=item B<get_wgs84_min_max>

Given a set of WGS84 coordinate data, returns the minimum, maximum,
and centre latitude and longitude.

    %data = OpenGuides::Utils->get_wgs84_min_max(
        nodes => [
                   { wgs84_lat => 51.1, wgs84_long => 1.1 },
                   { wgs84_lat => 51.2, wgs84_long => 1.2 },
                 ]
    );
    print "Top right-hand corner is $data{max_lat}, $data{max_long}";
    print "Centre point is $data{centre_lat}, $data{centre_long}";

The hashes in the C<nodes> argument can include other key/value pairs;
these will just be ignored.

Returns false if it can't find any valid geodata in the nodes.

=cut

sub get_wgs84_min_max {
    my ( $self, %args ) = @_;
    my @nodes = @{$args{nodes}};

    my @lats  = sort
                grep { defined $_ && /^[-.\d]+$/ }
                map { $_->{wgs84_lat} }
                @nodes;
    my @longs = sort
                grep { defined $_ && /^[-.\d]+$/ }
                map { $_->{wgs84_long} }
                @nodes;

    if ( !scalar @lats || !scalar @longs ) {
        return;
    }

    my %data = ( min_lat  => $lats[0],  max_lat  => $lats[$#lats],
                 min_long => $longs[0], max_long => $longs[$#longs] );
    $data{centre_lat} = ( $data{min_lat} + $data{max_lat} ) / 2;
    $data{centre_long} = ( $data{min_long} + $data{max_long} ) / 2;
    return %data;
}

=item B<get_index_page_description>

    $tt_vars{page_description} =
        OpenGuides::Utils->get_index_page_description(
            format => "map",
            criteria => [ type => "locale", value => "croydon" ],
    );

Returns a sentence that can be used as a summary of what's shown on an
index page.

=cut

sub get_index_page_description {
    my ( $class, %args ) = @_;
    my $desc = ( $args{format} eq "map" ) ? "Map" : "List";
    $desc .= " of all our pages";

    my ( @cats, @locs );
    foreach my $criterion ( @{$args{criteria}} ) {
        my ( $type, $name ) = ( $criterion->{type}, $criterion->{name} );
        if ( $type eq "category" ) {
            $name =~ s/Category //;
            push @cats, $name;
        } else {
            $name =~ s/Locale //;
            push @locs, $name;
        }
    }

    if ( scalar @cats ) {
        $desc .= " labelled with: " . join( ", ", @cats );
        if ( scalar @locs ) {
            $desc .= ", and";
        }
    }
    if ( scalar @locs ) {
        $desc .= " located in: " . join( ", ", @locs );
    }
    $desc .= ".";
    return $desc;
}

=item B<detect_redirect>

    $redir = OpenGuides::Utils->detect_redirect( content => "foo" );

Checks the content of a node to see if the node is a redirect to another
node.  If so, returns the name of the node that this one redirects to.  If
not, returns false.

(Also returns false if no content is provided.)

=cut

sub detect_redirect {
    my ( $self, %args ) = @_;
    return unless $args{content};

    if ( $args{content} =~ /^#REDIRECT\s+(.+?)\s*$/ ) {
        my $redirect = $1;

        # Strip off enclosing [[ ]] in case this is an extended link.
        $redirect =~ s/^\[\[//;
        $redirect =~ s/\]\]\s*$//;

        return $redirect;
    }
}

=item B<validate_edit>

    my $fails = OpenGuides::Utils->validate_edit(
        id       => $node,
        cgi_obj  => $q
    );

Checks supplied content for general validity. If anything is invalid,
returns an array ref of errors to report to the user.

=cut

sub validate_edit {
    my ( $self, %args ) = @_;
    my $q = $args{cgi_obj};
    my @fails;
    push @fails, "Content missing" unless $q;
    return \@fails if @fails;

    # Now do our real validation
    foreach my $var (qw(os_x os_y)) {
        if ($q->param($var) and $q->param($var) !~ /^-?\d+$/) {
            push @fails, "$var must be integer, was: " . $q->param($var);
        }
    }

    foreach my $var (qw(latitude longitude)) {
        if ($q->param($var) and $q->param($var) !~ /^-?\d+\.?(\d+)?$/) {
            push @fails, "$var must be numeric, was: " . $q->param($var);
        }
    }

    if ( $q->param('website') and $q->param('website') ne 'http://' ) {
        unless ( is_web_uri( scalar $q->param('website') ) ) {
            push @fails, $q->param('website') . ' is not a valid web URI';
        }
    }

    return \@fails;

};

=item B<parse_change_comment>

    my $change_comment = parse_change_comment($string, $base_url);

Given a base URL (for example, C<http://example.com/wiki.cgi?>), takes a string,
replaces C<[[page]]> and C<[[page|titled link]]> with

    <a href="http://example.com/wiki.cgi?page">page</a>

and

    <a href="http://example.com/wiki.cgi?page">titled link</a>

respectively, and returns it. This is a limited subset of wiki markup suitable for
use in page change comments.

=cut

sub parse_change_comment {
    my ($comment, $base_url) = @_;

    my @links = $comment =~ m{\[\[(.*?)\]\]}g;

    # It's not all that great having to reinvent the wheel in this way, but
    # Text::WikiFormat won't let you specify the subset of wiki notation that
    # you're interested in. C'est la vie.
    foreach (@links) {
        if (/(.*?)\|(.*)/) {
            my ($page, $title) = ($1, $2);
            $comment =~ s{\[\[$page\|$title\]\]}
                         {<a href="$base_url$page">$title</a>};
        } else {
            my $page = $_;
            $comment =~ s{\[\[$page\]\]}
                         {<a href="$base_url$page">$page</a>};
        }
    }

    return $comment;
}

=item B<send_email>

    eval { OpenGuides::Utils->send_email(
            config        => $config,
            subject       => "Subject",
            body          => "Test body",
            admin         => 1,
            nobcc         => 1,
            return_output => 1
    ) };

    if ($@) {
        print "Error mailing admin: $@\n";
    } else {
        print "Mailed admin\n";
    }

Send out email. If C<admin> is true, the email will be sent to the site
admin. If C<to> is defined, email will be sent to addresses in that
arrayref. If C<nobcc> is true, there will be no Bcc to the admin.

C<subject> and C<body> are mandatory arguments.

Debugging: if C<return_output> is true, the message will be returned as
a string instead of being sent by email.

=cut


sub send_email {
    my ( $self, %args ) = @_;
    my $config = $args{config} or die "config argument not supplied";
    my @to;
    @to = @{$args{to}} if $args{to};
    my @bcc;
    push @to, $config->contact_email if $args{admin};
    die "No recipients specified" unless $to[0];
    die "No subject specified" unless $args{subject};
    die "No body specified" unless $args{body};
    my $to_str = join ',', @to;
    push @bcc, $config->contact_email unless $args{nobcc};
    my $bcc_str = join ',', @bcc;
    my $msg = MIME::Lite->new(
        From    => $config->contact_email,
        To      => $to_str,
        Bcc     => $bcc_str,
        Subject => $args{subject},
        Data    => $args{body}
    );

    if ( $args{return_output} ) {
        return $msg->as_string;
    } else {
        $msg->send or die "Couldn't send mail!";
    }
}

=item B<in_moderate_whitelist>

 if (OpenGuides::Utils->in_moderate_whitelist( '127.0.0.1' )) {
     # skip moderation and apply new verson to published site
 }

Admins can supply a comma separated list of IP addresses or CIDR-notation
subnets indicating the hosts which can bypass enforced moderation. Any
values which cannot be parsed by C<NetAddr::IP> will be ignored.

=cut

sub in_moderate_whitelist {
    my ($self, $config, $ip) = @_;
    return undef if not defined $ip;

    # create NetAddr::IP object of the test IP
    my $addr = Net::Netmask->new2($ip) or return undef;

    # load the configured whitelist
    my @whitelist
        = split ',', $config->moderate_whitelist;

    # test each entry in the whitelist
    return eval{
        first { Net::Netmask->new2($_)->match($addr->base) } @whitelist
    };
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
