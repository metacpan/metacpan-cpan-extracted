package Tag::Reader::Perl;

use strict;
use warnings;

use Class::Utils qw(set_params);
use Error::Pure qw(err);
use Readonly;

# Constants.
Readonly::Scalar my $EMPTY_STR => q{};

our $VERSION = '0.02';

# Constructor.
sub new {
	my ($class, @params) = @_;
	my $self = bless {}, $class;

	# Process params.
	set_params($self, @params);

	# Object.
	return $self;
}

# Get tag token.
sub gettoken {
	my $self = shift;

	# Stay.
	$self->{'stay'} = 0;
	$self->{'spec_stay'} = 0;
	$self->{'old_stay'} = 0;

	# Data.
	$self->{'data'} = [];

	# Tag type.
	$self->{'tag_type'} = '!data';
	$self->{'tag_length'} = 0;

	# Braces.
	($self->{'brace'}, $self->{'bracket'}) = (0, 0);

	# Quote.
	$self->{'quote'} = $EMPTY_STR;

	# Tag line.
	$self->{'tagline'} = $self->{'textline'};
	$self->{'tagcharpos'} = 0;

	if (exists $self->{'text'}) {
		while (exists $self->{'text'}
			&& $self->{'stay'} < 98
			&& defined ($self->{'char'}
			= substr $self->{'text'}, 0, 1)) {

			$self->_gettoken;
		}
	} elsif (exists $self->{'filename'}) {
		while ($self->{'stay'} < 98
			&& ((defined ($self->{'char'}
			= shift @{$self->{'old_data'}}))
			|| defined ($self->{'char'}
			= getc $self->{'filename'}))) {

			$self->_gettoken;
		}
	}

	my $data = join $EMPTY_STR, @{$self->{'data'}};
	if ($data eq $EMPTY_STR) {
		return ();
	}
	return wantarray ? ($data, $self->{'tag_type'}, $self->{'tagline'},
		$self->{'tagcharpos'}) : $data;
}

# Set file.
sub set_file {
	my ($self, $file, $force) = @_;
	if (! $file || ! -r $file) {
		err 'Bad file.';
	}
	if (! $force && (defined $self->{'text'}
		|| defined $self->{'filename'})) {

		err 'Cannot set new data if exists data.';
	}
	my $inf;
	if (! open $inf, '<', $file) {
		err "Cannot open file '$file'.";
	}
	$self->{'filename'} = $inf;

	# Reset values.
	$self->_reset;

	return;
}

# Set text.
sub set_text {
	my ($self, $text, $force) = @_;
	if (! $text) {
		err 'Bad text.';
	}
	if (! $force && (defined $self->{'text'}
		|| defined $self->{'filename'})) {

		err 'Cannot set new data if exists data.';
	}
	$self->{'text'} = $text;

	# Reset values.
	$self->_reset;

	return;
}

# Reset class values.
sub _reset {
	my $self = shift;

	# Default values.
	$self->{'charpos'} = 0;
	$self->{'tagcharpos'} = 0;
	$self->{'textline'} = 1;
	$self->{'tagline'} = 0;
	$self->{'old_data'} = [];

	return;
}

# Main get token.
sub _gettoken {
	my $self = shift;

	# Char position.
	$self->{'charpos'}++;

	# Normal tag.
	if ($self->{'spec_stay'} == 0) {

		# Begin of normal tag.
		if ($self->{'stay'} == 0 && $self->{'char'} eq '<') {

			# In tag.
			if ($#{$self->{'data'}} == -1) {
				$self->{'tagcharpos'}
					= $self->{'charpos'};
				$self->{'stay'} = 1;
				push @{$self->{'data'}}, $self->{'char'};
				$self->{'tag_length'} = 1;

			# Start of tag, after data.
			} else {
				$self->{'stay'} = 99;
			}

		# Text.
		} elsif ($self->{'stay'} == 0) {
			push @{$self->{'data'}}, $self->{'char'};
			if ($self->{'tagcharpos'} == 0) {
				$self->{'tagcharpos'}
					= $self->{'charpos'};
			}

		# In a normal tag.
		} elsif ($self->{'stay'} == 1) {

			# End of normal tag.
			if ($self->{'char'} eq '>') {
				$self->{'stay'} = 98;
				$self->_tag_type;
				push @{$self->{'data'}}, $self->{'char'};
				$self->{'tag_length'} = 0;

			# First charcter after '<' in normal tag.
			} elsif ($self->{'tag_length'} == 1
				&& _is_first_char_of_tag($self->{'char'})) {

				if ($self->{'char'} eq q{!}) {
					$self->{'spec_stay'} = 1;
				}
				push @{$self->{'data'}}, $self->{'char'};
				$self->{'tag_length'}++;

			# Next character in normal tag (name).
			} elsif ($self->{'tag_length'} > 1
				&& _is_in_tag_name($self->{'char'})) {

				push @{$self->{'data'}}, $self->{'char'};
				$self->{'tag_length'}++;

			# Other characters.
			} else {
				if ($self->{'tag_length'} == 1
					|| $self->{'char'} eq '<') {

					err 'Bad tag.';
				}
				$self->_tag_type;
				push @{$self->{'data'}}, $self->{'char'};
			}
		}

	# Other tags.
	} else {

		# End of normal tag.
		if ($self->{'char'} eq '>') {
			if (($self->{'brace'} == 0
				&& $self->{'bracket'} == 0
				&& $self->{'spec_stay'} < 3)

				# Comment.
				|| ($self->{'spec_stay'} == 3
				&& join($EMPTY_STR,
				@{$self->{'data'}}[-2 .. -1])
				eq q{--})

				# CDATA.
				|| ($self->{'tag_type'} =~ /^!\[cdata\[/ms
				&& join($EMPTY_STR,
				@{$self->{'data'}}[-2 .. -1])
				eq ']]')) {

				$self->{'stay'} = 98;
				$self->{'spec_stay'} = 0;
				$self->{'tag_length'} = 0;
			}
			if ($self->{'spec_stay'} != 4) {
				$self->{'bracket'}--;
			}
			push @{$self->{'data'}}, $self->{'char'};

		# Comment.
		} elsif ($self->{'spec_stay'} == 3) {

			# '--' is bad.
			if ($self->{'tag_length'} == 0
				&& join($EMPTY_STR, @{$self->{'data'}}
				[-2 .. -1]) eq q{--}) {

				err 'Bad tag.';
			}
			$self->_tag_type;
			push @{$self->{'data'}}, $self->{'char'};

		# Quote.
		} elsif ($self->{'spec_stay'} == 4) {
			if ($self->{'char'} eq $self->{'quote'}) {
				$self->{'spec_stay'} = $self->{'old_stay'};
				$self->{'quote'} = $EMPTY_STR;
			}
			push @{$self->{'data'}}, $self->{'char'};

		} elsif ($self->{'char'} eq ']') {
			push @{$self->{'data'}}, $self->{'char'};
			$self->{'brace'}--;

		# Next character in normal tag (name).
		} elsif ($self->{'tag_length'} > 1
			&& _is_in_tag_name($self->{'char'})) {

			# Comment detect.
			if (($self->{'tag_length'} == 2
				|| $self->{'tag_length'} == 3)
				&& $self->{'char'} eq q{-}) {

				$self->{'spec_stay'}++;
			}
			if ($self->{'char'} eq '[') {
				$self->{'brace'}++;
			}
			push @{$self->{'data'}}, $self->{'char'};
			$self->{'tag_length'}++;

		# Other characters.
		} else {
			if ($self->{'quote'} eq $EMPTY_STR
				&& $self->{'char'} eq q{"}) {

				$self->{'quote'} = q{"};
				$self->{'old_stay'} = $self->{'spec_stay'};
				$self->{'spec_stay'} = 4;
			}
			if ($self->{'quote'} eq $EMPTY_STR
				&& $self->{'char'} eq q{'}) {

				$self->{'quote'} = q{'};
				$self->{'old_stay'} = $self->{'spec_stay'};
				$self->{'spec_stay'} = 4;
			}
			if ($self->{'char'} eq '<') {
				$self->{'bracket'}++;
			}
			if ($self->{'char'} eq '[') {
				$self->{'brace'}++;
			}
			$self->_tag_type;
			push @{$self->{'data'}}, $self->{'char'};
		}
	}

	# Remove char from buffer.
	if ($self->{'stay'} != 99) {
		if (exists $self->{'text'}) {
			if (length $self->{'text'} > 1) {
				$self->{'text'} = substr $self->{'text'}, 1;
			} else {
				delete $self->{'text'};
			}
		}
	} else {
		if (exists $self->{'filename'}
			&& defined $self->{'char'}) {

			push @{$self->{'old_data'}}, $self->{'char'};
		}
	}
	if ($self->{'stay'} == 98 || $self->{'stay'} == 99) {
		if ($self->{'stay'} == 99) {
			$self->{'charpos'}--;
		}
	}

	# Next line.
	if ($self->{'char'} eq "\n") {
		$self->{'textline'}++;
		$self->{'charpos'} = 0;
	}

	return;
}

# First character in tag.
sub _is_first_char_of_tag {
	my $char = shift;
	if ($char eq q{!} || $char eq q{/} || $char eq q{?}
		|| $char =~ /^[\d\w]+$/ms) {

		return 1;
	}
	return 0;
}

# Normal characters in a tag name.
sub _is_in_tag_name {
	my $char = shift;
	if ($char eq q{:} || $char eq '[' || $char eq q{-} || $char eq q{%}
		|| $char =~ /^[\d\w]+$/ms) {

		return 1;
	}
	return 0;
}

# Process tag type.
sub _tag_type {
	my $self = shift;
	if ($self->{'tag_length'} > 0) {
		$self->{'tag_type'}
			= lc join $EMPTY_STR, @{$self->{'data'}}
			[1 .. $self->{'tag_length'} - 1];
		$self->{'tag_length'} = 0;
	}
	return;
}

1;

__END__

=pod

=encoding utf8

=head1 NAME

 Tags::Reader::Perl - Parse SGML/HTML/XML by each "tag".

=head1 SYNOPSIS

 use Tags::Reader::Perl;

 my $obj = Tags::Reader::Perl->new;
 my @tokens = $obj->gettoken;
 $obj->set_file($file, $force);
 $obj->set_text($text, $force);

=head1 METHODS

=head2 C<new()>

 my $obj = Tags::Reader::Perl->new;

Constructor.

Returns instance of object.

=head2 C<gettoken>

 my @tokens = $obj->gettoken;

Get parsed token.

Returns structure defining parsed token in array context. See TOKEN STRUCTURE
e.g. <xml> → ('<xml>', 'xml', 1, 1)

Returns parsed token in scalar mode. e.g. <xml> → '<xml>'

=head2 C<set_file>

 $obj->set_file($file, $force);

Set file for parsing.
If $force present, reset file for parsing if exists previous text or file.

Returns undef.

=head2 C<set_text>

 $obj->set_text($text, $force);

Set text for parsing.
if $force present, reset text for parsing if exists previous text or file.

Returns undef.

=head1 TOKEN STRUCTURE

 Structure contains 4 fields in array:
 - parsed data
 - tag type
 - number of line
 - number of column in line

 Tag types are:
 - '[\w:]+' - element name.
 - '/[\w:]+' - end of element name.
 - '!data' - data
 - '![cdata[' - cdata
 - '!--' - comment
 - '?\w+' - instruction
 - '![\w+' - conditional
 - '!attlist' - DTD attlist
 - '!element' - DTD element
 - '!entity' - DTD entity
 - '!notation' - DTD notation

=head1 ERRORS

 new():
         From Class::Utils::set_params():
                 Unknown parameter '%s'.

 set_text():
         Bad tag.
         Bad text.
         Cannot set new data if exists data.

 set_file():
         Bad tag.
         Bad file.
         Cannot set new data if exists data.
         Cannot open file '%s'.

=head1 EXAMPLE1

 use strict;
 use warnings;

 use Tag::Reader::Perl;
 use Unicode::UTF8 qw(decode_utf8 encode_utf8);

 # Object.
 my $obj = Tag::Reader::Perl->new;

 # Example data.
 my $sgml = <<'END';
 <DOKUMENT> 
   <adresa stát="cs">
     <město>
     <ulice>Nová</ulice>
     <číslo>5</číslo>
   </adresa>
 </DOKUMENT>
 END

 # Set data to object.
 $obj->set_text(decode_utf8($sgml));

 # Tokenize.
 while (my @tag = $obj->gettoken) {
         print "[\n";
         print "\t[0]: '".encode_utf8($tag[0])."'\n";
         print "\t[1]: ".encode_utf8($tag[1])."\n";
         print "\t[2]: $tag[2]\n";
         print "\t[3]: $tag[3]\n";
         print "]\n";
 }

 # Output:
 # [
 # 	[0]: '<DOKUMENT>'
 # 	[1]: dokument
 # 	[2]: 1
 # 	[3]: 1
 # ]
 # [
 # 	[0]: ' 
 #   '
 # 	[1]: !data
 # 	[2]: 1
 # 	[3]: 11
 # ]
 # [
 # 	[0]: '<adresa stát="cs">'
 # 	[1]: adresa
 # 	[2]: 2
 # 	[3]: 3
 # ]
 # [
 # 	[0]: '
 #     '
 # 	[1]: !data
 # 	[2]: 2
 # 	[3]: 21
 # ]
 # [
 # 	[0]: '<město>'
 # 	[1]: město
 # 	[2]: 3
 # 	[3]: 5
 # ]
 # [
 # 	[0]: '
 #     '
 # 	[1]: !data
 # 	[2]: 3
 # 	[3]: 12
 # ]
 # [
 # 	[0]: '<ulice>'
 # 	[1]: ulice
 # 	[2]: 4
 # 	[3]: 5
 # ]
 # [
 # 	[0]: 'Nová'
 # 	[1]: !data
 # 	[2]: 4
 # 	[3]: 12
 # ]
 # [
 # 	[0]: '</ulice>'
 # 	[1]: /ulice
 # 	[2]: 4
 # 	[3]: 16
 # ]
 # [
 # 	[0]: '
 #     '
 # 	[1]: !data
 # 	[2]: 4
 # 	[3]: 24
 # ]
 # [
 # 	[0]: '<číslo>'
 # 	[1]: číslo
 # 	[2]: 5
 # 	[3]: 5
 # ]
 # [
 # 	[0]: '5'
 # 	[1]: !data
 # 	[2]: 5
 # 	[3]: 12
 # ]
 # [
 # 	[0]: '</číslo>'
 # 	[1]: /číslo
 # 	[2]: 5
 # 	[3]: 13
 # ]
 # [
 # 	[0]: '
 #   '
 # 	[1]: !data
 # 	[2]: 5
 # 	[3]: 21
 # ]
 # [
 # 	[0]: '</adresa>'
 # 	[1]: /adresa
 # 	[2]: 6
 # 	[3]: 3
 # ]
 # [
 # 	[0]: '
 # '
 # 	[1]: !data
 # 	[2]: 6
 # 	[3]: 12
 # ]
 # [
 # 	[0]: '</DOKUMENT>'
 # 	[1]: /dokument
 # 	[2]: 7
 # 	[3]: 1
 # ]
 # [
 # 	[0]: '
 # '
 # 	[1]: !data
 # 	[2]: 7
 # 	[3]: 12
 # ]

=head1 DEPENDENCIES

L<Class::Utils>,
L<Error::Pure>,
L<Readonly>,

=head1 SEE ALSO

=over

=item L<Tag::Reader>

Parse SGML/HTML/XML by each "tag".

=item L<HTML::TagReader>

Perl extension module for reading html/sgml/xml files by tags.

=back

=head1 REPOSITORY

L<https://github.com/michal-josef-spacek/Tag-Reader-Perl>

=head1 AUTHOR

Michal Josef Špaček L<mailto:skim@cpan.org>

L<http://skim.cz>

=head1 LICENSE AND COPYRIGHT

© Michal Josef Špaček 2005-2021

BSD 2-Clause License

=head1 VERSION

0.02

=cut
