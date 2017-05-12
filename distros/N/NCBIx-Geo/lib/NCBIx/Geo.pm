package NCBIx::Geo;
use base qw(NCBIx::Geo::Base);
use NCBIx::Geo::Sample;
use NCBIx::Geo::Item;
use LWP::Simple;
use XML::Simple;

use warnings;
use strict;
use Carp;

use version; our $VERSION = qv('1.0.0');

use constant UTILS_URL    => 'http://www.ncbi.nlm.nih.gov/entrez/eutils/';

our $accn_types  = { GDS => 1, GPL => 1, GSE => 1, GSM => 1 };
our $db          = 'gds';
our $default_dir = '/tmp/geo/'; 
		
{
        my %query_of       :ATTR( :get<query>       :set<query>       :default<''>  :init_arg<query> );
        my %query_type_of  :ATTR( :get<query_type>  :set<query_type>  :default<''>  :init_arg<query_type> );
        my %geo_item_of    :ATTR( :get<geo_item>    :set<geo_item>    :default<''>  :init_arg<geo_item> );
        my %data_dir_of    :ATTR( :get<data_dir>    :set<data_dir>    :default<''>  :init_arg<data_dir> );

        my %platforms_of   :ATTR( :get<platforms>   :set<platforms>   :default<[]>  :init_arg<platforms> );
        my %data_sets_of   :ATTR( :get<data_sets>   :set<data_sets>   :default<[]>  :init_arg<data_sets> );
        my %series_of      :ATTR( :get<series>      :set<series>      :default<[]>  :init_arg<series> );
        my %samples_of     :ATTR( :get<samples>     :set<samples>     :default<[]>  :init_arg<samples> );
                
        my %platforms_count_of   :ATTR( :get<platforms_count>   :set<platforms_count>   :default<''>  :init_arg<platforms_count> );
        my %data_sets_count_of   :ATTR( :get<data_sets_count>   :set<data_sets_count>   :default<''>  :init_arg<data_sets_count> );
        my %series_count_of      :ATTR( :get<series_count>      :set<series_count>      :default<''>  :init_arg<series_count> );
        my %samples_count_of     :ATTR( :get<samples_count>     :set<samples_count>     :default<''>  :init_arg<samples_count> );
                
        sub START {
                my ($self, $ident, $arg_ref) = @_;

		# Check for valid data_dir
		if ( $self->get_data_dir() eq '' ) { 
			# Set default data_dir
			$self->set_data_dir( $default_dir ); 
		} else {
			# Check for ending slash
			my $data_dir = $self->get_data_dir(); 
			if (! $data_dir =~ m#/$# ) { $self->set_data_dir( $data_dir . '/' ); } 
		}

		# Make data_dir if it doesn't already exist
		if (! -s $self->get_data_dir() ) { mkdir( $self->get_data_dir() ); }

		# Load data if accn submitted
		if ( defined $arg_ref->{accn} ) { 
			# Get meta data
			$self->meta( $arg_ref ); 

			# Check if sample data requested immediately
			if ( defined $arg_ref->{data} ) { 
				if ( $arg_ref->{data} == 1 ) { $self->data(); }
			}
		}

                return;
        }

	sub desc          { 
		my ( $self )  = @_; 
		my $accn_type = $self->get_query_type();
		my $desc;

		if    ( $accn_type eq 'GPL' ) { $desc = $self->_describe_platform(); }
		elsif ( $accn_type eq 'GDS' ) { $desc = $self->_describe_data_set(); }
		elsif ( $accn_type eq 'GSE' ) { $desc = $self->_describe_series(); }
		elsif ( $accn_type eq 'GSM' ) { $desc = $self->_describe_sample(); }

		return $desc;
	}

	sub sample        { my ( $self, $arg_ref ) = @_; $arg_ref->{data_dir} = $self->get_data_dir(); $arg_ref->{debug} = $self->debug(); return NCBIx::Geo::Sample->new( $arg_ref ); } 

	sub meta {
		my ( $self, $arg_ref ) = @_;

		my $accn     = defined $arg_ref->{accn} ? $arg_ref->{accn} : '';
		$self->set_query( $accn );

		my $accn_type = $self->get_accn_type( $arg_ref );
		$self->set_query_type( $accn_type );

		my $file     = $self->get_doc({ accn => $accn });
		$self->parse_doc({ file => $file });

		return $self;
	}

	sub data {
		my ( $self ) = @_;

		# Limit to one data_set
		if ( $self->get_data_sets_count() == 1 ) { 
			# Foreach series
			my $series_list = $self->get_series();
			foreach my $series ( @$series_list ) {
				# Get the file types
				my @file_exts = split( /\s/, $series->get_supp_file() );
			
				# Get sample list
				my @sample_accns = split( /;/, $series->get_sample_ids() );
		
				# Process each sample accn
				foreach my $sample_accn ( @sample_accns ) {
					$self->get_sample_data({ accn => $sample_accn, exts => \@file_exts });
				}
			}
		} else {
			my $data_sets_count = $self->get_data_sets_count() ;
			$self->_debug( "\nNote: Too many data_sets found ($data_sets_count); no samples downloaded.\n      Use a GDS, GSE, or GSM accession to download data." );
		}

		return;
	}

	sub diff {
		my ( $self, $arg_ref ) = @_;
		my @list               = defined $arg_ref->{list} ? @{ $arg_ref->{list} } : ();
		$self->_debug( "DIFF: " . join( ', ', @list ) );
		my $left_accn          = shift( @list );
		my $left_sample        = $self->sample({ accn => $left_accn });
		my $left_transcripts   = $left_sample->get_transcripts();
		my @ids                = split( ';', $left_sample->transcript_ids() );
		my $results;

		foreach my $right_accn ( @list ) {
			my ( @left_present, @right_present );

			# Get the right transcripts
			my $right_sample      = $self->sample({ accn => $right_accn });
			my $right_transcripts = $right_sample->get_transcripts();

			# Compare each transcript_id
			foreach my $transcript_id ( @ids ) {
				my $ltran = $left_transcripts->{$transcript_id}->{call};
				my $rtran = $right_transcripts->{$transcript_id}->{call};

				if ( $ltran eq 'P' && $rtran eq 'A' ) { push @left_present, $transcript_id; }
				if ( $ltran eq 'A' && $rtran eq 'P' ) { push @right_present, $transcript_id; }
			}

			# Build diff results
			$results .= "<<$left_accn\n";
			$results .= join( ';', @left_present ) . "\n";
			$results .= ">>$right_accn\n";
			$results .= join( ';', @right_present ) . "\n";
		}

		return $results;
	}

	sub get_doc {
		my ( $self, $arg_ref ) = @_;
		my $accn               = defined $arg_ref->{accn} ? $arg_ref->{accn} : '';
		my $file               = $self->get_data_dir() . $accn . '.xml';

		# Download XML file if it doesn't exist
		if (! -s $file ) {
			my $query    = $accn . '[ACCN]';
			my $esearch  = UTILS_URL . 'esearch.fcgi?';
			   $esearch .= "db=$db&retmax=1&usehistory=y&term=";
			my $result   = get($esearch . $query);
			
			my ( $Count, $QueryKey, $WebEnv ) = $result =~ m|<Count>(\d+)</Count>.*<QueryKey>(\d+)</QueryKey>.*<WebEnv>(\S+)</WebEnv>|s;
	
			$self->_debug( "FOUND: $Count, $QueryKey, $WebEnv" );
			my $esummary  = UTILS_URL . 'esummary.fcgi?';
			   $esummary .= "db=$db&query_key=$QueryKey&WebEnv=$WebEnv";
			   $result    = get($esummary);
			
			open( OUTFILE, '>', $file );
			print OUTFILE $result;
			close( OUTFILE );
		}

		return $file;
	}

	sub parse_doc {
                my ( $self, $arg_ref ) = @_;
		my $file               = defined $arg_ref->{file} ? $arg_ref->{file} : '';
		$self->_debug( "PARSE EXISTING FILE: $file" );
		my $doc                = XMLin( $file );
		my @items;
		
		my $triggers = { SeriesTitle   => \&__parse_SeriesTitle,  
		                 n_samples     => \&__parse_n_samples,  
		                 gdsType       => \&__parse_gdsType,  
		                 ptechType     => \&__parse_ptechType,  
		                 Samples       => \&__parse_Samples,  
		                 Projects      => \&__parse_Projects,  
		                 GSE           => \&__parse_GSE,  
		                 summary       => \&__parse_summary,  
		                 GSM_titles_L  => \&__parse_GSM_titles_L,  
		                 PubMedIds     => \&__parse_PubMedIds,  
		                 Relations     => \&__parse_Relations,  
		                 GPL           => \&__parse_GPL,  
		                 SSInfo        => \&__parse_SSInfo,  
		                 suppFile      => \&__parse_suppFile,  
		                 taxon         => \&__parse_taxon,  
		                 GSM_L         => \&__parse_GSM_L,  
		                 entryType     => \&__parse_entryType,  
		                 valType       => \&__parse_valType,  
		                 PDAT          => \&__parse_PDAT,  
		                 PlatformTaxa  => \&__parse_PlatformTaxa,  
		                 SamplesTaxa   => \&__parse_SamplesTaxa,  
		                 GDS           => \&__parse_GDS,  
		                 subsetInfo    => \&__parse_subsetInfo,  
		                 title         => \&__parse_title,  
		                 PlatformTitle => \&__parse_PlatformTitle };
		
		my $item_list = $doc->{DocSum};
		my $count     = @$item_list;  $self->_debug( "Found $count items." );
		
		foreach my $item ( @$item_list ) {
			my $item_obj  = NCBIx::Geo::Item->new();
			my $attr_list = $item->{Item};
			foreach my $attr ( @$attr_list ) {
				&{ $triggers->{ $attr->{Name} } }( $item_obj, $attr );
			}

			my $item_type = $item_obj->get_entry_type();
			my $item_id;
			if    ( $item_type eq 'GPL' ) { $item_id = $item_obj->get_gpl(); }
			elsif ( $item_type eq 'GDS' ) { $item_id = $item_obj->get_gds(); }
			elsif ( $item_type eq 'GSE' ) { $item_id = $item_obj->get_gse(); }
			$self->_debug( "PARSE ITEM: $item_type$item_id" );

			my $test = $item_obj->check_sample_count();

			# Add the item
			my $accn_type = $item_obj->get_entry_type();
			$self->add_item({ $accn_type => $item_obj });

			push @items, $item_obj;
		}

		return @items;
		#return $self;
	}	

	sub add_item {
                my ( $self, $arg_ref ) = @_;
		my ( $item, @items );

		my $gpl = defined $arg_ref->{GPL} ? $arg_ref->{GPL} : '';
		my $gds = defined $arg_ref->{GDS} ? $arg_ref->{GDS} : '';
		my $gse = defined $arg_ref->{GSE} ? $arg_ref->{GSE} : '';
		my $gsm = defined $arg_ref->{GSM} ? $arg_ref->{GSM} : '';

		@items = ();

		if    ( $gpl ) { $item = $arg_ref->{GPL}; @items = @{ $self->get_platforms() }; }
		elsif ( $gds ) { $item = $arg_ref->{GDS}; @items = @{ $self->get_data_sets() }; }
		elsif ( $gse ) { $item = $arg_ref->{GSE}; @items = @{ $self->get_series() }; }
		elsif ( $gsm ) { $item = $arg_ref->{GSM}; @items = @{ $self->get_samples() }; }

		push @items, $item;

		if    ( $gpl ) { $self->set_platforms( \@items ); $self->set_platforms_count( scalar( @items ) ); }
		elsif ( $gds ) { $self->set_data_sets( \@items ); $self->set_data_sets_count( scalar( @items ) ); }
		elsif ( $gse ) { $self->set_series( \@items ); $self->set_series_count( scalar( @items ) ); }
		elsif ( $gsm ) { $self->set_samples( \@items ); $self->set_samples_count( scalar( @items ) ); }

		return $self;
	}	

	sub _describe_platform() {
		my ( $self ) = @_;
		my $accn     = $self->get_query();
		my $accn_id  = $accn;
		   $accn_id  =~ s/^.{3}//;
		my $desc;

		my $platforms = $self->get_platforms();
		foreach my $platform ( @$platforms ) {
			if ( $platform->get_gpl() eq  $accn_id ) {
				my $title          = $platform->get_title();
				my $summary        = $platform->get_summary();
				my $taxon          = $platform->get_taxon();
				my $ptech_type     = $platform->get_ptech_type();

				my @gds            = split( ';', $platform->get_gds() );
				my $data_set_count = scalar( @gds );

				my @gse            = split( ';', $platform->get_gse() );
				my $series_count   = scalar( @gse );

				$desc  = " Platform: $accn \n";
				$desc .= "    Title: $title \n";
				$desc .= "Tech Type: $ptech_type \n";
				$desc .= "    Taxon: $taxon \n";
				$desc .= " Datasets: $data_set_count \n";
				$desc .= "   Series: $series_count \n";
				$desc .= "  Summary: $summary \n";
				
				last;
			}
		}
		return "\n$desc\n";
	}
	
	sub _describe_data_set() {
		my ( $self ) = @_;
		my $accn     = $self->get_query();
		my $accn_id  = $accn;
		   $accn_id  =~ s/^.{3}//;
		my $desc;

		my $data_sets = $self->get_data_sets();
		foreach my $data_set ( @$data_sets ) {
			if ( $data_set->get_gds() eq  $accn_id ) {
				my $title          = $data_set->get_title();
				my $summary        = $data_set->get_summary();
				my $taxon          = $data_set->get_taxon();

				my @gse            = split( ';', $data_set->get_gse() );
				my $series_count   = scalar( @gse );

				my @gsm_ids        = split( ';', $data_set->get_gsm_l() );
				my @gsm_titles     = split( ';', $data_set->get_gsm_titles_l() );
				my $samples_count  = scalar( @gsm_ids );

				my @gpl            = split( ';', $data_set->get_gpl() );
				my $platform_count = scalar( @gpl );
				my ( $gpl_accn, $gpl_title );
				if ( $platform_count == 1 ) {
					$gpl_accn       = 'GPL' . $self->get_platforms()->[0]->get_gpl();
					$gpl_title      = $self->get_platforms()->[0]->get_title();
				}

				$desc  = " Data Set: $accn $title \n";
				$desc .= "    Taxon: $taxon \n";
				if ( $gpl_accn ) { $desc .= " Platform: $gpl_accn $gpl_title \n"; }
				$desc .= "GSE Count: $series_count \n";
				$desc .= "GSM Count: $samples_count \n";
				$desc .= "  Summary: $summary \n";

				# Show samples
				my @samples;
				foreach ( my $i = 0; $i < @gsm_ids; $i++ ) { 
					push @samples, "GSM$gsm_ids[$i] $gsm_titles[$i]";
				}
				$desc .= "\n  Samples: " . join( "\n           ", @samples ) . "\n";
				
				last;
			}
		}
		return "\n$desc\n";
	}
	
	sub _describe_series() {
		my ( $self ) = @_;
		my $accn     = $self->get_query();
		my $accn_id  = $accn;
		   $accn_id  =~ s/^.{3}//;
		my $desc;

		my $series_list = $self->get_series();
		foreach my $series ( @$series_list ) {
			if ( $series->get_gse() eq  $accn_id ) {
				my $title          = $series->get_title();
				my $summary        = $series->get_summary();
				my $taxon          = $series->get_taxon();

				my @gpl            = split( ';', $series->get_gpl() );
				my $platform_count = scalar( @gpl );
				my ( $gpl_accn, $gpl_title );
				if ( $platform_count == 1 ) {
					$gpl_accn       = 'GPL' . $self->get_platforms()->[0]->get_gpl();
					$gpl_title      = $self->get_platforms()->[0]->get_title();
				}

				my @gds            = split( ';', $series->get_gds() );
				my $data_set_count = scalar( @gds );
				my ( $gds_accn, $gds_title );
				if ( $data_set_count == 1 ) {
					$gds_accn       = 'GDS' . $self->get_data_sets()->[0]->get_gds();
					$gds_title      = $self->get_data_sets()->[0]->get_title();
				}

				my @gsm_ids        = split( ';', $series->get_gsm_l() );
				my @gsm_titles     = split( ';', $series->get_gsm_titles_l() );
				my $samples_count  = scalar( @gsm_ids );

				$desc  = "   Series: $accn $title \n";
				$desc .= "    Taxon: $taxon \n";
				if ( $gpl_accn ) { $desc .= " Platform: $gpl_accn $gpl_title \n"; }
				if ( $gds_accn ) { $desc .= " Data Set: $gds_accn $gds_title \n"; }
				$desc .= "GDS Count: $data_set_count \n";
				$desc .= "GSM Count: $samples_count \n";
				$desc .= "  Summary: $summary \n";

				# Show samples
				my @samples;
				foreach ( my $i = 0; $i < @gsm_ids; $i++ ) { 
					push @samples, "GSM$gsm_ids[$i] $gsm_titles[$i]";
				}
				$desc .= "\n  Samples: " . join( "\n           ", @samples ) . "\n";
				
				last;
			}
		}
		return "\n$desc\n";
	}
	
	sub _describe_sample() {
		my ( $self ) = @_;
		my $gsm_accn = $self->get_query();
		my $accn_id  = $gsm_accn;
		   $accn_id  =~ s/^.{3}//;
		my $desc;

		my $series_list = $self->get_series();
		foreach my $series ( @$series_list ) {
			if ( $series->get_gsm_l() =~  $accn_id ) {
				my @gsm_ids        = split( ';', $series->get_gsm_l() );
				my @gsm_titles     = split( ';', $series->get_gsm_titles_l() );

				my $gsm_title;
				for ( my $i = 0; $i < @gsm_ids; $i++ ) {
					if ( $gsm_ids[$i] eq $accn_id ) {
						$gsm_title = $gsm_titles[$i];
					}
				}

				my $gse_title      = $series->get_title();
				my $gse_accn       = 'GSE' . $series->get_gse();
				my $summary        = $series->get_summary();
				my $taxon          = $series->get_taxon();

				my $gpl_accn       = 'GPL' . $self->get_platforms()->[0]->get_gpl();
				my $gpl_title      = $self->get_platforms()->[0]->get_title();
				my $gds_accn       = 'GDS' . $self->get_data_sets()->[0]->get_gds();
				my $gds_title      = $self->get_data_sets()->[0]->get_title();

				$desc  = "   Sample: $gsm_accn $gsm_title \n";
				$desc .= "    Taxon: $taxon \n";
				$desc .= " Platform: $gpl_accn $gpl_title \n";
				$desc .= " Data Set: $gds_accn $gds_title \n";
				$desc .= "   Series: $gse_accn $gse_title \n";
				$desc .= "  Summary: $summary \n";
				
				last;
			}
		}
		return "\n$desc\n";
	}

	sub __parse_SeriesTitle {  
		my ( $item_obj, $data ) = @_;
		$item_obj->set_series_title( __parse_string( $data ) );
	}
	
	sub __parse_n_samples {  
		my ( $item_obj, $data ) = @_;
		$item_obj->set_n_samples( __parse_integer( $data ) );
	}
	
	sub __parse_gdsType {  
		my ( $item_obj, $data ) = @_;
		$item_obj->set_gds_type( __parse_string( $data ) );
	}
	
	sub __parse_ptechType {  
		my ( $item_obj, $data ) = @_;
		$item_obj->set_ptech_type( __parse_string( $data ) );
	}
	
	sub __parse_Samples {  
		my ( $item_obj, $data ) = @_;
		my @values;
		if ( defined $data->{Item} ) { 
			if ( $data->{Item} =~ m/ARRAY/ ) { 
				foreach my $item ( @{ $data->{Item} } ) {
					if ( $item->{Type} =~ m/Structure/ ) {
						my $attr_list = $item->{Item};
						my %attr;
						foreach my $attr ( @$attr_list ) {
							my $key   = $attr->{Name};
							my $value = $attr->{content};
							$attr{$key} = $value;
						}
						push @values, { Accession => $attr{Accession}, Title => $attr{Title} };
					} else {
						__exception( $data ); 
					}
				}
			} else { 
				__exception( $data ); 
			}
		}
		$item_obj->set_samples_count( scalar(@values) );
		$item_obj->set_samples( \@values );
	}
	
	sub __parse_Projects {  
		my ( $item_obj, $data ) = @_;
		$item_obj->set_projects( '' );  # Have yet to see an example with data
	}
	
	sub __parse_GSE {  
		my ( $item_obj, $data ) = @_;
		$item_obj->set_gse( __parse_string( $data ) );
	}
	
	sub __parse_summary {  
		my ( $item_obj, $data ) = @_;
		$item_obj->set_summary( __parse_string( $data ) );
	}
	
	sub __parse_GSM_titles_L {  
		my ( $item_obj, $data ) = @_;
		$item_obj->set_gsm_titles_l( __parse_string( $data ) );
	}
	
	sub __parse_PubMedIds {  
		my ( $item_obj, $data ) = @_;
		my @values;
		if ( defined $data->{Item} ) { 
			if ( $data->{Item} =~ m/ARRAY/ ) { 
				foreach my $item ( @{ $data->{Item} } ) {
					if ( defined $item->{content} ) { 
						push @values, $item->{content}; 
					}
				}
			} elsif ( $data->{Item} =~ m/HASH/ ) { 
				my $item = $data->{Item};
				if ( defined $item->{content} ) { 
					push @values, $item->{content}; 
				}
			} else { 
				__exception( $data ); 
			}
		}
		$item_obj->set_pubmed_ids( join( ';', @values ) );
	}
	
	sub __parse_Relations {  
		my ( $item_obj, $data ) = @_;
		$item_obj->set_relations( '' );  # Have yet to see an example with data
	}
	
	sub __parse_GPL {  
		my ( $item_obj, $data ) = @_;
		$item_obj->set_gpl( __parse_string( $data ) );
	}
	
	sub __parse_SSInfo {  
		my ( $item_obj, $data ) = @_;
		$item_obj->set_ss_info( __parse_string( $data ) );
	}
	
	sub __parse_suppFile {  
		my ( $item_obj, $data ) = @_;
		$item_obj->set_supp_file( __parse_string( $data ) );
	}
	
	sub __parse_taxon {  
		my ( $item_obj, $data ) = @_;
		$item_obj->set_taxon( __parse_string( $data ) );
	}
	
	sub __parse_GSM_L {  
		my ( $item_obj, $data ) = @_;
		$item_obj->set_gsm_l( __parse_string( $data ) );
	}
	
	sub __parse_entryType {  
		my ( $item_obj, $data ) = @_;
		$item_obj->set_entry_type( __parse_string( $data ) );
	}
	
	sub __parse_valType {  
		my ( $item_obj, $data ) = @_;
		$item_obj->set_val_type( __parse_string( $data ) );
	}
	
	sub __parse_PDAT {  
		my ( $item_obj, $data ) = @_;
		$item_obj->set_pdat( __parse_string( $data ) );
	}
	
	sub __parse_PlatformTaxa {  
		my ( $item_obj, $data ) = @_;
		$item_obj->set_platform_taxa( __parse_string( $data ) );
	}
	
	sub __parse_SamplesTaxa {  
		my ( $item_obj, $data ) = @_;
		$item_obj->set_samples_taxa( __parse_string( $data ) );
	}
	
	sub __parse_GDS {  
		my ( $item_obj, $data ) = @_;
		$item_obj->set_gds( __parse_string( $data ) );
	}
	
	sub __parse_subsetInfo {  
		my ( $item_obj, $data ) = @_;
		$item_obj->set_subset_info( __parse_string( $data ) );
	}
	
	sub __parse_title {  
		my ( $item_obj, $data ) = @_;
		$item_obj->set_title( __parse_string( $data ) );
	}
	
	sub __parse_PlatformTitle {
		my ( $item_obj, $data ) = @_;
		$item_obj->set_platform_title( __parse_string( $data ) );
	}
	
	sub __parse_string {
		my ( $data ) = @_; 
		my $value    = '';
		if ( $data->{Type} =~ m/String/ ) { 
			if ( defined $data->{content} ) { 
				$value = $data->{content}; 
			}
		} else { 
			__exception( $data ); 
		}
		return $value;
	}
	
	sub __parse_integer {
		my ( $data ) = @_; 
		my $value    = '';
		if ( $data->{Type} =~ m/Integer/ ) { 
			if ( defined $data->{content} ) { 
				$value = $data->{content}; 
			}
		} else { 
			__exception( $data ); 
		}
		return $value;
	}
	
}

1; # Magic true value required at end of module
__END__

=head1 NAME

NCBIx::Geo - Download and Compare Transcripts through NCBI GEO

=head1 VERSION

This document describes NCBIx::Geo version 1.0.0

=head1 SYNOPSIS

To use the script, first install it as described in README. Then check usage:

    geo -h

To get sample data related to a GDS, GSE, or GSM:

    geo -v -a <accn> -d <data_dir>

To compare transcripts:

    geo -v -a <accn> -c <accn> -d <data_dir>

If you use NCBIx::Geo in a custom perl script, you can access the 
individual values of each transcript. To use NCBIx::Geo in a custom perl script:

    use NCBIx::Geo;

    # Load meta-data and ensure that all sample data is downloaded
    my $geo = NCBIx::Geo->new({ accn => 'GDS1096', data_dir => '/home/roger/geo/data/', data => 1, debug => 1 });

    # Print the transcript_id diff between two or more samples
    print $geo->diff({ list => ['GSM44705', 'GSM44704'] });

    # Load meta-data first
    my $geo = NCBIx::Geo->new({ accn => 'GDS1096', data_dir => '/home/roger/geo/data/' });

    # Print a description and summary of the accession
    print $geo->desc();

    # Get all related sample data for accn if you haven't already
    $geo->data();

    # Long way around but flexible
    my $geo = NCBIx::Geo->new();
       $geo->meta({ accn => 'GDS1096' });
       $geo->data();

    # Get transcript values
    my $sample      = $geo->sample({ accn => 'GSM44705' });
    my @transcripts = @{ $sample->transcript_ids() };
    foreach my $transcript_id ( @transcripts ) {
    	print "\n$transcript_id =>\n";
    	print $sample->value({ transcript_id => $transcript_id }) . "\n";
    	print $sample->call({ transcript_id => $transcript_id }) . "\n";
    	print $sample->p_value({ transcript_id => $transcript_id }) . "\n";
    }

  
=head1 DESCRIPTION

NCBIx::Geo uses eUtils, the GEO acc.cgi script, and supplementary data via ftp 
to download, describe, and compare transcripts of gene abundance measurement.


=head1 CONFIGURATION AND ENVIRONMENT

The geo.pp script should be copied to an executable directory in your PATH 
environment variable. It should be renamed geo.

=head1 DEPENDENCIES

    Class::Std
    Class::Std::Utils
    LWP::Simple
    XML::Simple
    Data::Dumper
    Getopt::Long


=head1 INCOMPATIBILITIES

None reported.


=head1 BUGS AND LIMITATIONS

No bugs have been reported.

Please report any bugs or feature requests to
C<bug-ncbix-geo@rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org>.


=head1 AUTHOR

Roger A Hall  C<< <rogerhall@cpan.org> >>


=head1 LICENSE AND COPYRIGHT

Copyleft (c) 2010, Roger A Hall C<< <rogerhall@cpan.org> >>. All rights reserved.

This module is free software; you can redistribute it and/or
modify it under the same terms as Perl itself. See L<perlartistic>.


=head1 DISCLAIMER OF WARRANTY

BECAUSE THIS SOFTWARE IS LICENSED FREE OF CHARGE, THERE IS NO WARRANTY
FOR THE SOFTWARE, TO THE EXTENT PERMITTED BY APPLICABLE LAW. EXCEPT WHEN
OTHERWISE STATED IN WRITING THE COPYRIGHT HOLDERS AND/OR OTHER PARTIES
PROVIDE THE SOFTWARE "AS IS" WITHOUT WARRANTY OF ANY KIND, EITHER
EXPRESSED OR IMPLIED, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE. THE
ENTIRE RISK AS TO THE QUALITY AND PERFORMANCE OF THE SOFTWARE IS WITH
YOU. SHOULD THE SOFTWARE PROVE DEFECTIVE, YOU ASSUME THE COST OF ALL
NECESSARY SERVICING, REPAIR, OR CORRECTION.

IN NO EVENT UNLESS REQUIRED BY APPLICABLE LAW OR AGREED TO IN WRITING
WILL ANY COPYRIGHT HOLDER, OR ANY OTHER PARTY WHO MAY MODIFY AND/OR
REDISTRIBUTE THE SOFTWARE AS PERMITTED BY THE ABOVE LICENSE, BE
LIABLE TO YOU FOR DAMAGES, INCLUDING ANY GENERAL, SPECIAL, INCIDENTAL,
OR CONSEQUENTIAL DAMAGES ARISING OUT OF THE USE OR INABILITY TO USE
THE SOFTWARE (INCLUDING BUT NOT LIMITED TO LOSS OF DATA OR DATA BEING
RENDERED INACCURATE OR LOSSES SUSTAINED BY YOU OR THIRD PARTIES OR A
FAILURE OF THE SOFTWARE TO OPERATE WITH ANY OTHER SOFTWARE), EVEN IF
SUCH HOLDER OR OTHER PARTY HAS BEEN ADVISED OF THE POSSIBILITY OF
SUCH DAMAGES.


