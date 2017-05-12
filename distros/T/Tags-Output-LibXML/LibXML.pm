package Tags::Output::LibXML;

# Pragmas.
use base qw(Tags::Output);
use strict;
use warnings;

# Modules.
use Error::Pure qw(err);
use Readonly;
use XML::LibXML;

# Constants.
Readonly::Scalar my $EMPTY_STR => q{};

# Version.
our $VERSION = 0.02;

# Flush tags in object.
sub flush {
	my ($self, $reset_flag) = @_;
	my $ret;
	my $ouf = $self->{'output_handler'};
	if ($ouf) {
		no warnings;
		print {$ouf} $self->{'doc'}->toString(
			$self->{'set_indent'} ? 2 : 0)
			or err 'Cannot write to output handler.';
	} else {
		$ret = $self->{'doc'}->toString(
			$self->{'set_indent'} ? 2 : 0);
	}

	# Reset.
	if ($reset_flag) {
		$self->reset;
	}

	return $ret;
}

# Resets internal variables.
sub reset {
	my $self = shift;

	# Root node.
	$self->{'doc'} = XML::LibXML::Document->new(
		$self->{'xml_version'},
		$self->{'encoding'},
	);

	# First node = root node.
	$self->{'first'} = 0;

	# Printed tags.
	$self->{'printed_tags'} = [];

	return;
}

# Check parameters to rigth values.
sub _check_params {
        my $self = shift;

	# Check to output handler.
	if (defined $self->{'output_handler'}
		&& ref $self->{'output_handler'} ne 'GLOB') {

		err 'Output handler is bad file handler.';
	}

	return;
}

# Default parameters.
sub _default_parameters {
	my $self = shift;

	# CDATA callback.
	$self->{'cdata_callback'} = undef;

	# Data callback.
	$self->{'data_callback'} = undef;

	# Document encoding.
	$self->{'encoding'} = 'UTF-8';

	# No simple tags.
	# TODO not implemented.
	$self->{'no_simple'} = [];

	# Set output handler.
	$self->{'output_handler'} = undef;

	# Preserved tags.
	# TODO not implemented.
	$self->{'preserved'} = [];

	# Set indent.
	$self->{'set_indent'} = 0;

	# Skip bad tags.
	$self->{'skip_bad_tags'} = 0;

	# XML version.
	$self->{'xml_version'} = '1.1';

	return;
}

# Attributes.
sub _put_attribute {
	my ($self, $attr, $value) = @_;
	$self->{'printed_tags'}->[0]->setAttribute($attr, $value);
	return;
}

# Begin of tag.
sub _put_begin_of_tag {
	my ($self, $tag) = @_;
	my $begin_node = $self->{'doc'}->createElement($tag);
	if ($self->{'first'} == 0) {
		$self->{'doc'}->setDocumentElement($begin_node);
		$self->{'first'} = 1;
	} else {
		if (! $self->{'printed_tags'}->[0]) {
			err "Second root tag '$tag' is bad.";
		} else {
			$self->{'printed_tags'}->[0]->addChild($begin_node);
		}
	}
	unshift @{$self->{'printed_tags'}}, $begin_node;
	return;
}

# CData.
sub _put_cdata {
	my ($self, @cdata) = @_;
	$self->_process_callback(\@cdata, 'cdata_callback');
	my $cdata = join($EMPTY_STR, @cdata);
	my $cdata_node = $self->{'doc'}->createCDATASection($cdata);
	$self->{'printed_tags'}->[0]->addChild($cdata_node);
	return;
}

# Comment.
sub _put_comment {
	my ($self, @comments) = @_;
	my $comment = join($EMPTY_STR, @comments);

	# HACK LibXML has a bug.
	if ($comment =~ m/-$/ms) {
		$comment .= ' ';
	}

	my $comment_node = $self->{'doc'}->createComment($comment);
	if (! defined $self->{'printed_tags'}->[0]) {
		$self->{'doc'}->appendChild($comment_node);
	} else {
		$self->{'printed_tags'}->[0]->addChild($comment_node);
	}
	return;
}

# Data.
sub _put_data {
	my ($self, @data) = @_;
	$self->_process_callback(\@data, 'data_callback');
	my $data = join($EMPTY_STR, @data);
	my $data_node = $self->{'doc'}->createTextNode($data);
	$self->{'printed_tags'}->[0]->addChild($data_node);
	return;
}

# End of tag.
sub _put_end_of_tag {
	my ($self, $tag) = @_;
	shift @{$self->{'printed_tags'}};
	return;
}

# Instruction.
sub _put_instruction {
	my ($self, $target, $code) = @_;
	my $instruction_node = $self->{'doc'}->createProcessingInstruction(
		$target, $code,
	);
	if (! defined $self->{'printed_tags'}->[0]) {
		$self->{'doc'}->appendChild($instruction_node);
	} else {
		$self->{'printed_tags'}->[0]->addChild($instruction_node);
	}
	return;
}

# Raw data.
sub _put_raw {
	my ($self, @raw_data) = @_;
	return;
}

1;

__END__

=pod

=encoding utf8

=head1 NAME

 Tags::Output::LibXML - Printing 'Tags' structure by LibXML library.

=head1 SYNOPSIS

 use Tags::Output::LibXML;
 my $tags = Tags::Output::LibXML->new(%parameters);
 $tags->put(['b', 'element']);
 my @open_tags = $tags->open_tags;
 $tags->finalize;
 $tags->flush($reset_flag);
 $tags->reset;

=head1 DESCRIPTION

 This class is only for XML structures.

=head1 METHODS

=over 8

=item C<new(%parameters)>

 Constructor.

=over 8

=item * C<cdata_callback>

 Subroutine for output processing of cdata.
 Input argument is reference to array.
 Default value is undef.
 Example is similar as 'data_callback'.

=item * C<data_callback>

 Subroutine for output processing of data, cdata and raw data.
 Input argument is reference to array.
 Default value is undef.

 Example:
 'data_callback' => sub {
         my $data_ar = shift;
	 foreach my $data (@{$data_ar}) {

	         # Some process.
	         $data =~ s/^\s*//ms;
	 }
 }

=item * C<encoding>

 Encoding for XML header.
 Default is 'UTF-8'.

=item * C<no_simple>

 TODO not implemented.
 Reference to array of tags, that can't by simple.
 Default is [].

=item * C<output_handler>

 Handler for print output strings.
 Must be a GLOB.
 Default is undef.

=item * C<preserved>

 TODO not implemented.
 Default value is reference to blank array.

=item * C<set_indent>

 Set indent flag.
 Default is 0.

=item * C<skip_bad_tags>

 Skip bad tags.
 Default value is 0.

=item * C<xml_version>

 XML version for XML header.
 Default is "1.1".

=back

=item C<finalize()>

 Finalize Tags output.
 Automaticly puts end of all opened tags.
 Returns undef.

=item C<flush($reset_flag)>

 Flush tags in object.
 If defined 'output_handler' flush to its.
 Or return code.
 If enabled $reset_flag, then resets internal variables via reset method. 

=item C<open_tags()>

 Return array of opened tags.

=item C<put(@data)>

 Put tags code in tags format.
 Returns undef.

=item C<reset()>

 Resets internal variables.
 Returns undef.

=back

=head1 ERRORS

 TODO

=head1 EXAMPLE1

 # Pragmas.
 use strict;
 use warnings;

 # Modules.
 use Tags::Output::LibXML;

 # Object.
 my $tags = Tags::Output::LibXML->new;

 # Put data.
 $tags->put(
         ['b', 'text'],
	 ['d', 'data'],
	 ['e', 'text'],
 );

 # Print.
 print $tags->flush."\n";

 # Output:
 # <?xml version="1.1" encoding="UTF-8"?>
 # <text>data</text>

=head1 EXAMPLE2

 # Pragmas.
 use strict;
 use warnings;

 # Modules.
 use Encode;
 use Tags::Output::LibXML;

 # Object.
 my $tags = Tags::Output::LibXML->new(
         'data_callback' => sub {
	         my $data_ar = shift;
		 foreach my $data (@{$data_ar}) {
		         $data = encode_utf8($data);
		 }
                 return;
	 },
 );

 # Data in characters.
 my $data = decode_utf8('řčěšřšč');

 # Put data.
 $tags->put(
         ['b', 'text'],
	 ['d', $data],
	 ['e', 'text'],
 );

 # Print.
 print $tags->flush."\n";

 # Output:
 # <?xml version="1.1" encoding="UTF-8"?>
 # <text>řčěšřšč</text>

=head1 DEPENDENCIES

L<Error::Pure>,
L<Readonly>,
L<Tags::Output>,
L<XML::LibXML>.

=head1 SEE ALSO

=over

=item L<Tags>

Structure oriented SGML/XML/HTML/etc. elements manipulation.

=item L<Tags::Output>

Base class for Tags::Output::*.

=item L<Task::Tags>

Install the Tags modules.

=back

=head1 AUTHOR

Michal Špaček L<skim@cpan.org>

=head1 LICENSE AND COPYRIGHT

 © 2011-2015 Michal Špaček
 BSD 2-Clause License

=head1 VERSION

0.02

=cut
