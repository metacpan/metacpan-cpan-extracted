package String::FuzzyMatch 0.01;
use 5.022;
use experimental 'signatures';
use feature 'postderef';
use Unicode::Normalize;
use Moo 2;

=encoding utf8

=head1 NAME

String::FuzzyMatch - match strings fuzzily

=head1 SYNOPSIS

  my $filter = String::FuzzyFind->new(
      highlight_start => '[',
      highlight_end => ']',
  );

  $filter->filter( 'ab', ['aab','abc','acb','cba','aaa', 'abab'] );
  # ['aab','abc','acb','abab' ]

  # By default ignores diacritics and case in haystack
  $filter->( 'ab', ['Aäb','abc','Äbc','äcb','cba','aaa'] );
  # ['Aäb','abc','Äbc','äcb' ]

  # By default respects diacritics in needle
  $filter->( 'äb', ['aäb','abc','Äbc','äcb','cba','aaa'] );
  # ['aäb','Äbc','äcb' ]

  # Ignore diacritics in needle as well
  my $ignore_diacritics = String::FuzzyFind->new(
      ignore_diacritics_lhs => 1,
  );
  $ignore_diacritics->( 'äb', ['aäb','abc','äbc','Äcb','cba','aaa'] );
  # ['aäb','abc','äbc','Äcb']


  $filter->highlight( 'ab', 'äcb' );
  # '[ä]c[b]'

  $filter->highlight( 'ab', 'äb/c' );
  # '[äb]/c'

  # HTML highlighting
  my $html = String::FuzzyFind->new(
      highlight_start => '<highlight>',
      highlight_end => '</highlight>',
  );
  $html->highlight( 'ab', 'äcb' );
  # '<highlight>ä</highlight>c<highlight>b</highlight>'


=head1 DESCRIPTION

This module fuzzily matches strings. All characters of the search string
("needle") must occur in sequence in the strings in the search list
("haystack"). So filtering by C<ab> will find C<a/b>, C<aaaab>
and C<cranberry>.

The searcher expects Unicode strings and matches using Unicode semantics.
The filter by default ignores diacritics and case in the haystack
and case in the needle, searching for C<abba> will also find C<ÄBBA>
by default.

This search approach is heavily inspired by the
filtering in L<fzf|https://junegunn.github.io/fzf/> but does not
implement any of the advanced query language.

=cut

=head2 C<< new >>

Creates a new filter

  my $filter = String::FuzzyFilter->new();

=over 4

=cut

has '_filter_code' => (
    is => 'ro',
    required => 1,
);

=item B<highlight>, B<highlight_start>, B<highlight_end>

  highlight => '_'

String to use for highlighting. Default C<[> and C<]>.

=cut
has 'highlight_start' => (
    is => 'rw',
);

has 'highlight_end' => (
    is => 'rw',
);

=item B<highlight_cb>

  highlight_cb =>  sub( $match ) { return "->$match<-" }

Callback to return a highlighted match.
Default: C<undef>.

=cut

has 'highlight_cb' => (
    is => 'rw',
);

=item B<match>

  match => 'caption'

Key of the hash to use for matching, if haystack contains only hashrefs. Can
be a scalar or a callback. Default: C<undef>.

=back

=cut

has 'match' => (
    is => 'ro',
);

sub _build_filter_re( $self, $needle, %args ) {
    my $nfd_needle = NFD($needle);
    my $q;

    if( !$args{ ignore_diacritics_lhs } ) {
        $q = '(?i)(.*?)' . join( '(.*?)',
            map { "($_)" }
            map { /\p{GrExt}/ ? quotemeta($_) : quotemeta($_) . '[\p{GrExt}]*\b{gcb}' }
            split /\b{gcb}/, $nfd_needle )
            . '(.*?)';

    } else {
        $nfd_needle =~ s/\p{GrExt}//g;
        $q = '(?i)(.*?)' . join( '(.*?)',
            map { "($_)" }
            map { quotemeta($_) } split /\b{gcb}/, $nfd_needle)
            . '(.*?)';
    }

    return $q;
}

# Default filter builder
sub _naive_filter( $self, %args ) {
    my $fetch = $args{ match } // (ref $self && $self->match);

    if( $fetch ) {
        return sub( $needle, $haystack ) {
            my $q = $self->_build_filter_re( $needle, %args );
            return [
                grep { NFD($fetch->($_)) =~ /$q/ }
                $haystack->@*
            ];
        }

    } else {
        return sub( $needle, $haystack ) {
            my $q = $self->_build_filter_re( $needle, %args );
            return [
                grep { NFD($_) =~ /$q/ }
                $haystack->@*
            ];
        }
    };
}


# If you're looking here, you likely want to make the filter faster.
# The below versions are specialized versions of the _naive_filter()
# which I discarded, since the simplicity of the code was worth more to me
# than the potential performance
#sub _filter( $self, %args ) {
#    my $transliterator = Text::Transliterator::Unaccent->new();
#
#    return sub( $needle, $haystack ) {
#        my $nfd_needle = NFD($needle);
#        my $has_diacritics = ($nfd_needle =~ /\P{GrBase}/);
#
#        if( $has_diacritics ) {
#            my $diacritic_respecting = '(.*?)' . join( '(.*?)',
#                map { /\p{GrExt}/ ? quotemeta($_) : quotemeta($_) . '[\p{GrExt}]*' }
#                split /\b{gcb}/, $nfd_needle )
#                . '(.*?)';
#
#            return [
#                grep { NFD($_) =~ /$diacritic_respecting/ }
#                $haystack->@*
#            ];
#
#        } else {
#            my $q = '(.*?)' . join( '(.*?)', map { quotemeta($_) } split //, $needle) . '(.*?)';
#            return [
#                grep { my $copy = $_; $transliterator->($copy); $copy =~ /$q/ }
#                $haystack->@*
#            ];
#        }
#    }
#}
#
## ASCII filter builder, ignores diacritics on the lhs too
#sub _ascii_filter( $self, %args ) {
#    # remove diacritics on the rhs
#    # remove diacritics on the lhs
#
#    my $transliterator = Text::Transliterator::Unaccent->new();
#
#    return sub( $needle, $haystack ) {
#        $transliterator->($needle);
#        my $q = '(.*?)' . join( '(.*?)', map { quotemeta($_) } split //, $needle) . '(.*?)';
#        return [
#            grep { my $copy = $_; $transliterator->($copy); $copy =~ /$q/ }
#            $haystack->@*
#        ]
#    }
#}

around BUILDARGS => sub( $orig, $class, %args ) {
    if( $args{ match } && !ref $args{ match }) {
        my $key = delete $args{ match };
        $args{ match } = sub( $o ) { $o->{$key} };
    }

    $args{ _filter_code } = $class->_naive_filter( %args );

    #if( $args{ignore_diacritics_lhs} ) {
    #    $args{ _filter_code } = $class->_ascii_filter( %args );
    #
    #} else {
    #    $args{ _filter_code } = $class->_filter( %args );
    #};

    $args{ highlight_start } //= $args{ highlight } // "[";
    $args{ highlight_end   } //= $args{ highlight } // "]";

    return $class->$orig(%args);
};

=head2 C<< ->filter $needle, $haystack >>

  my $results = $filter->filter( 'ab', ['ABBA','cabbage','all/users/ben','Änderungen (bearbeitet)','nobody'] );
  # ['ABBA','cabbage','all/users/ben','Änderungen (bearbeitet)']

Filters a list by the query given as string. All strings are assumed
to be Unicode strings.

=cut

sub filter( $self, $needle, $haystack ) {
    $self->_filter_code->($needle,$haystack)
}

=head2 C<< ->highlight $needle, $str >>

Returns a string with the matched parts of a string highlighted.

  my $higlighted = $filter->highlight( 'ab', 'all/users/ben' );
  # '[a]ll/users/[b]en'

Note that the returned string will be in NFD.

=cut

sub highlight( $self, $needle, $o_str, %args ) {
    return $o_str unless length $needle;

    $args{ highlight_start } //= $self->highlight_start // $args{ highlight };
    $args{ highlight_end }   //= $self->highlight_end // $args{ highlight };
    my $cb = $args{ highlight_cb } // $self->highlight_cb;

    # Should match the other query-to-regex part
    my $q = $self->_build_filter_re( $needle );

    my $str = NFD($o_str);

    $str =~ /$q/
        or return $o_str;

    # Rebuild the string with the markers inserted
    my $res = '';

    my ($match_start);

    for my $i (1.. scalar(@+) -1) {
        my $matched = !($i % 2); # odd parentheses are matched parts

        #say sprintf "%02d: [%s] '%s'", $i, $matched ? 'x' : '-', substr( $str, $-[$i], $+[$i]-$-[$i] );
        #use Data::Dumper; $Data::Dumper::Useqq = 1;
        #say Dumper substr( $str, $-[$i], $+[$i]-$-[$i] );

        if( $matched and ($-[$i]==0 or $-[$i-1] != $+[$i-1])) {
            # A match just started
            if( ! $cb ) {
                $res .= $args{ highlight_start };
            };
            $match_start //= $-[$i];
        };
        if( !$matched and $-[$i] < $+[$i] and $i > 1) {
            # A match just ended
            if( $cb ) {
                $res .= $cb->(substr( $str, $match_start, $+[$i-1]-$match_start ));
                undef $match_start;
            } else {
                $res .= $args{ highlight_end };
            };
        };

        $res .= substr( $str, $-[$i], $+[$i]-$-[$i] )
            if( !$matched or !$cb);
    }

    # Append the end, which is always unmatched
    $res .= ($cb ? $cb->(substr( $str, $match_start, $+[scalar @+ -1]-$match_start )) : $args{ highlight_end }) . substr( $str, $+[-1] );

    return $res;
}

1;

=head1 REPOSITORY

The public repository of this module is
L<https://github.com/Corion/String-FuzzyMatch>.

=head1 SUPPORT

The public support forum of this module is L<https://perlmonks.org/>.

=head1 BUG TRACKER

Please report bugs in this module via the Github bug queue at
L<https://github.com/Corion/String-FuzzyMatch/issues>

=head1 AUTHOR

Max Maischein C<corion@cpan.org>

=head1 COPYRIGHT (c)

Copyright 2026-2026 by Max Maischein C<corion@cpan.org>.

=head1 LICENSE

This module is released under the same terms as Perl itself.

=cut
