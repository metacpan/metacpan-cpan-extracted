package MojoX::Routes::AsGraph;
$MojoX::Routes::AsGraph::VERSION = '0.07';
use warnings;
use strict;
use Graph::Easy;

sub graph {
  my ($self, $r) = @_;
  return unless $r;
  
  my $g = Graph::Easy->new;
  _new_node($g, $r, {});
  
  return $g;
}

sub _new_node {
  my ($g, $r, $s) = @_;
  
  ### collect cool stuff
  my $name = $r->name;
  my $is_endpoint = $r->is_endpoint;
  my $pattern = $r->pattern;

  my $ctrl_actn;
  if ($pattern) {
    my $controller = $pattern->defaults->{controller};
    my $action     = $pattern->defaults->{action};

    $ctrl_actn = $controller || '';
    $ctrl_actn .= "->$action" if $action;

    $pattern    = $pattern->unparsed;
  }

  ### Create node
  my @node_name = ($is_endpoint? '*' : '');

  if (!$pattern && !$ctrl_actn) {
    my $n = ++$s->{empty};
    push @node_name, "<empty $n>";
  }
  else {
    push @node_name, "'$pattern'"    if $pattern;
    push @node_name, "[$ctrl_actn]" if $ctrl_actn;
  }
  push @node_name, "($name)" if $name;
  my $node = $g->add_node(join(' ', @node_name));
  
  ### Draw my children
  for my $child (@{$r->children}) {
    my $child_node = _new_node($g, $child, $s);
    $g->add_edge($node, $child_node);
  }
  
  return $node;  
}


1; # End of MojoX::Routes::AsGraph


__END__

=encoding utf8

=head1 NAME

MojoX::Routes::AsGraph - Create a graph from a MojoX::Routes object


=head1 VERSION

version 0.07

=head1 SYNOPSIS

Given a MojoX::Routes object, generates a Graph::Easy object with all
the possible routes.

    use MojoX::Routes::AsGraph;
    use My::Mojolicious::App;
    
    my $app   = My::Mojolicious::App->new;
    my $graph = MojoX::Routes::AsGraph->graph($app->routes);
    
    ### $graph is a Graph::Easy object, generate a .dot file
    if (open(my $dot, '>', 'routes.dot')) {
      print $dot $graph->as_graphviz;
      close($dot);
    }
    
    ### or directly as a PNG file
    if (open(my $png, '|-', 'dot -Tpng -o routes.png')) {
      print $png $graph->as_graphviz;
      close($png);
    }


=head1 METHODS

=head2 $graph = graph($routes)

Accepts a L<MojoX::Routes> object and generates an L<Graph::Easy> object
with a representation of the routes tree.


=head1 AUTHOR

Pedro Melo, C<< <melo at cpan.org> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-mojox-routes-asgraph at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=MojoX-Routes-AsGraph>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.


=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc MojoX::Routes::AsGraph


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=MojoX-Routes-AsGraph>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/MojoX-Routes-AsGraph>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/MojoX-Routes-AsGraph>

=item * Search CPAN

L<http://search.cpan.org/dist/MojoX-Routes-AsGraph/>

=item * IRC

Use the #mojo channel at FreeNode.

=back


=head1 COPYRIGHT & LICENSE

Copyright 2009 Pedro Melo.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.
