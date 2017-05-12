
package Search::Indexer::Incremental::MD5::Searcher ;

use strict;
use warnings ;
use Carp qw(carp croak confess) ;

BEGIN 
{
use Sub::Exporter -setup => 
	{
	exports => [ qw() ],
	groups  => 
		{
		all  => [ qw() ],
		}
	};
	
use vars qw ($VERSION);
$VERSION     = '0.02';
}

#----------------------------------------------------------------------------------------------------------

use Time::HiRes     qw/time/;
use Search::Indexer 0.75;
use Search::Indexer::Incremental::MD5 ;
use BerkeleyDB;
use English qw( -no_match_vars ) ;
use Readonly ;

=head1 NAME

Search::Indexer::Incremental::MD5::Searcher - Search your indexed files

=head1 SYNOPSIS

  
  my $search_string = 'find_me' ;
  my $searcher = 
	eval 
	{
	Search::Indexer::Incremental::MD5::Searcher->new
		(
		USE_POSITIONS => 1, 
		INDEX_DIRECTORY => 'text_index', 
		get_perl_word_regex_and_stop_words(),
		)
	} or croak "No full text index found! $@\n" ;
  
  my $results = $searcher->search($search_string) ;
  
  # sort in decreasing score order
  my @indexes = map { $_->[0] }
		    reverse
		        sort { $a->[1] <=> $b->[1] }
			    map { [$_, $results->[$_]{SCORE}] }
			        0 .. $#$results ;
  
  for (@indexes)
	{
	print {* STDOUT} "$results->[$_]{PATH} [$results->[$_]{SCORE}].\n" ;
	}
	
  $searcher = undef ;
  

=head1 DESCRIPTION

This module implements an incremental text indexer and searcher based on L<Search::Indexer>.

=head1 DOCUMENTATION

Given a list of files, this module will allow you to create an indexed text database that you can later
query for matches. You can also use the B<siim> command line application installed with this module.

=head1 SUBROUTINES/METHODS

=cut

#----------------------------------------------------------------------------------------------------------

sub new
{

=head2 new( %named_arguments)

Create a Search::Indexer::Incremental::MD5::Searcher object.  

  my $indexer = new Search::Indexer::Incremental::MD5::Searcher(%named_arguments) ;

I<Arguments> - %named_arguments

=over 2 

=item  - 

=back

I<Returns> - A B<Search::Indexer::Incremental::MD5::Searcher> object

I<Exceptions> - 

=over 2 

=item * Incomplete argument list

=item * Error creating index directory

=item * Error opening index metadata database

=item * Error creating a Search::Indexer object

=back

=cut

my ($class, %arguments) = @_ ;

my $index_directory = $arguments{INDEX_DIRECTORY} or croak 'Error: index directory missing' ;
-d $index_directory or croak "Error: can't find the index directory '$index_directory': $!";

Readonly my $ID_TO_METADATA_FILE => 'id_to_docs_metadata.bdb' ;

# use id_to_docs_metadata.bdb, to store a lookup from the uniq id 
# to the document metadata {$doc_id => "$md5\t$path"}
tie my %id_to_metadata, 'BerkeleyDB::Hash',  ## no critic (Miscellanea::ProhibitTies)
	-Filename => "$index_directory/$ID_TO_METADATA_FILE", 
	-Flags    => DB_CREATE
		or croak "Error: opening '$index_directory/$ID_TO_METADATA_FILE': $^E $BerkeleyDB::Error";

return 
	bless 
		{
		INDEXER => new Search::Indexer
					(
					writeMode => 0,
					dir       => $index_directory,
					#~ preMatch  => '[[',
					#~ postMatch => ']]',
					) ,
					
		ID_TO_METADATA => \%id_to_metadata,
		USE_POSITIONS => $arguments{USE_POSITIONS} , 
		INDEX_DIRECTORY => $arguments{INDEX_DIRECTORY}, 
		}, $class ;
}

#----------------------------------------------------------------------------------------------------------

sub words
{

=head2 words( $prefix)

Returns an array reference containing words starting with $prefix

I<Arguments>

=over 2 

=item *  $prefix  - String -  only words starting with $prefix will be returned

=back

I<Returns> - An array reference containing the words starting with $prefix

I<Exceptions> - No full text index found

=cut

my ($self, $prefix) = @_ ;

return $self->{INDEXER}->words($prefix) ;
}
	
#----------------------------------------------------------------------------------------------------------

sub search
{

=head2 search(%named_arguments)

search for $search_string in the index database

I<Arguments> %named_arguments

=over 2 

=item SEARCH_STRING  - Query string see L<Search::Indexer>

=back

I<Returns> - Array reference - each entry contains

=over 2 

=item *  SCORE - the score obtained by the file when applying the query

=item *  PATH - the path to the file

=item *  MD5 - the file MD5 when the indexing was done

=back

=cut

my ($self, %arguments) = @_ ;

my $search_string = $arguments{SEARCH_STRING} ;

# force Some::Module::Name into "Some::Module::Name" to prevent 
# interpretation of ':' as a field name by Query::Parser
$search_string =~ s/(^|\s)([\w]+(?:::\w+)+)(\s|$)/$1"$2"$3/smxg;

my $search_results = $self->{INDEXER}->search($search_string, 'implicit_plus');

my @matching_files ;

foreach my $matching_id (keys %{$search_results->{scores}}) 
	{
	if(exists $self->{ID_TO_METADATA}{$matching_id})
		{
		my ($md5, $path, $description) = split qr/\t/smx, $self->{ID_TO_METADATA}{$matching_id};
		
		push @matching_files,
			{
			SCORE => $search_results->{scores}{$matching_id},
			PATH => $path,
			DESCRIPTION => $description,
			MD5 => $md5,
			ID => $matching_id,
			} ;
		}
	else
		{
		#~ carp "matching id '$matching_id' corresponds to removed document!\n" ;
		}
	}
	
return \@matching_files ;
}

#----------------------------------------------------------------------------------------------------------

sub match_description
{

=head2 match_description(%named_arguments)

search for documents which description matches a regular expression passed as argument. Documents
without description never match.

I<Arguments> %named_arguments

=over 2 

=item SEARCH_STRING  - regular expression to match with the description field

=back

I<Returns> - Array reference - each entry contains

=over 2 

=item *  PATH - the path to the file

=item *  MD5 - the file MD5 when the indexing was done

=item *  DESCRIPTION - the file description

=back

=cut

my ($self, %arguments) = @_ ;

my $search_string = $arguments{SEARCH_STRING} ;

my @matching_files ;

for my $id (keys %{$self->{ID_TO_METADATA}}) 
	{
	my ($md5, $path, $description) = split qr/\t/smx, $self->{ID_TO_METADATA}{$id};
	
	if(defined $description && $description =~$search_string)
		{
		push @matching_files,
			{
			PATH => $path,
			DESCRIPTION => $description,
			MD5 => $md5,
			ID => $id,
			} ;
		}
	}
	
return \@matching_files ;
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

=cut
