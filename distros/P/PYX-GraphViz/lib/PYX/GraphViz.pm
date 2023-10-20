package PYX::GraphViz;

use strict;
use warnings;

use Class::Utils qw(set_params);
use Error::Pure qw(err);
use GraphViz;
use PYX::Parser;

our $VERSION = 0.06;

# Constructor.
sub new {
	my ($class, @params) = @_;

	# Object.
	my $self = bless {}, $class;

	# Colors.
	$self->{'colors'} = {
		'a' => 'blue',
		'blockquote' => 'orange',
		'br' => 'orange',
		'div' => 'green',
		'form' => 'yellow',
		'html' => 'black',
		'img' => 'violet',
		'input' => 'yellow',
		'option' => 'yellow',
		'p' => 'orange',
		'select' => 'yellow',
		'table' => 'red',
		'td' => 'red',
		'textarea' => 'yellow',
		'tr' => 'red',
		'*' => 'grey',
	};

	# Layout.
	$self->{'layout'} = 'neato';

	# Height and width.
	$self->{'height'} = 10;
	$self->{'width'} = 10;

	# Node height.
	$self->{'node_height'} = 0.3;

	# Output handler.
	$self->{'output_handler'} = \*STDOUT;

	# Process params.
	set_params($self, @params);

	# GraphViz object.
	$self->{'_g'} = GraphViz->new(
		'layout' => $self->{'layout'},
		'overlap' => 'scale',
		'height' => $self->{'height'},
		'width' => $self->{'width'},
	);

	# Check to '*' color.
	if (! exists $self->{'colors'}->{'*'}) {
		err "Bad color define for '*' elements.";
	}

	# PYX::Parser object.
	$self->{'_pyx_parser'} = PYX::Parser->new(
		'callbacks' => {
			'end_element' => \&_end_element,
			'final' => \&_final,
			'start_element' => \&_start_element,
		},
		'non_parser_options' => {
			'colors' => $self->{'colors'},
			'g' => $self->{'_g'},
			'node_height' => $self->{'node_height'},
			'num' => 0,
			'stack' => [],
		},
		'output_handler' => $self->{'output_handler'},
	);

	# Object.
	return $self;
}

# Parse pyx text or array of pyx text.
sub parse {
	my ($self, $pyx, $out) = @_;
	$self->{'_pyx_parser'}->parse($pyx, $out);
	return;
}

# Parse file with pyx text.
sub parse_file {
	my ($self, $file, $out) = @_;
	$self->{'_pyx_parser'}->parse_file($file, $out);
	return;
}

# Parse from handler.
sub parse_handler {
	my ($self, $input_file_handler, $out) = @_;
	$self->{'_pyx_parser'}->parse_handler($input_file_handler, $out);
	return;
}

# Process element.
sub _start_element {
	my ($pyx_parser_obj, $elem) = @_;
	$pyx_parser_obj->{'non_parser_options'}->{'num'}++;
	my $num = $pyx_parser_obj->{'non_parser_options'}->{'num'};
	my $colors = $pyx_parser_obj->{'non_parser_options'}->{'colors'};
	my $color;
	if (exists $colors->{$elem}) {
		$color = $colors->{$elem};
	} else {
		$color = $colors->{'*'};
	}
	my $g = $pyx_parser_obj->{'non_parser_options'}->{'g'};
	my $node_height = $pyx_parser_obj->{'non_parser_options'}
		->{'node_height'};
	$g->add_node($num,
		'color' => $color,
		'height' => $node_height,
		'shape' => 'point'
	);
	my $stack_ar = $pyx_parser_obj->{'non_parser_options'}->{'stack'};
	if (@{$stack_ar}) {
		$g->add_edge(
			 $num=> $stack_ar->[-1]->[1],
			'arrowhead' => 'none',
			'weight' => 2,
		);
	}
	push @{$stack_ar}, [$elem, $num];
	return;
}

# Process elements.
sub _end_element {
	my ($pyx_parser_obj, $elem) = @_;
	my $stack_ar = $pyx_parser_obj->{'non_parser_options'}->{'stack'};
	if ($stack_ar->[-1]->[0] eq $elem) {
		pop @{$stack_ar};
	}
	return;
}

# Final.
sub _final {
	my $pyx_parser_obj = shift;
	my $g = $pyx_parser_obj->{'non_parser_options'}->{'g'};
	my $out = $pyx_parser_obj->{'output_handler'};
	$g->as_png($out);
	return;
}

1;

__END__

=pod

=encoding utf8

=head1 NAME

PYX::GraphViz - GraphViz output for PYX handling.

=head1 SYNOPSIS

 use PYX::GraphViz;

 my $obj = PYX::GraphViz->new(%parameters);
 $obj->parse($pyx, $out);
 $obj->parse_file($input_file, $out);
 $obj->parse_handler($input_file_handler, $out);

=head1 METHODS

=over 8

=item C<new(%parameters)>

Constructor

=over 8

=item * C<colors>

 Colors.
 Default value is {
         'a' => 'blue',
         'blockquote' => 'orange',
         'br' => 'orange',
         'div' => 'green',
         'form' => 'yellow',
         'html' => 'black',
         'img' => 'violet',
         'input' => 'yellow',
         'option' => 'yellow',
         'p' => 'orange',
         'select' => 'yellow',
         'table' => 'red',
         'td' => 'red',
         'textarea' => 'yellow',
         'tr' => 'red',
         '*' => 'grey',
 }

=item * C<height>

 GraphViz object height.
 Default value is 10.

=item * C<layout>

 GraphViz layout.
 Default value is 'neato'.

=item * C<node_height>

 GraphViz object node height.
 Default value is 0.3.

=item * C<output_handler>

 Output handler.
 Default value is \*STDOUT.

=item * C<width>

 GraphViz object width.
 Default value is 10.

=back

=item C<parse($pyx[, $out])>

 Parse PYX text or array of PYX text.
 If $out not present, use 'output_handler'.
 Returns undef.

=item C<parse_file($input_file[, $out])>

 Parse file with PYX data.
 If $out not present, use 'output_handler'.
 Returns undef.

=item C<parse_handler($input_file_handler[, $out])>

 Parse PYX handler.
 If $out not present, use 'output_handler'.
 Returns undef.

=back

=head1 ERRORS

 new():
        Bad color define for '*' elements.
        From Class::Utils::set_params():
                Unknown parameter '%s'.

=head1 EXAMPLE

=for comment filename=simple_html_to_png.pl

 use strict;
 use warnings;

 use PYX::GraphViz;

 # Example PYX data.
 my $pyx = <<'END';
 (html
 (head
 (title
 -Title
 )title
 )head
 (body
 (div
 -data
 )div
 )body
 END

 # Object.
 my $obj = PYX::GraphViz->new;

 # Parse.
 $obj->parse($pyx);

 # Output
 # PNG data

=begin html

<a href="https://raw.githubusercontent.com/michal-josef-spacek/PYX-GraphViz/master/images/simple_html_to_png.png">
  <img src="https://raw.githubusercontent.com/michal-josef-spacek/PYX-GraphViz/master/images/simple_html_to_png.png" alt="Output of example" width="300px" height="300px" />
</a>

=end html

=head1 DEPENDENCIES

L<Class::Utils>,
L<Error::Pure>,
L<GraphViz>,
L<PYX::Parser>.

=head1 SEE ALSO

=over

=item L<Task::PYX>

Install the PYX modules.

=back

=head1 REPOSITORY

L<https://github.com/michal-josef-spacek/PYX-GraphViz>

=head1 AUTHOR

Michal Josef Špaček L<mailto:skim@cpan.org>

L<http://skim.cz>

=head1 LICENSE AND COPYRIGHT

© 2011-2023 Michal Josef Špaček

BSD 2-Clause License

=head1 VERSION

0.06

=cut
