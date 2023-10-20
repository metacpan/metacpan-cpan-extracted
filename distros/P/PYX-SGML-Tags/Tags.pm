package PYX::SGML::Tags;

use strict;
use warnings;

use Class::Utils qw(set_params);
use Error::Pure qw(err);
use PYX::Parser;
use PYX::Utils;
use Tags::Output::Raw;

our $VERSION = 0.10;

# Constructor.
sub new {
	my ($class, @params) = @_;

	my $self = bless {}, $class;

	# Input encoding.
	$self->{'input_encoding'} = 'utf-8';

	# Input 'Tags' item callback.
	$self->{'input_tags_item_callback'} = undef;

	# Output encoding.
	$self->{'output_encoding'} = 'utf-8';

	# Tags object.
	$self->{'tags'} = undef;

	# Process params.
	set_params($self, @params);

	if (! defined $self->{'tags'}) {
		$self->{'tags'} = Tags::Output::Raw->new(
			'input_tags_item_callback'
				=> $self->{'input_tags_item_callback'},
			'output_encoding' => $self->{'output_encoding'},
			'output_handler' => \*STDOUT,
		);
	}

	# Check for Tags::Output object.
	if (! $self->{'tags'}->isa('Tags::Output')) {
		err "Bad 'Tags::Output::*' object.";
	}

	# PYX::Parser object.
	$self->{'pyx_parser'} = PYX::Parser->new(
		'callbacks' => {
			'attribute' => \&_attribute,
			'comment' => \&_comment,
			'data' => \&_data,
			'end_element' => \&_end_element,
			'instruction' => \&_instruction,
			'start_element' => \&_start_element,
		},
		'input_encoding' => $self->{'input_encoding'},
		'non_parser_options' => {
			'tags' => $self->{'tags'},
		},
	);

	# Object.
	return $self;
}

# Parse pyx text or array of pyx text.
sub parse {
	my ($self, $pyx, $out) = @_;

	$self->{'pyx_parser'}->parse($pyx, $out);
	$self->{'tags'}->flush;

	return;
}

# Parse file with pyx text.
sub parse_file {
	my ($self, $file, $out) = @_;

	$self->{'pyx_parser'}->parse_file($file, $out);
	$self->{'tags'}->flush;

	return;
}

# Parse from handler.
sub parse_handler {
	my ($self, $input_file_handler, $out) = @_;

	$self->{'pyx_parser'}->parse_handler($input_file_handler, $out);
	$self->{'tags'}->flush;

	return;
}

sub finalize {
	my $self = shift;

	$self->{'tags'}->finalize;

	return;
}

# Process start of element.
sub _start_element {
	my ($self, $elem) = @_;

	my $tags = $self->{'non_parser_options'}->{'tags'};
	$tags->put(['b', $elem]);

	return;
}

# Process end of element.
sub _end_element {
	my ($self, $elem) = @_;

	my $tags = $self->{'non_parser_options'}->{'tags'};
	$tags->put(['e', $elem]);

	return;
}

# Process data.
sub _data {
	my ($self, $data) = @_;

	my $tags = $self->{'non_parser_options'}->{'tags'};
	$tags->put(['d', PYX::Utils::encode($data)]);

	return;
}

# Process attribute.
sub _attribute {
	my ($self, $attr, $value) = @_;

	my $tags = $self->{'non_parser_options'}->{'tags'};
	$tags->put(['a', $attr, $value]);

	return;
}

# Process instruction tag.
sub _instruction {
	my ($self, $target, $code) = @_;

	my $tags = $self->{'non_parser_options'}->{'tags'};
	$tags->put(['i', $target, $code]);

	return;
}

# Process comments.
sub _comment {
	my ($self, $comment) = @_;

	my $tags = $self->{'non_parser_options'}->{'tags'};
	$tags->put(['c', PYX::Utils::encode($comment)]);

	return;
}

1;

__END__

=pod

=encoding utf8

=head1 NAME

PYX::SGML::Tags - Processing PYX data or file and write as SGML via Tags.

=head1 SYNOPSIS

 use PYX::SGML::Tags;

 my $obj = PYX::SGML::Tags->new(%parameters);
 $obj->parse($pyx, $out);
 $obj->parse_file($input_file, $out);
 $obj->parse_handler($input_file_handler, $out);
 $obj->finalize;

=head1 METHODS

=head2 C<new>

 my $obj = PYX::SGML::Tags->new(%parameters);

Constructor.

=over 8

=item * C<input_encoding>

Input encoding for parse_file() and parse_handler() usage.

Default value is 'utf-8'.

=item * C<input_tags_item_callback>

Input 'Tags' item callback.
This callback is for Tags::Output::* constructor parameter 'input_tags_item_callback'.

Default value is undef.

=item * C<output_encoding>

Output encoding.

Default value is 'utf-8'.

=item * C<tags>

Tags object.
Can be any of Tags::Output::* objects.
Default value is C<Tags::Output::Raw->new('output_handler' => \*STDOUT)>.
It's required.

=back

Returns instance of class.

=head2 C<parse>

 $obj->parse($pyx, $out);

Parse PYX text or array of PYX text.
Output is serialization to SGML by Tags::Output::* module.
If C<$out> not present, use 'output_handler'.

Returns undef.

=head2 C<parse_file>

 $obj->parse_file($input_file, $out);

Parse file with PYX data.
C<$input_file> file is decoded by 'input_encoding'.
Output is serialization to SGML.
If C<$out> not present, use 'output_handler'.

Returns undef.

=head2 C<parse_handler>

 $obj->parse_handler($input_file_handler, $out);

Parse PYX handler.
C<$input_file_handler> handler is decoded by 'input_encoding'.
Output is serialization to SGML.
If C<$out> not present, use 'output_handler'.

Returns undef.

=head2 C<finalize>

 $obj->finalize;

 Finalize opened tags, if exists.
 Returns undef.

=head1 ERRORS

 new():
         Bad 'Tags::Output::*' object.
         From Class::Utils::set_params():
                 Unknown parameter '%s'.

 parse():
         From PYX::Parser::parse():
                 Bad PYX line '%s'.
         From Tags::Output::Raw::flush():
                 Cannot write to output handler.

 parse_file():
         From PYX::Parser::parse_file():
                 Bad PYX line '%s'.
                 No input handler.
         From Tags::Output::Raw::flush():
                 Cannot write to output handler.

 parse_handler():
         From PYX::Parser::parse_handler():
                 Bad PYX line '%s'.
                 No input handler.
         From Tags::Output::Raw::flush():
                 Cannot write to output handler.

=head1 EXAMPLE1

=for comment filename=simple_element_raw.pl

 use strict;
 use warnings;

 use PYX::SGML::Tags;

 # Input.
 my $pyx = <<'END';
 (element
 -data
 )element
 END

 # Object.
 my $obj = PYX::SGML::Tags->new;

 # Process.
 $obj->parse($pyx);
 print "\n";

 # Output:
 # <element>data</element>

=head1 EXAMPLE2

=for comment filename=simple_element_indent.pl

 use strict;
 use warnings;

 use PYX::SGML::Tags;
 use Tags::Output::Indent;

 # Input.
 my $pyx = <<'END';
 (element
 -data
 )element
 END

 # Object.
 my $obj = PYX::SGML::Tags->new(
         'tags' => Tags::Output::Indent->new(
                 'output_handler' => \*STDOUT,
         ),
 );

 # Process.
 $obj->parse($pyx);
 print "\n";

 # Output:
 # <element>data</element>

=head1 EXAMPLE3

=for comment filename=simple_element_callback.pl

 use strict;
 use warnings;

 use PYX::SGML::Tags;
 use Tags::Output::Indent;

 # Input.
 my $pyx = <<'END';
 (element
 -data
 )element
 END

 # Object.
 my $obj = PYX::SGML::Tags->new(
         'input_tags_item_callback' => sub {
                 my $tags_ar = shift;
                 print '[ '.$tags_ar->[0].' ]'."\n";
                 return;
         },
 );

 # Process.
 $obj->parse($pyx);
 print "\n";

 # Output:
 # [ b ]
 # [ d ]
 # [ e ]
 # <element>data</element>

=head1 DEPENDENCIES

L<Class::Utils>,
L<Error::Pure>,
L<PYX::Parser>,
L<PYX::Utils>,
L<Tags::Output::Raw>.

=head1 SEE ALSO

=over

=item L<Task::PYX>

Install the PYX modules.

=back

=head1 REPOSITORY

L<https://github.com/michal-josef-spacek/PYX-SGML-Tags>

=head1 AUTHOR

Michal Josef Špaček L<mailto:skim@cpan.org>

L<http://skim.cz>

=head1 LICENSE AND COPYRIGHT

© 2011-2023 Michal Josef Špaček

BSD 2-Clause License

=head1 VERSION

0.10

=cut
