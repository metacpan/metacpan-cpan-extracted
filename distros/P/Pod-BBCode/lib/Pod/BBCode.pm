# $Id: BBCode.pm,v 1.5 2005/05/15 13:51:33 chaos Exp $
# $Log: BBCode.pm,v $
# Revision 1.5  2005/05/15 13:51:33  chaos
# fixed a little bug on processing whitespaces
#
# Revision 1.4  2005/05/15 13:45:17  chaos
# stripped ending whitespaces in verbatim paragraph
#
# Revision 1.3  2005/05/15 06:14:53  chaos
# change version back to numeric
#
# Revision 1.2  2005/05/09 12:15:00  chaos
# modified tag
#
# Revision 1.1  2005/05/09 12:13:34  chaos
# Pod::BBCode
#
# vim:ts=4 sw=4
package Pod::BBCode;
use strict;
use Pod::Parser;
use vars qw/ @ISA $VERSION /;

$VERSION = '1.5';
@ISA = qw/ Pod::Parser /;

sub command
{
    my ($self, $command, $paragraph, $line_num) = @_;

    my $expansion;
    my $out_fh =  $self->output_handle();
	my ($headColor,$itemColor)=($self->{-headcolor},$self->{-itemcolor});
	
    for ( $command ) {
        /pod/ || /cut/ and return;
        /begin/ and do {
            $self->{ignore_section} = 1;
            return;
        };
        /end/ and do {
            $self->{ignore_section} = 0;
            return;
        };
        /head(\d)/ and do {
            $expansion = $self->interpolate($paragraph, $line_num);
			# convert =head[1-4] to [highlight][size=[5-2]][/size][/highlight]
			$expansion = "\n"
						. "[size=" . (6-$1) . "]"
						. ($headColor ? "[color=$headColor]" : '')
						. $expansion
						. ($headColor ? "[/color]" : '')
						. "[/size]"
						. "\n";
            last;
        };
        /over/ and do {
            push @{$self->{lists}}, undef;
			# the opening [list] tag's option can be only determined later
			# we can do nothing here
            return;
        };
        /back/ and do {
            pop @{$self->{lists}};
			$expansion = "[/list]\n";
            last;
        };
        /item/ and do {
			if(!defined($self->{lists}[-1])) {
				# this is the first item
				$self->{lists}[-1] =
					($paragraph =~ /^\d+\.?\s*/)
					? '1' 
					: '';	# we consider text item name to be the same as asterisk
				if($self->{lists}[-1] eq '1') {
					# numeric list
					$expansion = "[list=1]\n";
				} else {
					# asterisk list
					$expansion = "[list]\n";
				}
			} else {
				# this is the following item
				$expansion = ''
			}
			
			# strip item names
            $paragraph =~ s/^[*o-]+\s*//;
            $paragraph =~ s/^\d+\.?\s*//;

            $expansion .= '[*]'
							. ($itemColor ? "[color=$itemColor]" : '')
							. $self->interpolate($paragraph, $line_num)
							. ($itemColor ? "[/color]" : '')
							. "\n";
            last;
        };
    }

    print $out_fh $expansion;
}

sub textblock
{
    my ($self, $paragraph, $line_num) = @_;
    return if $self->{ignore_section};

	my $textColor=$self->{-textcolor};

    my $expansion = $self->interpolate($paragraph, $line_num);

    my $out_fh = $self->output_handle();
    print $out_fh ($textColor ? "[color=$textColor]" : '')
					. $expansion
					. ($textColor ? "[/color]" : '')
					. "\n";
}

sub interior_sequence
{
    my ($self, $seq_command, $seq_argument) = @_;

    my %markup = (
        B => [ '[b]', '[/b]' ],		# boldface
        I => [ '[i]', '[/i]' ],		# italic
        F => [ '[pre]', '[/pre]' ],	# filename
        C => [ '[pre]', '[/pre]' ],	# code
    );
	
    return $markup{$seq_command}[0] . $seq_argument . $markup{$seq_command}[1];
}

sub verbatim
{
    my ($self, $paragraph, $line_num) = @_;

    return if $self->{ignore_section};

    my $out_fh = $self->output_handle();
	# strip ending newlines
    $paragraph =~ s/\s*$//;
	# vBulletin forum doesn't seem to be able to handle text looks like BBCode tag in
	# the middle of tag pair, so we need to convert [] to corresponding HTML entities "&#091;" and "&#093;"
	$paragraph =~ s/\[/&#091;/g;
	$paragraph =~ s/\]/&#093;/g;
	# make paragraph looking like this:
	# [code]
	# ...
	# [/code]
    $paragraph = "[code]\n$paragraph\n[/code]\n"
        if length($paragraph)>0;
    print $out_fh $paragraph;
}

sub interpolate
{
    my $self = shift;
    local $_ = $self->SUPER::interpolate(@_);
    tr/ \t\r\n/ /s;
    s/\s+$//;
    return $_;
}

1;

=head1 NAME

Pod::BBCode - converts a POD file to a page using BB code.

=head1 SYNOPSIS

    use Pod::BBCode;

    my $p = new Pod::BBCode(-headcolor=>'red',-itemcolor=>'blue',-textcolor=>'black');
    $p->parse_from_file('in.pod');

=head1 DESCRIPTION

This class converts a file in POD syntax to the BBCode syntax, in order to simplify
the posting process on vBulletin forums. See any vBulletin forum's help for a description 
of the BBCode syntax.

Pod::BBCode derives from Pod::Parser and therefore inherits all its methods.

This module was modified from Pod::TikiWiki module. Thanks to the original author.

=head2 Supported formatting

=over 4

=item *

Heading directives (C<=head[1234]>) are handled with [size][/size] tag.

    =head1 NAME    --> [size=5]NAME[/size]
    =head2 Methods --> [size=4]Methods[/size]

=item *

List items are rendered with [list=1][/list] (for ordered lists) or [list][/list] (for unordered lists) tag.

    =over               [list]

    =item *
                   -->  [*]
    Text                Text

    =over               [list=1]

    =item 1
                   -->  [*]
    Text                Text

    =back               [/list]

    =back               [/list]

Items with a string are rendered into a asterisked list

    =item Text
                   -->  [*]Text
    Definition          Definition

=item *

Interior sequences C<B>, C<I>, C<F> and C<C> are honored. Both C<F> and C<C>
are rendered as monospaced text.

    B<bold>       --> [b]bold[/b]
    I<italic>     --> [i]italic[/i]
    F<file>       --> [pre]file[/pre]
    C<code>       --> [pre]code[/pre]

=back

=head1 LIMITATIONS

=over

=item *

Only the above four interior sequences are handled. C<S>, C<L>, C<X>, C<E> are
ignored.

=item *

BBCode-like text can't display correctly in non-verbatim environment, so be careful.

=item *

...

=back

=head1 SEE ALSO

L<perlpod>, L<Pod::Parser>

=head1 AUTHOR

chaoslawful (chaoslaw@cpan.org)

This module is free software. You can redistribute and/or modify it under the
terms of the GNU General Public License.

Thanks to the author of Pod::TikiWiki again!

=cut

