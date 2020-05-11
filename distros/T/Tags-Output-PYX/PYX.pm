package Tags::Output::PYX;

use base qw(Tags::Output);
use strict;
use warnings;

use Error::Pure qw(err);
use Readonly;
use Tags::Utils qw(encode_newline);

# Constants.
Readonly::Scalar my $EMPTY_STR => q{};
Readonly::Scalar my $SPACE => q{ };

our $VERSION = 0.04;

# Attributes.
sub _put_attribute {
	my ($self, $attr, $value) = @_;
	push @{$self->{'flush_code'}}, "A$attr $value";
	return;
}

# Begin of tag.
sub _put_begin_of_tag {
	my ($self, $tag) = @_;
	push @{$self->{'flush_code'}}, "($tag";
	unshift @{$self->{'printed_tags'}}, $tag;
	return;
}

# CData.
sub _put_cdata {
	my ($self, @cdata) = @_;
	$self->_put_data(@cdata);
	return;
}

# Comment.
sub _put_comment {
	my ($self, @comments) = @_;
	$self->_put_data(
		map { '<!--'.$_.'-->' } @comments,
	);
	return;
}

# Data.
sub _put_data {
	my ($self, @data) = @_;
	my $data = join($EMPTY_STR, @data);
	push @{$self->{'flush_code'}}, '-'.encode_newline($data);
	return;
}

# End of tag.
sub _put_end_of_tag {
	my ($self, $tag) = @_;
	my $printed = shift @{$self->{'printed_tags'}};
	if ($printed ne $tag) {
		err "Ending bad tag: '$tag' in block of tag '$printed'.";
	}
	push @{$self->{'flush_code'}}, ")$tag";
	return;
}

# Instruction.
sub _put_instruction {
	my ($self, $target, $code) = @_;

	# Construct instruction line.
	my $instruction = '?'.$target;
	if ($code) {
		$instruction .= $SPACE.$code;
	}

	# To flush code.
	push @{$self->{'flush_code'}}, encode_newline($instruction);

	return;
}

# Raw data.
sub _put_raw {
	my ($self, @raw_data) = @_;
	$self->_put_data(@raw_data);
	return;
}

1;

__END__

=pod

=encoding utf8

=head1 NAME

 Tags::Output::PYX - PYX class for line oriented output for 'Tags'.

=head1 SYNOPSYS

 use Tags::Output::PYX;

 my $obj = Tags::Output::PYX->new(%parameters);
 $obj->finalize;
 my $ret = $obj->flush($reset_flag);
 my @tags = $obj->open_tags;
 $obj->put(@data);
 $obj->reset;

=head1 PYX LINE CHARS

 ?  - Instruction.
 (  - Open tag.
 )  - Close tag.
 A  - Attribute.
 -  - Normal data.

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
 If defined 'output_handler' flush to its.
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
         Bad data.
         Bad type of data.
         Bad number of arguments. 'Tags' structure %s 
         Ending bad tag: '%s' in block of tag '%s'.

=head1 EXAMPLE

 use strict;
 use warnings;

 use Tags::Output::PYX;

 # Object.
 my $tags = Tags::Output::PYX->new;

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
 print $tags->flush."\n";

 # Output:
 # (tag
 # Apar val
 # -<!--data--><!--SCALAR(0x1570740)-->
 # )tag
 # ?target data
 # (tag
 # -datadata
 # )tag

=head1 DEPENDENCIES

L<Error::Pure>,
L<Readonly>,
L<Tags::Output>,
L<Tags::Utils>.

=head1 SEE ALSO

=over

=item L<Tags>

Structure oriented SGML/XML/HTML/etc. elements manipulation.

=item L<Task::PYX>

Install the PYX modules.

=item L<Task::Tags>

Install the Tags modules.

=back

=head1 REPOSITORY

L<https://github.com/michal-josef-spacek/Tags-Output-PYX>

=head1 AUTHOR

Michal Josef Špaček L<skim@cpan.org>

=head1 LICENSE AND COPYRIGHT

© 2011-2020 Michal Josef Špaček

BSD 2-Clause License

=head1 VERSION

0.04

=cut
