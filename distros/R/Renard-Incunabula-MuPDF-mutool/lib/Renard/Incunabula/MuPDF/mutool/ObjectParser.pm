use Renard::Incunabula::Common::Setup;
package Renard::Incunabula::MuPDF::mutool::ObjectParser;
# ABSTRACT: Parser for the output of C<mutool show>
$Renard::Incunabula::MuPDF::mutool::ObjectParser::VERSION = '0.004';
use Moo;
use Renard::Incunabula::Common::Types qw(Str Bool File InstanceOf);
use Renard::Incunabula::MuPDF::mutool::DateObject;

use constant {
	TypeString     => 1,
	TypeNumber     => 2,
	TypeBoolean    => 3,
	TypeReference  => 4,
	TypeDictionary => 5,
	TypeDate       => 6,
	TypeArray      => 7,
};

has filename => (
	is => 'ro',
	isa => File,
	coerce => 1,
	required => 1,
);

has string => (
	is => 'ro',
	isa => Str,
	required => 1,
);

has is_toplevel => (
	is => 'ro',
	isa => Bool,
	default => sub { 1 },
);

method BUILD(@) {
	$self->_parse;
};

method _parse() {
	my $text = $self->string;
	chomp($text);
	my @lines = split "\n", $text;

	return unless @lines;

	my $id;
	$id = shift @lines if $self->is_toplevel;

	if( $lines[0] eq '<<' ) {
		my $data = {};
		my $line;
		while( ">>" ne ($line = shift @lines)) {
			next unless $line =~ m|^ \s* / (?<Key>\w+) \s+ (?<Value>.*) $|x;
			$data->{$+{Key}} = Renard::Incunabula::MuPDF::mutool::ObjectParser->new(
				filename => $self->filename,
				string => $+{Value},
				is_toplevel => 0,
			);
		}

		$self->data( $data );
		$self->type( $self->TypeDictionary );
	} else {
		my $scalar = $lines[0];
		if( $scalar =~ m|^(?<Id>\d+) 0 R$| ) {
			$self->data($+{Id});
			$self->type($self->TypeReference);
		} elsif( $scalar =~ m|^(?<Number>\d+)$| ) {
			$self->data($+{Number});
			$self->type($self->TypeNumber);
		} elsif( $scalar =~ m{^(?<Boolean>/True|/False)$} ) {
			$self->data($+{Boolean} eq '/True');
			$self->type($self->TypeBoolean);
		} elsif( $scalar =~ /^\((?<String>.*)\)/ ) {
			my $string = $+{String};
			if( $string =~ /^D:/ ) {
				$self->data(
					Renard::Incunabula::MuPDF::mutool::DateObject->new(
						string => $string
					)
				);
				$self->type($self->TypeDate);
			} else {
				$self->data($self->unescape($string));
				$self->type($self->TypeString);
			}
		} elsif( $scalar =~ /^\[/ ) {
			$self->data('NOT PARSED');
			$self->type($self->TypeArray);
		} else {
			die "unknown PDF type: $scalar"; # uncoverable statement
		}
	}
}

classmethod unescape((Str) $pdf_string ) {
	my $new_string = $pdf_string;
	# TABLE 3.2 Escape sequences in literal strings (pg. 54)
	my %map = (
		'n'  => "\n", # Line feed (LF)
		'r'  => "\r", # Carriage return (CR)
		't'  => "\t", # Horizontal tab (HT)
		'b'  => "\b", # Backspace (BS)
		'f'  => "\f", # Form feed (FF)
		'('  => '(',  # Left parenthesis
		')'  => ')',  # Right parenthesis
		'\\' => '\\', # Backslash
	);

	my $escape_re = qr/
		(?<Char> \\ [nrtbf()\\] )
		|
		(?<Octal> \\ \d{1,3}) # \ddd Character code ddd (octal)
	/x;
	$new_string =~ s/$escape_re/
		exists $+{Char}
		?  $map{ substr($+{Char}, 1) }
		: chr(oct(substr($+{Octal}, 1)))
		/eg;

	$new_string;
}

has data => (
	is => 'rw',
);

has type => (
	is => 'rw',
);

method resolve_key( (Str) $key ) {
	return unless $self->type == $self->TypeDictionary
		&& exists $self->data->{$key};

	my $value = $self->data->{$key};

	while( $value->type == $self->TypeReference ) {
		$value = $self->new_from_reference( $value );
	}

	return $value;
}

method new_from_reference( (InstanceOf['Renard::Incunabula::MuPDF::mutool::ObjectParser']) $ref_obj ) {
	return unless $ref_obj->type == $self->TypeReference;
	my $ref_id = $ref_obj->data;
	$self->new(
		filename => $self->filename,
		string => Renard::Incunabula::MuPDF::mutool::get_mutool_get_object_raw($self->filename, $ref_id),
	);
}


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Renard::Incunabula::MuPDF::mutool::ObjectParser - Parser for the output of C<mutool show>

=head1 VERSION

version 0.004

=head1 EXTENDS

=over 4

=item * L<Moo::Object>

=back

=head1 ATTRIBUTES

=head2 filename

A required C<File> attribute that represents the location of the PDF file.

=head2 string

A required C<Str> attribute that represents the raw string output from
C<mutool show>.

=head2 is_toplevel

An optional C<Bool> attribute that tells whether the data is top-level or not.
This influences the parsing by removing the header from the C<mutool show>
output.

Default: C<true>

=head2 data

A C<Str> containing the parsed data.

=head2 type

Contains the type parsed in the C<data> attribute. See L</Types> for more
information.

=head1 CLASS METHODS

=head2 unescape

  classmethod unescape((Str) $pdf_string )

A class method that unescapes the escape sequences in a PDF string.

Returns a C<Str>.

=head1 METHODS

=head2 BUILD

Initialises the object by parsing the input data.

=head2 resolve_key

  method resolve_key( (Str) $key )

A method that follows the reference IDs contained in the data for the until a
non-reference type is found.

Returns a C<Renard::Incunabula::MuPDF::mutool::ObjectParser> instance.

=head2 new_from_reference

  method new_from_reference( (InstanceOf['Renard::Incunabula::MuPDF::mutool::ObjectParser']) $ref_obj )

Returns an instance of C<Renard::Incunabula::MuPDF::mutool::ObjectParser> that
follows the reference ID contained inside C<$ref_obj>.

=head1 Types

  TypeString
  TypeNumber
  TypeBoolean
  TypeReference
  TypeDictionary
  TypeDate
  TypeArray

The listed types are an enum for the kind of datatypes stored in the C<type>
attribute.

=begin comment

=method _parse

A private method that parses the data in the C<string> attribute.


=end comment

=head1 AUTHOR

Project Renard

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2017 by Project Renard.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
