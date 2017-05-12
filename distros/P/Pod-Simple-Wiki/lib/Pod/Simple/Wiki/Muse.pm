package Pod::Simple::Wiki::Muse;

###############################################################################
#
# Pod::Simple::Wiki::Muse - A class for creating Pod to Muse filters.
#
#
# Copyright 2015, Marco Pessotto melmothx@gmail.com
#
# Documentation after __END__
#

# perltidy with the following options: -mbl=2 -pt=0 -nola

use Pod::Simple::Wiki;
use strict;
use warnings;
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
    '<i>'    => '*',
    '</i>'   => '*',
    '<tt>'   => '<code>',
    '</tt>'  => '</code>',
    '<pre>'  => "\n<example>\n",
    '</pre>' => "\n</example>\n",

    '<h1>'  => "** ",
    '</h1>' => "\n\n",
    '<h2>'  => "*** ",
    '</h2>' => "\n\n",
    '<h3>'  => "**** ",
    '</h3>' => "\n\n",
    '<h4>'  => "***** ",
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
    my ($self, $item_type, $param) = @_;
    # print "Indent level is $self->{_item_indent}\n";
    my $indent_level = $self->{_item_indent} - 1;
    if ( $item_type eq 'bullet' ) {
        $self->_append( "\n" . '  ' x $indent_level . ' - ' );
    }
    elsif ( $item_type eq 'number' ) {
        $self->_append( "\n" . '  ' x $indent_level . ' 1. ' );
    }
    elsif ( $item_type eq 'text' ) {
        $self->_append( "\n" . '  ' x $indent_level . '  ' );
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

    # Only escape words in paragraphs
    if ( not $self->{_in_Para} ) {
        $self->{_wiki_text} .= $text;
        return;
    }

    # Split the text into tokens but maintain the whitespace
    my @tokens = split /(\s+)/, $text;

    # Portme:
    # Escape any tokens here, if necessary.

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
    $self->_output( " :: ");
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
        $self->_append( "\n" . '  ' x $indent_level . '  ' );
    }
}

sub _start_L {
    my ($self, $link_attrs) = @_;
    # print Dumper($link_attrs);
    # reset the buffer
    $self->_output('');
    $self->{_link_attr} = $link_attrs;
    my $link_target  = $link_attrs->{to};
    my $link_section = $link_attrs->{section};
    $link_target = '' if( !defined($link_target));

    # Handle links that are parsed as Pod links.
    if ( defined $link_section ) {
        $link_target = "$link_target#$link_section";
    }
    $self->_append( "[[$link_target][" );
}

sub _end_L {
    my $self         = shift;
    $self->_output(']]');
}

1;


__END__


=head1 NAME

Pod::Simple::Wiki::Muse - A class for creating Pod to Muse wiki filters.

=head1 SYNOPSIS

This module isn't used directly. Instead it is called via C<Pod::Simple::Wiki>:

    #!/usr/bin/perl -w

    use strict;
    use Pod::Simple::Wiki;


    my $parser = Pod::Simple::Wiki->new('muse');

    ...


Convert Pod to a Muse wiki format using the installed C<pod2wiki> utility:

    pod2wiki --style muse file.pod > file.wiki


=head1 DESCRIPTION

The C<Pod::Simple::Wiki::Muse> module is used for converting Pod text to Wiki text.

Pod (Plain Old Documentation) is a simple markup language used for writing Perl documentation.

For an introduction to Muse see:
L<http://www.gnu.org/software/emacs-muse/>.

For a Muse parser you may want to look at L<Text::Amuse> and
L<Text::Amuse::Compile>

For a wiki engine written in perl using this markup, please see
L<https://amusewiki.org>.

This module isn't generally invoked directly. Instead it is called via
C<Pod::Simple::Wiki>. See the L<Pod::Simple::Wiki> and L<pod2wiki>
documentation for more information.


=head1 METHODS

Pod::Simple::Wiki::Muse inherits all of the methods of C<Pod::Simple> and C<Pod::Simple::Wiki>. See L<Pod::Simple> and L<Pod::Simple::Wiki> for more details.

=head1 Muse Specific information

=head1 SEE ALSO

This module also installs a C<pod2wiki> command line utility. See C<pod2wiki --help> for details.


=head1 ACKNOWLEDGEMENTS

This module was written during the Perl Dancer Conference in Vienna,
October 19 2015 at the Metalab.

=head1 DISCLAIMER OF WARRANTY

Please refer to the DISCLAIMER OF WARRANTY in L<Pod::Simple::Wiki>.


=head1 AUTHORS

John McNamara jmcnamara@cpan.org

Marco Pessotto melmothx@gmail.com

=head1 COPYRIGHT

MMIII-MMXV, John McNamara.
2015, Marco Pessotto.

All Rights Reserved. This module is free software. It may be used, redistributed and/or modified under the same terms as Perl itself.
