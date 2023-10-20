package PYX::XMLNorm;

use strict;
use warnings;

use Class::Utils qw(set_params);
use Error::Pure qw(err);
use PYX qw(end_element);
use PYX::Parser;

our $VERSION = 0.05;

# Constructor.
sub new {
	my ($class, @params) = @_;
	my $self = bless {}, $class;

	# Flush stack on finalization.
	$self->{'flush_stack'} = 0;

	# Output handler.
	$self->{'output_handler'} = \*STDOUT;

	# XML normalization rules.
	$self->{'rules'} = {};

	# Process params.
	set_params($self, @params);

	# Check to rules.
	if (! keys %{$self->{'rules'}}) {
		err 'Cannot exist XML normalization rules.';
	}

	# PYX::Parser object.
	$self->{'pyx_parser'} = PYX::Parser->new(
		'callbacks' => {
			'data' => \&_end_element_simple,
			'end_element' => \&_end_element,
			'final' => \&_final,
			'start_element' => \&_start_element,
		},
		'non_parser_options' => {
			'flush_stack' => $self->{'flush_stack'},
			'rules' => $self->{'rules'},
			'stack' => [],
		},
		'output_handler' => $self->{'output_handler'},
		'output_rewrite' => 1,
	);

	# Object.
	return $self;
}

# Parse pyx text or array of pyx text.
sub parse {
	my ($self, $pyx, $out) = @_;
	$self->{'pyx_parser'}->parse($pyx, $out);
	return;
}

# Parse file with pyx text.
sub parse_file {
	my ($self, $file) = @_;
	$self->{'pyx_parser'}->parse_file($file);
	return;
}

# Parse from handler.
sub parse_handler {
	my ($self, $input_file_handler, $out) = @_;
	$self->{'pyx_parser'}->parse_handler($input_file_handler, $out);
	return;
}

# Process start of element.
sub _start_element {
	my ($pyx_parser, $tag) = @_;
	my $out = $pyx_parser->{'output_handler'};
	my $rules = $pyx_parser->{'non_parser_options'}->{'rules'};
	my $stack = $pyx_parser->{'non_parser_options'}->{'stack'};
	if (exists $rules->{'*'}) {
		foreach my $tmp (@{$rules->{'*'}}) {
			if (@{$stack} > 0 && lc($stack->[-1]) eq $tmp) {
				print {$out} end_element(pop @{$stack}), "\n";
			}
		}
	}
	if (exists $rules->{lc($tag)}) {
		foreach my $tmp (@{$rules->{lc($tag)}}) {
			if (@{$stack} > 0 && lc($stack->[-1]) eq $tmp) {
				print {$out} end_element(pop @{$stack}), "\n";
			}
		}
	}
	push @{$stack}, $tag;
	print {$out} $pyx_parser->line, "\n";
	return;
}

# Add implicit end_element.
sub _end_element_simple {
	my $pyx_parser = shift;
	my $rules = $pyx_parser->{'non_parser_options'}->{'rules'};
	my $stack = $pyx_parser->{'non_parser_options'}->{'stack'};
	my $out = $pyx_parser->{'output_handler'};
	if (exists $rules->{'*'}) {
		foreach my $tmp (@{$rules->{'*'}}) {
			if (@{$stack} && lc $stack->[-1] eq $tmp) {
				print {$out} end_element(pop @{$stack}), "\n";
			}
		}
	}
	print {$out} $pyx_parser->line, "\n";
	return;
}

# Process end of element
sub _end_element {
	my ($pyx_parser, $tag) = @_;
	my $out = $pyx_parser->{'output_handler'};
	my $rules = $pyx_parser->{'non_parser_options'}->{'rules'};
	my $stack = $pyx_parser->{'non_parser_options'}->{'stack'};
	if (exists $rules->{'*'}) {
		foreach my $tmp (@{$rules->{'*'}}) {
			if (lc($tag) ne $tmp && lc($stack->[-1]) eq $tmp) {
				print {$out} end_element(pop @{$stack}), "\n";
			}
		}
	}
# XXX Myslim, ze tenhle blok je spatne.
	if (exists $rules->{$tag}) {
		foreach my $tmp (@{$rules->{$tag}}) {
			if (lc($tag) ne $tmp && lc($stack->[-1]) eq $tmp) {
				print {$out} end_element(pop @{$stack}), "\n";
			}
		}
	}
	if (lc($stack->[-1]) eq lc($tag)) {
		pop @{$stack};
	}
	print {$out} $pyx_parser->line, "\n";
	return;
}

# Process final.
sub _final {
	my $pyx_parser = shift;
	my $stack = $pyx_parser->{'non_parser_options'}->{'stack'};
	my $out = $pyx_parser->{'output_handler'};
	if (@{$stack} > 0) {

		# If set, than flush stack.
		if ($pyx_parser->{'non_parser_options'}->{'flush_stack'}) {
			foreach my $tmp (reverse @{$stack}) {
				print {$out} end_element($tmp), "\n";
			}
		}
	}
	return;
}

1;

__END__

=pod

=encoding utf8

=head1 NAME

PYX::XMLNorm - Processing PYX data or file and do XML normalization.

=head1 SYNOPSIS

 use PYX::XMLNorm;

 my $obj = PYX::XMLNorm->new(%parameters);
 $obj->parse($pyx, $out);
 $obj->parse_file($input_file, $out);
 $obj->parse_handler($input_file_handler, $out);

=head1 METHODS

=head2 C<new(%parameters)>

 my $obj = PYX::XMLNorm->new(%parameters);

Constructor.

=over 8

=item * C<flush_stack>

Flush stack on finalization.

Default value is 0.

=item * C<output_handler>

Output handler.

Default value is \*STDOUT.

=item * C<rules>

XML normalization rules.
Parameter is required.
Format of rules is:
Outer element => list of inner elements.
e.g.

 {
         'middle' => ['end'],
 },

Outer element can be '*'.

Default value is {}.

=back

Returns instance of object.

=head2 C<parse($pyx[, $out])>

 $obj->parse($pyx, $out);

Parse PYX text or array of PYX text.
If C<$out> not present, use 'output_handler'.

Returns undef.

=head2 C<parse_file($input_file[, $out])>

 $obj->parse_file($input_file, $out);

Parse file with PYX data.
If C<$out> not present, use 'output_handler'.

Returns undef.

=head2 C<parse_handler($input_file_handler[, $out])>

 $obj->parse_handler($input_file_handler, $out);

Parse PYX handler.
If C<$out> not present, use 'output_handler'.

Returns undef.

=head1 ERRORS

 new():
         Cannot exist XML normalization rules.
         From Class::Utils::set_params():
                 Unknown parameter '%s'.

=head1 EXAMPLE

=for comment filename=normalize_xml.pl

 use strict;
 use warnings;

 use PYX::XMLNorm;

 # Example data.
 my $pyx = <<'END';
 (begin
 (middle
 (end
 -data
 )middle
 )begin
 END

 # Object.
 my $obj = PYX::XMLNorm->new(
         'rules' => {
                 'middle' => ['end'],
         },
 );

 # Nomrmalize..
 $obj->parse($pyx);

 # Output:
 # (begin
 # (middle
 # (end
 # -data
 # )end
 # )middle
 # )begin

=head1 DEPENDENCIES

L<Class::Utils>,
L<Error::Pure>,
L<PYX>,
L<PYX::Parser>.

=head1 SEE ALSO

=over

=item L<PYX>

A perl module for PYX handling.

=item L<Task::PYX>

Install the PYX modules.

=back

=head1 REPOSITORY

L<https://github.com/michal-josef-spacek/PYX-XMLNorm>

=head1 AUTHOR

Michal Josef Špaček L<skim@cpan.org>.

=head1 LICENSE AND COPYRIGHT

© 2011-2023 Michal Josef Špaček

BSD 2-Clause License

=head1 VERSION

0.05

=cut
