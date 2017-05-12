use strict;
use warnings;
package RDF::Trine::Exporter::GraphViz;
{
  $RDF::Trine::Exporter::GraphViz::VERSION = '0.141';
}
#ABSTRACT: Serialize RDF graphs as dot graph diagrams

use RDF::Trine;
use GraphViz qw(2.04);
use Scalar::Util qw(reftype blessed);
use Carp;
use RDF::NS;

our $NS = RDF::NS->new('any');

# TODO: create RDF::Trine::Exporter as base class
use base qw(RDF::Trine::Serializer);

our %FORMATS = (
    dot   => 'text/plain',
    ps    => 'application/postscript',
    hpgl  => 'application/vnd.hp-hpgl',
    pcl   => 'application/vnd.hp-pcl',
    mif   => 'application/vnd.mif',
    gif   => 'image/gif',
    jpeg  => 'image/jpeg',
    png   => 'image/png',
    wbmp  => 'image/vnd.wap.wbmp',
    cmapx => 'text/html',
    imap  => 'application/x-httpd-imap',
    'map' => 'application/x-httpd-imap',
    vrml  => 'model/vrml',
    fig   => 'image/x-xfig',
    svg   => 'image/svg+xml',
    svgz  => 'image/svg+xml',
);

sub new {
    my ($class, %args) = @_;

    my $self = bless \%args, $class;

    $self->{as} ||= 'dot';
    croak 'Unknown format ' . $self->{as}
        unless $FORMATS{ $self->{as} };

    $self->{mime} ||= $FORMATS{ $self->{as} };

    $self->{style}    ||= { rankdir => 'BT', concentrate => 1 };
    $self->{node}     ||= { shape => 'plaintext', color => 'gray' };
    $self->{resource} ||= { shape => 'box', style => 'rounded',
        fontcolor => 'blue' };
    $self->{literal}  ||= { shape => 'box' };
    $self->{blank}    ||= { label => '', shape => 'point',
        fillcolor => 'white', color => 'gray', width => '0.3' };
    $self->{variable} ||= { fontcolor => 'darkslategray' };
    $self->{prevar}   ||= '?';
    $self->{alias}    ||= { };

    if ( $self->{url} and (reftype($self->{url})||'') ne 'CODE' ) {
        $self->{url} = sub { shift->uri };
    }

    return $self;
}

sub media_types {
    my $self = shift;
    return ($self->{mime});
}

sub to_string {
    my ($self, $rdf, %options) = @_;

    my $g = $self->as_graphviz($rdf, %options);

    my $format = ($options{as} || $self->{as});
    die "Unknown serialization format $format" unless $FORMATS{$format};

    my $method = "as_$format";
    $method = 'as_canon' if $method eq 'as_dot';
    $method = 'as_imap'  if $method eq 'as_map';

    my $data;
    eval {
        # TODO: Catch error message sent to STDOUT by dot if this fails.
        $g->$method( \$data );
    };

    return $data;
}

sub to_file {
    my ($self, $file, $rdf, %options) = @_;

    croak "missing file parameter" unless defined $file;

    if (!ref $file) {
        $options{as} = $1 if $file =~ /\.([^.]+)$/ and $FORMATS{$1};
        open (my $fh, '>', $file);
        $file = $fh;
    }

    print {$file} $self->to_string( $rdf, %options );
}

sub serialize_model_to_string {
    shift->to_string(@_);
}

sub serialize_model_to_file {
    shift->to_file(@_);
}

sub serialize_iterator_to_string {
    shift->to_string(@_);
}

sub as_graphviz {
   my ($self, $rdf, %options) = @_;
   return unless blessed $rdf;
   $rdf = $rdf->as_stream if $rdf->isa('RDF::Trine::Model');
   return $self->iterator_as_graphviz( $rdf, %options );
}

sub iterator_as_graphviz {
    my ($self, $iter, %options) = @_;

    # We could make use of named graphs in a later version...
    $options{title}      ||= $self->{title};

    $options{namespaces} ||= $self->{namespaces} || $NS;
    $options{root}       ||= $self->{root};
    $options{prevar}     ||= $self->{prevar};

    my $get_alias =    $options{alias} || $self->{alias} || { };
    if (((reftype $get_alias) || '') eq 'HASH') {
        my $hash = $get_alias;
        $get_alias = sub { $hash->{shift} };
    }

    # Basic options. Should be more configurable.
    my %gopt = %{$self->{style}};
    $gopt{node} ||= $self->{node};

    my %root_style = ( color => 'red' );

    $gopt{name} = $options{title} if defined $options{title};

    my $get_edge = $options{edge} || $self->{edge};

    my $g = GraphViz->new( %gopt );
    my %nsprefix = reverse %{$options{namespaces}};

    my $get_label = sub {
        my $resource = shift;
        my $label = do { $_ = $resource->uri; $get_alias->( $_ ); };
        if (!defined $label) {
            my ($local, $qname) = eval { $resource->qname };
            my $prefix = $local ? $nsprefix{$local} : "";
            $label = $prefix ? "$prefix:$qname" : $resource->as_string;
        }
        return $label;
    };

    my %seen;
    while (my $t = $iter->next) {
        my @nodes;
        my $edge_options = { };
        if ($get_edge) {
            $_ = $t->predicate->uri;
            $edge_options = $get_edge->( $t->predicate );
        }
        next unless defined $edge_options;

        foreach my $pos (qw(subject object)) {
            my $n = $t->$pos();
            my $label;
            if ($n->is_literal) {
                $label = $n->literal_value;
            } elsif( $n->is_resource ) {
                $label = $get_label->($n);
             } elsif( $n->is_blank ) {
                $label = $n->as_string;
            } elsif( $n->is_variable ) {
                $label = $options{prevar}.$n->name;
            }
            # TODO: what about nodes with equal label?
            push(@nodes, $label);
            next if ($seen{ $label }++);
            if ( $n->is_literal ) {
                # TODO: add language / datatype
                $g->add_node( $label, %{$self->{literal}} );
            } elsif ( $n->is_resource ) {
                my %layout = %{$self->{resource}};
                $layout{URL} = $self->{url}->( $n ) if $self->{url};
                if ( ($options{'root'} ||  '') eq $n->uri ) {
                    $layout{$_} = $root_style{$_} for keys %root_style;
                }
                $g->add_node( $label, %layout );
            } elsif ( $n->is_blank ) {
                $g->add_node( $label, %{$self->{blank}} );
            } elsif ( $n->is_variable ) {
                $g->add_node( $label, %{$self->{variable}} );
            }
        }

        $edge_options->{label} //= $get_label->( $t->predicate );
        $g->add_edge( @nodes, %$edge_options );
    }

    return $g;
}

1;


__END__
=pod

=head1 NAME

RDF::Trine::Exporter::GraphViz - Serialize RDF graphs as dot graph diagrams

=head1 VERSION

version 0.141

=head1 SYNOPSIS

  use RDF::Trine::Exporter::GraphViz;

  my $ser = RDF::Trine::Exporter::GraphViz->new( as => 'dot' );
  my $dot = $ser->to_string( $rdf );

  $ser->to_file( 'graph.svg', $rdf );

  # highly configurable
  my $g = RDF::Trine::Exporter::GraphViz->new(
      namespaces => {
          foaf => 'http://xmlns.com/foaf/0.1/'
      },
      alias => {
          'http://www.w3.org/2002/07/owl#sameAs' => '=',
      },
      prevar => '$',  # variables as '$x' instead of '?x'
      url    => 1,    # hyperlink all URIs

      # see below for more configuration options
  );
  $g->to_file( 'test.svg', $model );

=head1 DESCRIPTION

L<RDF::Trine::Model> includes a nice but somehow misplaced and non-customizable
method C<as_graphviz>. This module implements an extended version, put in a
extends this method in a RDF::Trine::Exporter object.  (actually it is a
subclass of L<RDF::Trine::Serializer> as long as RDF::Trine has no common class
RDF::Trine::Exporter).  This module also includes a command line script
L<rdfdot> to create graph diagrams from RDF data.

=head1 METHODS

This modules derives from L<RDF::Trine::Serializer> with all of its methods (a
future version may be derived from RDF::Trine::Exporter). The following methods
are of interest in particular:

=head2 new ( %options )

Creates a new serializer with L<configuration|/CONFIGURATION> options
as described below.

=head2 to_file ( $file, $rdf [, %options ] )

Serialize RDF data, provided as L<RDF::Trine::Iterator> or as
L<RDF::Trine::Model> to a file. C<$file> can be a filehandle or file name.
The serialization format is automatically derived from known file extensions.

=head2 to_string( $rdf [ %options ] )

Serialize RDF data, provided as L<RDF::Trine::Iterator> or as
L<RDF::Trine::Model> to a string.

=head2 as_graphviz ( $rdf [, %options ] )

Creates and returns a L<GraphViz> object for further processing. You must
provide RDF data as L<RDF::Trine::Iterator> or as L<RDF::Trine::Model>.

=head2 media_types

Returns the exporter's mime type. For instance if you create an exporter with
C<< as => 'svg' >>, this method returns C<< ('image/svg+xml') >>.

=head2 serialize_model_to_file ( $file, $model [, %options ] )

Provided as alias for C<to_file> for compatibility with other
C<RDF::Trine::Exporter> classes.

=head2 serialize_model_to_string ( $model [, %options ] )

Provided as alias for C<to_string> for compatibility with other
C<RDF::Trine::Exporter> classes.

=head2 serialize_iterator_to_string ( $iterator [, %options ] )

Serialize a L<RDF::Trine::Iterator> as graph diagram to a string.

=head2 iterator_as_graphviz ( $iterator )

Internal core method, used by C<to_string> and C<to_file>, which one should
better call instead.

=head1 CONFIGURATION

The following configuration options can be set when creating a new object.

=over 4

=item as

Specific serialization format with C<dot> as default. Supported formats include
canonical DOT format (C<dot>), Graphics Interchange Format (C<gif>), JPEG File
Interchange Format (C<jpeg>), Portable Network Graphics (C<png>), Scalable
Vector Graphics (C<svg> and C<svgz>), server side HTML imape map (C<imap> or
C<map>), client side HTML image map (C<cmapx>), PostScript (C<ps>), Hewlett
Packard Graphic Language (C<hpgl>), Printer Command Language (C<pcl>), FIG
format (C<fig>), Maker Interchange Format (C<mif>), Wireless BitMap format
(C<wbmp>), and Virtual Reality Modeling Language (C<vrml>).

=item mime

Mime type. By default automatically set based on C<as>.

=item style

General graph style options as hash reference. Defaults to
C<< { rankdir => 'TB', concentrate => 1 } >>.

=item node

Hash reference with general options to style nodes. Defaults to
C<< { shape => 'plaintext', color => 'gray' } >>.

=item resource

Hash reference with options to style resource nodes. Defaults to
C<< { shape => 'box', style => 'rounded', fontcolor => 'blue' } >>.

=item literal

Hash reference with options to style literal nodes. Defaults to
C<< { shape => 'box' } >>.

=item blank

Hash reference with options to style blank nodes. Defaults to C<< { label => '',
shape => 'point', fillcolor => 'white', color => 'gray', width => '0.3' } >>.

=item edge

Code referece with a function that get passed a predicate and variable C<$_>
set to the predicate's URI. The function must return undef to skip the RDF
statement or a hash reference with options to style the edge.

=item url

Add clickable URLs to nodes You can either provide a boolean value or a code
reference that returns an URL when given a L<RDF::Trine::Node::Resource>.

=item alias

Hash reference with URL aliases to show as resource and predicate labels.

=item variable

Hash reference with options to style variable nodes. Defaults to C<< {
fontcolor => 'darkslategray' } >>.

=item prevar

Which character to prepend to variable names. Defaults to '?'. You can
also set it to '$'. By now the setting does not affect variables
in Notation3 formulas.

=item root

An URI that is marked as 'root' node.

=item title

Add a title to the graph.

=item namespaces

Hash reference with mapping from prefixes to URI namespaces to abbreviate URIs.
By default the prefix mapping from L<RDF::NS> is used.

=back

=head1 LIMITATIONS

This serializer does not support C<negotiate> on purpose. It may optionally be
enabled in a future version. GraphViz may fail on large graphs, its error
message is not catched yet.  Configuration in general is not fully covered by
unit tests. Identifiers of blank nodes are not included.

=head1 AUTHOR

Jakob Voß <voss@gbv.de>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2012 by Jakob Voß.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

