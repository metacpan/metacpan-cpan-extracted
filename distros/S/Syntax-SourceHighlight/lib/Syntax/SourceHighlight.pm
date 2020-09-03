package Syntax::SourceHighlight;

use 5.010;
use strict;
use warnings;
use parent 'DynaLoader';

our $VERSION = '2.1.2';

use Syntax::SourceHighlight::SourceHighlight;
use Syntax::SourceHighlight::LangMap;
use Syntax::SourceHighlight::HighlightEvent;

bootstrap Syntax::SourceHighlight;

sub highlightFile {
    my $self = shift;
    $self->highlight(@_);
}

sub highlightString {
    my $self      = shift;
    my $string    = shift;
    my $lang      = shift;
    my $file_name = shift // '';

    die __PACKAGE__
      . '->highlightString() accepts three arguments: '
      . 'string, language, and optional output file name'
      if @_
      or not defined $string
      or not defined $lang;
    return $self->highlights( $string, $lang, $file_name );
}

1;

__END__

=encoding UTF-8

=head1 NAME

Syntax::SourceHighlight - Perl Binding to GNU Source Highlight

=head1 SYNOPSIS

  use Syntax::SourceHighlight;

  my $hl = Syntax::SourceHighlight->new('esc.outlang');
  my $lm = Syntax::SourceHighlight::LangMap->new();

  print $hl->highlightString(
    "my $_ = 42;\n",
    $lm->getMappedFileName('perl')
  );

=head1 DESCRIPTION

L<GNU Source Highlight|https://www.gnu.org/software/src-highlite/> is a library
to format code written in many programming languages as text in several markup
languages. This binding to the underlying C++ library is very basic, supporting
only the essential functionality.

=head2 USAGE

The Perl library exports part of the libsource-highlight API as is therefore
any functionality details may be consulted with the
L<API manual|https://www.gnu.org/software/src-highlite/api/index.html>. There
are some deviations though:

=over

=item

only the three-argument C<highlight()> method is available; the stream-oriented
variant is not yet implemented,

=item

the additional C<< L</highlightString()> >> allows for operating on strings
rather than files,

=item

the constructor C<< LangMap->new() >> may be invoked with no parameters at all;
C<< I<'lang.map'> >> will be used as the default language map file.

=back

All symbols that are exported retain the original C++ camel caps naming
convention. Methods are accessible from Perl blessed hashrefs. Any attributes
are mapped to hash values. Any exceptions thrown by the library are passed back
to Perl with the equivalent of the C<< L<die|perlfunc/die> >> statement. The
I<srchilite> namespace is mapped to Perl's I<Syntax::SourceHighlight::> except
for the main class, I<srchilite::SourceHighlight>, which can be used directly
as C<< Syntax::SourceHighlight->new() >>. Its fully qualified equivalent also
exists for both completeness and compatibility with the older versions of the
package.

The argument to the boolean C<set*()> series of functions default to B<true>
regardless of the initial default value of the variable they address.

=head1 CLASSES

=head2 Syntax::SourceHighlight

This class is the counterpart of the I<srchilite::SourceHighlight> library
class. Most of the methods are exported. This class does not have any public
attributes.

=head3 C<new()>

    my $hl = Syntax::SourceHighlight->new($output_format)

Creates a new source highlighting control object that formats code using the
specified output language. It accepts one optional argument, the name of the
output definition file. The default is C<'html.outlang'>. 

The output language is a file name resolved relative to the data directory of
the control object. The default data directory depends on the compilation time
setup of the underlying library.

=head3 C<highlight()>

    $hl->highlight( $input_file_name, $output_file_name, $input_language )

Highlights the contents of the input file into the output file, using the
specified input language definition. If any of the input or output file names
are empty strings standard input or output will be used respectively.

Again the input language definition file is resolved relative to the data
directory.

I<The four argument variant of this method that uses IO streams has not been
implemented yet.>

=head3 C<highlightString()>

    my $str = $hl->highlightString( $input, $input_language, $input_file_name )

Highlights the contents of the input string using the specified input language
definition. The output is again returned as a string. The optional third
argument sets the “filename” that can be used by output templates.

I<This method is an extension of the original library.>

=head3 C<setHighlightEventListener()>

    $hl->setHighlightEventListener(
        sub {
            my $evt = shift;
            ...
        }
    )

A callback to be invoked on each highlighting event. It should accept one
argument – an object of the class
C<< L</Syntax::SourceHighlight::HighlightEvent> >>:

The highlighting event objects passed to the callback are roots of object
graphs valid only during the dynamic scope of the callback execution.

=head3 C<checkLangDef()>

    $hl->checkLangDef($input_language)

Checks the validity of the language definition file. An exception is thrown if
the language definition is invalid. Otherwise, this method returns no result.

=head3 C<checkOutLangDef()>

    $hl->checkOutLangDef($output_language)

Checks the validity of the output definition file. Exception is thrown if the
definition is invalid.

=head3 C<createOutputFileName()>

    $hl->createOutputFileName($input_file_name)

Given the input file name creates an output file name.

=head3 C<setDataDir()>

    $hl->setDataDir($data_directory_name)

Sets an alternative directory where the definition files are. The default is
compiled into the library.

=head3 C<setStyleFile()>

    $hl->setStyleFile($style_file_name)

The definition file containing format options. The default is I<default.style>.

=head3 C<setStyleCssFile()>

    $hl->setStyleCssFile($style_file_name)

The CSS style file.

=head3 C<setStyleDefaultFile()>

    $hl->setStyleDefaultFile($style_file_name)

The style defaults file.

=head3 C<setTitle()>

    $hl->setTitle($title)

The title of the output document. Defaults to the source file name.

=head3 C<setCss()>

    $hl->setCss($css_file)

Path to an external CSS file.

=head3 C<setHeaderFileName()>

    $hl->setHeaderFileName($header_file_name)

The file name of the header.

=head3 C<setFooterFileName()>

    $hl->setFooterFileName($footer_file_name)

The file name of the footer.

=head3 C<setOutputDir()>

    $hl->setOutputDir($output_directory_name)

The directory for output files.

=head3 C<setOptimize()>

    $hl->setOptimize($flag)

Whether to optimize output. For example, adjacent text parts belonging to the
same element will be buffered and generated as a single text part. The optional
C<$flag> parameter defaults to true.

=head3 C<setGenerateLineNumbers()>

    $hl->setGenerateLineNumbers($flag)

Whether to generate line numbers. The optional C<$flag> parameter defaults to
true.

=head3 C<setGenerateLineNumberRefs()>

    $hl->setGenerateLineNumberRefs($flag)

Whether to generate line numbers with references. The optional C<$flag>
parameter defaults to true.

=head3 C<setLineNumberPad()>

    $hl->setLineNumberPad($character)

The line number padding char. Defaults to C<'0'>.

=head3 C<setLineNumberAnchorPrefix()>

    $hl->setLineNumberAnchorPrefix($prefix)

The prefix for the line number anchors.

=head3 C<setGenerateEntireDoc()>

    $hl->setGenerateEntireDoc($flag)

Whether to generate an entire document. The initial state is no. The optional
C<$flag> parameter defaults to true.

=head3 C<setGenerateVersion()>

    $hl->setGenerateVersion($flag)

Whether to generate the program version in the output file and initially it is
set to yes. The optional C<$flag> parameter defaults to true.

=head3 C<setCanUseStdOut()>

    $hl->setCanUseStdOut($flag)

Whether the standard output can be used for output. This is true by default.
The optional C<$flag> parameter defaults to true.

=head3 C<setBinaryOutput()>

    $hl->setBinaryOutput($flag)

Whether to open output files in binary mode. Defaults to false. The optional
C<$flag> parameter defaults to true.

=head3 C<setRangeSeparator()>

    $hl->setRangeSeparator($separator)

The optional separator to be printed between ranges such as “..”.

=head3 C<setTabSpaces()>

    $hl->setTabSpaces($number)

Sets the tab width. The value C<0> disables replacing tabs with spaces and this
is the initial setting.

=head2 Syntax::SourceHighlight::LangMap

=head3 C<new()>

    my $lm = Syntax::SourceHighlight::LangMap->new($language_map)

or

    my $lm = Syntax::SourceHighlight::LangMap->new(
        $data_directory, $language_map
    )

Creates a new language map using the given name and data directory. A language
map can be used to determine the correct input language file name for a source
file name or a language name.

The language map name is a file name resolved relative to the data directory.
The default value is C<'lang.map'> if C<new()> is invoked with no arguments at
all. The default data directory is compiled into the C++ library.

I<The zero-argument variant of this constructor is an extension of the original library.>

=head3 C<getMappedFileName()>

    $lm->getMappedFileName($language)

Determines a suitable input language name by using the map file. It contains
some of the lower case names of the languages or interpreters as well as common
file suffixes. If no known input language definition is found, the method
returns an empty string.

=head3 C<getMappedFileNameFromFileName()>

    $lm->getMappedFileNameFromFileName($file_name)

Determines a suitable input language name for the given source file name. If no
known input language definition is found, the method returns the empty string.

Note that the default language map shipped with recent versions of the Source
Highlight library maps the file name suffix I<.pl> to Prolog, not Perl.

=head3 C<getLangNames()>

    $lm->getLangNames()

An array reference containing all known human-readable language names known to
the language map.

=head3 C<getMappedFileNames()>

    $lm->getMappedFileNames()

An array reference containing all known file names of language definitions
known to the language map.

=head2 Syntax::SourceHighlight::HighlightEvent

There is no Perl constructor for this object as it is normally created by the
library and passed to the callback set with
C<< L</setHighlightEventListener()> >>.

It has two attributes:

=over

=item I<type>

The type of the event. The value is equal to one of the following constants:

=over

=item

C<$Syntax::SourceHighlight::HighlightEvent::FORMAT>

=item

C<$Syntax::SourceHighlight::HighlightEvent::FORMATDEFAULT>

=item

C<$Syntax::SourceHighlight::HighlightEvent::ENTERSTATE>

=item

C<$Syntax::SourceHighlight::HighlightEvent::EXITSTATE>

=back

=item I<token>

The token of source text corresponding to the event represented by
the C<< L</Syntax::SourceHighlight::HighlightToken> >> the class.

=back

=head2 Syntax::SourceHighlight::HighlightToken

There is no Perl constructor for this object as it is normally created by the
library and passed to the callback set with
C<< L</setHighlightEventListener()> >>. This object class represents part of
the text being formatted and its highlighting pattern definition.

The following attributes are defined in this class:

=over

=item I<prefix>

A possible part of source text before the matched string.

=item I<prefixOnlySpaces>

True if the prefix is empty or consists only of whitespace characters.

=item I<suffix>

A possible part of source text after the matched string.

=item I<matchedSize>

The length of the whole matched data.

=item I<matched>

An array reference containing strings of the form
C<< I<element name>:I<source text> >>. The I<element name> depends on the
source language definition and usually classifies the type of source text, for
example, whether it is a variable name or a keyword.

=back

=head1 EXAMPLES

The following script takes file names from command line parameters and prints
the output to the terminal with ANSI escape codes.

    #!/usr/bin/env perl
    
    use strict;
    use warnings;
    use Syntax::SourceHighlight;
    
    my $hl = Syntax::SourceHighlight->new('esc.outlang');
    my $lm = Syntax::SourceHighlight::LangMap->new();
    
    foreach (@ARGV) {
        my $lang = $lm->getMappedFileNameFromFileName($_);
        unless ($lang) {
            warn "Cannot determine file format for '$_'.\n";
            next;
        }
        $hl->highlightFile( $_, '', $lang );
    }

The next example enhances the previous script with an event listener that
counts the number of objects found in the file. It prints the summary at the
end.

    #!/usr/bin/env perl
    
    use strict;
    use warnings;
    use Syntax::SourceHighlight;
    
    my $hl = Syntax::SourceHighlight->new('esc.outlang');
    my $lm = Syntax::SourceHighlight::LangMap->new();
    
    my %tokens;
    $hl->setHighlightEventListener(
        sub {
            my $he = shift;
            foreach ( @{ $he->{token}->{matched} } ) {
                next unless m/^(.*?):/s;
                $tokens{$1}++;
            }
        }
    );
    
    foreach (@ARGV) {
        %tokens = ();
        my $lang = $lm->getMappedFileNameFromFileName($_);
        unless ($lang) {
            warn "Cannot determine file format for '$_'.\n";
            next;
        }
        $hl->highlightFile( $_, '', $lang );
        next unless keys %tokens;
        print(
            "\nFound: ",
            join( ', ', map { "$tokens{$_} ${_}s" } sort keys %tokens ),
            "\n\n"
        );
    }

=head1 SEE ALSO

The homepage of the original library is at
L<https://www.gnu.org/software/src-highlite/>.

=head1 AUTHORS

=over

=item

Thomas Chust, L<chust@web.de|mailto:chust@web.de>

=item

Matt Latusek, L<matlib@matlibhax.com|mailto:matlib@matlibhax.com>

=back

=head1 COPYRIGHT AND LICENSE

Copyright © 2010 by Thomas Chust

This binding is in the Public Domain.

=cut
