package OpenGuides::Feed;

use strict;

use vars qw( $VERSION );
$VERSION = '0.03';

use Wiki::Toolkit::Feed::Atom;
use Wiki::Toolkit::Feed::RSS;
use Time::Piece;
use URI::Escape;
use Carp 'croak';

use base qw( Class::Accessor );
# Add more here if we need them - this one added for testing purposes.
my @variables = qw( html_equiv_link );
OpenGuides::Feed->mk_accessors( @variables );

sub new {
    my ($class, @args) = @_;
    my $self = {};
    bless $self, $class;
    $self->_init(@args);
}

sub _init {
    my ($self, %args) = @_;

    my $wiki = $args{wiki};

    unless ( $wiki && UNIVERSAL::isa( $wiki, "Wiki::Toolkit" ) ) {
       croak "No Wiki::Toolkit object supplied.";
    }
    $self->{wiki} = $wiki;

    my $config = $args{config};

    unless ( $config && UNIVERSAL::isa( $config, "OpenGuides::Config" ) ) {
        croak "No OpenGuides::Config object supplied.";
    }
    $self->{config} = $config;

    $self->{make_node_url} = sub {
        my ($node_name, $version) = @_;

        my $config = $self->{config};

        my $node_url = $config->script_url . uri_escape($config->script_name) . '?';
        $node_url .= 'id=' if defined $version;
        $node_url .= uri_escape($self->{wiki}->formatter->node_name_to_node_param($node_name));
        $node_url .= ';version=' . uri_escape($version) if defined $version;

        $node_url;
      };
    $self->{site_name}        = $config->site_name . " - Recent Changes";
    $self->{default_city}     = $config->default_city      || "";
    $self->{default_country}  = $config->default_country   || "";
    $self->{site_description} = $config->site_desc         || "";
    $self->{og_version}       = $args{og_version};
    $self->{html_equiv_link}  = $self->{config}->script_url
                                . $self->{config}->script_name . '?action=rc';

    $self;
}

=over 4

=item B<set_feed_name_and_url_params>
Overrides the default feed name and default feed http equivalent url.
Useful on custom feeds, where the defaults are incorrect.

   $feed->set_feed_name_and_url("Search Results", "search=pub");
   $feed->build_mini_feed_for_nodes("rss", @search_results);

=cut

sub set_feed_name_and_url_params {
    my ($self, $name, $url) = @_;

    unless($url =~ /^http/) {
        my $b_url = $self->{config}->script_url;
        unless($url =~ /\.cgi\?/) { $b_url .= "?"; }
        $b_url .= $url;
        $url = $b_url;
    }

    $self->{site_name} = $self->{config}->{site_name} . " - " . $name;
    $self->{html_equiv_link} = $url;
}

=item B<make_feed>

Produce one of the standard feeds, in the requested format.


my $feed_contents = feeds->make_feed(
                                feed_type => 'rss',
                                feed_listing => 'recent_changes'
                    );

Passes additional arguments through to the underlying Wiki::Toolkit::Feed

=cut

sub make_feed {
    my ($self, %args) = @_;

    my $feed_type = $args{feed_type};
    my $feed_listing = $args{feed_listing};

    my %known_listings = (
                          'recent_changes' => 1,
                          'node_all_versions' => 1,
                         );

    croak "No feed listing specified" unless $feed_listing;
    croak "Unknown feed listing: $feed_listing" unless $known_listings{$feed_listing};


    # Tweak any settings, as required by our feed listing
    if ($feed_listing eq 'node_all_versions') {
        $self->set_feed_name_and_url_params(
                    "All versions of ".$args{'name'},
                    "action=list_all_versions;id=".$args{'name'}
        );
    }


    # Fetch the right Wiki::Toolkit::Feeds::Listing instance to use
    my $maker = $self->fetch_maker($feed_type);


    # Call the appropriate feed listing from it
    if ($feed_listing eq 'recent_changes') {
        return $maker->recent_changes(%args);
    }
    elsif ($feed_listing eq 'node_all_versions') {
        return $maker->node_all_versions(%args);
    }
}

=item B<build_feed_for_nodes>

For the given feed type, build a feed from the supplied list of nodes.
Will figure out the feed timestamp from the newest node, and output a
 last modified header based on this.

my @nodes = $wiki->fetch_me_nodes_I_like();
my $feed_contents = $feed->build_feed_for_nodes("rss", @nodes);

=cut

sub build_feed_for_nodes {
    my ($self, $format, @nodes) = @_;
    return $self->render_feed_for_nodes($format, undef, 1, @nodes);
}

=item B<build_mini_feed_for_nodes>

For the given feed type, build a mini feed (name and distance) from the
 supplied list of nodes.
Will figure out the feed timestamp from the newest node, and output a
 last modified header based on this.

my @nodes = $wiki->search_near_here();
my $feed_contents = $feed->build_mini_feed_for_nodes("rss", @nodes);

=cut

sub build_mini_feed_for_nodes {
    my ($self, $format, @nodes) = @_;
    return $self->render_feed_for_nodes($format, undef, 0, @nodes);
}

=item B<render_feed_for_nodes>

Normally internal method to perform the appropriate building of a feed
based on a list of nodes.

=cut

sub render_feed_for_nodes {
    my ($self, $format, $html_url, $is_full, @nodes) = @_;

    # Grab our feed maker
    my $maker = $self->fetch_maker($format);

    # Find our newest node, so we can use that for the feed timestamp
    my $newest_node;
    foreach my $node (@nodes) {
        if($node->{last_modified}) {
            if((!$newest_node) || ($node->{last_modified} gt $newest_node->{last_modified})) {
                $newest_node = $node;
            }
        }
    }

    # Grab the timestamp, and do our header
    my $timestamp = $maker->feed_timestamp($newest_node);

    my $feed = "Last-Modified: ".$timestamp."\n\n";

    # Generate the feed itself
    if($is_full) {
        $feed .= $maker->generate_node_list_feed($timestamp, @nodes);
    } else {
        $feed .= $maker->generate_node_name_distance_feed($timestamp, @nodes);
    }

    return $feed;
}

=item B<default_content_type>

For the given feed type, return the default content type for that feed.

my $content_type = $feed->default_content_type("rss");

=cut

sub default_content_type {
    my ($self,$feed_type) = @_;

    my $content_type;

    if ($feed_type eq 'rss') {
        $content_type = "application/rdf+xml";
    }
    elsif ($feed_type eq 'atom') {
        $content_type = "application/atom+xml";
    }
    else {
        croak "Unknown feed type given: $feed_type";
    }

    return $content_type;
}

=item B<fetch_maker>

For the given feed type, identify and return the maker routine for feeds
of that type.

my $maker = $feed->fetch_maker("rss");
my $feed_contents = maker->node_all_versions(%options);

Will always return something of type Wiki::Toolkit::Feed::Listing

=cut

sub fetch_maker {
    my ($self,$feed_type) = @_;

    my %known_types = (
                          'atom'  => \&atom_maker,
                          'rss' => \&rss_maker,
                      );

    croak "No feed type specified" unless $feed_type;
    croak "Unknown feed type: $feed_type" unless $known_types{$feed_type};

    return &{$known_types{$feed_type}};
}

sub atom_maker {
    my $self = shift;

    unless ($self->{atom_maker}) {
        $self->{atom_maker} = Wiki::Toolkit::Feed::Atom->new(
            wiki                => $self->{wiki},
            site_name           => $self->{site_name},
            site_url            => $self->{config}->script_url,
            site_description    => $self->{site_description},
            make_node_url       => $self->{make_node_url},
            html_equiv_link     => $self->{html_equiv_link},
            atom_link           => $self->{html_equiv_link} . ";format=atom",
            software_name       => 'OpenGuides',
            software_homepage   => 'http://openguides.org/',
            software_version    => $self->{og_version},
            encoding            => $self->{config}->http_charset,
        );
    }

    $self->{atom_maker};
}

sub rss_maker {
    my $self = shift;

    unless ($self->{rss_maker}) {
        $self->{rss_maker} = Wiki::Toolkit::Feed::RSS->new(
            wiki                => $self->{wiki},
            site_name           => $self->{site_name},
            site_url            => $self->{config}->script_url,
            site_description    => $self->{site_description},
            make_node_url       => $self->{make_node_url},
            html_equiv_link     => $self->{html_equiv_link},
            software_name       => 'OpenGuides',
            software_homepage   => 'http://openguides.org/',
            software_version    => $self->{og_version},
            encoding            => $self->{config}->http_charset,
        );
    }

    $self->{rss_maker};
}

sub feed_timestamp {
    my ($self, %args) = @_;

    # Call the compatability timestamping method on the RSS Feed.
    # People should really just pass in also_return_timestamp to the
    #  feed method, and get the timestamp at the same time as their data
    $self->rss_maker->rss_timestamp(%args);
}

=back

=head1 NAME

OpenGuides::Feed - generate data feeds for OpenGuides in various formats.

=head1 DESCRIPTION

Produces RSS 1.0 and Atom 1.0 feeds for OpenGuides.  Distributed and
installed as part of the OpenGuides project, not intended for independent
installation.  This documentation is probably only useful to OpenGuides
developers.

=head1 SYNOPSIS

    use Wiki::Toolkit;
    use OpenGuides::Config;
    use OpenGuides::Feed;

    my $wiki = Wiki::Toolkit->new( ... );
    my $config = OpenGuides::Config->new( file => "wiki.conf" );
    my $feed = OpenGuides::Feed->new( wiki       => $wiki,
                                      config     => $config,
                                      og_version => '1.0', );

    # Ten most recent changes in RSS format.
    my %args = ( items     => 10,
                 feed_type => 'rss',
                 also_return_timestamp => 1 );
    my ($feed_output,$feed_timestamp) = $feed->make_feed( %args );

    print "Content-Type: application/rdf+xml\n";
    print "Last-Modified: " . $feed_timestamp . "\n\n";
    print $feed_output;

=head1 METHODS

=over 4

=item B<new>

    my $feed = OpenGuides::Feed->new( wiki       => $wiki,
                                      config     => $config,
                                      og_version => '1.0', );

C<wiki> must be a L<Wiki::Toolkit> object and C<config> must be an
L<OpenGuides::Config> object.  Both of these arguments are mandatory.
C<og_version> is an optional argument specifying the version of
OpenGuides for inclusion in the feed.

=item B<rss_maker>

Returns a raw L<Wiki::Toolkit::Feed::RSS> object created with the values you
invoked this module with.

=item B<atom_maker>

Returns a raw L<Wiki::Toolkit::Feed::Atom> object created with the values you
invoked this module with.

=item B<make_feed>

    # Ten most recent changes in RSS format.
    my %args = ( items     => 10,
                 feed_type => 'rss',
                 also_return_timestamp => 1 );
    my ($feed_output,$feed_timestamp) = $rdf_writer->make_feed( %args );

    print "Content-Type: application/rdf+xml\n";
    print "Last-Modified: " . $feed_timestamp . "\n\n";
    print $feed_output;
    print $rdf_writer->make_feed( %args );


    # All the changes made by bob in the past week, ignoring minor edits, in Atom.
    $args{days}               = 7;
    $args{ignore_minor_edits  = 1;
    $args{filter_on_metadata} => { username => "bob" };
    $args{also_return_timestamp} => 1;

    my ($feed_output,$feed_timestamp) = $rdf_writer->make_feed( %args );
    print "Content-Type: application/atom+xml\n";
    print "Last-Modified: " . $feed_timestamp . "\n\n";
    print $feed_output;

=item B<feed_timestamp>

Instead of calling this, you should instead pass in the 'also_return_timestamp'
option. You will then get back the feed timestamp, along with the feed output.

This method will be removed in future, and currently will only return
meaningful values if your arguments relate to recent changes.

    print "Last-Modified: " . $feed->feed_timestamp( %args ) . "\n\n";

Returns the timestamp of something in POSIX::strftime style ("Tue, 29 Feb 2000
12:34:56 GMT"). Takes the same arguments as make_recentchanges_rss().
You will most likely need this to print a Last-Modified HTTP header so
user-agents can determine whether they need to reload the feed or not.

=back

=head1 SEE ALSO

=over 4

=item * L<Wiki::Toolkit>, L<Wiki::Toolkit::Feed::RSS> and L<Wiki::Toolkit::Feed::Atom>

=item * L<http://openguides.org/>

=back

=head1 AUTHOR

The OpenGuides Project (openguides-dev@lists.openguides.org)

=head1 COPYRIGHT

Copyright (C) 2003-2012 The OpenGuides Project.  All Rights Reserved.

This module is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=head1 CREDITS

Written by Earle Martin, based on the original OpenGuides::RDF by Kake Pugh.

=cut

1;
