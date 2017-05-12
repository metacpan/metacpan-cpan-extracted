package NCBIx::Geo::Item;
use base qw(NCBIx::Geo::Base);

use warnings;
use strict;
use Carp;

use version; our $VERSION = qv('1.0.0');

{

        my %series_title_of   :ATTR( :get<series_title>   :set<series_title>   :default<''>             :init_arg<series_title> );
        my %n_samples_of      :ATTR( :get<n_samples>      :set<n_samples>      :default<''>             :init_arg<n_samples> );
        my %gds_type_of       :ATTR( :get<gds_type>       :set<gds_type>       :default<''>             :init_arg<gds_type> );
        my %ptech_type_of     :ATTR( :get<ptech_type>     :set<ptech_type>     :default<''>             :init_arg<ptech_type> );
        my %samples_of        :ATTR( :get<samples>        :set<samples>        :default<''>             :init_arg<samples> );
        my %projects_of       :ATTR( :get<projects>       :set<projects>       :default<''>             :init_arg<projects> );
        my %gse_of            :ATTR( :get<gse>            :set<gse>            :default<''>             :init_arg<gse> );
        my %summary_of        :ATTR( :get<summary>        :set<summary>        :default<''>             :init_arg<summary> );
        my %gsm_titles_l_of   :ATTR( :get<gsm_titles_l>   :set<gsm_titles_l>   :default<''>             :init_arg<gsm_titles_l> );
        my %pubmed_ids_of     :ATTR( :get<pubmed_ids>     :set<pubmed_ids>     :default<''>             :init_arg<pubmed_ids> );
        my %relations_of      :ATTR( :get<relations>      :set<relations>      :default<''>             :init_arg<relations> );
        my %gpl_of            :ATTR( :get<gpl>            :set<gpl>            :default<''>             :init_arg<gpl> );
        my %ss_info_of        :ATTR( :get<ss_info>        :set<ss_info>        :default<''>             :init_arg<ss_info> );
        my %supp_file_of      :ATTR( :get<supp_file>      :set<supp_file>      :default<''>             :init_arg<supp_file> );
        my %taxon_of          :ATTR( :get<taxon>          :set<taxon>          :default<''>             :init_arg<taxon> );
        my %gsm_l_of          :ATTR( :get<gsm_l>          :set<gsm_l>          :default<''>             :init_arg<gsm_l> );
        my %entry_type_of     :ATTR( :get<entry_type>     :set<entry_type>     :default<''>             :init_arg<entry_type> );
        my %val_type_of       :ATTR( :get<val_type>       :set<val_type>       :default<''>             :init_arg<val_type> );
        my %pdat_of           :ATTR( :get<pdat>           :set<pdat>           :default<''>             :init_arg<pdat> );
        my %platform_taxa_of  :ATTR( :get<platform_taxa>  :set<platform_taxa>  :default<''>             :init_arg<platform_taxa> );
        my %samples_taxa_of   :ATTR( :get<samples_taxa>   :set<samples_taxa>   :default<''>             :init_arg<samples_taxa> );
        my %gds_of            :ATTR( :get<gds>            :set<gds>            :default<''>             :init_arg<gds> );
        my %subset_info_of    :ATTR( :get<subset_info>    :set<subset_info>    :default<''>             :init_arg<subset_info> );
        my %title_of          :ATTR( :get<title>          :set<title>          :default<''>             :init_arg<title> );
        my %platform_title_of :ATTR( :get<platform_title> :set<platform_title> :default<''>             :init_arg<platform_title> );

        my %related_gpl_of    :ATTR( :get<related_gpl>    :set<related_gpl>    :default<''>             :init_arg<related_gpl> );
        my %related_gds_of    :ATTR( :get<related_gds>    :set<related_gds>    :default<''>             :init_arg<related_gds> );
        my %related_gse_of    :ATTR( :get<related_gse>    :set<related_gse>    :default<''>             :init_arg<related_gse> );
        my %samples_count_of  :ATTR( :get<samples_count> :set<samples_count> :default<''>  :init_arg<samples_count> );
                
        sub START {
                my ($self, $ident, $arg_ref) = @_;
        

                return;
        }

	sub add_related {
		my ( $self, $item )       = @_;
		my $acc_type = $item->get_entry_type();
		if    ( $acc_type =~ m/GPL/ ) { $self->set_related_gpl( $item ); }
		elsif ( $acc_type =~ m/GDS/ ) { $self->set_related_gds( $item ); }
		elsif ( $acc_type =~ m/GSE/ ) { $self->set_related_gse( $item ); }
		return $self;
	}

	sub get_sample_ids {
		my ( $self )       = @_;
		my @sample_accns;
		foreach my $sample ( @{ $self->get_samples() } ) {
			push @sample_accns, $sample->{Accession};
		}
		return join( ';', @sample_accns );
	}

	sub get_sample_descs {
		my ( $self )       = @_;
		my @sample_accns;
		foreach my $sample ( @{ $self->get_samples() } ) {
			push @sample_accns, $sample->{Accession} . "\t" . $sample->{Title};
		}
		return join( "\n", @sample_accns ) . "\n";
	}

	sub desc {
		my ( $self )       = @_;
		my $entry_type     = $self->get_entry_type();
		my $gse            = $self->get_gse();
		my $gpl            = $self->get_gpl();
		my $gds            = $self->get_gds();

		my $desc  = "[$entry_type] GPL: $gpl \n";
		   $desc .= "[$entry_type] GDS: $gds \n";
		   $desc .= "[$entry_type] GSE: $gse \n\n";

                return $desc;
        }

	sub dump {
		my ( $self )       = @_;
		my $series_title   = $self->get_series_title();
		my $n_samples      = $self->get_n_samples();
		my $gds_type       = $self->get_gds_type();
		my $ptech_type     = $self->get_ptech_type();
		my $samples        = $self->get_samples();
		my $projects       = $self->get_projects();
		my $gse            = $self->get_gse();
		my $summary        = $self->get_summary();
		my $gsm_titles_l   = $self->get_gsm_titles_l();
		my $pubmed_ids     = $self->get_pubmed_ids();
		my $relations      = $self->get_relations();
		my $gpl            = $self->get_gpl();
		my $ss_info        = $self->get_ss_info();
		my $supp_file      = $self->get_supp_file();
		my $taxon          = $self->get_taxon();
		my $gsm_l          = $self->get_gsm_l();
		my $entry_type     = $self->get_entry_type();
		my $val_type       = $self->get_val_type();
		my $pdat           = $self->get_pdat();
		my $platform_taxa  = $self->get_platform_taxa();
		my $samples_taxa   = $self->get_samples_taxa();
		my $gds            = $self->get_gds();
		my $subset_info    = $self->get_subset_info();
		my $title          = $self->get_title();
		my $platform_title = $self->get_platform_title();
	
		print "  ITEM: $series_title, $n_samples, $gds_type, $ptech_type, $samples, $projects, $gse, $summary, $gsm_titles_l, $pubmed_ids, $relations, $gpl, $ss_info, $supp_file, $taxon, $gsm_l, $entry_type, $val_type, $pdat, $platform_taxa, $samples_taxa, $gds, $subset_info, $title, $platform_title \n";

                return;
        }

	sub check_sample_count {
		my ( $self )      = @_;
		my $n_samples     = $self->get_n_samples();
		my $samples_count = scalar( @{ $self->get_samples() } );

		if ( $n_samples || $samples_count ) { 
			if ( $n_samples != $samples_count ) { return 0; } 
		}

		return 1;
	}
	
}

1; # Magic true value required at end of module
__END__

=head1 NAME

NCBIx::Geo::Item - NCBI GEO XML ITEM


=head1 VERSION

This document describes NCBIx::Geo::Item version 1.0.0


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
