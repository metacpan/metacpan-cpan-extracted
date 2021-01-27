package SGML::PYX;

use strict;
use warnings;

use Class::Utils qw(set_params);
use Encode qw(decode_utf8 encode_utf8);
use Error::Pure qw(err);
use Tag::Reader::Perl;
use PYX qw(comment end_element char instruction start_element);
use PYX::Utils qw(decode entity_decode);

our $VERSION = 0.07;

# Constructor.
sub new {
	my ($class, @params) = @_;

	# Create object.
	my $self = bless {}, $class;

	# Output callback.
	$self->{'output'} = sub {
		my (@data) = @_;

		print join "\n", map { encode_utf8($_) } @data;
		print "\n";

		return;
	};

	# Process params.
	set_params($self, @params);

	# Object.
	$self->{'_tag_reader'} = Tag::Reader::Perl->new;

	# Object.
	return $self;
}

# Parse file.
sub parsefile {
	my ($self, $sgml_file) = @_;

	# Set file.
	$self->{'_tag_reader'}->set_file($sgml_file);

	# Process.
	while (my ($data, $tag_type, $line, $column)
		= $self->{'_tag_reader'}->gettoken) {

		# Decode data to internal form.
		$data = decode_utf8($data);

		# Data.
		if ($tag_type eq '!data') {
			$self->{'output'}->(char(decode(entity_decode($data))));

		# Comment.
		} elsif ($tag_type eq '!--') {
			$data =~ s/^<!--//ms;
			$data =~ s/-->$//ms;
			$self->{'output'}->(comment($data));

		# End of element.
		} elsif ($tag_type =~ m/^\//ms) {
			my $element = $data;
			$element =~ s/^<\///ms;
			$element =~ s/>$//ms;
			$self->{'output'}->(end_element($element));

		# Begin of element.
		} elsif ($tag_type =~ m/^\w+/ms) {
			$data =~ s/^<//ms;
			$data =~ s/>$//ms;
			my $end = 0;
			if ($data =~ s/\/$//ms) {
				$end = 1;
			}
			(my $element, $data) = ($data =~ m/^([^\s]+)\s*(.*)$/ms);
			my @attrs = $self->_parse_attributes($data);
			$self->{'output'}->(start_element($element, @attrs));
			if ($end) {
				$self->{'output'}->(end_element($element));
			}

		# Doctype.
		} elsif ($tag_type eq '!doctype') {
			# Nop.

		# CData.
		} elsif ($tag_type eq '![cdata[') {
			$data =~ s/^<!\[[cC][dD][aA][tT][aA]\[//ms;
			$data =~ s/\]\]>$//ms;
			$self->{'output'}->(char(decode(entity_decode($data))));

		# Instruction.
		} elsif ($tag_type =~ m/^\?/ms) {
			$data =~ s/^<\?//ms;
			$data =~ s/\s*\?>$//ms;
			my ($target, $code) = split m/\s+/ms, $data, 2;
			$self->{'output'}->(instruction($target, $code));

		} else {
			err "Unsupported tag type '$tag_type'.";
		}
	}

	return;
}

# Parse attributes.
sub _parse_attributes {
	my ($self, $data) = @_;

	my $original_data = $data;
	my @attrs;
	while ($data) {

		# <example par="val"> or <example par = "val">
		if ($data =~ m/^([_\w:][\.\-\w:]*)\s*=\s*"(.*?)"\s*(.*)$/ms

			# <example par='val'> or <example par = 'val'>
			|| $data =~ m/^([_\w:][\.\-\w:]*)\s*=\s*'(.*?)'\s*(.*)$/ms

			# <example par=foo> or <example par = foo >.
			|| $data =~ m/^([_\w:][\.\-\w:]*)\s*=\s*([^\s]+)\s*(.*)$/ms) {

			push @attrs, $1, $2;
			$data = $3;

		# <example par = >
		} elsif ($data =~ m/^([_\w:][\.\-\w:]*)\s*=\s*$/ms) {
			push @attrs, $1, '';
			$data = '';

		# <example checked>
		} elsif ($data =~ m/^([_\w:][\.\-\w:]*)\s*(.*)$/ms) {
			push @attrs, $1, $1;
			$data = $2;
		} else {
			err 'Problem with attribute parsing.',
				'data', $original_data;
		}
	}

	return (@attrs);
}

1;

__END__

=pod

=encoding utf8

=head1 NAME

SGML::PYX - Convertor between SGML and PYX.

=head1 SYNOPSIS

 use SGML::PYX;

 my $obj = SGML::PYX->new(%params);
 $obj->parsefile($sgml_file);

=head1 METHODS

=head2 C<new>

 my $obj = SGML::PYX->new(%params);

Constructor.

Returns instance of object.

=over 8

=item * C<output>

 Output callback, which prints output PYX code.
 Default value is subroutine:
         my (@data) = @_;
         print join "\n", map { encode_utf8($_) } @data;
         print "\n";
         return;

=back

=head2 C<parsefile>

 $obj->parsefile($sgml_file);

Parse input SGML file and convert to PYX output.

Returns undef.

=head1 ERRORS

 new():
         From Class::Utils::set_params():
                 Unknown parameter '%s'.

 parsefile():
         Unsupported tag type '%s'.
         Problem with attribute parsing.
                 data: %s

=head1 EXAMPLE

 use strict;
 use warnings;

 use File::Temp qw(tempfile);
 use IO::Barf qw(barf);
 use SGML::PYX;

 # Input file.
 my (undef, $input_file) = tempfile();
 my $input = <<'END';
 <html><head><title>Foo</title></head><body><div /></body></html>
 END
 barf($input_file, $input);

 # Object.
 my $obj = SGML::PYX->new;

 # Parse file.
 $obj->parsefile($input_file);

 # Output:
 # (html
 # (head
 # (title
 # -Foo
 # )title
 # )head
 # (body
 # (div
 # )div
 # )body
 # )html
 # -\n

=head1 DEPENDENCIES

L<Class::Utils>,
L<Encode>,
L<Error::Pure>,
L<Tag::Reader::Perl>,
L<PYX>,
L<PYX::Utils>.

=head1 SEE ALSO

=over

=item L<Task::PYX>

Install the PYX modules.

=back

=head1 REPOSITORY

L<https://github.com/michal-josef-spacek/SGML-PYX>

=head1 AUTHOR

Michal Josef Špaček L<mailto:skim@cpan.org>

L<http://skim.cz>

=head1 LICENSE AND COPYRIGHT

© Michal Josef Špaček 2015-2021

BSD 2-Clause License

=head1 VERSION

0.07

=cut
