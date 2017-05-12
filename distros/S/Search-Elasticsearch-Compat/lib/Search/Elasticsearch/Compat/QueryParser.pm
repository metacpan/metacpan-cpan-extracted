package Search::Elasticsearch::Compat::QueryParser;
$Search::Elasticsearch::Compat::QueryParser::VERSION = '0.10';
use strict;
use warnings FATAL => 'all';
use Search::Elasticsearch::Util qw(parse_params throw);
use Scalar::Util qw(weaken);
@Search::Elasticsearch::Error::QueryParser::ISA
    = 'Search::Elasticsearch::Error';

# ABSTRACT: Check or filter query strings


#===================================
sub new {
#===================================
    my ( $proto, $params ) = parse_params(@_);
    my $class = ref $proto || $proto;
    $params = {
        escape_reserved => 0,
        fields          => 0,
        wildcard_prefix => 1,
        allow_bool      => 1,
        allow_boost     => 1,
        allow_fuzzy     => 1,
        allow_slop      => 1,
        allow_ranges    => 0,
        %$params,
    };
    return bless {
        _default_opts => $params,
        _opts         => $params,
    }, $class;
}

#===================================
sub filter {
#===================================
    my $self = shift;
    my $text = shift;
    my ( undef, $opts ) = parse_params( $self, @_ );
    $opts->{fix} = 1;
    return $self->_parse( $text, $opts );
}

#===================================
sub check {
#===================================
    my $self = shift;
    my $text = shift;
    my ( undef, $opts ) = parse_params( $self, @_ );
    $opts->{fix} = 0;
    return $self->_parse( $text, $opts );
}

#===================================
sub _parse {
#===================================
    my $self = shift;
    my $text = shift;
    $text = '' unless defined $text;
    utf8::upgrade($text);

    my $opts = shift;
    $self->{_opts} = { %{ $self->{_default_opts} }, %$opts };

    $self->{_tokeniser} = $self->_init_tokeniser($text);
    $self->{_tokens}    = [];
    $self->{_stack}     = [ {} ];
    $self->{_start_pos} = 0;
    $self->{_done}      = 0;

    my $phrase;
    eval {
        $phrase = $self->_multi_clauses;
        die "Syntax error\n"
            unless $self->{_done} || $opts->{fix};
    };
    if ($@) {
        $@ =~ s/\n$/:\n/;
        substr( $text, $self->{_start_pos}, 0, ' <HERE> ' );
        throw( 'QueryParser', "$@$text" );
    }
    return $phrase;
}

#===================================
sub _dump_tokens {
#===================================
    my $self = shift;
    my $text = shift;
    $text = '' unless defined $text;
    utf8::upgrade($text);

    my $tokeniser = $self->_init_tokeniser($text);

    while ( my $next = $tokeniser->() ) {
        printf "TOKEN: %-15s VARS: %s\n", shift @$next,
            join( ', ', grep { defined $_ } @$next );
    }
}

#===================================
sub _next_token {
#===================================
    my $self = shift;
    my $next = shift @{ $self->{_tokens} }
        || $self->{_tokeniser}->();
    return $next if $next;
    $self->{_done} = 1;
    return;
}

#===================================
sub _return_token {
#===================================
    my $self = shift;
    push @{ $self->{_tokens} }, shift;
    $self->{_done} = 0;
}

# 1     = Can follow
# 0     = Cannot follow, drop token and try next token
# undef = Cannot follow, stop looking

my %Clauses = (
    _LPAREN     => 1,
    _PLUS_MINUS => 1,
    _EXISTS     => 1,
    _FIELD      => 1,
    _TERM       => 1,
    _PHRASE     => 1,
    _WILDTERM   => 1,
    _RANGE      => 1,
    _NOT        => 1,
    _AND_OR     => 1,
    _SPACE      => 1,
    _RESERVED   => 1,
    _ESCAPE     => 1,
);

my %Boost = ( _BOOST => 1 );

my %Allowed = (
    _CLAUSE     => \%Clauses,
    _LPAREN     => { %Clauses, _RPAREN => 1 },
    _AND_OR     => { %Clauses, _AND_OR => 0 },
    _NOT        => { %Clauses, _NOT => 0, _AND_OR => 0 },
    _PLUS_MINUS => {
        %Clauses,
        _NOT        => 0,
        _AND_OR     => 0,
        _PLUS_MINUS => 0,
        _SPACE      => undef,
    },
    _FIELD => {
        _LPAREN   => 1,
        _TERM     => 1,
        _WILDTERM => 1,
        _PHRASE   => 1,
        _RANGE    => 1,
    },
    _PHRASE   => { _BOOST => 1, _FUZZY => 1 },
    _TERM     => { _BOOST => 1, _FUZZY => 1 },
    _WILDTERM => \%Boost,
    _RANGE    => \%Boost,
    _FUZZY    => \%Boost,
    _RPAREN   => \%Boost,
    _EXISTS   => \%Boost,
    _BOOST    => {},
    _SPACE    => {},
    _RESERVED => {},
    _ESCAPE   => {},
);

#===================================
sub _parse_context {
#===================================
    my $self    = shift;
    my $context = shift;
    my $allowed = $Allowed{$context};

TOKEN: {
        my $token = $self->_next_token or return;

        my ( $type, @args ) = @$token;
        if ( $allowed->{$type} ) {
            redo TOKEN if $type eq '_SPACE';
            return $self->$type(@args);
        }
        elsif ( defined $allowed->{$type} ) {
            die "Syntax error\n" unless $self->{_opts}{fix};
            redo TOKEN;
        }
        else {
            $self->_return_token($token);
            return undef;
        }
    }
}

#===================================
sub _multi_clauses {
#===================================
    my $self = shift;
    my @clauses;
    while (1) {
        my $clause = $self->_parse_context('_CLAUSE');
        if ( !defined $clause ) {
            last
                if @{ $self->{_stack} } > 1
                || !$self->{_opts}{fix}
                || $self->{_done};
            $self->_next_token;
            next;
        }
        next unless length $clause;
        push @clauses, $clause;
        $self->{_stack}[-1]{clauses}++;
    }
    return join( ' ', @clauses );
}

#===================================
sub _AND_OR {
#===================================
    my $self = shift;
    my $op   = shift;
    my $opts = $self->{_opts};

    unless ( $self->{_stack}[-1]{clauses} ) {
        return '' if $opts->{fix};
        die "$op must be preceded by another clause\n";
    }
    unless ( $opts->{allow_bool} ) {
        die qq("$op" not allowed) unless $opts->{fix};
        return '';
    }

    my $next = $self->_parse_context('_AND_OR');
    return "$op $next"
        if defined $next && length $next;

    return '' if $opts->{fix};
    die "$op must be followed by a clause\n";
}

#===================================
sub _NOT {
#===================================
    my $self = shift;
    my $op   = shift;

    my $opts = $self->{_opts};
    unless ( $opts->{allow_bool} ) {
        die qq("$op" not allowed) unless $opts->{fix};
        return '';
    }

    my $next = $self->_parse_context('_NOT');
    $next = '' unless defined $next;

    die "$op cannot be followed by + or -"
        if $next =~ s/^[+-]+// && !$opts->{fix};

    return "$op $next"
        if length $next;

    return '' if $opts->{fix};
    die "$op must be followed by a clause\n";
}

#===================================
sub _PLUS_MINUS {
#===================================
    my $self = shift;
    my $op   = shift;
    my $next = $self->_parse_context('_PLUS_MINUS');

    return "$op$next" if defined $next && length $next;

    return '' if $self->{_opts}{fix};
    die "$op must be followed by a clause";
}

#===================================
sub _LPAREN {
#===================================
    my $self = shift;
    push @{ $self->{_stack} }, {};
    my $clause = $self->_multi_clauses;

    my $close  = ')';
    my $rparen = $self->_next_token;
    if ( $rparen && $rparen->[0] eq '_RPAREN' ) {
        my $next = $self->_parse_context('_RPAREN') || '';
        $close .= $next if $next;
        pop @{ $self->{_stack} };
    }
    elsif ( $self->{_opts}{fix} ) {
        $self->_return_token($rparen);
    }
    else {
        die "Missing closing parenthesis\n";
    }
    return $clause ? "(${clause}${close}" : '';
}

#===================================
sub _BOOST {
#===================================
    my $self = shift;
    unless ( $self->{_opts}{allow_boost} ) {
        die "Boost not allowed" unless $self->{_opts}{fix};
        return '';
    }
    my $val = shift;
    unless ( defined $val && length $val ) {
        return '' if $self->{_opts}{fix};
        die "Missing boost value\n";
    }
    return "^$val";
}

#===================================
sub _FUZZY {
#===================================
    my $self  = shift;
    my $fuzzy = shift;
    my $opts  = $self->{_opts};
    my $fix   = $opts->{fix};

    if ( $self->{current} eq '_PHRASE' ) {

        # phrase slop
        if ( $opts->{allow_slop} ) {
            $fuzzy = int( $fuzzy || 0 );
            $fuzzy = $fuzzy ? "~$fuzzy" : '';
        }
        else {
            die "Phrase slop not allowed\n" unless $fix;
            $fuzzy = '';
        }
    }
    else {

        # fuzzy
        if ( $opts->{allow_fuzzy} ) {
            if ( defined $fuzzy ) {
                if ( $fuzzy <= 1 ) {
                    $fuzzy = "~$fuzzy";
                }
                else {
                    die "Fuzzy value must be between 0.0 and 1.0\n"
                        unless $fix;
                    $fuzzy = '';
                }
            }
            else {
                $fuzzy = '~';
            }
        }
        else {
            die "Fuzzy not allowed\n"
                unless $fix;
            $fuzzy = '';
        }
    }

    my $next = $self->_parse_context('_FUZZY') || '';
    return "$fuzzy$next";
}

#===================================
sub _PHRASE {
#===================================
    my $self   = shift;
    my $string = shift;

    local $self->{current} = '_PHRASE';
    my $next = $self->_parse_context('_PHRASE') || '';

    return qq("$string"$next);
}

#===================================
sub _EXISTS {
#===================================
    my $self   = shift;
    my $prefix = shift;
    my $field  = shift;

    my $opts = $self->{_opts};
    my $next = $self->_parse_context('_EXISTS') || '';
    unless ( $opts->{fields}
        and ( !ref $opts->{fields} || $opts->{fields}{$field} ) )
    {
        return '' if $opts->{fix};
        die qq("Field "$field" not allowed);
    }

    return "$prefix:$field$next"
        if $field;
    return '' if $self->{_opts}{fix};
    die "Missing field name for $prefix\n";
}

#===================================
sub _FIELD {
#===================================
    my $self  = shift;
    my $field = shift;

    my $opts = $self->{_opts};
    my $next = $self->_parse_context('_FIELD');

    unless ( defined $next && length $next ) {
        die "Missing clause after field $field\n"
            unless $opts->{fix};
        return '';
    }

    return "$field:$next"
        if $opts->{fields}
        and !ref $opts->{fields} || $opts->{fields}{$field};

    die qq("Field "$field" not allowed)
        unless $opts->{fix};

    return $next;
}

#===================================
sub _TERM {
#===================================
    my $self = shift;
    local $self->{current} = '_TERM';
    my $next = $self->_parse_context('_TERM') || '';
    return shift(@_) . $next;
}

#===================================
sub _WILDTERM {
#===================================
    my $self = shift;
    my $term = shift;
    my $min  = $self->{_opts}{wildcard_prefix};
    my $next = $self->_parse_context('_WILDTERM') || '';
    if ( $term !~ /^[^*?]{$min}/ ) {
        die "Wildcard cannot have * or ? "
            . (
            $min == 1 ? 'as first character' : "in first $min characters" )
            unless $self->{_opts}{fix};
        $term =~ s/[*?].*//;
        return '' unless length $term;
    }
    return "$term$next";
}

#===================================
sub _RANGE {
#===================================
    my $self = shift;
    my ( $open, $close, $from, $to ) = @_;
    my $opts = $self->{_opts};
    my $next = $self->_parse_context('_RANGE') || '';
    unless ( $opts->{allow_ranges} ) {
        die "Ranges not allowed\n"
            unless $opts->{fix};
        return '';
    }
    unless ( defined $to ) {
        die "Malformed range\n" unless $opts->{fix};
        return '';
    }
    return "$open$from TO $to$close$next";
}

#===================================
sub _RESERVED {
#===================================
    my $self = shift;
    my $char = shift;
    die "Reserved character $char\n"
        unless $self->{_opts}{fix};
    return $self->{_opts}{escape_reserved}
        ? "\\$char"
        : '';
}

#===================================
sub _ESCAPE {
#===================================
    my $self = shift;
    die qq(Cannot end with "\\"\n)
        unless $self->{_opts}{fix};
    return '';
}

my $DECIMAL  = qr/[0-9]+(?:[.][0-9]+)?/;
my $NUM_CHAR = qr/[0-9]/;
my $ESC_CHAR = qr/\\./;
my $WS       = qr/[ \t\n\r\x{3000}]/;
my $TERM_START_CHAR
    = qr/[^ \t\n\r\x{3000}+\-!():^[\]"{}~*?\\&|] | $ESC_CHAR/x;
my $TERM_CHAR   = qr/$TERM_START_CHAR |$ESC_CHAR | [-+]/x;
my $QUOTE_RANGE = qr/(?: " (?: \\" | [^"] )* ")/x;
my $RANGE_SEP   = qr/ \s+ (?: TO \s+)?/x;

#===================================
sub _init_tokeniser {
#===================================
    my $self = shift;
    my $text = shift;

    my $weak_self = $self;
    Scalar::Util::weaken($weak_self);
    return sub {
    TOKEN: {
            $weak_self->{_start_pos} = pos($text) || 0;
            return ['_SPACE']
                if $text =~ m/\G$WS/gc;
            return [ '_AND_OR', $1 ]
                if $text =~ m/\G(AND\b | && | OR\b | \|{2})/gcx;
            return [ '_NOT', $1 ]
                if $text =~ m/\G(NOT\b | !)/gcx;
            return [ '_PLUS_MINUS', $1 ]
                if $text =~ m/\G([-+])/gc;
            return ['_LPAREN']
                if $text =~ m/\G[(]/gc;
            return ['_RPAREN']
                if $text =~ m/\G[)]/gc;
            return [ '_BOOST', $1 ]
                if $text =~ m/\G\^($DECIMAL)?/gc;
            return [ '_FUZZY', $1 ]
                if $text =~ m/\G[~]($DECIMAL)?/gc;
            return [ '_PHRASE', $1, $2 ]
                if $text =~ m/\G " ( (?: $ESC_CHAR | [^"\\])*) "/gcx;
            return [ '_EXISTS', $1, $2 ]
                if $text =~ m/\G
                                (_exists_|_missing_):
                                ((?:$TERM_START_CHAR $TERM_CHAR*)?)
                            /gcx;
            return [ '_FIELD', $1 ]
                if $text =~ m/\G ($TERM_START_CHAR $TERM_CHAR*):/gcx;
            return [ '_TERM', $1 ]
                if $text =~ m/\G
                                ( $TERM_START_CHAR $TERM_CHAR*)
                                (?!$TERM_CHAR | [*?])
                            /gcx;
            return [ '_WILDTERM', $1 ]
                if $text =~ m/\G (
                                    (?:$TERM_START_CHAR | [*?])
                                    (?:$TERM_CHAR | [*?])*
                            )/gcx;
            return [ '_RANGE', '[', ']', $1, $2 ]
                if $text =~ m/\G \[
                                ( $QUOTE_RANGE | [^ \]]+ )
                                (?: $RANGE_SEP
                                    ( $QUOTE_RANGE | [^ \]]* )
                                )?
                            \]
                            /gcx;
            return [ '_RANGE', '{', '}', $1, $2 ]
                if $text =~ m/\G \{
                                ( $QUOTE_RANGE | [^ }]+ )
                                (?:
                                    $RANGE_SEP
                                    ( $QUOTE_RANGE | [^ }]* )
                                )?
                            \}
                            /gcx;

            return [ '_RESERVED', $1 ]
                if $text =~ m/\G ( ["&|!(){}[\]~^:+\-] )/gcx;

            return ['_ESCAPE']
                if $text =~ m/\G\\$/gc;
        }
        return;

    };
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Search::Elasticsearch::Compat::QueryParser - Check or filter query strings

=head1 VERSION

version 0.10

=head1 SYNOPSIS

    use Search::Elasticsearch::Compat;
    my $es = Search::Elasticsearch::Compat->new(servers=>'127.0.0.1:9200');
    my $qp = $es->query_parser(%opts);

    my $filtered_query_string = $qp->filter($unchecked_query_string)

    my $results = $es->search( query=> {
                      query_string=>{ query => $filtered_query_string }
                  });

For example:

    my $qs = 'foo NOT AND -bar - baz * foo* secret_field:SIKRIT "quote';

    print $qp->filter($qs);
    # foo AND -bar baz foo* "quote"

=head1 DESCRIPTION

Passing an illegal query string to Search::Elasticsearch::Compat, the request will fail.
When using a query string from an external source, eg the keywords field
from a web search form, it is important to filter it to avoid these
failures.

You may also want to allow or disallow certain query string features, eg
the ability to search on a particular field.

The L<Search::Elasticsearch::Compat::QueryParser> takes care of this for you.

See L<http://lucene.apache.org/java/3_0_3/queryparsersyntax.html>
for more information about the Lucene Query String syntax, and
L<http://www.elasticsearch.org/guide/reference/query-dsl/query-string-query.html#Syntax_Extension>
for custom Elasticsearch extensions to the query string syntax.

=head1 METHODS

=head2 new()

    my $qp = Search::Elasticsearch::Compat::QueryParser->new(%opts);
    my $qp = $es->query_parser(%opts);

Creates a new L<Search::Elasticsearch::Compat::QueryParser> object, and sets the passed in
options (see L</"OPTIONS">).

=head2 filter()

    $filtered_query_string = $qp->filter($unchecked_query_string, %opts)

Checks a passed in query string and returns a filtered version which is
suitable to pass to Elasticsearch.

Note: C<filter()> can still return an empty string, which is not considered
a valid query string, so you should still check for that before passing
to Elasticsearch.

If any C<%opts> are passed in to C<filter()>, these are added to the default
C<%opts> as set by L</"new()">, and apply only for the current run.

L</"filter()"> does not promise to parse the query string in exactly
the same way as Lucene, just to clear it up so that it won't throw an
error when passed to Elasticsearch.

=head2 check()

    $filtered_query_string = $qp->check($unchecked_query_string, %opts)

Checks a passed in query string and throws an error if it is not valid.
This is useful for debugging your own query strings.

If any C<%opts> are passed in to C<check()>, these are added to the default
C<%opts> as set by L</"new()">, and apply only for the current run.

=head1 OPTIONS

You can set various options to control how your query strings are filtered.

The defaults (if no options are passed in) are:

    escape_reserved => 0
    fields          => 0
    boost           => 1
    allow_bool      => 1
    allow_boost     => 1
    allow_fuzzy     => 1
    allow_slop      => 1
    allow_ranges    => 0
    wildcard_prefix => 1

Any options passed in to L</"new()"> are merged with these defaults. These
options apply for the life of the QueryParser instance.

Any options passed in to L</"filter()"> or L</"check()"> are merged with
the options set in L</"new()"> and apply only for the current run.

For instance:

    $qp = Search::Elasticsearch::Compat::QueryParser->new(allow_fuzzy => 0);

    $qs = "foo~0.5 bar^2 foo:baz";

    print $qp->filter($qs, allow_fuzzy => 1, allow_boost => 0);
    # foo~0.5 bar baz

    print $qp->filter($qs, fields => 1 );
    # foo bar^2 foo:baz

=head2 escape_reserved

Reserved characters must be escaped to be used in the query string. By default,
L</"filter()"> will remove these characters. Set C<escape_reserved> to true
if you want them to be escaped instead.

Reserved characters: C< + - && || ! ( ) { } [ ] ^ " ~ * ? : \>

=head2 fields

Normally, you don't want to allow your users to specify which fields to
search.  By default, L</"filter()"> removes any field prefixes, eg:

    $qp->filter('foo:bar secret_field:SIKRIT')
    # bar SIKRIT

You can set C<fields> to C<1> to allow all fields, or pass in a hashref
with a list of approved fieldnames, eg:

    $qp->filter('foo:bar secret_field:SIKRIT', fields => 1);
    # foo:bar secret_field:SIKRIT

    $qp->filter('foo:bar secret_field:SIKRIT', fields => {foo => 1});
    # foo:bar SIKRIT

Elasticsearch extends the standard Lucene syntax to include:

    _exists_:fieldname
  and
    _missing_:fieldname

The C<fields> option applies to these fieldnames as well.

=head2 allow_bool

Query strings can use boolean operators like:

    foo AND bar NOT baz OR ! (foo && bar)

By default, boolean operators are allowed.  Set C<allow_bool> to C<false>
to disable them.

Note: This doesn't affect the C<+> or C<-> operators, which are always
allowed. eg:

    +apple -crab

=head2 allow_boost

Boost allows you to give a more importance to a particular word, group
of words or phrase, eg:

    foo^2  (bar baz)^3  "this exact phrase"^5

By default, boost is enabled.  Setting C<allow_boost> to C<false> would convert
the above example to:

    foo (bar baz) "this exact phrase"

=head2 allow_fuzzy

Lucene supports fuzzy searches based on the Levenshtein Distance, eg:

    supercalifragilisticexpialidocious~0.5

To disable these, set C<allow_fuzzy> to false.

=head2 allow_slop

While a C<phrase search> (eg C<"this exact phrase">) looks for the exact
phrase, in the same order, you can use phrase slop to find all the words in
the phrase, in any order, within a certain number of words, eg:

    For the phrase: "The quick brown fox jumped over the lazy dog."

    Query string:               Matches:
    "quick brown"               Yes
    "brown quick"               No
    "quick fox"                 No
    "brown quick"~2             Yes  # within 2 words of each other
    "fox dog"~6                 Yes  # within 6 words of each other

To disable this "phrase slop", set C<allow_slop> to C<false>

=head2 allow_ranges

Lucene can accept ranges, eg:

    date:[2001 TO 2010]   name:[alan TO john]

To enable these, set C<allow_ranges> to C<true>.

=head2 wildcard_prefix

Lucene can accept wildcard searches such as:

    jo*n  smith?

Lucene takes these wildcards and expands the search to include all matching
terms, eg C<jo*n> could be expanded to C<jon>, C<john>, C<jonathan> etc

This can result in a huge number of terms, so it is advisable to require
that the first C<$min> characters of the word are not wildcards.

By default, the C<wildcard_prefix> requires that at least the first character
is not a wildcard, ie C<*> is not acceptable, but C<s*> is.

You can change the minimum length of the non-wildcard prefix by setting
C<wildcard_prefix>, eg:

    $qp->filter("foo* foobar*", wildcard_prefix=>4)
    # "foo foobar*"

=head1 AUTHOR

Clinton Gormley <drtech@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2014 by Elasticsearch BV.

This is free software, licensed under:

  The Apache License, Version 2.0, January 2004

=cut
