package NCBIx::BigFetch;
use warnings;
use strict;
use Class::Std;
use Class::Std::Utils;
use Carp;
use LWP::Simple;
use YAML qw(DumpFile LoadFile);
use Time::HiRes qw(usleep);

use version; our $VERSION = qv('0.5.6');

our $config_file   = 'efetch_N.yml';
our $esearch_file  = 'esearch_N.txt';
our $data_file     = 'sequences_N_M.txt';
our $sleep_policy  = 2_750_000;

{
	# These properties have defaults but can also be initialized by new()
	my %project_id_of         :ATTR( :get<project_id> :set<project_id> );
	my %base_url_of           :ATTR( :get<base_url> :set<base_url> );
	my %base_dir_of           :ATTR( :get<base_dir> :set<base_dir> );
	my %db_of                 :ATTR( :get<db> :set<db> );
	my %query_of              :ATTR( :get<query> :set<query> );
	my %index_of              :ATTR( :get<index> :set<index> );
	my %return_max_of         :ATTR( :get<return_max> :set<return_max> );
	my %return_type_of        :ATTR( :get<return_type> :set<return_type> );
	my %return_mode_of        :ATTR( :get<return_mode> :set<return_mode> );
	my %missing_of            :ATTR( :get<missing> :set<missing> );

	# These properties are set by the code
	my %start_date_of         :ATTR( :get<start_date> :set<start_date> );
	my %start_time_of         :ATTR( :get<start_time> :set<start_time> );
	my %querykey_of           :ATTR( :get<querykey> :set<querykey> );
	my %webenv_of             :ATTR( :get<webenv> :set<webenv> );
	my %count_of              :ATTR( :get<count> :set<count> );

	sub next_index           { my ($self) = @_; my $ident = ident $self; $index_of{$ident} += $return_max_of{$ident}; $self->_save(); }

	sub get_config_filename  { my ($self)  = @_; my $project_id = $self->get_project_id(); $config_file =~ s/N/$project_id/; return $self->get_base_dir() . '/' . $config_file; } 
	sub get_esearch_filename { my ($self)  = @_; my $project_id = $self->get_project_id(); $esearch_file =~ s/N/$project_id/; return $self->get_base_dir() . '/' . $esearch_file; } 
	sub get_data_filename    { my ($self, $index)  = @_; my $project_id = $self->get_project_id(); $index = defined($index) ? $index : $self->get_index(); my $filename = $data_file; $filename =~ s/N/$project_id/g; $filename =~ s/M/$index/g; return $self->get_base_dir() . '/' . $filename; } 

	sub BUILD {      
		my ($self, $ident, $arg_ref) = @_;

		# Set environment
		$self->_init( $arg_ref );
	
		# Check for existing project
		if (-e $self->get_config_filename()) { 
			$self->_status("Loading existing project");

			# Get existing config
			$self->_load();
		} else {
			$self->_status("Starting new project");

			# Set start date and time
			$self->_set_date();
	
			# Submit search and parse results
			$self->_search();
	
			# Save config
			$self->_save( $arg_ref );
		}

		return;
	}

	sub file_test {
		my ( $self )   = @_;
		my $file_written;

		# Get the file names for the test (/home/username/e* or /root/e*)
		my $config_filename  = $self->get_config_filename();
		my $esearch_filename = $self->get_esearch_filename();

		# Remove exisitng files and count files written
		if (-e $config_filename )  { $file_written++; `rm $config_filename`; } 
		if (-e $esearch_filename ) { $file_written++; `rm $esearch_filename`; } 

		return $file_written;
	}

	sub results_waiting {
		my ( $self )   = @_;
		if ( $self->get_index() < $self->get_count() ) { 
			return 1; 
		} else { 
			$self->_status("Found " . $self->_commify( scalar(@{ $self->get_missing() }) ) . " missing batches." );
			return 0; 
		}
	}

	sub missing_batches {
		my ( $self )   = @_;
		if ( @{ $self->get_missing() } ) { return 1; } else { return 0; }
	}

	sub get_next_batch {
		my ( $self )   = @_;
		my $index      = $self->get_index();

		# Get the batch
		$self->get_batch( $index );

		# Update the index
		$self->next_index();

		return;
	}

	sub get_batch {
		my ( $self, $index )   = @_;
		my $return_max  = $self->get_return_max();
		my $return_type = $self->get_return_type();
		my $return_mode = $self->get_return_mode();

		$self->_status("Starting with index " . $self->_commify( $index ) );
		
		# Ethics requires we wait sleep_policy microseconds before retrieving
		$self->_sleep();
		
		# Define a batch through URL
		my $efetch_url  = $self->get_base_url() . 'efetch.fcgi?db=' . $self->get_db();
		   $efetch_url .= '&WebEnv=' . $self->get_webenv() . '&query_key=' . $self->get_querykey() . "&rettype=$return_type&retmode=$return_mode";
		   $efetch_url .= "&retstart=$index&retmax=$return_max";
		   $efetch_url .= '&tool=ncbix_bigfetch&email=roger@iosea.com';

		# Get the batch using LWP::Simple (get)
		my $results  = get($efetch_url);
		
		# Check results # TODO: capture expired WebEnv and restart query
		if ( $results =~ m/resource is temporarily unavailable/i ) { $self->note_missing_batch( $index ); }
		if ( $results =~ m/NCBI C\+\+ Exception/i )                { $self->note_missing_batch( $index ); }
		if ( $results eq '' )                                      { $self->note_missing_batch( $index ); }

		# Save the sequences
		$self->_set_file_text( $self->get_data_filename( $index ), $results );

		return;
	}

	sub get_missing_batch {
		my ( $self )   = @_;

		# Get the next missing batch index
		my @missing    = @{ $self->get_missing() };
		my $index      = shift @missing;

		# Update the missing batch list
		$self->set_missing( \@missing );

		# Get the batch
		$self->get_batch( $index );

		return;
	}

	sub note_missing_batch { 
		my ( $self, $index )    = @_; 
		my @missing;
		my $missing             = $self->get_missing();
		if ( defined $missing ) { 
			@missing = @{ $missing }; 
		} else { 
			@missing = (); 
		}
		push @missing, $index;
		$self->set_missing( \@missing );
		$self->_save();
	}

	sub get_sequence {
		my ( $self, $id )   = @_;
		my $return_type = $self->get_return_type();
		my $return_mode = $self->get_return_mode();

		$self->_status("Fetching sequence $id");
		
		# Ethics requires we wait sleep_policy microseconds before retrieving
		$self->_sleep();
		
		# Define a batch through URL
		my $efetch_url  = $self->get_base_url() . 'efetch.fcgi?db=' . $self->get_db();
		   $efetch_url .= '&id=' . $id . "&rettype=$return_type&retmode=$return_mode";
		   $efetch_url .= '&tool=ncbix_bigfetch&email=roger@iosea.com';

		# Get the sequence
		my $results  = get($efetch_url);
		
		# Save the sequences in missing file
		$self->_add_file_text( $self->get_data_filename( 0 ), $results );

		return;
	}

	sub unavailable_ids {
		my ( $self )     = @_;
		my $count        = $self->get_index();
		my $return_max   = $self->get_return_max();
		my $index        = 1;
		my @unavailables = ();

		while ( $index < $count ) {
			$self->_status("Checking " . $self->_commify( $index ) . " through " . $self->_commify( $index + $return_max - 1 ) );
		
			# Get the sequences
			my $text = $self->_get_file_text( $self->get_data_filename( $index ) );

			while ( $text =~ m/Error:\s(\d+)\sis\snot\savailable\sat\sthis\stime/g ) { push @unavailables, $1; }

			# Update the index
			$index += $return_max;
		}

		$self->_status("Found " . $self->_commify( scalar(@unavailables) ) . " unavailable ids." );

		return \@unavailables;
	}

	sub _init {
		my ( $self, $arg_ref ) = @_;

		my $project_id   = $arg_ref->{project_id}  ? $arg_ref->{project_id}  : "1";    
		my $base_url     = $arg_ref->{base_url}    ? $arg_ref->{base_url}    : "http://eutils.ncbi.nlm.nih.gov/entrez/eutils/";    
		my $base_dir     = $arg_ref->{base_dir}    ? $arg_ref->{base_dir}    : $self->_get_base_dir();    
		my $db           = $arg_ref->{db}          ? $arg_ref->{db}          : "protein";    
		my $query        = $arg_ref->{query}       ? $arg_ref->{query}       : "apoptosis";    
		my $index        = $arg_ref->{index}       ? $arg_ref->{index}       : "1";    
		my $return_max   = $arg_ref->{return_max}  ? $arg_ref->{return_max}  : "500";    
		my $return_type  = $arg_ref->{return_type} ? $arg_ref->{return_type} : "fasta";	
		my $return_mode  = $arg_ref->{return_mode} ? $arg_ref->{return_mode} : "text";	
		my $missing      = $arg_ref->{missing}     ? $arg_ref->{missing}     : [];

		$self->set_project_id( $project_id );
		$self->set_base_url( $base_url );
		$self->set_base_dir( $base_dir );
		$self->set_db( $db );
		$self->set_query( $query );
		$self->set_index( $index );
		$self->set_return_max( $return_max );
		$self->set_return_type( $return_type );
		$self->set_return_mode( $return_mode );
		$self->set_missing( $missing );

		return;
	}

	sub _set_date {
		my ( $self ) = @_;

		my @time  = localtime;
		my $year  = 1900 + $time[5];
		my $month = $time[4] + 1; $month =~ s/^(\d)$/0$1/;
		my $day   = $time[3];     $day   =~ s/^(\d)$/0$1/;
		my $hour  = $time[2];     $hour  =~ s/^(\d)$/0$1/;
		my $min   = $time[1];     $min   =~ s/^(\d)$/0$1/;
		my $sec   = $time[0];     $sec   =~ s/^(\d)$/0$1/;
		
		$self->set_start_date( "$year-$month-$day" );
		$self->set_start_time( "$hour:$min:$sec" );

		return;
	}

	sub _search {
		#my ( $self, $arg_ref ) = @_;
		my ( $self, $arg_ref ) = @_;

		# Get search result ticket
		my $esearch_url          = $self->get_base_url() . 'esearch.fcgi?db=' . $self->get_db();
		   $esearch_url         .= '&term=' . $self->get_query() . '&usehistory=y';
		   $esearch_url         .= '&tool=ncbix_bigfetch&email=roger@iosea.com';
		my $esearch_result       = get($esearch_url);

		# Save search result
		$self->_set_file_text( $self->get_esearch_filename(), $esearch_result );
		
		# Parse the relevant keys
		$esearch_result =~ m/<Count>([0-9]*)<\/Count>/g;               $self->set_count( $1 );
		$esearch_result =~ m/<QueryKey>([0-9]*)<\/QueryKey>/g;         $self->set_querykey( $1 );
		$esearch_result =~ m/<WebEnv>([\.a-zA-Z0-9_@\-]*)<\/WebEnv>/g; $self->set_webenv( $1 );

		return;
	}

	sub _load {
		my ( $self ) = @_;
		my %config = %{ LoadFile( $self->get_config_filename() ) };
		$self->set_project_id( $config{project_id} );
		$self->set_base_url( $config{base_url} );
		$self->set_base_dir( $config{base_dir} );
		$self->set_db( $config{db} );
		$self->set_query( $config{query} );
		$self->set_querykey( $config{querykey} );
		$self->set_webenv( $config{webenv} );
		$self->set_count( $config{count} );
		$self->set_index( $config{index} );
		$self->set_start_date( $config{start_date} );
		$self->set_start_time( $config{start_time} );
		$self->set_return_max( $config{return_max} );
		$self->set_return_type( $config{return_type} );
		$self->set_return_mode( $config{return_mode} );
		$self->set_missing( $config{missing} );
	}

	sub _save {
		my ( $self, $arg_ref ) = @_;
		my $ident    = ident $self;
		my $config;

		if (defined $arg_ref) {
			$config = $arg_ref;
		} else {
			$config = {  project_id   => $project_id_of{$ident},
				     base_url     => $base_url_of{$ident},
				     base_dir     => $base_dir_of{$ident},
				     db           => $db_of{$ident},
				     query        => $query_of{$ident},
				     querykey     => $querykey_of{$ident},
				     webenv       => $webenv_of{$ident},
				     count        => $count_of{$ident},
				     index        => $index_of{$ident},
				     start_date   => $start_date_of{$ident},
				     start_time   => $start_time_of{$ident},
				     return_max   => $return_max_of{$ident},
				     return_type  => $return_type_of{$ident},
				     return_mode  => $return_mode_of{$ident},
				     missing      => $missing_of{$ident} };
		}
		DumpFile( $self->get_config_filename(), $config );
		return;
	}

	sub _get_base_dir {
		my ( $self, $base_dir ) = @_;
		chomp( my $id = `id -nu`);
		if ($id eq 'root') { $base_dir = '/root'; } else { $base_dir = '/home/' . $id; }
		return $base_dir;
	}

	sub _status {
		my ( $self, $msg ) = @_;
		print STDOUT "  STATUS: $msg \n";
		return;
	}

	sub _sleep {
		my ( $self ) = @_;
		usleep($sleep_policy);
		return;
	}

	sub _get_file_text {
		my ( $self, $path_file_name ) = @_;
		my ($text, $line);
		if (-e $path_file_name) {
			open  (my $IN, '<', $path_file_name) || croak( "Cannot open $path_file_name: $!" );
			while ($line = <$IN>) { $text .= $line; }
			close ($IN)                          || croak( "Cannot close $path_file_name: $!" );
		}
		return $text;
	}
	
	sub _set_file_text {
		my ( $self, $path_file_name, $text ) = @_;
		open  (my $OUT, '>', $path_file_name)        || croak( "Cannot open $path_file_name: $!" );
		print $OUT $text                             || croak( "Cannot write $path_file_name: $!" );
		close ($OUT)                                 || croak( "Cannot close $path_file_name: $!" );
	}
	
	sub _add_file_text {
		my ( $self, $path_file_name, $text ) = @_;
		open  (my $OUT, '>>', $path_file_name)       || croak( "Cannot open $path_file_name: $!" );
		print $OUT $text                             || croak( "Cannot write $path_file_name: $!" );
		close ($OUT)                                 || croak( "Cannot close $path_file_name: $!" );
	}

	sub _commify { # Perl Cookbook 2.17
		my ( $self, $string ) = @_;
		my $text = reverse $string;
		$text =~ s/(\d\d\d)(?=\d)(?!\d*\.)/$1,/g;
		return scalar reverse $text;
	}
	
	sub authors { return 'Roger Hall <roger@iosea.com>, Michael Bauer <mbkodos@gmail.org>, Kamakshi Duvvuru <kduvvuru@gmail.com>. Copyleft (C) 2009'; }
}

1; # Magic true value required at end of module
__END__

=head1 NAME

NCBIx::BigFetch - Robustly retrieve very large NCBI sequence result sets 
based on keyword searches using NCBI eUtils.

=head1 SYNOPSIS

  use NCBIx::BigFetch;
  
  # Parameters
  my $params = { project_id => "1", 
                 base_dir   => "/home/user/data", 
  	         db         => "protein",
  	         query      => "apoptosis",
                 return_max => "500" };
  
  # Start project
  my $project = NCBIx::BigFetch->new( $params );
  
  # Love the one you're with
  print " AUTHORS: " . $project->authors() . "\n";
  
  # Attempt all batches of sequences
  while ( $project->results_waiting() ) { $project->get_next_batch(); }
  
  # Get missing batches 
  while ( $project->missing_batches() ) { $project->get_missing_batch(); }
  
  # Find unavailable ids
  my $ids = $project->unavailable_ids();
  
  # Retrieve unavailable ids
  foreach my $id ( @$ids ) { $project->get_sequence( $id ); }

=head1 DESCRIPTION

NCBIx::BigFetch is useful for downloading very large result sets of sequences 
from NCBI given a text query. Its first use had over 
11,000,000 sequences as the result of a single keyword search. It uses YAML 
to create a configuration file to maintain project state in case network or 
server issues interrupts execution, in which case it may be easily restarted 
after the last batch. 

Downloaded data is organized by "project id" and "base directory" 
and saved in text files. Each file includes the project id in 
its name. The project_id and base_dir keys are the only required 
keys, although you will get the same search for "apoptosis" 
everytime unless you also set the "query" key. In any case, once 
a project is started, it only needs the two parameters to be 
reloaded.

Besides the data files, two other files are saved: 
1) the initial search result, which includes the WebEnv key, and 
2) a configuration file, which saves the parsed data and is used 
to pick-up the download and recover missing batches or sequences. 

Results are retrived in batches depending on the "return_max" key. 
By default, the "index" starts at 1 and downloads continue until 
the index exceedes "count".

Occasionally errors happen and entire batches are not downloaded. 
In this case, the "index" is added to the "missing" list. This 
list is saved in the configuration file. The missing batches should 
be downloaded every day, and not saved until the end of the complete 
run.

Working scripts are included in the script directory:

	fetch-all.pp
	fetch-missing.pp
	fetch-unavailable.pp

The recommended workflow is:

	1. Copy the scripts and edit them for a specific project. Use 
	   a new number as the project ID. 

	2. Begin downloading by running fetch-all.pp, which will first 
	   submit a query and save the resulting WebEnv key in a project 
	   specific configuration file (using YAML).

	3. The next morning, kill the fetch-all.pp process and run 
	   fetch-missing.pp until it completes.  

	4. Restart fetch-all.pp.  

If you wish to re-download "not available" sequences, you may run 
fetch-unavailable.pp. However, they will be downloaded at the end of 
fetch-all.pp if it completes normally.

If your query result set is so large that your WebEnv times out, simply 
start a new project with that last index of the previous project, and 
it will pick up the result set from there (with a new WebEnv). (Planned 
upgrade will automagically start another search.)

Warning: You may lose a (very) few sequences if your download extends 
across multiple projects. However, our testing shows that the batches 
generated with the same query within a few days of each other are largely 
identical.

=head2 MAIN METHODS

These are the primary methods that implement the highest abilities 
of the module. They are the ones found in the included scripts.

=over 4

=item * new()

  my $project = NCBIx::BigFetch->new( $params );

The parameters hash reference should include the following minimum 
keys: project_id, base_dir, db, and query. 

=item * results_waiting()

  while ( $project->results_waiting() ) { ... }

This method is used to determine if all of the batches have been 
attempted. It compares the current index to the total count, and 
is TRUE if the index is less than the count.

=item * get_next_batch()

  $project->get_next_batch();

Attempts to retrieve the next batch of "retmax" sequences, starting 
with the current index, which is updated every time a batch is 
downloaded. When used as in the Synopsis above, the index is both 
kept in memory and updated in the configuration file. If the 
download is interrupted and restarted, the correct index will be 
used and no data will be lost.

=item * note_missing_batch()

  $project->note_missing_batch( $index );

Adds the batch index to the list of missing batches.

=item * missing_batches()

  while ( $project->missing_batches() ) { ... }

This method is used to determine if any batches have been noted 
as "missing". It measures the "missing" list (which is stored 
in the configuration file) and returns TRUE when at leat one batch 
is listed. The batches are listed by starting index, which 
together with the return_max setting is used to describe a batch.

=item * get_missing_batch()

  $project->get_missing_batch();

Warning: do not kill the script during this phase. 

Gets a single batch, using the first index on the "missing" list. 
The index is shifted off the list and then attempted, so if you 
break during this phase you may actually lose track of the batch.

Recovery: edit the configuration file and add the index back to the 
missing list. The index will be reported to STDOUT in the status 
message.

=item * get_batch()

  $project->get_batch( $index );

Gets a single batch using the index parameter. This routine may be 
called on its own, but it is intended to only be used by get_next_batch() 
and get_missing_batch().

=item * unavailable_ids()

  my $ids = $project->unavailable_ids();

Notice that this method depends on a loaded (or started) project. It 
reads through all data files and creates a list of individual 
sequences that were unavailable when a batch was reported. The list 
is returned as a perl list reference.

=item * authors()

  $project->authors();

Surely you can stand a few bytes of vanity for the price of free software! 
Actually, the email addresses are of the "lifetime" sort, so feel free 
to contact the authors with any questions or concerns.

=back

=head2 ADDITIONAL METHODS

These methods are not meant to be used in a stand alone fashion, but 
if they did, it would look like this.

=over 4

=item * get_sequence()

  $project->get_sequence( $id );

Notice that this method depends on a loaded (or started) project. It 
retrieves the sequence by id and saves it to a special data file 
which uses "0" as an index. All unavailable sequences retrieved 
this way are saved to this file, so it could potentially be larger 
than the rest.

  use NCBIx::BigFetch;
  
  my $id = 'AC123456';  # Get this however you want

  # Parameters
  my $params = { project_id => "1", 
                 base_dir   => "/home/user/data" };
  
  # Start project
  my $project = NCBIx::BigFetch->new( $params );

  # Get sequence
  my $sequence = $project->get_sequence( $id );

  exit;

This method adds always adds the sequence to a special file with 
batch index of 0.

=item * next_index()

  $project->next_index();

Gets the next result index by adding the return_max value to the current index. The 
index is relative to the search results, and is the index of the first sequence in 
the returned batch (which serves as the batch id).

=item * data_filename()

  $project->data_filename();

Creates a filename for a given batch based on project_id and result index.

=item * esearch_filename()

  $project->esearch_filename();

Creates a filename for saving the intial search request.

=item * config_filename()

  $project->config_filename();

Creates a filename for the configuration file based on the project_id.

=back

=head2 PUBLIC PROPERTIES

All of the properties have get_/set_ methods courtesy of Class:Std and the :ATTR feature.

These properties have defaults but each may be overriden by passing 
them as keys in a hashref to new(). (See the variable $params in the SYNOPSIS above.)

=over 4

=item * project_id

The project_id is used to distinguish sets of data within a single data 
directory. It is part of each filename associated with the project. The 
default is "1". It is recommended that you always set project_id.

=item * base_dir

The base directory where project data will be saved. The default is 
/home/username. It is recommended that you always set base_dir.


=item * base_url

The base URL for NCBI eUtils. The default is 
"http://eutils.ncbi.nlm.nih.gov/entrez/eutils/".

=item * db

Gets the eSearch database setting. The default is "protein".

=item * index

Gets the current result index. The index is reset after every attempted batch by 
retmax amount. The default is "1".

=item * missing

Gets the list of missing batch indices. This property is stored as an arrayref. The default is "[]".

=item * query

Gets the query string used for eSearch. The default is "apoptosis".

=item * return_max

Gets the retmax setting used to limit the batch size. The default is "500".

=item * return_type

Gets the rettype setting used to determine the format 
of fetched sequences. The default is "fasta".

=item * return_mode

Gets the retmode setting used to determine the format 
of fetched sequences. The default is "text".

=back

=head2 PUBLIC PROPERTIES

These properties are set by the code.

=over 4

=item * querykey

The querykey property is parsed from the eSearch result. It 
is currently expected to always be be 1 (since only query 
is ever submitted by NCBIx::BigFetch).

=item * count

The count property is parsed from the eSearch result and 
represents the total number of results for the query.

=item * webenv

The WebEnv property is parsed from the eSearch result. It is used 
to build the eFetch URL for retrieving batches of 
sequences. It represens a pointer to the results, which are 
stored on NCBI's servers for a few days before being deleted.

=item * start_date

Calculates the start date for the project.

=item * start_time

Calculates the start time for the project.

=back

=head2 EXPORT

None

=head1 SEE ALSO

=over

=item * http://bioinformatics.ualr.edu/

=item * http://www.ncbi.nlm.nih.gov/entrez/query/static/efetch_help.html

=item * http://eutils.ncbi.nlm.nih.gov/entrez/query/static/efetchseq_help.html

=item * http://www.ncbi.nlm.nih.gov/entrez/query/static/eutils_example.pl

=back

=head1 AUTHORS

Feel free to email the authors with questions or concerns. Please be patient 
for a reply. 

=over

=item * Roger Hall (roger@iosea.com), (rahall2@ualr.edu)

=item * Michael Bauer (mbkodos@gmail.com), (mabauer@ualr.edu) 

=item * Kamakshi Duvvuru (kduvvuru@gmail.com) 

=back

=head1 COPYRIGHT AND LICENSE

Copyleft (C) 2009 by the Authors

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.5 or,
at your option, any later version of Perl 5 you may have available.

=cut
