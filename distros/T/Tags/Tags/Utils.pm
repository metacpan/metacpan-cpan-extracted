package Tags::Utils;

use base qw(Exporter);
use strict;
use warnings;

use Error::Pure qw(err);
use HTML::Entities;
use Readonly;

# Constants.
Readonly::Array our @EXPORT_OK => qw(encode_newline encode_attr_entities
	encode_char_entities);
Readonly::Scalar my $ATTR_CHARS => q{<&"};
Readonly::Scalar my $CHAR_CHARS => q{<&\240};
Readonly::Scalar my $EMPTY_STR => q{};

our $VERSION = 0.07;

# Encode newline in data to '\n' in output.
sub encode_newline {
	my $string = shift;
	$string =~ s/\n/\\n/gms;
	return $string;
}

# Encode '<&"' attribute entities.
sub encode_attr_entities {
	my $data_r = shift;
	if (ref $data_r eq 'SCALAR') {
		${$data_r} = encode_entities(decode_entities(${$data_r}),
			$ATTR_CHARS);
	} elsif (ref $data_r eq 'ARRAY') {
		foreach my $one_data (@{$data_r}) {
			encode_attr_entities(\$one_data);
		}
	} elsif (ref $data_r eq $EMPTY_STR) {
		return encode_entities(decode_entities($data_r), $ATTR_CHARS);
	} else {
		err 'Reference \''.(ref $data_r).'\' doesn\'t supported.';
	}
	return;
}

# Encode '<&NBSP' char entities.
sub encode_char_entities {
	my $data_r = shift;
	if (ref $data_r eq 'SCALAR') {
		${$data_r} = encode_entities(decode_entities(${$data_r}),
			$CHAR_CHARS);
	} elsif (ref $data_r eq 'ARRAY') {
		foreach my $one_data (@{$data_r}) {
			encode_char_entities(\$one_data);
		}
	} elsif (ref $data_r eq $EMPTY_STR) {
		return encode_entities(decode_entities($data_r), $CHAR_CHARS);
	} else {
		err 'Reference \''.(ref $data_r).'\' doesn\'t supported.';
	}
	return;
}

1;

__END__

=pod

=encoding utf8

=head1 NAME

 Tags::Utils - Utils module for Tags.

=head1 SYNOPSIS

 use Tags::Utils qw(encode_newline encode_attr_entities encode_char_entities);
 my $string_with_encoded_newline = encode_newline("foo\nbar");
 my $string_with_encoded_attr_entities = encode_attr_entities('<data & "data"');
 my $string_with_encoded_char_entities = encode_char_entities('<data & data');

=head1 SUBROUTINES

=over 8

=item C<encode_newline($string)>

 Encode newline to '\n' string.

=item C<encode_attr_entities($data_r)>

 Decode all '&..;' strings.
 Encode '<', '&' and '"' entities to '&..;' string.

 $data_r can be:
 - Scalar. Returns encoded scalar.
 - Scalar reference. Returns undef.
 - Array reference of scalars. Returns undef.

=item C<encode_char_entities($data_r)>

 Decode all '&..;' strings.
 Encode '<', '&' and 'non-break space' entities to '&..;' string.

 $data_r can be:
 - Scalar. Returns encoded scalar.
 - Scalar reference. Returns undef.
 - Array reference of scalars. Returns undef.

=back

=head1 ERRORS

 encode_attr_entities():
         Reference '%s' doesn't supported.

 encode_char_entities():
         Reference '%s' doesn't supported.

=head1 EXAMPLE1

 use strict;
 use warnings;

 use Tags::Utils qw(encode_newline);

 # Input text.
 my $text = <<'END';
 foo
 bar
 END

 # Encode newlines.
 my $out = encode_newline($text);

 # Print out.
 print $out."\n";

 # Output:
 # foo\nbar\n

=head1 EXAMPLE2

 use strict;
 use warnings;

 use Dumpvalue;
 use Tags::Utils qw(encode_attr_entities);

 # Input data.
 my @data = ('&', '<', '"');

 # Encode.
 encode_attr_entities(\@data);

 # Dump out.
 my $dump = Dumpvalue->new;
 $dump->dumpValues(\@data);

 # Output:
 # 0  ARRAY(0x8b8f428)
 #    0  '&amp;'
 #    1  '&lt;'
 #    2  '&quot;'

=head1 DEPENDENCIES

L<HTML::Entities>,
L<Error::Pure>,
L<Readonly>.

=head1 SEE ALSO

=over

=item L<Task::Tags>

Install the Tags modules.

=back

=head1 REPOSITORY

L<https://github.com/tupinek/Tags>

=head1 AUTHOR

Michal Josef Špaček L<mailto:skim@cpan.org>

L<http://skim.cz/>

=head1 LICENSE AND COPYRIGHT

 © 2005-2018 Michal Josef Špaček
 BSD 2-Clause License

=head1 VERSION

0.07

=cut
