package Search::Tools;
use 5.008_003;
use strict;
use warnings::register;
use Carp;
use Scalar::Util qw( openhandle );
use File::Basename;

our $VERSION = '1.007';

use XSLoader;
XSLoader::load( 'Search::Tools', $VERSION );

our $XS_DEBUG = 0;

sub parser {
    my $class = shift;
    require Search::Tools::QueryParser;
    return Search::Tools::QueryParser->new(@_);
}

sub regexp {
    my $class = shift;

    croak("as of version 0.24 you should use parser() instead of regexp()");
}

sub hiliter {
    my $class = shift;
    require Search::Tools::HiLiter;
    return Search::Tools::HiLiter->new(@_);
}

sub snipper {
    my $class = shift;
    require Search::Tools::Snipper;
    return Search::Tools::Snipper->new(@_);
}

sub transliterate {
    my $class = shift;
    require Search::Tools::Transliterate;
    return Search::Tools::Transliterate->new->convert(@_);
}

sub spellcheck {
    my $class = shift;
    require Search::Tools::SpellCheck;
    return Search::Tools::SpellCheck->new(@_);
}

sub slurp {
    my ( $self, $file ) = @_;
    my ( $buf, $fh );
    my ( $name, $path, $suffix ) = fileparse( $file, qr/\.[^.]*/ );
    $suffix = lc($suffix);
    if ( $suffix eq '.gz' ) {
        require IO::Uncompress::Gunzip;
        $fh = IO::Uncompress::Gunzip->new($file);
    }
    elsif ( $suffix eq '.bz2' ) {
        require IO::Uncompress::Bunzip2;
        $fh = IO::Uncompress::Bunzip2->new($file)
            or die "bunzip2 failed: $IO::Uncompress::Bunzip2::Bunzip2Error\n";

    }
    else {
        require IO::File;
        $fh = openhandle($file) || IO::File->new( $file, '<' );
    }

    die "Failed to open $file: $!" unless $fh;

    while ( my $ln = $fh->getline ) {
        $buf .= $ln;
    }

    return $buf;
}

1;

__END__

=pod

=head1 NAME

Search::Tools - high-performance tools for building search applications

=head1 SYNOPSIS

 use Search::Tools;
 
 my $string     = 'the quik brown fox';
 my $qparser    = Search::Tools->parser();
 my $query      = $qparser->parse($string);
 my $snipper    = Search::Tools->snipper(query => $query);
 my $hiliter    = Search::Tools->hiliter(query => $query);
 my $spellcheck = Search::Tools->spellcheck(query_parser => $qparser);

 my $suggestions = $spellcheck->suggest($string);
 
 for my $s (@$suggestions) {
    if (! $s->{suggestions}) {
        # $s->{word} was spelled correctly
    }
    elsif (@{ $s->{suggestions} }) {
        printf "Did you mean: %s\n", join(' or ', @{$s->{suggestions}}));
    }
 }

 for my $result (@search_results) {
    print $hiliter->light( $snipper->snip( $result->summary ) );
 }
  
 
=head1 DESCRIPTION

As of version 1.000 Search::Tools uses L<Moo> and L<Class::XSAccessor>.

Search::Tools is a set of utilities for building search applications.
Rather than adhering to a particular search application or framework,
the goal of Search::Tools is to provide general-purpose methods for common
search application features. Think of Search::Tools like a toolbox
rather than a hammer.

Examples include:

=over

=item

Parsing search queries for the meaningful terms

=item

Rich regular expressions for locating terms in the original
indexed documents

=item

Contextual snippets showing query terms

=item

Highlighting of terms in context

=item

Spell check terms and suggestions of alternate spellings.

=back

Search::Tools is derived from some of the features in HTML::HiLiter
and SWISH::HiLiter, but has been re-written with an eye to accomodating
more general purpose features.

=head1 METHODS

=head2 parser( I<args> )

Returns a Search::Tools::Parser object, passing I<args> to new().

=head2 regexp

Deprecated. Use parser() instead.

=head2 hiliter( I<args> )

Returns a Search::Tools::HiLiter object, passing I<args> to new().

=head2 snipper( I<args> )

Returns a Search::Tools::Snipper object, passing I<args> to new().

=head2 transliterate( I<str> )

Same as:

 Search::Tools::Transliterate->new()->convert( $str )

=head2 spellcheck( I<args> )

Returns a Search::Tools::SpellCheck object, passing I<args> to new().

=head2 slurp( I<filename> )

Reads contents of I<filename> into a scalar variable. Similar to File::Slurp,
but will handle compressed files (.gz or .bz2) transparently
using IO::Uncompress.

=cut

=head1 FUNCTIONS

=head2 describe( I<object> )

XS debugging help. Same as using Devel::Peek.

=head1 REQUIREMENTS

Perl 5.8.3 or later is required. This is for full UTF-8 support.

The following non-core CPAN modules are required:

=over

=item Class::XSAccessor

=item Search::Query

=item Data::Dump

=item Encode

=item Encoding::FixLatin

=item Carp

=back

The following CPAN modules are recommended for the full set of features
and for performance.

=over

=item Text::Aspell

=back

See also the specific module documentation for individual requirements.

=head1 HISTORY

The public API has changed as of version 0.24. The following classes
are now removed:

 Search::Tools::Keywords
 Search::Tools::RegExp
 Search::Tools::RegExp::Keywords
 Search::Tools::RegExp::Keyword

The following Search::Tools method is deprecated:

 regexp()

The following classes are new as of version 0.24:

 Search::Tools::HeatMap
 Search::Tools::Query
 Search::Tools::QueryParser
 Search::Tools::RegEx
 Search::Tools::Token
 Search::Tools::TokenList
 Search::Tools::TokenListPP
 Search::Tools::TokenListUtils
 Search::Tools::TokenPP
 Search::Tools::Tokenizer

=head1 EXAMPLES

See the tests in t/ and the example scripts in example/.
 
=head1 AUTHOR

Peter Karman C<< <karman@cpan.org> >>

=head1 ACKNOWLEDGMENTS

The original idea and regular expression builder comes from
HTML::HiLiter by the same author, copyright 2004 by Cray Inc.

Thanks to Atomic Learning C<www.atomiclearning.com> 
for sponsoring the development of some of these modules.

=head1 BUGS

Please report any bugs or feature requests to C<bug-search-tools at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Search-Tools>.  
I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Search::Tools


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Search-Tools>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Search-Tools>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Search-Tools>

=item * Search CPAN

L<http://search.cpan.org/dist/Search-Tools/>

=back

=head1 COPYRIGHT

Copyright 2006-2009, 2014 by Peter Karman.

This package is free software; you can redistribute it and/or modify it under the 
same terms as Perl itself.

=head1 SEE ALSO

HTML::HiLiter, SWISH::HiLiter, L<Moo>, L<Class::XSAccessor>, L<Text::Aspell>

=cut
