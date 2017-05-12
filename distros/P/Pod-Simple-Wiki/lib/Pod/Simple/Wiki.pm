package Pod::Simple::Wiki;

###############################################################################
#
# Pod::Simple::Wiki - A class for creating Pod to Wiki filters.
#
#
# Copyright 2003-2015, John McNamara, jmcnamara@cpan.org
#
# Documentation after __END__
#

# perltidy with the following options: -mbl=2 -pt=0 -nola

use strict;

#use Pod::Simple::Debug (5);
use Pod::Simple;
use vars qw(@ISA $VERSION);

@ISA     = qw(Pod::Simple);
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
    '<tt>'   => '"',
    '</tt>'  => '"',
    '<pre>'  => '',
    '</pre>' => "\n\n",

    '<h1>'  => "\n----\n'''",
    '</h1>' => "'''\n\n",
    '<h2>'  => "\n'''''",
    '</h2>' => "'''''\n\n",
    '<h3>'  => "\n''",
    '</h3>' => "''\n\n",
    '<h4>'  => "\n",
    '</h4>' => "\n\n",
};


###############################################################################
#
# new()
#
# Simple constructor inheriting from Pod::Simple.
#
sub new {

    my $class = shift;
    my $format = lc( shift || 'wiki' );
    $format = 'mediawiki' if $format eq 'wikipedia';
    $format = 'moinmoin'  if $format eq 'moin';

    my $module = "Pod::Simple::Wiki::" . ucfirst $format;

    # Try to load a sub-module unless the format type is 'wiki' in which
    # case we use this, the parent, module.
    if ( $format ne 'wiki' ) {
        eval "require $module";
        die "Module $module not implemented for wiki format $format\n" if $@;
        return $module->new( @_ );
    }

    my $self = Pod::Simple->new( @_ );
    $self->{_wiki_text} = '';
    $self->{_tags}      = $tags;
    $self->{output_fh} ||= *STDOUT{IO};
    $self->{_item_indent} = 0;
    $self->{_debug}       = 0;

    # Set Pod::Simple parser options
    # - Merge contiguous text        RT#60304
    $self->merge_text( 1 );

    # - Ignore X<>  (index entries)  RT#60307
    $self->nix_X_codes( 1 );

    bless $self, $class;
    return $self;
}


###############################################################################
#
# _debug()
#
# Sets the debug flag for some Pod::Simple::Wiki debugging. See also the
# Pod::Simple::Debug module.
#
sub _debug {

    my $self = shift;

    $self->{_debug} = $_[0];
}


###############################################################################
#
# _append()
#
# Appends some text to the buffered Wiki text.
#
sub _append {

    my $self = shift;

    $self->{_wiki_text} .= $_[0];
}


###############################################################################
#
# _output()
#
# Appends some text to the buffered Wiki text and then emits it. Also resets
# the buffer.
#
sub _output {

    my $self = shift;
    my $text = $_[0];

    $text = '' unless defined $text;

    print { $self->{output_fh} } $self->{_wiki_text}, $text;

    $self->{_wiki_text} = '';
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
        $self->_append( "*" x $indent_level );

        # This was the way C2 Wiki used to define a bullet list
        # $self->_append("\t" x $indent_level . '*');
    }
    elsif ( $item_type eq 'number' ) {
        $self->_append( "\t" x $indent_level . $item_param );
    }
    elsif ( $item_type eq 'text' ) {
        $self->_append( "\t" x $indent_level );
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

    return 0;
}


###############################################################################
#
# _append_tag()
#
# Add an open or close tag to the current text.
#
sub _append_tag {

    my $self = shift;
    my $tag  = $_[0];

    $self->_append( $self->{_tags}->{$tag} );
}


###############################################################################
###############################################################################
#
# The methods in the following section are required by Pod::Simple to handle
# Pod directives and elements.
#
# The methods _handle_element_start() _handle_element_end() and _handle_text()
# are called by Pod::Simple in response to Pod constructs. We use
# _handle_element_start() and _handle_element_end() to generate calls to more
# specific methods. This is basically a long-hand version of Pod::Simple::
# Methody with the addition of location tracking.
#


###############################################################################
#
# _handle_element_start()
#
# Call a method to handle the start of a element if one has been defined.
# We also set a flag to indicate that we are "in" the element type.
#
sub _handle_element_start {

    my $self    = shift;
    my $element = $_[0];

    $element =~ tr/-/_/;

    if ( $self->{_debug} ) {
        print '    ' x $self->{_item_indent}, "<$element>\n";
    }

    $self->{ "_in_" . $element }++;

    if ( my $method = $self->can( '_start_' . $element ) ) {
        $method->( $self, $_[1] );
    }
}


###############################################################################
#
# _handle_element_end()
#
# Call a method to handle the end of a element if one has been defined.
# We also set a flag to indicate that we are "out" of the element type.
#
sub _handle_element_end {

    my $self    = shift;
    my $element = $_[0];

    $element =~ tr/-/_/;

    if ( my $method = $self->can( '_end_' . $element ) ) {
        $method->( $self );
    }

    $self->{ "_in_" . $element }--;

    if ( $self->{_debug} ) {
        print "\n", '    ' x $self->{_item_indent}, "</$element>\n\n";
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

    for ( @tokens ) {
        next unless /\S/;    # Ignore the whitespace
        next if m[^(ht|f)tp://];    # Ignore URLs
        s/([A-Z][a-z]+)(?=[A-Z])/$1''''''/g    # Escape with 6 single quotes

    }

    # Rejoin the tokens and whitespace.
    $self->{_wiki_text} .= join '', @tokens;
}


###############################################################################
#
# Functions to deal with the I<>, B<> and C<> formatting codes.
#
sub _start_I { $_[0]->_append_tag( '<i>' )  unless $_[0]->_skip_headings() }
sub _start_B { $_[0]->_append_tag( '<b>' )  unless $_[0]->_skip_headings() }
sub _start_C { $_[0]->_append_tag( '<tt>' ) unless $_[0]->_skip_headings() }
sub _start_F { $_[0]->_start_I }

sub _end_I { $_[0]->_append_tag( '</i>' )  unless $_[0]->_skip_headings() }
sub _end_B { $_[0]->_append_tag( '</b>' )  unless $_[0]->_skip_headings() }
sub _end_C { $_[0]->_append_tag( '</tt>' ) unless $_[0]->_skip_headings() }
sub _end_F { $_[0]->_end_I }


###############################################################################
#
# Functions to deal with the Pod =head directives
#
sub _start_head1 { $_[0]->_append_tag( '<h1>' ) }
sub _start_head2 { $_[0]->_append_tag( '<h2>' ) }
sub _start_head3 { $_[0]->_append_tag( '<h3>' ) }
sub _start_head4 { $_[0]->_append_tag( '<h4>' ) }

sub _end_head1 { $_[0]->_append_tag( '</h1>' ); $_[0]->_output() }
sub _end_head2 { $_[0]->_append_tag( '</h2>' ); $_[0]->_output() }
sub _end_head3 { $_[0]->_append_tag( '</h3>' ); $_[0]->_output() }
sub _end_head4 { $_[0]->_append_tag( '</h4>' ); $_[0]->_output() }


###############################################################################
#
# Functions to deal with verbatim paragraphs. We emit the text "as is" for now.
# TODO: escape any Wiki formatting in text such as ''code''.
#
sub _start_Verbatim { $_[0]->_append_tag( '<pre>' ) }
sub _end_Verbatim { $_[0]->_append_tag( '</pre>' ); $_[0]->_output() }


###############################################################################
#
# Functions to deal with =over ... =back regions for
#
# Bulleted lists
# Numbered lists
# Text     lists
# Block    lists
#
sub _start_over_bullet { $_[0]->{_item_indent}++ }
sub _start_over_number { $_[0]->{_item_indent}++ }
sub _start_over_text   { $_[0]->{_item_indent}++ }

sub _end_over_bullet {
    $_[0]->{_item_indent}--;
    $_[0]->_output( "\n" ) unless $_[0]->{_item_indent};
}

sub _end_over_number {
    $_[0]->{_item_indent}--;
    $_[0]->_output( "\n" ) unless $_[0]->{_item_indent};
}

sub _end_over_text {
    $_[0]->{_item_indent}--;
    $_[0]->_output( "\n" ) unless $_[0]->{_item_indent};
}

sub _start_item_bullet { $_[0]->_indent_item( 'bullet' ) }
sub _start_item_number { $_[0]->_indent_item( 'number', $_[1]->{number} ) }
sub _start_item_text   { $_[0]->_indent_item( 'text' ) }

sub _end_item_bullet { $_[0]->_output( "\n" ) }
sub _end_item_number { $_[0]->_output( "\n" ) }

sub _end_item_text { $_[0]->_output( ":\t" ) }    # Format specific.

sub _start_over_block { $_[0]->{_item_indent}++ }
sub _end_over_block   { $_[0]->{_item_indent}-- }


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
        $self->_append( ( "\t" x $indent_level ) . " :\t" );
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
    else {
        $self->_output( "\n" );
    }

    $self->_output( "\n" );
}


1;


__END__


=pod

=encoding utf8

=head1 NAME

Pod::Simple::Wiki - A class for creating Pod to Wiki filters.


=head1 SYNOPSIS

To create a simple filter to convert from Pod to a wiki format:

    #!/usr/bin/perl

    use strict;
    use warnings;
    use Pod::Simple::Wiki;


    my $parser = Pod::Simple::Wiki->new('kwiki');

    if ( defined $ARGV[0] ) {
        open IN, $ARGV[0] or die "Couldn't open $ARGV[0]: $!\n";
    }
    else {
        *IN = *STDIN;
    }

    if ( defined $ARGV[1] ) {
        open OUT, ">$ARGV[1]" or die "Couldn't open $ARGV[1]: $!\n";
    }
    else {
        *OUT = *STDOUT;
    }

    $parser->output_fh( *OUT );
    $parser->parse_file( *IN );

    __END__


To convert Pod to a wiki format using the installed C<pod2wiki> utility:

    pod2wiki --style mediawiki file.pod > file.wiki


=head1 DESCRIPTION

The C<Pod::Simple::Wiki> module is used for converting Pod text to Wiki text.

Pod (Plain Old Documentation) is a simple markup language used for writing Perl documentation.

A Wiki is a user extensible web site. It uses very simple mark-up that is converted to Html. For an introduction to Wikis see: L<http://en.wikipedia.org/wiki/Wiki>


=head1 METHODS

=head2 new('wiki_format')

The C<new> method is used to create a new C<Pod::Simple::Wiki> object. It is also used to set the output Wiki format.

    my $parser1 = Pod::Simple::Wiki->new( 'wiki' );
    my $parser2 = Pod::Simple::Wiki->new( 'mediawiki' );
    my $parser3 = Pod::Simple::Wiki->new(); # Defaults to 'wiki'

The currently supported formats are:

    wiki
    kwiki
    usemod
    twiki
    tiddlywiki
    textile
    wikipedia or mediawiki
    markdown
    moinmoin
    confluence


=head2 Other methods

Pod::Simple::Wiki inherits all of the methods of C<Pod::Simple>. See L<Pod::Simple> for more details.


=head1 Supported Formats

The following wiki formats are supported by C<Pod::Simple::Wiki>:

=over 4

=item wiki

This is the original Wiki format as used on Ward Cunningham's Portland repository of Patterns. See L<http://c2.com/cgi/wiki>.

=item kwiki

This is the format as used by Brian Ingerson's Kwiki: L<http://www.kwiki.org>.

=item usemod

This is the format used by the Usemod wikis. See: L<http://www.usemod.com/cgi-bin/wiki.pl>.

=item twiki

This is the format used by TWiki wikis. See: L<http://twiki.org/>.

=item tiddlywiki

This is the format used by the TiddlyWiki. See: L<http://www.tiddlywiki.com/>.

=item textile

The Textile markup format as used on GitHub. See: L<http://textile.thresholdstate.com/>.

=item wikipedia or mediawiki

This is the format used by Wikipedia and MediaWiki wikis. See: L<http://www.mediawiki.org/>.

=item markdown

This is the format used by GitHub and other sites. See: L<http://daringfireball.net/projects/markdown/syntax>.

=item moinmoin

This is the format used by MoinMoin wikis. See: L<http://moinmo.in/MoinMoinWiki>.

=item muse

Emacs Muse (also known as "Muse" or "Emacs-Muse") is an authoring and publishing environment for Emacs.

=item confluence

This is the format used by Confluence. See: L<http://www.atlassian.com/software/confluence/>.

=back

If no format is specified the parser defaults to C<wiki>.

Any other parameters in C<new> will be passed on to the parent C<Pod::Simple> object. See L<Pod::Simple> for more details.


=head1 Porting New Wiki Formats

If you are interested in porting a new wiki format have a look at L<Pod::Simple::Wiki::Template>.

The C<Pod::Simple::Wiki> git repository is: L<http://github.com/jmcnamara/pod-simple-wiki/>.

=head1 SEE ALSO

This module also installs a C<pod2wiki> command line utility. See C<pod2wiki --help> for details.


=head1 TODO

=over 4

=item *

Fix some of the C<=over> edge cases. See the TODOs in the test programs.

=back


=head1 ACKNOWLEDGEMENTS

Thanks to Sean M. Burke for C<Pod::Simple>. It may not be simple but sub-classing it is. C<:-)>

Thanks to Zoffix Znet for various pull requests and fixes.

Thanks to Sam Tregar for TWiki support.

Thanks Tony Sidaway for Wikipedia/MediaWiki support.

Thanks to Daniel T. Staal for Markdown support.

Thanks to Michael Matthews for MoinMoin support.

Thanks to Christopher J. Madsen for several MediaWiki additions and tests.

Thanks Tim Bunce for the TiddlyWiki prod and Ron Savage for the port.

Thanks to Olivier 'dolmen' MenguE<eacute> for various TiddlyWiki patches.

Thanks to David Bartle, Andrew Hobbs and Jim Renwick for confluence patches.

Thanks to Peter Hallam for MediaWiki enhancements.

Thanks to Marco Pessotto for the Muse format.


=head1 DISCLAIMER OF WARRANTY

Because this software is licensed free of charge, there is no warranty for the software, to the extent permitted by applicable law. Except when otherwise stated in writing the copyright holders and/or other parties provide the software "as is" without warranty of any kind, either expressed or implied, including, but not limited to, the implied warranties of merchantability and fitness for a particular purpose. The entire risk as to the quality and performance of the software is with you. Should the software prove defective, you assume the cost of all necessary servicing, repair, or correction.

In no event unless required by applicable law or agreed to in writing will any copyright holder, or any other party who may modify and/or redistribute the software as permitted by the above licence, be liable to you for damages, including any general, special, incidental, or consequential damages arising out of the use or inability to use the software (including but not limited to loss of data or data being rendered inaccurate or losses sustained by you or third parties or a failure of the software to operate with any other software), even if such holder or other party has been advised of the possibility of such damages.


=head1 LICENSE

Either the Perl Artistic Licence L<http://dev.perl.org/licenses/artistic.html> or the GPL L<http://www.opensource.org/licenses/gpl-license.php>.


=head1 AUTHOR

John McNamara jmcnamara@cpan.org


=head1 COPYRIGHT

MMIII-MMIV, John McNamara.

All Rights Reserved. This module is free software. It may be used, redistributed and/or modified under the same terms as Perl itself.
