package Search::Tools::Query;
use Moo;
extends 'Search::Tools::Object';
use overload
    '""'     => sub { $_[0]->str; },
    'bool'   => sub {1},
    fallback => 1;
use Carp;
use Data::Dump qw( dump );
use Search::Tools::RegEx;
use Search::Tools::UTF8;
use Search::Tools::Tokenizer;
use Search::Tools::XML;

use namespace::autoclean;

our $VERSION = '1.007';

has 'terms'   => ( is => 'ro' );
has 'fields'  => ( is => 'ro' );
has 'dialect' => ( is => 'ro' );
has 'str'     => ( is => 'ro' );
has 'regex'   => ( is => 'ro' );
has 'qp'      => ( is => 'ro' );

=head1 NAME

Search::Tools::Query - objectified string for highlighting, snipping, etc.

=head1 SYNOPSIS

 use Search::Tools::QueryParser;
 my $qparser  = Search::Tools::QueryParser->new;
 my $query    = $qparser->parse(q(the quick color:brown "fox jumped"));
 my $fields   = $query->fields; # ['color']
 my $terms    = $query->terms;  # ['quick', 'brown', '"fox jumped"']
 my $regex    = $query->regex_for($terms->[0]); # S::T::RegEx
 my $tree     = $query->tree; # the Search::Query::Dialect tree()
 print "$query\n";  # the quick color:brown "fox jumped"
 print $query->str . "\n"; # same thing


=head1 DESCRIPTION


=head1 METHODS

=head2 fields

Array ref of fields from the original query string.
See Search::Tools::QueryParser for controls over ignore_fields().

=head2 terms

Array ref of key words from the original query string.
See Search::Tools::QueryParser for controls over ignore_fields()
and tokenizing regex.

B<NOTE:>
Only positive words are extracted by QueryParser. 
In other words, if you search for:

 foo not bar
 
then only C<foo> is returned. Likewise:

 +foo -bar
 
would return only C<foo>.

=head2 str

The original string.

=head2 regex

The hash ref of terms to Search::Tools::RegEx objects.

=head2 dialect

The internal Search::Query::Dialect object. See tree()
and str_clean() which delegate to the dialect object.

=head2 qp

The Search::Tools::QueryParser object used to generate the Query.

=head2 num_terms

Returns the number of terms().

=cut

sub num_terms {
    return scalar @{ shift->{terms} };
}

=head2 unique_terms

Returns array ref of unique terms from query.
If stemming was on in the QueryParser,
all terms have already been stemmed as part
of the parsing process.

=cut

sub unique_terms {
    my $self = shift;
    my @t    = @{ $self->{terms} };
    my %uniq;
    for my $t (@t) {
        my $re = $self->regex_for($t);
        if ( $re->is_phrase ) {
            for my $pt ( @{ $re->phrase_terms } ) {
                $uniq{ $pt->term }++;
            }
        }
        else {
            $uniq{ $re->term }++;
        }
    }
    return [ keys %uniq ];
}

=head2 num_unique_terms

Returns number of unique_terms().

=cut

sub num_unique_terms {
    return scalar( @{ $_[0]->unique_terms } );
}

=head2 phrases

Return array ref of RegEx objects for all terms where is_phrase
is true.

=cut

sub phrases {
    my $self = shift;
    my @p;
    for my $t ( keys %{ $self->{regex} } ) {
        if ( $self->{regex}->{$t}->is_phrase ) {
            push @p, $self->{regex}->{$t};
        }
    }
    return \@p;
}

=head2 non_phrases

Return array ref of RegEx objects for all terms where is_phrase
is false.

=cut

sub non_phrases {
    my $self = shift;
    my @p;
    for my $t ( keys %{ $self->{regex} } ) {
        if ( !$self->{regex}->{$t}->is_phrase ) {
            push @p, $self->{regex}->{$t};
        }
    }
    return \@p;
}

=head2 tree

Returns the internal Search::Query::Dialect tree().

=cut

sub tree {
    my $self = shift;
    return $self->dialect->tree();
}

=head2 str_clean

Returns the internal Search::Query::Dialect stringify().

=cut

sub str_clean {
    my $self = shift;
    return $self->dialect->stringify();
}

=head2 regex_for(I<term>)

Returns a Search::Tools::RegEx object for I<term>.

=cut

sub regex_for {
    my $self = shift;
    my $term = shift;
    unless ( defined $term ) {
        croak "term required";
    }
    my $regex = $self->{regex} or croak "regex not defined for query";
    if ( !exists $regex->{$term} ) {
        croak "no regex for $term";
    }
    return $regex->{$term};
}

=head2 regexp_for

Alias for regex_for(). The author has come to prefer "regex"
instead of "regexp" because it's one less keystroke.

=cut

*regexp_for = \&regex_for;

=head2 matches_text( I<text> )

Returns the number of matches for the query against I<text>.

=head2 matches_html( I<html> )

Returns the number of matches for the query against I<html>.

=cut

sub _matches_stemmed {
    my $self      = shift;
    my $text      = to_utf8( $_[0] );
    my $count     = 0;
    my $qp        = $self->qp;
    my $stemmer   = $qp->stemmer;
    my $wildcard  = $qp->wildcard;
    my $tokenizer = Search::Tools::Tokenizer->new(
        re    => $qp->term_re,
        debug => $self->debug,
    );

    # stem the whole text, creating a new buffer to
    # match against. This covers both the cases where
    # a term is a phrase and where it is not.
    my @buf;
    my $buf_maker = sub {
        push @buf, $stemmer->( $qp, $_[0]->str );
    };
    $tokenizer->tokenize( $text, $buf_maker );
    my $new_text = join( " ", @buf );

    for my $term ( @{ $self->{terms} } ) {
        my $re = $self->{regex}->{$term}->{plain};
        $count += $new_text =~ m/$re/;
    }
    return $count;
}

sub _matches {
    my $self  = shift;
    my $style = shift;
    my $text  = to_utf8( $_[0] );
    my $count = 0;
    for my $term ( @{ $self->{terms} } ) {
        my $regex = $self->{regex}->{$term}->{$style};
        $count += $text =~ m/$regex/;
    }
    return $count;
}

sub matches_text {
    my $self = shift;
    my $text = shift;
    if ( !defined $text ) {
        croak "text required";
    }
    return $self->_matches_stemmed($text) if $self->qp->stemmer;
    return $self->_matches( 'plain', $text );
}

sub matches_html {
    my $self = shift;
    my $html = shift;
    if ( !defined $html ) {
        croak "html required";
    }
    if ( $self->qp->stemmer ) {
        return $self->_matches_stemmed( Search::Tools::XML->no_html($html) );
    }
    return $self->_matches( 'html', $html );
}

=head2 terms_as_regex([I<treat_phrases_as_singles>])

Returns all terms() as a single qr// regex, pipe-joined in a "OR"
logic.

=cut

sub terms_as_regex {
    my $self                     = shift;
    my $treat_phrases_as_singles = shift;
    $treat_phrases_as_singles = 1 unless defined $treat_phrases_as_singles;
    my $wildcard = $self->qp->wildcard;
    my $wild_esc = quotemeta($wildcard);
    my $wc       = $self->qp->word_characters;
    my @re;
    for my $term ( @{ $self->{terms} } ) {

        my $q = quotemeta($term);    # quotemeta speeds up the match, too
                                     # even though we have to unquote below

        $q =~ s/\\$wild_esc/[$wc]*/g;    # wildcard match is very approximate

        # treat phrases like OR'd words
        # since that will just create more matches.
        # if hiliting later, the phrase will be treated as such.
        if ($treat_phrases_as_singles) {
            $q =~ s/(\\ )+/\|/g;
        }

      # if keeping phrases together use a less-naive regex instead of a space.
        else {

            #$q = $self->regex_for($term)->plain();
            #$q =~ s/(\\ )+/[^$wc]+/g;
        }

        push( @re, $q );
    }

    my $j = sprintf( '(%s)', join( '|', @re ) );
    return qr/$j/i;
}

1;

__END__

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

Search::Query::Dialect
