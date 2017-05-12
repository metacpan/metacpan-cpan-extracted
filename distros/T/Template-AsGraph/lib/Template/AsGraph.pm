package Template::AsGraph;

use warnings;
use strict;
use Graph::Easy;
use Template;
use Carp 'croak';
use File::Spec;

our $VERSION = '0.02';


sub graph {
	# get parameters
	my $self     = shift;
	my $filename = shift or croak "you must specify a template name";
	my $config   = (@_ ? shift : {});
	my $vars     = (@_ ? shift : {});
	
	unless (exists $config->{OUTPUT}) {
		$config->{OUTPUT} ||= File::Spec->devnull;
	}

	# setup our own context object. This can be 
	# overridable by user's $config, assuming 
	# they know what they're doing
	$Template::Config::CONTEXT = 'Template::AsGraph::Context';

	# process the given template, to populate
	# context's tree structure
	my $template = Template->new($config);
	$template->process($filename, $vars)
		|| croak $template->error;

	# grab our shiny tree and make it a graph!
	my $tree = $template->context->tree;	

	my $graph = Graph::Easy->new();
	foreach my $child (keys %{$tree}) {
		_new_node($graph, $filename, $tree->{$child});
	}
	
	return $graph;
}


# this internal method recursively fills 
# our graph with appropriate node values
sub _new_node {
	my ($graph, $name, $tree) = (@_);
	
	# add current node to graph
	my $node = $graph->add_node($name);
	
	# link each child to it
	foreach my $child (keys %{$tree}) {
		my $child_node = _new_node($graph, $child, $tree->{$child});
		$graph->add_edge($node, $child_node);
	}

	return $node;
}

42;
__END__
=head1 NAME

Template::AsGraph - Create a graph from a Template Toolkit file

=head1 VERSION

Version 0.01

=head1 SYNOPSIS

Given a Template Toolkit filename, it generates a Graph::Easy object with the entire template flow.

  use Template::AsGraph;
  
  # quick graph creation for any TT2 template
  my $graph = Template::AsGraph->graph('mytemplate.tt2');
  
  
You can also set up any TT configurations such as different tag styles and INCLUDE_PATHs. You can even set OUTPUT to actually get the processed template (see documentation below):

  my %config = (
        INCLUDE_PATH => 'root/src/',
        START_TAG    => '<+',
        END_TAG      => '+>',
        PLUGIN_BASE  => 'MyApp::Template::Plugin',
        PRE_PROCESS  => 'header',
        OUTPUT       => \$output,
  );
  my $graph = Template::AsGraph->graph('mytemplate.tt2', \%config);
  
  
Alternatively, if you have dinamically loaded templates, you may want to pass on variables and other TT options just as you would to a regular Template object.

  my $graph = Template::AsGraph->graph('mytemplate.tt2', \%config, \%vars);


The returnerd $graph is a Graph::Easy object, so you can manipulate it at will. For example, save as a PNG file (assuming you have graphviz's "dot" binary)

  if (open my $png, '|-', 'dot -Tpng -o routes.png') {
      print $png $graph->as_graphviz;
      close($png);
  }


=head1 DESCRIPTION


=head2 graph($template_name)

=head2 graph($template_name, \%tt_config)

=head2 graph($template_name, \%tt_config, \%tt_vars)

Receives a template name and generates a L<Graph::Easy> object with a representation of the template's flow. It may optionally receive any L<Template> configuration option and variables.


=head1 AUTHOR

Breno G. de Oliveira, C<< <garu at cpan.org> >>

=head1 CAVEATS

Although this module should work without any quirks and DWIM for almost everyone, there are some minor issues that can emerge with advanced users:

=over 4

=item * In order to correctly find the processing tree, we wrap TT's Context module on our own. So you won't be able to setup a custom Context object to use with this module. If your version also wraps the original TT Context (and you should), you can easily fix this by inheriting from Template::AsGraph::Context instead of from Template::Context, and just setting it up in the config hash:

   CONTEXT => My::Custom::Context->new(),


=item * If, by any chance, you also want to fetch the output of the processed template(s), you'll need to setup the OUTPUT (and, optionally, OUTPUT_PATH). Please refer to L<Template::Manual::Config> for more information on how to get the best out of it.

=back


=head1 BUGS

Please report any bugs or feature requests to C<bug-template-asgraph at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Template-AsGraph>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.




=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Template::AsGraph


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Template-AsGraph>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Template-AsGraph>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Template-AsGraph>

=item * Search CPAN

L<http://search.cpan.org/dist/Template-AsGraph/>

=back


=head1 ACKNOWLEDGEMENTS

Andy Wardley and his awesome Template Toolkit deserve all the praise. Also, many thanks to Pedro Melo and his L<MojoX::Routes::AsGraph>, which served as inspiration for this module from the main idea down to the actual code.

=head1 COPYRIGHT & LICENSE

Copyright 2009 Breno G. de Oliveira, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.
