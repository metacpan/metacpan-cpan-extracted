package SWISH::HiLiter;
use strict;
use Carp;
use Data::Dump qw( dump );
use Search::Tools::HiLiter;
use Search::Tools::Snipper;
use Search::Tools::UTF8;
use base qw( Search::Tools::Object );

# the fuzzy word access was fixed in SWISH::API 0.04
# but this module will still work under 0.03 if not using fuzzy
eval { require SWISH::API; };    # eval per cpan bug request 14003
if ( $@
    or ( $SWISH::API::VERSION eq '0.01' or $SWISH::API::VERSION eq '0.02' ) )
{
    die "SWISH::HiLiter requires SWISH::API version 0.03 or newer\n";
}

our $VERSION = '0.08';

__PACKAGE__->mk_accessors(qw( hiliter snipper swish query ));

sub init {
    my $self = shift;
    my %args = @_;

    # interrogate the SWISH::API object first to get word_chars, etc.
    if ( !$args{swish} ) {
        croak "SWISH::API object required";
    }
    my $token_meta = $self->_get_swish_index_info( $args{swish} );

    # normalize param names
    for my $name ( keys %$token_meta ) {
        my $val = $token_meta->{$name};
        $name =~ s/(\w+?)([A-Z])/$1_\l$2/g;
        $name = lc($name);
        next if ( exists $args{$name} );
        $args{$name} = $val;
    }

    #dump $self;

    $args{stemmer} = undef;
    unless ( $args{no_stemmer} ) {
        $args{stemmer} = sub {
            return $self->{_use_stemming} ? $self->stem( $_[1] ) : $_[1];
        };
    }
    my %api_ok = map { $_ => $args{$_} } grep { $self->can($_) } keys %args;
    %api_ok = $self->_normalize_args(%api_ok);
    $self->SUPER::init(%api_ok);

    my $query = $self->query or croak "query required";

    # cache the query_parser for use in set_query()
    $self->{_query_parser} = $query->qp;

    # create snipper and hiliter
    my %snipper_args = map { $_ => $args{$_} }
        grep { Search::Tools::Snipper->can($_) } keys %args;
    my %hiliter_args = map { $_ => $args{$_} }
        grep { Search::Tools::HiLiter->can($_) } keys %args;

    $self->{_snipper_args} = \%snipper_args;
    $self->{_hiliter_args} = \%hiliter_args;

    $self->{hiliter}
        ||= Search::Tools::HiLiter->new( %hiliter_args, query => $query );
    $self->{snipper}
        ||= Search::Tools::Snipper->new( %snipper_args, query => $query );
    return $self;
}

sub _get_swish_index_info {

    # takes a SWISH::API object and
    # uses the SWISH methods to set WordChar, etc.

    my $self       = shift;
    my $swish_obj  = shift or croak "SWISH::API object required";
    my @head_names = $swish_obj->HeaderNames;
    my @indexes    = $swish_obj->IndexNames;

    # just use the first index, assuming user
    # won't pass more than one with different Header values
    my $index = shift @indexes;
    $self->{_index} = $index;    # cache for stem()

    my %token_meta;
    for my $h (@head_names) {

        my @v = $swish_obj->HeaderValue( $index, $h );

        $self->{_index_headers}->{$h}
            = scalar @v > 1
            ? [@v]
            : $v[0];

        $token_meta{$h} = quotemeta( to_utf8( $v[0] || '' ) )
            if $h =~ /char/i;

    }

    # set stemmer flag if it was used in the index

    $self->{_use_stemming} = $self->{'Stemming Applied'};

    return \%token_meta;
}

sub stem {
    if ( $SWISH::API::VERSION < 0.04 ) {
        die "stem() requires SWISH::API version 0.04 or newer\n";
    }
    my $self  = shift;
    my $w     = shift;
    my $index = $self->{_index} || ( $self->{swish}->IndexNames )[0];
    $self->{_index} ||= $index;
    my $fw = $self->{swish}->Fuzzify( $index, $w );
    my @fuzz = $fw->WordList;

    if ( my $e = $fw->WordError ) {
        warn "Error in Fuzzy WordList ($e): $!\n";
        return undef;
    }

    return $fuzz[0];    # we ignore possible doublemetaphone

}

sub light {
    return shift->hiliter->light(@_);
}

*setq = \&set_query;

sub set_query {
    my $self = shift;
    my $q    = shift;
    if ( !defined $q ) {
        croak "query required";
    }

    # re-create hiliter and snipper objects
    # this is mostly a backwards compat feature,
    # as it would be just as easy to create a new SWISH::HiLiter
    # for each query. All we save is the index interrogation.
    $self->{query} = $self->{_query_parser}->parse($q);
    $self->{hiliter}
        = Search::Tools::HiLiter->new( %{ $self->{_hiliter_args} },
        query => $self->{query} );
    $self->{snipper}
        = Search::Tools::Snipper->new( %{ $self->{_snipper_args} },
        query => $self->{query} );
    return $self->{query};
}

sub snip {
    return shift->snipper->snip(@_);
}

1;
__END__

=head1 NAME

SWISH::HiLiter - simple interface to SWISH::API and Search::Tools

=head1 SYNOPSIS

  use SWISH::API;
  use SWISH::HiLiter;
  use Search::Tools::UTF8;
  
  my $query   = "foo OR bar";
  my $swish   = SWISH::API->new( 'my_index' );
  my $hiliter = SWISH::HiLiter->new( 
    swish => $swish, 
    query => $query,
  );
     
  my $results = $swish->query( $query );
  
  while ( my $result = $results->next_result ) {
	
	my $path 	= $result->Property( "swishdocpath" );
	my $title 	= $hiliter->light(
				to_utf8( $result->Property( "swishtitle" ) )
			  );
	my $snip 	= $hiliter->light(
			    $hiliter->snip(
				to_utf8( $result->Property( "swishdescription" ) )
			    )
			  );
	my $rank 	= $result->Property( "swishrank" );
	my $file	= $result->Property( "swishreccount" );
       
	print join("\n", $file, $path, $title, $rank, $snip );
	
  }
   

=head1 DESCRIPTION

SWISH::HiLiter is a simple interface to Search::Tools. It is designed
to work specifically with the SWISH::API module for searching Swish-e 
indexes and displaying snippets of highlighted text from 
the stored Swish-e properties.

SWISH::HiLiter is B<NOT> a drop-in replacement for the highlighting modules that
come with the Swish-e distribution. Instead, it is intended to be used when programming
with SWISH::API.

=head1 REQUIREMENTS

=over

=item

Search::Tools 0.25 or later.

If you intend to use full-page highlighting, also get the HTML::Parser and its
required modules.

=item

Perl 5.8.3 or later.

=item

SWISH::API 0.04 or later.

=back

=head1 METHODS

=head2 new()

Create a SWISH::HiLiter object. The new() method requires
a hash of parameter key/values. Available parameters include:

=over

=item swish

A SWISH::API object. Version 0.03 or newer. [ Required ]

=item query

The query string you want highlighted. [ Required ]

=item colors

A reference to an array of HTML color names.

=item occur

How many query matches to display when running snip(). 
See also Search::Tools::Snipper.

=item max_chars

Number of words around match to return in snip(). 
See also Search::Tools::Snipper.

=item noshow

Bashful setting. If snip() fails to match any of your query 
(as can happen if the match is beyond the range of SwishDescription 
as set in your index), don't show anything. The
default is to show the first I<max_chars> of the text.

See the "dump" algorithm in Search::Tools::Snipper.

=item snipper

A Search::Tools::Snipper object. If you do not provide one,
one will be created for you. The snip() method delegates
to Search::Tools::Snipper. The snipper() method can get/set
the internal Snipper object.

See Search::Tools::Snipper for a description of the different snipping
algorithms.

=item hiliter

A Search::Tools::HiLiter object. If you do not provide one,
one will be created for you. The light() method delegates
to Search::Tools::HiLiter. The hiliter() method can get/set
the internal HiLiter object.

=item escape

Your text is assumed not to contain HTML markup and so it is HTML-escaped by default.
If you have included markup in your text and want it left as-is, set 'escape' to 0. Highlighting
should still work, but snip() might break.

=back

=head2 init

Called internally.

=head2 snip( I<text> )

Returns extracted snippets from I<text> that include terms from the I<query>.

=head2 light( I<text> )

Returns highlighted I<text>. See new() for ways to control context, length, etc.

=head2 stem( I<word> )

Return the stemmed version of a word. Only works if your first index in SWISH::API
object used Fuzzy Mode.

This method is just a wrapper around SWISH::API::Fuzzify.

The stem() method is called internally by the Search::Tools::QueryParser.

B<NOTE:> stem() requires SWISH::API version 0.04 or newer. If you have an older
SWISH::API, first consider upgrading (0.03 is very old), and second, set C<no_stemmer>
in new() to turn off stemming.

=head2 set_query( I<query> )

Set the query in the highlighting object. Called automatically by new() if
'query' is present in the new() call.

You should only call set_query() if you are trying to re-use a SWISH::HiLiter
object, as when under a persistent environment like mod_perl or in a loop.

Like query(), return the internal Search::Tools::Query object representing I<query>.

=head2 setq( I<query> )

For pre-0.04 compatability, setq() is an alias to set_query().

=head1 LIMITATIONS

If your text contains HTML markup and escape = 0, snip() may fail to return
valid HTML. I don't consider this a bug, but listing here in case it happens to you.

Stemming and regular expression building considers only the first index's header values
from your SWISH::API object. If those header values differ (for example, WordCharacters
is defined differently), be aware that only the first index from SWISH::API::IndexNames is used.

B<REMINDER:> Use HTML::HiLiter to highlight full HTML pages;
use SWISH::HiLiter to highlight plain text and smaller HTML chunks.

=head1 AUTHOR

Peter Karman, karman@cray.com

Thanks to the Swish-e developers, in particular Bill Moseley for graciously
sharing time, advice and code examples.

Comments and suggestions are welcome.

=head1 COPYRIGHT

 ###############################################################################
 #    CrayDoc 4
 #    Copyright (C) 2004 Cray Inc swpubs@cray.com
 #
 #    This program is free software; you can redistribute it and/or modify
 #    it under the terms of the GNU General Public License as published by
 #    the Free Software Foundation; either version 2 of the License, or
 #    (at your option) any later version.
 #
 #    This program is distributed in the hope that it will be useful,
 #    but WITHOUT ANY WARRANTY; without even the implied warranty of
 #    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 #    GNU General Public License for more details.
 #
 #    You should have received a copy of the GNU General Public License
 #    along with this program; if not, write to the Free Software
 #    Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA 02111-1307, USA.
 ###############################################################################


=head1 SEE ALSO

L<HTML::HiLiter>, L<SWISH::API>, L<Search::Tools>

=cut
