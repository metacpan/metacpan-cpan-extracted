package Pod::Simple::Wiki::Confluence;

###############################################################################
#
# Pod::Simple::Wiki::Confluence - A class for creating Pod to Confluence filters.
#
#
# Copyright 2003-2012, John McNamara, jmcnamara@cpan.org
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
    '<b>'    => '*',
    '</b>'   => '*',
    '<i>'    => '_',
    '</i>'   => '_',
    '<tt>'   => '{{',
    '</tt>'  => '}}',
    '<pre>'  => "{noformat}\n",
    '</pre>' => "\n{noformat}\n",

    '<h1>'  => 'h1. ',
    '</h1>' => "\n\n",
    '<h2>'  => 'h2. ',
    '</h2>' => "\n\n",
    '<h3>'  => 'h3. ',
    '</h3>' => "\n\n",
    '<h4>'  => 'h4. ',
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
    my $indent_level = $self->{_item_indent};

    if ( $item_type eq 'bullet' ) {
        $self->_append( '*' x $indent_level . ' ' );
    }
    elsif ( $item_type eq 'number' ) {
        $self->_append( '#' x $indent_level . ' ' );
    }

    # Confluence doesn't have the equivalent of a <dl> list so we use a
    # bullet list with a bolded "item" as a workaround.
    elsif ( $item_type eq 'text' ) {
        $self->_append( '*' x $indent_level . ' *' );
    }
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

    # Split the text into tokens but maintain the whitespace
    my @tokens = split /(\s+)/, $text;

    # Escape any tokens here, if necessary.
    @tokens = map { s/([[{*_-])/\\$1/g; $_ } @tokens;

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
sub _end_item_text { $_[0]->_output( '* ' ) }


###############################################################################
#
# _start_Para()
#
# Special handling for paragraphs that are part of an "over" block.
#
sub _start_Para {

    my $self         = shift;
    my $indent_level = $self->{_item_indent};

    if ( $self->{_in_over_block} ) {
        $self->_append( 'bq. ' );
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

    # Handle links that are parsed as Pod links.
    if ( defined $link_section ) {
        $link_target = $link_section;

        # Remove quotes around link name.
        $self->{_wiki_text} =~ s/^"//;
        $self->{_wiki_text} =~ s/"$//;
    }

    # Only write [text|link] if text and link are different.
    if ( $self->{_wiki_text} ne $link_target ) {
        $self->_append( "|$link_target]" );
    }
    else {
        $self->_append( "]" );
    }
}


1;


__END__


=head1 NAME

Pod::Simple::Wiki::Confluence - A class for creating Pod to Confluence wiki filters.

=head1 SYNOPSIS

This module isn't used directly. Instead it is called via C<Pod::Simple::Wiki>:

    #!/usr/bin/perl -w

    use strict;
    use Pod::Simple::Wiki;


    my $parser = Pod::Simple::Wiki->new('confluence');

    ...


Convert Pod to a Confluence wiki format using the installed C<pod2wiki> utility:

    pod2wiki --style confluence file.pod > file.wiki


=head1 DESCRIPTION

The C<Pod::Simple::Wiki::Confluence> module is used for converting Pod text to Wiki text.

Pod (Plain Old Documentation) is a simple markup language used for writing Perl documentation.

For an introduction to Confluence see: L<http://www.atlassian.com/software/confluence/>

This module isn't generally invoked directly. Instead it is called via C<Pod::Simple::Wiki>. See the L<Pod::Simple::Wiki> and L<pod2wiki> documentation for more information.


=head1 METHODS

Pod::Simple::Wiki::Confluence inherits all of the methods of C<Pod::Simple> and C<Pod::Simple::Wiki>. See L<Pod::Simple> and L<Pod::Simple::Wiki> for more details.


=head1 SEE ALSO

This module also installs a C<pod2wiki> command line utility. See C<pod2wiki --help> for details.


=head1 ACKNOWLEDGEMENTS

Thanks to David Bartle, Andrew Hobbs and Jim Renwick for patches.


=head1 DISCLAIMER OF WARRANTY

Please refer to the DISCLAIMER OF WARRANTY in L<Pod::Simple::Wiki>.


=head1 AUTHORS

John McNamara jmcnamara@cpan.org


=head1 COPYRIGHT

MMIII-MMXV, John McNamara.

All Rights Reserved. This module is free software. It may be used, redistributed and/or modified under the same terms as Perl itself.
