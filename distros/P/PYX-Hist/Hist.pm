package PYX::Hist;

use strict;
use warnings;

use Class::Utils qw(set_params);
use Error::Pure qw(err);
use List::Util qw(reduce);
use PYX::Parser;

our $VERSION = 0.08;

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
			'end_element' => \&_end_element,
			'final' => \&_final,
			'start_element' => \&_start_element,
		},
		'non_parser_options' => {
			'hist' => {},
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

# End of element.
sub _end_element {
	my ($pyx_parser_obj, $elem) = @_;
	my $stack_ar = $pyx_parser_obj->{'non_parser_options'}->{'stack'};
	if ($stack_ar->[-1] eq $elem) {
		pop @{$stack_ar};
	} else {
		err 'Bad end of element.',
			'Element', $elem;
	}
	return;
}

# Finalize.
sub _final {
	my $pyx_parser_obj = shift;
	my $stack_ar = $pyx_parser_obj->{'non_parser_options'}->{'stack'};
	if (@{$stack_ar} > 0) {
		err 'Stack has some elements.';
	}
	my $hist_hr = $pyx_parser_obj->{'non_parser_options'}->{'hist'};
	my $max_len = length reduce { length($a) > length($b) ? $a : $b }
		keys %{$hist_hr};
	my $out = $pyx_parser_obj->{'output_handler'};
	foreach my $key (sort keys %{$hist_hr}) {
		printf {$out} "[ %-${max_len}s ] %s\n", $key, $hist_hr->{$key};
	}
	return;
}

# Start of element.
sub _start_element {
	my ($pyx_parser_obj, $elem) = @_;
	my $stack_ar = $pyx_parser_obj->{'non_parser_options'}->{'stack'};
	push @{$stack_ar}, $elem;
	if (! $pyx_parser_obj->{'non_parser_options'}->{'hist'}->{$elem}) {
		$pyx_parser_obj->{'non_parser_options'}->{'hist'}->{$elem} = 1;
	} else {
		$pyx_parser_obj->{'non_parser_options'}->{'hist'}->{$elem}++;
	}
	return;
}

1;

__END__

=pod

=encoding utf8

=head1 NAME

PYX::Hist - Processing PYX data or file and print histogram.

=head1 SYNOPSIS

 use PYX::Hist;

 my $obj = PYX::Hist->new(%parameters);
 $obj->parse($pyx, $out);
 $obj->parse_file($input_file, $out);
 $obj->parse_handler($input_file_handler, $out);

=head1 METHODS

=head2 C<new>

 my $obj = PYX::Hist->new(%parameters);

Constructor.

=over 8

=item * C<output_handler>

 Output handler.
 Default value is \*STDOUT.

=back

Returns instance of object.

=head2 C<parse>

 $obj->parse($pyx, $out);

Parse PYX text or array of PYX text and print histogram of PYX input.
If C<$out> not present, use 'output_handler'.

Returns undef.

=head2 C<parse_file>

 $obj->parse_file($input_file, $out);

Parse file with PYX data and print histogram of PYX input.
If C<$out> not present, use 'output_handler'.

Returns undef.

=head2 C<parse_handler>

 $obj->parse_handler($input_file_handler, $out);

Parse PYX handler and print histogram of PYX input.
If C<$out> not present, use 'output_handler'.

Returns undef.

=head1 ERRORS

 new():
         From Class::Utils::set_params():
                 Unknown parameter '%s'.

 parse():
         Bad end of element.
                 Element: %s
         Stack has some elements.

 parse_file():
         Bad end of element.
                 Element: %s
         Stack has some elements.

 parse_handler():
         Bad end of element.
                 Element: %s
         Stack has some elements.

=head1 EXAMPLE1

=for comment filename=hist.pl

 use strict;
 use warnings;

 use PYX::Hist;

 # Example data.
 my $pyx = <<'END';
 (begin
 (middle
 (end
 -data
 )end
 (end
 -data
 )end
 )middle
 )begin
 END

 # PYX::Hist object.
 my $obj = PYX::Hist->new;

 # Parse.
 $obj->parse($pyx);

 # Output:
 # [ begin  ] 1
 # [ end    ] 2
 # [ middle ] 1

=head1 EXAMPLE2

=for comment filename=hist_with_bad_end_element.pl

 use strict;
 use warnings;

 use Error::Pure;
 use PYX::Hist;

 # Error output.
 $Error::Pure::TYPE = 'PrintVar';

 # Example data.
 my $pyx = <<'END';
 (begin
 (middle
 (end
 -data
 )middle
 )begin
 END

 # PYX::Hist object.
 my $obj = PYX::Hist->new;

 # Parse.
 $obj->parse($pyx);

 # Output:
 # PYX::Hist: Bad end of element.
 # Element: middle

=head1 EXAMPLE3

=for comment filename=hist_with_missing_element.pl

 use strict;
 use warnings;

 use Error::Pure;
 use PYX::Hist;

 # Error output.
 $Error::Pure::TYPE = 'PrintVar';

 # Example data.
 my $pyx = <<'END';
 (begin
 (middle
 (end
 -data
 )end
 )middle
 END

 # PYX::Hist object.
 my $obj = PYX::Hist->new;

 # Parse.
 $obj->parse($pyx);

 # Output:
 # PYX::Hist: Stack has some elements.

=head1 DEPENDENCIES

L<Class::Utils>,
L<Error::Pure>,
L<List::Util>,
L<PYX::Parser>.

=head1 SEE ALSO

=over

=item L<Task::PYX>

Install the PYX modules.

=back

=head1 REPOSITORY

L<https://github.com/michal-josef-spacek/PYX-Hist>

=head1 AUTHOR

Michal Josef Špaček L<mailto:skim@cpan.org>

L<http://skim.cz>

=head1 LICENSE AND COPYRIGHT

© 2014-2023 Michal Josef Špaček

BSD 2-Clause License

=head1 VERSION

0.08

=cut
