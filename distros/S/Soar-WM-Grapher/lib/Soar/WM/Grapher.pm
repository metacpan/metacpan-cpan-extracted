#
# This file is part of Soar-WM-Grapher
#
# This software is copyright (c) 2012 by Nathan Glenn.
#
# This is free software; you can redistribute it and/or modify it under
# the same terms as the Perl 5 programming language system itself.
#
package Soar::WM::Grapher;

# ABSTRACT: Utility for creating graphs of Soar's working memory
use strict;
use warnings;
use Carp;
use Soar::WM qw(wm_root_from_file);
use GraphViz;
use base qw(Exporter);
our @EXPORT_OK = qw(wm_graph);
use feature 'state';

our $VERSION = '0.02'; # VERSION

# print wm_graph(@ARGV)->as_svg('lawyers.svg') unless caller;
if ( !caller ) {
    my $wm = Soar::WM->new( file => shift() );
    my $g = wm_graph(
        $wm, @ARGV,
        layout  => 'twopi',
        ratio   => 'compress',
        overlap => 'scale'
    );
    $g->as_svg('wm_graph.svg');
}

# wm_graph(@ARGV) unless caller;

sub wm_graph {
    my ( $wm, $id, $depth, @graph_args ) = @_;
    if ( !( $wm && $id && $depth ) ) {
        carp 'Usage: get_graph(filename, wme_id, depth)';
        return;
    }
    if ( $depth < 1 ) {
        carp 'depth argument must be 1 or more';
        return;
    }

    my $wme = $wm->get_wme($id);
    my $g   = GraphViz->new(@graph_args);    #edge=>{arrowhead=>'none'}

    #begin graph by adding first WME
    $g->add_node( name => $wme->id, color => 'red' );
    return _recurse( $wme, $depth, $g );
}

#recursively create GraphViz object
sub _recurse {
    my ( $wme, $depth, $g ) = @_;

#counter is used to prevent nodes from having the same name. Should work as long as
#the number of nodes with the same name doesn't exceed your machine's integer size.
    state $counter = 0;

    #base case: depth is 0
    return if !$depth;
    $depth--;

    #iterate attributes and their values
    for my $att ( @{ $wme->atts } ) {
        for my $val ( @{ $wme->vals($att) } ) {
            if ( ref $val eq 'Soar::WM::Element' ) {

          # print "edge from " . $wme->id . " to " . $val->id . " named $att\n";
          #add an edge from parent to att value; label edge with att name
                $g->add_edge( $wme->id => $val->id, label => $att );
                _recurse( $val, $depth, $g );
            }
            else {
                #add value as a node, making sure its name is unique.
                my $val_node_name = $val . $counter;
                $counter++;
                $g->add_node( label => $val, name => $val_node_name );
                $g->add_edge( $wme->id => $val_node_name, label => $att );
            }
        }
    }
    return $g;
}

1;

__END__

=pod

=head1 NAME

Soar::WM::Grapher - Utility for creating graphs of Soar's working memory

=head1 VERSION

version 0.02

=head1 SYNOPSIS

  use Soar::WM;
  use Soar::WM::Grapher qw(wm_graph);
  my $wm = Soar::WM->new(file=>'path/to/wme/dump');
  my $wme_id = 'S1'; #name of WME to begin graph from
  my $depth = 2; #number of levels to traverse during graphing
  my $g = wm_graph($wm, $wme_id, $depth, layout => 'twopi', ratio => 'compress', overlap=>'scale');
  $g->as_svg('wm_graph.svg'); 

=head1 DESCRIPTION

This module can be used to create GraphViz representations of Soar working memory.

=head1 NAME

Soar::WM - Perl extension for representing Soar working memory given a WME dump file

=head1 METHODS

=head2 C<wm_graph>

There are three required arguments: a L<Soar::WM> object, the ID of the working memory element to begin graphing from, and the depth to graph.
If the depth is 1, then only the specified element and its attribute-value pairs will be graphed. 2 will also graph each of the WMEs attached to the first node, and so on.
The return value is a L<GraphViz> object.
Any extra arguments passed to this function are passed on to the GraphViz constructor; therefore, you can specify graphing options such as layout, as seen in the synopsis above.

=head1 TODO

I understand that L<GraphViz> is deprecated in favor of L<GraphViz2>. However, I cannot cleanly install GraphViz2 on my own computer (it has a rather large dependency list). When I can cleanly install GraphViz2, I'll switch to that module.

=head1 SEE ALSO

The C<wm_graph> function accepts many optional arguments specified by the L<GraphViz> module.

=head1 AUTHOR

Nathan Glenn <garfieldnate@gmail.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2012 by Nathan Glenn.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
