package Search::Tools::QueryParser;
use Moo;
extends 'Search::Tools::Object';
use Carp;
use Data::Dump qw( dump );
use Search::Query::Parser;
use Encode;
use Data::Dump;
use Search::Tools::Query;
use Search::Tools::UTF8;
use Search::Tools::XML;
use Search::Tools::RegEx;

use namespace::autoclean;

our $VERSION = '1.007';

my $XML = Search::Tools::XML->new();
my $C2E = $XML->char2ent_map;

# we turn locale pragma on in a small block
# because we don't want it to mess up our regex building
# or taint vars in other areas. We just want to use setlocale()
# and make sure we get correct ->utf8 encoding
my ( $locale, $lang, $charset );
{
    use POSIX qw(locale_h);
    $locale = setlocale(LC_CTYPE);
    ( $lang, $charset ) = split( m/\./, $locale );
    $charset ||= q/UTF-8/;    # <v0.24 this was iso-8895-1
    $lang = q/en_US/ if $lang =~ m/^(posix|c)$/i;
}

my %Defaults = (
    and_word                => q/and|near\d*/,
    charset                 => $charset,
    default_field           => "",
    ignore_case             => 1,
    ignore_fields           => {},
    ignore_first_char       => quotemeta(q/'-/),
    ignore_last_char        => quotemeta(q/'-/),
    lang                    => $lang,
    locale                  => $locale,
    not_word                => q/not/,
    or_word                 => q/or/,
    phrase_delim            => q/"/,
    query_class             => 'Search::Tools::Query',
    query_dialect           => "Search::Query::Dialect::Native",
    stemmer                 => undef,
    stopwords               => [],
    tag_re                  => $XML->tag_re,
    term_re                 => qr/\w+(?:[\'\-]\w+)*/,
    term_min_length         => 1,
    treat_uris_like_phrases => 1,
    whitespace              => $XML->html_whitespace,
    wildcard                => q/*/,
    word_characters         => q/\w/ . quotemeta(q/'-/),
);

for my $attr ( keys %Defaults ) {
    has( $attr => ( is => 'rw', default => sub { $Defaults{$attr} } ) );
}
has 'start_bound'        => ( is => 'ro' );
has 'end_bound'          => ( is => 'ro' );
has 'plain_phrase_bound' => ( is => 'ro' );
has 'html_phrase_bound'  => ( is => 'ro' );

sub get_defaults {
    return {%Defaults};
}

sub BUILD {
    my $self = shift;

    # TODO handle case where both term_re and word_characters are defined

    # charset/locale/lang are a bit interdependent
    # so make sure charset/lang are set if locale is explicitly passed.
    if ( $self->{locale} ne $Defaults{locale} ) {
        ( $self->{lang}, $self->{charset} ) = split( m/\./, $self->{locale} );
        $self->{lang} = 'en_US' if $self->{lang} =~ m/^(posix|c)$/i;
        $self->{charset} ||= $Defaults{charset};
    }

    # make sure ignore_fields is a hash ref
    if ( ref( $self->{ignore_fields} ) eq 'ARRAY' ) {
        $self->{ignore_fields}
            = { map { $_ => $_ } @{ $self->{ignore_fields} } };
    }

    $self->_setup_regex_builder;

    return $self;
}

sub parse {
    my $self      = shift;
    my $query_str = shift;
    confess "query required" unless defined $query_str;
    if ( ref $query_str ) {
        croak "query must be a scalar string";
    }

    #$query_str = to_utf8( $query_str, $self->charset );
    my $extracted = $self->_extract_terms($query_str);
    my %regex;
TERM: for my $term ( @{ $extracted->{terms} } ) {
        my ( $plain, $html, $escaped ) = $self->_build_regex($term);
        my $is_phrase = $term =~ m/\ /;
        my @phrase_terms;

        # if the term is a phrase,
        # build regex for each term in the phrase
        if ($is_phrase) {
            my @pts = split( /\ /, $term );
            for my $pt (@pts) {
                my ( $pt_plain, $pt_html, $pt_esc )
                    = $self->_build_regex($pt);
                push @phrase_terms,
                    Search::Tools::RegEx->new(
                    plain     => $pt_plain,
                    html      => $pt_html,
                    term      => $pt,
                    term_re   => qr/$pt_esc/i,
                    is_phrase => 0,
                    );
            }
        }
        $regex{$term} = Search::Tools::RegEx->new(
            plain        => $plain,
            html         => $html,
            term         => $term,
            term_re      => qr/$escaped/i,
            is_phrase    => $is_phrase,
            phrase_terms => \@phrase_terms,
        );

    }
    return $self->{query_class}->new(
        dialect => $extracted->{dialect},
        terms   => $extracted->{terms},
        fields  => $extracted->{fields},
        str     => to_utf8( $query_str, $self->charset ),
        regex   => \%regex,
        qp      => $self,
    );
}

sub _extract_terms {
    my $self  = shift;
    my $query = shift;
    confess "need query to extract terms" unless defined $query;
    my $stopwords     = $self->stopwords;
    my $and_word      = $self->and_word;
    my $or_word       = $self->or_word;
    my $not_word      = $self->not_word;
    my $wildcard      = $self->wildcard;
    my $phrase        = $self->phrase_delim;
    my $igf           = $self->ignore_first_char;
    my $igl           = $self->ignore_last_char;
    my $wordchar      = $self->word_characters;
    my $default_field = $self->default_field;
    my $esc_wildcard  = quotemeta($wildcard);
    my $word_re       = qr/(($esc_wildcard)?[$wordchar]+($esc_wildcard)?)/;
    my $min_length    = $self->term_min_length;
    my $raw_query     = $query;

    $stopwords = [ split( /\s+/, $stopwords ) ] unless ref $stopwords;
    my %stophash = map { to_utf8( lc($_), $self->charset ) => 1 } @$stopwords;
    my ( %words, %uniq, $c );
    my $parser = Search::Query::Parser->new(
        and_regex     => qr{$and_word}i,
        or_regex      => qr{$or_word}i,
        not_regex     => qr{$not_word}i,
        default_field => $default_field,
        query_class   => $self->query_dialect,
    );

    my $baked_query = $raw_query;
    $baked_query = lc($baked_query) if $self->ignore_case;
    $baked_query = to_utf8( $baked_query, $self->charset );
    my $dialect = $parser->parse($baked_query) or croak $parser->error;
    $self->debug && carp "parsetree: " . Data::Dump::dump( $dialect->tree );
    my $fields_searched
        = $self->_get_value_from_tree( \%uniq, $dialect->tree, $c );

    $self->debug && carp "parsed: " . Data::Dump::dump( \%uniq );

    my $count = scalar( keys %uniq );

    # parse uniq into word tokens
    # including removing stop words

    $self->debug && carp "word_re: $word_re";

U: for my $u ( sort { $uniq{$a} <=> $uniq{$b} } keys %uniq ) {

        my $n = $uniq{$u};

        # only phrases have space
        # but due to our word_re, a single non-spaced string
        # might actually be multiple word tokens
        my $isphrase = $u =~ m/\s/ || 0;

        if ( $self->treat_uris_like_phrases ) {

            # special case: treat email addresses, uris, as phrase
            $isphrase ||= $u =~ m/[$wordchar][\@\.\\\/][$wordchar]/ || 0;
        }

        $self->debug && carp "$u -> isphrase = $isphrase";

        my @w = ();

    TOK: for my $w ( split( m/\s+/, to_utf8( $u, $self->charset ) ) ) {

            next TOK unless $w =~ m/\S/;

            $w =~ s/\Q$phrase\E//g;

            while ( $w =~ m/$word_re/g ) {
                my $tok = _untaint($1);

                # strip ignorable chars
                $tok =~ s/^[$igf]+// if length($igf);
                $tok =~ s/[$igl]+$// if length($igl);

                unless ($tok) {
                    $self->debug && carp "no token for '$w' $word_re";
                    next TOK;
                }

                $self->debug && carp "found token: $tok";

                if ( exists $stophash{ lc($tok) } ) {
                    $self->debug && carp "$tok = stopword";
                    next TOK unless $isphrase;
                }

                unless ($isphrase) {
                    next TOK if $tok =~ m/^($and_word|$or_word|$not_word)$/i;
                }

                # if tainting was on, odd things can happen.
                # so check one more time
                $tok = to_utf8( $tok, $self->charset );

                # final sanity check
                if ( !Encode::is_utf8($tok) ) {
                    carp "$tok is NOT utf8";
                    next TOK;
                }

                #$self->debug && carp "pushing $tok into wordlist";
                push( @w, $tok );

            }

        }

        next U unless @w;

        #$self->debug && carp "joining \@w: " . Data::Dump::dump(\@w);
        if ($isphrase) {
            $words{ join( ' ', @w ) } = $n + $count++;
        }
        else {
            for (@w) {
                $words{$_} = $n + $count++;
            }
        }

    }

    $self->debug && carp "tokenized: " . Data::Dump::dump( \%words );

    # make sure we don't have 'foo' and 'foo*'
    for ( keys %words ) {
        if ( $_ =~ m/$esc_wildcard/ ) {
            ( my $copy = $_ ) =~ s,$esc_wildcard,,g;

            # delete the more exact of the two
            # since the * will match both
            delete( $words{$copy} );
        }

        if ( length $_ < $min_length ) {
            $self->debug and carp "token too short: '$_'";
            delete $words{$_};
        }

    }

    $self->debug && carp "wildcards removed: " . Data::Dump::dump( \%words );

    # if any words need to be stemmed
    if ( $self->stemmer ) {

        # split each $word into words
        # stem each word
        # if stem ne word, break into chars and find first N common
        # rejoin $uniq

        #carp "stemming ON\n";

    K: for ( keys %words ) {
            my (@w) = split /\s+/;
        W: for my $w (@w) {
                my $func = $self->stemmer;
                my $f = &$func( $self, $w );
                if ( !defined $f or !length $f ) {
                    next W;
                }
                $f = to_utf8($f);

                #warn "w: $w\nf: $f\n";

                # add wildcard to indicate chars were lost
                $w = $f . $wildcard;

            }
            my $new = join ' ', @w;
            if ( $new ne $_ ) {
                $words{$new} = $words{$_};
                delete $words{$_};
            }
        }

    }

    $self->debug && carp "stemming done: " . Data::Dump::dump( \%words );

    # sort keeps query in same order as we entered
    return {
        terms => [ sort { $words{$a} <=> $words{$b} } keys %words ],
        fields  => [ keys %$fields_searched ],
        dialect => $dialect,
        query   => $raw_query,
    };

}

# stolen nearly verbatim from Taint::Runtime
# apparently regex can be tainted when running under 'use locale'.
# as of version 0.24 this should not be needed but until I can find a way
# to easily test the Taint feature, we just do this. It's low overhead.
sub _untaint {
    my $str = shift;
    my $ref = ref($str) ? $str : \$str;
    if ( !defined $$ref ) {
        $$ref = undef;
    }
    else {
        $$ref
            = ( $$ref =~ /(.*)/ )
            ? $1
            : do { confess("Couldn't find data to untaint") };
    }
    return ref($str) ? 1 : $str;
}

sub _get_value_from_tree {
    my $self      = shift;
    my $uniq      = shift;
    my $parseTree = shift;
    my $c         = shift;
    my %fields    = ();

    # we only want the values from non minus queries
    for my $node ( '+', '' ) {
        next unless exists $parseTree->{$node};

        my @branches = @{ $parseTree->{$node} };

        #warn dump \@branches;

        for my $leaf (@branches) {
            my $v = $leaf->{value};
            if ( !defined $v ) {
                croak "undefined value in query tree: " . dump($leaf);
            }
            if ( defined $leaf->{field}
                and exists $self->ignore_fields->{ $leaf->{field} } )
            {
                next;
            }
            my $field = $leaf->{field};
            if ( defined $field ) {
                $fields{$field}++;
            }
            if ( ref $v eq 'HASH' ) {
                my $f = $self->_get_value_from_tree( $uniq, $v, $c );
                $fields{$_} = $f->{$_} for ( keys %$f );
            }
            elsif ( ref $v eq 'ARRAY' ) {
                for my $value (@$v) {
                    $value =~ s/\s+/ /g;
                    $uniq->{$value} = ++$c;
                }
            }
            else {

                # if the $leaf is a proximity query,
                # ignore the "phrase-ness" of it and split
                # on whitespace. This is a compromise,
                # mitigated by the tendency of HeatMap
                # to reward proximity anyway.
                if ( $leaf->{proximity} and $leaf->{proximity} > 1 ) {
                    my @tokens = split( m/\ +/, $v );
                    $uniq->{$_} = ++$c for @tokens;
                    next;
                }

                # collapse any whitespace
                $v =~ s,\s+,\ ,g;

                $uniq->{$v} = ++$c;
            }
        }
    }
    return \%fields;
}

sub _setup_regex_builder {
    my $self = shift;

    # TODO optional for term_re

    # a search for a '<' or '>' should still highlight,
    # since &lt; or &gt; can be indexed as literal < and >
    # but this causes a great deal of hassle
    # so we just ignore them.
    my $wordchars = $self->word_characters;
    $wordchars =~ s,[<>&],,g;
    $self->{html_safe_wordchars} = $wordchars;    # remember for build
    my $ignore_first    = $self->ignore_first_char;
    my $ignore_last     = $self->ignore_last_char;
    my $html_whitespace = $self->whitespace;

    # what's the boundary between a word and a not-word?
    # by default:
    #	the beginning of a string
    #	the end of a string
    #	whatever we've defined as WhiteSpace
    #	any character that is not a WordChar
    #   any character we explicitly ignore at start or end of word
    #
    # the \A and \Z (beginning and end) should help if the word butts up
    # against the beginning or end of a tagset
    # like <p>Word or Word</p>

    my @start_bound = (
        '\A',
        '[>]',
        '(?:&[\w\#]+;)',    # because a ; might be a legitimate wordchar
                            # and we treat a char entity like a single char.
                            # if &char; resolves to a legit wordchar
                            # this might give unexpected results.
                            # NOTE that &nbsp; etc is in $WhiteSpace
        $html_whitespace,
        '[^' . $wordchars . ']'
    );
    push( @start_bound, qr/[$ignore_first]+/i ) if length $ignore_first;

    my @end_bound
        = ( '\Z', '[<&]', $html_whitespace, '[^' . $wordchars . ']' );
    push( @end_bound, qr/[$ignore_last]+/i ) if length $ignore_last;

    $self->{start_bound} ||= join( '|', @start_bound );

    $self->{end_bound} ||= join( '|', @end_bound );

    # the whitespace in a query phrase might be:
    #	any ignore_last_char, followed by
    #	one or more nonwordchar or whitespace, followed by
    #	any ignore_first_char
    # define for both text and html
    # NOTE the first/last swap for plain vs html
    # is intentional because of how regex are built.

    my @plain_phrase_bound = (
        ( length($ignore_last) ? qr/[$ignore_last]*/i : '' ),
        qr/(?:[\s\x20]|[^$wordchars])+/is,
        ( length($ignore_first) ? qr/[$ignore_first]?/i : '' ),
    );
    $self->{plain_phrase_bound} = join( '', @plain_phrase_bound );

    my @html_phrase_bound = (
        ( length($ignore_first) ? qr/[$ignore_first]*/i : '' ),
        qr/(?:$html_whitespace|[^$wordchars])+/is,
        ( length($ignore_last) ? qr/[$ignore_last]?/i : '' ),
    );
    $self->{html_phrase_bound} = join( '', @html_phrase_bound );

}

sub _build_regex {
    my $self      = shift;
    my $q         = shift or croak "need query to build()";
    my $wild      = $self->{html_safe_wordchars};
    my $st_bound  = $self->{start_bound};
    my $end_bound = $self->{end_bound};
    my $wc        = $self->{html_safe_wordchars};
    my $ppb       = $self->{plain_phrase_bound};
    my $hpb       = $self->{html_phrase_bound};
    my $wildcard  = $self->wildcard;
    my $wild_esc  = quotemeta($wildcard);
    my $tag_re    = $self->tag_re;

    # define simple pattern for plain text
    # and complex pattern for HTML markup
    my ( $plain, $html );
    my $escaped = quotemeta($q);
    $escaped =~ s/\\[$wild_esc]/[$wc]*/g;    # wildcard
    $escaped =~ s/\\[\s]/$ppb/g;             # whitespace

    $plain = qr/
(
\A|$ppb
)
(
${escaped}
)
(
\Z|$ppb
)
/xis;

    my (@char) = split( m//, $q );

    my $counter = -1;

CHAR: foreach my $c (@char) {
        $counter++;

        my $ent = $C2E->{$c} || undef;
        my $num = ord($c);

        # if this is a special regexp char, protect it
        $c = quotemeta($c);

        # if it's a *, replace it with the Wild class
        $c = "[$wild]*" if $c eq $wild_esc;

        if ( $c eq '\ ' ) {
            $c = $hpb . $tag_re . '*';
            next CHAR;
        }

        my $aka;
        if ($ent) {
            $aka = $ent eq "&#$num;" ? $ent : "$ent|&#$num;";
        }
        else {
            $aka = "&#$num;";
        }

        # make $c into a regexp
        $c = qr/$c|$aka/i unless $c eq "[$wild]*";

  # any char might be followed by zero or more tags, unless it's the last char
        $c .= $tag_re . '*' unless $counter == $#char;

    }

    # re-join the chars into a single string
    my $safe = join( "\n", @char );   # use \n to make it legible in debugging

# for debugging legibility we include newlines, so make sure we s//x in matches
    $html = qr/
(
${st_bound}
)
(
${safe}
)
(
${end_bound}
)
/xis;

    return ( $plain, $html, $escaped );
}

sub _build_term_re {

    # this based on SWISH::PhraseHighlight::set_match_regexp()

    my $self = shift;

    #dump $self;

    my $wc = $self->word_characters;
    $self->{_wc_regexp}
        = qr/[^$wc]+/io;    # regexp for splitting into swish-words

    my $igf = $self->ignore_first_char;
    my $igl = $self->ignore_last_char;
    for ( $igf, $igl ) {
        if ($_) {
            $_ = "[$_]*";
        }
        else {
            $_ = '';
        }
    }

    $self->{_ignoreFirst} = $igf;
    $self->{_ignoreLast}  = $igl;

}

1;

__END__

=pod

=head1 NAME

Search::Tools::QueryParser - convert string queries into objects

=head1 SYNOPSIS

 use Search::Tools::QueryParser;
 my $qparser = Search::Tools::QueryParser->new(
        
        # regex to define a query term (word)
            term_re        => qr/\w+(?:'\w+)*/,
        
        # or assemble a definition from the following
            word_characters     => q/\w\'\-/,
            ignore_first_char   => q/\+\-/,
            ignore_last_char    => q/\+\-/,
            term_min_length     => 1,
            
        # words to ignore
            stopwords           => [qw( the )],
            
        # query operators
            and_word            => q(and),
            or_word             => q(or),
            not_word            => q(not),
            phrase_delim        => q("),
            treat_uris_like_phrases => 1,
            ignore_fields       => [qw( site )],
            wildcard            => quotemeta(q(*)),
                        
        # language-specific settings
            stemmer             => &your_stemmer_here,       
            charset             => 'iso-8859-1',
            lang                => 'en_US',
            locale              => 'en_US.iso-8859-1',

        # development help
            debug               => 0,
    );
    
 my $query    = $qparser->parse(q(the quick color:brown "fox jumped"));
 my $terms    = $query->terms; # ['quick', 'brown', '"fox jumped"']
 
 # a Search::Tools::RegEx object
 my $regexp   = $query->regexp_for($terms->[0]); 
 
 # the Search::Query::Dialect tree()
 my $tree     = $query->tree;
 
 print "$query\n";  # the quick color:brown "fox jumped"
 print $query->str . "\n"; # same thing
 
 
=head1 DESCRIPTION

Search::Tools::QueryParser turns search queries into objects that can
be applied for highlighting, spelling, and extracting matching snippets
from source documents.

=head1 METHODS

=head2 new( %opts )

The new() method instantiates a QueryParser object. With the exception
of parse(), all the following methods can be passed as key/value
pairs in new().

=head2 BUILD

Called internally by new().

=head2 parse( I<query> )

The parse() method parses I<query> and returns a Search::Tools::Query object.

I<query> must be a scalar string.

B<NOTE:> All queries are converted to UTF-8. See the C<charset> param.

=head2 stemmer

The stemmer function is used to find the root 'stem' of a word. There are many
stemming algorithms available, including many on CPAN. The stemmer function
should expect to receive two parameters: the QueryParser object and the word to be
stemmed. It should return exactly one value: the stemmed word.

Example stemmer function:

 use Lingua::Stem;
 my $stemmer = Lingua::Stem->new;
 
 sub mystemfunc {
     my ($parser, $word) = @_;
     return $stemmer->stem($word)->[0];
 }
 
 # and pass to the new() method:
 
 my $qparser = Search::Tools::QueryParser->new(stemmer => \&mystemfunc);
     
=head2 stopwords

A list of common words that should be ignored in parsing out keyword terms. 
May be either a string that will be split on whitespace, or an array ref.

B<NOTE:> If a stopword is contained in a phrase, then the phrase 
will be tokenized into words based on whitespace, then the stopwords removed.

=head2 end_bound

=head2 get_defaults

=head2 html_phrase_bound

=head2 phrase_delim

=head2 plain_phrase_bound

=head2 start_bound

=head2 tag_re

=head2 term_re

=head2 term_min_length

=head2 whitespace

=head2 word_characters

=head2 ignore_first_char

String of characters to strip from the beginning of all words.

=head2 ignore_last_char

String of characters to strip from the end of all words.

=head2 ignore_case

All queries are run through Perl's built-in lc() function before
parsing. The default is C<1> (true). Set to C<0> (false) to preserve
case.

=head2 ignore_fields

Value may be a hash or array ref of field names to ignore in query parsing.
Example:

 ignore_fields => [qw( site )]

would parse the query:

 site:foo.bar AND baz   # terms = baz

=head2 default_field

Set the default field to be used in parsing the query, if no field
is specified. The default is the empty string (the Search::Query::Parser
default).

=head2 treat_uris_like_phrases

Boolean (default true (1)).

If set to true, queries like B<foo@bar.com> will be treated like a single
phrase B<"foo bar com"> instead of being split into three separate terms.

=head2 and_word

Default: C<and|near\d*>

=head2 or_word

Default: C<or>

=head2 not_word

Default: C<not>

=head2 wildcard

Default: C<*>

=head2 locale

Set a locale explicitly. If not set, the locale is inherited from the 
C<LC_CTYPE> environment variable.

=head2 LC_CTYPE

Imported function by locale pragma. Documented only to satisfy pod tests.

=head2 lang

Base language. If not set, extracted from C<locale> or defaults to C<en_US>.

=head2 charset

Base charset used for converting queries to UTF-8. If not set, 
extracted from C<locale> or defaults to C<iso-8859-1>.

=head2 query_class

The default is C<Search::Tools::Query> but you can set your own to subclass
the Query object.

=head2 query_dialect

The default is C<Search::Query::Dialect::Native> but you can set your own.
See the L<Search::Query::Dialect> documentation.

=head1 LIMITATIONS

The special HTML chars &, < and > can pose problems in regexps against markup, so they
are ignored in creating regular expressions if you include them in 
C<word_characters> in new().

=head1 AUTHOR

Peter Karman C<< <karman@cpan.org> >>

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

Copyright 2009 by Peter Karman.

This package is free software; you can redistribute it and/or modify it under the 
same terms as Perl itself.

=head1 SEE ALSO

Search::Query::Parser
