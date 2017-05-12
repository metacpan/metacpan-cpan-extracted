package Symantec::PCAnywhere::Profile;

use strict;
use warnings;

=head1 NAME

Symantec::PCAnywhere::Profile - Base class for pcAnywhere utility functions

=head1 VERSION

Version 0.06

=cut

our $VERSION = '0.06';

=head1 SYNOPSIS

This class should not be instantiated or used by itself. Use one of its
subclasses instead.

=head1 DESCRIPTION

Provides methods common to pcAnywhere utility functions. See L<METHODS>.  Below
is an overview of the general decoding mechaism.

=head2 FILE OBSCURING ALGORITHM

The general idea of the file obscuring algorithm is that each byte is XOR'd
with the previous byte plus an incrementing eight-bit counter. For reasons
unknown to us, there seems to be some kind of shift in the algorithm starting
at byte 448, so we split up our decoding into a "first part" and a "second
part).

	for each byte 
	do
		char = thisbyte (XOR) prevbyte (XOR)  counter++
	done

=head2 FIELD BREAKDOWN

The interesting fields appear to be in fixed positions: this was very helpful.

String fields seem to be terminated with a NUL byte, and we have observed that
changing a long value to a short one leaves the tail end of the long field
inside the file. In some cases we do not ever care about the "old" value, but
since passwords and login names are disabled by NULing out the first byte, the
bytes that remain might be interesting. See L<FIELD DECODING> for further
discussion.

We believe that some fields are slightly overloaded - we have seen overlap -
and they mainly revolve around the GATEWAY fields.  We don't know how
pcAnywhere gateways work well enough to really know what to make of it.

=head2 FIELD DECODING

We define all the fields of interest in a hash to allow us to do a bit more
than just decode: perhaps a bit of reporting or double-checking for overlaps
and the like.

Each entry has a name, which is used as the key to the user-returned hash, plus
the zero-based offset into the setring, the length, and a "type". The type is
one of:

	0 = string, strip everything after first NUL byte
	1 = string, strip trailing NUL bytes
	2 = binary
	3 = little-endian 16-bit word

The reason we allow for type #1 is to avoid stripping NUL bytes from a few
fields, such as passwords. If you enter a login name or password, but then
disable the "auto-login", pcAnywhere simply NULs out the first byte: this is
still useful information.

The original code on which this module is based was used for penetration
testing, and so Type 1 was useful for recovering partly-obscured credentials.
However, using Type 1 hampers the more likely use of this module, so the
Hostname, Domain_Logname, and Password fields have been changed from Type 1 to
Type 0.

Type 3 currently exists only for decoding port numbers.

=cut

use Carp;

#
# These lists hold coderefs for en-/de-coding.
#
# Pass in (data). Modified on stack and returned.
#
my @DECODE_SUB = (
	# Type 0 -- strip ALL after NUL
	sub { $_[0] =~ s/\0.*$// },
	# Type 1 -- strip trailing NUL only
	sub { $_[0] =~ s/\0+$// },
	# Type 2 -- binary byte
	sub { $_[0] = ord($_[0]) },
	# Type 3 -- little-endian 16-bit word
	sub { $_[0] = unpack("v", $_[0]) }
);

#
# Pass in (data, len). Modified on stack and returned.
#
my @ENCODE_SUB = (
	# Type 0 -- pad with NUL
	sub { $_[0] = substr($_[0] . ("\0" x ($_[1] - length $_[0])), 0, $_[1]) },
	# Type 1 -- equivalent to Type 0 for encoding
	sub { $_[0] = substr($_[0] . ("\0" x ($_[1] - length $_[0])), 0, $_[1]) },
	# Type 2 -- binary byte
	sub { $_[0] = chr($_[0]) },
	# Type 3 -- little-endian 16-bit word
	sub { $_[0] = pack("v", $_[0]) }
);

=head1 METHODS

=head2 PUBLIC

=over 4

=item new

The "new" constructor takes any number of arguments and sets the appropriate
flags internally before returning a new object. The object is implemented as a
blessed hash; if more than one argument is passed in, the arguments are
considered as a list of key-value pairs which are inserted into the object
data. Both "regular" and dash-style arguments are supported.

=cut

sub new {
	my $type = shift;
	my %defaults = (
		encode_sub	=> \@ENCODE_SUB,
		decode_sub	=> \@DECODE_SUB,
	);

	# Support dash- and regular-style arguments, stripping dashes
	my %args = map { substr($_, /^-/ ? 1 : 0) => {@_}->{$_} } keys %{{@_}};
	my $self = bless { %defaults, %args }, $type;
	return $self;
}

=item load_from_file

	$chf->load_from_file($filename);

Loads a file for processing, optionally taking a filename.

=cut

sub load_from_file ($;$) {
	my $self = shift;
	$self->{filename} ||= shift or croak "No filename to read from";

	local $/ = undef;
	open F, "<", $self->{filename}
		or croak "Failed to open '$self->{filename}' for reading";
	binmode F;
	$self->{data} = <F>;
	close F;
}

=item set_attrs

	$chf->set_attrs(
		PhoneNumber	=> 5551234,
		AreaCode	=> 800,
		IPAddress	=> '172.0.0.11',
		ControlPort	=> '4763'
	);

Sets the attributes of the file; pass in any number of key-value pairs.

=cut

sub set_attrs ($%) {
	my $self = shift;
	my %attrs = @_;

	$self->{attrs} ||= { };
	while (my ($attr, $value) = each %attrs) {
		$self->{attrs}{$attr} = $value if $self->{fields}{$attr};
	}
}

=item set_attr

	$chf->set_attr($attr => $value);

This convenience method sets the value for only one attribute. Note that
set_attrs() can be called with exactly the same arguments as this method.

=cut

sub set_attr ($$$) { shift->set_attrs(shift, shift) }

=item get_attrs

	my @query = qw(PhoneNumber AreaCode IPAddress ControlPort);
	my $attr = $chf->get_attrs(@query);
	my $attrs = $chf->get_attrs(@query);

Pass in a list of items whose attributes you wish to retrieve. Returns a
reference to a hash whose keys are the values you passed in and whose values
are the attributes retrieved.

=cut

sub get_attrs ($@) {
	my $self = shift;
	my %results;

	# Do the parsing if necessary
	$self->{attrs} ||= $self->_parse_pca_file;
	%results = map { $_ => $self->{attrs}{$_} } @_;
	return \%results;
}

=item get_attr

	my $value = $chf->get_attr($attr);

This helper method gets the value for only one attribute and returns it as a
scalar.

=cut

sub get_attr ($$) { (values %{ shift->get_attrs(shift) })[0] }

=item get_fields

	my @fields = $self->get_fields;

Returns (in hash order) the names of fields that can be read from or written to
the file.

=cut

sub get_fields () { keys %{ shift->{fields} } }

=item write_to_file

Writes data to a file, optionally taking a filename (if none is supplied, the
filename object field is used)

=cut

sub write_to_file ($;$) {
	my $self = shift;
	$self->{filename} ||= shift or croak "No filename to write to";
	$self->{data} or do { $self->encode } or croak "No data to write";

	open F, ">", $self->{filename}
		or croak "Failed to open '$self->{filename}' for writing";
	binmode F;
	print F $self->{data};
	close F;
}

=item decode

	$chf->decode;
	$chf->decode($chfdata);

Decodes the currently-loaded data or new data passed in.

=cut

sub decode ($;$) {
	my $self = shift;
	$self->{data} ||= shift or do { $self->_load };
	$self->{data} or croak "No data to decode";
	$self->{decoded} = $self->_decode_pca_file;
}

=item encode

	$chf->encode;
	
Returns an encoded representation of the CHF file, constructed from the
attributes previously set by set_attrs or existing from a constructor or
load_from_file() call.

=cut

sub encode ($) {
	my $self = shift;
	$self->{decoded} = $self->_edit_pca_file;
	$self->{decoded} or croak "No data to encode";
	$self->{data} = $self->_encode_pca_file;
}

=item _encode_pca_file

=item _decode_pca_file

Method declarations ("abstract" methods) to be implmented by subclasses

=cut

sub _encode_pca_file ($$);
sub _decode_pca_file ($$);

=back

=head2 PRIVATE

=over 4

=item _rawencode

This is the low-level engine that handles the XOR encoding of the byte stream.
It knows nothing of pcAnywhere data, and it can be called on multiple sections
of the file independently.

	$roll - starting value of the rolling counter
	$prev - the "previous byte" value upon entry to the loop
	$str  - the string we're to encode

=cut

sub _rawencode {
	shift;	# Get rid of my $self
	my ($roll, $prev, $str) = @_;
	my $encstr = "";                  # encoded string

	foreach ( split( m//, $str) ) {
		$prev = ord($_) ^ $prev ^ ($roll++ & 0xFF);
		$encstr .= chr($prev);
	}

	return $encstr;
}

=item _rawdecode

This is the low-level engine that handles the XOR decoding of the byte stream.
It knows nothing of pcAnywhere data, and it can be called on multiple sections
of the file independently.

	$roll - starting value of the rolling counter
	$prev - the "previous byte" value upon entry to the loop
	$str  - the string we're to decode

=cut

sub _rawdecode {
	shift;	# Get rid of my $self
	my ($roll, $prev, $str) = @_;
	my $decstr = "";                  # decoded string

	foreach ( split( m//, $str) ) {
		my $c = ord($_);

		$decstr .= chr( $c ^ $prev ^ ($roll++ & 0xFF) );
		$prev = $c;
	}

	return $decstr;
}

=item _edit_pca_file

Performs encoding operations (internal)

=cut

sub _edit_pca_file ($) {
	my $self = shift;
	# Make a copy of the template string
	my $str = $self->{template};

	foreach my $key ( keys %{ $self->{attrs} } ) {
		my $f = $self->{fields}{$key};
		# This must be a known key to continue
		unless ($f) {
			carp "Tried to set unknown key -- continuing";
			next;
		}

		my ($off, $len, $type) = @$f;
		my $val = $self->{attrs}{$key};

		# If there is a handler defined for this type, use it
		$self->{encode_sub}[$type]->($val, $len)
			if defined $self->{encode_sub}[$type];

		substr($str, $off, $len) = $val;
	}

	return $str;
}

=item _parse_pca_file

Teases the binary format into a hash (internal)

=cut

sub _parse_pca_file ($) {
	my $self = shift;
	my $str = $self->{decoded} || do { $self->decode };
	my $ref = { };

	foreach my $key ( keys %{ $self->{fields} } ) {
		my ($off, $len, $type) = @{ $self->{fields}{$key} };
		my $val = substr($str, $off, $len);

		# If there is a handler defined for this type, use it
		$self->{decode_sub}[$type]->($val)
			if defined $self->{decode_sub}[$type];

		$ref->{$key} = $val;
	}

	return $ref;
}

=item _load

Does loading of filedata if necessary

=cut

sub _load ($) {
	my $self = shift;
	unless ($self->{data}) {
		if ($self->{filename}) {
			$self->load_from_file;
		} else {
			croak "No filename specified and no data loaded";
		}
	}
}

=back

=head1 TO DO

Our understanding of the decoding process just looks incomplete: it's
complicated enough for no good reason that we really just suspect that we have
done it wrong. There are a couple of glitches even in the current decoding that
it requires a bit more thought.

Implement better error handling.

Explain the default values for certain special fields.

Get rid of the silly prototype definitions on the method definitions.

Create (more) tests!

=head1 SEE ALSO

See L<Symantec::PCAnywhere::Profile::CHF> for a useful subclass of this module.

=head1 AUTHOR

Darren Kulp, C<< <darren at kulp.ch> >>, based on code from Stephen J. Friedl,
(http://unixwiz.net/)

=head1 ACKNOWLEDGEMENTS

This module is based on 'pcainfo' from Stephen J. Friedl. His work, which is in
the public domain, has been modified to add encoding capabilities to allow
creating CHFs (pcAnywhere connection profiles). Thanks, Stephen!

The addition of encoding and an OO interface, as well as the packaging as a
CPAN module and the correcting of some typographical errors, semantic
redundancies, and spelling mistakes, was done by Darren Kulp.

=head1 COPYRIGHT AND LICENSE

This code is in the public domain. Contains code placed in the public domain
2002 by Stephen Friedl.

"Symantec" and "pcAnywhere" are trademarks of Symantec Corp.

=head1 BUGS

Please report any bugs or feature requests to
C<bug-symantec-pcanywhere-profile at rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Symantec-PCAnywhere-Profile>.
I will be notified, and then you'll automatically be notified of progress on
your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Symantec::PCAnywhere::Profile

You can also look for information at:

=over 4

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Symantec-PCAnywhere-Profile>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Symantec-PCAnywhere-Profile>

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Symantec-PCAnywhere-Profile>

=item * Search CPAN

L<http://search.cpan.org/dist/Symantec-PCAnywhere-Profile>

=back

=cut

1; # End of Symantec::PCAnywhere::Profile
