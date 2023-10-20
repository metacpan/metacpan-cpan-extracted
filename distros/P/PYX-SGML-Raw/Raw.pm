package PYX::SGML::Raw;

use strict;
use warnings;

use Class::Utils qw(set_params);
use PYX::Parser;
use PYX::Utils qw(encode entity_encode);

our $VERSION = 0.05;

# Constructor.
sub new {
	my ($class, @params) = @_;

	my $self = bless {}, $class;

	# Output handler.
	$self->{'output_handler'} = \*STDOUT;

	# Process params.
	set_params($self, @params);

	# PYX::Parser object.
	$self->{'pyx_parser'} = PYX::Parser->new(
		'callbacks' => {
			'start_element' => \&_start_element,
			'end_element' => \&_end_element,
			'data' => \&_data,
			'instruction' => \&_instruction,
			'attribute' => \&_attribute,
			'comment' => \&_comment,
		},
		'non_parser_options' => {
			'tag_open' => 0,
		},
		'output_handler' => $self->{'output_handler'},
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

sub finalize {
	my $self = shift;

	_end_of_start_tag($self->{'pyx_parser'});

	return;
}

# Process start of element.
sub _start_element {
	my ($pyx_parser_obj, $elem) = @_;

	my $out = $pyx_parser_obj->{'output_handler'};
	_end_of_start_tag($pyx_parser_obj);
	print {$out} "<$elem";
	$pyx_parser_obj->{'non_parser_options'}->{'tag_open'} = 1;

	return;
}

# Process end of element.
sub _end_element {
	my ($pyx_parser_obj, $elem) = @_;

	my $out = $pyx_parser_obj->{'output_handler'};
	_end_of_start_tag($pyx_parser_obj);
	print {$out} "</$elem>";

	return;
}

# Process data.
sub _data {
	my ($pyx_parser_obj, $decoded_data) = @_;

	my $out = $pyx_parser_obj->{'output_handler'};
	my $data = encode($decoded_data);
	_end_of_start_tag($pyx_parser_obj);
	print {$out} entity_encode($data);

	return;
}

# Process attribute.
sub _attribute {
	my ($pyx_parser_obj, $att, $attval) = @_;

	my $out = $pyx_parser_obj->{'output_handler'};
	print {$out} " $att=\"", entity_encode($attval), '"';

	return;
}

# Process instruction.
sub _instruction {
	my ($pyx_parser_obj, $target, $data) = @_;

	my $out = $pyx_parser_obj->{'output_handler'};
	_end_of_start_tag($pyx_parser_obj);
	print {$out} "<?$target ", encode($data), "?>";

	return;
}

# Ends start tag.
sub _end_of_start_tag {
	my $pyx_parser_obj = shift;

	my $out = $pyx_parser_obj->{'output_handler'};
	if ($pyx_parser_obj->{'non_parser_options'}->{'tag_open'}) {
		print {$out} '>';
		$pyx_parser_obj->{'non_parser_options'}->{'tag_open'} = 0;
	}

	return;
}

# Process comment.
sub _comment {
	my ($pyx_parser_obj, $comment) = @_;

	my $out = $pyx_parser_obj->{'output_handler'};
	print {$out} '<!--'.encode($comment).'-->';

	return;
}

1;

__END__

=pod

=encoding utf8

=head1 NAME

PYX::SGML::Raw - Processing PYX data or file and write as SGML.

=head1 SYNOPSIS

 use PYX::SGML::Raw;

 my $obj = PYX::SGML::Raw->new(%parameters);
 $obj->parse($pyx, $out);
 $obj->parse_file($input_file, $out);
 $obj->parse_handler($input_file_handler, $out);
 $obj->finalize;

=head1 METHODS

=head2 C<new>

 my $obj = PYX::SGML::Raw->new(%parameters);

Constructor.

=over 8

=item * C<output_handler>

 Output handler.
 Default value is \*STDOUT.

=back

Returns instance of object.

=head2 C<parse>

 $obj->parse($pyx, $out);

Parse PYX text or array of PYX text.
Output is serialization to SGML.
If C<$out> not present, use 'output_handler'.

Returns undef.

=head2 C<parse_file>

 $obj->parse_file($input_file, $out);

Parse file with PYX data.
Output is serialization to SGML.
If C<$out> not present, use 'output_handler'.

Returns undef.

=head2 C<parse_handler>

 $obj->parse_handler($input_file_handler, $out);

Parse PYX defined by handler.
Output is serialization to SGML.
If C<$out> not present, use 'output_handler'.

Returns undef.

=head2 C<finalize>

 $obj->finalize;

Finalize opened tags, if exists.

Returns undef.

=head1 ERRORS

 new():
         From Class::Utils::set_params():
                 Unknown parameter '%s'.

=head1 EXAMPLE

=for comment filename=pyx_as_sgml.pl

 use strict;
 use warnings;

 use PYX::SGML::Raw;

 # Input.
 my $pyx = <<'END';
 (element
 -data
 )element
 END

 # Object.
 my $obj = PYX::SGML::Raw->new;

 # Process.
 $obj->parse($pyx);
 print "\n";

 # Output:
 # <element>data</element>

=head1 DEPENDENCIES

L<Class::Utils>,
L<PYX::Parser>,
L<PYX::Utils>.

=head1 SEE ALSO

=over

=item L<Task::PYX>

Install the PYX modules.

=back

=head1 REPOSITORY

L<https://github.com/michal-josef-spacek/PYX-SGML-Raw>

=head1 AUTHOR

Michal Josef Špaček L<skim@cpan.org>.

L<http://skim.cz>

=head1 LICENSE AND COPYRIGHT

© 2011-2023 Michal Josef Špaček

BSD 2-Clause License

=head1 VERSION

0.05

=cut
