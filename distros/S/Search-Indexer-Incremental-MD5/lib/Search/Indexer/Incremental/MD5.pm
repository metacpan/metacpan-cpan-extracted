package Search::Indexer::Incremental::MD5 ;

use strict;
use warnings ;
use Carp qw(carp croak confess) ;

BEGIN 
{
use Sub::Exporter -setup => 
	{
	exports => 
		[
		qw
			(
			delete_indexing_databases
			show_database_information
			add_files
			remove_files
			check_index
			search_string
			)
		],
		
	groups  => 
		{
		all  => [
			qw
				(
				delete_indexing_databases
				show_database_information
				add_files
				remove_files
				check_index
				search_string
				)
			],
		}
	};
	
use vars qw ($VERSION);
$VERSION     = '0.06';
}

#----------------------------------------------------------------------------------------------------------

use File::stat;
use Time::localtime;
use BerkeleyDB;
use List::Util qw/sum/;

use Search::Indexer::Incremental::MD5::Indexer qw() ;
use Search::Indexer::Incremental::MD5::Searcher qw() ;
use Search::Indexer::Incremental::MD5::Language::Perl qw(get_perl_word_regex_and_stopwords) ;

use Digest::MD5 ;
use English qw( -no_match_vars ) ;

use Readonly ;
Readonly my $EMPTY_STRING => q{} ;

#----------------------------------------------------------------------------------------------------------

=head1 NAME

Search::Indexer::Incremental::MD5 - Incrementally index your files

=head1 SYNOPSIS

  use File::Find::Rule ;
  
  use Readonly ;
  Readonly my $DEFAUT_MAX_FILE_SIZE_INDEXING_THRESHOLD => 300 << 10 ; # 300KB
  
  my $indexer 
	= Search::Indexer::Incremental::MD5::Indexer->new
		(
		USE_POSITIONS => 1, 
		INDEX_DIRECTORY => 'text_index', 
		get_perl_word_regex_and_stopwords(),
		) ;
  
  my @files = File::Find::Rule
		->file()
		->name( '*.pm', '*.pod' )
		->size( "<=$DEFAUT_MAX_FILE_SIZE_INDEXING_THRESHOLD" )
		->not_name(qr[auto | unicore | DateTime/TimeZone | DateTime/Locale])
		->in('.') ;
  
  indexer->add_files(@files) ;
  indexer->add_files(@more_files) ;
  indexer = undef ;
  
  my $search_string = 'find_me' ;
  my $searcher = 
	eval 
	{
	Search::Indexer::Incremental::MD5::Searcher->new
		(
		USE_POSITIONS => 1, 
		INDEX_DIRECTORY => 'text_index', 
		get_perl_word_regex_and_stopwords(),
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

Readonly my $ID_TO_METADATA_FILE => 'id_to_docs_metadata.bdb' ;

#----------------------------------------------------------------------------------------------------------

sub show_database_information
{

=head2 show_database_information($index_directory)

I<Arguments>

=over 2 

=item * $index_directory - location of the index databases

=back

I<Returns> - A hash reference. Keys represent an information field.

I<Exceptions> - Error opening the indexing database

=cut

my ($index_directory) = @_ ;

croak 'Error: index directory not defined!'  unless defined $index_directory ;

Readonly my $ID_TO_METADATA_FILE_AND_PATH => "$index_directory/$ID_TO_METADATA_FILE" ;

# use id_to_docs_metadata.bdb, to store a lookup from the uniq id 
# to the document metadata {$doc_id => "$md5\t$path"}
tie my %id_to_metadata, 'BerkeleyDB::Hash', ## no critic (Miscellanea::ProhibitTies)
	-Filename => $ID_TO_METADATA_FILE_AND_PATH, 
	-Flags    => DB_CREATE
		or croak "Error: opening '$ID_TO_METADATA_FILE_AND_PATH': $^E $BerkeleyDB::Error";

return
	{
	entries => scalar(grep {defined $id_to_metadata{$_}} keys %id_to_metadata),
	size => sum(map {-s} (glob("$index_directory/*.bdb"), $ID_TO_METADATA_FILE_AND_PATH)),
	update_date => ctime(stat($ID_TO_METADATA_FILE_AND_PATH)->mtime),
	} ;
}

#----------------------------------------------------------------------------------------------------------

sub delete_indexing_databases
{

=head2 delete_indexing_databases($index_directory)

Removes all the index databases in the passed directory

I<Arguments>

=over 2 

=item * $index_directory - location of the index databases

=back

I<Returns> - Nothing

I<Exceptions> - Can't remove index databases.

=cut

my ($index_directory) = @_ ;

croak "Error: Invalid or undefined index directory!\n" unless defined $index_directory ;

for my $file_to_remove
	(
	"$index_directory/$ID_TO_METADATA_FILE",
	"$index_directory/ixd.bdb",
	"$index_directory/ixw.bdb",
	)
	{
	unlink $file_to_remove or croak "Error: Can't unlink '$file_to_remove': $!" ;
	}

return ;
}

#----------------------------------------------------------------------------------------------------------

sub search_string
{

=head2 search_string(\%arguments)

Displays all the files matching the search query.

I<Arguments>

=over 2 

=item \%arguments - 

=over 2 

=item  - 

=item $arguments->{perl_mode} - Boolean - Use Perl specific word regex and stopwords

=item $arguments->{index_directory} - The location of the index database

=item $arguments->{use_position} - See L<Sear::Indexer> for a complete documentation

=item $arguments->{search} - String - The search query

=item $arguments->{verbose} - Boolean - Display the document id and score if set

=back

=item $search_string - 

=back

I<Returns> - Nothing

I<Exceptions> - None

=cut

my ($arguments) = @_ ;

my $searcher 
	= eval 
		{
		Search::Indexer::Incremental::MD5::Searcher->new
			(
			INDEX_DIRECTORY => $arguments->{index_directory}, 
			USE_POSITIONS => $arguments->{use_position}, 
			);
		} or croak "No full text index found! $@\n" ;

my $results = $searcher->search(SEARCH_STRING => $arguments->{search}) ;

## no critic (ProhibitDoubleSigils)
my @indexes = map { $_->[0] } 
				reverse
					sort { $a->[1] <=> $b->[1] }
						map { [$_, $results->[$_]{SCORE}] }
							0 .. $#$results ;

for my $index (@indexes)
	{
	my $matching_file = $results->[$index]{PATH} ;
	
	if($arguments->{verbose})
		{
		print {* STDOUT} "'$matching_file' [id:$results->[$index]{ID}] with score $results->[$index]{SCORE}.\n" ;
		}
	else
		{
		print {* STDOUT} "$matching_file\n" ;
		}
	}
	
return ;
}

#----------------------------------------------------------------------------------------------------------

sub add_files
{

=head2 add_files(\%arguments, \@files)

Adds files to index, if the files are modified, and displays their name.

I<Arguments>

=over 2 

=item \%arguments - 

=over 2 

=item $arguments->{perl_mode} - Boolean - Use Perl specific word regex and stopwords

=item $arguments->{stopwords_file} - Optional- Name of the file containing the stopwords to use (overridden by the perl option)

=item $arguments->{index_directory} - The location of the index database

=item $arguments->{use_position} - See L<Sear::Indexer> for a complete documentation

=item $arguments->{maximum_document_size} - Integer - Only files with size inferior to this limit will be added

=item $arguments->{verbose} - Boolean - Display the document id and score if set

=back

=item \@files - Files to be added in the index

=back

I<Returns> - Nothing

I<Exceptions> - None

=cut

my ($arguments, $files) = @_ ;

my @perl_extra_arguments  ;
@perl_extra_arguments = get_perl_word_regex_and_stopwords() if($arguments->{perl_mode}) ;

my @stopwords ;
@stopwords = (STOPWORDS => $arguments->{stopwords_file}) if($arguments->{stopwords_file}) ;

my $indexer 
	= Search::Indexer::Incremental::MD5::Indexer->new
		(
		INDEX_DIRECTORY => $arguments->{index_directory}, 
		USE_POSITIONS => $arguments->{use_position}, 
		WORD_REGEX => qr/\w+/smx,
		@stopwords,
		@perl_extra_arguments,
		) ;

$indexer->add_files
	(
	FILES => [sort @{$files}],
	MAXIMUM_DOCUMENT_SIZE => $arguments->{maximum_document_size},
	DONE_ONE_FILE_CALLBACK => 
		sub
		{
		my ($file, $description, $file_info) = @_ ;
		
		if($file_info->{STATE} == 0)
			{
			if($arguments->{verbose})
				{
				printf {* STDOUT} "'$file' [id:$file_info->{ID}] up to date %.3f s.\n", $file_info->{TIME} ;
				}
			}
		elsif($file_info->{STATE} == 1)
			{
			if($arguments->{verbose})
				{
				printf {* STDOUT} "'$file' [id:$file_info->{ID}] re-indexed in %.3f s.\n", $file_info->{TIME} ;
				}
			else
				{
				print {* STDOUT} "$file\n" ;
				}
			}
		elsif($file_info->{STATE} == 2)
			{
			if($arguments->{verbose})
				{
				printf {* STDOUT} "'$file' [id:$file_info->{ID}] new file %.3f s.\n", $file_info->{TIME} ;
				}
			else
				{
				print {* STDOUT} "$file\n" ;
				}
			}
		else
			{
			croak "Error: Unexpected file '$file' state!\n" ;
			}
		}
	) ;

return
}

#----------------------------------------------------------------------------------------------------------

sub remove_files
{

=head2 remove_files(\%arguments, \@files)

Remove the passed files from the index

I<Arguments>

=over 2 

=item $\%arguments -

=over 2 

=item $arguments->{perl_mode} - Boolean - Use Perl specific word regex and stopwords

=item $arguments->{stopwords_file} - Optional- Name of the file containing the stopwords to use (overridden by the perl option)

=item $arguments->{index_directory} - The location of the index database

=item $arguments->{use_position} - See L<Sear::Indexer> for a complete documentation

=item $arguments->{verbose} - Boolean - Display the document id and score if set

=back

=item \@files - Files to be removed

=back

I<Returns> - Nothing

I<Exceptions> - None

=cut

my ($arguments, $files) = @_ ;

my @perl_extra_arguments  ;
@perl_extra_arguments = get_perl_word_regex_and_stopwords() if($arguments->{perl_mode}) ;

my @stopwords ;
@stopwords = (STOPWORDS => $arguments->{stopwords_file}) if($arguments->{stopwords_file}) ;

my $indexer 
	= Search::Indexer::Incremental::MD5::Indexer->new
		(
		INDEX_DIRECTORY => $arguments->{index_directory}, 
		USE_POSITIONS => $arguments->{use_position}, 
		WORD_REGEX => qr/\w+/smx,
		@stopwords,
		@perl_extra_arguments,
		) ;

$indexer->remove_files
	(
	FILES => $files,
	DONE_ONE_FILE_CALLBACK => 
		sub
		{
		my ($file, $description, $file_info) = @_ ;

		if($file_info->{STATE} == 0)
			{
			if($arguments->{verbose})
				{
				printf {* STDOUT} "'$file' [id:$file_info->{ID}] removed in  %.3f s.\n", $file_info->{TIME} ;
				}
			else
				{
				print {* STDOUT} "$file\n" ;
				}
			}
		elsif($file_info->{STATE} == 1)
			{
			if($arguments->{verbose})
				{
				printf {* STDOUT} "'$file' not found in %.3f s.\n", $file_info->{TIME} ;
				}
			}
		else
			{
			croak "Error: Unexpected file '$file' state!\n" ;
			}
		}
	) ;
	
return ;
}

#----------------------------------------------------------------------------------------------------------

sub check_index
{

=head2 check_index(\%arguments)

check the files in the index

I<Arguments>

=over 2 

=item \%arguments -

=over 2 

=item $arguments->{perl_mode} - Boolean - Use Perl specific word regex and stopwords

=item $arguments->{stopwords_file} - Optional- Name of the file containing the stopwords to use (overridden by the perl option)

=item $arguments->{index_directory} - The location of the index database

=item $arguments->{use_position} - See L<Sear::Indexer> for a complete documentation

=item $arguments->{verbose} - Boolean - Display the document id and score if set

=back

=back

I<Returns> - Nothing

I<Exceptions> - None

=cut

my ($arguments) = @_ ;

my @perl_extra_arguments  ;
@perl_extra_arguments = get_perl_word_regex_and_stopwords() if($arguments->{perl_mode}) ;

my @stopwords ;
@stopwords = (STOPWORDS => $arguments->{stopwords_file}) if($arguments->{stopwords_file}) ;

my $indexer 
	= Search::Indexer::Incremental::MD5::Indexer->new
		(
		INDEX_DIRECTORY => $arguments->{index_directory}, 
		USE_POSITIONS => $arguments->{use_position}, 
		WORD_REGEX => qr/\w+/smx,
		@stopwords,
		@perl_extra_arguments,
		) ;

$indexer->check_indexed_files
	(
	DONE_ONE_FILE_CALLBACK => 
		sub
		{
		my ($file, $description,$file_info) = @_ ;

		if($file_info->{STATE} == 0)
			{
			if($arguments->{verbose})
				{
				printf {* STDOUT} "'$file' [id:$file_info->{ID}] found and identical in %.3f s.\n", $file_info->{TIME} ;
				}
			else
				{
				print {* STDOUT} "$file\n" ;
				}
			}
		elsif($file_info->{STATE} == 1)
			{
			if($arguments->{verbose})
				{
				printf {* STDOUT} "'$file' [id:$file_info->{ID}] file found, contents differ %.3f s.\n", $file_info->{TIME} ;
				}
			else
				{
				print {* STDOUT} "$file\n" ;
				}
			}
		elsif($file_info->{STATE} == 2)
			{
			if($arguments->{verbose})
				{
				printf {* STDOUT} "'$file' [id:$file_info->{ID}] not found in %.3f s.\n", $file_info->{TIME} ;
				}
			else
				{
				print {* STDOUT} "$file\n" ;
				}
			}
		else
			{
			croak "Error: Unexpected file '$file' state!\n" ;
			}
		}
	) ;

return ;
}

#----------------------------------------------------------------------------------------------------------

sub get_file_MD5
{

=head2 get_file_MD5($file)

Returns the MD5 of the I<$file> argument.

I<Arguments>

=over 2 

=item $file - The location of the file to compute an MD5 for

=back

I<Returns> - A string containing the file md5

I<Exceptions> - fails if the file can't be open

=cut

my ($file) = @_ ;
open(my $fh, '<', $file) or croak "Error: Can't open '$file' to compute MD5: $!";
binmode($fh);

my $md5 = Digest::MD5->new->addfile($fh)->hexdigest ;

close $fh or croak 'Error: Can not close file!' ;

return $md5 ;
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
