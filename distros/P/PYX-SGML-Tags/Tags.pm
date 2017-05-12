package PYX::SGML::Tags;

# Pragmas.
use strict;
use warnings;

# Modules.
use Class::Utils qw(set_params);
use Error::Pure qw(err);
use PYX::Parser;
use PYX::Utils qw(encode);
use Tags::Output::Raw;

# Version.
our $VERSION = 0.02;

# Constructor.
sub new {
	my ($class, @params) = @_;
	my $self = bless {}, $class;

	# Input encoding.
	$self->{'input_encoding'} = 'utf-8';

	# Tags object.
	$self->{'tags'} = Tags::Output::Raw->new(
		'output_handler' => \*STDOUT,
	);

	# Process params.
	set_params($self, @params);

	# Check for Tags::Output object.
	if (! $self->{'tags'}
		|| ! $self->{'tags'}->isa('Tags::Output')) {

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
	$tags->put(['d', encode($data)]);
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
	$tags->put(['c', encode($comment)]);
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
 $obj->parse_handle($input_file_handler, $out);
 $obj->finalize;

=head1 METHODS

=over 8

=item C<new()>

Constructor.

=over 8

=item * C<input_encoding>

 Input encoding.
 Default value is 'utf-8'.

=item * C<tags>

 Tags object.
 Can be any of Tags::Output::* objects.
 Default value is Tags::Output::Raw->new('output_handler' => \*STDOUT).
 It's required.

=back

=item C<parse($pyx[, $out])>

 Parse PYX text or array of PYX text.
 Output is serialization to SGML by Tags::Output::* module.
 If $out not present, use 'output_handler'.
 Returns undef.

=item C<parse_file($input_file[, $out])>

 Parse file with PYX data.
 Output is serialization to SGML.
 If $out not present, use 'output_handler'.
 Returns undef.

=item C<parse_handler($input_file_handler[, $out])>

 Parse PYX handler.
 Output is serialization to SGML.
 If $out not present, use 'output_handler'.
 Returns undef.

=item C<finalize()>

 Finalize opened tags, if exists.
 Returns undef.

=back

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

=head1 EXAMPLE

 # Pragmas.
 use strict;
 use warnings;

 # Modules.
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

L<https://github.com/tupinek/PYX-SGML-Tags>

=head1 AUTHOR

Michal Špaček L<mailto:skim@cpan.org>

L<http://skim.cz>

=head1 LICENSE AND COPYRIGHT

 © 2011-2016 Michal Špaček
 BSD 2-Clause License

=head1 VERSION

0.02

=cut
