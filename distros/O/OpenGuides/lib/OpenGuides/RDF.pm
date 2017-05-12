package OpenGuides::RDF;

use strict;

use OpenGuides::Utils;

use vars qw( $VERSION );
$VERSION = '0.15';

use Time::Piece;
use URI::Escape;
use Carp 'croak';
use HTML::Entities qw( encode_entities_numeric );
use Template;

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
    $self->{site_name}        = $config->site_name;
    $self->{default_city}     = $config->default_city     || "";
    $self->{default_country}  = $config->default_country  || "";
    $self->{site_description} = $config->site_desc        || "";
    $self->{og_version}       = $args{og_version};

    $self;
}

sub emit_rdfxml {
    my ($self, %args) = @_;

    my $node_name = $args{node};
    my $config = $self->{config};
    my $wiki = $self->{wiki};
    my $formatter = $wiki->formatter;

    my %node_data = $wiki->retrieve_node( $node_name );
    my %metadata = %{ $node_data{metadata} };
    my %tt_vars = (
                    node_name  => $node_name,
                    version    => $node_data{version},
                    site_name  => $self->{site_name},
                    site_desc  => $self->{site_description},
                    og_version => $self->{og_version},
                    config     => $config,
                  );

    my %defaults = (
                     city => $self->{default_city},
                     country => $self->{default_country},
                   );

    foreach my $var ( qw( phone fax website opening_hours_text address
                          postcode city country latitude longitude
                          os_x os_y map_link summary node_image ) ) {
        my $val = $metadata{$var}[0] || $defaults{$var} || "";
        $tt_vars{$var} = $val;
    }

    my @cats = @{ $metadata{category} || [] };
    @cats = map { { name => $_ } } @cats;
    $tt_vars{categories} = \@cats;

    my @locs = @{ $metadata{locale} || [] };
    @locs = map {
                  {
                    name => $_,
                    id   => $formatter->node_name_to_node_param( $_ ),
                  }
                } @locs;
    $tt_vars{locales} = \@locs;

    # Check for geospatialness and define container object as appropriate.
    my $is_geospatial;
    foreach my $var ( qw( os_x os_y latitude longitude address postcode
                          opening_hours_text map_link ) ) {
        $is_geospatial = 1 if $tt_vars{$var};
    }

    $is_geospatial = 1 if scalar @locs;

    $tt_vars{obj_type} = $is_geospatial ? "geo:SpatialThing"
                                        : "rdf:Description";
    $tt_vars{is_geospatial} = $is_geospatial;

    # Fix up lat and long.
    eval {
           @tt_vars{ qw( wgs84_long wgs84_lat ) } =
               OpenGuides::Utils->get_wgs84_coords(
                                             longitude => $tt_vars{longitude},
                                             latitude  => $tt_vars{latitude},
                                             config    => $config );
    };

    # Timestamp of last edited.
    my $timestamp = $node_data{last_modified};
    if ( $timestamp ) {
        # Make a Time::Piece object in order to canonicalise time.  I think.
        my $timestamp_fmt = $Wiki::Toolkit::Store::Database::timestamp_fmt;
        my $time   = Time::Piece->strptime($timestamp, $timestamp_fmt);
        $tt_vars{timestamp} = $time->strftime("%Y-%m-%dT%H:%M:%S");
    }

    $tt_vars{node_uri} = $self->{make_node_url}->( $node_name );
    $tt_vars{node_uri_with_version}
                            = $self->{make_node_url}->( $node_name,
                                                        $tt_vars{version} );

    my $redirect = OpenGuides::Utils->detect_redirect( content =>
                                                         $node_data{content} );
    if ( $redirect ) {
        $tt_vars{redirect} = $config->script_url . $config->script_name
                             . "?id="
                             . $formatter->node_name_to_node_param( $redirect )
                             . ";format=rdf#obj";
    }

    # Escape stuff!
    foreach my $var ( keys %tt_vars ) {
        if ( $tt_vars{$var} ) {
            $tt_vars{$var} = encode_entities_numeric( $tt_vars{$var} );
        }
    }

    my @revisions = $wiki->list_node_all_versions(
                                                   name => $node_name,
                                                   with_content => 0,
                                                   with_metadata => 1,
                                                 );

    # We want all users who have edited the page listed as contributors,
    # but only once each
    foreach my $rev ( @revisions ) {
        my $username = $rev->{metadata}{username};
        next unless defined $username && length $username;

        my $user_id = $username;
        $user_id =~ s/\s+/_/g;

        $tt_vars{contributors}{$username} ||=
            {
              username => encode_entities_numeric($username),
              user_id  => encode_entities_numeric($user_id),
            };
    }

    # OK, we've set all our template variables; now process the template.
    my $template_path = $config->template_path;
    my $custom_template_path = $config->custom_template_path || "";
    my $tt = Template->new( {
                    INCLUDE_PATH => "$custom_template_path:$template_path" } );

    $tt_vars{full_cgi_url} = $config->script_url . $config->script_name;

    my $rdf;
    $tt->process( "node_rdf.tt", \%tt_vars, \$rdf );
    $rdf ||= "ERROR: " . $tt->error;
    return $rdf;
}

=head1 NAME

OpenGuides::RDF - An OpenGuides plugin to output RDF/XML.

=head1 DESCRIPTION

Does all the RDF stuff for OpenGuides.  Distributed and installed as
part of the OpenGuides project, not intended for independent
installation.  This documentation is probably only useful to OpenGuides
developers.

=head1 SYNOPSIS

    use Wiki::Toolkit;
    use OpenGuides::Config;
    use OpenGuides::RDF;

    my $wiki = Wiki::Toolkit->new( ... );
    my $config = OpenGuides::Config->new( file => "wiki.conf" );
    my $rdf_writer = OpenGuides::RDF->new( wiki   => $wiki,
                                         config => $config );

    # RDF version of a node.
    print "Content-Type: application/rdf+xml\n\n";
    print $rdf_writer->emit_rdfxml( node => "Masala Zone, N1 0NU" );

=head1 METHODS

=over 4

=item B<new>

    my $rdf_writer = OpenGuides::RDF->new( wiki   => $wiki,
                                           config => $config );

C<wiki> must be a L<Wiki::Toolkit> object and C<config> must be an
L<OpenGuides::Config> object.  Both arguments mandatory.


=item B<emit_rdfxml>

    $wiki->write_node( "Masala Zone, N1 0NU",
		     "Quick and tasty Indian food",
		     $checksum,
		     { comment  => "New page",
		       username => "Kake",
		       locale   => "Islington" }
    );

    print "Content-Type: application/rdf+xml\n\n";
    print $rdf_writer->emit_rdfxml( node => "Masala Zone, N1 0NU" );

B<Note:> Some of the fields emitted by the RDF/XML generator are taken
from the node metadata. The form of this metadata is I<not> mandated
by L<Wiki::Toolkit>. Your wiki application should make sure to store some or
all of the following metadata when calling C<write_node>:

=over 4

=item B<postcode> - The postcode or zip code of the place discussed by the node.  Defaults to the empty string.

=item B<city> - The name of the city that the node is in.  If not supplied, then the value of C<default_city> in the config object supplied to C<new>, if available, otherwise the empty string.

=item B<country> - The name of the country that the node is in.  If not supplied, then the value of C<default_country> in the config object supplied to C<new> will be used, if available, otherwise the empty string.

=item B<username> - An identifier for the person who made the latest edit to the node.  This person will be listed as a contributor (Dublin Core).  Defaults to empty string.

=item B<locale> - The value of this can be a scalar or an arrayref, since some places have a plausible claim to being in more than one locale.  Each of these is put in as a C<Neighbourhood> attribute.

=item B<phone> - Only one number supported at the moment.  No validation.

=item B<website> - No validation.

=item B<opening_hours_text> - A freeform text field.

=back

=back

=head1 SEE ALSO

=over 4

=item * L<Wiki::Toolkit>

=item * L<http://openguides.org/>

=item * L<http://chefmoz.org/>

=back

=head1 AUTHOR

The OpenGuides Project (openguides-dev@lists.openguides.org)

=head1 COPYRIGHT

Copyright (C) 2003-2013 The OpenGuides Project.  All Rights Reserved.

This module is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=head1 CREDITS

Code in this module written by Kake Pugh and Earle Martin. Dan Brickley, Matt
Biddulph and other inhabitants of #swig on irc.freenode.net gave useful feedback
and advice.

=cut

1;
