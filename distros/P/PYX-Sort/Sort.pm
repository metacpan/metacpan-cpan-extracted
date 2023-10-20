package PYX::Sort;

use strict;
use warnings;

use Class::Utils qw(set_params);
use PYX::Parser;

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
			'attribute' => \&_attribute,
			'start_element' => \&_tag,
			'end_element' => \&_tag,
			'comment' => \&_tag,
			'instruction' => \&_tag,
			'data' => \&_tag,
		},
		'non_parser_options' => {
			'tag' => {},
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
	my ($self, $file, $out) = @_;
	$self->{'pyx_parser'}->parse_file($file, $out);
	return;
}

# Parse from handler.
sub parse_handler {
	my ($self, $input_file_handler, $out) = @_;
	$self->{'pyx_parser'}->parse_handler($input_file_handler, $out);
	return;
}

# Process attribute.
sub _attribute {
	my ($pyx_parser_obj, $att, $attval) = @_;
	$pyx_parser_obj->{'non_parser_options'}->{'tag'}->{$att} = $attval;
	return;
}

# Process tag.
sub _tag {
	my $pyx_parser_obj = shift;
	my $out = $pyx_parser_obj->{'output_handler'};
	_flush($pyx_parser_obj);
	print {$out} $pyx_parser_obj->line, "\n";
	return;
}

# Flush attributes.
sub _flush {
	my $pyx_parser_obj = shift;
	my $out = $pyx_parser_obj->{'output_handler'};
	foreach my $key (sort keys %{$pyx_parser_obj->{'non_parser_options'}
		->{'tag'}}) {

		print {$out} 'A'.$key.'="'.$pyx_parser_obj
			->{'non_parser_options'}->{'tag'}->{$key}.'"'."\n";
	}
	$pyx_parser_obj->{'non_parser_options'}->{'tag'} = {};
	return;
}

1;

__END__

=pod

=encoding utf8

=head1 NAME

PYX::Sort - Processing PYX data or file and sort element attributes.

=head1 SYNOPSIS

 use PYX::Sort;

 my $obj = PYX::Sort->new(%parameters);
 $obj->parse($pyx, $out);
 $obj->parse_file($input_file, $out);
 $obj->parse_handler($input_file_handler, $out);

=head1 METHODS

=head2 C<new>

 my $obj = PYX::Sort->new(%parameters);

Constructor.

=over 8

=item * C<output_handler>

Output handler.

Default value is \*STDOUT.

=back

Returns instance of object.

=head2 C<parse>

 $obj->parse($pyx, $out);

Parse PYX text or array of PYX text and print sorted list of element attributes in PYX format.
If C<$out> not present, use 'output_handler'.

Returns undef.

=head2 C<parse_file>

 $obj->parse_file($input_file, $out);

Parse file with PYX data and print sorted list of element attributes in PYX format.
If C<$out> not present, use 'output_handler'.

Returns undef.

=head2 C<parse_handler>

 $obj->parse_handler($input_file_handler, $out);

Parse PYX handler print sorted list of element attributes in PYX format.
If C<$out> not present, use 'output_handler'.

Returns undef.

=head1 ERRORS

 new():
         From Class::Utils::set_params():
                 Unknown parameter '%s'.

=head1 EXAMPLE

=for comment filename=sort_element_attributes.pl

 use strict;
 use warnings;

 use PYX::Sort;

 # Example data.
 my $pyx = <<'END';
 (tag
 Aattr3 value
 Aattr2 value
 Aattr1 value
 -text
 )tag
 END

 # PYX::Sort object.
 my $obj = PYX::Sort->new;

 # Parse.
 $obj->parse($pyx);

 # Output:
 # (tag
 # Aattr1="value"
 # Aattr2="value"
 # Aattr3="value"
 # -text
 # )tag

=head1 DEPENDENCIES

L<Class::Utils>,
L<PYX::Parser>.

=head1 SEE ALSO

=over

=item L<Task::PYX>

Install the PYX modules.

=back

=head1 REPOSITORY

L<https://github.com/michal-josef-spacek/PYX-Sort>

=head1 AUTHOR

Michal Josef Špaček L<mailto:skim@cpan.org>

L<http://skim.cz>

=head1 LICENSE AND COPYRIGHT

© 2011-2023 Michal Josef Špaček

BSD 2-Clause License

=head1 VERSION

0.05

=cut
