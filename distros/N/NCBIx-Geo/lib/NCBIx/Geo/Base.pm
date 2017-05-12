package NCBIx::Geo::Base;
use Class::Std;
use Class::Std::Utils;
use LWP::Simple;
use Data::Dumper;

use warnings;
use strict;
use Carp;

use version; our $VERSION = qv('1.0.0');

use constant GEO_FTP_URL  => 'ftp://ftp.ncbi.nih.gov/pub/geo/DATA/supplementary/samples/';
use constant GEO_ACC_URL  => 'http://www.ncbi.nlm.nih.gov/geo/query/acc.cgi?view=data&db=GeoDb_blob01&acc=';

{
        my %debug_of  :ATTR( :get<debug>   :set<debug>   :default<'0'>    :init_arg<debug> );
                
        sub START {
                my ($self, $ident, $arg_ref) = @_;

		if ( defined $arg_ref->{debug} ) { $self->set_debug( $arg_ref->{debug} ); }

                return;
        }

	sub debug { my ( $self ) = @_; return $self->get_debug(); }

	sub get_accn_type {
		my ( $self, $arg_ref ) = @_;

		my $accn     = defined $arg_ref->{accn} ? $arg_ref->{accn} : '';
		   $accn     =~ m/^(\w{3})/; 
		return $1;
	}

	sub get_sample_data {
		my ( $self, $arg_ref ) = @_;
		my $sample_accn        = defined $arg_ref->{accn} ? $arg_ref->{accn} : '';
		my @file_exts          = defined $arg_ref->{exts} ? @{ $arg_ref->{exts} } : ();

		# Calculate the NCBI GSM directory
		my $gsm_dir  = $sample_accn;
		   $gsm_dir  =~ s/.{3}$/nnn/;
		my $gsm_url  = GEO_FTP_URL . "$gsm_dir/$sample_accn/";

		# Get the raw data
		foreach my $ext ( @file_exts ) {
			if ( $ext eq 'TXT' ) { $ext = 'txt'; }

			# Calculate file_name and file_path_name
			my $file      = $sample_accn . '.' . $ext . '.gz';
			my $path_name = $self->get_data_dir() . $file;

			# Download if it doesn't exist
			if (! -s $path_name ) {
				my $url    = $gsm_url . $file;
				$self->_debug( "DOWNLOAD: $url" );
				my $result = get( $url );
				$self->_debug( "SAVE FILE: $path_name" );
				$self->_set_file_text({ file => $path_name, text => $result });
			} else {
				$self->_debug( "FILE EXISTS: $path_name" );
			}
		}	

		# Calculate call data file_name and file_path_name
		my $file      = $sample_accn . '.html';
		my $path_name = $self->get_data_dir() . $file;

		# Download call data if it doesn't exist
		if (! -s $path_name ) {
			my $acc_url = GEO_ACC_URL . $sample_accn;
			$self->_debug( "DOWNLOAD: $acc_url" );
			my $result  = get( $acc_url );
			$self->_debug( "SAVE FILE: $path_name" );
			$self->_set_file_text({ file => $path_name, text => $result });
		} else {
			$self->_debug( "FILE EXISTS: $path_name" );
		}
	}

	sub _set_file_text {
		my ( $self, $arg_ref ) = @_;
		my $file = defined $arg_ref->{file} ? $arg_ref->{file} : '';
		my $text = defined $arg_ref->{text} ? $arg_ref->{text} : '';

		if ( $file ) {
			open( OUTFILE, '>', $file );
			print OUTFILE $text;
			close( OUTFILE );
		}

                return;
        }

	sub _get_file_text {
		my ( $self, $arg_ref ) = @_;
		my $file = defined $arg_ref->{file} ? $arg_ref->{file} : '';
		$self->_debug( "INFILE: $file" );
		my $lines;

		if ( $file ) {
			open( INFILE, '<', $file );
			while ( my $line = <INFILE> ) { $lines .= $line; }
			close( INFILE );
		}

                return $lines;
        }

	sub _get_url {
		my ( $self, $url ) = @_;
		my $response;
		eval { $response = get( $url ); };
		if( $@ ) {
		  $self->warn("Can't query website: $@");
		  return;
		}
		$self->debug( "resp is $response\n"); 
		return $response;
	}

	sub _debug {
		my ( $self, $message ) = @_;
		if ( $self->debug() ) { print( $message . "\n" ); }
		return $self;
	}

	sub __exception {
		my ( $data ) = @_; 
		print "\n#######################################\n";
		print "# Exception                           #\n";
		print "#######################################\n";
		print Dumper( $data );
		print "#######################################\n\n";
	}
	
}

1; # Magic true value required at end of module
__END__

=head1 NAME

NCBIx::Geo::Base - Download and Compare Transcripts through NCBI GEO


=head1 VERSION

This document describes NCBIx::Geo::Base version 1.0.0


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
