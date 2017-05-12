
=head1 NAME

TeX::DVI::Parse - parse TeX's DVI output file

=cut

package TeX::DVI::Parse;

use FileHandle;

$VERSION = '1.01';

sub make_dim
	{
	if (scalar(@_) == 8) {
		return make_dim(@_[0 .. 3]), make_dim(@_[4 .. 7]);
	}
	my $result = shift;
	while (@_) { $result = $result * 256 + shift; }
	$result;
	}
sub make_fnt_def
	{
	my $in_buffer = pop @_;
	my ($c, $s, $d, $a, $l, $buffer) = unpack "NNNCCa*", $in_buffer;
	my $len = $a + $l;
	return @_, ($c, $s, $d, $a, $l), unpack "a${len}a*", $buffer;
	}
sub make_special
	{
	my ($num, $len, $buffer) = @_;
	return $num, $len, unpack "a${len}a*", $buffer;
	}
@COMMANDS = (
	( [ "set_char", sub { ( $_[0], @_ ); } ] ) x 128,
	[ "set_char", "C" ],
	[ "set_char", "CC", 2 ],
	[ "set_char", "CCC", 3 ],
	[ "set_char", "cCCC", 4 ],
	[ "set_rule", "cCCCcCCC", 8 ],
	[ "put_char", "C" ],
	[ "put_char", "CC", 2 ],
	[ "put_char", "CCC", 3 ],
	[ "put_char", "CCCC", 4 ],
	[ "put_rule", "cCCCcCCC", 8 ],
	"nop",
	[ "bop", "NNNNNNNNNNcCCC", 4 ],
	"eop",
	"push",
	"pop",
	[ "right", "c" ],
	[ "right", "cC", 2 ],
	[ "right", "cCC", 3 ],
	[ "right", "cCCC", 4 ],
	"move_w",
	[ "move_w", "c" ],
	[ "move_w", "cC", 2 ],
	[ "move_w", "cCC", 3 ],
	[ "move_w", "cCCC", 4 ],
	"move_x",
	[ "move_x", "c" ],
	[ "move_x", "cC", 2 ],
	[ "move_x", "cCC", 3 ],
	[ "move_x", "cCCC", 4 ],
	[ "down", "c" ],
	[ "down", "cC", 2 ],
	[ "down", "cCC", 3 ],
	[ "down", "cCCC", 4 ],
	"move_y",
	[ "move_y", "c" ],
	[ "move_y", "cC", 2 ],
	[ "move_y", "cCC", 3 ],
	[ "move_y", "cCCC", 4 ],
	"move_z",
	[ "move_z", "c" ],
	[ "move_z", "cC", 2 ],
	[ "move_z", "cCC", 3 ],
	[ "move_z", "cCCC", 4 ],
	( [ "fnt_num", sub { ($_[0], $_[0] - 171, $_[-1]); } ] ) x 64,
	[ "fnt_num", "C" ],
	[ "fnt_num", "CC", 2 ],
	[ "fnt_num", "CCC", 3 ],
	[ "fnt_num", "cCCC", 4 ],
	[ "special", "C", \&make_special ],
	[ "special", "CC", 2, \&make_special ],
	[ "special", "CCC", 3, \&make_special ],
	[ "special", "CCCC", 4, \&make_special ],
	[ "fnt_def", "C", \&make_fnt_def ],
	[ "fnt_def", "CC", 2, \&make_fnt_def ],
	[ "fnt_def", "CCC", 3, \&make_fnt_def ],
	[ "fnt_def", "cCCC", 4, \&make_fnt_def ],
	[ "preamble", "CNNNC",
		sub { my $buffer = pop @_;
			return @_, unpack "a$_[5]a*", $buffer; } ],
	[ "post", "NNNNNNnn" ],
	[ "post_post", "NCa*"],
	"undefined_command",
	);

sub new
	{
	my $class = shift;
	my $self = {};
	my $filename = shift;
	$self->{'fh'} = new FileHandle($filename);
	binmode $self->{'fh'};
	bless $self, $class;
	$self;
	}
sub parse
	{
	my $self = shift;
	my $oldselect = select;
	local $/ = undef;
	## print STDERR "Parse started\n";
	my $buffer = $self->{'fh'}->getline();
	## print STDERR "File loaded\n";
	while (length $buffer > 0)
		{
		my $ord = ord $buffer;
		$buffer = substr $buffer, 1;
		my $command = $COMMANDS[$ord];
		if (ref $command and ref $command eq 'ARRAY')
			{
			my @list = ( $ord, $buffer );
			my $i = 1;
			if (not ref $command->[1])
				{
				@list = ($ord, unpack $command->[1] . "a*", $buffer);
				$i = 2;
				}
			while (defined $command->[$i])
				{
				if (ref $command->[$i])
					{ @list = &{$command->[$i]}(@list); }
				else
					{
					my $buffer = pop @list;
					my @num = splice @list, -$command->[$i];
					push @list, make_dim(@num), $buffer;
					}
				$i++;
				}
			$buffer = pop @list;
			my $can;
			if ($can = $self->can($command->[0]))
				{ &$can($self, @list) };
			}
		else
			{
			my $can;
			if ($can = $self->can($command))
				{ &$can($self, $ord) };
			}
		}
	select($oldselect);
	## print STDERR "Parse finished\n";
	}

package TeX::DVI::Print;
@ISA = qw( TeX::DVI::Parse );

sub set_char
	{
	my ($self, $ord, $char) = @_;
	print "Set ch\t$ord, $char";
	print " '", chr $char, "'" if $char >= 32 and $char <= 255;
	print "\n";
	}
sub set_rule
	{
	my ($self, $ord, $height, $width) = @_;
	print "Set rul\t$ord, height: $height, width: $width\n";
	}
sub put_char
	{
	my ($self, $ord, $char) = @_;
	print "Put ch\t$ord, $char";
	print " '", chr $ord, "'" if $ord >= 32 and $ord <= 255;
	print "\n";
	}
sub put_rule
	{
	my ($self, $ord, $height, $width) = @_;
	print "Put rul\t$ord, height: $height, width: $width\n";
	}
sub nop
	{ my ($self, $ord) = @_; print "Nop\t$ord\n"; }
sub bop
	{
	my ($self, $ord, @numbers) = @_;
	$prev_page = pop @numbers;
	print "Bop\t$ord, id: [@numbers], previous page: $prev_page\n";
	}
sub eop
	{ my ($self, $ord) = @_; print "Eop\t$ord\n"; }
sub push
	{ my ($self, $ord) = @_; print "Push\t$ord\n"; }
sub pop
	{ my ($self, $ord) = @_; print "Pop\t$ord\n"; }
sub right
	{ my ($self, $ord, $value) = @_; print "Right\t$ord, value: $value\n"; }
sub move_w
	{
	my ($self, $ord, $value) = @_;
	$value = 'no_b' unless defined $value;
	print "Move w\t$ord, value: $value\n";
	}
sub move_x
	{
	my ($self, $ord, $value) = @_;
	$value = 'no_b' unless defined $value;
	print "Move x\t$ord, value: $value\n";
	}
sub down
	{
	my ($self, $ord, $value) = @_;
	print "Down\t$ord, value: $value\n";
	}
sub move_y
	{
	my ($self, $ord, $value) = @_;
	$value = 'no_b' unless defined $value;
	print "Move y\t$ord, value: $value\n";
	}
sub move_z
	{
	my ($self, $ord, $value) = @_;
	$value = 'no_b' unless defined $value;
	print "Move z\t$ord, value: $value\n";
	}
sub fnt_num
	{
	my ($self, $ord, $k) = @_;
	print "Fnt num\t$ord, k: $k\n";
	}
sub special
	{
	my ($self, $ord, $len, $text) = @_;
	print "Spec\t$ord, len: $len\n\t`$text'\n";
	}
sub fnt_def
	{
	my ($self, $ord, $k, $c, $s, $d, $a, $l, $name) = @_;
	print "Fnt def\t$ord, k: $k, name: $name\n";
	}
sub preamble
	{
	my ($self, $ord, $i, $num, $den, $mag, $k, $text) = @_;
	print "Pream\t$ord, i: $i, num: $num, den: $den, mag: $mag, k: $k\n\t`$text'\n";
	}
sub post
	{
	my ($self, $ord, $prev, $num, $den, $mag, $l, $u, $s, $t) = @_;
	print "Post\t$ord, prev: $prev, num: $num, den: $den, mag: $mag, \n\tl: $l, u: $u, s: $s, t: $t\n";
	}
sub post_post
	{
	my ($self, $ord, $q, $i, $rest) = @_;
	print "PPost\t$ord, q: $q, i: $i\n";
	print "\tWrong end of DVI\n"
		unless $rest =~ /^\337{4,7}$/;
	}
sub undefined_command
	{
	print "Undefined command\n";
	}
1;

=head1 SYNOPSIS

	use TeX::DVI::Parse;
	my $dvi_parse = new TeX::DVI::Parse("test.dvi");
	$dvi_parse->parse();

=head1 DESCRIPTION

I have created this module on request from Mirka Misáková. She wanted
to do some post-processing on the DVI file and I said that it will be
better to parse the DVI file directly, instead of the output of the
B<dvitype> program.

As the result there is this module B<TeX::DVI::Parse> that recognizes
all commands from the DVI file and for each command found it calls
method of appropriate name, if defined in the class.

The example above is not very reasonable because the core
B<TeX::DVI::Parse> module doesn't itself define any methods for the
DVI commands. You will probably want to inherit a new class and define
the functions yourself:

	packages My_Parse_DVI;
	use TeX::DVI::Parse;
	@ISA = qw( TeX::DVI::Parse );

	sub set_char
		{
		my ($self, $ord, $char) = @_;
		## print the info or something;
		}

As an example there is class B<TeX::DVI::Print> coming in this file,
so you can do

	use TeX::DVI::Parse;
	my $dvi_parse = new TeX::DVI::Print("test.dvi");
	$dvi_parse->parse();

and get listing of DVI's content printed in (hopefully) readable form.

=head2 Methods

For creating new classes, a documentation of expected methods names
and their parameters is necessary, so here is the list. The names come
from the B<dvitype> documentation and that is also the basic reference
for the meaning of the parameters. Note that each method receives as
the first two parameters I<$self> and I<$ord>, reference to the parsing
object and the byte value of the command as found in the DVI file.
These are mandatory so only the other parameters to each method are
listed below.

=over 4

=item set_char -- typeset character and shift right by its width

I<$char> -- specifies the ordinal value of the character.

=item put_char -- as B<set_char> but without moving

I<$char> -- ordinal value of the character.

=item set_rule -- typeset black rectangle and shift to the right

I<$height>, I<$width> -- dimensions of the rectangle.

=item put_rule -- as B<set_rule> without moving

I<$height>, I<$width> -- dimensions of the rectangle.

=item nop -- no operation

no parameter

=item bop -- begin of page

I<$number[0]> .. I<$number[9]>, I<$prev_page> -- the ten numbers
that specify the page, the pointer to the start of the previous page.

=item eop -- end of page

no parameter

=item push -- push to the stack

no parameter

=item pop -- pop from the stack

no parameter

=item right -- move right

I<$value> -- how much to move.

=item move_w, move_x, down, move_y, move_z -- move position

all take one parameter, I<$value>.

=item fnt_def -- define font

I<$k>, I<$c>, I<$s>, I<$d>, I<$a>, I<$l>, I<$n> -- number of the font, 
checksum, scale factor, design size, length of the directory and length
of the filename, name of the font.

=item fnt_num -- select font

I<$k> -- number of the font.

=item special -- generic DVI primitive 

I<$k>, I<$x> -- length of the special and its data.

=item preamble

I<$i>, I<$num>, I<$den>, I<$mag>, I<$k>, I<$x> -- ID of the format,
numerator and denumerator of the multiplication fraction,
magnification, length of the comment and comment.

=item post -- postamble

I<$p>, I<$num>, I<$den>, I<$mag>, I<$l>, I<$u>, I<$s>, I<$t> -- pointer
to the last page, the next three are as in preamble, maximal dimensions
(I<$l> and I<$u>), maximal depth of the stack and the final page number.

=item post_post -- post postamble

I<$q>, I<$i>, I<$dummy> -- pointer to the postamble, ID and the last fill.

=item undefined_command -- for byte that has no other meaning

no parameter

=back

=head1 VERSION

1.01

=head1 AVAILABLE FROM

http://www.adelton.com/perl/TeX-DVI/

=head1 AUTHOR

(c) 1996--2011 Jan Pazdziora.

All rights reserved. This package is free software; you can
redistribute it and/or modify it under the same terms as Perl itself.

Contact the author at jpx dash perl at adelton dot com.

=head1 SEE ALSO

Font::TFM(3), TeX::DVI(3), perl(1).

=cut

