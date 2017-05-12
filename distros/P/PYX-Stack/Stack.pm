package PYX::Stack;

# Pragmas.
use strict;
use warnings;

# Modules.
use Class::Utils qw(set_params);
use Error::Pure qw(err);
use PYX::Parser;

# Version.
our $VERSION = 0.04;

# Constructor.
sub new {
	my ($class, @params) = @_;
	my $self = bless {}, $class;

	# Check bad end of element.
	$self->{'bad_end'} = 0;

	# Output handler.
	$self->{'output_handler'} = \*STDOUT;

	# Verbose.
	$self->{'verbose'} = 0;

	# Process params.
	set_params($self, @params);

	# PYX::Parser object.
	$self->{'_pyx_parser'} = PYX::Parser->new(
		'callbacks' => {
			'end_element' => \&_end_element,
			'start_element' => \&_start_element,
			'final' => \&_final,
		},
		'non_parser_options' => {
			'bad_end' => $self->{'bad_end'},
			'stack' => [],
			'verbose' => $self->{'verbose'},
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
	} elsif ($pyx_parser_obj->{'non_parser_options'}->{'bad_end'}) {
		err 'Bad end of element.',
			'Element', $elem;
	}
	if ($pyx_parser_obj->{'non_parser_options'}->{'verbose'}
		&& @{$stack_ar} > 0) {

		my $out = $pyx_parser_obj->{'output_handler'};
		print {$out} join('/', @{$stack_ar}), "\n";
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
	return;
}

# Start of element.
sub _start_element {
	my ($pyx_parser_obj, $elem) = @_;
	my $stack_ar = $pyx_parser_obj->{'non_parser_options'}->{'stack'};
	my $out = $pyx_parser_obj->{'output_handler'};
	push @{$stack_ar}, $elem;
	if ($pyx_parser_obj->{'non_parser_options'}->{'verbose'}) {
		print {$out} join('/', @{$stack_ar}), "\n";
	}
	return;
}

1;

__END__

=pod

=encoding utf8

=head1 NAME

PYX::Stack - Processing PYX data or file and process element stack.

=head1 SYNOPSIS

 use PYX::Stack;
 my $obj = PYX::Stack->new(%parameters);
 $obj->parse($pyx, $out);
 $obj->parse_file($input_file, $out);
 $obj->parse_handle($input_file_handler, $out);

=head1 METHODS

=over 8

=item C<new(%parameters)>

 Constructor.

=over 8

=item * C<bad_end>

 Check bad end of element.
 If set, print error on unopened end of element.
 Default value is 0.

=item * C<output_handler>

 Output handler.
 Default value is \*STDOUT.

=item * C<verbose>

 Verbose flag.
 If set, each start element prints information to 'output_handler'.
 Default value is 0.

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

 # Pragmas.
 use strict;
 use warnings;

 # Modules.
 use PYX::Stack;

 # Example data.
 my $pyx = <<'END';
 (begin
 (middle
 (end
 -data
 )end
 )middle
 )begin
 END

 # PYX::Stack object.
 my $obj = PYX::Stack->new(
         'verbose' => 1,
 );

 # Parse.
 $obj->parse($pyx);

 # Output:
 # begin
 # begin/middle
 # begin/middle/end
 # begin/middle
 # begin

=head1 EXAMPLE2

 # Pragmas.
 use strict;
 use warnings;

 # Modules.
 use Error::Pure;
 use PYX::Stack;

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

 # PYX::Stack object.
 my $obj = PYX::Stack->new;

 # Parse.
 $obj->parse($pyx);

 # Output:
 # PYX::Stack: Stack has some elements.

=head1 EXAMPLE3

 # Pragmas.
 use strict;
 use warnings;

 # Modules.
 use Error::Pure;
 use PYX::Stack;

 # Error output.
 $Error::Pure::TYPE = 'PrintVar';

 # Example data.
 my $pyx = <<'END';
 (begin
 (middle
 -data
 )end
 )middle
 )begin
 END

 # PYX::Stack object.
 my $obj = PYX::Stack->new(
         'bad_end' => 1,
 );

 # Parse.
 $obj->parse($pyx);

 # Output:
 # PYX::Stack: Bad end of element.
 # Element: end

=head1 DEPENDENCIES

L<Class::Utils>,
L<Error::Pure>,
L<PYX::Parser>.

=head1 SEE ALSO

=over

=item L<Task::PYX>

Install the PYX modules.

=back

=head1 REPOSITORY

L<https://github.com/tupinek/PYX-Stack>

=head1 AUTHOR

Michal Špaček L<mailto:skim@cpan.org>

L<http://skim.cz>

=head1 LICENSE AND COPYRIGHT

 © 2011-2015 Michal Špaček
 BSD 2-Clause License

=head1 VERSION

0.04

=cut
