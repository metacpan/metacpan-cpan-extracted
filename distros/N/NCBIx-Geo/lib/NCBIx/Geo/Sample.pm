package NCBIx::Geo::Sample;
use base qw(NCBIx::Geo::Base);

use warnings;
use strict;
use Carp;

use version; our $VERSION = qv('1.0.0');

{
        my %accn_of          :ATTR( :get<accn>           :set<accn>           :default<''>  :init_arg<accn> );
        my %data_dir_of      :ATTR( :get<data_dir>       :set<data_dir>       :default<''>  :init_arg<data_dir> );
        my %transcripts_of   :ATTR( :get<transcripts>    :set<transcripts>    :default<''>  :init_arg<transcripts> );
                
        sub START {
                my ($self, $ident, $arg_ref) = @_;
        
		if ( defined $arg_ref->{accn} ) { $self->load_transcripts(); }

                return;
        }

        sub transcript_ids {
                my ( $self, $arg_ref ) = @_;
                return join( ';', keys %{ $self->get_transcripts() } );
        }

        sub value {
                my ( $self, $arg_ref ) = @_;
		my $transcript_id      = defined $arg_ref->{transcript_id} ? $arg_ref->{transcript_id} : '';
                return $self->get_transcripts()->{$transcript_id}->{value};
        }

        sub call {
                my ( $self, $arg_ref ) = @_;
		my $transcript_id      = defined $arg_ref->{transcript_id} ? $arg_ref->{transcript_id} : '';
                return $self->get_transcripts()->{$transcript_id}->{call};
        }

        sub p_value {
                my ( $self, $arg_ref ) = @_;
		my $transcript_id      = defined $arg_ref->{transcript_id} ? $arg_ref->{transcript_id} : '';
                return $self->get_transcripts()->{$transcript_id}->{p_value};
        }

        sub load_transcripts {
                my ( $self, $arg_ref ) = @_;
		my $sample_accn        = $self->get_accn();
		my $transcripts        = {};

		# Calculate call data file_name and file_path_name
		my $file      = $sample_accn . '.html';
		my $path_name = $self->get_data_dir() . $file;

		my $text      = $self->_get_file_text({ file => $path_name });
		   $text      =~ m#<pre>(.*)</pre>#six;
		   $text      = $1;
		my @lines     = split( /\n/, $text );

		foreach my $line ( @lines ) {
			if ( $line =~ m/^#/ ) { next; }
			if ( $line =~ m/^</ ) { next; }
			if ( $line =~ m/^$/ ) { next; }

			my ( $transcript_id, $value, $call, $p_value ) = split( /\t/, $line );
			$transcripts->{ $transcript_id } = { value => $value, call => $call, p_value => $p_value };
		}

		$self->set_transcripts( $transcripts );
        }

}

1; # Magic true value required at end of module
__END__

=head1 NAME

NCBIx::Geo::Sample - NCBI GEO Sample


=head1 VERSION

This document describes NCBIx::Geo::Sample version 1.0.0


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
