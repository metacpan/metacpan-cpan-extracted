
package Search::Indexer::Incremental::MD5::Indexer ;

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

use List::Util      qw/max/;
use Time::HiRes     qw/time/;
use Search::Indexer 0.75;
use Search::Indexer::Incremental::MD5 ;
use BerkeleyDB;
use File::Slurp ;
use English qw( -no_match_vars ) ;

use Readonly ;
Readonly my $EMPTY_STRING => q{} ;

=head1 NAME

Search::Indexer::Incremental::MD5::Indexer - Incrementally index your files

=head1 SYNOPSIS

  use File::Find::Rule ;
  
  use Readonly ;
  Readonly my $DEFAUT_MAX_FILE_SIZE_INDEXING_THRESHOLD => 300 << 10 ; # 300KB
  
  my $indexer 
	= Search::Indexer::Incremental::MD5::Indexer->new
		(
		USE_POSITIONS => 1, 
		INDEX_DIRECTORY => 'text_index', 
		get_perl_word_regex_and_stop_words(),
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

Create a Search::Indexer::Incremental::MD5::Indexer object.  

  my $indexer = new Search::Indexer::Incremental::MD5::Indexer(%named_arguments) ;

I<Arguments> - %named_arguments

=over 2 

=item %named_arguments - 

=back

I<Returns> - A B<Search::Indexer::Incremental::MD5::Indexer> object

I<Exceptions> - 

=over 2 

=item * Incomplete argument list

=item * Error creating index directory

=item * Error creating index metadata database

=item * Error creating a Search::Indexer object

=back

=cut

my ($invocant, %arguments) = @_ ;

my $class = ref($invocant) || $invocant ;
confess 'Invalid constructor call!' unless defined $class ;

my $index_directory = $arguments{INDEX_DIRECTORY} or croak 'Error: index directory not defined!' ;
-d $index_directory or mkdir $index_directory or croak "Error: mkdir $index_directory: $!";

Readonly my $ID_TO_METADATA_FILE => 'id_to_docs_metadata.bdb' ;

# use id_to_docs_metadata.bdb, to store a lookup from the uniq id 
# to the document metadata {$doc_id => "$md5\t$path"}
tie my %id_to_metadata, 'BerkeleyDB::Hash',  ## no critic (Miscellanea::ProhibitTies)
	-Filename => "$index_directory/$ID_TO_METADATA_FILE", 
	-Flags    => DB_CREATE
		or croak "Error: opening '$index_directory/$ID_TO_METADATA_FILE': $^E $BerkeleyDB::Error";

# build a path  to document metadata lookup
my %path_to_metadata ;

while (my ($id, $document_metadata) = each %id_to_metadata) 
	{
	my ($md5, $path, $description) = split /\t/smx, $document_metadata ;
	
	$path_to_metadata{$path} = {id => $id, MD5 => $md5, DESCRIPTION => $description};
	}

return 
	bless 
		{
		INDEXER => new Search::Indexer
					(
					dir       => $arguments{INDEX_DIRECTORY} || q{.},
					writeMode => 1,
					positions => $arguments{USE_POSITIONS},
					wregex    => $arguments{WORD_REGEX} || qr/\w+/smx,
					stopwords => $arguments{STOPWORDS} || [],
					) ,

		INDEXED_FILES => {},
		ID_TO_METADATA => \%id_to_metadata,
		MAX_DOC_ID => max(keys %id_to_metadata),
		PATH_TO_METADATA => \%path_to_metadata,
		USE_POSITIONS => $arguments{USE_POSITIONS} , 
		INDEX_DIRECTORY => $arguments{INDEX_DIRECTORY}, 
		}, $class ;
}

#----------------------------------------------------------------------------------------------------------

Readonly my $STATE_ADD_UP_TO_DATE => 0 ;
Readonly my $STATE_ADD_RE_INDEX => 1 ;
Readonly my $STATE_ADD_NEW_FILE => 2 ;

sub add_files
{

=head2 add_files($self, %named_arguments)

Adds the contents of the files passed as arguments to the index database. Files already indexed are checked and
re-indexed only if their content has changed

I<Arguments> %named_arguments

=over 2 

=item FILES - Array reference - a list of files to add to the index. The file can either be a:

=over 2 

=item Scalar -  The name of the file  to indexed

=item  Hash reference - this is, for example,  useful when you want to index the contents of a tarball 

=over 2 

=item NAME -  The name of the file  to indexed

=item DESCRIPTION -  A user specific description string to be saved within the database

=back

=back

=item MAXIMUM_DOCUMENT_SIZE - Integer - a warning is displayed for document with greater size

=item DONE_ONE_FILE_CALLBACK - sub reference - called every time a file is handled

=over 2 

=item $file_name -  the name of the file re-indexed

=item $file_description -  user specific description of the name

=item $file_info -  Hash reference

=over 2 

=item * STATE - Boolean -  

=over 2 

=item 0 - up to date, no re-indexing necessary

=item 1 - file content changed since last index, re-indexed

=back

=item * ID - integer -  document id

=item * TIME - Float -  re_indexing time

=back

=back

=back

I<Returns> - Hash reference keyed on the file name

=over 2 

=item * STATE - Boolean -  

=over 2 

=item 0 - up to date, no re-indexing necessary

=item 1 - file content changed since last index, re-indexed

=item 2 - new file

=back

=item * ID - integer -  document id

=item * TIME - Float -  re-indexing time

=back

I<Exceptions>

=cut

my ($self, %arguments) = @_;

Readonly my $MAXIMUM_SIZE => (300 << 10) ;

my $files = $arguments{FILES} ;
my $maximum_document_size = $arguments{MAXIMUM_DOCUMENT_SIZE} ||  $MAXIMUM_SIZE ;
my $callback =  $arguments{DONE_ONE_FILE_CALLBACK} ;

my %file_information ;

for my $file (@{$files})
	{
	my ($name, $description) = ref $file eq $EMPTY_STRING ? ($file, $file) : ($file->{NAME}, $file->{DESCRIPTION}) ;
	
	if(-f $name) # index files only
		{
		if(-s $name < $maximum_document_size)
			{
			if(! exists $file_information{$name}) # only handle the file once
				{
				$file_information{$name} = $self->add_file($name, $description) ;
				$callback->($name, $description, $file_information{$name}) if $callback ;
				}
			}
		else
			{
			carp "'$name' is bigger than $maximum_document_size bytes, skipping!\n" ;
			}
		}
	else
		{
		carp "'$name' is not a file, skipping!\n" ;
		}
	}
	
return \%file_information ;
}

sub add_file
{

=head2 add_file($self, $name, $description)

I<Arguments> 

=over 2 

=item $self - 

=item $name -

=item $description

=back

I<Returns> - Hash reference containing

=over 2 

=item * STATE - Boolean -  

=over 2 

=item 0 - up to date, no re-indexing necessary

=item 1 - file content changed since last index, re-indexed

=item 2 - new file

=back

=item * ID - integer -  document id

=item * TIME - Float -  re-indexing time

=back

I<Exceptions>

=cut

my ($self, $name, $description) = @_ ;
$description = defined $description ? $description : $EMPTY_STRING;

my $t0 = time ;
my $file_md5 = Search::Indexer::Incremental::MD5::get_file_MD5($name) ;

my $old_id = $self->{PATH_TO_METADATA}{$name}{id};
my $new_id = ++$self->{MAX_DOC_ID};

my $file_information ;

if ($file_md5 eq ($self->{PATH_TO_METADATA}{$name}{MD5} || 'no_md5_for_the_file')) 
	{
	$file_information = {STATE => $STATE_ADD_UP_TO_DATE, TIME => (time - $t0), ID => $new_id} ;
	}
else
	{
	my $state = $STATE_ADD_NEW_FILE ;
	
	my $file_contents = read_file($name) ;

	if ($old_id)
		{
		$state = $STATE_ADD_RE_INDEX ;
		
		if($self->{USE_POSITIONS})
			{
			$self->remove_document_with_id($old_id)   ;
			}
		else
			{
			my $file_contents = read_file($name) ;
			$self->remove_document_with_id($old_id, $file_contents)   ;
			}
		}
		
	$self->{INDEXER}->add($new_id, $file_contents);
	
	$self->{ID_TO_METADATA}{$new_id} = "$file_md5\t$name\t$description" ;

	$file_information = {STATE => $state, TIME => (time - $t0), ID => $new_id} ;
	}

return $file_information ;
}

#----------------------------------------------------------------------------------------------------------

sub remove_files
{

=head2 remove_files(%named_arguments)

removes the contents of the files passed as arguments from the index database.

I<Arguments> %named_arguments

=over 2 

=item FILES  - Array reference - a list of files to remove from to the index

=item DONE_ONE_FILE_CALLBACK - sub reference - called every time a file is handled

=over 2 

=item $file_name -  the name of the file removed

=item $file_description -  description of the file

=item $file_info -  Hash reference

=over 2 

=item * STATE - Boolean -  

=over 2 

=item 0 - file not found

=item 1 - file found and removed

=back

=item * ID - integer -  document id

=item * TIME - Float -  removal time

=back

=back

=back

I<Returns> - Hash reference keyed on the file name

=over 2 

=item * STATE - Boolean -  

=over 2 

=item 0 - file found and removed

=item 1 - file not found

=back

=item * ID - integer -  document id

=item * TIME - Float -  re-indexing time

=back

I<Exceptions>

=cut

my ($self, %arguments) = @_;

my $files = $arguments{FILES} ;
my $callback =  $arguments{DONE_ONE_FILE_CALLBACK} ;

Readonly my $STATE_REMOVE_REMOVED => 0 ;
Readonly my $STATE_REMOVE_NOT_FOUND => 1 ;

my %file_information ;

FILE:
foreach my $file (grep {-f } @{$files}) # remove files only
	{
	next FILE if ($self->{INDEXED_FILES}{$file}++) ;
	
	my $t0 = time;

	my $old_id = $self->{PATH_TO_METADATA}{$file}{id} ;
	my $description = $self->{PATH_TO_METADATA}{$file}{DESCRIPTION} ;
	
	my $state = $STATE_REMOVE_NOT_FOUND ;
	
	if ($old_id)
		{
		$state = $STATE_REMOVE_REMOVED ;
		
		my $file_contents = $EMPTY_STRING ;
		$file_contents = read_file($file) if -e $file ;
		
		$self->remove_document_with_id($old_id, $file_contents) ;
		}
		
	$file_information{$file} = {STATE => $state, TIME => (time - $t0), ID => $old_id} ;
	$callback->($file, $description, $file_information{$file}) if $callback ;
	}
	
return \%file_information ;
}

#----------------------------------------------------------------------------------------------------------

sub remove_document_with_id
{

=head2 remove_document_with_id($id, $content)

removes the contents of the files passed as arguments 

I<Arguments> 

=over 2 

=item * $id - The id of the document to remove from the database

=item * $content - The contents of the document or I<undef>

=back

I<Returns> - Nothing

I<Exceptions> - None

=cut

my ($self, $id, $content) = @_ ;

if($self->{USE_POSITIONS})
	{
	$self->{INDEXER}->remove($id) ;
	}
else
	{
	$self->{INDEXER}->remove($id, $content || $EMPTY_STRING) ;
	}
	
delete $self->{ID_TO_METADATA}{$id} ;

return ;
}

#----------------------------------------------------------------------------------------------------------

sub check_indexed_files
{

=head2 check_indexed_files(%named_arguments)

Checks the index database contents.

I<Arguments> %named_arguments

=over 2 

=item DONE_ONE_FILE_CALLBACK - sub reference - called every time a file is handled

=over 2 

=item $file_name - the name of the file being checked

=item $description - description of the file

=item $file_info -  Hash reference containing

=over 2 

=item * STATE - Boolean -  

=over 2 

=item 0 - file found and identical

=item 1 - file found, content is different (needs re-indexing)

=item 2 - file not found

=back

=item * ID - integer -  document id

=item * TIME - Float -  check time

=back

=back

=back

I<Returns> - Hash reference keyed on the file name or nothing in void context

=over 2 

=item * STATE - Boolean -  

=over 2 

=item 0 - file found and identical

=item 1 - file found, content is different (needs re-indexing)

=item 2 - file not found

=back

=item * ID - integer -  document id

=item * TIME - Float -  check time

=back

I<Exceptions> - None

=cut

my ($self, %arguments) = @_;

my $callback =  $arguments{DONE_ONE_FILE_CALLBACK} ;

my %file_information ;

for my $file (sort keys %{$self->{PATH_TO_METADATA}})
	{
	my $t0 = time;
	my $id = $self->{PATH_TO_METADATA}{$file}{id} ;
	my $description = $self->{PATH_TO_METADATA}{$file}{DESCRIPTION} ;
	
	my $state = 2 ;

	if(-e $file)
		{
		$state = 1 ;
		
		my $file_md5 = Search::Indexer::Incremental::MD5::get_file_MD5($file) ;
		
		if($self->{PATH_TO_METADATA}{$file}{MD5} eq $file_md5)
			{
			$state = 0 ;
			}
		}
		
	$file_information{$file} = {STATE => $state, TIME => (time - $t0), ID => $id} ;
	$callback->($file, $description,$file_information{$file}) if $callback ;
	
	delete $file_information{$file} unless defined wantarray ;
	}
	
if(defined wantarray)
	{
	return \%file_information ;
	}
else
	{
	return ;
	}
}

#----------------------------------------------------------------------------------------------------------

sub remove_reference_to_unexisting_documents
{

=head2 remove_reference_to_unexisting_documents()

Checks the index database contents and remove any reference to  documents that don't exist.

I<Arguments> - None

I<Returns> - Array reference containing the named of the document that don't exist

I<Exceptions> - None

=cut

my ($self, %arguments) = @_;

my $callback =  $arguments{DONE_ONE_FILE_CALLBACK} ;

my @file_references_removed ;

my $t0 = time;

for my $file (keys %{$self->{PATH_TO_METADATA}})
	{
	unless(-e $file)
		{
		my $id = $self->{PATH_TO_METADATA}{$file}{id};
		
		$self->remove_document_with_id($id)   ;
		
		push @file_references_removed, $file ;
		}
	}
	
return \@file_references_removed;
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
