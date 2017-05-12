package Pod::Simple::Wiki::Markdown;

###############################################################################
#
# Pod::Simple::Wiki::Markdown - A class for creating Pod to Markdown filters.
#
#
# Copyright 2003-2014, John McNamara, jmcnamara@cpan.org, Daniel T. Staal,
# DStaal@usa.net
#
# Documentation after __END__
#

# perltidy with the following options: -mbl=2 -pt=0 -nola

use Pod::Simple::Wiki;
use strict;
use vars qw(@ISA $VERSION);


@ISA     = qw(Pod::Simple::Wiki);
$VERSION = '0.20';

###############################################################################
#
# The tag to wiki mappings.
#
my $tags = {
    '<b>'    => '**',
    '</b>'   => '**',
    '<i>'    => '_',
    '</i>'   => '_',
    '<tt>'   => '`',
    '</tt>'  => '`',
    '<pre>'  => "\n```\n",
    '</pre>' => "\n```\n",

    '<h1>'  => '# ',
    '</h1>' => "\n\n",
    '<h2>'  => '## ',
    '</h2>' => "\n\n",
    '<h3>'  => '### ',
    '</h3>' => "\n\n",
    '<h4>'  => '#### ',
    '</h4>' => "\n\n",
};

###############################################################################
#
# new()
#
# Simple constructor inheriting from Pod::Simple::Wiki.
#
sub new {

    my $class = shift;
    my $self = Pod::Simple::Wiki->new( 'wiki', @_ );
    $self->{_tags} = $tags;

    bless $self, $class;
    return $self;
}

###############################################################################
#
# _indent_item()
#
# Indents an "over-item" to the correct level.
#
sub _indent_item {

    my $self         = shift;
    my $item_type    = $_[0];
    my $item_param   = $_[1];
    my $indent_level = $self->{_item_indent} - 1;

    if ( $item_type eq 'bullet' ) {
        $self->_append( '    ' x $indent_level . '* ' );
    }
    elsif ( $item_type eq 'number' ) {
        $self->_append( '    ' x $indent_level . '1 ' );
    }

# In theory Markdown supports nested definition lists - but *everything* has to be indented.
    elsif ( $item_type eq 'text' ) {
        $self->_append( '    ' x $indent_level . '' );
    }
}

###############################################################################
#
# _start_L()
#
# Handle the start of a link element.
#
sub _start_L {

    my $self       = shift;
    my $link_attrs = shift;

    $self->{_link_attrs} = $link_attrs;

    # Ouput start of Confluence link and flush the _wiki_text buffer.
    $self->_output( '[' );
}


###############################################################################
#
# _end_L()
#
# Handle the end of a link element.
#
sub _end_L {

    my $self         = shift;
    my $link_attrs   = $self->{_link_attrs};
    my $link_target  = $link_attrs->{to};
    my $link_section = $link_attrs->{section};

	$link_target = '' if( !defined($link_target));

    # Handle links that are parsed as Pod links.
    if ( defined $link_section ) {
        $link_target = "$link_target#$link_section";
    }

	$self->_append( "]($link_target)" );
}

###############################################################################
#
# _handle_text()
#
# Perform any necessary transforms on the text. This is mainly used to escape
# inadvertent CamelCase words.
#
sub _handle_text {

    my $self = shift;
    my $text = $_[0];

    # Only escape words in paragraphs
    if ( not $self->{_in_Para} ) {
        $self->{_wiki_text} .= $text;
        return;
    }

    # Split the text into tokens but maintain the whitespace
    my @tokens = split /(\s+)/, $text;

    # Escape any tokens here, if necessary.
    # The following characters are escaped by prepending a backslash: \`*_
    # (Markdown has other escapes as well, but these cover most cases, and the others
    # are usually optional.)
    @tokens = map { s/([\\`\*\_])/\\$1/g; $_ } @tokens;

    # Rejoin the tokens and whitespace.
    $self->{_wiki_text} .= join '', @tokens;
}


###############################################################################
#
# Functions to deal with =over ... =back regions for
#
# Bulleted lists
# Numbered lists
# Text     lists
# Block    lists
#
sub _end_item_text {
    my $self         = shift;
    my $indent_level = $self->{_item_indent} - 1;

    $self->_output( "\n" . '    ' x $indent_level . ':   ' );
}


###############################################################################
#
# _start_Para()
#
# Special handling for paragraphs that are part of an "over" block.
#
sub _start_Para {

    my $self         = shift;
    my $indent_level = $self->{_item_indent} - 1;

    if ( $self->{_in_over_block} ) {
        $self->_append( '    ' x $indent_level . '' );
    }
}


1;


__END__


=head1 NAME

Pod::Simple::Wiki::Markdown - A class for creating Pod to Markdown wiki filters.

=head1 SYNOPSIS

This module isn't used directly. Instead it is called via C<Pod::Simple::Wiki>:

    #!/usr/bin/perl -w

    use strict;
    use Pod::Simple::Wiki;


    my $parser = Pod::Simple::Wiki->new('markdown');

    ...


Convert Pod to a markdown wiki format using the installed C<pod2wiki> utility:

    pod2wiki --style markdown file.pod > file.wiki


=head1 DESCRIPTION

The C<Pod::Simple::Wiki::Markdown> module is used for converting Pod text to Markdown text.

Pod (Plain Old Documentation) is a simple markup language used for writing Perl documentation.

This module isn't generally invoked directly. Instead it is called via C<Pod::Simple::Wiki>. See the L<Pod::Simple::Wiki> and L<pod2wiki> documentation for more information.

=head1 METHODS

Pod::Simple::Wiki::Markdown inherits all of the methods of C<Pod::Simple> and C<Pod::Simple::Wiki>. See L<Pod::Simple> and L<Pod::Simple::Wiki> for more details.

=head1 Markdown Specific information

Some format features of Pod are not present in base Markdown (and vice-versa).  In particular this module supports both code blocks and definition lists - in a somewhat inconsistent fashion.  Code blocks are supported using GitHub Markdown syntax: three backticks at the start and end of the codeblock.  Definition lists are (crudely) supported in the PHP Markdown Extra syntax: A colon followed by three spaces starting the line with the definition.  PHP Markdown Extra works with the GitHub syntax, so this should not cause a problem.  (GitHub does not support definition lists.)  This module also creates nested definition lists - which may or may not be supported.  (And may need extra newlines entered, which is beyond the technical limits of this module.)

Links are always output in the universal [link text](link source) format, even when it's redundant, or overlong.  Anything POD considers a link will be treated as one, even if it's not a valid link.  (In particular, automatic 'man page' links will not point to anything useful - the user will be required to turn C<(Pod::Simple)> into something useful, likely your favorite interface for CPAN.)

Escapes are automatically applied to asterisks, underscores, backticks, and backslashes, and they are always required.  Markdown provides escapes for other characters (in particular braces and parenthesis), but they are not required in all cases.  I leave it up to the user to determine when they would be considered formatting and when they wouldn't.

=head1 SEE ALSO

This module also installs a C<pod2wiki> command line utility. See C<pod2wiki --help> for details.

=head1 ACKNOWLEDGEMENTS

Thanks to Daniel T. Staal for patches, documentation or bugfixes.

=head1 DISCLAIMER OF WARRANTY

Please refer to the DISCLAIMER OF WARRANTY in L<Pod::Simple::Wiki>.

=head1 AUTHORS

John McNamara jmcnamara@cpan.org

Daniel T. Staal DStaal@usa.net


=head1 COPYRIGHT

MMIII-MMXV, John McNamara, Daniel T. Staal

All Rights Reserved. This module is free software. It may be used, redistributed and/or modified under the same terms as Perl itself.
