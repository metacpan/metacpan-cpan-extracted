package Pod::Simple::Wiki::Mediawiki;

###############################################################################
#
# Pod::Simple::Wiki::Mediawiki - A class for creating Pod to MediaWiki filters.
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
    '<tt>'   => '<tt>',
    '</tt>'  => '</tt>',
    '<pre>'  => "<code>\n",
    '</pre>' => "\n</code>\n",

    '<h1>'  => '==',
    '</h1>' => "==\n",
    '<h2>'  => '===',
    '</h2>' => "===\n",
    '<h3>'  => '====',
    '</h3>' => "====\n",
    '<h4>'  => '=====',
    '</h4>' => "=====\n",
};


###############################################################################
#
# The default module options
#
my $default_opts = {
    transformer_lists     => 0,
    link_prefix           => 0,
    sentence_case_headers => 0,
    remove_name_section   => 0,
};


###############################################################################
#
# new()
#
# Simple constructor inheriting from Pod::Simple::Wiki.
#
sub new {

    my $class = shift;
    my $opts  = {};

    if ( ref $_[-1] eq 'HASH' ) {
        $opts = pop @_;

        # Merge custom tags with the default tags, if passed.
        $opts->{tags} = {
            %$tags,
            %{
                exists $opts->{custom_tags}
                ? delete $opts->{custom_tags}
                : {}
            }
        };
    }
    else {
        $opts->{tags} = $tags;
    }

    $opts = { %$default_opts, %$opts };

    my $self = Pod::Simple::Wiki->new( 'wiki', @_ );
    $self->{_tags}                  = $opts->{tags};
    $self->{_transformer_lists}     = $opts->{transformer_lists};
    $self->{_link_prefix}           = $opts->{link_prefix};
    $self->{_sentence_case_headers} = $opts->{sentence_case_headers};
    $self->{_remove_name_section}   = $opts->{remove_name_section};

    bless $self, $class;

    $self->accept_targets( 'mediawiki' );
    $self->nbsp_for_S( 1 );

    return $self;
}


###############################################################################
#
# _append()
#
# Appends some text to the buffered Wiki text.
#
sub _append {

    my $self = shift;

    if ( $self->{_indent_text} ) {
        $self->{_wiki_text} .= $self->{_indent_text};
        $self->{_indent_text} = '';
    }

    $self->{_wiki_text} .= $_[0];
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
    elsif ( $item_type eq 'text' ) {
        $self->_append( ':' x ( $indent_level - 1 ) . '; ' );
    }
}


###############################################################################
#
# Functions to deal with links.

sub _start_L {

    my ( $self, $attr ) = @_;

    if ( !$self->_skip_headings ) {
        $self->_append( '' );    # In case we have _indent_text pending
        # Flush the text buffer, so it will contain only the link text
        $self->_output;
        $self->{_link_attr} = $attr;    # Save for later
    }
}

sub _end_L {

    my $self = $_[0];

    my $attr = delete $self->{_link_attr};

    if ( $attr and my $method = $self->can( '_format_link' ) ) {
        $self->{_wiki_text} = $method->( $self, $self->{_wiki_text}, $attr );
    }
}


###############################################################################
#
# _format_link

sub _format_link {

    my ( $self, $text, $attr ) = @_;

    if ( $attr->{type} eq 'url' ) {
        my $link = $attr->{to};

        return $link if $attr->{'content-implicit'};
        return "[$link $text]";
    }

    # Manpage:
    if ( $attr->{type} eq 'man' ) {

        # FIXME link to http://www.linuxmanpages.com?
        return "<tt>$text</tt>" if $attr->{'content-implicit'};
        return "$text (<tt>$attr->{to}</tt>)";
    }

    die "Unknown link type $attr->{type}" unless $attr->{type} eq 'pod';

    # Handle a link within this page:
    return "[[#$attr->{section}|$text]]" unless defined $attr->{to};

    # Handle a link to a specific section in another page:
    if ( defined $attr->{section} ) {
        return $self->{_link_prefix}
          ? "[$self->{_link_prefix}$attr->{to}#$attr->{section} $text]"
          : "[[$attr->{to}#$attr->{section}|$text]]";
    }

    if ( $attr->{'content-implicit'} ) {
        return $self->{_link_prefix}
          ? "[$self->{_link_prefix}$attr->{to} $attr->{to}]"
          : "[[$attr->{to}]]";
    }

    return "[[$attr->{to}|$text]]";
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

    if ( $self->{_sentence_case_headers} ) {
        if ( $self->{_in_head1} ) {
            $text = ucfirst( lc( $text ) );
        }
    }

    if ( !$self->{_in_Data} ) {

        # Escape colons in definition lists:
        if ( $self->{_in_item_text} ) {
            $text =~ s/:/&#58;/g;    # A colon would end the item
        }

        # Escape empty lines in verbatim sections:
        if ( $self->{_in_Verbatim} ) {
            $text =~ s/^$/ /mg;      # An empty line would split the section
        }

        $text =~ s/\xA0/&nbsp;/g;    # Convert non-breaking spaces to entities

        $text =~ s/''/'&#39;/g;      # It's not a formatting code

        $text =~ s/\xA9/&copy;/g;    # Convert copyright symbols to entities
    }

    $self->_append( $text );
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
sub _end_item_text { }    # _start_Para will insert the :


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
        $self->{_indent_text} = ( ':' x $indent_level );
    }

    if ( $self->{_in_over_text} ) {
        $self->{_indent_text} = "\n" . ( ':' x $indent_level );
    }

    if ( $self->{_transformer_lists} ) {
        if ( $self->{_in_over_bullet} || $self->{_in_over_number} ) {
            if ( $self->{output_string} ) {
                chomp( ${ $self->{output_string} } );
            }
            $self->{_indent_text} = "<p>";
        }
    }
}


###############################################################################
#
# _end_Para()
#
# Special handling for paragraphs that are part of an "over_text" block.
#
sub _end_Para {

    my $self = shift;

    # Only add a newline if the paragraph isn't part of a text
    if ( $self->{_in_over_text} ) {

        # Do nothing in this format.
    }
    elsif ( $self->{_transformer_lists}
        && ( $self->{_in_over_bullet} || $self->{_in_over_number} ) )
    {

        $self->_output( "</p>\n" );
    }
    else {
        $self->_output( "\n" );
    }

    if ( !$self->{_transformer_lists}
        || ( !$self->{_in_over_bullet} && !$self->{_in_over_number} ) )
    {

        $self->_output( "\n" );
    }
}


######################################################################
#
# _end_Data
#
# Special handling for data paragraphs

sub _end_Data { $_[0]->_output( "\n\n" ) }


###############################################################################
#
# parse_string_document()
#
# Optional overriding of Pod::Simple method to remove the "NAME" section
#
sub parse_string_document {

    my $self = shift;

    $self = $self->SUPER::parse_string_document( @_ );

    if ( $self->{_remove_name_section} ) {
        no warnings 'uninitialized';
        ${ $self->{output_string} } =~
          s/^==\s*NAME\s*==\n(?:[\w:]+)(?: - (.*))*/$1||''/iesg;
    }

    return $self;
}

1;


__END__

=pod

=encoding utf8

=head1 NAME

Pod::Simple::Wiki::Mediawiki - A class for creating Pod to Mediawiki wiki filters.

=head1 SYNOPSIS

This module isn't used directly. Instead it is called via C<Pod::Simple::Wiki>:

    #!/usr/bin/perl -w

    use strict;
    use Pod::Simple::Wiki;


    my $parser = Pod::Simple::Wiki->new('mediawiki', \%opts);

    ...


Convert Pod to a Mediawiki wiki format using the installed C<pod2wiki> utility:

    pod2wiki --style mediawiki file.pod > file.wiki


=head1 DESCRIPTION

The C<Pod::Simple::Wiki::Mediawiki> module is used for converting Pod text to Wiki text.

Pod (Plain Old Documentation) is a simple markup language used for writing Perl documentation.

For an introduction to Mediawiki see: http://www.mediawiki.org/wiki/MediaWiki

This module isn't generally invoked directly. Instead it is called via C<Pod::Simple::Wiki>. See the L<Pod::Simple::Wiki> and L<pod2wiki> documentation for more information.


=head1 METHODS

Pod::Simple::Wiki::Mediawiki inherits all of the methods of C<Pod::Simple> and C<Pod::Simple::Wiki>. See L<Pod::Simple> and L<Pod::Simple::Wiki> for more details.


=head2 new

The following options are supported by the C<Pod::Simple::Wiki::Mediawiki> constructor:

=over 4

=item B<custom_tags>

This option accepts a hashref containing the HTML tag to MediaWiki mappings.

For example, if your MediaWiki installation has the L<SyntaxHighlight GeSHi|http://www.mediawiki.org/wiki/Extension:SyntaxHighlight_GeSHi> extension installed, you could pass the following custom tags to enable your verbatim paragraphs to be syntax highlighted:

    {
        custom_tags => {
            '<pre>'     => "<syntaxhighlight lang=\"perl\">\n",
            '</pre>'    => "\n</syntaxhighlight>\n",
        }
    }

Any custom tags you define will override the classes' default tags as defined in the C<$tags> variable.

Defaults to "{}".

=item B<transformer_lists>

If enabled, modify the item list output to better support the L<Pod::Elemental::Transformer::List> style of lists (as used by many L<Dist::Zilla> based distros via L<Pod::Weaver>).

For example, the output of the following list definition:

    =for :list
    * Point one
    This is pointy
    * Point two
    That hurts

will be transformed into:

    * Point one<p>This is pointy</p>
    * Point two<p>That hurts</p>

This will be rendered as a bulleted with list headings that have correctly indented paragraph blocks immediately beneath.

Defaults to 0.

=item B<link_prefix>

If set, all links without any extra qualifier text are prefixed with the given URL.  A useful URL to set this option to is: C<http://search.cpan.org/perldoc?>, which will enable the links to be correctly resolved to the external links when used within your internal MediaWiki site.

Defaults to 0.

=item B<sentence_case_headers>

This option will modify any C<=head1> header by lower-casing it and then upper-casing the first character.

For example, this header:

    =head1 DESCRIPTION

becomes:

    =head1 Description

This option is inspired from L<http://en.wikipedia.org/wiki/Wikipedia:Manual_of_Style#Article_titles> in the Wikipedia "Manual of Style".

Defaults to 0.

=item B<remove_name_section>

If enabled, modify the resultant wiki output text to remove the "NAME" (or "Name") section, but first parse out the embedded abstract text and place that at the top of the wiki page, as a brief introduction.

Defaults to 0.

=back

=head1 SEE ALSO

This module also installs a C<pod2wiki> command line utility. See C<pod2wiki --help> for details.


=head1 ACKNOWLEDGEMENTS

Thanks Tony Sidaway for initial Wikipedia/MediaWiki support. Christopher J. Madsen for several major additions and tests. Peter Hallam added several MediaWiki enhancements.



=head1 DISCLAIMER OF WARRANTY

Please refer to the DISCLAIMER OF WARRANTY in L<Pod::Simple::Wiki>.


=head1 AUTHORS

John McNamara jmcnamara@cpan.org

Christopher J. Madsen perl@cjmweb.net


=head1 COPYRIGHT

MMIII-MMXV, John McNamara.

All Rights Reserved. This module is free software. It may be used, redistributed and/or modified under the same terms as Perl itself.
