package Search::Indexer::Incremental::MD5::Language::Perl ;

use strict;
use warnings ;
use Carp qw(carp croak confess) ;

BEGIN 
{
use Sub::Exporter -setup => 
	{
	exports => [ qw(get_perl_word_regex_and_stopwords) ],
	groups  => 
		{
		all  => [ qw() ],
		}
	};
	
use vars qw ($VERSION);
$VERSION     = '0.03';
}

#----------------------------------------------------------------------------------------------------------

use File::stat;
use Time::localtime;
use BerkeleyDB;
use List::Util qw/sum/;

use Search::Indexer::Incremental::MD5::Indexer qw() ;
use Search::Indexer::Incremental::MD5::Searcher qw() ;

use Digest::MD5 ;
use English qw( -no_match_vars ) ;

use Readonly ;
Readonly my $EMPTY_STRING => q{} ;

#~ my @perl_extra_arguments  ;
#~ @perl_extra_arguments = get_perl_word_regex_and_stopwords() if($options->{perl_mode}) ;

#~ my @stopwords ;
#~ @stopwords = (STOPWORDS => $options->{stopwords_file}) if($options->{stopwords_file}) ;


#----------------------------------------------------------------------------------------------------------

=head1 NAME

Search::Indexer::Incremental::MD5::Language::Perl - defined perl specific data to use with L<Search::Indexer>

=head1 SYNOPSIS

  my @perl_extra_arguments = get_perl_word_regex_and_stopwords()  ;
  
  my $searcher 
	= eval 
		{
		Search::Indexer::Incremental::MD5::Searcher->new
			(
			...
			@perl_extra_arguments,
			);
		} or croak "No full text index found! $@\n" ;

=head1 DESCRIPTION

This module contains the regex and stopwords specific for Perl.

=head1 DOCUMENTATION

The word regex and stopwords available in this module are specific for the Perl language.  They regex allows L<Search::Indexer>
to precisely find what Perl considers as a word while the stop words limit the number of word indexed.

=head1 SUBROUTINES/METHODS

=cut

#----------------------------------------------------------------------------------------------------------

sub get_perl_word_regex_and_stopwords
{
	
=head2 get_perl_word_regex_and_stopwords()

creates a $word_regex and $stopwords for the perl language

I<Arguments> - None

I<Returns> -  a list of tuples 

=over 2 

=item (WORD_REGEX => $word_regex) - a key and a regex defining a word in the Perl language

=item (STOPWORDS => $stopwords) - a key and an array reference containing words to ignore in the Perl language

=back

I<Exceptions> - None

=cut

my $id_regex =
	qr{
	(?![0-9])       # don't start with a digit
	\w\w+           # start with 2 or more word chars ..
	 (?:::\w+)*      # .. and  possibly ::some::more::components
	}smx; 

my $word_regex =
	qr{
  	    (?:                # either a Perl variable:
	    (?:\$\#?|\@|\%)    #   initial sigil
	    (?:                #     followed by
	       $id_regex       #       an id
	       |               #     or
	       \^\w            #       builtin var with '^' prefix
	       |               #     or
	       (?:[\#\$](?!\w))#       just '$$' or '$#'
	       |               #     or
	       [^\{\w\s\$]      #       builtin vars with 1 special char
	     )
	     |                 # or
	     $id_regex         # a plain word or module name
	     )
	}smx;

my @stopwords = 
	(
	'a' .. 'z', '_', '0' .. '9',
	qw/
	__data__ __end__ __file__ __line__ $class $indexing_operation
	above after all also always an and any are as at
	be because been before being both but by
	can cannot could
	die do done
	defined do does doesn
	each else elsif eq
	for from foreach
	ge gt
	has have how
	if in into is isn it item its
	keys
	last le lt
	many may me method might must my
	ne new next no nor not
	of on only or other our
	package  pl pm push
	qq qr qw
	ref return
	see shift should since so some something sub such
	than that the their them then these they this those to tr
	undef unless until up us use used uses using
	values
	was we what when which while will with would
	you your
	COPYRIGHT  LICENSE 
	/, 
	'SEE ALSO',
	);

return(WORD_REGEX => $word_regex, STOPWORDS => \@stopwords,) ;
}

#----------------------------------------------------------------------------------------------------------

1 ;

=head1 BUGS AND LIMITATIONS

None so far.

=head1 AUTHOR

	Nadim ibn hamouda el Khemir
	CPAN ID: NKH
	mailto: nadim@cpan.org

=head1 LICENSE AND COPYRIGHT

This program is free software; you can redistribute
it and/or modify it under the same terms as Perl itself.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Search::Indexer::Incremental::MD5

You can also look for information at:

=over 4

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Search-Indexer-Incremental-MD5>

=item * RT: CPAN's request tracker

Please report any bugs or feature requests to  L <bug-search-indexer-incremental-md5@rt.cpan.org>.

We will be notified, and then you'll automatically be notified of progress on
your bug as we make changes.

=item * Search CPAN

L<http://search.cpan.org/dist/Search-Indexer-Incremental-MD5>

=back

=head1 SEE ALSO

L<Search::Indexer>

L<Search::Indexer::Incremental::MD5::Indexer> and L<Search::Indexer::Incremental::MD5::Searcher>

=cut
