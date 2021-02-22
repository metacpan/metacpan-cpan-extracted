package PYX::Parser;

use strict;
use warnings;

use Class::Utils qw(set_params);
use Encode qw(decode);
use Error::Pure qw(err);
use Readonly;

# Constants.
Readonly::Scalar my $EMPTY_STR => q{};

our $VERSION = 0.08;

# Constructor.
sub new {
	my ($class, @params) = @_;
	my $self = bless {}, $class;

	# Parse callbacks.
	$self->{'callbacks'} = {
		'attribute' => undef,
		'comment' => undef,
		'data' => undef,
		'end_element' => undef,
		'final' => undef,
		'init' => undef,
		'instruction' => undef,
		'rewrite' => undef,
		'start_element' => undef,
		'other' => undef,
	},

	# Input encoding.
	$self->{'input_encoding'} = 'utf-8';

	# Non parser options.
	$self->{'non_parser_options'} = {};

	# Output encoding.
	$self->{'output_encoding'} = 'utf-8';

	# Output handler.
	$self->{'output_handler'} = \*STDOUT;

	# Output rewrite.
	$self->{'output_rewrite'} = 0;

	# Process params.
	set_params($self, @params);

	# Check output handler.
	if (defined $self->{'output_handler'}
		&& ref $self->{'output_handler'} ne 'GLOB') {

		err 'Bad output handler.';
	}

	# Processing line.
	$self->{'_line'} = $EMPTY_STR;

	# Object.
	return $self;
}

# Get actual parsing line.
sub line {
	my $self = shift;

	return $self->{'_line'};
}

# Parse PYX text or array of PYX text.
sub parse {
	my ($self, $pyx, $out) = @_;

	if (! defined $out) {
		$out = $self->{'output_handler'};
	}

	# Input data.
	my @text;
	if (ref $pyx eq 'ARRAY') {
		@text = @{$pyx};
	} else {
		@text = split /\n/ms, $pyx;
	}

	# Parse.
	if ($self->{'callbacks'}->{'init'}) {
		&{$self->{'callbacks'}->{'init'}}($self);
	}
	foreach my $line (@text) {
		$self->_parse($line, $out);
	}
	if ($self->{'callbacks'}->{'final'}) {
		&{$self->{'callbacks'}->{'final'}}($self);
	}

	return;
}

# Parse file with PYX data.
sub parse_file {
	my ($self, $input_file, $out) = @_;

	open my $inf, '<', $input_file;
	$self->parse_handler($inf, $out);
	close $inf;

	return;
}

# Parse PYX handler.
sub parse_handler {
	my ($self, $input_file_handler, $out) = @_;

	if (! $input_file_handler || ref $input_file_handler ne 'GLOB') {
		err 'No input handler.';
	}
	if (! defined $out) {
		$out = $self->{'output_handler'};
	}
	if ($self->{'callbacks'}->{'init'}) {
		&{$self->{'callbacks'}->{'init'}}($self);
	}
	while (my $line = <$input_file_handler>) {
		chomp $line;
		$line = decode($self->{'input_encoding'}, $line);
		$self->_parse($line, $out);
	}
	if ($self->{'callbacks'}->{'final'}) {
		&{$self->{'callbacks'}->{'final'}}($self);
	}

	return;
}

# Parse text string.
sub _parse {
	my ($self, $line, $out) = @_;

	$self->{'_line'} = $line;
	my ($type, $value) = $line =~ m/\A([A()\?\-_])(.*)\Z/;
	if (! $type) {
		$type = 'X';
	}

	# Attribute.
	if ($type eq 'A') {
		my ($att, $attval) = $line =~ m/\AA([^\s]+)\s*(.*)\Z/;
		$self->_is_sub('attribute', $out, $att, $attval);

	# Start of element.
	} elsif ($type eq '(') {
		$self->_is_sub('start_element', $out, $value);

	# End of element.
	} elsif ($type eq ')') {
		$self->_is_sub('end_element', $out, $value);

	# Data.
	} elsif ($type eq '-') {
		$self->_is_sub('data', $out, $value);

	# Instruction.
	} elsif ($type eq '?') {
		my ($target, $data) = $line =~ m/\A\?([^\s]+)\s*(.*)\Z/;
		$self->_is_sub('instruction', $out, $target, $data);

	# Comment.
	} elsif ($type eq '_') {
		$self->_is_sub('comment', $out, $value);

	# Others.
	} else {
		if ($self->{'callbacks'}->{'other'}) {
			&{$self->{'callbacks'}->{'other'}}($self, $line);
		} else {
			err "Bad PYX line '$line'.";
		}
	}

	return;
}

# Helper to defined callbacks.
sub _is_sub {
	my ($self, $key, $out, @values) = @_;

	# Callback with name '$key'.
	if (exists $self->{'callbacks'}->{$key}
		&& ref $self->{'callbacks'}->{$key} eq 'CODE') {

		&{$self->{'callbacks'}->{$key}}($self, @values);

	# Rewrite callback.
	} elsif (exists $self->{'callbacks'}->{'rewrite'}
		&& ref $self->{'callbacks'}->{'rewrite'} eq 'CODE') {

		&{$self->{'callbacks'}->{'rewrite'}}($self, $self->{'_line'});

	# Raw output to output file handler.
	} elsif ($self->{'output_rewrite'}) {
		my $encoded_line = Encode::encode(
			$self->{'output_encoding'},
			$self->{'_line'},
		);
		print {$out} $encoded_line, "\n";
	}

	return;
}

1;

__END__

=pod

=encoding utf8

=head1 NAME

PYX::Parser - PYX parser with callbacks.

=head1 SYNOPSIS

 use PYX::Parser;

 my $obj = PYX::Parser->new(%parameters);
 my $line = $obj->line;
 $obj->parse($pyx, $out);
 $obj->parse_file($input_file, $out);
 $obj->parse_handle($input_file_handler, $out);

=head1 METHODS

=head2 C<new>

 my $obj = PYX::Parser->new(%parameters);

Constructor.

=over 8

=item * C<callbacks>

 Callbacks.

=over 8

=item * C<attribute>

 Attribute callback.
 Default value is undef.

=item * C<comment>

 Comment callback.
 Default value is undef.

=item * C<data>

 Data callback.
 Default value is undef.

=item * C<end_element>

 End of element callback.
 Default value is undef.

=item * C<final>

 Final callback.
 Default value is undef.

=item * C<init>

 Init callback.
 Default value is undef.

=item * C<instruction>

 Instruction callback.
 Default value is undef.

=item * C<rewrite>

 Rewrite callback.
 Callback is used on every line.
 Default value is undef.

=item * C<start_element>

 Start of element callback.
 Default value is undef.

=item * C<other>

 Other Callback.
 Default value is undef.

=back

=item * C<input_encoding>

 Input encoding for parse_file() and parse_handler() usage.
 Default value is 'utf-8'.

=item * C<non_parser_options>

 Non parser options.
 Default value is blank reference to hash.

=item * C<output_encoding>

 Output encoding.
 Default value is 'utf-8'.

=item * C<output_handler>

 Output handler.
 Default value is \*STDOUT.

=item * C<output_rewrite>

 Output rewrite.
 Default value is 0.

=back

=head2 C<line>

 my $line = $obj->line;

Get actual parsing line.

Returns string.

=head2 C<parse>

 $obj->parse($pyx, $out);

Parse PYX text or array of PYX text.
If C<$out> not present, use 'output_handler'.

Returns undef.

=head2 C<parse_file>

 $obj->parse_file($input_file, $out);

Parse file with PYX data.
C<$input_file> file is decoded by 'input_encoding'.
If C<$out> not present, use 'output_handler'.

Returns undef.

=head2 C<parse_handler>

 $obj->parse_handle($input_file_handler, $out);

Parse PYX handler.
C<$input_file_handler> handler is decoded by 'input_encoding'.
If C<$out> not present, use 'output_handler'.

Returns undef.

=head1 ERRORS

 new():
         Bad output handler.
         From Class::Utils::set_params():
                 Unknown parameter '%s'.

 parse():
         Bad PYX line '%s'.

 parse_file():
         Bad PYX line '%s'.
         No input handler.

 parse_handler():
         Bad PYX line '%s'.
         No input handler.

=head1 EXAMPLE

 use strict;
 use warnings;

 use PYX::Parser;

 # Open file.
 my $file_handler = \*STDIN;
 my $file = $ARGV[0];
 if ($file) {
        if (! open(INF, '<', $file)) {
                die "Cannot open file '$file'.";
        }
        $file_handler = \*INF;
 }

 # PYX::Parser object.
 my $parser = PYX::Parser->new(
	'callbacks' => {
        	'start_element' => \&start_element,
        	'end_element' => \&end_element,
	},
 );
 $parser->parse_handler($file_handler);

 # Close file.
 if ($file) {
        close(INF);
 }

 # Start element callback.
 sub start_element {
        my ($self, $elem) = @_;
        print "Start of element '$elem'.\n";
        return;
 }

 # End element callback.
 sub end_element {
        my ($self, $elem) = @_;
        print "End of element '$elem'.\n";
        return;
 }

=head1 DEPENDENCIES

L<Class::Utils>,
L<Encode>,
L<Error::Pure>,
L<Readonly>.

=head1 SEE ALSO

=over

=item L<Task::PYX>

Install the PYX modules.

=back

=head1 REPOSITORY

L<https://github.com/michal-josef-spacek/PYX>

=head1 AUTHOR

Michal Josef Špaček L<mailto:skim@cpan.org>

L<http://skim.cz>

=head1 LICENSE AND COPYRIGHT

© 2005-2021 Michal Josef Špaček

BSD 2-Clause License

=head1 VERSION

0.08

=cut
