package Pod::Simple::Wiki::Kwiki;

###############################################################################
#
# Pod::Simple::Wiki::Kwiki - A class for creating Pod to Kwiki filters.
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
    '<i>'    => '/',
    '</i>'   => '/',
    '<tt>'   => '[=',
    '</tt>'  => ']',
    '<pre>'  => '',
    '</pre>' => "\n\n",

    '<h1>'  => "\n----\n= ",
    '</h1>' => " =\n\n",
    '<h2>'  => "\n== ",
    '</h2>' => " ==\n\n",
    '<h3>'  => "\n=== ",
    '</h3>' => " ===\n\n",
    '<h4>'  => "==== ",
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
        $self->_append( '0' x $indent_level . ' ' );
    }
    elsif ( $item_type eq 'text' ) {
        $self->_append( ';' x $indent_level . ' ' );
    }
}


###############################################################################
#
# _skip_headings()
#
# Formatting in headings doesn't look great or is ignored in some formats.
#
sub _skip_headings {

    my $self = shift;

    if (   $self->{_in_head1}
        or $self->{_in_head2}
        or $self->{_in_head3}
        or $self->{_in_head4} )
    {
        return 1;
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

    # Only escape CamelCase in Kwiki paragraphs
    if ( not $self->{_in_Para} ) {
        $self->{_wiki_text} .= $text;
        return;
    }

    # Split the text into tokens but maintain the whitespace
    my @tokens = split /(\s+)/, $text;

    for ( @tokens ) {
        next unless /\S/;    # Ignore the whitespace
        next if m[^(ht|f)tp://];    # Ignore URLs
        s/([A-Z][a-z]+[A-Z]\w+)/!$1/g;    # Escape with !
    }

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
sub _end_item_text { $_[0]->_output( ' ; ' ) }


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

        # Do something here is necessary
    }
}


###############################################################################
#
# _end_Para()
#
# Special handling for paragraphs that are part of an "over_text" block.
# This is mainly required  be Kwiki.
#
sub _end_Para {

    my $self = shift;

    # Only add a newline if the paragraph isn't part of a text.
    if ( $self->{_in_over_text} ) {

        # Workaround for the fact that Kwiki doesn't have a definition block.
        #$self->_output("\n");
    }
    else {
        $self->_output( "\n" );
    }

    $self->_output( "\n" );
}


1;


__END__


=head1 NAME

Pod::Simple::Wiki::Kwiki - A class for creating Pod to Kwiki wiki filters.

=head1 SYNOPSIS

This module isn't used directly. Instead it is called via C<Pod::Simple::Wiki>:

    #!/usr/bin/perl -w

    use strict;
    use Pod::Simple::Wiki;


    my $parser = Pod::Simple::Wiki->new('kwiki');

    ...


Convert Pod to a Kwiki wiki format using the installed C<pod2wiki> utility:

    pod2wiki --style kwiki file.pod > file.wiki


=head1 DESCRIPTION

The C<Pod::Simple::Wiki::Kwiki> module is used for converting Pod text to Wiki text.

Pod (Plain Old Documentation) is a simple markup language used for writing Perl documentation.

For an introduction to Kwiki see: L<http://www.kwiki.org>

This module isn't generally invoked directly. Instead it is called via C<Pod::Simple::Wiki>. See the L<Pod::Simple::Wiki> and L<pod2wiki> documentation for more information.


=head1 METHODS

Pod::Simple::Wiki::Kwiki inherits all of the methods of C<Pod::Simple> and C<Pod::Simple::Wiki>. See L<Pod::Simple> and L<Pod::Simple::Wiki> for more details.


=head1 SEE ALSO

This module also installs a C<pod2wiki> command line utility. See C<pod2wiki --help> for details.


=head1 ACKNOWLEDGEMENTS

Submit a bugfix or test and your name will go here.


=head1 DISCLAIMER OF WARRANTY

Please refer to the DISCLAIMER OF WARRANTY in L<Pod::Simple::Wiki>.


=head1 AUTHORS

John McNamara jmcnamara@cpan.org


=head1 COPYRIGHT

MMIII-MMXV, John McNamara.

All Rights Reserved. This module is free software. It may be used, redistributed and/or modified under the same terms as Perl itself.
