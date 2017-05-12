package PYX::XMLSchema::List;

# Pragmas.
use strict;
use warnings;

# Modules.
use Class::Utils qw(set_params);
use Error::Pure qw(err);
use List::Util qw(reduce);
use PYX::Parser;
use Readonly;

# Constants.
Readonly::Scalar our $EMPTY_STR => q{};
Readonly::Scalar our $SPACE => q{ };

# Version.
our $VERSION = 0.04;

# Constructor.
sub new {
	my ($class, @params) = @_;
	my $self = bless {}, $class;

	# Output handler.
	$self->{'output_handler'} = \*STDOUT;

	# Process params.
	set_params($self, @params);

	# PYX::Parser object.
	$self->{'_pyx_parser'} = PYX::Parser->new(
		'callbacks' => {
			'attribute' => \&_call_attribute,
			'final' => \&_call_final,
			'start_element' => \&_call_start_element,
		},
		'non_parser_options' => {
			'schemas' => {},
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

# Reset parser.
sub reset {
	my $self = shift;
	$self->{'_pyx_parser'}->{'non_parser_options'}->{'schemas'} = {};
	return;
}

# Gets statistics structure.
sub stats {
	my $self = shift;
	my $schemas_hr = $self->{'_pyx_parser'}->{'non_parser_options'}
		->{'schemas'};
	return $schemas_hr;
}

# Attribute callback.
sub _call_attribute {
	my ($pyx_parser_obj, $key, $val) = @_;
	my $schemas_hr = $pyx_parser_obj->{'non_parser_options'}->{'schemas'};
	if (my ($first, $sec) = _parse_schema($key)) {

		# Get URL for XML schema.
		if ($first eq 'xmlns') {
			my $schema = $sec;
			if (! exists $schemas_hr->{$schema}) {
				_init_struct($schemas_hr, $schema, $val);
			} else {
				$schemas_hr->{$schema}->[0] = $val;
			}

		# Add attribute to XML schema statistics.
		} else {
			my $schema = $first;
			_init_struct($schemas_hr, $schema);
			$schemas_hr->{$schema}->[1]->{'attr'}++;
		}
	}
	return;
}

# Finalize callback.
sub _call_final {
	my $pyx_parser_obj = shift;
	my $schemas_hr = $pyx_parser_obj->{'non_parser_options'}->{'schemas'};
	my $out = $pyx_parser_obj->{'output_handler'};
	my $max_string = reduce { length($a) > length($b) ? $a : $b } keys %{$schemas_hr};
	my $max_len = defined $max_string ? length $max_string : 0;
	foreach my $key (sort keys %{$schemas_hr}) {
		printf {$out} "[ %-${max_len}s ] (E: %04d, A: %04d)%s\n", $key,
			$schemas_hr->{$key}->[1]->{'element'},
			$schemas_hr->{$key}->[1]->{'attr'},
			$schemas_hr->{$key}->[0] ne $EMPTY_STR
				? $SPACE.$schemas_hr->{$key}->[0]
				: $EMPTY_STR;
	}
	if (! keys %{$schemas_hr}) {
		print {$out} "No XML schemas.\n";
	}
	return;
}

# Start of element callback.
sub _call_start_element {
	my ($pyx_parser_obj, $elem) = @_;
	my $schemas_hr = $pyx_parser_obj->{'non_parser_options'}->{'schemas'};
	if (defined(my $schema = _parse_schema($elem))) {
		_init_struct($schemas_hr, $schema);
		$schemas_hr->{$schema}->[1]->{'element'}++;
	}
	return;
}

# Initialize XML schema structure.
sub _init_struct {
	my ($schemas_hr, $schema, $uri) = @_;
	if (! defined $uri) {
		$uri = $EMPTY_STR;
	}
	if (! exists $schemas_hr->{$schema}) {
		$schemas_hr->{$schema} = [$uri, {
			'attr' => 0,
			'element' => 0,
		}];
	}
	return;
}

# Parse XML schema from string.
sub _parse_schema {
	my $string = shift;
	if ($string =~ m/^(.+?):(.+)$/ms) {
		return wantarray ? ($1, $2) : $1;
	}
	return;
}

1;

__END__

=pod

=encoding utf8

=head1 NAME

PYX::XMLSchema::List - Processing PYX data or file and print list of XML schemas.

=head1 SYNOPSIS

 use PYX::XMLSchema::List;
 my $obj = PYX::XMLSchema::List->new(%parameters);
 $obj->parse($pyx, $out);
 $obj->parse_file($input_file, $out);
 $obj->parse_handle($input_file_handler, $out);
 $obj->reset;
 my $stats_hr = $obj->stats;

=head1 METHODS

=over 8

=item C<new(%parameters)>

 Constructor.

=over 8

=item * C<output_handler>

 Output handler.
 Default value is \*STDOUT.

=back

=item C<parse($pyx[, $out])>

 Parse PYX text or array of PYX text and print list of XML schemas of PYX input.
 If $out not present, use 'output_handler'.
 Returns undef.

=item C<parse_file($input_file[, $out])>

 Parse file with PYX data and print list of XML schemas of PYX input.
 If $out not present, use 'output_handler'.
 Returns undef.

=item C<parse_handler($input_file_handler[, $out])>

 Parse PYX handler and print list of XML schemas of PYX input.
 If $out not present, use 'output_handler'.
 Returns undef.

=item C<reset()>

 Resets internal structure with statistics.
 Returns undef.

=item C<stats()>

 Gets statistics structure.
 Returns undef.

=back

=head1 ERRORS

 new():
         From Class::Utils::set_params():
                 Unknown parameter '%s'.

=head1 EXAMPLE1

 # Pragmas.
 use strict;
 use warnings;

 # Modules.
 use PYX::XMLSchema::List;

 # Example data.
 my $pyx = <<'END';
 (foo
 Axmlns:bar http://bar.foo
 Axmlns:foo http://foo.bar
 Afoo:bar baz
 (foo:bar
 Axml:lang en
 Abar:foo baz
 )foo:bar
 )foo
 END

 # PYX::XMLSchema::List object.
 my $obj = PYX::XMLSchema::List->new;

 # Parse.
 $obj->parse($pyx);

 # Output:
 # [ bar ] (E: 0000, A: 0001) http://bar.foo
 # [ foo ] (E: 0001, A: 0001) http://foo.bar
 # [ xml ] (E: 0000, A: 0001)

=head1 DEPENDENCIES

L<Class::Utils>,
L<Error::Pure>,
L<List::Util>,
L<PYX::Parser>,
L<Readonly>.

=head1 SEE ALSO

=over

=item L<PYX>

A perl module for PYX handling.

=item L<Task::PYX>

Install the PYX modules.

=back

=head1 REPOSITORY

L<https://github.com/tupinek/PYX-XMLSchema-List>

=head1 AUTHOR

Michal Špaček L<mailto:skim@cpan.org>

L<http://skim.cz>

=head1 LICENSE AND COPYRIGHT

 © 2015 Michal Špaček
 BSD 2-Clause License

=head1 VERSION

0.04

=cut
