package Pod::Simple::Wiki::Moinmoin;

###############################################################################
#
# Pod::Simple::Wiki::Moinmoin - A class for creating Pod to Moinmoin filters.
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
    '<b>'    => "'''",
    '</b>'   => "'''",
    '<i>'    => "''",
    '</i>'   => "''",
    '<tt>'   => '`',
    '</tt>'  => '`',
    '<pre>'  => "\n{{{\n",
    '</pre>' => "\n}}}\n",

    '<h1>'  => "\n== ",
    '</h1>' => " ==\n\n",
    '<h2>'  => "\n=== ",
    '</h2>' => " ===\n\n",
    '<h3>'  => "\n==== ",
    '</h3>' => " ====\n\n",
    '<h4>'  => "\n===== ",
    '</h4>' => " =====\n\n",
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
        $self->_append( ' ' x $indent_level . "* " );
    }
    elsif ( $item_type eq 'number' ) {
        $self->_append( ' ' x $indent_level . "1. " );
    }
    elsif ( $item_type eq 'text' ) {
        $self->_append( ' ' x $indent_level );
    }

    $self->{_moinmoin_list} = 1;
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

    # Escape any tokens here.

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
    $_[0]->_output( ":: " );
    $_[0]->{_moinmoin_list} = 0;
}

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
        $self->_append( ' ' x $indent_level );
    }

    if ( $self->{_moinmoin_list} ) {
        if ( not $self->{_in_over_text} and $self->{_moinmoin_list} == 1 ) {
            $self->_append( "\n" );
        }

        if ( $self->{_in_over_text} and $self->{_moinmoin_list} == 2 ) {
            $self->_append( "\n" );
        }

        if ( not( $self->{_in_over_text} and $self->{_moinmoin_list} == 1 ) ) {
            $self->_append( ' ' x $indent_level );
        }

        $self->{_moinmoin_list}++;
    }
}


1;


__END__


=head1 NAME

Pod::Simple::Wiki::Moinmoin - A class for creating Pod to Moinmoin wiki filters.

=head1 SYNOPSIS

This module isn't used directly. Instead it is called via C<Pod::Simple::Wiki>:

    #!/usr/bin/perl -w

    use strict;
    use Pod::Simple::Wiki;


    my $parser = Pod::Simple::Wiki->new('moinmoin');

    ...


Convert Pod to a Moinmoin wiki format using the installed C<pod2wiki> utility:

    pod2wiki --style moinmoin file.pod > file.wiki


=head1 DESCRIPTION

The C<Pod::Simple::Wiki::Moinmoin> module is used for converting Pod text to Wiki text.

Pod (Plain Old Documentation) is a simple markup language used for writing Perl documentation.

For an introduction to Moinmoin see: L<http://moinmoin.wikiwikiweb.de/>

This module isn't generally invoked directly. Instead it is called via C<Pod::Simple::Wiki>. See the L<Pod::Simple::Wiki> and L<pod2wiki> documentation for more information.


=head1 METHODS

Pod::Simple::Wiki::Moinmoin inherits all of the methods of C<Pod::Simple> and C<Pod::Simple::Wiki>. See L<Pod::Simple> and L<Pod::Simple::Wiki> for more details.


=head1 SEE ALSO

This module also installs a C<pod2wiki> command line utility. See C<pod2wiki --help> for details.


=head1 ACKNOWLEDGEMENTS

Thanks to Michael Matthews for MoinMoin support.


=head1 DISCLAIMER OF WARRANTY

Please refer to the DISCLAIMER OF WARRANTY in L<Pod::Simple::Wiki>.


=head1 AUTHORS

John McNamara jmcnamara@cpan.org


=head1 COPYRIGHT

MMIII-MMXV, John McNamara.

All Rights Reserved. This module is free software. It may be used, redistributed and/or modified under the same terms as Perl itself.
