package Tags::Output::Structure;

# Pragmas.
use base qw(Tags::Output);
use strict;
use warnings;

# Modules.
use Error::Pure qw(err);

# Version.
our $VERSION = 0.04;

# Flush.
sub flush {
	my ($self, $reset_flag) = @_;
	my $ouf = $self->{'output_handler'};

	# Text output.
	my $ret_ar;
	if ($ouf) {
		foreach my $line_ar (@{$self->{'flush_code'}}) {
			my $line = "['";
			$line .= join "', '", @{$line_ar};
			$line .= "']".$self->{'output_sep'};
			no warnings;
			print {$ouf} $line
				or err 'Cannot write to output handler.';
		}

	# Structure.
	} else {
		$ret_ar = $self->{'flush_code'};
	}

	# Reset.
	if ($reset_flag) {
		$self->reset;
	}

	return $ret_ar;
}

# Attributes.
sub _put_attribute {
	my ($self, $attr, $value) = @_;
	$self->_put_structure('a', $attr, $value);
	return;
}

# Begin of tag.
sub _put_begin_of_tag {
	my ($self, $tag) = @_;
	$self->_put_structure('b', $tag);
	unshift @{$self->{'printed_tags'}}, $tag;
	return;
}

# CData.
sub _put_cdata {
	my ($self, @cdata) = @_;
	$self->_put_structure('cd', @cdata);
	return;
}

# Comment.
sub _put_comment {
	my ($self, @comments) = @_;
	$self->_put_structure('c', @comments);
	return;
}

# Data.
sub _put_data {
	my ($self, @data) = @_;
	$self->_put_structure('d', @data);
	return;
}

# End of tag.
sub _put_end_of_tag {
	my ($self, $tag) = @_;
	my $printed = shift @{$self->{'printed_tags'}};
	if ($printed ne $tag) {
		err "Ending bad tag: '$tag' in block of tag '$printed'.";
	}
	$self->_put_structure('e', $tag);
	return;
}

# Instruction.
sub _put_instruction {
	my ($self, $target, $code) = @_;
	my @instruction = ('i', $target);
	if ($code) {
		push @instruction, $code;
	}
	$self->_put_structure(@instruction);
	return;
}

# Raw data.
sub _put_raw {
	my ($self, @raw_data) = @_;
	$self->_put_structure('r', @raw_data);
	return;
}

# Put common structure.
sub _put_structure {
	my ($self, @struct) = @_;
	push @{$self->{'flush_code'}}, \@struct;
	return;
}

1;

__END__

=pod

=encoding utf8

=head1 NAME

 Tags::Output::Structure - Structure class for 'Tags' output.

=head1 SYNOPSYS

 use Tags::Output::Structure;
 my $obj = Tags::Output::Structure->new(%parameters);
 $obj->finalize;
 my $ret_ar = $obj->flush($reset_flag);
 my @tags = $obj->open_tags;
 $obj->put(@data);
 $obj->reset;

=head1 METHODS

=over 8

=item C<new(%parameters)>

 Constructor.

=over 8

=item * C<auto_flush>

 Auto flush flag.
 Default value is 0.

=item * C<output_callback>

 Output callback.
 Default value is undef.

=item * C<output_handler>

 Set output handler.
 Default value is undef.

=item * C<output_sep>

 Output separator.
 Default value is newline.

=item * C<skip_bad_data>

 Skip bad tags.
 Default value is 0.

=item * C<strict_instruction>

 Strict instruction.
 Default value is 1.

=back

=item C<finalize()>

 Finalize Tags output.
 Automaticly puts end of all opened tags.
 Returns undef.

=item C<flush($reset_flag)>

 Flush tags in object.
 Or returns code.
 If enabled $reset_flag, then resets internal variables via reset method.

=item C<open_tags()>

 Returns array of opened tags.

=item C<put(@data)>

 Put tags code in tags format.
 Returns undef.

=item C<reset()>

 Resets internal variables.
 Returns undef.

=back

=head1 ERRORS

 new():
         Auto-flush can't use without output handler.
         Output handler is bad file handler.
         From Class::Utils::set_params():
                 Unknown parameter '%s'.

 flush():
         Cannot write to output handler.

 put():
         Ending bad tag: '%s' in block of tag '%s'.

=head1 EXAMPLE1

 # Pragmas.
 use strict;
 use warnings;

 # Modules.
 use Data::Printer;
 use Tags::Output::Structure;

 # Object.
 my $tags = Tags::Output::Structure->new;

 # Put all tag types.
 $tags->put(
         ['b', 'tag'],
         ['a', 'par', 'val'],
         ['c', 'data', \'data'],
         ['e', 'tag'],
         ['i', 'target', 'data'],
         ['b', 'tag'],
         ['d', 'data', 'data'],
         ['e', 'tag'],
 );

 # Print out.
 my $ret_ar = $tags->flush;

 # Dump out.
 p $ret_ar;

 # Output:
 # \ [
 #     [0] [
 #         [0] "b",
 #         [1] "tag"
 #     ],
 #     [1] [
 #         [0] "a",
 #         [1] "par",
 #         [2] "val"
 #     ],
 #     [2] [
 #         [0] "c",
 #         [1] "data",
 #         [2] \ "data"
 #     ],
 #     [3] [
 #         [0] "e",
 #         [1] "tag"
 #     ],
 #     [4] [
 #         [0] "i",
 #         [1] "target",
 #         [2] "data"
 #     ],
 #     [5] [
 #         [0] "b",
 #         [1] "tag"
 #     ],
 #     [6] [
 #         [0] "d",
 #         [1] "data",
 #         [2] "data"
 #     ],
 #     [7] [
 #         [0] "e",
 #         [1] "tag"
 #     ]
 # ]

=head1 EXAMPLE2

 # Pragmas.
 use strict;
 use warnings;

 # Modules.
 use Tags::Output::Structure;

 # Object.
 my $tags = Tags::Output::Structure->new(
         'output_handler' => \*STDOUT,
 );

 # Put all tag types.
 $tags->put(
         ['b', 'tag'],
         ['a', 'par', 'val'],
         ['c', 'data', \'data'],
         ['e', 'tag'],
         ['i', 'target', 'data'],
         ['b', 'tag'],
         ['d', 'data', 'data'],
         ['e', 'tag'],
 );

 # Print out.
 $tags->flush;

 # Output:
 # ['b', 'tag']
 # ['a', 'par', 'val']
 # ['c', 'data', 'SCALAR(0x143d9c0)']
 # ['e', 'tag']
 # ['i', 'target', 'data']
 # ['b', 'tag']
 # ['d', 'data', 'data']
 # ['e', 'tag']

=head1 DEPENDENCIES

L<Error::Pure>,
L<Tags::Output>.

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

Michal Špaček L<mailto:skim@cpan.org>

L<http://skim.cz>

=head1 LICENSE AND COPYRIGHT

 © 2012-2015 Michal Špaček
 BSD 2-Clause License

=head1 VERSION

0.04

=cut
