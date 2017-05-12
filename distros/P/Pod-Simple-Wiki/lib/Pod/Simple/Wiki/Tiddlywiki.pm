package Pod::Simple::Wiki::Tiddlywiki;

###############################################################################
#
# Pod::Simple::Wiki::Tiddlywiki - A class for creating Pod to Tiddlywiki filters.
#
#
# Copyright 2007, Ron Savage, ron@savage.net.au
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
    '<b>'    => q(''),
    '</b>'   => q(''),
    '<i>'    => '//',
    '</i>'   => '//',
    '<tt>'   => '{{{',
    '</tt>'  => '}}}',
    '<pre>'  => "{{{\n",
    '</pre>' => "\n}}}\n\n",

    '<h1>'  => '!',
    '</h1>' => "\n",
    '<h2>'  => '!!',
    '</h2>' => "\n",
    '<h3>'  => '!!!',
    '</h3>' => "\n",
    '<h4>'  => '!!!!',
    '</h4>' => "\n",
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

# How Pod "=over" blocks are converted to Tiddlywiki wiki lists.

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

    # TiddlyWiki doesn't have the equivalent of a <dl> list so we use a
    # bullet list as a workaround.
    elsif ( $item_type eq 'text' ) {
        $self->_append( '*' x $indent_level . ' ' );
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
    for ( @tokens ) {
        next unless /\S/;    # Ignore the whitespace

        # Escape WikiWords with ~, unless in varbatim section.
        next if $self->{_in_Verbatim};
        next if $self->{_in_C};

        # Escape WikiWords  RT#60650
        s/(?<![A-Za-z0-9])([A-Z]+[-_0-9a-z]+[A-Z]+[-_0-9a-zA-Z]*)/~$1/g;

        # Escape TiddlyWiki formating sequences RT#60304
        s[(([-/'_^~@<>])\2+)][{{{$1}}}]g;
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

# TiddlyWiki doesn't have the equivalent of a <dl> list so we use a
# bullet list as a workaround.
sub _end_item_text { $_[0]->_output( ' ' ) }


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

        # Do something here if necessary
    }
}


1;


__END__

=encoding utf8

=head1 NAME

Pod::Simple::Wiki::Tiddlywiki - A class for creating Pod to Tiddlywiki wiki filters.

=head1 SYNOPSIS

This module isn't used directly. Instead it is called via C<Pod::Simple::Wiki>:

    #!/usr/bin/perl -w

    use strict;
    use Pod::Simple::Wiki;


    my $parser = Pod::Simple::Wiki->new('tiddlywiki');

    ...


Convert Pod to a Tiddlywiki wiki format using the installed C<pod2wiki> utility:

    pod2wiki --style tiddlywiki file.pod > file.wiki


=head1 DESCRIPTION

The C<Pod::Simple::Wiki::Tiddlywiki> module is used for converting Pod text to Wiki text.

Pod (Plain Old Documentation) is a simple markup language used for writing Perl documentation.

For an introduction to Tiddlywiki see: L<http://tiddlywiki.com/>

This module isn't generally invoked directly. Instead it is called via C<Pod::Simple::Wiki>. See the L<Pod::Simple::Wiki> and L<pod2wiki> documentation for more information.

=head1 METHODS

Pod::Simple::Wiki::Tiddlywiki inherits all of the methods of C<Pod::Simple> and C<Pod::Simple::Wiki>. See L<Pod::Simple> and L<Pod::Simple::Wiki> for more details.

=head1 Tiddlywiki Specific information

=head1 SEE ALSO

This module also installs a C<pod2wiki> command line utility. See C<pod2wiki --help> for details.

=head1 ACKNOWLEDGEMENTS

Submit a bugfix or test and your name will go here.

=head1 DISCLAIMER OF WARRANTY

Please refer to the DISCLAIMER OF WARRANTY in L<Pod::Simple::Wiki>.

=head1 AUTHORS

John McNamara jmcnamara@cpan.org

Ron Savage, ron@savage.net.au

Olivier 'dolmen' Mengué

=head1 COPYRIGHT

MMIII-MMXV, John McNamara.

All Rights Reserved. This module is free software. It may be used, redistributed and/or modified under the same terms as Perl itself.
