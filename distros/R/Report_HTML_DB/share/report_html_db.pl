#!/usr/bin/perl 
# @File report_html_db.pl
# @Author Wendel Hime Lino Castro
# @Created Jul 19, 2016 10:45:01 AM
#

use strict;
use warnings;
use Getopt::Long;
use Data::Dumper;
use DB_File;
use utf8;
use open qw(:utf8);
use experimental 'smartmatch';

#
# ==> BEGIN OF AUTO GENERATED CODE (do not edit!!!)
#
# generateConfigRead.pl version 2.2
#
#
#begin of module configuration
my $print_conf = <<'CONF';
# Configuration parameters for component (see documentation for details)
# * lines starting with == indicate mandatory parameters, and must be changed to parameter=value
# * parameters containing predefined values indicate component defaults
==organism_name
==uniquename
==fasta_file
FT_artemis_selected_dir=
FT_submission_selected_dir=
GFF_dir=
GFF_selected_dir=
aa_fasta_dir=
nt_fasta_dir=
fasta_dir=
blast_dir=
rpsblast_dir=
hmmer_dir=
signalp_dir=
tmhmm_dir=
phobius_dir=
dgpi_dir=
predgpi_dir =
bigpi_dir =
interpro_dir=
eggnog_dir=
cog_dir=
kog_dir=
pathways_dir=
aa_orf_file=
nt_orf_file=
background_image_file=
index_file=
export_subgroup=yes
overwrite_output=yes
report_pathways_dir
report_eggnog_dir
report_cog_dir
report_kog_dir
alienhunter_output_file =
alienhunter_dir = 
infernal_output_file =
infernal_dir = 
rbs_dir =
rnammer_dir = 
transterm_dir = 
tcdb_dir = 
skews_dir =
trf_dir = 
trna_dir = 
string_dir = 
mreps_dir = 
report_go_dir = go_report_dir
go_file
TCDB_file=
==homepage_text_file
homepage_banner_image=
CONF

unless (@ARGV) {
    print $print_conf;
    exit;
}

use strict;
use EGeneUSP::SequenceObject;
use EGeneUSP::Config;
#
#get program version (assumnes CVS)
#
my $version = '$Revision$';
$version =~ s/.*?: ([\d.]+) \$/$1/;    #

#mandatory fields
#
my $organism_name;
my $fasta_file;
my $standard_dir;
#
#optional arguments and configuration defaults
#
#####

#my $FT_artemis_selected_dir="";
#my $FT_submission_selected_dir="";
#my $GFF_dir="";
#my $GFF_selected_dir="";
my $type_target_class_id = 0;
#my $pipeline             = 0;
my $aa_fasta_dir         = "";

my $nt_fasta_dir = "";

#my $xml_dir="xml_dir";
my $fasta_dir = "";

#my $blast_dir="";
#my $rpsblast_dir="";
#my $hmmer_dir="";
#my $signalp_dir="";
#my $tmhmm_dir="";
#my $phobius_dir="";
#my $dgpi_dir="";
#my $predgpi_dir = "";
#my $bigpi_dir = "";
#my $interpro_dir="";
#my $orthology_dir="";
#my $eggnog_dir;
#my $cog_dir;
#my $kog_dir;
#my $orthology_extension="";
#my $pathways_dir="";
my $aa_orf_file = "";

#my $nt_orf_file="";
#my $background_image_file="";
#my $index_file="";
#my $export_subgroup="yes";
#my $overwrite_output="yes";

my @reports_global_analyses = ();
my $report_feature_table_submission = "";
my $report_feature_table_artemis = "";
my $report_gff = "";

#my $report_cog_dir;
#my $report_kog_dir;
#componentes jota
my $alienhunter_output_file = "";
my $alienhunter_dir         = "";
my $infernal_output_file    = "";
my $infernal_dir            = "";

#my $rbs_output_file = "";
my $rbs_dir     = "";
my $rnammer_dir = "";

#my $transterm_output_file = "";
my $transterm_dir = "";
my $tcdb_dir      = "";
my $skews_dir     = "";
my $trf_dir       = "";
my $trna_dir      = "";
my $string_dir    = "";
my $mreps_dir     = "";

#my $report_csv_dir;
my $filepath_log = "";

#my $csv_file;
my $component_name_list;

#local variables
my @arguments;
my $config;
my $configFile;
my $missingArgument = 0;
my $conf;
my $databases_code;
my $databases_dir;
my $html_file;
my $banner;
my $titlePage;
my $color_primary;
my $color_accent;
my $color_primary_text;
my $color_accent_text;
my $color_menu;
my $color_background;
my $color_footer;
my $color_footer_text;
my $tcdb_file = "";
my $ko_file;
#my $uniquename;
my $annotation_dir;

my $homepage_image_organism;
my $filepath_assets;

#
#read configuration file
#

my $module = new EGeneUSP::Config($version);

$module->initialize();

$config = $module->config;
#
#check if any mandatory argument is missing
#
if (   !exists( $config->{"organism_name"} ) )
{
    $missingArgument = 1;
    print "Missing mandatory configuration argument:organism_name\n";
}
else { $organism_name = $config->{"organism_name"} }
if ( !exists( $config->{"fasta_file"} ) ) {
}
else { $fasta_file = $config->{"fasta_file"} }
if ($missingArgument) {
    die
    "\n\nCannot run $0, mandatory configuration argument missing (see above)\n";
}
#
#set optional arguments that were declared in configuration file
#
if ( defined( $config->{"std_dir"} ) ) {
    $standard_dir = $config->{"std_dir"};
}
if ( defined( $config->{"aa_fasta_dir"} ) ) {
    $aa_fasta_dir = $config->{"aa_fasta_dir"};
}

if ( defined( $config->{"nt_fasta_dir"} ) ) {
    $nt_fasta_dir = $config->{"nt_fasta_dir"};
}
if ( defined( $config->{"fasta_dir"} ) ) {
    $fasta_dir = $config->{"fasta_dir"};
}

=pod
if (defined($config->{"blast_dir"})){
   $blast_dir = $config->{"blast_dir"};
}
=cut

if ( defined( $config->{"aa_orf_file"} ) ) {
    $aa_orf_file = $config->{"aa_orf_file"};
}

#if (defined($config->{"nt_orf_file"})){
#   $nt_orf_file = $config->{"nt_orf_file"};
#}
if ( defined( $config->{"type_target_class_id"} ) ) {
    $type_target_class_id = $config->{"type_target_class_id"};
}
#if ( defined( $config->{"pipeline"} ) ) {
#	$pipeline = $config->{"pipeline"};
#}

#componentes do Jota
if ( defined( $config->{"alienhunter_output_file"} ) ) {
    $alienhunter_output_file = $config->{"alienhunter_output_file"};
}
if ( defined( $config->{"alienhunter_dir"} ) ) {
    $alienhunter_dir = $config->{"alienhunter_dir"};
}
if ( defined( $config->{"infernal_output_file"} ) ) {
    $infernal_output_file = $config->{"infernal_output_file"};
}
if ( defined( $config->{"infernal_dir"} ) ) {
    $infernal_dir = $config->{"infernal_dir"};
}
if ( defined( $config->{"rbs_dir"} ) ) {
    $rbs_dir = $config->{"rbs_dir"};
}
if ( defined( $config->{"rnammer_dir"} ) ) {
    $rnammer_dir = $config->{"rnammer_dir"};
}
if ( defined( $config->{"transterm_dir"} ) ) {
    $transterm_dir = $config->{"transterm_dir"};
}
if ( defined( $config->{"tcdb_dir"} ) ) {
    $tcdb_dir = $config->{"tcdb_dir"};
}
if ( defined( $config->{"skews_dir"} ) ) {
    $skews_dir = $config->{"skews_dir"};
}
if ( defined( $config->{"trf_dir"} ) ) {
    $trf_dir = $config->{"trf_dir"};
}

if ( defined( $config->{"trna_dir"} ) ) {
    $trna_dir = $config->{"trna_dir"};
}

if ( defined( $config->{"string_dir"} ) ) {
    $string_dir = $config->{"string_dir"};
}

if ( defined( $config->{"mreps_dir"} ) ) {
    $mreps_dir = $config->{"mreps_dir"};
}

if ( defined( $config->{"reports_global_analyses"} ) ) {
    @reports_global_analyses = split( ";", $config->{"reports_global_analyses"} );
}

if ( defined( $config->{"report_feature_table_submission_dir"} ) ) {
    $report_feature_table_submission = $config->{"report_feature_table_submission_dir"};
}
if ( defined( $config->{"report_feature_table_artemis_dir"} ) ) {
    $report_feature_table_artemis = $config->{"report_feature_table_artemis_dir"};
}
if ( defined( $config->{"report_gff_dir"} ) ) {
    $report_gff = $config->{"report_gff_dir"};
} 
if ( defined( $config->{"database_code_list"} ) ) {
    $databases_code = $config->{"database_code_list"};
}

if ( defined( $config->{"blast_dir_list"} ) ) {
    $databases_dir = $config->{"blast_dir_list"};
}
if ( defined( $config->{"homepage_text_file"} ) ) {
    $html_file = $config->{"homepage_text_file"};
}
if ( defined( $config->{"homepage_banner_image"} ) ) {
    $banner = $config->{"homepage_banner_image"};
}
if (defined( $config->{"homepage_title"} ) ) {
    $titlePage = $config->{"homepage_title"};
} 
if (defined( $config->{"color_primary"} ) ) {
    $color_primary = $config->{"color_primary"};
} 
if (defined( $config->{"color_accent"} ) ) {
    $color_accent = $config->{"color_accent"};
}
if (defined( $config->{"color_menu"} ) ) {
    $color_menu = $config->{"color_menu"};
}
if (defined( $config->{"color_primary_text"} ) ) {
    $color_primary_text = $config->{"color_primary_text"};
}
if (defined( $config->{"color_accent_text"} ) ) {
    $color_accent_text = $config->{"color_accent_text"};
}  
if (defined( $config->{"color_background"} ) ) {
    $color_background = $config->{"color_background"};
}  
if (defined( $config->{"color_footer"} ) ) {
    $color_footer = $config->{"color_footer"};
}  
if (defined( $config->{"color_footer_text"} ) ) {
    $color_footer_text = $config->{"color_footer_text"};
}  
if ( defined( $config->{"TCDB_file"} ) ) {
    $tcdb_file = $config->{"TCDB_file"};
}
if ( defined( $config->{"ko_file"} ) ) {
    $ko_file = $config->{"ko_file"};
}
#if ( defined( $config->{"uniquename"} ) ) {
#	$uniquename = $config->{"uniquename"};
#}
if ( defined( $config->{"filepath_log"} ) ) {
    $filepath_log = $config->{"filepath_log"};
}
if ( defined( $config->{"component_name_list"} ) ) {
    $component_name_list = $config->{"component_name_list"};
}
if ( defined( $config->{"annotation_dir"} ) ) {
    $annotation_dir = $config->{"annotation_dir"};
}

if ( defined( $config->{"homepage_image_organism"} ) ) {
    $homepage_image_organism = $config->{"homepage_image_organism"};
}
if ( defined( $config->{"filepath_assets"} ) ) {
    $filepath_assets = $config->{"filepath_assets"};
}

#
# ==> END OF AUTO GENERATED CODE
#

open( my $LOG, ">", $filepath_log );
###
#
#	Script SQL a ser rodado, necessário instancia nessa parte pois sera realizado concatenações após ler sequencias
#
###

my $scriptSQL = <<SQL;
CREATE TABLE TEXTS (
    id INTEGER PRIMARY KEY AUTOINCREMENT NOT NULL, 
    tag VARCHAR(200),
    value VARCHAR(2000),
    details VARCHAR(2000)
);

CREATE TABLE FILES (
    id INTEGER PRIMARY KEY AUTOINCREMENT NOT NULL,
    tag VARCHAR(200),
    filepath VARCHAR(2000),
    details VARCHAR(2000)
);

CREATE TABLE COMPONENTS(
    id INTEGER PRIMARY KEY AUTOINCREMENT NOT NULL,  
    name VARCHAR(2000),
    locus_tag VARCHAR(2000),
    component VARCHAR(2000),
    filepath VARCHAR(2000)
);

CREATE TABLE SEQUENCES(
    id INTEGER PRIMARY KEY NOT NULL,
    name VARCHAR(2000),
    filepath VARCHAR(2000)
);
BEGIN TRANSACTION;
INSERT INTO TEXTS(tag, value, details) VALUES
        ("menu", "home", "/"),
        ("menu", "blast", "/Blast"),
        ("menu", "search database", "/SearchDatabase"),
        ("menu", "global analyses", "/GlobalAnalyses"),
        ("menu", "downloads", "/Downloads"),
        ("menu", "help", "/Help"),
        ("menu", "about", "/About"),
        ("blast-form-title", "Choose program to use and database to search:", ""),
        ("blast-program-title", "Program:", "http://puma.icb.usp.br/blast/docs/blast_program.html"),
        ("blast-program-option", "blastn", ""),
        ("blast-program-option", "blastp", ""),
        ("blast-program-option", "blastx", ""),
        ("blast-program-option", "tblastn", ""),
        ("blast-program-option", "tblastx", ""),
        ("blast-database-title", "Database:", ""),
        ("blast-database-option", "All genes - nucleotide sequences", "PMN_genome_1"),
        ("blast-database-option", "Contigs - nucleotide sequences", "PMN_genes_1"),
        ("blast-database-option", "Protein sequences", "PMN_prot_1"),
        ("blast-format-title", "Enter sequence below in <a href='http://puma.icb.usp.br/blast/docs/fasta.html'>FASTA</a> format", ""),
        ("blast-sequence-file-title", "Or load it from disk ", ""),
        ("blast-subsequence-title", "Set subsequence ", ""),
        ("blast-subsequence-value", "From:", "QUERY_FROM"),
        ("blast-subsequence-value", "To:", "QUERY_TO"),
        ("blast-search-options-title", "Search options", ""),
        ("blast-search-options-sequence-title", "The query sequence is <a href='http://puma.icb.usp.br/blast/docs/filtered.html'>filtered</a> for low complexity regions by default.", ""),
        ("blast-search-options-filter-title", "Filter:", "http://puma.icb.usp.br/blast/docs/newoptions.html#filter"),
        ("blast-search-options-filter-options", "Low complexity", "value='L' checked=''"),
        ("blast-search-options-expect", "<a href='http://puma.icb.usp.br/blast/docs/newoptions.html#expect'>Expect</a> (e.g. 1e-6)", ""),
        ("blast-search-options-matrix", "Matrix", "http://puma.icb.usp.br/blast/docs/matrix_info.html"),
        ("blast-search-options-matrix-options", "BLOSUM62", "BLOSUM62"),
        ("blast-search-options-matrix-options", "BLOSUM45", "BLOSUM45"),
        ("blast-search-options-matrix-options", "BLOSUM50", "BLOSUM50"), 
        ("blast-search-options-matrix-options", "BLOSUM80", "BLOSUM80"),
        ("blast-search-options-matrix-options", "BLOSUM90", "BLOSUM90"), 
        ("blast-search-options-matrix-options", "PAM30", "PAM30"),
        ("blast-search-options-matrix-options", "PAM70", "PAM70"),
        ("blast-search-options-matrix-options", "PAM250", "PAM250"),
        ("blast-search-options-alignment", "Perform ungapped alignment", ""),
        ("blast-search-options-query", "Query Genetic Codes (blastx only)", "http://puma.icb.usp.br/blast/docs/newoptions.html#gencodes"),
        ("blast-search-options-query-options", "Standard (1)", "value='1'"),
        ("blast-search-options-query-options", "Vertebrate Mitochondrial (2)", "value='2'"),
        ("blast-search-options-query-options", "Yeast Mitochondrial (3)", "value='3'"),
        ("blast-search-options-query-options", "Mold Mitochondrial; ... (4)", "value='4'"),
        ("blast-search-options-query-options", "Invertebrate Mitochondrial (5)", "value='5'"),
        ("blast-search-options-query-options", "Ciliate Nuclear; ... (6)", "value='6'"),
        ("blast-search-options-query-options", "Echinoderm Mitochondrial (9)", "value='9'"),
        ("blast-search-options-query-options", "Euplotid Nuclear (10)", "value='10'"),
        ("blast-search-options-query-options", "Bacterial (11)", "value='11'"),
        ("blast-search-options-query-options", "Alternative Yeast Nuclear (12)", "value='12'"),
        ("blast-search-options-query-options", "Ascidian Mitochondrial (13)", "value='13'"),
        ("blast-search-options-query-options", "Alternative Flatworm Mitochondrial (14)", "value='14'"),
        ("blast-search-options-query-options", "Blepharisma Macronuclear (15)", "value='15'"),
        ("blast-search-options-query-options", "Chlorophycean Mitochondrial (16)", "value='16'"),
        ("blast-search-options-query-options", "Trematode Mitochondrial (21)", "value='21'"),
        ("blast-search-options-query-options", "Scenedesmus obliquus Mitochondrial (22)", "value='22'"),
        ("blast-search-options-query-options", "Thraustochytrium Mitochondrial (23)", "value='23'"),
        ("blast-search-options-query-options", "Pterobranchia Mitochondrial (24)", "value='24'"),
        ("blast-search-options-query-options", "Candidate Division SR1 and Gracilibacteria (25)", "value='25'"),
        ("blast-search-options-query-options", "Pachysolen tannophilus Nuclear (26)", "value='26'"),
        ("blast-search-options-database", "Database Genetic Codes (tblastn or tblastx only)", "http://puma.icb.usp.br/blast/docs/newoptions.html#gencodes"),
        ("blast-search-options-database-options", "Standard (1)", "value='1'"),
        ("blast-search-options-database-options", "Vertebrate Mitochondrial (2)", "value='2'"),
        ("blast-search-options-database-options", "Yeast Mitochondrial (3)", "value='3'"),
        ("blast-search-options-database-options", "Mold Mitochondrial; ... (4)", "value='4'"),
        ("blast-search-options-database-options", "Invertebrate Mitochondrial (5)", "value='5'"),
        ("blast-search-options-database-options", "Ciliate Nuclear; ... (6)", "value='6'"),
        ("blast-search-options-database-options", "Echinoderm Mitochondrial (9)", "value='9'"),
        ("blast-search-options-database-options", "Euplotid Nuclear (10)", "value='10'"),
        ("blast-search-options-database-options", "Bacterial (11)", "value='11'"),
        ("blast-search-options-database-options", "Alternative Yeast Nuclear (12)", "value='12'"),
        ("blast-search-options-database-options", "Ascidian Mitochondrial (13)", "value='13'"),
        ("blast-search-options-database-options", "Alternative Flatworm Mitochondrial (14)", "value='14'"),
        ("blast-search-options-database-options", "Blepharisma Macronuclear (15)", "value='15'"),
        ("blast-search-options-database-options", "Chlorophycean Mitochondrial (16)", "value='16'"),
        ("blast-search-options-database-options", "Trematode Mitochondrial (21)", "value='21'"),
        ("blast-search-options-database-options", "Scenedesmus obliquus Mitochondrial (22)", "value='22'"),
        ("blast-search-options-database-options", "Thraustochytrium Mitochondrial (23)", "value='23'"),
        ("blast-search-options-database-options", "Pterobranchia Mitochondrial (24)", "value='24'"),
        ("blast-search-options-database-options", "Candidate Division SR1 and Gracilibacteria (25)", "value='25'"),
        ("blast-search-options-database-options", "Pachysolen tannophilus Nuclear (26)", "value='26'"),
        ("blast-search-options-other-advanced-options", "Other advanced options:", "http://puma.icb.usp.br/blast/docs/full_options.html"),
        ("blast-display-options-title", "Display options", ""),
        ("blast-display-options-graphical-overview", "Graphical Overview", "http://puma.icb.usp.br/blast/docs/newoptions.html#graphical-overview"),
        ("blast-display-options-alignment-view-title", "Alignment view", "http://puma.icb.usp.br/blast/docs/options.html#alignmentviews"),
        ("blast-display-options-alignment-view-options", "Pairwise", "0"),
        ("blast-display-options-alignment-view-options", "query-anchored showing identities", "1"),
        ("blast-display-options-alignment-view-options", "query-anchored no identities", "2"),
        ("blast-display-options-alignment-view-options", "flat query-anchored, show identities", "3"),
        ("blast-display-options-alignment-view-options", "flat query-anchored, no identities", "4"),
        ("blast-display-options-alignment-view-options", "XML Blast output", "5"),
        ("blast-display-options-descriptions", "Descriptions", "http://puma.icb.usp.br/blast/docs/newoptions.html#descriptions"),
        ("blast-display-options-descriptions-options", "0", ""),
        ("blast-display-options-descriptions-options", "10", ""),
        ("blast-display-options-descriptions-options", "50", ""),
        ("blast-display-options-descriptions-options", "100", "selected"),
        ("blast-display-options-descriptions-options", "250", ""),
        ("blast-display-options-descriptions-options", "500", ""),
        ("blast-display-options-alignments", "Alignments", "http://puma.icb.usp.br/blast/docs/newoptions.html#alignments"),
        ("blast-display-options-alignments-options", "0", ""),
        ("blast-display-options-alignments-options", "10", ""),
        ("blast-display-options-alignments-options", "50", "selected"),
        ("blast-display-options-alignments-options", "100", ""),
        ("blast-display-options-alignments-options", "250", ""),
        ("blast-display-options-alignments-options", "500", ""),
        ("blast-button", "Clear sequence", "onclick=""this.form.reset();"" type=""button"" class='btn btn-default' "),
        ("blast-button", "Search", "type='submit' class='btn btn-primary' "),
        ("search-database-form-title", "Search based on sequences or annotations", ""),
        ("search-database-gene-ids-descriptions-title", "Gene IDs", ""),
    ("search-database-gene-ids-descriptions-tab", "<li class='active'><a href='#geneIdentifier' data-toggle='tab'>Gene identifier</a></li>", ""),
        ("search-database-gene-ids-descriptions-gene-id", "<label>Gene ID: </label>", ""),        
        ("search-database-analyses-protein-code-title", "Protein-coding genes", ""),
        ("search-database-analyses-protein-code-limit", "Limit by term(s) in gene description(optional): ", ""),
        ("search-database-analyses-protein-code-match-all", "Match all terms", ""),
        ("search-database-analyses-protein-code-excluding", "Excluding: ", ""),
        ("search-database-analyses-protein-code-tab", "<a href='#interpro' data-toggle='tab'>Interpro</a>", "#interpro"),


        ("search-database-analyses-protein-code-search-by-sequence", "Search by sequence identifier of match:", ""),
        ("search-database-analyses-protein-code-search-by-description", "Or by description of match:", ""),

        ("search-database-analyses-protein-code-not-containing-classification-rpsblast", " not containing RPS-BLAST matches", ""),

        ("search-database-dna-based-analyses-title", "DNA-based analyses", ""),
        ("search-database-dna-based-analyses-tab", "<a href='#contigs' data-toggle='tab'>Contigs</a>", "#contigs"),
        ("search-database-dna-based-analyses-only-contig-title", "Get only contig: ", ""),
        ("search-database-dna-based-analyses-from-base", " from base ", ""),
        ("search-database-dna-based-analyses-to", " to ", ""),
        ("search-database-dna-based-analyses-reverse-complement", " reverse complement?", "");

INSERT INTO TEXTS(tag, value, details) VALUES
        ("search-database-dna-based-analyses-tandem-repeats", "Get all tandem repeats that: ", ""),
        ("search-database-dna-based-analyses-contain-sequence-repetition-unit", "Contain the sequence in the repetition unit:", ""),
        ("search-database-dna-based-analyses-repetition-unit-bases", "Has repetition units of bases: ", ""),
        ("search-database-dna-based-analyses-occours-between", "Occurs between ", ""),
        ("search-database-dna-based-analyses-occours-between-and", "and", ""),
        ("search-database-dna-based-analyses-occours-between-and-times", "times", ""),
        ("search-database-dna-based-analyses-tandem-repeats-note", "NOTE: to get an exact number of repetitions, enter the same number in both boxes (numbers can have decimal places). Otherwise, to get 5 or more repetitions, enter 5 in the first box and nothing in the second; for 5 or less repetitions, enter 5 in the second box and nothing in the first. See the 'Help' section for further instructions.", ""),

        ("search-database-dna-based-analyses-footer", "Search categories in the DNA-based analyses are <b>not</b> additive, i.e. only the category whose ""Search"" button has been pressed will be searched.", ""),
        ("global-analyses-go-terms-mapping-footer", "NOTE: Please use Mozilla Firefox, Safari or Opera browser to visualize the expansible trees. If you are using Internet Explorer, please use the links to ""Table of ontologies"" to visualize the results.", ""),
        ("downloads-genes", "Genes", ""),
        ("downloads-other-sequences", "Other sequences", ""),

        ("help-table-contents", "Table of contents", ""),
        ("help-table-contents-1", "1. Introduction", "help_1"),                                                                                                                                
        ("help-table-contents-2", "2. BLAST", "help_2"),                                                                                                                                       
        ("help-table-contents-3", "3. Search database", "help_3"),                                                                                                                             
        ("help-table-contents-3-0", "3.0. Factors affecting database search speed", "help_3.0"),                                                                                                 
        ("help-table-contents-3-0-1", "3.0.1. Amount of results", "help_3.0.1"),                                                                                                                   
        ("help-table-contents-3-0-2", "3.0.2. Specificity of search", "help_3.0.2"),                                                                                                               
        ("help-table-contents-3-0-3", "3.0.3. Complexity of search", "help_3.0.3"),                                                                                                                
        ("help-table-contents-3-1", "3.1. Protein-coding gene IDs and descriptions", "help_3.1"),                                                                                                
        ("help-table-contents-3-1-1", "3.1.1. Gene identifier", "help_3.1.1"),                                                                                                                     
        ("help-table-contents-3-1-2", "3.1.2. Gene description", "help_3.1.2"),
        ("help-table-contents-3-2", "3.2. Analyses of protein-coding genes", "help_3.2"),
        ("help-table-contents-3-2-1", "3.2.1. Excluding criteria", "help_3.2.1"),
        ("help-table-contents-3-2-2", "3.2.2. Search criterion precedence", "help_3.2.2"),
        ("help-table-contents-3-2-3", "3.2.3. Filtering by description keyword(s)", "help_3.2.3"),
        ("help-table-contents-3-3", "3.3. DNA-based analyses", "help_3.3"),
        ("help-table-contents-3-3-1", "3.3.1. Contig sequences", "help_3.3.1"),
        ("help-table-contents-3-3-2", "3.3.2. Other analysis results", "help_3.3.2"),
        ("help-table-contents-4", "4. Global analyses", "help_4"),
        ("help-table-contents-4-1", "4.1. GO term mapping", "help_4.1"),
        ("help-table-contents-4-1-1", "4.1.1. Expansible trees", "help_4.1.1"),
        ("help-table-contents-4-1-2", "4.1.2. Table of ontologies", "help_4.1.2"),
        ("help-table-contents-4-2", "4.2. eggNOG - evolutionary genealogy of genes: Non-supervised Orthologous Groups", "help_4.2"),
        ("help-table-contents-4-3", "4.3. KEGG Pathways", "help_4.3"),
        ("help-table-contents-5", "5. Download", "help_5"),
        ("help-table-contents-5-1", "5.1. Annotation files", "help_5.1"),
        ("help-table-contents-5-2", "5.2. Nucleotide sequences", "help_5.2"),
        ("help-table-contents-5-3", "5.3. Aminoacid sequences", "help_5.3"),
        ("help-table-contents-5-4", "5.4. Other DNA sequences", "help_5.4"),
        ("help-table-contents-6", "6. Some known issues", "help_6"),
        ("help_1-0-paragraph", "This help page describes the data and services available at the <i>P. luminescens</i> MN7 site. Roche 454 sequencing data (shotgun and paired-end libraries) were assembled by Newbler v. 2.7 and assemblies were extended using GeneSeedHMM (an unpublished update of the <a href='http://www.coccidia.icb.usp.br/genseed/'>GenSeed</a> program) and manual verification. 
                                        The assembled contigs were then submitted to an EGene2 (an unpublished update of the <a href='http://www.coccidia.icb.usp.br/egene/'>EGene</a> platform) pipeline for comprehensive sequence annotation.
                                        The pipeline consisted in finding all protein-coding (using Glimmer3), transfer RNA (tRNAscan-SE), ribosomal RNA (RNAmmer), and other non-coding (Infernal + RFAM) genes. 
                                        Translated protein-coding gene sequences were then submitted to a number of analyses, namely sequence similarity (BLAST versus NR), protein domains (RPS-BLAST versus CDD), protein motifs (InterProScan versus all included databases), transmembrane domains and signal peptide (Phobius), and transporter classification (TCDB). 
                                        Using InterPro IDs, we mapped and quantified GO terms using a GO Slim file. <a href='http://eggnog.embl.de/version_3.0/'>eggNOG</a> orthology mapping and <a href='http://www.genome.jp/kegg/'>KEGG</a> pathway mapping were also performed with <a href='http://www.coccidia.icb.usp.br/egene/'>EGene2</a> components.
                                        Finally, DNA sequence-based analyses have also been performed, including searching for regions possibly originated from horizontal gene transfer (by AlienHunter), transcriptional terminators (TransTermHP), ribosomal binding sites (RBSfinder), and GC compositional skew (using an EGene2 component).", ""),
        ("help_1-1-paragraph", "The following sections describe how to:", ""),
        ("help_1-2-list-1", "perform BLAST searches on a number of sequences from <i>P. luminescens</i> MN7", ""),                                                                                                                         
        ("help_1-2-list-2", "search for genes based on their identifiers or product description", ""),                                                                                       
        ("help_1-2-list-3", "search for genes based on characteristics of their annotations", ""),                                                                                           
        ("help_1-2-list-4", "search for other", ""),                                                                                                                                         
        ("help_1-2-list-5", "download bulk data", ""),
        ("help_2-0-paragraph", "A BLAST service is available and searches can be performed against one of three <i>P. luminescens</i> MN7 databases: genomic DNA (contigs), predicted genes, or translated protein-coding genes. BLAST programs to be used are BLASTN, TBLASTN, or TBLASTX (for the first two databases) and BLASTP or BLASTX (for the third database).", ""),
        ("help_2-1-paragraph", "Our BLAST search page is mostly the same as the standard one formerly distributed with the legacy <i>www-blast</i> package, and is therefore familiar to most users. We have made small cosmetic adjustments, the most significant of which being the way in which the E-value cutoff (""Expect"" field in the page) can be entered. Our BLAST page allows for any E-value cutoff, while the original BLAST page contained a dropdown list with six different predetermined values. In our text box, any numeric value can be entered directly, using the syntax 1e-10 for E-values with an exponent.", ""),
        ("help_2-2-paragraph", "<font color='red'>[to be implemented]</font> Links to the GBrowse genome browser are included in the BLAST search results, both linking to the region matched (click on the link present after the match) and to the whole sequence where the match occurred (click on contig or gene name). Retrieval of results for longer sequences might take some time to complete.", ""),
        ("help_3-0-paragraph", "This page allows queries to the <i>P. luminescens</i> MN7 genome database, interrogating either gene identifiers, gene product descriptions, and results from all programs used by EGene2 to collect annotation evidence. It is also possible to retrieve contig sequences, or a user-specified subsubquence, with the option of reversing and complementing the sequence returned.", ""),
        ("help_3-1-paragraph", "Reflecting this variety of possible search strategies, the database search page is divided in three main sections. And each section is in turn divided in subsections, all of which are described in more detail below. But first, a word on search speed.", ""),
        ("help_3-2-title", "3.0. Factors affecting database search speed.", "help_3.0"),
        ("help_3-3-paragraph", "The PhotoBase database search capabilities are based on a <a href='http://gmod.org/wiki/Chado_-_Getting_Started'>Chado</a> database (<a href='http://www.ncbi.nlm.nih.gov/pubmed/17646315'>Mungall et al., 2007</a>), which is a generic and powerful database schema for biological sequence-related information. With generality and power, comes complexity. Therefore, some queries to the database can become quite large and slow, depending on a number of factors. While it is hard to accurately predict how long a query will take, we have observed a number of simple, general characteristics of a search that usually correlate to longer waiting times. The main such characteristics are:", ""),
        ("help_3-4-list-1", "Number of genes (or other records) returned by a query – the more genes, the longer the time", ""),
        ("help_3-4-list-2", "The specificity of the query – the more specific the query, the shorter the time", ""),
        ("help_3-4-list-3", "Complexity of the search – the more complex the query, the longer the time", ""),
        ("help_3-5-title", "3.0.1 Amount of results", "help_3.0.1"),
        ("help_3-6-paragraph", "The first factor, the approximate number of genes retrieved, might not always be knowable in advance. But many times it is possible to control. The most obvious example is a search for gene identifiers; a search for ""PMN_000"" will be much faster than one for ""PMN_"" – which will actually retrieve <b>all</b> genes and will take several minutes to complete. This is valid for comparably complex searches (see below).", ""),
        ("help_3-7-title", "3.0.2 Specifility of search", "help_3.0.2"),
        ("help_3-8-paragraph", "The second factor is somewhat related to the first, since more specific queries will be much more likely to return less genes than less specific ones. Therefore, searching for genes whose proteins have exactly 6 transmembrane domains predicted by Phobius, for example, will be usually faster than searching for those that have 6 or more TM domains. Another example, a search for a very common (i.e., less specific) description keyword will also return more genes and therefore take longer to complete than a search for a more rare and specific keyword.", ""),
        ("help_3-9-title", "3.0.3 Complexity of search", "help_3.0.2"),
        ("help_3-10-paragraph", "And finally, the complexity of the query also directly affects the time needed for a query to complete – the more complex the query, i.e the more criteria chosen to restrict the returned results, the longer the query will usually take to complete. That happens specially when performing searches in the ""Analyses of protein-coding genes"" section. Due to the way the database is structure, each criterion used in the search (e.g. KEGG, eggNOG, description, etc.) actually requires the equivalent of one database search, and then the different searches get combined to yield the final results. The search can be complex enough that it will take about a minute and return no genes at all, given how strict the requirements became – after all, only genes that meet all of them will be returned, and the likelihood of finding a gene diminishes with the more criteria chosen. As can be seen, this contradicts the first factor, since a search for less genes is taking longer.", ""),
        ("help_3-11-paragraph", "Therefore, when tuning searches, please take these factors into account when getting too many (or few) results, or when the search takes too long to complete. Also, try different combinations; given the complexity of the database and of the interactions between database tables, sometimes a more complex search can actually be faster than a less complex one. It is hard to know in advance when that will be the case, so testing the possibilities is the best practice when in doubt.", ""),
        ("help_3-12-title", "3.1 Protein-coding gene IDs and descriptions ", "help_3.1"),
        ("help_3-13-title", "3.1.1 Gene identifier ", "help_3.1.1"),
        ("help_3-14-paragraph", "If the user already knows the sequence ID, then the corresponding annotation can be directly retrieved from the <b>Gene identifier</b> section. For instance, PMN_0003 is a valid ID of a <i>P. luminescens</i> MN7 sequence. It is also possible to retrieve multiple genes by using partial identifiers. If one enters PMN_000 in the search field, for example, all genes whose identifiers start with PMM_000 will be retrieved, i.e genes PMN_0001 to PMN_0009.", ""),
        ("help_3-15-title", "3.1.2 Gene description ", "help_3.1.2"),
        ("help_3-16-paragraph", "In the next section, <b>Gene description</b>, the user can also enter one or more keywords to perform the search based on the text of each gene's product description. Entering more than one keyword will result in an OR-search, i.e the retrieved genes will contain one keyword, or the other, or the other (or more than one of them). For example, if the search was ""protease serine"", genes retrived could contain any or all of the terms ""protease"" and ""serine"" in their description. It is also possible to use partial words to match multiple terms. For example: searching for ""transp"" will match descriptions containing ""transporter"", ""transparent"", ""transport"", etc.", ""),
        ("help_3-17-paragraph", "The two boxes allow searches that require either presence (first box, labeled <i>""Description containing:""</i>) or absence (second box, labeled <i>""Excluding:""</i>) of terms in the description. Using only the first box retrieves genes containing the terms entered; using only the second one retrieves all genes that do not contain the term entered.", ""),
        ("help_3-18-paragraph", "Additionallly, the two boxes can be used in combination, performing an AND-search. As an example, the search could consist of entering ""protease"" in the first box and ""serine"" in the second one. In this case, the retrieved genes should contain ""protease"", but never ""serine"", in the description.", ""),
        ("help_3-19-title", "3.2 Analyses of protein-coding genes", "help_3.2"),
        ("help_3-20-paragraph", "In this section, it is possible to search the database of <i>P. luminescens</i> MN7 gene annotations using an enormous number of combinations. The different subsections can be combined in an AND-search, i.e. the retrieved genes will have to possess all characteristics specified in all the subsections filled. For example: specifying a KEGG pathway, a BLAST result containing the term ""kinase"", and a signal peptide (in Phobius) will retrieve only genes that belong to the pathway <b>and</b> have ""kinase"" in the BLAST hit description <b>and</b> had a signal peptide predicted by Phobius.", ""),
        ("help_3-21-paragraph", "As mentioned above, searches in this section are additive, which means that the criteria in all subsections chosen during a search must be met for a gene to be retrieved. To reflect this fact, there is only one ""Search"" button for the whole section, located at the bottom. So if a search specifies criteria for eggNOG, InterPro, and transporter classification analyses, for example, only genes that meet the eggNOG <b>and</b> InterPro <b>and</b> transporter classification requirements used will appear in the results table. As explained in <a href='#help_3.0'>3.0 Factors affecting database search speed</a> above, the more subsections are chosen here, the longer the query will take – and the lower the probability that any genes will be retrieved.", ""),
        ("help_3-22-title", "3.2.1 Excluding criteria", "help_3.2.1"),
        ("help_3-23-paragraph", "It is possible to restrict results to genes that do not possess annotations generated by a certain analyses, by checking the ""not containing *"" box at the top of the corresponding subsection. As an example: a search for all genes that matched kinases in a BLAST search but had no InterPro matches at all would be performed by entering ""kinase"" in the description field of the BLAST subsection, and checking the box labeled ""not containing InterProScan matches"" in the InterPro subsection.", ""),
        ("help_3-24-title", "3.2.2 Excluding criteria", "help_3.2.2"),
        ("help_3-25-paragraph", "In most of the subsections, some search criteria inside of the subsection take precedence over other. When that is the case, the criterion closer to the top has precedence over the ones below it that happened also have been filled with some value. To indicate such cases, the interface displays the alternative criteria with labels starting with ""Or"". When the criteria labels do not start with ""Or"", it means the different criteria will be applied simultaneously, in an AND-search.", ""),
        ("help_3-26-paragraph", "A couple of examples might make the behavior clearer. A search involving criteria related to transporter classification can restrict results by five different criteria, in order of greater to lesser precedence: transporter identifier; family; subclass; class; decription of match in the transporter database. Therefore, if the search specifies a transporter family (e.g. 1.A.3) and a class (3. Active primary transporters), the results will be constrained only by the first criterion chosen.", ""),
        ("help_3-27-paragraph", "Another example would be a search for genes with certain characteristics in their Phobius results, which can be filtered according to number of transmembrane domains predicted and/or status of signal peptide prediction. In this case, no criterion takes precedence over the other – if both are select, then both (and not just the top one) will be taken into account when performing the search.", ""),
        ("help_3-28-paragraph", "For instance, if one selects serine protease in all organisms, choosing the option “Find one of the query terms”, the database will report 365 sequences. Alternatively, if one chooses the option “Find all query terms”, the database will report 287 sequences found for the first term (serine) and 111 sequences for the second term (protease). Since not all products containing serine in their name are proteases (e.g. serine protein kinases), nor all proteases are serine proteases, the database will only report 33 sequences annotated as serine proteases.", ""),
        ("help_3-29-title", "3.2.3 Filtering by description keyword(s)", "help_3.2.3"),
        ("help_3-30-paragraph", "This capability is identical to the one described above in <a href='#help_3.1'>3.1. Protein-coding gene IDs and descriptions</a>, with the fundamental difference that it can be combined with the annotation subsections present after it, while the description keyword search of the ""Gene description"" subsection of the ""Protein-coding gene IDs and descriptions"" section can not.", ""),
        ("help_3-31-paragraph", "Accordingly, if these description keyword boxes are used but no filtering criteria are entered in the annotation subsections, search results will be identical to the same search had it been performed in the ""Gene descrition"" subsection.", ""),
        ("help_3-32-title", "3.3 DNA-based analyses", "help_3.3"),
        ("help_3-33-paragraph", "In this third and final main section of the database search page, it is possible to search for non-protein-coding genes, as well as other DNA-based analysis features from the genome of <i>P. luminescens</i> MN7. Differently from the section for protein-coding gene annotations, in this section searches are <b>not</b> additive; to reflect that, each subsection has its own ""Search"" button. Each subsection is thus independent from the others, and only the one whose ""Search"" button has been pressed will influence the generated results.", ""),
        ("help_3-34-title", "3.3.1 Contig sequences", "help_3.3.1"),
        ("help_3-35-paragraph", "This subsection can be use for the download of full or partial contig sequences, optionally generating the reverse-complement of the sequence. If the intent is to download all contigs without any modification, it is more efficient to go to the ""Downloads"" tab of PhotoBase and choose ""Get all contigs"", from the ""Other sequences"" section.", ""),
        ("help_3-36-paragraph", "The contig to be downloaded can be chosen by name in the dropdown list. Leaving the two text boxes empty will download the full contig sequence. Start and end positions for the sequence retrieved can specified in the boxes labeled ""from base"" and ""to"", and the sequence retrieved will be the reverse-complement of the original if the box ""reverse complement?"" is checked. Please notice that, when providing start and end positions for the sequence, <b>both</b> figures must be entered.", ""),
        ("help_3-37-title", "3.3.2 Other analysis results", "help_3.3.2"),
        ("help_3-38-paragraph", "The other subsections of the ""DNA-based analyses"" section behave in similar ways to the subsections already described for the ""Analyses of protein-coding genes"" section – with the already mentioned fundamental difference that searches are not additive, so one subsection knows nothing about the criteria specified by the other ones.", ""),
        ("help_3-39-paragraph", "Inside each subsection, criteria can be searched in an additive manner or not, depending on the subsection under consideration. As described above, non-additive searches contain criteria with labels starting with ""Or"", while additive searches do not.", ""),
        ("help_3-40-paragraph", "The ""tRNA"" subsection, for example, performs non-additive, OR-searches. Therefore, it is possible to search for tRNA genes based on amino acid encoded <b>or</b> codon in the gene, but not both simultaneously. The ""Tandem repeats"" subsection on the other hand has additive criteria: it is possible to filter by any of the three possible criteria, or any combination of them. One could then search for tandem repeats containing ""ATGGCT"" in the repeat unit, which also have repeat units of 10 bases (exactly, or more, or less), and which have between three and seven repetitions of the repeat unit.", ""),
        ("help_3-41-paragraph", "Notice that the two boxes for the minimum and maximum number of repetitions of the repeat unit can be used individually or in combination. If both boxes are used, the tandem repeat regions retrieved will have a number of repetitions that is equal to the number in the first box or more, but up to (and including) the number in the second. To get <b>all</b> regions with a certain number of repetitions or more without any upper boundary, the cutoff number should be entered in the first box, <i>leaving the second box empty</i>. Conversely, getting those that contain a number of repetitions or less can be done by filling only the second box.", ""),
        ("help_4-0-paragraph", "This section provides both qualitative and quantitative analyses for the whole set of translated products of <i>P. luminescens</i> MN7. Analyses include Gene Ontology (GO) term mapping, orthology functional classification using the eggNOG database, and pathway mapping using KEGG.", ""),
        ("help_4-1-title", "4.1 GO Term Mapping.", ""),
        ("help_4-2-paragraph", "We have mapped all GO terms found, and quantified the distribution of these terms using a GO Slim file. The results are presented in two different formats: expansible trees and tables. As detailed below, some Web browsers might have problems displaying the expansible tree, in which case the table format should be used.", ""),
        ("help_4-3-title", "4.1.1 Expansible Trees.", ""),
        ("help_4-4-paragraph", "Each expansible/collapsible tree is in fact composed of a set of three trees, each one corresponding to an ontology domain. By clicking on the left plus and minus signs, the branches can be expanded or collapsed, respectively. If the user clicks on the GO term itself, its <a href='http://amigo.geneontology.org'>Amigo</a> page is opened, showing the corresponding term description and other details. The links to the right of each GO term provide all sequences whose products have been mapped to this GO term. The list of sequences is then followed by links to the corresponding nucleotide and protein sequences. Also, links to GO terms display all GO terms mapped to the sequence. ", ""),
        ("help_4-5-paragraph", "Note: this format can only be used on Mozilla Firefox, Safari or Opera browsers, since the XML files are not compatible with MS Internet Explorer. For this latter browser we provide another data format, using conventional HTML tables (see below).", ""),
        ("help_4-6-title", "4.1.2 Table of ontologies.", ""),
        ("help_4-7-paragraph", "An alternative for MS Internet Explorer users to visualize the data is to click on the table of ontologies link. In this case, instead of a hierarchical tree, a typical HTML table will be displayed. The information content, however, is exactly the same as described above, but without the hierarchical view.", ""),
        ("help_4-8-title", "4.2. eggNOG - evolutionary genealogy of genes: Non-supervised Orthologous Groups. ", ""),
        ("help_4-9-paragraph", "We have mapped all predicted gene sequences onto the <a href='http://eggnog.embl.de/version_3.0/'>eggNOG v3.0</a> database, a comprehensive and enriched database of orthologous groups, constructed based on data from 1,133 organisms <a href='http://www.ncbi.nlm.nih.gov/pubmed/22096231'>(Powell et al., 2011)</a>. A table displays eggNOG functional categories and the respective numbers of sequences classified in each category. A pie chart also depicts the same information. By clicking on the one-letter code on the table, the user gets access to a page displaying a list of all proteins classified in that category. BLAST alignments and a link to the corresponding functional category information on the eggNOG site are also provided.", ""),
        ("help_4-10-title", "4.3 KEGG Pathways", ""),
        ("help_4-11-paragraph", "We mapped the translated protein sequences onto <a href='http://www.genome.jp/kegg/ko.html'>KEGG Orthology</a> <a href='http://www.ncbi.nlm.nih.gov/pubmed/18025687'>(Aoki-Kinoshita &amp; Kanehisa, 2007)</a> database. Using the identified <a href='http://www.genome.jp/kegg/ko.html'>KEGG Orthology</a> entries (KOs), we mapped the corresponding metabolic pathways. The <a href='http://www.genome.jp/kegg/pathway.html'>KEGG Pathway</a> classes are listed on a table and the respective sequence counts classified in each class are presented. A pie chart also depicts the <a href='http://www.genome.jp/kegg/'>KEGG</a> category distribution. By clicking on a <a href='http://www.genome.jp/kegg/pathway.html'>KEGG Pathway</a> Class link, an expanded list of subclasses is displayed. Each subclass presents the corresponding number of classified sequences and contains a link that opens up a page with the list of proteins (with links to BLAST alignments), Class Pathway IDs, KO descriptions, E.C. numbers and <a href='http://www.genome.jp/kegg/pathway.html'>KEGG pathways</a>. Each pathway link redirects to a page presenting a graphical representation of the corresponding pathway, as generated by <a href='http://www.genome.jp/kegg/'>KEGG</a>. The protein corresponding to the mapped query protein is displayed in a red-labeled box.", ""),
        ("help_5-0-paragraph", "In this section, the user can download annotation files, genes as nucleotide and (when appropriate) amino acid sequences, and other types of DNA sequences. ", ""),
        ("help_5-1-title", "5.1 Annotation files.", ""),
        ("help_5-2-paragraph", "Annotation files of <i>P. luminescens</i> MN7 are available for download in GenBank Feature Table and Extended Feature Table (Artemis-compatible) formats. Annotation data is provided in compressed zip files. Each file contains the complete annotation of the whole set of contigs, including genes of all types plus results from other analyses, e.g. transcriptional terminators, ribosomal binding sites, etc.", ""),
        ("help_5-3-title", "5.2 Nucleotide sequences.", ""),
        ("help_5-4-paragraph", "Nucleotide sequence data in FASTA format are available for download, separated in files for:", ""),
        ("help_5-5-list-1", "All genes (protein-coding, ribosomal RNA, transfer RNA, and non-coding RNA)", ""),
        ("help_5-5-list-2", "Protein-coding genes only", ""),
        ("help_5-5-list-3", "Ribosomal genes only", ""),
        ("help_5-5-list-4", "Transfer RNA genes only", ""),
        ("help_5-5-list-5", "Other ncRNA genes only", ""),
        ("help_5-6-title", "5.3 Aminoacid sequences.", ""),
        ("help_5-7-paragraph", "Translations of all protein-coding genes are available for download in one file.", ""),
        ("help_5-8-title", "5.4 Other DNA sequences.", ""),
        ("help_5-9-paragraph", "In this section,about.html the user can download files containing all <i>P. luminescens</i> MN7 sequences from a certain category:", ""),
        ("help_5-10-list-1", "All contigs", ""),
        ("help_5-10-list-2", "All intergenic regions", ""),
        ("help_5-10-list-3", "All regions identified as potential lateral transfers", ""),
        ("help_5-10-list-4", "All transcriptional terminators", ""),
        ("help_5-10-list-5", "All ribosomal binding sites", ""),
        ("help_6-0-paragraph", "Linking to GBrowse is still not implemented, therefore some links will currently not work.", ""),
        ("help_6-1-paragraph", "Some files still not present for download.", ""),
        ("help_6-2-paragraph", "To be added...", ""),
        ("result-warning-contigs", "Stretch not exist", "");

    INSERT INTO TEXTS(tag, value, details) VALUES
        ("search-database-analyses-protein-code-not-containing-classification-eggNOG", " not containing eggNOG matches", ""),
        ("search-database-analyses-protein-code-eggNOG", "Search by eggNOG identifier: ", "");

    INSERT INTO TEXTS(tag, value, details) VALUES
        ("search-database-analyses-protein-code-not-containing-classification-kegg", " not containing KEGG pathway matches", ""),
        ("search-database-analyses-protein-code-by-orthology-identifier-kegg", "Search by KEGG orthology identifier:", ""),
        ("search-database-analyses-protein-code-by-kegg-pathway", "Or by KEGG pathway:", ""),
        ("search-database-analyses-protein-code-not-containing-classification", " not containing Gene Ontology classification", ""),
        ("search-database-analyses-protein-code-not-containing-classification-interpro", " not containing InterProScan matches", ""),
        ("search-database-analyses-protein-code-interpro", "Search by InterPro identifier: ", ""),
        ("search-database-analyses-protein-code-not-containing-classification-blast", " not containing BLAST matches", ""),

        ("search-database-analyses-protein-code-number-transmembrane-domain", "Number of transmembrane domains: ", ""),
        ("search-database-quantity-tmhmmQuant", "<input type='radio' name='tmhmmQuant' value='orLess'> or less", ""),
        ("search-database-quantity-tmhmmQuant", "<input type='radio' name='tmhmmQuant' value='orMore'> or more", ""),
        ("search-database-quantity-tmhmmQuant", "<input type='radio' name='tmhmmQuant' value='exact'> exactly", ""),
        ("search-database-quantity-tmhmmQuant", "<input type='radio' name='tmhmmQuant' value='none'> none", ""),

    ("search-database-quantity-cleavageQuant", "<input type='radio' name='cleavageQuant' value='orLess'> or less", ""),
        ("search-database-quantity-cleavageQuant", "<input type='radio' name='cleavageQuant' value='orMore'> or more", ""),
        ("search-database-quantity-cleavageQuant", "<input type='radio' name='cleavageQuant' value='exact'> exactly", ""),
        ("search-database-quantity-cleavageQuant", "<input type='radio' name='cleavageQuant' value='none'> none", ""),

    ("search-database-quantity-scoreQuant", "<input type='radio' name='scoreQuant' value='orLess'> or less", ""),
        ("search-database-quantity-scoreQuant", "<input type='radio' name='scoreQuant' value='orMore'> or more", ""),
        ("search-database-quantity-scoreQuant", "<input type='radio' name='scoreQuant' value='exact'> exactly", ""),
        ("search-database-quantity-scoreQuant", "<input type='radio' name='scoreQuant' value='none'> none", ""),

    ("search-database-quantity-positionQuantPreDGPI", "<input type='radio' name='positionQuantPreDGPI' value='orLess'> or less", ""),
        ("search-database-quantity-positionQuantPreDGPI", "<input type='radio' name='positionQuantPreDGPI' value='orMore'> or more", ""),
        ("search-database-quantity-positionQuantPreDGPI", "<input type='radio' name='positionQuantPreDGPI' value='exact'> exactly", ""),
        ("search-database-quantity-positionQuantPreDGPI", "<input type='radio' name='positionQuantPreDGPI' value='none'> none", ""),

    ("search-database-quantity-specificityQuantPreDGPI", "<input type='radio' name='specificityQuantPreDGPI' value='orLess'> or less", ""),
        ("search-database-quantity-specificityQuantPreDGPI", "<input type='radio' name='specificityQuantPreDGPI' value='orMore'> or more", ""),
        ("search-database-quantity-specificityQuantPreDGPI", "<input type='radio' name='specificityQuantPreDGPI' value='exact'> exactly", ""),
        ("search-database-quantity-specificityQuantPreDGPI", "<input type='radio' name='specificityQuantPreDGPI' value='none'> none", ""),

    ("search-database-quantity-pvalueQuantBigpi", "<input type='radio' name='pvalueQuantBigpi' value='orLess'> or less", ""),
        ("search-database-quantity-pvalueQuantBigpi", "<input type='radio' name='pvalueQuantBigpi' value='orMore'> or more", ""),
        ("search-database-quantity-pvalueQuantBigpi", "<input type='radio' name='pvalueQuantBigpi' value='exact'> exactly", ""),
        ("search-database-quantity-pvalueQuantBigpi", "<input type='radio' name='pvalueQuantBigpi' value='none'> none", ""),

    ("search-database-quantity-positionQuantBigpi", "<input type='radio' name='positionQuantBigpi' value='orLess'> or less", ""),
        ("search-database-quantity-positionQuantBigpi", "<input type='radio' name='positionQuantBigpi' value='orMore'> or more", ""),
        ("search-database-quantity-positionQuantBigpi", "<input type='radio' name='positionQuantBigpi' value='exact'> exactly", ""),
        ("search-database-quantity-positionQuantBigpi", "<input type='radio' name='positionQuantBigpi' value='none'> none", ""),

        
    ("search-database-quantity-scoreQuantBigpi", "<input type='radio' name='scoreQuantBigpi' value='orLess'> or less", ""),
        ("search-database-quantity-scoreQuantBigpi", "<input type='radio' name='scoreQuantBigpi' value='orMore'> or more", ""),
        ("search-database-quantity-scoreQuantBigpi", "<input type='radio' name='scoreQuantBigpi' value='exact'> exactly", ""),
        ("search-database-quantity-scoreQuantBigpi", "<input type='radio' name='scoreQuantBigpi' value='none'> none", ""),

    ("search-database-quantity-tmQuant", "<input type='radio' name='tmQuant' value='orLess'> or less", ""),
        ("search-database-quantity-tmQuant", "<input type='radio' name='tmQuant' value='orMore'> or more", ""),
        ("search-database-quantity-tmQuant", "<input type='radio' name='tmQuant' value='exact'> exactly", ""),
        ("search-database-quantity-tmQuant", "<input type='radio' name='tmQuant' value='none'> none", ""),

    ("search-database-quantity-ncrna", "<input type='radio' name='ncRNAevM' value='orLess'> or less", ""),
        ("search-database-quantity-ncrna", "<input type='radio' name='ncRNAevM' value='orMore'> or more", ""),
        ("search-database-quantity-ncrna", "<input type='radio' name='ncRNAevM' value='exact'> exactly", ""),
        ("search-database-quantity-ncrna", "<input type='radio' name='ncRNAevM' value='none'> none", ""),

    ("search-database-quantity-trf", "<input type='radio' name='TRFsize' value='orLess'> or less", ""),
        ("search-database-quantity-trf", "<input type='radio' name='TRFsize' value='orMore'> or more", ""),
        ("search-database-quantity-trf", "<input type='radio' name='TRFsize' value='exact'> exactly", ""),
        ("search-database-quantity-trf", "<input type='radio' name='TRFsize' value='none'> none", ""),

    ("search-database-analyses-protein-code-TTconfM", "<input type='radio' name='TTconfM' value='orLess'> or less", ""),
        ("search-database-analyses-protein-code-TTconfM", "<input type='radio' name='TTconfM' value='orMore'> or more", ""),
        ("search-database-analyses-protein-code-TTconfM", "<input type='radio' name='TTconfM' value='exact'> exactly", ""),
        ("search-database-analyses-protein-code-TTconfM", "<input type='radio' name='TTconfM' value='none'> none", ""),

    ("search-database-analyses-protein-code-TThpM", "<input type='radio' name='TThpM' value='orLess'> or less", ""),
        ("search-database-analyses-protein-code-TThpM", "<input type='radio' name='TThpM' value='orMore'> or more", ""),
        ("search-database-analyses-protein-code-TThpM", "<input type='radio' name='TThpM' value='exact'> exactly", ""),
        ("search-database-analyses-protein-code-TThpM", "<input type='radio' name='TThpM' value='none'> none", ""),

    ("search-database-analyses-protein-code-TTtailM", "<input type='radio' name='TTtailM' value='orLess'> or less", ""),
        ("search-database-analyses-protein-code-TTtailM", "<input type='radio' name='TTtailM' value='orMore'> or more", ""),
        ("search-database-analyses-protein-code-TTtailM", "<input type='radio' name='TTtailM' value='exact'> exactly", ""),
        ("search-database-analyses-protein-code-TTtailM", "<input type='radio' name='TTtailM' value='none'> none", ""),

    ("search-database-analyses-protein-code-AHlenM", "<input type='radio' name='AHlenM' value='orLess'> or less", ""),
        ("search-database-analyses-protein-code-AHlenM", "<input type='radio' name='AHlenM' value='orMore'> or more", ""),
        ("search-database-analyses-protein-code-AHlenM", "<input type='radio' name='AHlenM' value='exact'> exactly", ""),
        ("search-database-analyses-protein-code-AHlenM", "<input type='radio' name='AHlenM' value='none'> none", ""),

    ("search-database-analyses-protein-code-AHscM", "<input type='radio' name='AHscM' value='orLess'> or less", ""),
        ("search-database-analyses-protein-code-AHscM", "<input type='radio' name='AHscM' value='orMore'> or more", ""),
        ("search-database-analyses-protein-code-AHscM", "<input type='radio' name='AHscM' value='exact'> exactly", ""),
        ("search-database-analyses-protein-code-AHscM", "<input type='radio' name='AHscM' value='none'> none", ""),

    ("search-database-analyses-protein-code-AHthrM", "<input type='radio' name='AHthrM' value='orLess'> or less", ""),
        ("search-database-analyses-protein-code-AHthrM", "<input type='radio' name='AHthrM' value='orMore'> or more", ""),
        ("search-database-analyses-protein-code-AHthrM", "<input type='radio' name='AHthrM' value='exact'> exactly", ""),
        ("search-database-analyses-protein-code-AHthrM", "<input type='radio' name='AHthrM' value='none'> none", ""),


        ("search-database-analyses-protein-code-signal-peptide", "With signal peptide? ", ""),
        ("search-database-analyses-protein-code-signal-peptide-option", "<input type='radio' name='sigP' value='sigPyes' >  yes", ""),
        ("search-database-analyses-protein-code-signal-peptide-option", "<input type='radio' name='sigP' value='sigPno'> no", ""),
        ("search-database-analyses-protein-code-signal-peptide-option", "<input type='radio' name='sigP' value='sigPwhatever' checked='checked'> do not care", ""),
        ("search-database-analyses-protein-code-signal-peptide-option-signalP", "<input type='radio' name='signalP' value='YES' >  yes", ""),
        ("search-database-analyses-protein-code-signal-peptide-option-signalP", "<input type='radio' name='signalP' value='NO'> no", ""),
        ("search-database-analyses-protein-code-signal-peptide-option-signalP", "<input type='radio' name='signalP' value='whatever' checked='checked'> do not care", "");
SQL


###
#
#	Realiza a leitura do arquivo example.html
#	Pega o conteúdo e concatena a query no script SQL
#
###
$scriptSQL .= readJSON($html_file);
print $LOG "\n$html_file read!\n";

#apaga diretorios antigos com fastas
print $LOG "\nDeleting old fasta directories\n";

#if(-d "$html_dir/root/$fasta_dir" && -d "$html_dir/root/$aa_fasta_dir" && -d "$html_dir/root/$nt_fasta_dir")
#{
#    !system("rm -r $html_dir/root/$fasta_dir $html_dir/root/$aa_fasta_dir $html_dir/root/$nt_fasta_dir")
#	or die "Could not removed directories\n";
#}

print $LOG "\nSeparating sequences od multifasta and create directory\n";

#separa sequencias do multifasta e cria diretorio
my $html_dir     = $organism_name."-Website";
my $services_dir = $organism_name."-Services";
print $LOG "\nCreating $html_dir\n";
!system("mkdir -p $html_dir")
    or die "Could not created directory $html_dir\n";
print $LOG "\nCreating $fasta_dir\n";
!system("mkdir -p $html_dir/root/$fasta_dir")
    or die "Could not created directory $html_dir/root/$fasta_dir\n";

#print $LOG "Separating ORFs em AA of multifasta AA";
##separa ORFs em aa do multifasta aa
print $LOG "\nCreating $aa_fasta_dir\n";
!system("mkdir -p $html_dir/root/$aa_fasta_dir")
    or die "Could not created directory $html_dir/root/$aa_fasta_dir\n";
#
#if ( $aa_orf_file ne "" ) {
#	open( FILE_AA, "$aa_orf_file" ) or print $LOG "Could not open file $aa_orf_file\n";
#}
#
#print $LOG "Separating ORFs NT of multifasta NT";
##separa ORFs nt do multifasta nt
print $LOG "\nCreating $nt_fasta_dir\n";
!system("mkdir -p $html_dir/root/$nt_fasta_dir")
    or print $LOG "Could not created directory $html_dir/root/$nt_fasta_dir\n";

#if($nt_orf_file ne "")
#{
#    open(FILE,"$nt_orf_file") or die "Could not open file $nt_orf_file\n";
#}

#prefix_name for sequence
my $prefix_name;
my $header;
print $LOG "\nComponent list: " . $component_name_list . "\n";
my @components_name = split( ';', $component_name_list );

#push @components_name,"go_terms";
my @comp_dna = ();
my @comp_ev  = ();
foreach my $c ( sort @components_name ) {
    if (   $c eq "annotation_alienhunter.pl"
        || $c eq "annotation_skews.pl"
        || $c eq "annotation_infernal.pl"
        || $c eq "annotation_rbsfinder.pl"
        || $c eq "annotation_rnammer.pl"
        || $c eq "annotation_transterm.pl"
        || $c eq "annotation_trf.pl"
        || $c eq "annotation_trna.pl"
        || $c eq "annotation_string.pl"
        || $c eq "annotation_mreps.pl"
        || $c eq "annotation_glimmer3.pl"
        || $c eq "upload_gtf.pl"
        || $c eq "upload_prediction.pl"
        || $c eq "annotation_trna.pl"
        || $c eq "annotation_alienhunter.pl" )
    {
        #$c =~ s/\.pl//;
        $c =~ /\.pl/g;
        my $name = $`;
        push @comp_dna, $name;
    }
    else {
        #$c =~ s/\.pl//;
        $c =~ /\.pl/g;
        push @comp_ev, $`;
    }
}
#
# Read ALL Sequence Objects and sort by name for nice display
#

my @sequence_objects;
my $index = 0;

my $strlen    = 4;
my $count_seq = 1;

my $sequence_object = new EGeneUSP::SequenceObject();
my %hash_ev         = ();
my %hash_dna        = ();
my @seq_links;

#contador de sequencias
my $seq_count           = 0;
my %components          = ();
my @filepathsComponents = ();
my $dbName              = "";
my $dbHost              = "";
my $dbUser              = "";
my $dbPassword          = "";
my $locus               = 0;

if ( scalar @reports_global_analyses > 0 ) {
    foreach my $path (@reports_global_analyses) {
        my $key = "";
        if($path =~ /([\.\/\w]+)\//) {
            my $directory = $1;
            $key = $_ foreach($directory =~ /\/([\w._]+)+$/img);	 
        }
        my $name = $key;
        $name =~ s/([\w_]+)+_report/$1/;
        print $LOG "\n[908] $key - $name\n";
        $scriptSQL .=
        "\nINSERT INTO COMPONENTS(name, component, filepath) VALUES('$name', 'report_$name', '$key');\n";
        $components{$name} = $path;
    }
}

print $LOG "\nReading sequences\n";

my $annotation_blast = 0;
my $annotation_interpro = 0;
my $annotation_orthology = 0;
my $annotation_pathways = 0;
my $annotation_trna = 0;
my $annotation_alienhunter = 0;
my $annotation_rbs = 0;
my $annotation_transterm = 0;
my $annotation_phobius = 0;
my $annotation_rpsblast = 0;
my $annotation_rnammer = 0;
my $annotation_tmhmm = 0;
my $annotation_dgpi = 0;
my $annotation_predgpi = 0;
my $annotation_bigpi = 0;
my $annotation_tcdb = 0;
my $annotation_infernal = 0;
my $annotation_trf = 0;
my $annotation_signalP = 0;

my $allGenesSequences = 0;
my $proteinCodingSequences = 0;
my $rRNASequences = 0;
my $tRNASequences = 0;
my $nonCodingSequences = 0;
my $allContigs = 0;
my $ttSequences = 0;

open(my $SEQUENCES, ">", "$html_dir/root/Sequences.fasta");
open(my $SEQUENCES_NT, ">", "$html_dir/root/Sequences_NT.fasta");
open(my $SEQUENCES_AA, ">", "$html_dir/root/Sequences_AA.fasta");

$scriptSQL .= <<SQL;
            INSERT INTO FILES(tag, filepath) VALUES ("ag", "all_genes.fasta"), 
            ("trg", "trna_seqs.fasta"), ("rrg", "rrna_seqs.fasta"), ("oncg", "rna_seqs.fasta"), ("pro", "Sequences_NT.fasta"), 
            ("ac", "Sequences.fasta"), ("tt", "transterm_seqs.fasta");
SQL

while ( $sequence_object->read() ) {
    $sequence_object->print();
    print $LOG "\nSequence:\t" . $sequence_object->{sequence_id} . "\nName:\t".$sequence_object->sequence_name()."\nPipeline ID: ". $sequence_object->{pipeline_id}."\n"; 
    ++$seq_count;
    $header = $sequence_object->fasta_header();
    my @conclusions = @{ $sequence_object->get_conclusions() };
    my $n           = scalar(@conclusions);

    #	print STDERR "N de conc: $n\n";
    my $bases = $sequence_object->current_sequence();
    #print $LOG "\nCurrent Sequence:\t$bases\n";
    my $name  = $sequence_object->sequence_name();
    $dbName     = $sequence_object->{dbname};
    $dbHost     = $sequence_object->{host};
    $dbUser     = $sequence_object->{user};
    $dbPassword = $sequence_object->{password};
    print $LOG "\nDatabase name:\t$dbName\nHost:\t$dbHost\nUser:\t$dbUser\n";

#aqui começaria a geração da pagina relacionada a cada anotação
#pulando isso, passamos para geração dos arquivos, volta a duvida sobre a necessidade desses arquivos
    my $file_aa = $name . "_CDS_AA.fasta";
    my $file_nt = $name . "_CDS_NT.fasta";
    open( FILE_AA, ">$html_dir/root/$aa_fasta_dir/$file_aa" );
    open( FILE_NT, ">$html_dir/root/$nt_fasta_dir/$file_nt" );

    #	print $LOG "\n$name\n$bases\n\n";
    $scriptSQL .=
    "\nINSERT INTO SEQUENCES(id, name, filepath) VALUES ("
    . $sequence_object->{sequence_id} . ", '"
    . $name . "', '"
    . $fasta_dir . "/"
    . $name
    . ".fasta');\n";

#    my $ann_file = "annotations/".$name;
# no script original(report_html.pl) começa a criação da pagina principal onde são listadas as sequencias
# pulando essa parte, começamos a escrita do arquivo fasta, entra em duvida a necessidade desse arquivo
    open( FASTAOUT, ">$html_dir/root/$fasta_dir/$name.fasta" )
        or warn
    "could not create fasta file $html_dir/root/$fasta_dir/$name.fasta\n";
    my $length = length($bases);
    print $SEQUENCES ">$name\n";
    for ( my $i = 0 ; $i < $length ; $i += 60 ) {
        my $sequence = substr( $bases, $i, 60 );
        print $SEQUENCES "$sequence\n";
    }
    print FASTAOUT ">$name\n";
    for ( my $i = 0 ; $i < $length ; $i += 60 ) {
        my $sequence = substr( $bases, $i, 60 );
        print FASTAOUT "$sequence\n";
    }
    close(FASTAOUT);

#	my @logs = @{ $sequence_object->get_logs_hash() };

    foreach my $conclusion (@conclusions) {
        $sequence_object->get_evidence_for_conclusion();
        my %hash      = %{ $sequence_object->{array_evidence} };
        my @evidences = @{ $conclusion->{evidence_number} };

        ###
        #
        # Receber lista de componentes rodados
        #
        ###

        foreach my $ev (@evidences) {
            my $evidence      = $hash{$ev};
            my $ev_name = $sequence_object->fasta_header_evidence($evidence);
            $ev_name =~ s/>//;
            my $fasta_header_evidence =
            $sequence_object->fasta_header_evidence($evidence);

            $fasta_header_evidence =~ s/>//g;
            $fasta_header_evidence =~ s/>//g;
            $fasta_header_evidence =~ s/\|/_/g;
            $fasta_header_evidence =~ s/__/_/g;

            $fasta_header_evidence =~ s/>//g;

            my $component = $sequence_object->fasta_header_program($evidence);
            my $component_name =
            !$evidence->{log}{name}
            ? ( $component =~ /(annotation[_\w]+)/g )[0]
            : $evidence->{log}{name};
            $component_name = $` if $component_name =~ /\.pl/g;
            my $locus_tag;

            if ( $conclusion->{locus_tag} ) {
                $locus_tag = $conclusion->{locus_tag};
            }
            else {
                $locus++;
                $locus_tag = "NOLOCUSTAG_$locus";
            }

            $fasta_header_evidence =~ s/>//g;
            $fasta_header_evidence =~ s/>//g;
            $fasta_header_evidence =~ s/\|/_/g;
            $fasta_header_evidence =~ s/__/_/g;
            print $LOG "\n[1186]\tFastaHeaderEvidence\t-\t$fasta_header_evidence\n";
            my $html_file = $fasta_header_evidence . ".html";
            my $txt_file  = $fasta_header_evidence . ".txt";
            my $png_file  = $fasta_header_evidence . ".png";
            #$component_name = $evidence->{log}{name};
            $fasta_header_evidence =~ s/>//g;

            my %hashSQL = ();
            my @logs = @{$sequence_object->get_logs_hash()};

            if ( $evidence->{tag} eq "CDS" ) {
                foreach my $log (@logs){
                    my $log_name = $log->{program};
                    $log_name =~ s/\.pl//g;
                    $log_name =~ s/$annotation_dir//g;
                    $log_name =~ s/\///g;
                    #my $resp1 = verify_element($log_name, \@comp_dna);
                    my $resp2 = verify_element($log_name, \@comp_ev);
                    print $LOG "\n[1056] $log_name\n";
                    #if(!$resp1 and !$resp2){ 
                    if($resp2) {
                        my $file = "";
                        $file = "$html_file" if($log_name eq "annotation_blast");
                        $file = "$html_file" if($log_name eq "annotation_interpro" || $log_name eq "annotation_pathways" || $log_name eq "annotation_tcdb");
                        if($log_name eq "annotation_orthology") {
                            my $code;
                            $code = $_ foreach ($log->{arguments} =~ /database_code\s*=\s*(\w+)+\s*/ig);
                            my $aux_html = $html_file;				
                            $code = ".".$code.".html";
                            $aux_html =~ s/\.html/$code/g;
                            $file = $aux_html;
                        }
                        $file = "$png_file" if($log_name eq "annotation_phobius" || $log_name eq "annotation_signalP" || $log_name eq "annotation_tmhmm");
                        $file = "$txt_file" if($log_name eq "annotation_rpsblast");

                        $hashSQL{$log_name} = 
                        "\nINSERT INTO COMPONENTS(name, locus_tag,  component, filepath) VALUES('$log_name', '$locus_tag', '$log_name.pl', '".$log->{program}."_log_".$log->{log_number}."/$file');\n";
                        print $LOG "\n[1087] - ".$hashSQL{$log_name}."\n";
                        $hash_ev{$log_name} = 1;
                    }
                }
            }

            #				print STDERR "\nNumber:\t$number\nStart:\t$start\nEnd:\t$end\n";
            #				print $LOG "\nNumber:\t$number\nStart:\t$start\nEnd:\t$end\n";

            my $number = $evidence->{number};
            my $start;
            my $end;

            if ( $evidence->{start} < $evidence->{end} ) {
                $start = $evidence->{start};
                $end   = $evidence->{end};
            }
            else {
                $start = $evidence->{end};
                $end   = $evidence->{start};
            }
            my $len_nt = ( $end - $start ) + 1;
            my $sequence_nt;
            my $nt_seq = substr( $bases, $start - 1, $len_nt );
            $len_nt = length($nt_seq);
            my $file_ev = $locus_tag . ".fasta";

            open(ALL_GENES, ">>", "$html_dir/root/all_genes.fasta");

            if ( $evidence->{tag} eq "CDS" ) {
                open( AA, ">$html_dir/root/$aa_fasta_dir/$file_ev" );
                print FILE_NT ">$locus_tag\n";
                print $SEQUENCES_NT ">$locus_tag\n";
                print ALL_GENES ">$locus_tag\n";

                my @intervals = @{ $evidence->{intervals} };
                print $LOG "\nIntervals:	" . @intervals . "\n";
                my $strand = $intervals[0]->{strand};
                print $LOG "\nstrand:	" . $strand . "\n";
                if ( ( $strand eq '-' ) or ( ( $strand eq '-1' ) ) ) {

                    #					print $LOG "Sequencia antes:\t".$nt_seq."\n";
                    $nt_seq = formatSequence( reverseComplement($nt_seq) );

                    #					print $LOG "\nNumber:\t$number\nStart:\t$start\nEnd:\t$end\n";
                    #					print $LOG "\nSequencia depois:\t".$nt_seq."\n";
                }
                print AA ">$locus_tag-nucleotide_sequence\n"; 
                $nt_seq =~ s/\n//g;

                for ( my $i = 0 ; $i < $len_nt ; $i += 60 ) {
                    $sequence_nt = substr( $nt_seq, $i, 60 );
                    print FILE_NT "$sequence_nt\n";
                    print AA "$sequence_nt\n";
                    print $SEQUENCES_NT "$sequence_nt\n";
                    print ALL_GENES "$sequence_nt\n";
                    $allGenesSequences = 1;
                    $proteinCodingSequences = 1;
                    $allContigs = 1;
                }
                my $seq_aa = $evidence->{protein_sequence};
                my $sequence_aa;
                my $len_aa = length($seq_aa);
                print FILE_AA ">$locus_tag\n";
                print AA ">$locus_tag-translated_sequence\n";
                print $SEQUENCES_AA ">$locus_tag\n";
                for ( my $i = 0 ; $i < $len_aa ; $i += 60 ) {
                    $sequence_aa = substr( $seq_aa, $i, 60 );
                    print FILE_AA "$sequence_aa\n";
                    print AA "$sequence_aa\n";
                    print $SEQUENCES_AA "$sequence_aa\n";
                }
            }
            elsif ($evidence->{tag} eq "tRNAscan") {
                open( tRNA_FILE, ">>", "$html_dir/root/trna_seqs.fasta" );
                print tRNA_FILE ">$locus_tag\n";
                print ALL_GENES ">$locus_tag\n";				
                for ( my $i = 0 ; $i < $len_nt ; $i += 60 ) {
                    my $sequence = substr( $nt_seq, $i, 60 );
                    print tRNA_FILE "$sequence\n";
                    print ALL_GENES "$sequence\n";
                }
                close(tRNA_FILE);
                $allGenesSequences = 1;
                $tRNASequences = 1;
            }
            elsif ($evidence->{tag} eq "RNA_scan"){
                open( rna_FILE, ">>", "$html_dir/root/rna_seqs.fasta" );
                print rna_FILE ">$locus_tag\n";
                print ALL_GENES ">$locus_tag\n";				
                for ( my $i = 0 ; $i < $len_nt ; $i += 60 ) {
                    my $sequence = substr( $nt_seq, $i, 60 );
                    print rna_FILE "$sequence\n";
                    print ALL_GENES "$sequence\n";
                }
                close(rna_FILE);
                $allGenesSequences = 1;
                $nonCodingSequences = 1;
            }
            elsif ($evidence->{tag} eq "rRNA_prediction"){
                open( rRNA_FILE, ">>", "$html_dir/root/rrna_seqs.fasta" );
                print rRNA_FILE ">$locus_tag\n";				
                print ALL_GENES ">$locus_tag\n";
                for ( my $i = 0 ; $i < $len_nt ; $i += 60 ) {
                    my $sequence = substr( $nt_seq, $i, 60 );
                    print rRNA_FILE "$sequence\n";
                    print ALL_GENES "$sequence\n";
                }
                close(rRNA_FILE);
                $allGenesSequences = 1;
                $rRNASequences = 1;
            } else {
                print $LOG "\n[1082] TAG:\t".$evidence->{tag}."\n";
                open( UNKNOWN_FILE, ">>", "$html_dir/root/".$evidence->{tag}."_seqs.fasta" );
                print UNKNOWN_FILE ">$locus_tag\n";				
                print ALL_GENES ">$locus_tag\n";
                for ( my $i = 0 ; $i < $len_nt ; $i += 60 ) {
                    my $sequence = substr( $nt_seq, $i, 60 );
                    print UNKNOWN_FILE "$sequence\n";
                    print ALL_GENES "$sequence\n";
                }
                close(UNKNOWN_FILE);
                $allGenesSequences = 1;
                $ttSequences = 1 if($evidence->{tag} eq "transterm");
            }
            close(ALL_GENES);

            if ( $component && $component_name ) {
                my $resp = verify_element( $component_name, \@comp_dna );
                print $LOG "\n[962] $component_name -  resp = $resp\n";
                if ($resp) {
                    my $relative_path = "";
                    if ( $component_name eq "annotation_trf" ) {
                        my $file = $name . "_trf.txt";
                        $components{$component} = "$annotation_dir/$component/$file";
                        $relative_path = "$component/$file";
                        $annotation_trf = 1;
                    }
                    elsif ( $component_name eq "annotation_trna" ) {
                        my $file = $name . "_trna.txt";
                        $components{$component} = "$annotation_dir/$component/$file";
                        $relative_path = "$component/$file";
                        $annotation_trna = 1;
                    }
                    elsif ( $component_name eq "annotation_alienhunter" ) {
                        my $file = $alienhunter_output_file . "_" . $name;
                        $components{$component} = "$annotation_dir/" . $component . "/" . $file;
                        $relative_path = "$component/$file";
                        $annotation_alienhunter = 1;
                    }
                    elsif ( $component_name eq "annotation_infernal" ) {
                        my $file = $infernal_output_file . "_" . $name;
                        $components{$component} = "$annotation_dir/$component/$file";
                        $relative_path = "$component/$file";
                        $annotation_infernal = 1;
                    }
                    elsif ( $component_name eq "annotation_skews" ) {
                        my $filestring = `ls $skews_dir`;
                        my @phdfilenames = split( /\n/, $filestring );
                        my $aux      = "";
                        foreach my $file (@phdfilenames) {
                            if (    $file =~ m/$name/
                                    and $file =~ m/.png/ )
                            {
                                $aux .= "$annotation_dir/$component/$file\n";
                                $relative_path .= "$component/$file\n"; 
                            }
                        }

                        $components{$component} = $aux;
                    }
                    elsif ( $component_name eq "annotation_rbsfinder" ) {
                        my $file = $name . ".txt";
                        $components{$component} = "$annotation_dir/$component/$file";
                        $relative_path = "$component/$file";
                        $annotation_rbs = 1;
                    }
                    elsif ( $component_name eq "annotation_rnammer" ) {
                        my $file = $name . "_rnammer.gff";
                        $components{$component} = "$annotation_dir/$component/$file";
                        $relative_path = "$component/$file";
                        $annotation_rnammer = 1;
                    }
                    elsif ( $component_name eq "annotation_glimmer3" ) {
                        $components{$component} =
                        "$annotation_dir/$component/glimmer3.txt";
                        $relative_path = "$component/glimmer3.txt";
                    }
                    elsif ( $component_name eq "upload_gtf" ) {
                        $components{$component} =
                        "$annotation_dir/$component/upload_gtf.txt";
                        $relative_path = "$component/upload_gtf.txt";
                    }
                    elsif ( $component_name eq "upload_prediction" ) {
                        $components{$component} =
                        "$annotation_dir/$component/upload_prediction.txt";
                        $relative_path = "$component/upload_prediction.txt";
                    }
                    elsif ( $component_name eq "annotation_transterm" ) {
                        my $file = $name . ".txt";
                        $components{$component} = "$annotation_dir/$component/$file";
                        $annotation_transterm = 1;
                        $relative_path = "$component/$file";
                    }
                    elsif ( $component_name eq "annotation_mreps" ) {
                        my $file = "$annotation_dir/" . $component . "/" . $name . "_mreps.txt";
                        $components{$component} = "$file";
                        $relative_path = "$component/" . $name . "_mreps.txt";;
                    }
                    elsif ( $component_name eq "annotation_string" ) {
                        my $file =
                        $string_dir . "/" . $name . "_string.txt";
                        $components{$component} = "$annotation_dir/$component/$file";
                        $relative_path = "$component/$file";
                    }

#					if ( $component_name =~ /annotation_/g ) {
#						$component_name =~ s/annotation_//g;
#					}
#					els
                    if ( $component_name =~ /report_/g ) {
                        $component_name =~ s/report_//g;
                    }

                    push @filepathsComponents, $components{$component};

#					print STDERR "\n[1119] Name:\t$component_name\nComponent:\t$component\nfilepath:\t$components{$component}\n\n";
                    $scriptSQL .=
                    "\nINSERT INTO COMPONENTS(name, locus_tag, component, filepath) VALUES('$component_name', '$locus_tag', '$component', '$relative_path');\n";
                }

            }


            if ( $evidence->{tag} eq "CDS" ) {

                #				foreach my $subevidence ( @{ $evidence->{evidences} } ) {
                #					push @subevidences, $subevidence;
                #				}



                print $LOG "\nLocus tag: " . $locus_tag . "\n";

                my @sub_evidences = @{ $evidence->{evidences} };

                foreach my $sub_evidence (@sub_evidences) {
                    my $component_name = $sub_evidence->{log}{name};
                    $component_name =~ s/.pl//g;
                    my $component =
                    $sequence_object->fasta_header_program($sub_evidence);

                    my $resp = verify_element( $component_name, \@comp_ev );
                    print $LOG "\n[1263] - $component - $component_name - resp = $resp - locus_tag = $locus_tag\n";

                    if (  $resp  )
                    {
                        if ( $component_name eq "annotation_blast" ) {
                            $components{$component} = "$annotation_dir/$component/$html_file";

                            $hashSQL{$component_name} = 
                            "\nINSERT INTO COMPONENTS(name, locus_tag, component, filepath) VALUES('$component_name', '$locus_tag', '$component', '$component/$html_file');\n";
                            $annotation_blast = 1;
                        }
                        elsif ( $component_name eq "annotation_glimmer3" ) {
                            $components{$component} =
                            "$annotation_dir/". $component . "/glimmer3.txt";
                            $scriptSQL .=
                            "\nINSERT INTO COMPONENTS(name, locus_tag, component, filepath) VALUES('$component_name', '$locus_tag', '$component', '$component/glimmer3.txt');\n";
                        }
                        elsif ( $component_name eq "upload_gtf" ) {
                            $components{$component} =
                            "$annotation_dir/$component/upload_gtf.txt";
                            $scriptSQL .=
                            "\nINSERT INTO COMPONENTS(name, locus_tag, component, filepath) VALUES('$component_name', '$locus_tag', '$component', '$component/upload_gtf.txt');\n";  
                        }
                        elsif ( $component_name eq "upload_prediction" ) {
                            $components{$component} =
                            "$annotation_dir/$component/upload_prediction.txt";                                                                                          
                            $scriptSQL .=
                            "\nINSERT INTO COMPONENTS(name, locus_tag, component, filepath) VALUES('$component_name', '$locus_tag', '$component', '$component/upload_prediction.txt');\n";  
                        }
                        elsif ( $component_name eq "annotation_interpro" ) {
                            $components{$component} = "$annotation_dir/$component/";
                            $hashSQL{$component_name} =
                            "\nINSERT INTO COMPONENTS(name, locus_tag, component, filepath) VALUES('$component_name', '$locus_tag', '$component', '$component/HTML/$html_file');\n";
                            $annotation_interpro = 1;
                        }
                        elsif ( $component_name eq "annotation_orthology" ) {
                            my $code;

                            while ( $sub_evidence->{log}{arguments} =~
                                /database_code\s*=\s*(\w+)+\s*/ig )
                            {
                                $code = $1;
                            }
                            my $aux_html = $html_file;
                            $code = "." . $code . ".html";
                            $aux_html =~ s/.html/$code/g;
                            $components{$component} = "$annotation_dir/$component/$aux_html";
                            $hashSQL{$component_name} =
                            "\nINSERT INTO COMPONENTS(name, locus_tag, component, filepath) VALUES('$component_name', '$locus_tag', '$component', '$component/$aux_html');\n";
                            $annotation_orthology = 1;
                        }
                        elsif ( $component_name eq "annotation_pathways" ) {
                            $components{$component} = "$annotation_dir/$component/$html_file";
                            $hashSQL{$component_name} =
                            "\nINSERT INTO COMPONENTS(name, locus_tag,  component, filepath) VALUES('$component_name', '$locus_tag', '$component', '$component/$html_file');\n";
                            $annotation_pathways = 1;
                        }
                        elsif ( $component_name eq "annotation_phobius" ) {
                            $components{$component} = "$annotation_dir/$component/$png_file";
                            $annotation_phobius = 1;
                            $hashSQL{$component_name} =
                            "\nINSERT INTO COMPONENTS(name, locus_tag, component, filepath) VALUES('$component_name', '$locus_tag', '$component', '$component/$png_file');\n";
                        }
                        elsif ( $component_name eq "annotation_signalP" ) {
                            $components{$component} = "$annotation_dir/$component/$png_file";
                            $annotation_signalP = 1;
                            $hashSQL{$component_name} =
                            "\nINSERT INTO COMPONENTS(name, locus_tag, component, filepath) VALUES('$component_name', '$locus_tag', '$component', '$component/$png_file');\n";
                        }
                        elsif ( $component_name eq "annotation_rpsblast" ) {
                            $components{$component} = "$annotation_dir/$component/$txt_file";
                            $hashSQL{$component_name} =
                            "\nINSERT INTO COMPONENTS(name, locus_tag, component, filepath) VALUES('$component_name', '$locus_tag', '$component', '$component/$txt_file');\n";
                            $annotation_rpsblast = 1;
                        }
                        elsif( $component_name eq "annotation_tmhmm" ) {
                            $components{$component} = "$annotation_dir/$component/$png_file";
                            $hashSQL{$component_name} =
                            "\nINSERT INTO COMPONENTS(name, locus_tag, component, filepath) VALUES('$component_name', '$locus_tag', '$component', '$component/$png_file');\n";
                            $annotation_tmhmm = 1;
                        }
                        elsif($component_name eq "annotation_predgpi" || $component_name eq "annotation_dgpi" || $component_name eq "annotation_bigpi" || $component_name eq "annotation_tcdb") {
                            $components{$component} = "$annotation_dir/$component/$html_file";
                            $hashSQL{$component_name} =
                            "\nINSERT INTO COMPONENTS(name, locus_tag, component, filepath) VALUES('$component_name', '$locus_tag', '$component', '$component/$html_file');\n";

                            if($component_name eq "annotation_dgpi") {
                                $annotation_dgpi = 1;
                            } elsif($component_name eq "annotation_predgpi"){
                                $annotation_predgpi = 1;
                            } elsif($component_name eq "annotation_bigpi") {
                                $annotation_bigpi = 1;
                            } elsif($component_name eq "annotation_tcdb") {
                                $annotation_tcdb = 1;
                            }
                        }
                        elsif ( $component_name eq "annotation_hmmer" ) {
                            $components{$component} = "$annotation_dir/" .
                            $component . "/hmmer.txt";
                            $hashSQL{$component_name} =
                            "\nINSERT INTO COMPONENTS(name, locus_tag, component, filepath) VALUES('$component_name', '$locus_tag', '$component', '$component/hmmer.txt');\n";
                        }
                    }
                    push @filepathsComponents, $components{$component};
                }
                $scriptSQL .= "\n".$hashSQL{$_}."\n" foreach(keys %hashSQL);

            }

        }

    }

    foreach my $key ( keys %components ) {
        print $LOG "\nKey:\t$key\nValue:\t" . $components{$key} . "\n"
        if defined $components{$key};
        push @filepathsComponents, $components{$key};
    }

    close(AA);
    close(FILE_AA);
    close(FILE_NT);


    $header =~ s/>//g;
    $header =~ m/(\S+)_(\d+)/;
    $prefix_name = $1;

}

close($SEQUENCES_NT);
close($SEQUENCES_AA);
close($SEQUENCES);
`cp -r $html_dir/root/Sequences.fasta $html_dir/root/$fasta_dir/Sequences.fasta`;
`cp -r $html_dir/root/Sequences_AA.fasta $html_dir/root/$aa_fasta_dir/Sequences_AA.fasta`;
`cp -r $html_dir/root/Sequences_NT.fasta $html_dir/root/$nt_fasta_dir/Sequences_NT.fasta`;
`makeblastdb -dbtype prot -in $html_dir/root/$aa_fasta_dir/Sequences_AA.fasta -parse_seqids -title 'Sequences_AA' -out $html_dir/root/$aa_fasta_dir/Sequences_AA -logfile $html_dir/root/$aa_fasta_dir/makeblastdb.log`;
`makeblastdb -dbtype nucl -in $html_dir/root/$nt_fasta_dir/Sequences_NT.fasta -parse_seqids -title 'Sequences_NT' -out $html_dir/root/$nt_fasta_dir/Sequences_NT -logfile $html_dir/root/$nt_fasta_dir/makeblastdb.log`;
`makeblastdb -dbtype nucl -in $html_dir/root/$fasta_dir/Sequences.fasta -parse_seqids -title 'Sequences' -out $html_dir/root/$fasta_dir/Sequences -logfile $html_dir/root/$fasta_dir/makeblastdb.log`;
`mkdir -p $services_dir/root/`;
`mkdir -p $html_dir/root/$nt_fasta_dir/`;
`cp -r $html_dir/root/$aa_fasta_dir/ $services_dir/root/`;
`cp -r $html_dir/root/$nt_fasta_dir/ $services_dir/root/`;
`cp -r $html_dir/root/$fasta_dir/ $services_dir/root/`;

$scriptSQL .= " INSERT INTO TEXTS(tag, value, details) VALUES ('downloads-genes-links-1', 'All genes (protein-coding, ribosomal RNA, transfer RNA, and non-coding RNA)', '/DownloadFile?type=ag');\n" if ($allGenesSequences);
$scriptSQL .= " INSERT INTO TEXTS(tag, value, details) VALUES ('downloads-genes-links-2', 'Protein-coding genes only', '/DownloadFile?type=pro');\n" if ($proteinCodingSequences);
$scriptSQL .= " INSERT INTO TEXTS(tag, value, details) VALUES ('downloads-genes-links-3', 'Ribosomal RNA genes only', '/DownloadFile?type=rrg');\n" if ($rRNASequences);
$scriptSQL .= " INSERT INTO TEXTS(tag, value, details) VALUES ('downloads-genes-links-4', 'Transfer RNA genes only', '/DownloadFile?type=trg');\n" if ($tRNASequences);
$scriptSQL .= " INSERT INTO TEXTS(tag, value, details) VALUES ('downloads-genes-links-5', 'Other non-coding RNA genes only table', '/DownloadFile?type=oncg');\n" if ($nonCodingSequences);
$scriptSQL .= " INSERT INTO TEXTS(tag, value, details) VALUES ('downloads-other-sequences-links-1', 'Get all contigs', '/DownloadFile?type=ac');\n" if ($allContigs);
$scriptSQL .= " INSERT INTO TEXTS(tag, value, details) VALUES ('downloads-other-sequences-links-2', 'All transcriptional terminators (predicted by TransTermHP)', '/DownloadFile?type=tt');\n" if ($ttSequences);

if($annotation_trf) {
    $scriptSQL .= <<SQL;
                INSERT INTO TEXTS(tag, value, details) VALUES 
                    ("search-database-dna-based-analyses-tab", "<a href='#tandemRepeats' data-toggle='tab'>Tandem repeats</a>", "");
SQL
}
if($annotation_interpro) {
    $scriptSQL .= <<SQL;
                INSERT INTO TEXTS(tag, value, details) VALUES
                    ("search-database-analyses-protein-code-tab", "<a href='#geneOntology' data-toggle='tab'>GO</a>", "");
SQL
}
if($annotation_tcdb) {
    ###
    #
    #       Realiza leitura do arquivo de TCDBs
    #
    ###
    if ($tcdb_file) {
        $scriptSQL .= readTCDBFile($tcdb_file);
        $scriptSQL .= <<SQL;
        INSERT INTO TEXTS(tag, value, details) VALUES
        ("search-database-analyses-protein-code-tab", "<a href='#transporterClassification' data-toggle='tab'>TCDB</a>", ""),
        ("search-database-analyses-protein-code-not-containing-classification-tcdb", " not containing TCDB classification", ""),
        ("search-database-analyses-protein-code-search-by-transporter-identifier", "Search by transporter identifier(e.g. 1.A.3.1.1):", ""),
        ("search-database-analyses-protein-code-search-by-transporter-family", "Or by transporter family(e.g. 3.A.17):", ""),
        ("search-database-analyses-protein-code-search-by-transporter-subclass", "Or by transporter subclass:", ""),
        ("search-database-analyses-protein-code-search-by-transporter-class", "Or by transporter class:", ""),
        ("search-database-dna-based-analyses-search-ncrna-by-target-identifier", "Search ncRNA by target identifier: ", ""),
        ("search-database-dna-based-analyses-or-by-evalue-match", "Or by E-value of match(e.g. 1e-6 or; 0.000001): ", ""),
        ("search-database-dna-based-analyses-or-by-target-name", "Or by target name: ", ""),
        ("search-database-dna-based-analyses-or-by-target-class", "Or by target class: ", ""),
        ("search-database-dna-based-analyses-or-by-target-type", "Or by target type: ", ""),
        ("search-database-dna-based-analyses-or-by-target-description", "Or by target description: ", "");
SQL
    }
    print $LOG "\n$tcdb_file read!\n";

}
if($annotation_orthology) {
    $scriptSQL .= <<SQL;
                INSERT INTO TEXTS(tag, value, details) VALUES
                    ("search-database-analyses-protein-code-tab", "<a href='#orthologyAnalysis' data-toggle='tab'>eggNOG</a>", "");
SQL
}
if($annotation_blast) {
    print $LOG "\n[1505] Inseriu BLAST tab\n";
    $scriptSQL .= <<SQL;
                INSERT INTO TEXTS(tag, value, details) VALUES
                    ("search-database-analyses-protein-code-tab", "<a href='#blast' data-toggle='tab'>BLAST"</a>, "");
SQL
}
if($annotation_pathways) {
    $scriptSQL .= <<SQL;
                INSERT INTO TEXTS(tag, value, details) VALUES
                    ("search-database-analyses-protein-code-tab", "<a href='#kegg' data-toggle='tab'>KEGG</a>", "");
SQL

    ###
    #
    #	Pegando todos os pathways do arquivo KO
    #
    ###
    open( my $KOFILE, "<", $ko_file )
        or warn
    "WARNING: Could not open KO file $ko_file: $!\n";
    my $content        = do { local $/; <$KOFILE> };
    my @idKEGG         = ();
    my %workAroundSort = ();
    while (
        $content =~ /[PATHWAY]*\s+ko(\d*)\s*(.*)/gm )
    {
        if ( !( $1 ~~ @idKEGG ) && $1 ne "" ) {
            $workAroundSort{$2} = $1;
            push @idKEGG, $1;
        }
    }

    foreach my $key ( sort keys %workAroundSort ) {
        my $value = $workAroundSort{$key};
        $scriptSQL .= <<SQL;
            INSERT INTO TEXTS(tag, value, details) VALUES ("search-database-analyses-protein-code-by-kegg-pathway-options", "<option value='$value'>$key</option>", "");
SQL
    }
    close($KOFILE);
}
if($annotation_phobius) {
    $scriptSQL .= <<SQL;
                INSERT INTO TEXTS(tag, value, details) VALUES
                    ("search-database-analyses-protein-code-tab", "<a href='#phobius' data-toggle='tab'>Phobius</a>", "");
SQL
}
if ($annotation_signalP) {
    $scriptSQL .= <<SQL;
                INSERT INTO TEXTS(tag, value, details) VALUES 
                    ("search-database-analyses-protein-code-tab", "<a href='#signalP' data-toggle='tab'>SignalP</a>", "");
SQL
}
if($annotation_tmhmm) {
    $scriptSQL .= <<SQL;
                INSERT INTO TEXTS(tag, value, details) VALUES
                    ("search-database-analyses-protein-code-tab", "<a href='#tmhmm' data-toggle='tab'>TMHMM</a>", ""),
                    ("search-database-analyses-protein-code-number-transmembrane-domains", "Number of transmembrane domains:", "");
SQL
}
if($annotation_dgpi) {
    $scriptSQL .= <<SQL;
                INSERT INTO TEXTS(tag, value, details) VALUES 
                    ("search-database-analyses-protein-code-tab", "<a href='#dgpi' data-toggle='tab'>DGPI</a>", ""),
                    ("search-database-analyses-protein-code-not-containing-dgpi", " not containing DGPI matches", ""),
                    ("search-database-analyses-protein-code-cleavage-site-dgpi", "Get by cleavage site", ""),
                    ("search-database-analyses-protein-code-score-dgpi", "Or get by score", "");
SQL
}
if($annotation_predgpi) {
    $scriptSQL .= <<SQL;
                INSERT INTO TEXTS(tag, value, details) VALUES 
                    ("search-database-analyses-protein-code-tab", "<a href='#predgpi' data-toggle='tab'>PreDGPI</a>", ""),
                    ("search-database-analyses-protein-code-not-containing-predgpi", " not containing PreDGPI matches", ""),
                    ("search-database-analyses-protein-code-name-predgpi", "Get by name", ""),
                    ("search-database-analyses-protein-code-position-predgpi", "Or get by position", ""),
                    ("search-database-analyses-protein-code-specificity-predgpi", "Or get by specificity", ""),
                    ("search-database-analyses-protein-code-sequence-predgpi", "Or get by sequence", "");
SQL
}
if($annotation_bigpi) {
    $scriptSQL .= <<SQL;
                INSERT INTO TEXTS(tag, value, details) VALUES 
                    ("search-database-analyses-protein-code-tab", "<a href='#bigpi' data-toggle='tab'>BIGPI</a>", ""),
                    ("search-database-analyses-protein-code-not-containing-bigpi", " not containing BIGPI matches", ""),
                    ("search-database-analyses-protein-code-value-bigpi", "Get by value", ""),
                    ("search-database-analyses-protein-code-score-bigpi", "Or get by score", ""),
                    ("search-database-analyses-protein-code-position-bigpi", "Or get by position", "");
SQL
}
if($annotation_rpsblast) {
    $scriptSQL .= <<SQL;
                INSERT INTO TEXTS(tag, value, details) VALUES
                    ("search-database-analyses-protein-code-tab", "<a href='#rpsblast' data-toggle='tab'>RPS-BLAST</a>", "");
SQL
}
if ($annotation_transterm) {
    $scriptSQL .= <<SQL;
                INSERT INTO TEXTS(tag, value, details) VALUES 
                    ("search-database-dna-based-analyses-tab", "<a href='#transcriptionalTerminators' data-toggle='tab'>Transcriptional terminators</a>", ""),
                    ("search-database-dna-based-analyses-transcriptional-terminators-confidence-score", "Get transcriptional terminators with confidence score: ", ""),
                    ("search-database-dna-based-analyses-or-hairpin-score", "Or with hairpin score: ", ""),
                    ("search-database-dna-based-analyses-or-tail-score", "Or with tail score: ", ""),
                    ("search-database-dna-based-analyses-hairpin-note", "NOTE: hairpin and tail scores are negative.", "");
SQL
}
if($annotation_rbs) {
    $scriptSQL .= <<SQL;
                INSERT INTO TEXTS(tag, value, details) VALUES 
                    ("search-database-dna-based-analyses-tab", "<a href='#ribosomalBindingSites' data-toggle='tab'>Ribosomal binding sites</a>", ""),
                    ("search-database-dna-based-analyses-ribosomal-binding", "Search ribosomal binding sites containing sequence pattern: ", ""),
                    ("search-database-dna-based-analyses-or-search-all-ribosomal-binding-shift", " Or search for all ribosomal binding site predictions that recommend a shift in start codon position", ""),
                    ("search-database-dna-based-analyses-or-search-all-ribosomal-binding-options", "<input type='radio' name='RBSshiftM' value='neg' checked> upstream", "value='neg' checked"),
                    ("search-database-dna-based-analyses-or-search-all-ribosomal-binding-options", "<input type='radio' name='RBSshiftM' value='pos'> downstream", "value='pos'"),
                    ("search-database-dna-based-analyses-or-search-all-ribosomal-binding-options", "<input type='radio' name='RBSshiftM' value='both'> either", "value='both'"),
                    ("search-database-dna-based-analyses-or-search-all-ribosomal-binding-start", "Or search for all ribosomal binding site predictions that recommend a change of  start codon", "");
SQL
}
if($annotation_infernal) {
    $scriptSQL .= <<SQL;
                INSERT INTO TEXTS(tag, value, details) VALUES 
                    ("search-database-dna-based-analyses-tab", "<a href='#otherNonCodingRNAs' data-toggle='tab'>Other non-coding RNAs</a>", "");
SQL
}
if($annotation_alienhunter) {
    $scriptSQL .= <<SQL;
                INSERT INTO TEXTS(tag, value, details) VALUES 
                    ("search-database-dna-based-analyses-tab", "<a href='#horizontalGeneTransfers' data-toggle='tab'>Horizontal gene transfers</a>", ""),
                    ("search-database-dna-based-analyses-predicted-alienhunter", "Get predicted AlienHunter regions of length: ", ""),
                    ("search-database-dna-based-analyses-or-get-regions-score", "Or get regions of score: ", ""),
                    ("search-database-dna-based-analyses-or-get-regions-threshold", "Or get regions of threshold: ", "");
SQL
}
if($annotation_rnammer) {
    $scriptSQL .= <<SQL;
                INSERT INTO TEXTS(tag, value, details) VALUES
                    ("search-database-dna-based-analyses-tab", "<a href='#rrna' data-toggle='tab'>rRNA</a>", ""), 
                    ("search-database-dna-based-analyses-get-by-rrna-type", "Get rRNAs by type: ", "");
SQL
}
if($annotation_trna) {
    $scriptSQL .= <<SQL;
                INSERT INTO TEXTS(tag, value, details) VALUES 
                    ("search-database-dna-based-analyses-tab", "<a href='#trna' data-toggle='tab'>tRNA</a>", ""),
                    ("search-database-dna-based-analyses-get-by-amino-acid", "Get tRNAs by amino acid: ", ""),
                    ("search-database-dna-based-analyses-get-by-amino-acid-options", "<option value='Ala'>Alanine (A)</option>", ""),                                                                                                
                    ("search-database-dna-based-analyses-get-by-amino-acid-options", "<option value='Arg'>Arginine (R)</option>", ""),                                                                                               
                    ("search-database-dna-based-analyses-get-by-amino-acid-options", "<option value='Asp'>Asparagine (N)</option>", ""),                                                                                             
                    ("search-database-dna-based-analyses-get-by-amino-acid-options", "<option value='Ala'>Aspartic acid (D)</option>", ""),                                                                                          
                ("search-database-dna-based-analyses-get-by-amino-acid-options", "<option value='Cys'>Cysteine (C)</option>", ""),                                                                                               
                                ("search-database-dna-based-analyses-get-by-amino-acid-options", "<option value='Glu'>Glutamic acid (E)</option>", ""),                                                                                          
                                ("search-database-dna-based-analyses-get-by-amino-acid-options", "<option value='Gln'>Glutamine (Q)</option>", ""),                                                                                              
                                ("search-database-dna-based-analyses-get-by-amino-acid-options", "<option value='Gly'>Glycine (G)</option>", ""),                                                                                                
                                ("search-database-dna-based-analyses-get-by-amino-acid-options", "<option value='His'>Histidine (H)</option>", ""),                                                                                              
                                ("search-database-dna-based-analyses-get-by-amino-acid-options", "<option value='Ile'>Isoleucine (I)</option>", ""),
                                ("search-database-dna-based-analyses-get-by-amino-acid-options", "<option value='Leu'>Leucine (L)</option>", ""),
                                ("search-database-dna-based-analyses-get-by-amino-acid-options", "<option value='Lys'>Lysine (K)</option>", ""),
                                ("search-database-dna-based-analyses-get-by-amino-acid-options", "<option value='Met'>Methionine (M)</option>", ""),
                                ("search-database-dna-based-analyses-get-by-amino-acid-options", "<option value='Phe'>Phenylalanine (F)</option>", ""),
                                ("search-database-dna-based-analyses-get-by-amino-acid-options", "<option value='Pro'>Proline (P)</option>", ""),
                                ("search-database-dna-based-analyses-get-by-amino-acid-options", "<option value='Ser'>Serine (S)</option>", ""),
                                ("search-database-dna-based-analyses-get-by-amino-acid-options", "<option value='Thr'>Threonine (T)</option>", ""),
                                ("search-database-dna-based-analyses-get-by-amino-acid-options", "<option value='Trp'>Tryptophan (W)</option>", ""),
                                ("search-database-dna-based-analyses-get-by-amino-acid-options", "<option value='Tyr'>Tyrosine (Y)</option>", ""),
                                ("search-database-dna-based-analyses-get-by-amino-acid-options", "<option value='Val'>Valine (V)</option>", ""),
                    ("search-database-dna-based-analyses-get-by-codon", "Or get tRNAs by codon: ", ""),
                ("search-database-dna-based-analyses-get-by-codon-options", "<option value='AAA'>AAA</option>", "<option value='AAA'>AAA</option>"),                                            
                                ("search-database-dna-based-analyses-get-by-codon-options", "<option value='AAC'>AAC</option>", "<option value='AAC'>AAC</option>"), 
                                ("search-database-dna-based-analyses-get-by-codon-options", "<option value='AAG'>AAG</option>", "<option value='AAG'>AAG</option>"),
                                ("search-database-dna-based-analyses-get-by-codon-options", "<option value='AAT'>AAT</option>", "<option value='AAT'>AAT</option>"),
                                ("search-database-dna-based-analyses-get-by-codon-options", "<option value='ACA'>ACA</option>", "<option value='ACA'>ACA</option>"),
                                ("search-database-dna-based-analyses-get-by-codon-options", "<option value='ACC'>ACC</option>", "<option value='ACC'>ACC</option>"),
                                ("search-database-dna-based-analyses-get-by-codon-options", "<option value='ACG'>ACG</option>", "<option value='ACG'>ACG</option>"),
                                ("search-database-dna-based-analyses-get-by-codon-options", "<option value='ACT'>ACT</option>", "<option value='ACT'>ACT</option>"),
                                ("search-database-dna-based-analyses-get-by-codon-options", "<option value='AGA'>AGA</option>", "<option value='AGA'>AGA</option>"),
                                ("search-database-dna-based-analyses-get-by-codon-options", "<option value='AGC'>AGC</option>", "<option value='AGC'>AGC</option>"),
                                ("search-database-dna-based-analyses-get-by-codon-options", "<option value='AGG'>AGG</option>", "<option value='AGG'>AGG</option>"),
                                ("search-database-dna-based-analyses-get-by-codon-options", "<option value='AGT'>AGT</option>", "<option value='AGT'>AGT</option>"),
                                ("search-database-dna-based-analyses-get-by-codon-options", "<option value='ATA'>ATA</option>", "<option value='ATA'>ATA</option>"),
                                ("search-database-dna-based-analyses-get-by-codon-options", "<option value='ATC'>ATC</option>", "<option value='ATC'>ATC</option>"),
                                ("search-database-dna-based-analyses-get-by-codon-options", "<option value='ATG'>ATG</option>", "<option value='ATG'>ATG</option>"),
                                ("search-database-dna-based-analyses-get-by-codon-options", "<option value='ATT'>ATT</option>", "<option value='ATT'>ATT</option>"),
                                ("search-database-dna-based-analyses-get-by-codon-options", "<option value='CAA'>CAA</option>", "<option value='CAA'>CAA</option>"),
                                ("search-database-dna-based-analyses-get-by-codon-options", "<option value='CAC'>CAC</option>", "<option value='CAC'>CAC</option>"),
                                ("search-database-dna-based-analyses-get-by-codon-options", "<option value='CAG'>CAG</option>", "<option value='CAG'>CAG</option>"),
                                ("search-database-dna-based-analyses-get-by-codon-options", "<option value='CAT'>CAT</option>", "<option value='CAT'>CAT</option>"),
                                ("search-database-dna-based-analyses-get-by-codon-options", "<option value='CCA'>CCA</option>", "<option value='CCA'>CCA</option>"),
                                ("search-database-dna-based-analyses-get-by-codon-options", "<option value='CCC'>CCC</option>", "<option value='CCC'>CCC</option>"),
                                ("search-database-dna-based-analyses-get-by-codon-options", "<option value='CCG'>CCG</option>", "<option value='CCG'>CCG</option>"),
                                ("search-database-dna-based-analyses-get-by-codon-options", "<option value='CCT'>CCT</option>", "<option value='CCT'>CCT</option>"),
                                ("search-database-dna-based-analyses-get-by-codon-options", "<option value='CGA'>CGA</option>", "<option value='CGA'>CGA</option>"),
                                ("search-database-dna-based-analyses-get-by-codon-options", "<option value='CGC'>CGC</option>", "<option value='CGC'>CGC</option>"),
                                ("search-database-dna-based-analyses-get-by-codon-options", "<option value='CGG'>CGG</option>", "<option value='CGG'>CGG</option>"),
                                ("search-database-dna-based-analyses-get-by-codon-options", "<option value='CGT'>CGT</option>", "<option value='CGT'>CGT</option>"),
                                ("search-database-dna-based-analyses-get-by-codon-options", "<option value='CTA'>CTA</option>", "<option value='CTA'>CTA</option>"),
                                ("search-database-dna-based-analyses-get-by-codon-options", "<option value='CTC'>CTC</option>", "<option value='CTC'>CTC</option>"),
                                ("search-database-dna-based-analyses-get-by-codon-options", "<option value='CTG'>CTG</option>", "<option value='CTG'>CTG</option>"),
                                ("search-database-dna-based-analyses-get-by-codon-options", "<option value='CTT'>CTT</option>", "<option value='CTT'>CTT</option>"),
                                ("search-database-dna-based-analyses-get-by-codon-options", "<option value='GAA'>GAA</option>", "<option value='GAA'>GAA</option>"),
                                ("search-database-dna-based-analyses-get-by-codon-options", "<option value='GAC'>GAC</option>", "<option value='GAC'>GAC</option>"),
                                ("search-database-dna-based-analyses-get-by-codon-options", "<option value='GAG'>GAG</option>", "<option value='GAG'>GAG</option>"),
                                ("search-database-dna-based-analyses-get-by-codon-options", "<option value='GAT'>GAT</option>", "<option value='GAT'>GAT</option>"),
                                ("search-database-dna-based-analyses-get-by-codon-options", "<option value='GCA'>GCA</option>", "<option value='GCA'>GCA</option>"),
                                ("search-database-dna-based-analyses-get-by-codon-options", "<option value='GCC'>GCC</option>", "<option value='GCC'>GCC</option>"),
                                ("search-database-dna-based-analyses-get-by-codon-options", "<option value='GCG'>GCG</option>", "<option value='GCG'>GCG</option>"),
                                ("search-database-dna-based-analyses-get-by-codon-options", "<option value='GCT'>GCT</option>", "<option value='GCT'>GCT</option>"),
                                ("search-database-dna-based-analyses-get-by-codon-options", "<option value='GGA'>GGA</option>", "<option value='GGA'>GGA</option>"),
                                ("search-database-dna-based-analyses-get-by-codon-options", "<option value='GGC'>GGC</option>", "<option value='GGC'>GGC</option>"),
                                ("search-database-dna-based-analyses-get-by-codon-options", "<option value='GGG'>GGG</option>", "<option value='GGG'>GGG</option>"),
                                ("search-database-dna-based-analyses-get-by-codon-options", "<option value='GGT'>GGT</option>", "<option value='GGT'>GGT</option>"),
                                ("search-database-dna-based-analyses-get-by-codon-options", "<option value='GTA'>GTA</option>", "<option value='GTA'>GTA</option>"),
                                ("search-database-dna-based-analyses-get-by-codon-options", "<option value='GTC'>GTC</option>", "<option value='GTC'>GTC</option>"),
                                ("search-database-dna-based-analyses-get-by-codon-options", "<option value='GTG'>GTG</option>", "<option value='GTG'>GTG</option>"),
                                ("search-database-dna-based-analyses-get-by-codon-options", "<option value='GTT'>GTT</option>", "<option value='GTT'>GTT</option>"),
                                ("search-database-dna-based-analyses-get-by-codon-options", "<option value='TAC'>TAC</option>", "<option value='TAC'>TAC</option>"),
                                ("search-database-dna-based-analyses-get-by-codon-options", "<option value='TAT'>TAT</option>", "<option value='TAT'>TAT</option>"),
                                ("search-database-dna-based-analyses-get-by-codon-options", "<option value='TCA'>TCA</option>", "<option value='TCA'>TCA</option>"),
                                ("search-database-dna-based-analyses-get-by-codon-options", "<option value='TCC'>TCC</option>", "<option value='TCC'>TCC</option>"),
                                ("search-database-dna-based-analyses-get-by-codon-options", "<option value='TCG'>TCG</option>", "<option value='TCG'>TCG</option>"),
                                ("search-database-dna-based-analyses-get-by-codon-options", "<option value='TCT'>TCT</option>", "<option value='TCT'>TCT</option>"),
                                ("search-database-dna-based-analyses-get-by-codon-options", "<option value='TGC'>TGC</option>", "<option value='TGC'>TGC</option>"),
                                ("search-database-dna-based-analyses-get-by-codon-options", "<option value='TGG'>TGG</option>", "<option value='TGG'>TGG</option>"),
                                ("search-database-dna-based-analyses-get-by-codon-options", "<option value='TGT'>TGT</option>", "<option value='TGT'>TGT</option>"),
                                ("search-database-dna-based-analyses-get-by-codon-options", "<option value='TTA'>TTA</option>", "<option value='TTA'>TTA</option>"),
                                ("search-database-dna-based-analyses-get-by-codon-options", "<option value='TTC'>TTC</option>", "<option value='TTC'>TTC</option>"),
                                ("search-database-dna-based-analyses-get-by-codon-options", "<option value='TTG'>TTG</option>", "<option value='TTG'>TTG</option>"),
                                ("search-database-dna-based-analyses-get-by-codon-options", "<option value='TTT'>TTT</option>", "<option value='TTT'>TTT</option>");
SQL
}

#my $help;
my $filepath = `pwd`;
chomp $filepath;
my $databaseFilepath =
$filepath . "/" . $standard_dir . "/" . $html_dir . "/database.db";
`mkdir -p "$filepath"/"$standard_dir"/"$html_dir"`;

#my $optret = GetOptions(
#	"h|help"     => \$help,
#	"name=s"     => \$nameProject,
#	"database=s" => \$databaseFilepath
#);

#my $helpMessage = <<HELP;
#
###### report_html_db.pl - In development stage 19/06/2016 - Wendel Hime #####
#
#Project of scientific iniciation used to generate site based on content of evidences and results of analysis.
#
#Usage:  report_html_db.pl -name <Name site>
#
#
#Mandatory parameters:
#
#Optional parameters:
#
#-h          Print this help message and exit
#
#-name = html_dir      Name of the site or project to be created
#
#-database = database.db     Filepath to be used like static contents of the project
#
#HELP
#
#if ( $help ) {
#	print $helpMessage;
#	exit;
#}

#path catalyst file
my $pathCatalyst = `which catalyst.pl`;
unless ($pathCatalyst) {
    print $LOG
    "\nCatalyst not found, please install dependences:\ncpan DBIx::Class Catalyst::Devel Catalyst::Runtime Catalyst::View::TT Catalyst::View::JSON Catalyst::Model::DBIC::Schema DBIx::Class::Schema::Loader MooseX::NonMoose\n";
    exit;
}
chomp $pathCatalyst;

#give permission to execute catalyst.pl
#chmod( "755", $pathCatalyst );
#`chmod 755 $pathCatalyst`;
my $packageWebsite = $html_dir;
$packageWebsite =~ s/-/::/; 
my $packageServices = $services_dir; 
$packageServices =~ s/-/::/; 
print $LOG "\nCreating website...\n";
`$pathCatalyst $packageWebsite`;
print $LOG "\nCreating services...\n";
`$pathCatalyst $packageServices`;

my $libDirectoryWebsite = $html_dir;
my $libDirectoryServices = $services_dir;
$libDirectoryWebsite =~ s/-/\//;
$libDirectoryServices =~ s/-/\//;
my $lowCaseName = $html_dir;
$lowCaseName = lc $lowCaseName;
$lowCaseName =~ s/-/_/g;

#give permission to execute files script
#chmod("111", "$nameProject/script/".$lowCaseName."_server.pl");
#chmod("111", "$nameProject/script/".$lowCaseName."_create.pl");
#create view
open(my $FILEHANDLER, ">>", "$html_dir/$lowCaseName.conf");
print $FILEHANDLER "\ncomponents_ev " . join(".pl ", keys %hash_ev) . "\n";
close($FILEHANDLER);
print $LOG "\nCreating view\n";
`./$html_dir/script/"$lowCaseName"_create.pl view TT TT`;
if($report_feature_table_submission) {
    my @files = glob( $report_feature_table_submission . "/*.gb");
    use Archive::Zip qw( :ERROR_CODES :CONSTANTS );
    my $zip = Archive::Zip->new();
    $zip->addFile( $_, getFilenameByFilepath($_) ) foreach @files;
    print $LOG "\n[1962] submission - $_\n" foreach @files;
    `mkdir -p $standard_dir/$html_dir/root`;
    unless ( $zip->writeToFileNamed("$standard_dir/$html_dir/root/feature_table_submission.zip") == AZ_OK ) {
        die 'error';
    }
    $scriptSQL .= "\nINSERT INTO TEXTS(tag, value, details) VALUES 
    ('downloads-annotations-links-1', 'Feature Table', '/DownloadFile?type=ftb');\nINSERT INTO FILES(tag, filepath, details) VALUES ('ftb', 'feature_table_submission.zip', '');\n";
}
if($report_feature_table_artemis) {
    my @files = glob( $report_feature_table_artemis . "/*all_results.tab");
    use Archive::Zip qw( :ERROR_CODES :CONSTANTS );
    my $zip = Archive::Zip->new();
    $zip->addFile( $_, getFilenameByFilepath($_) ) foreach @files;
    print $LOG "\n[1972] artemis - $_\n" foreach @files;
    `mkdir -p $standard_dir/$html_dir/root`;
    unless ( $zip->writeToFileNamed("$standard_dir/$html_dir/root/feature_table_artemis.zip") == AZ_OK ) {
        die 'error';
    } 
    $scriptSQL .= "\nINSERT INTO TEXTS(tag, value, details) VALUES 
    ('downloads-annotations-links-2', 'Extended Feature Table', '/DownloadFile?type=eft');\nINSERT INTO FILES(tag, filepath, details) VALUES ('eft', 'feature_table_artemis.zip', '');\n"; 
}
if($report_gff) {
    my @files = glob( $report_gff . "/*");
    use Archive::Zip qw( :ERROR_CODES :CONSTANTS );
    my $zip = Archive::Zip->new();
    $zip->addFile( $_, getFilenameByFilepath($_) ) foreach @files;
    print $LOG "\n[1982] gff3 - $_\n" foreach @files;
    `mkdir -p $standard_dir/$html_dir/root`;
    unless ( $zip->writeToFileNamed("$standard_dir/$html_dir/root/gff3.zip") == AZ_OK ) {
        die 'error';
    }
    $scriptSQL .= "\nINSERT INTO TEXTS(tag, value, details) VALUES 
    ('downloads-annotations-links-3', 'GFF3', '/DownloadFile?type=gff');\nINSERT INTO FILES(tag, filepath, details) VALUES ('gff', 'gff3.zip', '');\n"; 
} 

if(defined $report_feature_table_submission ||
    defined $report_feature_table_artemis ||
    defined $report_gff ) {
    $scriptSQL .= "\nINSERT INTO TEXTS(tag, value, details) VALUES
    ('downloads-annotations', 'Annotations', '');\n";
}

my $fileHandler;
open( $fileHandler, "<", "$html_dir/lib/$libDirectoryWebsite/View/TT.pm" );
my $contentToBeChanged =
"__PACKAGE__->config(\n\tTEMPLATE_EXTENSION\t=>\t'.tt',\n\tTIMER\t=>\t0,\n\tWRAPPER\t=>\t'$lowCaseName/_layout.tt',\n\tENCODING\t=>\t'utf-8',\n\trender_die\t=> 1,\n);";
my $data = do { local $/; <$fileHandler> };
$data =~ s/__\w+->config\(([\w\s=>''"".,\/]*)\s\);/$contentToBeChanged/igm;
close($fileHandler);
print $LOG "\nEditing view\n";
writeFile( "$html_dir/lib/$libDirectoryWebsite/View/TT.pm", $data );

#if database file exists, delete
if ( -e $databaseFilepath ) {
    unlink $databaseFilepath;
}

#add resources to the config file
open( $fileHandler, ">>", "$html_dir/$lowCaseName.conf" );
print $fileHandler "\ntarget_class_id "
. $type_target_class_id
. "\n";
close($fileHandler);

my $lowCaseNameServices = $services_dir;
$lowCaseNameServices = lc $services_dir;
$lowCaseNameServices =~ s/-/_/; 
open($fileHandler, ">>", "$services_dir/$lowCaseNameServices.conf");
print $fileHandler "\nannotations_dir " . $annotation_dir;
close($fileHandler);

#create the file sql to be used
print $LOG "\nCreating SQL file\tscript.sql\n";
$scriptSQL .= "\nCOMMIT;\n";
writeFile( "script.sql", $scriptSQL );

#create file database
print $LOG "\nCreating database file\t$databaseFilepath\n";
`sqlite3 $databaseFilepath < script.sql`;

#create models project
print $LOG "\nCreating models\n";
`$html_dir/script/"$lowCaseName"_create.pl model Basic DBIC::Schema "$packageWebsite"::Basic create=static "dbi:SQLite:$databaseFilepath" on_connect_do="PRAGMA foreign_keys = ON;PRAGMA encoding='UTF-8'"`;

my %models = (
    "BaseResponse" => <<BASERESPONSE,
use strict;
use warnings;
use base 'Catalyst::Model::Adaptor';

__PACKAGE__->config( 
    class       => 'Report_HTML_DB::Models::Services::BaseResponse',
    constructor => 'new',
);

1;
BASERESPONSE
    "PagedResponse" => <<PAGEDRESPONSE,
use strict;
use warnings;
use base 'Catalyst::Model::Adaptor';

__PACKAGE__->config( 
    class       => 'Report_HTML_DB::Models::Services::PagedResponse',
    constructor => 'new',
);

1;	
PAGEDRESPONSE
    "Feature" => <<FEATURE,
use strict;
use warnings;
use base 'Catalyst::Model::Adaptor';

__PACKAGE__->config( 
    class       => 'Report_HTML_DB::Models::Application::Feature',
    constructor => 'new',
);

1;
FEATURE

    "Subevidence" => <<SUBEVIDENCE,
use strict;
use warnings;
use base 'Catalyst::Model::Adaptor';

__PACKAGE__->config( 
    class       => 'Report_HTML_DB::Models::Application::Subevidence',
    constructor => 'new',
);

1;
SUBEVIDENCE
    "TRFSearch" => <<TRFSEARCH,
use strict;
use warnings;
use base 'Catalyst::Model::Adaptor';

__PACKAGE__->config( 
    class       => 'Report_HTML_DB::Models::Application::TRFSearch',
    constructor => 'new',
);

1;
TRFSEARCH
    "TRNASearch" => <<TRNASEARCH,
use strict;
use warnings;
use base 'Catalyst::Model::Adaptor';

__PACKAGE__->config( 
    class       => 'Report_HTML_DB::Models::Application::TRNASearch',
    constructor => 'new',
);

1;

TRNASEARCH
    "SearchDBClient" => <<CLIENTS,
use strict;
use warnings;
use base 'Catalyst::Model::Adaptor';

__PACKAGE__->config(
    class		=> 'Report_HTML_DB::Clients::SearchDBClient',
    constructor	=> 'new',
);

1;

CLIENTS

    "BlastClient" => <<CLIENTS,
use strict;
use warnings;
use base 'Catalyst::Model::Adaptor';

__PACKAGE__->config(
    class		=> 'Report_HTML_DB::Clients::BlastClient',
    constructor	=> 'new',
);

1;

CLIENTS
);

foreach my $key ( keys %models ) {
    my $package_website = "package " . $packageWebsite . "::Model::" . $key . ";";
    my $package_services =
    "package " . $packageServices . "::Model::" . $key . ";";
    my $content_website = $package_website . "\n" . $models{$key};
    writeFile( "$html_dir/lib/$libDirectoryWebsite/Model/" . $key . ".pm",
        $content_website );
    writeFile( "$services_dir/lib/$libDirectoryServices/Model/" . $key . ".pm",
        $package_services . "\n" . $models{$key} );

}

#`$nameProject/script/"$lowCaseName"_create.pl model Chado DBIC::Schema "$nameProject"::Chado create=static "dbi:Pg:dbname=$dbName;host=$dbHost" "$dbUser" "$dbPassword"`;

my $hadGlobal         = 0;
my $hadSearchDatabase = 0;
foreach my $component ( sort keys %components ) {
    if ( scalar @reports_global_analyses > 0 )
    {
        $hadGlobal = 1;
    }
    if ( $component =~ m/annotation/gi ) {
        $hadSearchDatabase = 1;
    }
}

#####
#
#	Add relationship to models
#
#####
my $packageDBI = $packageServices . "::Model::SearchDatabaseRepository";
my $DBI        = <<DBI;
package $packageDBI;


use strict;
use warnings;
use parent 'Catalyst::Model::DBI';

__PACKAGE__->config(
    dsn      => "dbi:Pg:dbname=$dbName;host=$dbHost",
    user     => "$dbUser",
    password => "$dbPassword",
    options  => {},
);

=head2 getPipeline

  Title    : getPipeline
  Usage    : my \$results = \$my_object->getPipeline();
  Function : Method used to get pipeline from database
  Returns  : Reference to a hash
           :
=cut

sub getPipeline {
    my ( \$self ) = \@_;
    my \$dbh = \$self->dbh;
    my \$query = "select distinct p.value as value
    from feature_relationship r
    join featureloc l on (r.subject_id = l.feature_id)
    join featureprop p on (p.feature_id = l.srcfeature_id)
    join cvterm cp on (p.type_id = cp.cvterm_id)
    WHERE cp.name='pipeline_id';";
    my \$sth = \$dbh->prepare(\$query);
    print STDERR \$query;
    \$sth->execute();
    my \@rows = \@{ \$sth->fetchall_arrayref() };
    my \%returnedHash = ();

    for ( my \$i = 0 ; \$i < scalar \@rows ; \$i++ ) {
        \$returnedHash{pipeline_id} = \$rows[\$i][0];
    }

    return \\\%returnedHash;
}

=head2 getRibosomalRNAs

  Title    : getRibosomalRNAs
  Usage    : my \$results = \$my_object->getRibosomalRNAs( -hash => \%{ ( "pipeline_id" => "4528" ) } );
  Function : Method used to get rRNAs availables in the sequence
  Returns  : list reference of rRNAs available
  Args     : named arguments:
           : -hash => referenced hash with pipeline_id property
           :
=cut

sub getRibosomalRNAs {
    my ( \$self, \$hash ) = \@_;
    my \$dbh = \$self->dbh;
    my \@args = ();
    my \$query = "select distinct pd.value AS name 
    from feature f 
    join feature_relationship r on (f.feature_id = r.object_id) 
    join cvterm cr on (r.type_id = cr.cvterm_id) 
    join featureprop ps on (r.subject_id = ps.feature_id) 
    join cvterm cs on (ps.type_id = cs.cvterm_id) 
    join featureprop pf on (f.feature_id = pf.feature_id) 
    join cvterm cf on (pf.type_id = cf.cvterm_id) 
    join featureloc l on (l.feature_id = f.feature_id) 
    join featureprop pl on (l.srcfeature_id = pl.feature_id) 
    join cvterm cp on (pl.type_id = cp.cvterm_id) 
    join featureprop pd on (r.subject_id = pd.feature_id) 
    join cvterm cd on (pd.type_id = cd.cvterm_id) 
    where cr.name = 'based_on' and cf.name = 'tag' and pf.value='rRNA_prediction' and cs.name = 'locus_tag' and cd.name = 'description' and cp.name = 'pipeline_id' and pl.value=? ORDER BY pd.value ASC ;";
    push \@args, \$hash->{pipeline};
    my \$sth = \$dbh->prepare(\$query);
    print STDERR \$query;
    \$sth->execute(\@args);
    my \@rows = \@{ \$sth->fetchall_arrayref() };
    my \@list = ();
    for ( my \$i = 0 ; \$i < scalar \@rows ; \$i++ ) {
        push \@list, \$rows[\$i][0];
    }
    return \\\@list;
}

=head2 analyses_CDS

  Title    : analyses_CDS
  Usage    : my \$results = \$my_object->analyses_CDS( -hash => \%{ (
    "pipeline" => "4528"
  ) } );
  Function : Method used to realize search based on parameters received by form of analyses of protein-coding genes
  Returns  : Return a referenced hash with a list of feature IDs and total number of results
  Args     : named arguments:
           : -hash => referenced hash with the following properties:
| Key | Description |
| :-- | :-- |
| pipeline | Scalar variable with pipeline ID |
| contig | Scalar variable with feature ID from contig |
| geneDesc | Scalar variable which realize search by all CDS with this description |
| noDesc | Scalar variable which realize search by all CDS that doesn’t have this description |
| individually | Scalar variable which make all terms from geneDesc and noDesc match  |
| noGO | Scalar variable, if you don’t want to have results related to GO annotation |
| goID | Scalar variable with GO Identifier  |
| goDesc | Scalar variable with GO Description  |
| noTC | Scalar variable, if you don’t want to have results related to TCDB annotation  |
| tcdbID | Scalar variable with TCDB ID  |
| tcdbFam | Scalar variable with TCDB Family |
| tcdbSubclass | Scalar variable with TCDB subclass  |
| tcdbClass | Scalar variable with TCDB class  |
| tcdbDesc | Scalar variable with TCDB description  |
| noBlast | Scalar variable, if you don’t want to have results related to BLAST annotations  |
| blastID | Scalar variable with BLAST identifier  |
| blastDesc | Scalar variable with BLAST description  |
| noRps | Scalar variable, if you don’t want to have results related to RPS-BLAST annotations  |
| rpsID | Scalar variable with RPS-BLAST Identifier  |
| rpsDesc | Scalar variable with RPS-BLAST Description  |
| noKEGG | Scalar variable, if you don’t want to have results related to KEGG annotations  |
| koID | Scalar variable with KEGG Identifier  |
| keggPath | Scalar variable with KEGG Pathway |
| keggDesc | Scalar variable with KEGG description  |
| noOrth | Scalar variable, if you don’t want to see results related to orthology annotations.  |
| orthID | Scalar variable with orthology Identifier  |
| orthDesc | Scalar variable with orthology description  |
| noIP | Scalar variable, if you don’t want to see results related to InterProScan annotations.  |
| interproID | Scalar variable with InterProScan identifier  |
| interproDesc | Scalar variable with InterProScan description  |
| noTMHMM | Scalar variable, if you don’t want results related to TMHMM annotations.  |
| TMHMMdom | Scalar variable with number of transmembrane domains  |
| tmhmmQuant | Scalar variable which auxiliate search of TMHMMdom, if you want exatly value: “exact”, less: “orLess”, more: “orMore”, or none: "none" |
| noDGPI | Scalar variable, if you don’t want results related to DGPI annotations.  |
| cleavageSiteDGPI | Scalar variable with cleavage site from DGPI  |
| scoreDGPI | Scalar variable with score from DGPI  |
| cleavageQuant | Scalar variable which auxiliate search of cleavageSiteDGPI, if you want exatly value: “exact”, less: “orLess”, more: “orMore”, or none: "none"  |
| scoreQuant | Scalar variable which auxiliate search of scoreDGPI, if you want exatly value: “exact”, less: “orLess”, more: “orMore”, or none: "none"  |
| noPreDGPI | Scalar variable, if you don’t want results related to PreDGPI annotations.  |
| namePreDGPI | Scalar variable with name of PreDGPI  |
| positionPreDGPI | Scalar variable with position from PreDGPI  |
| positionQuantPreDGPI | Scalar variable which auxiliate search of positionPreDGPI, if you want exatly value: “exact”, less: “orLess”, more: “orMore”, or none: "none"  |
| specificityPreDGPI | Scalar variable specifity from PreDGPI  |
| specificityQuantPreDGPI | Scalar variable which auxiliate search of specificityPreDGPI, if you want exatly value: “exact”, less: “orLess”, more: “orMore”, or none: "none"  |
| sequencePreDGPI | Scalar variable with sequence to compare with PreDGPI annotations  |
| noBigGPI | Scalar variable, if you don’t want results related to BiGPI annotations.  |
| pvalueBigpi | Scalar variable value from BiGPI  |
| pvalueQuantBigpi | Scalar variable which auxiliate search of quantity BiGPI, if you want exatly value: “exact”, less: “orLess”, more: “orMore”, or none: "none"  |
| positionBigpi | Scalar variable value with the position of BiGPI annotation  |
| positionQuantBigpi | Scalar variable which auxiliate search of position BiGPI, if you want exatly value: “exact”, less: “orLess”, more: “orMore”, or none: "none"  |
| noPhobius | Scalar variable, if you don’t want results related to Phobius annotations.  |
| TMdom | Scalar vairable, quantity of transmembrane domains  |
| tmQuant | Scalar variable which auxiliate search of parameter TMdom, if you want exatly value: “exact”, less: “orLess”, more: “orMore”, or none: "none"  |
| sigP | Scalar variable if you want the phobius with result with signal peptide. If you don’t care: “sigPwhatever”, if you want: “sigPyes”, if you don’t want: “sigPno”  |
| pageSize | Scalar variable with the page size |
| offset | Scalar variable with the offset |
| components | Scalar variable with annotation component names used |            
           :


=cut

sub analyses_CDS {
    my ( \$self, \$hash ) = \@_;
    my \$dbh  = \$self->dbh;
    my \@args = ();
    my \$query = "SELECT motherfuckerquery.feature_id, COUNT(*) OVER() FROM "
    . "((select distinct f.feature_id "
    . "from feature f "
    . "join feature_relationship r on (f.feature_id = r.object_id) "
    . "join cvterm cr on (r.type_id = cr.cvterm_id) "
    . "join featureprop ps on (r.subject_id = ps.feature_id) "
    . "join cvterm cs on (ps.type_id = cs.cvterm_id) "
    . "join featureprop pf on (f.feature_id = pf.feature_id) "
    . "join cvterm cf on (pf.type_id = cf.cvterm_id) "
    . "join featureloc l on (l.feature_id = f.feature_id) "
    . "join featureprop pl on (l.srcfeature_id = pl.feature_id) "
    . "join cvterm cp on (pl.type_id = cp.cvterm_id) "
    . "join featureprop pd on (r.subject_id = pd.feature_id) "
    . "join cvterm cd on (pd.type_id = cd.cvterm_id) "
    . "where cr.name = 'based_on' and cf.name = 'tag' and pf.value='CDS' and cs.name = 'locus_tag' and cd.name = 'description' and cp.name = 'pipeline_id' and pl.value=? ";
    push \@args, \$hash->{pipeline};

    if(exists \$hash->{contig} && \$hash->{contig}) {
        \$query .= " and l.srcfeature_id = ? ) ";
        push \@args, \$hash->{contig};
    } else {
        \$query .= " ) ";
    }

    my \$connector = "1";

    my \$query_gene     = "";
    my \$query_GO       = "";
    my \$query_TCDB     = "";
    my \$query_Phobius  = "";
    my \$query_sigP     = "";
    my \$query_blast    = "";
    my \$query_RPS      = "";
    my \$query_KEGG     = "";
    my \$query_ORTH     = "";
    my \$query_interpro = "";
    my \$query_tmhmm    = "";
    my \$query_dgpi	    = "";
    my \$query_predgpi  = "";
    my \$query_bigpi	= "";
    my \%components = ();
    if(exists \$hash->{components}) {
        \%components =  (\$hash->{components} =~ /,/) ? map { \$_ => 1} split(",", \$hash->{components}) : (\$hash->{components} => 1 );
    }

    if (   ( exists \$hash->{geneDesc} && \$hash->{geneDesc} )
        || ( exists \$hash->{noDesc} && \$hash->{noDesc} ) )
    {
        my \$and = "";
        \$query_gene =
        "(SELECT DISTINCT f.feature_id "
        . "FROM feature f JOIN feature_relationship r ON (f.feature_id = r.object_id) "
        . "JOIN cvterm cr ON (r.type_id = cr.cvterm_id) "
        . "JOIN featureloc l ON (l.feature_id = f.feature_id) "
        . "JOIN featureprop pl ON (l.srcfeature_id = pl.feature_id) "
        . "JOIN cvterm cp ON (pl.type_id = cp.cvterm_id) "
        . "JOIN featureprop pd ON (r.subject_id = pd.feature_id) "
        . "JOIN cvterm cd ON (pd.type_id = cd.cvterm_id) "
        . "WHERE cr.name = 'based_on' AND cd.name = 'description' AND cp.name = 'pipeline_id' AND pl.value=? AND ";
        push \@args, \$hash->{pipeline};
        \$connector = " INTERSECT " if \$connector;

        if ( exists \$hash->{geneDesc} && \$hash->{geneDesc} ) {
            \$query_gene .= generate_clause( "?", "", "", "lower(pd.value)" );
            push \@args, lc("\%".\$hash->{geneDesc} . "\%");
            \$and = " AND ";
        }
        if ( exists \$hash->{noDesc} && \$hash->{noDesc} ) {
            \$query_gene .=
            generate_clause( "?", "NOT", \$and, "lower(pd.value)" );
            push \@args, "\%" . lc( \$hash->{noDesc} ) . "\%";
        }

        if (   ( exists \$hash->{geneDescription} && \$hash->{geneDescription} )
            || ( exists \$hash->{noDescription} && \$hash->{noDescription} ) )
        {
            my \@likesDescription   = ();
            my \@likesNoDescription = ();
            if ( \$hash->{geneDescription} ) {
                while ( \$hash->{geneDescription} =~ /(\\S+)/g ) {
                    push \@likesDescription,
                    generate_clause( "?", "", "",
                        "lower(pd.value)"
                    );
                    push \@args, lc( "\%" . \$1 . "\%" );
                }
            }
            if ( \$hash->{noDescription} ) {
                while ( \$hash->{noDescription} =~ /(\\S+)/g ) {
                    push \@likesNoDescription,
                    generate_clause( "?", "NOT", "",
                        "lower(pd.value)"
                    );
                    push \@args, lc( "\%" . \$1 . "\%" );
                }
            }

            if (    exists \$hash->{individually}
                    and \$hash->{individually}
                    and scalar(\@likesDescription) > 0 )
            {
                if ( scalar(\@likesNoDescription) > 0 ) {
                    foreach my \$like (\@likesDescription) {
                        \$query_gene .= " AND " . \$like;
                    }
                    foreach my \$notLike (\@likesNoDescription) {
                        \$query_gene .= " AND " . \$notLike;
                    }
                }
                else {
                    foreach my \$like (\@likesDescription) {
                        \$query_gene .= " AND " . \$like;
                    }
                }
            }
            elsif ( scalar(\@likesDescription) > 0 ) {
                my \$and = "";
                if ( scalar(\@likesNoDescription) > 0 ) {
                    foreach my \$notLike (\@likesNoDescription) {
                        \$query_gene .= " AND " . \$notLike;
                    }
                    \$and = "1";
                }
                if (\$and) {
                    \$and = " AND ";
                }
                else {
                    \$and = " OR ";
                }
                \$query_gene .= " AND (";
                my \$counter = 0;
                foreach my \$like (\@likesDescription) {
                    if ( \$counter == 0 ) {
                        \$query_gene .= \$like;
                        \$counter++;
                    }
                    else {
                        \$query_gene .= \$and . \$like;
                    }
                }
                \$query_gene .= " ) ";
            }
            elsif ( scalar(\@likesDescription) <= 0
                    and scalar(\@likesNoDescription) > 0 )
            {
                foreach my \$like (\@likesNoDescription) {
                    \$query_gene .= " AND " . \$like;
                }
            }
        }

        \$query_gene .= ")";
        \$query_gene = \$connector . \$query_gene;
        \$connector  = "1";
    }
    if (   ( exists \$hash->{noGO} && \$hash->{noGO} )
        || ( exists \$hash->{goID}   && \$hash->{goID} )
        || ( exists \$hash->{goDesc} && \$hash->{goDesc} )
        || \$components{"GO"} )
    {
        \$query_GO =
        "(SELECT DISTINCT r.object_id "
        . "FROM feature_relationship r "
        . "JOIN featureloc l ON (r.object_id = l.feature_id) "
        . "JOIN featureprop p ON (p.feature_id = l.srcfeature_id) "
        . "JOIN cvterm c ON (p.type_id = c.cvterm_id) "
        . "JOIN feature_relationship pr ON (r.subject_id = pr.object_id) "
        . "JOIN featureprop pd ON (pr.subject_id = pd.feature_id) "
        . "JOIN cvterm cpd ON (pd.type_id = cpd.cvterm_id) "
        . "WHERE c.name ='pipeline_id' AND p.value = ? AND cpd.name LIKE 'evidence_\%' ";

        push \@args, \$hash->{pipeline};

        \$connector = " INTERSECT " if \$connector;

        if ( exists \$hash->{noGO} && \$hash->{noGO} ) {
            \$connector = " EXCEPT " if \$connector;
        }
        elsif ( exists \$hash->{goID} && \$hash->{goID} ) {
            \$query_GO .=
            " AND lower(pd.value) LIKE ? ";
            push \@args, "\%" . lc( \$hash->{'goID'} ) . "\%";
        }
        elsif ( exists \$hash->{goDesc} && \$hash->{goDesc} ) {
            \$query_GO .=
            " and lower(pd.value) LIKE ? ";
            push \@args, "\%" . lc( \$hash->{'goDesc'} ) . "\%";
        }
        \$query_GO  = \$connector . \$query_GO . ")";
        \$connector = "1";
    }
    if (   ( exists \$hash->{'noTC'} && \$hash->{'noTC'} )
        || ( exists \$hash->{'tcdbID'}       && \$hash->{'tcdbID'} )
        || ( exists \$hash->{'tcdbFam'}      && \$hash->{'tcdbFam'} )
        || ( exists \$hash->{'tcdbSubclass'} && \$hash->{'tcdbSubclass'} )
        || ( exists \$hash->{'tcdbClass'}    && \$hash->{'tcdbClass'} )
        || ( exists \$hash->{'tcdbDesc'}     && \$hash->{'tcdbDesc'} ) 
        || \$components{"TCDB"} )
    {
        \$query_TCDB =
        "(SELECT DISTINCT r.object_id "
        . "FROM feature_relationship r "
        . "JOIN featureloc l ON (r.object_id = l.feature_id) "
        . "JOIN featureprop p ON (p.feature_id = l.srcfeature_id) "
        . "JOIN cvterm c ON (p.type_id = c.cvterm_id) "
        . "JOIN feature_relationship pr ON (r.subject_id = pr.object_id) "
        . "JOIN featureprop ppr ON (pr.subject_id = ppr.feature_id) "
        . "JOIN featureprop pd ON (pr.subject_id = pd.feature_id) "
        . "JOIN cvterm cpd ON (pd.type_id = cpd.cvterm_id) "
        . "join analysisfeature af on (r.subject_id = af.feature_id)"
        . "join analysis a on (a.analysis_id = af.analysis_id) "
        . "WHERE a.program = 'annotation_tcdb.pl' and c.name ='pipeline_id' AND p.value = ? ";
        push \@args, \$hash->{pipeline};

        \$connector = " INTERSECT " if \$connector;

        if ( \$hash->{'noTC'} ) {
            \$connector = " EXCEPT " if \$connector;
            \$query_TCDB .= " AND cpd.name = 'TCDB_ID'";
        }
        elsif ( \$hash->{'tcdbID'} ) {
            \$query_TCDB .= "AND cpd.name = 'TCDB_ID' AND pd.value = ?";
            push \@args, \$hash->{'tcdbID'};
        }
        elsif ( \$hash->{'tcdbFam'} ) {
            \$query_TCDB .=
            "AND cpd.name = 'TCDB_family' AND lower(pd.value) LIKE ?";
            push \@args, "\%" . lc( \$hash->{'tcdbFam'} ) . "\%";
        }
        elsif ( \$hash->{'tcdbSubclass'} ) {
            \$query_TCDB .=
            "AND cpd.name = 'TCDB_subclass' AND lower(pd.value) LIKE ?";
            push \@args, "\%" . lc( \$hash->{'tcdbSubclass'} ) . "\%";
        }
        elsif ( \$hash->{'tcdbClass'} ) {
            \$query_TCDB .=
            "AND cpd.name = 'TCDB_class' AND lower(pd.value) LIKE ?";
            push \@args, "\%" . lc( \$hash->{'tcdbClass'} ) . "\%";
        }
        elsif ( \$hash->{'tcdbDesc'} ) {
            \$query_TCDB .=
            "and cpd.name = 'hit_description' and "
            . generate_clause( "?", "", "", "lower(pd.value)" );
            push \@args, lc( \$hash->{'tcdbDesc'} );
        }
        \$query_TCDB = \$connector . \$query_TCDB . ")";
        \$connector  = "1";
    }
    if (   ( exists \$hash->{'noBlast'} && \$hash->{'noBlast'} )
        || ( exists \$hash->{'blastID'}   && \$hash->{'blastID'} )
        || ( exists \$hash->{'blastDesc'} && \$hash->{'blastDesc'} ) 
        || \$components{"BLAST"} )
    {
        \$query_blast = "(SELECT DISTINCT r.object_id " . " FROM feature f
        JOIN feature_relationship r ON (r.subject_id = f.feature_id)
        JOIN feature fo ON (r.object_id = fo.feature_id)
        JOIN analysisfeature af ON (f.feature_id = af.feature_id)
        JOIN analysis a ON (a.analysis_id = af.analysis_id)
        JOIN featureloc l ON (r.object_id = l.feature_id)
        JOIN featureprop p ON (p.feature_id = srcfeature_id)
        JOIN cvterm c ON (p.type_id = c.cvterm_id)
        JOIN feature_relationship ra ON (ra.object_id = f.feature_id)
        JOIN cvterm cra ON (ra.type_id = cra.cvterm_id)
        JOIN featureprop pfo ON (ra.subject_id = pfo.feature_id)
        JOIN cvterm cpfo ON (cpfo.cvterm_id = pfo.type_id)
        JOIN featureprop pr ON (r.object_id = pr.feature_id)
        JOIN cvterm cpr ON (pr.type_id = cpr.cvterm_id) ";
        my \$conditional =
        "WHERE a.program = 'annotation_blast.pl' AND c.name ='pipeline_id' AND p.value = ? AND cra.name = 'alignment' AND cpfo.name = 'subject_id'";
        push \@args, \$hash->{pipeline};
        \$connector = " INTERSECT " if \$connector;
        if ( \$hash->{'noBlast'} ) {
            \$connector = " EXCEPT " if \$connector;
        }
        elsif ( \$hash->{'blastID'} ) {
            \$conditional .= " AND lower(pfo.value) LIKE ?";
            push \@args, "\%" . lc( \$hash->{'blastID'} ) . "\%";
        }
        elsif ( \$hash->{'blastDesc'} ) {
            \$conditional .=
            " AND " . generate_clause( "?", "", "", "lower(pfo.value)" );
            push \@args, \$hash->{'blastDesc'};
        }
        \$query_blast = \$connector . \$query_blast . \$conditional . ")";
        \$connector   = "1";
    }
    if (   ( exists \$hash->{'noRps'} && \$hash->{'noRps'} )
        || ( exists \$hash->{'rpsID'}   && \$hash->{'rpsID'} )
        || ( exists \$hash->{'rpsDesc'} && \$hash->{'rpsDesc'} ) 
        || \$components{"RPS-BLAST"} )
    {
        \$query_RPS =
        "(select distinct r.object_id "
        . " from feature f "
        . "join feature_relationship r on (r.subject_id = f.feature_id) "
        . "join feature fo on (r.object_id = fo.feature_id) "
        . "join analysisfeature af on (f.feature_id = af.feature_id) "
        . "join analysis a on (a.analysis_id = af.analysis_id) "
        . "join featureloc l on (r.object_id = l.feature_id) "
        . "join featureprop p on (p.feature_id = srcfeature_id) "
        . "join cvterm c on (p.type_id = c.cvterm_id) "
        . "join feature_relationship ra on (ra.object_id = f.feature_id) "
        . "join cvterm cra on (ra.type_id = cra.cvterm_id) "
        . "join featureprop pfo on (ra.subject_id = pfo.feature_id) "
        . "join cvterm cpfo on (cpfo.cvterm_id = pfo.type_id) "
        . "join featureprop pr on (r.object_id = pr.feature_id) "
        . "join cvterm cpr on (pr.type_id = cpr.cvterm_id) ";
        my \$conditional =
        "where a.program = 'annotation_rpsblast.pl' and c.name ='pipeline_id' and p.value = ? and cra.name = 'alignment' and cpfo.name = 'subject_id' ";
        push \@args, \$hash->{pipeline};
        \$connector = " INTERSECT " if \$connector;

        if ( \$hash->{'noRps'} ) {
            \$connector = " EXCEPT " if \$connector;
        }
        elsif ( \$hash->{'rpsID'} ) {
            \$conditional .= " and lower(pfo.value) like ? ";
            push \@args, "\%" . lc( \$hash->{'rpsID'} ) . "\%";
        }
        elsif ( \$hash->{'rpsDesc'} ) {
            \$conditional .=
            " and " . generate_clause( "?", "", "", "lower(pfo.value)" );
            push \@args, "\%" . lc( \$hash->{'rpsDesc'} ) . "\%";
        }
        \$query_RPS = \$connector . \$query_RPS . \$conditional . ")";
        \$connector = 1;
    }
    if (   \$hash->{'noKEGG'}
        || \$hash->{'koID'}
        || \$hash->{'keggPath'}
        || \$hash->{'keggDesc'} 
        || \$components{"KEGG"} )
    {
        \$query_KEGG =
        "(select distinct r.object_id "
        . "from feature_relationship r "
        . "join featureloc l on (r.object_id = l.feature_id)"
        . "join featureprop p on (p.feature_id = l.srcfeature_id)"
        . "join cvterm c on (p.type_id = c.cvterm_id)"
        . "join feature_relationship pr on (r.subject_id = pr.object_id)"
        . "join featureprop ppr on (pr.subject_id = ppr.feature_id)"
        . "join featureprop pd on (pr.subject_id = pd.feature_id)"
        . "join cvterm cpd on (pd.type_id = cpd.cvterm_id) "
        . "join featureprop pd2 on (pr.subject_id = pd2.feature_id)"
        . "join cvterm cpd2 on (pd2.type_id = cpd2.cvterm_id) "
        . "join featureprop pd3 on (pr.subject_id = pd3.feature_id)"
        . "join cvterm cpd3 on (pd3.type_id = cpd3.cvterm_id) "
        . "join analysisfeature af on (r.subject_id = af.feature_id)"
        . "join analysis a on (a.analysis_id = af.analysis_id) ";
        my \$conditional = " where c.name ='pipeline_id' and p.value = ? and cpd.name = 'orthologous_group_id' and cpd2.name = 'metabolic_pathway_id' and cpd3.name = 'orthologous_group_description'  and a.program = 'annotation_pathways.pl' ";
        push \@args, \$hash->{pipeline};
        \$connector = " intersect " if \$connector;
        if ( \$hash->{'noKEGG'} ) {
            \$connector = " except " if \$connector;
        } else {
            if ( \$hash->{'koID'} ) {
                \$conditional .= " and lower(pd.value) LIKE ? ";
                push \@args, "\%" . lc( \$hash->{'koID'} ) . "\%";
            }
            if ( \$hash->{'keggPath'} ) {
                \$conditional .=
                " and lower(pd2.value) like ? ";
                push \@args, "\%" . lc( \$hash->{'keggPath'} ) . "\%";
            }
            if ( \$hash->{'keggDesc'} ) {
                while ( \$hash->{keggDesc} =~ /(\\S+)/g ) {
                    \$conditional .= " and ". 
                    generate_clause( "?", "", "",
                        "lower(pd3.value)"
                    );
                    push \@args, lc( "\%" . \$1 . "\%" );
                }
            }
        }
        \$query_KEGG = \$connector . \$query_KEGG . \$conditional . ")";
        \$connector  = "1";
    }
    if (   ( exists \$hash->{'noOrth'} && \$hash->{'noOrth'} )
        || ( exists \$hash->{'orthID'}   && \$hash->{'orthID'} )
        || ( exists \$hash->{'orthDesc'} && \$hash->{'orthDesc'} ) 
        || \$components{"eggNOG"} )
    {
        \$query_ORTH =
        "(select distinct r.object_id"
        . " from feature_relationship r "
        . "join featureloc l on (r.object_id = l.feature_id) "
        . "join featureprop p on (p.feature_id = l.srcfeature_id) "
        . "join cvterm c on (p.type_id = c.cvterm_id) "
        . "join feature_relationship pr on (r.subject_id = pr.object_id) "
        . "join featureprop ppr on (pr.subject_id = ppr.feature_id) "
        . "join featureprop pd on (pr.subject_id = pd.feature_id) "
        . "join cvterm cpd on (pd.type_id = cpd.cvterm_id) "
        . "join analysisfeature af on (r.subject_id = af.feature_id) "
        . "join analysis a on (a.analysis_id = af.analysis_id) ";
        my \$conditional = "where c.name ='pipeline_id' and p.value = ? and a.program = 'annotation_orthology.pl' ";
        push \@args, \$hash->{pipeline};
        \$connector = " intersect " if \$connector;
        if ( \$hash->{'noOrth'} ) {
            \$connector = " except " if \$connector;
            \$conditional .= " and cpd.name = 'orthologous_group' ";
        }
        elsif ( \$hash->{'orthID'} ) {
            \$conditional =
            "and cpd.name = 'orthologous_group' and lower(pd.value) like ? ";
            push \@args, "\%" . lc( \$hash->{'orthID'} ) . "\%";
        }
        elsif ( \$hash->{'orthDesc'} ) {
            \$conditional .=
            "and cpd.name = 'orthologous_group_description' "; 

            while ( \$hash->{orthDesc} =~ /(\\S+)/g ) {
                \$conditional .= " and ". 
                generate_clause( "?", "", "",
                    "lower(pd.value)"
                );
                push \@args, lc( "\%" . \$1 . "\%" );
            }
        }
        \$query_ORTH = \$connector . \$query_ORTH . \$conditional . ")";
        \$connector  = "1";
    }
    if (   ( exists \$hash->{'noIP'} && \$hash->{'noIP'} )
        || ( exists \$hash->{'interproID'}   && \$hash->{'interproID'} )
        || ( exists \$hash->{'interproDesc'} && \$hash->{'interproDesc'} ) 
        || \$components{"Interpro"} )
    {
        \$query_interpro =
        "(select distinct r.object_id "
        . " from feature f "
        . "join feature_relationship r on (r.subject_id = f.feature_id) "
        . "join featureloc l on (r.object_id = l.feature_id) "
        . "join featureprop p on (p.feature_id = l.srcfeature_id) "
        . "join cvterm c on (p.type_id = c.cvterm_id) "
        . "join feature_relationship pr on (r.subject_id = pr.object_id) "
        . "join featureprop ppr on (pr.subject_id = ppr.feature_id) "
        . "join cvterm cpr on (ppr.type_id = cpr.cvterm_id) "
        . "join analysisfeature af on (r.subject_id = af.feature_id) "
        . "join analysis a on (a.analysis_id = af.analysis_id) ";
        my \$conditional = "where c.name ='pipeline_id' and p.value = ? and a.program='annotation_interpro.pl'";
        push \@args, \$hash->{pipeline};
        \$connector = " intersect " if \$connector;
        if ( \$hash->{'noIP'} ) {
            \$connector = " except " if \$connector;
            \$conditional .= "and cpr.name like 'interpro_id'";
        }
        elsif ( \$hash->{'interproID'} ) {
            \$conditional .=
            "and cpr.name like 'interpro_id' and ppr.value LIKE ? ";
            push \@args, "\%" . \$hash->{'interproID'} . "\%";
        }
        elsif ( \$hash->{'interproDesc'} ) {
            \$conditional .=
            "and cpr.name like 'description\%' and ppr.value like ? ";
            push \@args, "\%" . \$hash->{'interproDesc'} . "\%";
        }
        \$query_interpro = \$connector . \$query_interpro . \$conditional . ")";
        \$connector      = 1;
    }
    if (    ( exists \$hash->{'TMHMMdom'}   && \$hash->{'TMHMMdom'}   ) 
        ||  ( exists \$hash->{'tmhmmQuant'} && \$hash->{'tmhmmQuant'} )
        || \$components{"TMHMM"} )
    {
        my \$select = "(SELECT DISTINCT r.object_id       
        FROM feature f 
        JOIN feature_relationship r ON (r.subject_id = f.feature_id) 
        JOIN feature fo ON (r.object_id = fo.feature_id) 
        JOIN featureloc l ON (r.object_id = l.feature_id) 
        JOIN featureprop p ON (p.feature_id = l.srcfeature_id) 
        JOIN analysisfeature af ON (f.feature_id = af.feature_id) 
        JOIN analysis a ON (a.analysis_id = af.analysis_id) 
        JOIN cvterm c ON (p.type_id = c.cvterm_id)  
        JOIN feature_relationship pr ON (r.subject_id = pr.object_id) 
        JOIN featureprop ppr ON (pr.subject_id = ppr.feature_id) 
        JOIN cvterm cpr ON (ppr.type_id = cpr.cvterm_id)  
        JOIN featureprop pp ON (pr.subject_id = pp.feature_id) 
        JOIN cvterm cpp ON (pp.type_id = cpp.cvterm_id) 
        JOIN featureprop ppp ON (pr.subject_id = ppp.feature_id)       
        JOIN cvterm cppp ON (ppp.type_id = cppp.cvterm_id)
        WHERE a.program = 'annotation_tmhmm.pl' AND c.name ='pipeline_id' AND p.value=? AND cpr.name ='version' AND cpp.name='direction' AND cppp.name='predicted_TMHs' ";
        push \@args, \$hash->{pipeline};
        \$connector = " INTERSECT " if \$connector;
        if ( \$hash->{'tmhmmQuant'} eq "exact" && \$hash->{'TMHMMdom'} ) {
            \$select .= " AND my_to_decimal(ppp.value) = ?";
            push \@args, \$hash->{'TMHMMdom'} if \$hash->{'tmhmmQuant'};
            \$query_tmhmm = \$connector . \$select . ")";
            \$connector     = "1";
        }
        elsif ( \$hash->{'tmhmmQuant'} eq "orLess" && \$hash->{'TMHMMdom'} ) {
            \$select .= " AND my_to_decimal(ppp.value) <= ?";
            push \@args, \$hash->{'TMHMMdom'} if \$hash->{'tmhmmQuant'};
            \$query_tmhmm = \$connector . \$select . ")";
            \$connector     = "1";
        }
        elsif ( \$hash->{'tmhmmQuant'} eq "orMore" && \$hash->{'TMHMMdom'} ) {
            \$select .= " AND my_to_decimal(ppp.value) >= ?";
            push \@args, \$hash->{'TMHMMdom'} if \$hash->{'tmhmmQuant'};
            \$query_tmhmm = \$connector . \$select . ")";
            \$connector     = "1";
        }
        elsif ( \$hash->{'tmhmmQuant'} eq "none") {
            \$select .= " AND my_to_decimal(ppp.value) != 0";
            \$query_tmhmm = " EXCEPT " . \$select . ")";

        } else {
            \$select .= " AND my_to_decimal(ppp.value) != 0";
            \$query_tmhmm = \$connector . \$select . ")";
        }

    }
    if (    ( exists \$hash->{'noDGPI'} && \$hash->{'noDGPI'} )
        ||  ( exists \$hash->{'cleavageSiteDGPI'}   && \$hash->{'cleavageSiteDGPI'}   ) 
        ||  ( exists \$hash->{'scoreDGPI'}   && \$hash->{'scoreDGPI'}   )  
        || \$components{"DGPI"} )
    {
        my \$select = "(SELECT DISTINCT r.object_id       
        FROM feature f 
        JOIN feature_relationship r ON (r.subject_id = f.feature_id) 
        JOIN feature fo ON (r.object_id = fo.feature_id) 
        JOIN featureloc l ON (r.object_id = l.feature_id) 
        JOIN featureprop p ON (p.feature_id = l.srcfeature_id) 
        JOIN analysisfeature af ON (f.feature_id = af.feature_id) 
        JOIN analysis a ON (a.analysis_id = af.analysis_id) 
        JOIN cvterm c ON (p.type_id = c.cvterm_id)  
        JOIN feature_relationship pr ON (r.subject_id = pr.object_id) 
        JOIN featureprop ppr ON (pr.subject_id = ppr.feature_id) 
        JOIN cvterm cpr ON (ppr.type_id = cpr.cvterm_id)
        JOIN featureprop pp ON (pr.subject_id = pp.feature_id) 
        JOIN cvterm cpp ON (pp.type_id = cpp.cvterm_id)  
        WHERE a.program = 'annotation_dgpi.pl' AND c.name='pipeline_id' AND p.value=? AND cpr.name='cleavage_site' AND cpp.name='score' ";
        push \@args, \$hash->{pipeline};
        \$connector = " INTERSECT " if \$connector;
        if(\$hash->{'noDGPI'}) {
            \$connector = " EXCEPT " if \$connector;
            \$query_dgpi = \$connector . \$select . ")";
        } elsif(\$hash->{'cleavageSiteDGPI'}) {
            \$select .= " AND my_to_decimal(ppr.value) ";

            if ( \$hash->{'cleavageQuant'} eq "exact" ) {
                \$select .= "= ? ";
                push \@args, \$hash->{'cleavageSiteDGPI'} if \$hash->{'cleavageQuant'};
            }
            elsif ( \$hash->{'cleavageQuant'} eq "orLess" ) {
                \$select .= "<= ? ";
                push \@args, \$hash->{'cleavageSiteDGPI'} if \$hash->{'cleavageQuant'};
            }
            elsif ( \$hash->{'cleavageQuant'} eq "orMore" ) {
                \$select .= ">= ? ";
                push \@args, \$hash->{'cleavageSiteDGPI'} if \$hash->{'cleavageQuant'};
            }
            elsif (\$hash->{'cleavageQuant'} eq "none" ) {
                \$select .= "= 0";
            }
            \$query_dgpi = \$connector . \$select . ")";
            \$connector     = "1";
        } elsif(\$hash->{'scoreDGPI'}) {
            \$select .= " AND my_to_decimal(pp.value) ";

            if ( \$hash->{'scoreQuant'} eq "exact" ) {
                \$select .= "= ? ";
                push \@args, \$hash->{'scoreDGPI'} if \$hash->{'scoreQuant'};
            }
            elsif ( \$hash->{'scoreQuant'} eq "orLess" ) {
                \$select .= "<= ? ";
                push \@args, \$hash->{'scoreDGPI'} if \$hash->{'scoreQuant'};
            }
            elsif ( \$hash->{'scoreQuant'} eq "orMore" ) {
                \$select .= ">= ? ";
                push \@args, \$hash->{'scoreDGPI'} if \$hash->{'scoreQuant'};
            }
            elsif ( \$hash->{'scoreQuant'} eq "none" ) {
                \$select .= "= 0 ";
                push \@args, \$hash->{'scoreDGPI'} if \$hash->{'scoreQuant'};
            }
            \$query_dgpi = \$connector . \$select . ")";
            \$connector     = "1";
        } else {
            \$query_dgpi = \$connector . \$select . ")";
            \$connector     = "1";
        }
        \$connector      = 1;
    }
    if (    ( exists \$hash->{'noPreDGPI'} && \$hash->{'noPreDGPI'} )
        ||  ( exists \$hash->{'namePreDGPI'} && \$hash->{'namePreDGPI'} ) 
        ||  ( exists \$hash->{'positionPreDGPI'} && \$hash->{'positionPreDGPI'} ) 
        ||  ( exists \$hash->{'specificityPreDGPI'} && \$hash->{'specificityPreDGPI'} ) 
        ||  ( exists \$hash->{'sequencePreDGPI'} && \$hash->{'sequencePreDGPI'} )   
        ||  ( exists \$hash->{'positionQuantPreDGPI'} && \$hash->{'positionQuantPreDGPI'} )
        ||  ( exists \$hash->{'specificityQuantPreDGPI'} && \$hash->{'specificityQuantPreDGPI'} )
        || \$components{"PreDGPI"} ) {
        my \$select = "(SELECT DISTINCT r.object_id       
        FROM feature f 
        JOIN feature_relationship r ON (r.subject_id = f.feature_id) 
        JOIN feature fo ON (r.object_id = fo.feature_id) 
        JOIN featureloc l ON (r.object_id = l.feature_id) 
        JOIN featureprop p ON (p.feature_id = l.srcfeature_id) 
        JOIN analysisfeature af ON (f.feature_id = af.feature_id) 
        JOIN analysis a ON (a.analysis_id = af.analysis_id) 
        JOIN cvterm c ON (p.type_id = c.cvterm_id)  
        JOIN feature_relationship pr ON (r.subject_id = pr.object_id) 
        JOIN featureprop ppr ON (pr.subject_id = ppr.feature_id) 
        JOIN cvterm cpr ON (ppr.type_id = cpr.cvterm_id)  
        JOIN featureprop pp ON (pr.subject_id = pp.feature_id) 
        JOIN cvterm cpp ON (pp.type_id = cpp.cvterm_id)
        JOIN featureprop ppp ON (pr.subject_id = ppp.feature_id) 
        JOIN cvterm cppp ON (ppp.type_id = cppp.cvterm_id) 
        JOIN featureprop pppp ON (pr.subject_id = pppp.feature_id) 
        JOIN cvterm cpppp ON (pppp.type_id = cpppp.cvterm_id)      
        WHERE a.program = 'annotation_predgpi.pl' AND c.name='pipeline_id' AND p.value=? AND cpr.name='name' AND cpp.name='position' AND cppp.name='specificity' AND cpppp.name='sequence' ";
        push \@args, \$hash->{pipeline};
        \$connector = " INTERSECT " if \$connector;
        if(\$hash->{'noPreDGPI'}) {
            \$connector = " EXCEPT " if \$connector;
            \$query_predgpi = \$connector . \$select . ")";
        }
        elsif(\$hash->{'namePreDGPI'}) {
            \$select .= " AND lower(ppr.value ) LIKE ? ";
            push \@args, "%" . lc( \$hash->{'namePreDGPI'} ) . "%";
            \$query_predgpi .= \$connector . \$select . " ) ";
            \$connector     = "1";
        }
        elsif(\$hash->{'positionPreDGPI'} || \$hash->{positionQuantPreDGPI} eq 'none') {
            \$select .= " AND my_to_decimal(pp.value) ";
            if ( \$hash->{'positionQuantPreDGPI'} eq "exact" ) {
                \$select .= "= ? ";
                push \@args, \$hash->{'positionPreDGPI'} if \$hash->{positionQuantPreDGPI};
            }
            elsif ( \$hash->{'positionQuantPreDGPI'} eq "orLess" ) {
                \$select .= "<= ? ";
                push \@args, \$hash->{'positionPreDGPI'} if \$hash->{positionQuantPreDGPI};
            }
            elsif ( \$hash->{'positionQuantPreDGPI'} eq "orMore" ) {
                \$select .= ">= ? ";
                push \@args, \$hash->{'positionPreDGPI'} if \$hash->{positionQuantPreDGPI};
            }
            elsif ( \$hash->{'positionQuantPreDGPI'} eq "none" ) {
                \$select .= "= 0 ";
            }
            \$query_predgpi .= \$connector . \$select . " ) ";
            \$connector     = "1";
        }
        elsif(\$hash->{'specificityPreDGPI'} || \$hash->{specificityQuantPreDGPI} eq 'none') {
            \$select .= " AND my_to_decimal(replace(ppp.value, '\%', '')) ";
            if ( \$hash->{'specificityQuantPreDGPI'} eq "exact" ) {
                \$select .= "= ? ";
                push \@args, \$hash->{'specificityPreDGPI'} if \$hash->{specificityQuantPreDGPI};
            }
            elsif ( \$hash->{'specificityQuantPreDGPI'} eq "orLess" ) {
                \$select .= "<= ? ";
                push \@args, \$hash->{'specificityPreDGPI'} if \$hash->{specificityQuantPreDGPI};
            }
            elsif ( \$hash->{'specificityQuantPreDGPI'} eq "orMore" ) {
                \$select .= ">= ? ";
                push \@args, \$hash->{'specificityPreDGPI'} if \$hash->{specificityQuantPreDGPI};
            }
            elsif ( \$hash->{'specificityQuantPreDGPI'} eq "none" ) {
                \$select .= "= 0 ";
            }
            \$query_predgpi .= \$connector . \$select . " ) ";
            \$connector     = "1";
        }
        elsif(\$hash->{'sequencePreDGPI'}) {
            \$select .= " AND lower(pppp.value ) LIKE ? ";
            push \@args, "\%" . lc( \$hash->{'sequencePreDGPI'} ) . "\%";
            \$query_predgpi .= \$connector . \$select . " ) ";
            \$connector     = "1";
        } else {
            \$query_predgpi .= \$connector . \$select . " ) ";
            \$connector     = "1";
        }

    }
    if (    ( exists \$hash->{'noBigGPI'} && \$hash->{'noBigGPI'} )
        ||  ( exists \$hash->{'pvalueBigpi'}   && \$hash->{'pvalueBigpi'}   ) 
        ||  ( exists \$hash->{'positionBigpi'}   && \$hash->{'positionBigpi'}   )  
        ||  ( exists \$hash->{'scoreBigpi'} && \$hash->{'scoreBigpi'} )
        ||  ( exists \$hash->{pvalueQuantBigpi} && \$hash->{pvalueQuantBigpi} )
        ||  ( exists \$hash->{positionQuantBigpi} && \$hash->{positionQuantBigpi} )
        ||  ( exists \$hash->{specificityQuantPreDGPI} && \$hash->{specificityQuantPreDGPI} )
        ||  ( exists \$hash->{scoreQuantBigpi} && \$hash->{scoreQuantBigpi} )
        || \$components{"BIGPI"} ) 
    {
        my \$select = "(SELECT DISTINCT r.object_id       
        FROM feature f 
        JOIN feature_relationship r ON (r.subject_id = f.feature_id) 
        JOIN feature fo ON (r.object_id = fo.feature_id) 
        JOIN featureloc l ON (r.object_id = l.feature_id) 
        JOIN featureprop p ON (p.feature_id = l.srcfeature_id) 
        JOIN analysisfeature af ON (f.feature_id = af.feature_id) 
        JOIN analysis a ON (a.analysis_id = af.analysis_id) 
        JOIN cvterm c ON (p.type_id = c.cvterm_id)  
        JOIN feature_relationship pr ON (r.subject_id = pr.object_id) 
        JOIN featureprop ppr ON (pr.subject_id = ppr.feature_id) 
        JOIN cvterm cpr ON (ppr.type_id = cpr.cvterm_id)
        JOIN featureprop pp ON (pr.subject_id = pp.feature_id) 
        JOIN cvterm cpp ON (pp.type_id = cpp.cvterm_id)  
        JOIN featureprop ppp ON (pr.subject_id = ppp.feature_id) 
        JOIN cvterm cppp ON (ppp.type_id = cppp.cvterm_id)  
        WHERE a.program = 'annotation_bigpi.pl' AND c.name='pipeline_id' AND p.value=? AND cpr.name='p_value' AND cpp.name='position' AND cppp.name='score' ";
        push \@args, \$hash->{pipeline};
        \$connector = " INTERSECT " if \$connector;
        if(\$hash->{'noBigGPI'}) {
            \$connector = " EXCEPT " if \$connector;
            \$query_predgpi = \$connector . \$select . ")";
        } elsif (\$hash->{'pvalueBigpi'} || \$hash->{'pvalueBigpi'} eq 'none') {
            \$select .= " AND my_to_decimal(ppr.value) ";
            if ( \$hash->{'pvalueQuantBigpi'} eq "exact" ) {
                \$select .= "= ? ";
                push \@args, \$hash->{'pvalueBigpi'} if \$hash->{pvalueQuantBigpi};
            }
            elsif ( \$hash->{'pvalueQuantBigpi'} eq "orLess" ) {
                \$select .= "<= ? ";
                push \@args, \$hash->{'pvalueBigpi'} if \$hash->{pvalueQuantBigpi};
            }
            elsif ( \$hash->{'pvalueQuantBigpi'} eq "orMore" ) {
                \$select .= ">= ? ";
                push \@args, \$hash->{'pvalueBigpi'} if \$hash->{pvalueQuantBigpi};
            }
            elsif ( \$hash->{'pvalueQuantBigpi'} eq "none" ) {
                \$select .= "= 0 ";
            }
            \$query_bigpi .= \$connector . \$select . " ) ";
            \$connector     = "1";
        } elsif (\$hash->{'positionBigpi'} || \$hash->{'positionBigpi'} eq 'none') {
            \$select .= " AND my_to_decimal(pp.value) ";
            if ( \$hash->{'positionQuantBigpi'} eq "exact" ) {
                \$select .= "= ? ";
                push \@args, \$hash->{'positionBigpi'} if \$hash->{positionQuantBigpi};
            }
            elsif ( \$hash->{'positionQuantBigpi'} eq "orLess" ) {
                \$select .= "<= ? ";
                push \@args, \$hash->{'positionBigpi'} if \$hash->{positionQuantBigpi};
            }
            elsif ( \$hash->{'positionQuantBigpi'} eq "orMore" ) {
                \$select .= ">= ? ";
                push \@args, \$hash->{'positionBigpi'} if \$hash->{positionQuantBigpi};
            }
            elsif ( \$hash->{'positionQuantBigpi'} eq "none" ) {
                \$select .= "= 0 ";
            }
            \$query_bigpi .= \$connector . \$select . " ) ";
            \$connector     = "1";
        } elsif(\$hash->{'scoreBigpi'} || \$hash->{'scoreBigpi'} eq 'none') {
            \$select .= " AND my_to_decimal(ppp.value) ";
            if ( \$hash->{'scoreQuantBigpi'} eq "exact" ) {
                \$select .= "= ? ";
                push \@args, \$hash->{'scoreBigpi'} if \$hash->{scoreQuantBigpi};
            }
            elsif ( \$hash->{'scoreQuantBigpi'} eq "orLess" ) {
                \$select .= "<= ? ";
                push \@args, \$hash->{'scoreBigpi'} if \$hash->{scoreQuantBigpi};
            }
            elsif ( \$hash->{'scoreQuantBigpi'} eq "orMore" ) {
                \$select .= ">= ? ";
                push \@args, \$hash->{'scoreBigpi'} if \$hash->{scoreQuantBigpi};
            }
            elsif ( \$hash->{'scoreQuantBigpi'} eq "none" ) {
                \$select .= "= 0 ";
            }
            \$query_bigpi .= \$connector . \$select . " ) ";
            \$connector     = "1";
        } else {
            \$query_bigpi .= \$connector . \$select . " ) ";
            \$connector     = "1";
        }
    }
    if (   ( exists \$hash->{'TMdom'} && \$hash->{'TMdom'} ) 
        || ( exists \$hash->{'tmQuant'} && \$hash->{'tmQuant'} )
        || ( exists \$hash->{'sigP'} && \$hash->{'sigP'} ne 'sigPwhatever' ) 
        || \$components{"Phobius"} ) 
    {
        my \$select = "(SELECT DISTINCT r.object_id ";
        my \$join =
        "FROM feature f \n"
        . "JOIN feature_relationship r ON (r.subject_id = f.feature_id) \n"
        . "JOIN feature fo ON (r.object_id = fo.feature_id) \n"
        . "JOIN featureloc l ON (r.object_id = l.feature_id) \n"
        . "JOIN featureprop p ON (p.feature_id = l.srcfeature_id) \n"
        . "JOIN analysisfeature af ON (f.feature_id = af.feature_id) \n"
        . "JOIN analysis a ON (a.analysis_id = af.analysis_id) \n"
        . "JOIN cvterm c ON (p.type_id = c.cvterm_id) \n"
        . "JOIN feature_relationship pr ON (r.subject_id = pr.object_id) \n"
        . "JOIN featureprop ppr ON (pr.subject_id = ppr.feature_id) \n"
        . "JOIN cvterm cpr ON (ppr.type_id = cpr.cvterm_id) \n"
        . "JOIN featureprop pp ON (pr.subject_id = pp.feature_id) \n"
        . "JOIN cvterm cpp ON (pp.type_id = cpp.cvterm_id) \n";
        my \$conditional =
        "WHERE a.program = 'annotation_phobius.pl' AND c.name ='pipeline_id' AND p.value=? " .
            " AND cpr.name = 'classification' AND ppr.value= 'TRANSMEM' AND cpp.name = 'predicted_TMHs' ";

        push \@args, \$hash->{pipeline};
        \$connector = " INTERSECT " if \$connector;

        if ( \$hash->{'tmQuant'} eq "exact" && \$hash->{'TMdom'}) {
            \$conditional .= " AND my_to_decimal(pp.value)  = ? ";
            push \@args, \$hash->{'TMdom'} if \$hash->{'tmQuant'};
            \$query_Phobius = \$connector . \$select . \$join . \$conditional . ")";
            \$connector     = "1";
        }
        elsif ( \$hash->{'tmQuant'} eq "orLess" && \$hash->{'TMdom'} ) {
            my \$secondaryQuery = "select distinct f.feature_id 
            from feature f 
            join feature_relationship r on (f.feature_id = r.object_id) 
            join cvterm cr on (r.type_id = cr.cvterm_id) 
            join featureprop ps on (r.subject_id = ps.feature_id) 
            join cvterm cs on (ps.type_id = cs.cvterm_id) 
            join featureprop pf on (f.feature_id = pf.feature_id) 
            join cvterm cf on (pf.type_id = cf.cvterm_id) 
            join featureloc l on (l.feature_id = f.feature_id) 
            join featureprop pl on (l.srcfeature_id = pl.feature_id) 
            join cvterm cp on (pl.type_id = cp.cvterm_id) 
            join featureprop pd on (r.subject_id = pd.feature_id) 
            join cvterm cd on (pd.type_id = cd.cvterm_id) 
            where cr.name = 'based_on' and cf.name = 'tag' and pf.value='CDS' and cs.name = 'locus_tag' and cd.name = 'description' and cp.name = 'pipeline_id' and pl.value=? ";

            if(exists \$hash->{contig} && \$hash->{contig}) {
                \$query .= " and l.srcfeature_id = ? ";
                push \@args, \$hash->{contig};
            } 
            my \$oldQueryPhobius = "(".\$secondaryQuery. " EXCEPT "  . \$select . \$join . \$conditional . " AND my_to_decimal(pp.value)  != 0))";
            \$conditional .= " AND my_to_decimal(pp.value)  <= ? ";
            push \@args, \$hash->{'TMdom'} if \$hash->{'tmQuant'};
            \$query_Phobius = \$connector . "(" . \$select . \$join . \$conditional . ") UNION \$oldQueryPhobius)";
            push \@args, \$hash->{pipeline};
            push \@args, \$hash->{pipeline};
            \$connector     = "1";
        }
        elsif ( \$hash->{'tmQuant'} eq "orMore" && \$hash->{'TMdom'} ) {
            \$conditional .= " AND my_to_decimal(pp.value)  >= ? ";
            push \@args, \$hash->{'TMdom'} if \$hash->{'tmQuant'};
            \$query_Phobius = \$connector . \$select . \$join . \$conditional . ")";
            \$connector     = "1";
        }
        elsif ( \$hash->{'tmQuant'} eq "none" ) {
            \$connector = " EXCEPT " if \$connector;
            \$query_Phobius = \$connector . \$select . \$join . \$conditional . ")";
        } else {
            \$query_Phobius = \$connector . \$select . \$join . \$conditional . " AND my_to_decimal(pp.value)  != 0)";
        }
        if ( \$hash->{'sigP'} ne "sigPwhatever" ) {
            my \$sigPconn = "";
            if ( \$hash->{'sigP'} eq "sigPyes" ) {
                \$sigPconn = " INTERSECT " if \$connector;
            }
            elsif ( \$hash->{'sigP'} eq "sigPno") {
                \$sigPconn = " EXCEPT " if \$connector;
            }

            \$query_Phobius .=
            " \$sigPconn (SELECT DISTINCT r.object_id FROM feature f
            JOIN feature_relationship r ON (r.subject_id = f.feature_id)
            JOIN feature fo ON (r.object_id = fo.feature_id)
            JOIN featureloc l ON (r.object_id = l.feature_id)
            JOIN featureprop p ON (p.feature_id = l.srcfeature_id)
            JOIN analysisfeature af ON (f.feature_id = af.feature_id)
            JOIN analysis a ON (a.analysis_id = af.analysis_id)
            JOIN cvterm c ON (p.type_id = c.cvterm_id)
            JOIN feature_relationship pr ON (r.subject_id = pr.object_id)
            JOIN featureprop ppr ON (pr.subject_id = ppr.feature_id)
            JOIN cvterm cpr ON (ppr.type_id = cpr.cvterm_id)
            JOIN featureprop pp ON (pr.subject_id = pp.feature_id)
            JOIN cvterm cpp ON (pp.type_id = cpp.cvterm_id)
            where a.program = 'annotation_phobius.pl' AND c.name = 'pipeline_id' AND p.value = ? AND cpr.name = 'classification' AND ppr.value = 'SIGNAL')";
            push \@args, \$hash->{pipeline};
            \$connector = "1";
        }
    }
    if ((exists \$hash->{'signalP'} && \$hash->{'signalP'} ne "whatever") 
        || \$components{"SignalP"} ) 
    {
        if ( \$hash->{'signalP'} eq "YES" ) {
            \$query_sigP = " INTERSECT " if \$connector;

        }elsif (\$hash->{'signalP'} eq "NO") {
            \$query_sigP = " EXCEPT " if \$connector;
        }
        \$query_sigP .= " (SELECT DISTINCT r.object_id       
        FROM feature f 
        JOIN feature_relationship r ON (r.subject_id = f.feature_id) 
        JOIN feature fo ON (r.object_id = fo.feature_id) 
        JOIN featureloc l ON (r.object_id = l.feature_id) 
        JOIN featureprop p ON (p.feature_id = l.srcfeature_id) 
        JOIN analysisfeature af ON (f.feature_id = af.feature_id) 
        JOIN analysis a ON (a.analysis_id = af.analysis_id) 
        JOIN cvterm c ON (p.type_id = c.cvterm_id)  
        JOIN feature_relationship pr ON (r.subject_id = pr.object_id) 
        JOIN featureprop ppr ON (pr.subject_id = ppr.feature_id) 
        JOIN cvterm cpr ON (ppr.type_id = cpr.cvterm_id)  
        WHERE a.program = 'annotation_signalP.pl' AND c.name = 'pipeline_id' AND p.value = ? AND cpr.name = 'pep_sig' AND ppr.value = 'YES')";
        push \@args, \$hash->{pipeline};
        \$connector = "1"; 
    }

    \$query =
    \$query
    . \$query_gene
    . \$query_GO
    . \$query_TCDB
    . \$query_Phobius
    . \$query_sigP
    . \$query_blast
    . \$query_RPS
    . \$query_KEGG
    . \$query_ORTH
    . \$query_interpro
    . \$query_tmhmm
    . \$query_dgpi
    . \$query_bigpi
    . \$query_predgpi
    . " ) as motherfuckerquery 
    LEFT JOIN feature_relationship fr ON (fr.object_id = motherfuckerquery.feature_id) 
    LEFT JOIN featureprop fp ON (fp.feature_id = fr.subject_id) 
    LEFT JOIN cvterm cv ON (cv.cvterm_id = fp.type_id) 
    WHERE cv.name = 'locus_tag' 
    GROUP BY motherfuckerquery.feature_id, fp.value ORDER BY fp.value ASC ";

    if (!\$query_Phobius) {
        my \$quantityParameters = () = \$query =~ /\\?/g;
        my \$counter = scalar \@args;
        if(\$counter > \$quantityParameters) {
            while(scalar \@args > \$quantityParameters) {
                print STDERR "\nARGS:\t".\$_."\n" foreach (\@args);
                shift \@args;
#				delete \$args[\$counter-1];
#				\$counter--;
            }
        }
    }

    if (   exists \$hash->{pageSize}
        && \$hash->{pageSize}
        && exists \$hash->{offset}
        && \$hash->{offset} )
    {
        \$query .= " LIMIT ? ";
        push \@args, \$hash->{pageSize};
        if ( \$hash->{offset} == 1 ) {
            \$query .= " OFFSET 0 ";
        }
        else {
            \$query .= " OFFSET ? ";
            push \@args, \$hash->{offset};
        }
    }	

    my \$sth = \$dbh->prepare(\$query);
    print STDERR \$query;
    \$sth->execute(\@args);
    my \@rows = \@{ \$sth->fetchall_arrayref() };
    my \%returnedHash = ();
    my \@list         = ();

    for ( my \$i = 0 ; \$i < scalar \@rows ; \$i++ ) {
        push \@list, \$rows[\$i][0];
        \$returnedHash{total} = \$rows[\$i][1];
    }

    \$returnedHash{list} = \\\@list;

    return \\\%returnedHash;
}

=head2 generate_clause

Method used to generate clause for any query

=cut

sub generate_clause {
    my \$terms = shift;
    my \$not   = shift || "";
    my \$and   = shift || "";
    my \$field = shift;

    my \@terms  = split( /\\s+/, \$terms );
    my \$clause = " \$and (";
    my \$i      = 0;
    foreach my \$term (\@terms) {
        my \$com = "";
        \$com = " or " if \$i > 0;
        \$clause .= "\$com \$field \$not like \$term";
        \$i++;
    }
    \$clause .= ")";
    return \$clause;
}

=head2 rRNA_search

  Title    : rRNA_search
  Usage    : my \$results = \$my_object->rRNA_search( -hash => \%{ ("pipeline" => "4528", "pageSize" => "10", "offset" => "0") } );
  Function : Method used to realize search of rRNAs by contig and type 
  Returns  : Returns a array of feature IDs of rRNA results as response
  Args     : named arguments:
           : -hash => referenced hash with the following properties:
| Key | Descriptions |
| :-- | :-- |
| pipeline | Pipeline ID |
| pageSize | Quantity of elements |
| offset   | Offset of search |
| type     | Type of rRNA |
| contig   | Contig ID |

           :
=cut

sub rRNA_search {
    my ( \$self, \$hash ) = \@_;
    my \$dbh  = \$self->dbh;
    my \@args = ();
    my \$query = "select f.feature_id, COUNT(*) OVER() AS total
    from feature f 
    join feature_relationship r on (f.feature_id = r.object_id) 
    join cvterm cr on (r.type_id = cr.cvterm_id) 
    join featureprop ps on (r.subject_id = ps.feature_id) 
    join cvterm cs on (ps.type_id = cs.cvterm_id) 
    join featureprop pf on (f.feature_id = pf.feature_id) 
    join cvterm cf on (pf.type_id = cf.cvterm_id) 
    join featureloc l on (l.feature_id = f.feature_id) 
    join featureprop pl on (l.srcfeature_id = pl.feature_id) 
    join cvterm cp on (pl.type_id = cp.cvterm_id) 
    join featureprop pd on (r.subject_id = pd.feature_id) 
    join cvterm cd on (pd.type_id = cd.cvterm_id) 
    where cr.name = 'based_on' and cf.name = 'tag' and pf.value='rRNA_prediction' and cs.name = 'locus_tag' and cd.name = 'description' and cp.name = 'pipeline_id' and pl.value=?";
    push \@args, \$hash->{pipeline};

    if(exists \$hash->{contig} && \$hash->{contig}) {
        \$query .= " and l.srcfeature_id = ? ";
        push \@args, \$hash->{contig};
    }

    if(exists \$hash->{type} && \$hash->{type}) {
        \$query .= " and pd.value=?";
        push \@args, \$hash->{type};
    }

    \$query .= " ORDER BY f.uniquename ASC, l.fstart ASC ";

    if (   exists \$hash->{pageSize}
        && \$hash->{pageSize}
        && exists \$hash->{offset}
        && \$hash->{offset} )
    {
        \$query .= " LIMIT ? ";
        push \@args, \$hash->{pageSize};
        if ( \$hash->{offset} == 1 ) {
            \$query .= " OFFSET 0 ";
        }
        else {
            \$query .= " OFFSET ? ";
            push \@args, \$hash->{offset};
        }
    }

    my \$sth = \$dbh->prepare(\$query);
    print STDERR \$query;
    \$sth->execute(\@args);
    my \@rows = \@{ \$sth->fetchall_arrayref() };
    my \%returnedHash = ();
    my \@list         = ();
    for ( my \$i = 0 ; \$i < scalar \@rows ; \$i++ ) {
        push \@list, \$rows[\$i][0];
        \$returnedHash{total} = \$rows[\$i][1];
    }
    \$returnedHash{"list"} = \\\@list;

    return \\\%returnedHash;

}

=head2 tRNA_search

  Title    : tRNA_search
  Usage    : my \$results = \$my_object->tRNA_search( -hash => \%{ ("pipeline" => "4528") } );
  Function : Method used to return tRNA data from database 
  Returns  : Returns hash with Report_HTML_DB::Models::Application::TRNASearch list and total number of results
  Args     : named arguments:
           : -hash => referenced hash with the following properties:
| Key | Description |
| :-- | :-- |
| pipeline | Scalar variable with pipeline ID |
| pageSize | Scalar variable with the page size |
| offset | Scalar variable with the offset |
| contig | Scalar variable with feature ID from contig |
| tRNAaa | Scalar variable to search tRNA by amino acid |
| tRNAcd | Scalar variable to search tRNA by codon |           
           :

=cut

sub tRNA_search {
    my ( \$self, \$hash ) = \@_;
    my \$dbh  = \$self->dbh;
    my \@args = ();
    my \$query =
    "select r.object_id AS id, fp.value AS sequence, pt.value AS amino_acid, pa.value AS codon, COUNT(*) OVER() AS total "
    . "from feature_relationship r "
    . "join cvterm c on (r.type_id = c.cvterm_id) "
    . "join featureloc l on (r.subject_id = l.feature_id) "
    . "join feature fl on (fl.feature_id = l.srcfeature_id) "
    . "join analysisfeature af on (af.feature_id = r.object_id) "
    . "join analysis a on (a.analysis_id = af.analysis_id) "
    . "join featureprop p on (p.feature_id = l.srcfeature_id) "
    . "join cvterm cp on (p.type_id = cp.cvterm_id) "
    . "join featureprop pt on (r.subject_id = pt.feature_id) "
    . "join cvterm cpt on (pt.type_id = cpt.cvterm_id) "
    . "join featureprop pa on (r.subject_id = pa.feature_id) "
    . "join cvterm cpa on (pa.type_id = cpa.cvterm_id) "
    . "join featureprop fp on (r.subject_id = fp.feature_id) "
    . "join cvterm cfp on (fp.type_id = cfp.cvterm_id) "
    . "where c.name='interval' and a.program = 'annotation_trna.pl' and cp.name='pipeline_id' and p.value=? and cpt.name='type' and cpa.name='anticodon' and cfp.name = 'sequence' ";
    push \@args, \$hash->{pipeline};
    my \$anticodon = "";

    if(exists \$hash->{contig} && \$hash->{contig}) {
        \$query .= " and l.srcfeature_id = ? ";
        push \@args, \$hash->{contig};
    }

    if ( \$hash->{'tRNAaa'} ne "" ) {
        \$query .= "and pt.value = ?";
        push \@args, \$hash->{'tRNAaa'};
    }
    elsif ( \$hash->{'tRNAcd'} ne "" ) {
        \$anticodon = reverseComplement( \$hash->{'tRNAcd'} );
        \$query .= "and pa.value = ?";
        push \@args, \$anticodon;
    }

    \$query .= " ORDER BY fl.uniquename ASC,  l.fstart ASC ";

    if (   exists \$hash->{pageSize}
        && \$hash->{pageSize}
        && exists \$hash->{offset}
        && \$hash->{offset} )
    {
        \$query .= " LIMIT ? ";
        push \@args, \$hash->{pageSize};
        if ( \$hash->{offset} == 1 ) {
            \$query .= " OFFSET 0 ";
        }
        else {
            \$query .= " OFFSET ? ";
            push \@args, \$hash->{offset};
        }
    }

    my \$sth = \$dbh->prepare(\$query);
    print STDERR \$query;
    \$sth->execute(\@args);
    my \@rows = \@{ \$sth->fetchall_arrayref() };
    my \%returnedHash = ();
    my \@list         = ();
    use Report_HTML_DB::Models::Application::TRNASearch;
    for ( my \$i = 0 ; \$i < scalar \@rows ; \$i++ ) {
        my \$result = Report_HTML_DB::Models::Application::TRNASearch->new(
            id         => \$rows[\$i][0],
            sequence   => \$rows[\$i][2],
            amino_acid => \$rows[\$i][1],
            codon      => \$rows[\$i][3],
        );
        \$returnedHash{total} = \$rows[\$i][4];
        push \@list, \$result;
    }
    \$returnedHash{"list"} = \\\@list;

    return \\\%returnedHash;
}

=head2 trf_search

  Title    : trf_search
  Usage    : my \$results = \$my_object->trf_search( -hash => \%{ ("pipeline" => "4528") } );
  Function : Method used to return tandem repeats data from database 
  Returns  : Returns a referenced hash with Report_HTML_DB::Models::Application::TRFSearch list and total number of results available
  Args     : named arguments:
           : -hash => referenced hash with the following properties:
| Key | Description |
| :-- | :-- |
| pipeline | Scalar variable with pipeline ID |
| pageSize | Scalar variable with the page size |
| offset | Scalar variable with the offset |
| contig | Scalar variable with feature ID from contig |
| TRFrepSeq | Scalar variable with sequence in repetition unit |
| TRFrepSize | Scalar variable with repetition units of bases |
| TRFsize | Scalar variable which auxiliate search of repetition units of bases, if you want exatly value: “exact”, less: “orLess”, more: “orMore”, or none: "none" |
| TRFrepNumMin | Scalar variable with occurrences in this min value |
| TRFrepNumMax | Scalar variable with occurrences in this max value |

=cut

sub trf_search {
    my ( \$self, \$hash ) = \@_;
    my \$dbh       = \$self->dbh;
    my \@args      = ();
    my \$connector = "";
    my \$select =
    "select fl.uniquename AS contig, l.fstart AS start, l.fend AS end, pp.value AS length, pc.value AS copy_number, pur.value AS sequence, fl.feature_id, COUNT(*) OVER() AS total ";
    my \$join = "from feature_relationship r
    join featureloc l on (r.subject_id = l.feature_id)
    join feature fl on (fl.feature_id = l.srcfeature_id)
    join featureprop pp on (r.subject_id = pp.feature_id)
    join cvterm cp on (pp.type_id = cp.cvterm_id)
    join featureprop pc on (r.subject_id = pc.feature_id)
    join cvterm cc on (pc.type_id = cc.cvterm_id)
    join featureprop pur on (pur.feature_id = r.subject_id)
    join cvterm cpur on (pur.type_id = cpur.cvterm_id)
    join analysisfeature af on (r.object_id = af.feature_id)
    join analysis a on (af.analysis_id = a.analysis_id)
    join featureprop ps on (ps.feature_id = l.srcfeature_id)
    join cvterm cps on (ps.type_id = cps.cvterm_id) ";
    my \$query =
    "where a.program = 'annotation_trf.pl' and cp.name = 'period_size' and cc.name = 'copy_number' and cpur.name='sequence' and cps.name='pipeline_id' and ps.value=? ";
    push \@args, \$hash->{pipeline};

    if(exists \$hash->{contig} && \$hash->{contig}) {
        \$query .= " and l.srcfeature_id = ? ";
        push \@args, \$hash->{contig};
    }

    if ( \$hash->{'TRFrepSeq'} !~ /^\\s*\$/ ) {
        \$hash->{'TRFrepSeq'} =~ s/\\s+//g;
        \$query .= "and lower(pur.value) ilike ? ";
        \$connector = ",";
        push \@args, lc("\%\$hash->{'TRFrepSeq'}\%");
    }

    if ( \$hash->{'TRFrepSize'} !~ /^\\s*\$/ || \$hash->{'TRFsize'} eq "none") {
        \$hash->{'TRFrepSize'} =~ s/\\s+//g;

        if ( \$hash->{'TRFsize'} eq "exact" ) {
            \$query .= "and pp.value = ? ";
            \$connector = ",";
            push \@args, \$hash->{'TRFrepSize'};
        }
        elsif ( \$hash->{'TRFsize'} eq "orLess" ) {
            \$query .= "and my_to_decimal(pp.value) <= ? ";
            \$connector = ",";
            push \@args, \$hash->{'TRFrepSize'};
        }
        elsif ( \$hash->{'TRFsize'} eq "orMore" ) {
            \$query .= "and my_to_decimal(pp.value) >= ? ";
            \$connector = ",";
            push \@args, \$hash->{'TRFrepSize'};
        }
        elsif ( \$hash->{'TRFsize'} eq "none" ) {
            \$query .= "and my_to_decimal(pp.value) = 0 ";
            \$connector = ",";
        }
    }

    if (   \$hash->{'TRFrepNumMin'} !~ /^\\s*\$/
        || \$hash->{'TRFrepNumMax'} !~ /^\\s*\$/ )
    {
        my \$min = 0;
        my \$max = 0;

        \$hash->{'TRFrepNumMin'} =~ s/\\s+//g;
        if ( \$hash->{'TRFrepNumMin'} ) {
            \$min++;
        }

        \$hash->{'TRFrepNumMax'} =~ s/\\s+//g;
        if ( \$hash->{'TRFrepNumMax'} ) {
            \$max++;
        }

        if ( \$min && \$max ) {
            if ( \$hash->{'TRFrepNumMin'} == \$hash->{'TRFrepNumMax'} ) {
                \$query .= "and my_to_decimal(pc.value) = ? ";
                push \@args, \$hash->{'TRFrepNumMax'};
            }
            elsif ( \$hash->{'TRFrepNumMin'} < \$hash->{'TRFrepNumMax'} ) {
                \$query .=
                "and my_to_decimal(pc.value) >= ? and my_to_decimal(pc.value) <= ? ";
                push \@args, \$hash->{'TRFrepNumMin'};
                push \@args, \$hash->{'TRFrepNumMax'};
            }
        }
        elsif (\$min) {
            \$query .= "and my_to_decimal(pc.value) >= ? ";
            push \@args, \$hash->{'TRFrepNumMin'};
        }
        elsif (\$max) {
            \$query .= "and my_to_decimal(pc.value) <= ? ";
            push \@args, \$hash->{'TRFrepNumMax'};
        }
    }

    \$query = \$select . \$join . \$query;

    if (   exists \$hash->{pageSize}
        && \$hash->{pageSize}
        && exists \$hash->{offset}
        && \$hash->{offset} )
    {
        \$query .= " LIMIT ? ";
        push \@args, \$hash->{pageSize};
        if ( \$hash->{offset} == 1 ) {
            \$query .= " OFFSET 0 ";
        }
        else {
            \$query .= " OFFSET ? ";
            push \@args, \$hash->{offset};
        }
    }

    my \$sth = \$dbh->prepare(\$query);
    print STDERR \$query;
    \$sth->execute(\@args);
    my \@rows = \@{ \$sth->fetchall_arrayref() };
    my \@list = ();
    my \%hash = ();

    use Report_HTML_DB::Models::Application::TRFSearch;
    for ( my \$i = 0 ; \$i < scalar \@rows ; \$i++ ) {
        my \$result = Report_HTML_DB::Models::Application::TRFSearch->new(
            contig      => \$rows[\$i][0],
            start       => \$rows[\$i][1],
            end         => \$rows[\$i][2],
            'length'    => \$rows[\$i][3],
            copy_number => \$rows[\$i][4],
            sequence    => \$rows[\$i][5],
            feature_id	=> \$rows[\$i][6],
        );
        push \@list, \$result;
        \$hash{total} = \$rows[\$i][7];
    }

    \$hash{list} = \\\@list;
    return \\\%hash;
}

=head2

Method used to return non coding RNAs data from database

=cut

sub ncRNA_search {
    my ( \$self, \$hash ) = \@_;
    my \$dbh  = \$self->dbh;
    my \@args = ();
    my \$select =
    "select distinct r.object_id AS id, fl.uniquename AS contig, l.fstart AS end, l.fend AS start, pp.value AS description, COUNT(*) OVER() AS total ";
    my \$join = " from feature_relationship r 
    join featureloc lc on (r.subject_id = lc.feature_id)
    join feature fl on (fl.feature_id = lc.srcfeature_id)
    join cvterm c on (r.type_id = c.cvterm_id)
    join featureloc l on (r.subject_id = l.feature_id)
    join analysisfeature af on (af.feature_id = r.object_id)
    join analysis a on (a.analysis_id = af.analysis_id)
    join featureprop p on (p.feature_id = l.srcfeature_id) 
    join cvterm cp on (p.type_id = cp.cvterm_id) 
    join featureprop pp on (pp.feature_id = r.subject_id) 
    join cvterm cpp on (pp.type_id = cpp.cvterm_id) ";
    my \$query =
    "where c.name='interval' and a.program = 'annotation_infernal.pl' and cp.name='pipeline_id' and p.value=? and cpp.name='target_description' ";
    push \@args, \$hash->{pipeline};

    if(exists \$hash->{contig} && \$hash->{contig}) {
        \$query .= " and l.srcfeature_id = ? ";
        push \@args, \$hash->{contig};
    }

    if ( \$hash->{'ncRNAtargetID'} !~ /^\\s*\$/ ) {
        \$hash->{'ncRNAtargetID'} =~ s/\\s+//g;
        \$select .= ", ppc.value AS Target_ID";
        \$join .=
        "join featureprop ppc on (ppc.feature_id = r.subject_id) join cvterm cppc on (ppc.type_id = cppc.cvterm_id) ";
        \$query .=
        "and cppc.name = 'target_identifier' and lower(ppc.value) LIKE ? ";
        push \@args, "\%" . lc( \$hash->{'ncRNAtargetID'} ) . "\%";
    }

    elsif ( \$hash->{'ncRNAevalue'} !~ /^\\s*\$/ || \$hash->{'ncRNAevM'} eq "none" ) {
        \$hash->{'ncRNAevalue'} =~ s/\\s+//g;
        \$select .= ", ppe.value AS evalue";
        \$join .=
        "join featureprop ppe on (ppe.feature_id = r.subject_id) join cvterm cppe on (ppe.type_id = cppe.cvterm_id) ";
        if ( \$hash->{'ncRNAevM'} eq "exact" ) {
            \$query .=
            "and cppe.name = 'evalue' and my_to_decimal(ppe.value) = ? ";
            push \@args, \$hash->{'ncRNAevalue'};
        }
        elsif ( \$hash->{'ncRNAevM'} eq "orLess" ) {
            \$query .=
            "and cppe.name = 'evalue' and my_to_decimal(ppe.value) <= ? ";
            push \@args, \$hash->{'ncRNAevalue'};
        }
        elsif ( \$hash->{'ncRNAevM'} eq "orMore" ) {
            \$query .=
            "and cppe.name = 'evalue' and my_to_decimal(ppe.value) >= ? ";
            push \@args, \$hash->{'ncRNAevalue'};
        }
        elsif ( \$hash->{'ncRNAevM'} eq "none" ) {
            \$query .=
            "and cppe.name = 'evalue' and my_to_decimal(ppe.value) = 0 ";
        }
    }
    elsif ( \$hash->{'ncRNAtargetName'} !~ /^\\s*\$/ ) {
        \$hash->{'ncRNAtargetName'} =~ s/^\\s+//;
        \$hash->{'ncRNAtargetName'} =~ s/\\s+\$//;
        \$select .= ", ppn.value AS Target_name";
        \$join .=
        "join featureprop ppn on (ppn.feature_id = r.subject_id) join cvterm cppn on (ppn.type_id = cppn.cvterm_id) ";
        \$query .= "and cppn.name = 'target_name' and lower(ppn.value) ilike ? ";
        push \@args, lc( "\%" . \$hash->{'ncRNAtargetName'} . "\%" );
    }

    elsif ( \$hash->{'ncRNAtargetClass'} !~ /^\\s*\$/ ) {
        \$select .= ", ppc.value AS Target_class";
        \$join .=
        "join featureprop ppc on (ppc.feature_id = r.subject_id) join cvterm cppc on (ppc.type_id = cppc.cvterm_id) ";
        \$query .= "and cppc.name = 'target_class' and ppc.value = ? ";
        push \@args, \$hash->{'ncRNAtargetClass'};
    }

    elsif ( \$hash->{'ncRNAtargetType'} !~ /^\\s*\$/ ) {
        \$hash->{'ncRNAtargetType'} =~ s/^\\s+//;
        \$hash->{'ncRNAtargetType'} =~ s/\\s+\$//;
        \$select .= ", ppt.value AS Target_type";
        \$join .=
        "join featureprop ppt on (ppt.feature_id = r.subject_id) join cvterm cppt on (ppt.type_id = cppt.cvterm_id) ";
        \$query .= "and cppt.name = 'target_type' and lower(ppt.value) ilike ? ";
        push \@args, lc( "\%" . \$hash->{'ncRNAtargetType'} . "\%" );
    }
    elsif ( \$hash->{'ncRNAtargetDesc'} !~ /^\\s*\$/ ) {
        \$hash->{'ncRNAtargetDesc'} =~ s/^\\s+//;
        \$hash->{'ncRNAtargetDesc'} =~ s/\\s+\$//;
        \$query .= "and lower(pp.value) like ? ";
        push \@args, lc( "\%" . \$hash->{'ncRNAtargetDesc'} . "\%" );
    }

    \$query = \$select . \$join . \$query . " ORDER BY fl.uniquename ASC, l.fstart ASC  ";

    if (   exists \$hash->{pageSize}
        && \$hash->{pageSize}
        && exists \$hash->{offset}
        && \$hash->{offset} )
    {
        \$query .= " LIMIT ? ";
        push \@args, \$hash->{pageSize};
        if ( \$hash->{offset} == 1 ) {
            \$query .= " OFFSET 0 ";
        }
        else {
            \$query .= " OFFSET ? ";
            push \@args, \$hash->{offset};
        }
    }

    my \$sth = \$dbh->prepare(\$query);
    print STDERR \$query;
    \$sth->execute(\@args);
    my \@rows = \@{ \$sth->fetchall_arrayref() };
    my \@list = ();
    my \%hash = ();
    use Report_HTML_DB::Models::Application::NcRNASearch;
    for ( my \$i = 0 ; \$i < scalar \@rows ; \$i++ ) {
        my \$result = Report_HTML_DB::Models::Application::NcRNASearch->new(
            id           => \$rows[\$i][0],
            contig       => \$rows[\$i][1],
            start        => \$rows[\$i][3],
            end          => \$rows[\$i][2],
            description  => \$rows[\$i][4],
            target_ID    => \$rows[\$i][6] ? \$rows[\$i][6] !~ '' : '',
            evalue       => \$rows[\$i][6] ? \$rows[\$i][6] !~ '' : '',
            target_name  => \$rows[\$i][6] ? \$rows[\$i][6] !~ '' : '',
            target_class => \$rows[\$i][6] ? \$rows[\$i][6] !~ '' : '',
            target_type  => \$rows[\$i][6] ? \$rows[\$i][6] !~ '' : ''

        );
        push \@list, \$result;
        \$hash{total} = \$rows[\$i][5];
    }
    \$hash{list} = \\\@list;
    return \\\%hash;
}

=head2

Method used to return transcriptional terminator data from database

=cut

sub transcriptional_terminator_search {
    my ( \$self, \$hash ) = \@_;
    my \$dbh  = \$self->dbh;
    my \@args = ();
    my \$select =
    "select fl.uniquename AS contig, l.fstart AS start, l.fend AS end, ppConfidence.value AS confidence, ppHairpinScore.value AS hairpin_score, ppTailScore.value AS tail_score, fl.feature_id, COUNT(*) OVER() AS total ";

    my \$join = " from feature_relationship r
    join featureloc lc on (r.subject_id = lc.feature_id)
    join feature fl on (fl.feature_id = lc.srcfeature_id)
    join cvterm c on (r.type_id = c.cvterm_id)
    join featureloc l on (r.subject_id = l.feature_id)
    join analysisfeature af on (af.feature_id = r.object_id)
    join analysis a on (a.analysis_id = af.analysis_id)
    join featureprop p on (p.feature_id = l.srcfeature_id)
    join cvterm cp on (p.type_id = cp.cvterm_id)
    join featureprop ppConfidence on (ppConfidence.feature_id = r.subject_id)
    join cvterm cppConfidence on (ppConfidence.type_id = cppConfidence.cvterm_id) 
    join featureprop ppHairpinScore on (ppHairpinScore.feature_id = r.subject_id)
    join cvterm cppHairpinScore on (ppHairpinScore.type_id = cppHairpinScore.cvterm_id) 
    join featureprop ppTailScore on (ppTailScore.feature_id = r.subject_id)
    join cvterm cppTailScore on (ppTailScore.type_id = cppTailScore.cvterm_id) ";
    my \$query =
    "where c.name='interval' and a.program = 'annotation_transterm.pl' and cp.name='pipeline_id' and p.value=? and cppConfidence.name = 'confidence' AND cppHairpinScore.name = 'hairpin' AND cppTailScore.name = 'tail' ";
    push \@args, \$hash->{pipeline};

    if(exists \$hash->{contig} && \$hash->{contig}) {
        \$query .= " and l.srcfeature_id = ? ";
        push \@args, \$hash->{contig};
    }

    my \$search_field;
    my \$field;
    my \$modifier;

    if ( \$hash->{'TTconf'} !~ /^\\s*\$/ || \$hash->{'TTconfM'} eq "none" ) {
        \$search_field = \$hash->{'TTconf'};
        \$modifier     = \$hash->{'TTconfM'};
        \$field        = "ppConfidence";
    }
    elsif ( \$hash->{'TThp'} !~ /^\\s*\$/ || \$hash->{'TThpM'} eq "none") {
        \$search_field = \$hash->{'TThp'};
        \$modifier     = \$hash->{'TThpM'};
        \$field        = "ppHairpinScore";
    }
    elsif ( \$hash->{'TTtail'} !~ /^\\s*\$/ || \$hash->{'TTtailM'} eq "none") {
        \$search_field = \$hash->{'TTtail'};
        \$modifier     = \$hash->{'TTtailM'};
        \$field        = "ppTailScore";
    }

    \$search_field =~ s/\\s+//g;

    if ( \$modifier eq "exact" ) {
        \$query .= " and my_to_decimal(\$field.value) = ? ";
        push \@args, (\$search_field ) if (\$search_field);
    }
    elsif ( \$modifier eq "orLess" ) {
        \$query .= " and my_to_decimal(\$field.value) <= ? ";
        push \@args, (\$search_field ) if (\$search_field);
    }
    elsif ( \$modifier eq "orMore" ) {
        \$query .= " and my_to_decimal(\$field.value) >= ? ";
        push \@args, (\$search_field ) if (\$search_field);
    }
    elsif ( \$modifier eq "none" ) {
        \$query .= " and my_to_decimal(\$field.value) = 0 ";
    }


    \$query = \$select . \$join . \$query;

    if (   exists \$hash->{pageSize}
        && \$hash->{pageSize}
        && exists \$hash->{offset}
        && \$hash->{offset} )
    {
        \$query .= " LIMIT ? ";
        push \@args, \$hash->{pageSize};
        if ( \$hash->{offset} == 1 ) {
            \$query .= " OFFSET 0 ";
        }
        else {
            \$query .= " OFFSET ? ";
            push \@args, \$hash->{offset};
        }
    }

    my \$sth = \$dbh->prepare(\$query);
    print STDERR \$query;
    \$sth->execute(\@args);
    my \@rows = \@{ \$sth->fetchall_arrayref() };
    my \%hash = ();
    my \@list    = ();
    my \@columns = \@{ \$sth->{NAME} };
    use Report_HTML_DB::Models::Application::TranscriptionalTerminator;
    for ( my \$i = 0 ; \$i < scalar \@rows ; \$i++ ) {
        my \$result = Report_HTML_DB::Models::Application::TranscriptionalTerminator->new(
            contig 			=> \$rows[\$i][0],
            start  			=> \$rows[\$i][1],
            end    			=> \$rows[\$i][2],
            confidence    	=> \$rows[\$i][3],
            hairpin_score  	=> \$rows[\$i][4],
            tail_score    	=> \$rows[\$i][5],
            feature_id		=> \$rows[\$i][6],
        );
        push \@list, \$result;
        \$hash{total} = \$rows[\$i][7];
    }
    \$hash{list} = \\\@list;
    return \\\%hash;
}

=head2

Method used to return ribosomal binding sites data from database

=cut

sub rbs_search {
    my ( \$self, \$hash ) = \@_;
    my \$dbh  = \$self->dbh;
    my \@args = ();
    my \$select =
    "select fl.uniquename AS contig, l.fstart AS start, l.fend AS end, fl.feature_id, ppSitePattern.value AS site_pattern, ppPositionShift.value AS position_shift, ".
    " ppOldStart.value AS old_start, ppOldPosition.value AS old_position, COUNT(*) OVER() AS total, pp2.value AS new_start  ";

#	if ( \$hash->{'RBSpattern'} !~ /^\\s*\$/ ) {
#		\$select .= " AS site_pattern";
#	}
#	elsif ( \$hash->{'RBSnewcodon'} !~ /^\\s*\$/ ) {
#		\$select .= " AS old_start";
#	}
#	else {
#		\$select .= " AS position_shift";
#	}
    my \$join = " from feature_relationship r
    join featureloc lc on (r.subject_id = lc.feature_id) 
    join feature fl on (fl.feature_id = lc.srcfeature_id) 
    join cvterm c on (r.type_id = c.cvterm_id)
    join featureloc l on (r.subject_id = l.feature_id)
    join analysisfeature af on (af.feature_id = r.object_id)
    join analysis a on (a.analysis_id = af.analysis_id)
    join featureprop p on (p.feature_id = l.srcfeature_id)
    join cvterm cp on (p.type_id = cp.cvterm_id)
    join featureprop ppSitePattern on (ppSitePattern.feature_id = r.subject_id)
    join cvterm cppSitePattern on (ppSitePattern.type_id = cppSitePattern.cvterm_id) 
    join featureprop ppOldStart on (ppOldStart.feature_id = r.subject_id)
    join cvterm cppOldStart on (ppOldStart.type_id = cppOldStart.cvterm_id)
    join featureprop ppPositionShift on (ppPositionShift.feature_id = r.subject_id)
    join cvterm cppPositionShift on (ppPositionShift.type_id = cppPositionShift.cvterm_id) 
    join featureprop pp2 on (pp2.feature_id = r.subject_id) 
    join cvterm cpp2 on (pp2.type_id = cpp2.cvterm_id) 
    join featureprop ppOldPosition on (ppOldPosition.feature_id = r.subject_id)
    join cvterm cppOldPosition on (ppOldPosition.type_id = cppOldPosition.cvterm_id) ";
    my \$query =
    "where c.name='interval' and a.program = 'annotation_rbsfinder.pl' and cp.name='pipeline_id' and p.value=? ".
    " and cppSitePattern.name='RBS_pattern' and cppOldStart.name='old_start_codon' and cppPositionShift.name='position_shift'  and cpp2.name='new_start_codon' and cppOldPosition.name='old_position' ";
    push \@args, \$hash->{pipeline};

    if(exists \$hash->{contig} && \$hash->{contig}) {
        \$query .= " and l.srcfeature_id = ? ";
        push \@args, \$hash->{contig};
    }

    if ( \$hash->{'RBSpattern'} !~ /^\\s*\$/ ) {
        \$hash->{'RBSpattern'} =~ s/\\s*//g;
        \$query .= " and lower(ppSitePattern.value) like ? ";
        push \@args, lc( "\%" . \$hash->{'RBSpattern'} . "\%" );
    }
    elsif ( \$hash->{'RBSshift'} ) {
        if ( \$hash->{'RBSshiftM'} eq "both" ) {
            \$query .= " and ppPositionShift.value != '0'";
        }
        elsif ( \$hash->{'RBSshiftM'} eq "neg" ) {
            \$query .=
            " and my_to_decimal(ppPositionShift.value) < '0'";
        }
        elsif ( \$hash->{'RBSshiftM'} eq "pos" ) {
            \$query .=
            " and my_to_decimal(ppPositionShift.value) >= '0'";
        }
    }
    elsif ( \$hash->{'RBSnewcodon'} ) {
        \$query .= " and (ppOldStart.value != pp2.value) ";
    }

    \$query = \$select . \$join . \$query;
    if (   exists \$hash->{pageSize}
        && \$hash->{pageSize}
        && exists \$hash->{offset}
        && \$hash->{offset} )
    {
        \$query .= " LIMIT ? ";
        push \@args, \$hash->{pageSize};
        if ( \$hash->{offset} == 1 ) {
            \$query .= " OFFSET 0 ";
        }
        else {
            \$query .= " OFFSET ? ";
            push \@args, \$hash->{offset};
        }
    }

    my \$sth = \$dbh->prepare(\$query);
    print STDERR \$query;
    \$sth->execute(\@args);
    my \@rows = \@{ \$sth->fetchall_arrayref() };
    my \@list = ();
    my \%hash = ();
    my \@columns = \@{ \$sth->{NAME} };
    use Report_HTML_DB::Models::Application::RBSSearch;
    for ( my \$i = 0 ; \$i < scalar \@rows ; \$i++ ) {
        my \$result = Report_HTML_DB::Models::Application::RBSSearch->new(
            contig 			=> \$rows[\$i][0],
            start  			=> \$rows[\$i][2],
            end    			=> \$rows[\$i][1],
            feature_id 		=> \$rows[\$i][3],
            site_pattern	=> \$rows[\$i][4],
            position_shift	=> \$rows[\$i][5],
            old_start		=> \$rows[\$i][6],
            old_position    => \$rows[\$i][7]
        );

        if ( \$columns[9] eq "new_start" ) {
            \$result->setNewStart( \$rows[\$i][9] );
        }
        \$hash{total} = \$rows[\$i][8];
        push \@list, \$result;
    }
    \$hash{list} = \\\@list;
    return \\\%hash;
}

=head2

Method used to return horizontal transferences data from database

=cut

sub alienhunter_search {
    my ( \$self, \$hash ) = \@_;
    my \$dbh  = \$self->dbh;
    my \@args = ();
    my \$select =
    "select r.object_id AS id, fl.uniquename AS contig, l.fstart AS start, l.fend AS end, ppLength.value AS length, ppScore.value AS score, ppThreshold.value AS threshold, fl.feature_id, COUNT(*) OVER() AS total ";

    my \$join = " from feature_relationship r
    join featureloc lc on (r.subject_id = lc.feature_id) 
    join feature fl on (fl.feature_id = lc.srcfeature_id) 
    join cvterm c on (r.type_id = c.cvterm_id) 
    join featureloc l on (r.subject_id = l.feature_id) 
    join analysisfeature af on (af.feature_id = r.object_id) 
    join analysis a on (a.analysis_id = af.analysis_id) 
    join featureprop p on (p.feature_id = l.srcfeature_id) 
    join cvterm cp on (p.type_id = cp.cvterm_id) 
    join featureprop ppLength on (ppLength.feature_id = r.subject_id) 
    join cvterm cppLength on (ppLength.type_id = cppLength.cvterm_id) 
    join featureprop ppScore on (ppScore.feature_id = r.subject_id) 
    join cvterm cppScore on (ppScore.type_id = cppScore.cvterm_id) 
    join featureprop ppThreshold on (ppThreshold.feature_id = r.subject_id) 
    join cvterm cppThreshold on (ppThreshold.type_id = cppThreshold.cvterm_id) ";
    my \$query =
    "where c.name='interval' and a.program = 'annotation_alienhunter.pl' and cp.name='pipeline_id' and p.value=? and cppLength.name = 'length' and cppScore.name = 'score' and cppThreshold.name = 'threshold' ";
    push \@args, \$hash->{pipeline};

    if(exists \$hash->{contig} && \$hash->{contig}) {
        \$query .= " and l.srcfeature_id = ? ";
        push \@args, \$hash->{contig};
    }

    my \$search_field;
    my \$field;
    my \$modifier;

    if ( \$hash->{'AHlen'} !~ /^\\s*\$/ || \$hash->{'AHlenM'} eq "none") {
        \$search_field = \$hash->{'AHlen'} + 1;
        \$modifier     = \$hash->{'AHlenM'};
        \$field		  = "ppLength";
    }
    elsif ( \$hash->{'AHscore'} !~ /^\\s*\$/ || \$hash->{'AHscM'} eq "none" ) {
        \$search_field = \$hash->{'AHscore'} + 1;
        \$modifier     = \$hash->{'AHscM'};
        \$field		  = "ppScore";
    }
    elsif ( \$hash->{'AHthr'} !~ /^\\s*\$/ || \$hash->{'AHthrM'} eq "none" ) {
        \$search_field = \$hash->{'AHthr'} + 1;
        \$modifier     = \$hash->{'AHthrM'};
        \$field		  = "ppThreshold";
    }

    \$search_field =~ s/\\s+//g;

    if ( \$modifier eq "exact" ) {
        \$query .= " and my_to_decimal(\$field.value) = ? ";
        push \@args, (\$search_field) if \$search_field;
    }
    elsif ( \$modifier eq "orLess" ) {
        \$query .= " and my_to_decimal(\$field.value) <= ? ";
        push \@args, (\$search_field) if \$search_field;
    }
    elsif ( \$modifier eq "orMore" ) {
        \$query .= " and my_to_decimal(\$field.value) >= ? ";
        push \@args, (\$search_field) if \$search_field;
    }
    elsif ( \$modifier eq "none" ) {
        \$query .= " and my_to_decimal(\$field.value) = 0 ";
    }


    \$query = \$select . \$join . \$query;

    if (   exists \$hash->{pageSize}
        && \$hash->{pageSize}
        && exists \$hash->{offset}
        && \$hash->{offset} )
    {
        \$query .= " LIMIT ? ";
        push \@args, \$hash->{pageSize};
        if ( \$hash->{offset} == 1 ) {
            \$query .= " OFFSET 0 ";
        }
        else {
            \$query .= " OFFSET ? ";
            push \@args, \$hash->{offset};
        }
    }

    my \$sth = \$dbh->prepare(\$query);
    print STDERR \$query;
    \$sth->execute(\@args);
    my \@rows = \@{ \$sth->fetchall_arrayref() };
    my \@list = ();
    my \%hash = ();
    my \@columns = \@{ \$sth->{NAME} };
    use Report_HTML_DB::Models::Application::AlienHunterSearch;
    for ( my \$i = 0 ; \$i < scalar \@rows ; \$i++ ) {
        my \$result = Report_HTML_DB::Models::Application::AlienHunterSearch->new(
            id     		=> \$rows[\$i][0],
            contig 		=> \$rows[\$i][1],
            start  		=> \$rows[\$i][2],
            end    		=> \$rows[\$i][3],
            length 		=> \$rows[\$i][4],
            score  		=> \$rows[\$i][5],
            threshold 	=> \$rows[\$i][6],
            feature_id	=> \$rows[\$i][7],
        );

        \$hash{total} = \$rows[\$i][8];
        push \@list, \$result;
    }
    \$hash{list} = \\\@list;
    return \\\%hash;
}

=head2

Method used to return the reverse complement

=cut

sub reverseComplement {
    my (\$sequence) = \@_;
    my \$reverseComplement = reverse(\$sequence);
    \$reverseComplement =~ tr/ACGTacgt/TGCAtgca/;
    return \$reverseComplement;
}

=head2

Method used to realize search by feature

=cut

sub searchGene {
    my ( \$self, \$hash ) = \@_;
    my \$dbh  = \$self->dbh;
    my \@args = ();
    my \$query =
    "SELECT me.feature_id AS feature_id, feature_relationship_props_subject_feature.value AS name, feature_relationship_props_subject_feature_2.value AS uniquename, "
    . "featureloc_features_2.fstart AS fstart, featureloc_features_2.fend AS fend, featureprops_2.value AS type,  COUNT(*) OVER() AS total "
    . "FROM feature me "
    . "LEFT JOIN feature_relationship feature_relationship_objects_2 ON feature_relationship_objects_2.object_id = me.feature_id "
    . "LEFT JOIN featureprop feature_relationship_props_subject_feature ON feature_relationship_props_subject_feature.feature_id = feature_relationship_objects_2.subject_id "
    . "LEFT JOIN cvterm type ON type.cvterm_id = feature_relationship_props_subject_feature.type_id "
    . "LEFT JOIN cvterm type_2 ON type_2.cvterm_id = feature_relationship_objects_2.type_id "
    . "LEFT JOIN featureloc featureloc_features_2 ON featureloc_features_2.feature_id = me.feature_id "
    . "LEFT JOIN featureprop featureloc_featureprop ON featureloc_featureprop.feature_id = featureloc_features_2.srcfeature_id "
    . "LEFT JOIN cvterm type_3 ON type_3.cvterm_id = featureloc_featureprop.type_id "
    . "LEFT JOIN feature_relationship feature_relationship_objects_4 ON feature_relationship_objects_4.object_id = me.feature_id "
    . "LEFT JOIN featureprop feature_relationship_props_subject_feature_2 ON feature_relationship_props_subject_feature_2.feature_id = feature_relationship_objects_4.subject_id "
    . "LEFT JOIN cvterm type_4 ON type_4.cvterm_id = feature_relationship_props_subject_feature_2.type_id "
    . "LEFT JOIN featureprop featureprops_2 ON featureprops_2.feature_id = me.feature_id "
    . "LEFT JOIN cvterm type_5 ON type_5.cvterm_id = featureprops_2.type_id "
    . "LEFT JOIN feature ff ON ff.feature_id = featureloc_features_2.srcfeature_id ";
    my \$where =
    "WHERE type.name = 'locus_tag' AND type_2.name = 'based_on' AND type_3.name = 'pipeline_id' AND type_4.name = 'description' AND type_5.name = 'tag' AND featureloc_featureprop.value = ? ";
    push \@args, \$hash->{pipeline};

    if(exists \$hash->{contig} && \$hash->{contig}) {
        \$where .= " AND featureloc_features_2.srcfeature_id = ? ";
        push \@args, \$hash->{contig};
    }

    my \$connector = "";
    if ( exists \$hash->{featureId} && \$hash->{featureId} ) {
        if ( index( \$hash->{featureId}, " " ) != -1 ) {
            \$where .= " AND (";
            while ( \$hash->{featureId} =~ /(\\d+)+/g ) {
                \$connector = " OR " if \$connector;
                \$where .= \$connector . "me.feature_id = ? ";
                push \@args, \$1;
                \$connector = "1";
            }
            \$where .= ")";
        }
        else {

            \$where .= " AND me.feature_id = ? ";
            push \@args, \$hash->{featureId};
            \$connector = "1";
        }
    }

    if (   ( exists \$hash->{geneDescription} && \$hash->{geneDescription} )
            or ( exists \$hash->{noDescription} && \$hash->{noDescription} ) )
    {
        \$connector = " AND " if \$connector;
        \$where .= \$connector;
        my \@likesDescription   = ();
        my \@likesNoDescription = ();
        if ( \$hash->{geneDescription} ) {
            while ( \$hash->{geneDescription} =~ /(\\S+)/g ) {
                push \@likesDescription,
                generate_clause( "?", "", "",
                    "lower(feature_relationship_props_subject_feature_2.value)"
                );
                push \@args, lc( "\%" . \$1 . "\%" );
            }
        }
        if ( \$hash->{noDescription} ) {
            while ( \$hash->{noDescription} =~ /(\\S+)/g ) {
                push \@likesNoDescription,
                generate_clause( "?", "NOT", "",
                    "lower(feature_relationship_props_subject_feature_2.value)"
                );
                push \@args, lc( "\%" . \$1 . "\%" );
            }
        }

        if (    exists \$hash->{individually}
                and \$hash->{individually}
                and scalar(\@likesDescription) > 0 )
        {
            if ( scalar(\@likesNoDescription) > 0 ) {
                foreach my \$like (\@likesDescription) {
                    \$where .= " AND " . \$like;
                }
                foreach my \$notLike (\@likesNoDescription) {
                    \$where .= " AND " . \$notLike;
                }
            }
            else {
                foreach my \$like (\@likesDescription) {
                    \$where .= " AND " . \$like;
                }
            }
        }
        elsif ( scalar(\@likesDescription) > 0 ) {
            my \$and = "";
            if ( scalar(\@likesNoDescription) > 0 ) {
                foreach my \$notLike (\@likesNoDescription) {
                    \$where .= " AND " . \$notLike;
                }
                \$and = "1";
            }
            if (\$and) {
                \$and = " AND ";
            }
            else {
                \$and = " OR ";
            }
            \$where .= " AND (";
            my \$counter = 0;
            foreach my \$like (\@likesDescription) {
                if ( \$counter == 0 ) {
                    \$where .= \$like;
                    \$counter++;
                }
                else {
                    \$where .= \$and . \$like;
                }
            }
            \$where .= " ) ";
        }
        elsif ( scalar(\@likesDescription) <= 0
                and scalar(\@likesNoDescription) > 0 )
        {
            foreach my \$like (\@likesNoDescription) {
                \$where .= " AND " . \$like;
            }
        }
    }

    if ( exists \$hash->{geneID} && \$hash->{geneID} ) {
        \$where .=
        " AND lower(feature_relationship_props_subject_feature.value) LIKE ? ";
        push \@args, lc( "\%" . \$hash->{geneID} . "\%" );
    }

    \$where .= " ORDER BY ff.uniquename ASC, featureloc_features_2.fstart ASC ";

    if (   exists \$hash->{pageSize}
        && \$hash->{pageSize}
        && exists \$hash->{offset}
        && \$hash->{offset} )
    {
        \$where .= " LIMIT ? ";
        push \@args, \$hash->{pageSize};
        if ( \$hash->{offset} == 1 ) {
            \$where .= " OFFSET 0 ";
        }
        else {
            \$where .= " OFFSET ? ";
            push \@args, \$hash->{offset};
        }
    }

    \$query .= \$where;

    my \$sth = \$dbh->prepare(\$query);
    print STDERR \$query;
    \$sth->execute(\@args);
    my \@rows = \@{ \$sth->fetchall_arrayref() };
    my \%returnedHash = ();
    my \@list         = ();

    use Report_HTML_DB::Models::Application::Feature;
    for ( my \$i = 0; \$i < scalar \@rows ; \$i++ ) {
        my \$feature;
        if(\$rows[\$i][5] eq "CDS") {
            my \%hashBlast = ();
            \$hashBlast{pipeline_id} = \$hash->{pipeline};
            \$hashBlast{feature_id} = \$rows[\$i][0];
            my \$identifierDescriptionHash = getIdentifierAndDescriptionSimilarity(\$self, getFirstBlastResult(\$self, \\\%hashBlast)->{feature_id});
            my \$uniquename =(\$identifierDescriptionHash->{description} ? \$identifierDescriptionHash->{description} : \$rows[\$i][2]) ;
            \$uniquename =~ s/\\w+\\_*\\.+\\w\\s//g;
            \$uniquename =~ s/\\w*_[\\w\\d]*//g;
            \$feature = Report_HTML_DB::Models::Application::Feature->new(
                feature_id => \$rows[\$i][0],
                uniquename => \$uniquename,
                name       => \$rows[\$i][1],
                fstart     => \$rows[\$i][3],
                fend       => \$rows[\$i][4],
                type       => \$rows[\$i][5],
            );
        } else {
            my \$uniquename = \$rows[\$i][2];
            \$uniquename =~ s/\\w+\\_*\\.+\\w\\s//g;
            \$uniquename =~ s/\\w*_[\\w\\d]*//g; 
            \$feature = Report_HTML_DB::Models::Application::Feature->new(
                feature_id => \$rows[\$i][0],
                uniquename => \$uniquename,
                name       => \$rows[\$i][1],
                fstart     => \$rows[\$i][3],
                fend       => \$rows[\$i][4],
                type       => \$rows[\$i][5],
            );
        }
        \$returnedHash{total} = \$rows[\$i][6];
        push \@list, \$feature;
    }
    \$returnedHash{list} = \\\@list;

    return \\\%returnedHash;
}

sub getFirstBlastResult {
    my (\$self, \$hash) = \@_;
    my \$dbh  = \$self->dbh;
    my \@args = ();
    my \$query = "SELECT DISTINCT f.feature_id
    FROM feature f
    JOIN feature_relationship r ON (r.subject_id = f.feature_id)
    JOIN feature fo ON (r.object_id = fo.feature_id)
    JOIN analysisfeature af ON (f.feature_id = af.feature_id)
    JOIN analysis a ON (a.analysis_id = af.analysis_id)
    JOIN analysisprop ap ON (ap.analysis_id = a.analysis_id)
    JOIN featureloc l ON (r.object_id = l.feature_id)
    JOIN featureprop p ON (p.feature_id = srcfeature_id)
    JOIN cvterm c ON (p.type_id = c.cvterm_id)
    JOIN feature_relationship ra ON (ra.object_id = f.feature_id)
    JOIN cvterm cra ON (ra.type_id = cra.cvterm_id)
    JOIN featureprop pfo ON (ra.subject_id = pfo.feature_id)
    JOIN cvterm cpfo ON (cpfo.cvterm_id = pfo.type_id)
    JOIN featureprop pr ON (r.object_id = pr.feature_id)
    JOIN cvterm cpr ON (pr.type_id = cpr.cvterm_id)
    WHERE a.program = 'annotation_blast.pl'
    AND c.name ='pipeline_id'
    AND p.value = ?
    AND cra.name = 'alignment'
    AND cpfo.name = 'subject_id'
    AND r.object_id = ?
    AND ap.value LIKE '%database_code=INSD%' LIMIT 1";

    push \@args, \$hash->{pipeline_id};
    push \@args, \$hash->{feature_id};
    my \$sth = \$dbh->prepare(\$query);
    \$sth->execute(\@args);
    my \@rows = \@{ \$sth->fetchall_arrayref() };
    my \%hash  = ();
    \$hash{feature_id} = \$rows[0][0];
    return \\\%hash;
}

=head2

Method used to realize search for basic content of any feature
=cut

sub geneBasics {
    my ( \$self, \$hash ) = \@_;
    my \$dbh  = \$self->dbh;
    my \@args = ();
    my \$query = "
    SELECT srcfeature.feature_id AS feature_id, feature_relationship_props_subject_feature.value AS name, srcfeature.uniquename AS uniquename, 
    featureloc_features_2.fstart AS	fstart, featureloc_features_2.fend AS fend, featureprops_2.value AS value, a.program
    FROM feature me
    LEFT JOIN feature_relationship feature_relationship_objects_2 ON feature_relationship_objects_2.object_id = me.feature_id    
    LEFT JOIN featureprop feature_relationship_props_subject_feature ON feature_relationship_props_subject_feature.feature_id = feature_relationship_objects_2.subject_id
    LEFT JOIN cvterm type ON type.cvterm_id = feature_relationship_props_subject_feature.type_id
    LEFT JOIN cvterm type_2 ON type_2.cvterm_id = feature_relationship_objects_2.type_id
    LEFT JOIN featureprop featureprops_2 ON featureprops_2.feature_id = me.feature_id
    LEFT JOIN cvterm type_3 ON type_3.cvterm_id = featureprops_2.type_id
    LEFT JOIN featureloc featureloc_features_2 ON featureloc_features_2.feature_id = me.feature_id
    LEFT JOIN feature srcfeature ON srcfeature.feature_id = featureloc_features_2.srcfeature_id
    LEFT JOIN featureprop featureloc_featureprop ON featureloc_featureprop.feature_id = featureloc_features_2.srcfeature_id
    LEFT JOIN cvterm type_4 ON type_4.cvterm_id = featureloc_featureprop.type_id 
    LEFT JOIN feature_relationship feature_relationship_objects_4 ON feature_relationship_objects_4.object_id = me.feature_id
    LEFT JOIN featureprop feature_relationship_props_subject_feature_2 ON feature_relationship_props_subject_feature_2.feature_id = feature_relationship_objects_4.subject_id
    LEFT JOIN cvterm type_5 ON type_5.cvterm_id = feature_relationship_props_subject_feature_2.type_id
    LEFT JOIN analysisfeature af ON (af.feature_id = me.feature_id)
    LEFT JOIN analysis_relationship ar ON (ar.object_id = af.analysis_id)
    LEFT JOIN analysis a ON (a.analysis_id = ar.subject_id)
    WHERE ( ( featureloc_featureprop.value = ? AND me.feature_id = ? AND type.name =
    'locus_tag' AND type_2.name = 'based_on' AND type_3.name = 'tag' AND
    type_4.name = 'pipeline_id' AND type_5.name = 'description' ) )
    GROUP BY srcfeature.feature_id,
    feature_relationship_props_subject_feature.value,
    feature_relationship_props_subject_feature_2.value,
    featureloc_features_2.fstart, featureloc_features_2.fend,
    featureprops_2.value, a.program ";
    push \@args, \$hash->{pipeline};
    push \@args, \$hash->{feature_id};
    my \$sth = \$dbh->prepare(\$query);
    print STDERR \$query;
    \$sth->execute(\@args);
    my \@rows = \@{ \$sth->fetchall_arrayref() };
    my \@list = ();

    use Report_HTML_DB::Models::Application::Feature;
    for ( my \$i = 0 ; \$i < scalar \@rows ; \$i++ ) {
        my \$feature = Report_HTML_DB::Models::Application::Feature->new(
            feature_id => \$rows[\$i][0],
            name       => \$rows[\$i][1],
            uniquename => \$rows[\$i][2],
            fstart     => \$rows[\$i][3],
            fend       => \$rows[\$i][4],
            type       => \$rows[\$i][5],
            predictor  => \$rows[\$i][6]
        );
        push \@list, \$feature;
    }

    return \\\@list;
}

=head2

Method used to get gene by position

=cut

sub geneByPosition {
    my ( \$self, \$hash ) = \@_;
    my \$dbh  = \$self->dbh;
    my \@args = ();
    my \$query =
    "SELECT me.feature_id AS feature_id, COUNT(*) OVER() AS total "
    . "FROM feature me "
    . "LEFT JOIN feature_relationship feature_relationship_objects_2 ON feature_relationship_objects_2.object_id = me.feature_id "
    . "LEFT JOIN featureprop feature_relationship_props_subject_feature ON feature_relationship_props_subject_feature.feature_id = feature_relationship_objects_2.subject_id "
    . "LEFT JOIN cvterm type ON type.cvterm_id = feature_relationship_props_subject_feature.type_id "
    . "LEFT JOIN cvterm type_2 ON type_2.cvterm_id = feature_relationship_objects_2.type_id "
    . "LEFT JOIN featureprop featureprops_2 ON featureprops_2.feature_id = me.feature_id "
    . "LEFT JOIN cvterm type_3 ON type_3.cvterm_id = featureprops_2.type_id "
    . "LEFT JOIN featureloc featureloc_features_2 ON featureloc_features_2.feature_id = me.feature_id "
    . "LEFT JOIN feature srcfeature ON srcfeature.feature_id = featureloc_features_2.srcfeature_id "
    . "LEFT JOIN featureprop featureloc_featureprop ON featureloc_featureprop.feature_id = featureloc_features_2.srcfeature_id "
    . "LEFT JOIN cvterm type_4 ON type_4.cvterm_id = featureloc_featureprop.type_id "
    . "WHERE ( ( featureloc_featureprop.value = ? AND featureloc_features_2.fstart >= ? AND featureloc_features_2.fend <= ? AND featureloc_features_2.srcfeature_id = ? AND type.name = 'locus_tag' AND type_2.name = 'based_on' AND type_3.name = 'tag' AND type_4.name = 'pipeline_id' ) ) "
    . "GROUP BY me.feature_id, featureloc_features_2.fstart, featureloc_features_2.fend, featureprops_2.value, srcfeature.uniquename, srcfeature.feature_id "
    . "ORDER BY MIN( feature_relationship_props_subject_feature.value )";
    push \@args, \$hash->{pipeline};
    push \@args, \$hash->{start};
    push \@args, \$hash->{end};
    push \@args, \$hash->{contig};

    if (   exists \$hash->{pageSize}
        && \$hash->{pageSize}
        && exists \$hash->{offset}
        && \$hash->{offset} )
    {
        \$query .= " LIMIT ? ";
        push \@args, \$hash->{pageSize};
        if ( \$hash->{offset} == 1 ) {
            \$query .= " OFFSET 0 ";
        }
        else {
            \$query .= " OFFSET ? ";
            push \@args, \$hash->{offset};
        }
    }
    my \$sth = \$dbh->prepare(\$query);
    print STDERR \$query;
    \$sth->execute(\@args);
    my \@rows = \@{ \$sth->fetchall_arrayref() };
    my \%hash = ();
    my \@list = ();

    for ( my \$i = 0 ; \$i < scalar \@rows ; \$i++ ) {
        push \@list, \$rows[\$i][0];
        \$hash{total} = \$rows[\$i][1];
    }

    \$hash{list} = \\\@list;

    return \\\%hash;
}


=head2

Method used to realize search by subevidences

=cut

sub subevidences {
    my ( \$self, \$feature_id ) = \@_;
    my \$dbh  = \$self->dbh;
    my \@args = ();
    my \$query =
    "SELECT subev_id, subev_type, subev_number, subev_start, subev_end, subev_strand, is_obsolete, program FROM get_subevidences(?) ORDER BY subev_id ASC";
    push \@args, \$feature_id;

    my \$sth = \$dbh->prepare(\$query);
    print STDERR \$query;
    \$sth->execute(\@args);
    my \@rows = \@{ \$sth->fetchall_arrayref() };

    my \%component_name = (
        'annotation_interpro.pl' => 'InterProScan - Domain search',
        'annotation_blast.pl'    => 'BLAST - Similarity search',
        'annotation_rpsblast.pl' => 'RPS-BLAST - Domain search',
        'annotation_phobius.pl' =>
        'Phobius - Transmembrane domains and signal peptide',
        'annotation_pathways.pl'  => 'KEGG - Pathway mapping',
        'annotation_orthology.pl' => 'eggNOG - Orthology assignment',
        'annotation_tcdb.pl'      => 'TCDB - Transporter classification',
        'annotation_dgpi.pl'      => 'DGPI - GPI anchor',
        'annotation_predgpi.pl'	=> 'PreDGPI',
        'annotation_tmhmm.pl'     => 'TMHMM - Transmembrane domains',
        'annotation_hmmer.pl'	=> 'HMMER',
        "annotation_signalP.pl" => 'SignalP - Signal peptide',
        'annotation_bigpi.pl'   => 'BIGPI',
    );

    my \@list = ();
    use Report_HTML_DB::Models::Application::Subevidence;
    for ( my \$i = 0 ; \$i < scalar \@rows ; \$i++ ) {
        my \$subevidence = Report_HTML_DB::Models::Application::Subevidence->new(
            id                  => \$rows[\$i][0],
            type                => \$rows[\$i][1],
            number              => \$rows[\$i][2],
            start               => \$rows[\$i][3],
            end                 => \$rows[\$i][4],
            strand              => \$rows[\$i][5],
            is_obsolete         => \$rows[\$i][6],
            program             => \$rows[\$i][7],
            program_description => \$component_name{ \$rows[\$i][7] }
        );
        push \@list, \$subevidence;
    }

    return \\\@list;
}

=head2

Method used to realize search by interval evidence properties

=cut

sub intervalEvidenceProperties {
    my ( \$self, \$feature_id ) = \@_;
    my \$dbh = \$self->dbh;

    my \$query =
    "select c.name, p.value, l.fstart, l.fend 
    from featureprop p 
    join cvterm c on (p.type_id = c.cvterm_id) 
    join feature_relationship r on (r.subject_id = p.feature_id) 
    join cvterm cr on (r.type_id = cr.cvterm_id) 
    join featureloc l on (r.subject_id = l.feature_id)
    where cr.name='interval' and r.object_id=? ORDER BY r.subject_id ASC;";

    my \$sth = \$dbh->prepare(\$query);
    print STDERR \$query;
    \$sth->execute(\$feature_id);
    my \@rows = \@{ \$sth->fetchall_arrayref() };

    my \@list = ();
    my \%property = ();

    for ( my \$i = 0 ; \$i < scalar \@rows ; \$i++ ) {
        my \%hash = ();

        \$hash{ key } = \$rows[\$i][0];
        \$hash{ key_value } = \$rows[\$i][1];
        \$hash{ fstart } = \$rows[\$i][2];
        \$hash{ fend } = \$rows[\$i][3];

        if ( !exists \$property{ \$hash{key} } ) {
            if ( \$hash{key} eq "anticodon" ) {
                \$property{ \$hash{key} } = \$hash{key_value};
                \$property{codon} = reverseComplement( \$hash{key_value} );
            }
            else {
                \$property{ \$hash{key} } = \$hash{key_value};
            }
            \$property{ fstart } = \$hash{fstart};
            \$property{ fend } = \$hash{fend};
        }
        else {
            my \%tempHash = ();
            foreach my \$key ( keys \%property ) {
                if ( defined \$key && \$key ) {
                    \$tempHash{\$key} = \$property{\$key};
                }
            }
            push \@list, \\\%tempHash;
            \%property = ();
            if ( \$hash{key} eq "anticodon" ) {
                \$property{ \$hash{key} } = \$hash{key_value};
                \$property{codon} = reverseComplement( \$hash{key_value} );
            }
            else {
                \$property{ \$hash{key} } = \$hash{key_value};
            }
            \$property{ fstart } = \$hash{fstart};
            \$property{ fend } = \$hash{fend};
        }
    }
    push \@list, \\\%property if scalar \@list == 0;

    return \\\@list;
}

=head2

Method used to realize search by similarity evidence properties

=cut

sub similarityEvidenceProperties {
    my ( \$self, \$feature_id ) = \@_;
    my \$dbh = \$self->dbh;

    my \$query =
    "SELECT key, key_value FROM get_similarity_evidence_properties(?)";

    my \$sth = \$dbh->prepare(\$query);
    print STDERR \$query;
    \$sth->execute(\$feature_id);
    my \@rows = \@{ \$sth->fetchall_arrayref() };

    my \@list    = ();
    my \@columns = \@{ \$sth->{NAME} };

    for ( my \$i = 0 ; \$i < scalar \@rows ; \$i++ ) {
        my \%hash = ();
        for ( my \$j = 0 ; \$j < scalar \@columns ; \$j++ ) {
            \$hash{ \$columns[\$j] } = \$rows[\$i][\$j];
        }
        push \@list, \\\%hash;
    }
    my \%returnedhash = ();
    for ( my \$i = 0 ; \$i < scalar \@list ; \$i++ ) {
        my \$result = \$list[\$i];
        if ( \$result->{key} eq "anticodon" ) {
            \$returnedhash{ \$result->{key} } = \$result->{key_value};
            \$returnedhash{codon} = reverseComplement( \$result->{key_value} );
        }
        else {
            \$returnedhash{ \$result->{key} } = \$result->{key_value};
        }
    }
    \$returnedhash{id} = \$feature_id;

    return \\\%returnedhash;

}

=head2

Method used to get identifier and description of similarity

=cut

sub getIdentifierAndDescriptionSimilarity {
    my (\$self, \$feature_id) = \@_;
    my \$dbh = \$self->dbh;

    my \$query =
    "select p.value from feature_relationship r 
    join feature q on (r.subject_id = q.feature_id)         
    join featureprop p on (p.feature_id = r.subject_id)
    join cvterm c on (p.type_id = c.cvterm_id)
    join cvterm cr on (r.type_id = cr.cvterm_id)
    join cvterm cq on (q.type_id = cq.cvterm_id)
    where cr.name='alignment' 
        and cq.name='subject_sequence' and c.name='subject_id' and r.object_id=? ";

    my \$sth = \$dbh->prepare(\$query);
    print STDERR \$query;

    \$sth->execute(\$feature_id);
    my \@rows = \@{ \$sth->fetchall_arrayref() };

    my \%hash = ();
    for ( my \$i = 0 ; \$i < scalar \@rows ; \$i++ ) {

        my \$response = \$rows[\$i][0];
        my \@values = ();
        if (\$response =~ /\\|/g) {
            if (\$response =~ /CDD/g) {
                \$response =~ /\\|\\w+\\|(\\d*)([\\w\\ ;.,]*)/g;
                while (\$response =~ /\\|\\w+\\|(\\d*)([\\w\\ ;.,]*)/g) {
                    push \@values, \$1;
                    push \@values, \$2;
                }
            }  else {
                while (\$response =~ /(?:\\w+)\\|(\\w+\\.*\\w*)\\|([\\w\\ \\:\\[\\]\\<\\>\\.\\-\\+\\*\\(\\)\\&\\\\\%\\\$\\#\\\@\\!\\/]*)\$/g) {
                    push \@values, \$1;
                    push \@values, \$2;
                }
            } 
        } else {
            if(\$response =~ /CDD:(\\w+)+\\s*\\w*[\\s,]*([\\w]+)+,/gmi) {
                \@values = (\$1, \$2);
            } else {
                while (\$response =~ /(\\w+)([\\w\\s]*)/g) {
                    push \@values, \$1;
                    push \@values, \$2;
                }
            }
        }
        \$hash{identifier} = \$values[0];
        \$hash{description} = \$values[1];

    }
    return \\\%hash;
}

=head2

Method used to get feature ID by uniquename

=cut

sub get_feature_id {
    my ( \$self, \$uniquename ) = \@_;
    my \$dbh = \$self->dbh;

    my \$query = "SELECT feature_id FROM feature WHERE uniquename = ? LIMIT 1";

    my \$sth = \$dbh->prepare(\$query);
    print STDERR \$query;
    \$sth->execute(\$uniquename);
    my \@rows = \@{ \$sth->fetchall_arrayref() };

    return \$rows[0][0];
}

=head2

Method used to get target class

=cut

sub get_target_class {
    my ( \$self, \$pipeline_id ) = \@_;
    my \$dbh  = \$self->dbh;
    my \@args = ();
    my \$query =
    "select DISTINCT ppc.value as value 
    from feature_relationship r 
    join featureloc l on (r.subject_id = l.feature_id) 
    join featureprop p on (p.feature_id = l.srcfeature_id) 
    join cvterm cp on (p.type_id = cp.cvterm_id) 
    join featureprop ppc on (ppc.feature_id = r.subject_id) 
    join cvterm cppc on (ppc.type_id = cppc.cvterm_id) 
    WHERE cppc.name= 'target_class' and cp.name='pipeline_id' and p.value=?";
    push \@args, \$pipeline_id;
    my \$sth = \$dbh->prepare(\$query);
    print STDERR \$query;
    \$sth->execute(\@args);
    my \@rows = \@{ \$sth->fetchall_arrayref() };

    my \@list = ();

    for ( my \$i = 0 ; \$i < scalar \@rows ; \$i++ ) {
        push \@list, \$rows[\$i][0];
    }

    return \\\@list;
}

=head2

Method used to get GO results from feature ID

=cut

sub getGOResultsByFeatureID {
    my (\$self, \$pipeline_id, \$feature_id) = \@_;
    my \$dbh  = \$self->dbh;
    my \$query = "SELECT DISTINCT pd.value 
            FROM feature_relationship r 
            JOIN featureloc l ON (r.object_id = l.feature_id) 
            JOIN featureprop p ON (p.feature_id = l.srcfeature_id) 
            JOIN cvterm c ON (p.type_id = c.cvterm_id) 
            JOIN feature_relationship pr ON (r.subject_id = pr.object_id) 
            JOIN featureprop pd ON (pr.subject_id = pd.feature_id) 
            JOIN cvterm cpd ON (pd.type_id = cpd.cvterm_id) 
            WHERE c.name ='pipeline_id' AND p.value = ? AND cpd.name LIKE 'evidence_\%' AND r.object_id = ? ";
    my \@args = ();
    push \@args, \$pipeline_id;
    push \@args, \$feature_id;
    my \$sth = \$dbh->prepare(\$query);
    print STDERR \$query;
    \$sth->execute(\@args);
    my \@rows = \@{ \$sth->fetchall_arrayref() };
    my \@list = ();
    for ( my \$i = 0 ; \$i < scalar \@rows ; \$i++ ) {
        push \@list, \$rows[\$i];
    }

    return \\\@list;
}

=head1 NAME

  $packageDBI - DBI Model Class 

=head1 SYNOPSIS
  
  This repository execute queries in annotation database created by EGene2

=head1 DESCRIPTION

DBI Model Class.

=head1 AUTHOR - Wendel Hime Lino Castro

Wendel Hime Lino Castro wendelhime\@hotmail.com

=head1 LICENSE

This library is free software, you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

1;

DBI

writeFile( "$services_dir/lib/$libDirectoryServices/Model/SearchDatabaseRepository.pm",
    $DBI );

$packageDBI = $packageServices . "::Model::BlastRepository";
$DBI        = <<DBI;
package $packageDBI;
use strict;
use warnings;
use base 'Catalyst::Model::Adaptor';

__PACKAGE__->config(
    class		=> 'Report_HTML_DB::Repositories::BlastRepository',
    constructor	=> 'new',
);

1;

DBI

writeFile( "$services_dir/lib/$libDirectoryServices/Model/BlastRepository.pm",
    $DBI );

#####
#
#	Add controllers
#
#####

#create controllers project
print $LOG "\nCreating controllers...\n";

`$services_dir/script/"$lowCaseNameServices"_create.pl controller SearchDatabase`;

my $temporaryPackage = $packageWebsite . '::Controller::Site';
writeFile( "$html_dir/lib/$libDirectoryWebsite/Controller/Site.pm", <<CONTENTSite);
package $temporaryPackage;
use Moose;
use namespace::autoclean;

BEGIN { extends 'Catalyst::Controller'; }

=head1 NAME

TESTE2::Controller::Site - Catalyst Controller

=head1 DESCRIPTION

Catalyst Controller.

=head1 METHODS

=cut

use base 'Catalyst::Controller::REST';
BEGIN { extends 'Catalyst::Controller::REST'; }

=head2 getHTMLContent
Method used to get HTML content from file by filepath
=cut

sub getHTMLContent : Path("/GetHTMLContent") : CaptureArgs(1) :
ActionClass('REST') { }

sub getHTMLContent_GET {
    my ( \$self, \$c, \$filepath ) = \@_;
    if ( !\$filepath and defined \$c->request->param("filepath") ) {
        \$filepath = \$c->request->param("filepath");
    }
    if(\$filepath =~ m/\\.\\.\\//) {
        \$self->status_bad_request(\$c, message => "Invalid filepath");
    }
    my \$root = \$c->path_to('.');
    chomp(\$root);
    my \$directoryWebsite = "";
    \$directoryWebsite = \$_ foreach(\$root =~ /\\/([\\w.-]+)+\$/);
    \$directoryWebsite =~ s/-/_/;
    \$directoryWebsite = lc \$directoryWebsite;

    open( my \$FILEHANDLER,
        "<", \$c->path_to('root') . "/" .  \$directoryWebsite . "/" . \$filepath );

    my \$content = do { local \$/; <\$FILEHANDLER> };
    close(\$FILEHANDLER);
    standardStatusOk( \$self, \$c, \$content );
}

=head2

Method used to return components used

=cut

sub getComponents : Path("/Components") : Args(0) :
ActionClass('REST') { }

sub getComponents_GET {
    my ( \$self, \$c ) = \@_;

    my \$resultSet = \$c->model('Basic::Component')->search(
        {},
        {
            order_by => {
                -asc => [qw/ component /]
            },
        }
    );

    my \@list = ();
    while ( my \$result = \$resultSet->next ) {
        my \%hash = ();
        \$hash{id}        = \$result->id;
        \$hash{name}      = \$result->name;
        \$hash{component} = \$result->component;
        if ( \$result->filepath ne "" ) {
            \$hash{filepath} = \$c->path_to('root') . "/" .\$result->filepath;
        }
        push \@list, \\%hash;
    }

    standardStatusOk( \$self, \$c, \\\@list );
}


=head2

Method used to get file by component id

=cut
sub getFileByComponentID : Path("/FileByComponentID") : CaptureArgs(1) {
    my ( \$self, \$c, \$id ) = \@_;
    if ( !\$id and defined \$c->request->param("id") ) {
        \$id = \$c->request->param("id");
    }

    my \$resultSet = \$c->model('Basic::Component')->search(
        {
            'locus_tag' => \$id,
        },
        {
            order_by => {
                -asc => [qw/ component /]
            },
        }
    );
    my \%hash = ();
    while ( my \$result = \$resultSet->next ) {
        \$hash{id}        = \$result->id;
        \$hash{name}      = \$result->name;
        \$hash{component} = \$result->component;
        \$hash{locus_tag} = \$result->locus_tag;
        if ( \$result->filepath ne "" ) {
            \$hash{filepath} = \$c->path_to('root') . "/" .\$result->filepath;
        }
    }

    use File::Basename;
    use Digest::MD5 qw(md5 md5_hex md5_base64);
    use Archive::Zip qw( :ERROR_CODES :CONSTANTS );
    my \$randomString = md5_base64( rand(\$\$) );
        \$randomString =~ s/\\///;
        my \$zip = Archive::Zip->new();

        \$zip->addFile( \$c->path_to('root') . "/" . \$hash{filepath},
            getFilenameByFilepath(\$c->path_to('root') . "/" . \$hash{filepath} ) );
        if (   \$hash{name} =~ /annotation\\_blast/
            || \$hash{name} =~ /annotation\\_pathways/
            || \$hash{name} =~ /annotation\\_orthology/
            || \$hash{name} =~ /annotation\\_tcdb/ )
        {
            \$hash{filepath} =~ s/\\.html/\\.png/;
            \$zip->addFile( \$c->path_to('root') . "/" . \$hash{filepath},
                getFilenameByFilepath( \$c->path_to('root') . "/" .\$hash{filepath} ) );
        }
        elsif ( \$hash{name} =~ /annotation\\_interpro/ ) {
            \$hash{filepath} =~ s/\\/[\\w\\s\\-_]+\\.[\\w\\s\\-_ .]+//;
            \$zip->addDirectory(
                \$c->path_to('root') . "/"
                . \$hash{filepath}
                . "/resources",
                "resources"
            );
        }

        unless ( \$zip->writeToFileNamed("/tmp/\$randomString") == AZ_OK ) {
            die 'error';
        }

        open( my \$FILEHANDLER, "<", "/tmp/\$randomString" );
        binmode \$FILEHANDLER;
        my \$file;

        local \$/ = \\10240;
        while (<\$FILEHANDLER>) {
            \$file .= \$_;
        }

        \$c->response->headers->content_type('application/x-download');
        \$c->response->header( 'Content-Disposition' => 'attachment; filename='
            . \$randomString
            . '.zip' );
        \$c->response->body(\$file);
        close \$FILEHANDLER;
        unlink("/tmp/\$randomString");
    }

=head2

Method used to view result by component ID

=cut

sub getViewResultByComponentID : Path("/ViewResultByComponentID") : CaptureArgs(2) {
    my ( \$self, \$c, \$id, \$name ) = \@_;
    if ( !\$id and defined \$c->request->param("locus_tag") ) {
        \$id = \$c->request->param("locus_tag");
    }
    if ( !\$name and defined \$c->request->param("name") ) {
        \$name = \$c->request->param("name");
    }

    my \$resultSet = \$c->model('Basic::Component')->search(
        {
            -and => [
                'locus_tag' => \$id,
                'name'      => \$name
            ]
        },
        {
            order_by => {
                -asc => [qw/ component /]
            },
        }
    );
    my \%hash = ();
    while ( my \$result = \$resultSet->next ) {
        \$hash{id}        = \$result->id;
        \$hash{name}      = \$result->name;
        \$hash{component} = \$result->component;
        \$hash{locus_tag} = \$result->locus_tag;
        if ( \$result->filepath ne "" ) {
            \$hash{filepath} = \$c->path_to('root') . "/" . \$result->filepath;
        }
    }

    use File::Basename;
    open( my \$FILEHANDLER,
        "<", \$hash{filepath} );
    my \$content = do { local(\$/); <\$FILEHANDLER> };;
    close(\$FILEHANDLER);

    if (   \$hash{name} =~ /annotation\\_blast/
        || \$hash{name} =~ /annotation\\_pathways/
        || \$hash{name} =~ /annotation\\_orthology/
        || \$hash{name} =~ /annotation\\_tcdb/ )
    {
        my \$image = \$hash{filepath};
        \$image =~ s/\\.html/\\.png/g;
        open( \$FILEHANDLER,
            "<", \$image );
        my \$contentImage = do { local(\$/); <\$FILEHANDLER> };
        close(\$FILEHANDLER);
        use MIME::Base64;
        \$contentImage = MIME::Base64::encode_base64(\$contentImage);
        \$content =~ s/\$_/<img src="data:image\\/png;base64,\$contentImage/ foreach (\$content =~ /(<img src="[\\.\\w\\s\\-]*)"/img);
    }
    elsif ( \$hash{name} =~ /annotation\\_interpro/ ) {
        my \$directory = \$hash{filepath};
        \$directory =~ s/\\/([\\w\\s\\-_\\.]+)\\.html//g;
        foreach (\$content =~ /<img src="([\\.\\w\\s\\-\\/]*)"/img) {
    open( \$FILEHANDLER,
    "<", \$directory . "/" . \$_ );
    my \$contentFile = do { local(\$/); <\$FILEHANDLER> };
    close(\$FILEHANDLER);
    use MIME::Base64;
    \$contentFile = MIME::Base64::encode_base64(\$contentFile);
    \$content =~ s/<img src="\$_/<img src="data:image\\/png;base64,\$contentFile/;
    }
    while (\$content =~ /<link([\\w\\s="]*)href="([\\.\\w\\s\\-\\/]*)"/img) {
            open( \$FILEHANDLER,
                "<", \$directory . "/" . \$2 );
            my \$contentFile = do { local(\$/); <\$FILEHANDLER> };
            close(\$FILEHANDLER);
            use MIME::Base64;
            \$contentFile = MIME::Base64::encode_base64(\$contentFile);
            if (\$1) {
                \$content =~ s/<link\$1href="\$2/<link \$1 href="data:text\\/css;base64,\$contentFile/;
            } else {
                \$content =~ s/<link href="\$2/<link href="data:text\\/css;base64,\$contentFile/;
            }
        }
        foreach (\$content =~ /<script src="([\\.\\w\\s\\-\\/]*)"/img) {
    open( \$FILEHANDLER,
    "<", \$directory . "/" . \$_ );
    my \$contentFile = do { local(\$/); <\$FILEHANDLER> };
    close(\$FILEHANDLER);
    use MIME::Base64;
    \$contentFile = MIME::Base64::encode_base64(\$contentFile);
    \$content =~ s/<script src="\$_/<script src="data:text\\/javascript;base64,\$contentFile/;
    }
    }

    \$c->response->body(\$content);

    }

    sub viewFileByContigAndType : Path("/ViewFileByContigAndType") : CaptureArgs(2) {
    my (\$self, \$c, \$contig, \$type) = \@_;
    if ( !\$type and defined \$c->request->param("type") ) {
    \$type = \$c->request->param("type");
    }
    if ( !\$contig and defined \$c->request->param("contig") ) {
    \$contig = \$c->request->param("contig");
    }
    my \$name = "";
    if(\$type eq "rna") {
    \$name = "infernal";
    } elsif(\$type eq "rrna_prediction") {
    \$name = "rnammer";
    } elsif(\$type =~ "trna") {
    \$name = "trna";
    } else {
    \$name = \$type;
    }

    my \$filepath = (
    \$c->model('Basic::Component')->search(
    {
    name 		=> {  "like", "%".\$name."%"},
    filepath 	=> { "like", "%".\$contig."%"}
    },
    {
    columns => qw/filepath/,
    rows    => 1
    }
    )->single->get_column(qw/filepath/)
    );
    open( my \$FILEHANDLER, "<", \$c->path_to('root') . "/" . \$filepath ); 
    my \$content = do { local(\$/); <\$FILEHANDLER> };;
    close(\$FILEHANDLER); 
    \$c->response->body(\$content); 
    \$c->response->headers->content_type('text/plain'); 
    } 

    sub downloadFileByContigAndType : Path("/DownloadFileByContigAndType") : CaptureArgs(2) {
    my (\$self, \$c, \$contig, \$type) = \@_;
    if ( !\$type and defined \$c->request->param("type") ) {
    \$type = \$c->request->param("type");
    }
    if ( !\$contig and defined \$c->request->param("contig") ) {
    \$contig = \$c->request->param("contig");
    }
    my \$name = "";
    if(\$type eq "rna") {
    \$name = "infernal";
    } elsif(\$type eq "rrna_prediction") {
    \$name = "rnammer";
    } elsif(\$type =~ "trna") {
    \$name = "trna";
    } else {
    \$name = \$type;
    }

    my \$filepath = (
    \$c->model('Basic::Component')->search(
    {
    name 		=> {  "like", "%".\$name."%"},
    filepath 	=> { "like", "%".\$contig."%"}
    },
    {
    columns => qw/filepath/,
    rows    => 1
    }
    )->single->get_column(qw/filepath/)
    );
    open( my \$FILEHANDLER, "<", \$c->path_to('root') . "/" . \$filepath );
    binmode \$FILEHANDLER;
    my \$file;

    local \$/ = \\10240;
    while (<\$FILEHANDLER>) {
    \$file .= \$_;
    }
    \$c->response->headers->content_type('text/plain'); 
    \$c->response->body(\$file);
    close \$FILEHANDLER;
    }


=head2

Method used to get filename by filepath

=cut

sub getFilenameByFilepath {
    my (\$filepath) = \@_;
    my \$filename = "";
    if ( \$filepath =~ /\\/([\\w\\s\\-_]+\\.[\\w\\s\\-_.]+)/g ) {
                    \$filename = \$1;
                }
                return \$filename;
            }

=head2 searchContig

Method used to realize search by contigs, optional return a stretch or a reverse complement

=cut

sub searchContig : Path("/Contig") : CaptureArgs(4) :
ActionClass('REST') { }

sub searchContig_GET {
    my ( \$self, \$c, \$contig, \$start, \$end, \$reverseComplement ) = \@_;
    if ( !\$contig and defined \$c->request->param("contig") ) {
        \$contig = \$c->request->param("contig");
    }
    if ( !\$start and defined \$c->request->param("contigStart") ) {
        \$start = \$c->request->param("contigStart");
    }
    if ( !\$end and defined \$c->request->param("contigEnd") ) {
        \$end = \$c->request->param("contigEnd");
    }
    if ( !\$reverseComplement
            and defined \$c->request->param("revCompContig") )
    {
        \$reverseComplement = \$c->request->param("revCompContig");
    }

    my \@list = ();
    push \@list, sequenceContig(\$c, \$contig, \$start, \$end, \$reverseComplement);
    standardStatusOk( \$self, \$c, \@list );
}

sub sequenceContig {
    my ( \$c, \$contig, \$start, \$end, \$reverseComplement ) = \@_;
    use File::Basename;
    my \$data     = "";
    my \$sequence = \$c->model('Basic::Sequence')->find(\$contig);

    open( my \$FILEHANDLER,
        "<", \$c->path_to('root') . "/" . \$sequence->filepath );

    my \$content = do { local \$/; <\$FILEHANDLER> };

    my \@lines = \$content =~ /^(\\w+)\\n*\$/mg;
    \$data = join("", \@lines);

    close(\$FILEHANDLER);

    if ( \$start && \$end ) {
        \$start += -1;
        \$data = substr( \$data, \$start, ( \$end - \$start ) );
        \$c->stash->{start}     = \$start;
        \$c->stash->{end}       = \$end;
        \$c->stash->{hadLimits} = 1;
    }
    if ( \$reverseComplement ) {
        \$data = reverseComplement(\$data);
        \$c->stash->{hadReverseComplement} = 1;
    }
    \$data = formatSequence(\$data);
    my \$result = \$data;

    my \%hash = ();
    \$hash{'geneID'} = \$sequence->id;
    \$hash{'gene'}   = \$sequence->name;
    \$hash{'contig'} = \$result;
    \$hash{'reverseComplement'} = \$reverseComplement ? 1 : 0;
    return \\\%hash;
}

=head2 reverseComplement

Method used to return the reverse complement of a sequence

=cut

sub reverseComplement {
    my (\$sequence) = \@_;
    my \$reverseComplement = reverse(\$sequence);
    \$reverseComplement =~ tr/ACGTacgt/TGCAtgca/;
    return \$reverseComplement;
}

=head2 formatSequence

Method used to format sequence

=cut

sub formatSequence {
    my \$seq = shift;
    my \$block = shift || 80;
    \$seq =~ s/.{\$block}/\$&\\n/gs;
    chomp \$seq;
    return \$seq;
}

=head2
Standard return of status ok
=cut

sub standardStatusOk {
    my ( \$self, \$c, \$response, \$total, \$pageSize, \$offset ) = \@_;
    if (   ( defined \$total || \$total )
        && ( defined \$pageSize || \$pageSize )
        && ( defined \$offset   || \$offset ) )
    {
        my \$pagedResponse = \$c->model('PagedResponse')->new(
            status_code => 200,
            message     => "Ok",
            elapsed_ms  => \$c->stats->elapsed,
            response    => \$response,
            total       => \$total,
            pageSize    => \$pageSize,
            offset      => \$offset,
        );
        \$self->status_ok( \$c, entity => \$pagedResponse->pack(), );
    }
    else {
        my \$baseResponse = \$c->model('BaseResponse')->new(
            status_code => 200,
            message     => "Ok",
            elapsed_ms  => \$c->stats->elapsed,
            response    => \$response
        );
        \$self->status_ok( \$c, entity => \$baseResponse->pack(), );
    }
}

=encoding utf8

=head1 AUTHOR

Wendel Hime L. Castro,,,

=head1 LICENSE

This library is free software. You can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

__PACKAGE__->meta->make_immutable;

1;
CONTENTSite
$temporaryPackage = $packageServices . '::Controller::Blast';
writeFile( "$services_dir/lib/$libDirectoryServices/Controller/Blast.pm" , <<CONTENT
package $temporaryPackage;
use Moose;
use namespace::autoclean;

BEGIN { extends 'Catalyst::Controller'; }

=head1 NAME

services::Controller::Blast - Catalyst Controller

=head1 DESCRIPTION

Catalyst Controller.

=head1 METHODS

=cut

use base 'Catalyst::Controller::REST';
BEGIN { extends 'Catalyst::Controller::REST'; }

=head2

Method used to realize search blast

=cut

sub search : Path("/Blast/search") : CaptureArgs(18) : ActionClass('REST') { }

sub search_POST {
    my ( \$self, \$c ) = \@_;

    open( my \$FILEHANDLER, "<", \$c->req->body );
    my \$formData = do { local \$/; <\$FILEHANDLER> };
    close(\$FILEHANDLER);
    use JSON;
    my \%hash = \%{ decode_json(\$formData) };

    foreach my \$key ( keys \%hash ) {
        if (\$key) {
            \$hash{\$key} =~ s/['"&.|]//g;
            chomp( \$hash{\$key} ) if \$key ne "SEQUENCE";
        }
    }

    use File::Temp ();
    my \$fh    = File::Temp->new();
    my \$fname = \$fh->filename;
    open( \$FILEHANDLER, ">", \$fname );
    my \@fuckingSequence = split( /\\\\n/, \$hash{SEQUENCE} );
    \$hash{SEQUENCE} = join( "\\n", \@fuckingSequence );
    print \$FILEHANDLER \$hash{SEQUENCE};
    close(\$FILEHANDLER);

    \$hash{DATALIB} = \$c->path_to("root") . "/seq/Sequences"
    if ( \$hash{DATALIB} eq "PMN_genome_1" );
    \$hash{DATALIB} = \$c->path_to("root") . "/orfs_nt/Sequences_NT"
    if ( \$hash{DATALIB} eq "PMN_genes_1" );
    \$hash{DATALIB} = \$c->path_to("root") . "/orfs_aa/Sequences_AA"
    if ( \$hash{DATALIB} eq "PMN_prot_1" );
    my \$content = "";
    if ( exists \$hash{PROGRAM} ) {
        if (   \$hash{PROGRAM} eq "blastn"
            || \$hash{PROGRAM} eq "blastp"
            || \$hash{PROGRAM} eq "blastx"
            || \$hash{PROGRAM} eq "tblastn"
            || \$hash{PROGRAM} eq "tblastx" )
        {
            my \@response = \@{
            \$c->model('BlastRepository')->executeBlastSearch(
            \$hash{PROGRAM},            \$hash{DATALIB},
            \$fname,                    \$hash{QUERY_FROM},
            \$hash{QUERY_TO},           \$hash{FILTER},
            \$hash{EXPECT},             \$hash{MAT_PARAM},
            \$hash{UNGAPPED_ALIGNMENT}, \$hash{GENETIC_CODE},
            \$hash{DB_GENETIC_CODE},    
            \$hash{ALIGNMENT_VIEW},     \$hash{DESCRIPTIONS},
            \$hash{ALIGNMENTS},         \$hash{COST_OPEN_GAP},
            \$hash{COST_EXTEND_GAP},    \$hash{WORD_SIZE}
            )
            };
            \$content = join( "", \@response );
        }
        else {
            \$content = "PROGRAM NOT IN THE LIST";
        }
    }
    else {
        \$content = "NO PROGRAM DEFINED";
    }

    return standardStatusOk( \$self, \$c, \$content );
}

sub fancy : Path("/Blast/fancy") : CaptureArgs(3) : ActionClass('REST') { }

sub fancy_POST {
    my ( \$self, \$c ) = \@_;
    open( my \$FILEHANDLER, "<", \$c->req->body );
    my \$formData = do { local \$/; <\$FILEHANDLER> };
    close(\$FILEHANDLER);
    use JSON;
    my \%hash = \%{ decode_json(\$formData) };

    use File::Temp ();
    my \$fh    = File::Temp->new();
    my \$fname = \$fh->filename;
    open( \$FILEHANDLER, ">", \$fname );
    print \$FILEHANDLER \$hash{blast};
    close(\$FILEHANDLER);
    use File::Temp qw/ :mktemp  /;
    my \$tmpdir_name = mkdtemp("/tmp/XXXXXX");
    \%hash = ();
    if (\$c->model('BlastRepository')->fancyBlast(\$fname, \$tmpdir_name)) {
        my \@files = ();
        opendir(my \$DIR, \$tmpdir_name);
        \@files = grep(!/^\\./, readdir(\$DIR));
        closedir(\$DIR);
        use MIME::Base64;
        for(my \$i = 0; \$i < scalar \@files; \$i++) 
        {
            open(\$FILEHANDLER, "<", \$tmpdir_name . "/" . \$files[\$i]);
            my \$content = do { local \$/; <\$FILEHANDLER> };
            if(\$files[\$i] =~ /\\.html/g) {
                \$hash{html} = \$content;
            }
            elsif(\$files[\$i] =~ /\\.png/g) {
                \$hash{image} = MIME::Base64::encode_base64(\$content);
            }
            close(\$FILEHANDLER);
        }
    }
    use File::Path;
    rmtree(\$tmpdir_name);
    return standardStatusOk(\$self, \$c, \\\%hash);
}

=head2

Method used to make a default return of every ok request using BaseResponse model

=cut

sub standardStatusOk {
    my ( \$self, \$c, \$response, \$total, \$pageSize, \$offset ) = \@_;
    if (   ( defined \$total || \$total )
        && ( defined \$pageSize || \$pageSize )
        && ( defined \$offset   || \$offset ) )
    {
        my \$pagedResponse = \$c->model('PagedResponse')->new(
            status_code => 200,
            message     => "Ok",
            elapsed_ms  => \$c->stats->elapsed,
            response    => \$response,
            total       => \$total,
            pageSize    => \$pageSize,
            offset      => \$offset,
        );
        \$self->status_ok( \$c, entity => \$pagedResponse->pack(), );
    }
    else {
        my \$baseResponse = \$c->model('BaseResponse')->new(
            status_code => 200,
            message     => "Ok",
            elapsed_ms  => \$c->stats->elapsed,
            response    => \$response
        );
        \$self->status_ok( \$c, entity => \$baseResponse->pack(), );
    }
}

=encoding utf8

=head1 AUTHOR

Wendel Hime L. Castro,,,

=head1 LICENSE

This library is free software. You can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

__PACKAGE__->meta->make_immutable;

1;

CONTENT
);

$temporaryPackage = $packageServices . '::Controller::SearchDatabase';
writeFile( "$services_dir/lib/$libDirectoryServices/Controller/SearchDatabase.pm",
    <<CONTENT);
package $temporaryPackage;
use Moose;
use namespace::autoclean;

BEGIN { extends 'Catalyst::Controller'; }

=head1 NAME

services::Controller::SearchDatabase - Catalyst Controller

=head1 DESCRIPTION

Catalyst Controller.

=head1 METHODS

=cut

use base 'Catalyst::Controller::REST';
BEGIN { extends 'Catalyst::Controller::REST'; }

=head2 getFeatureID

Method used to get feature id

=cut

sub getFeatureID : Path("/SearchDatabase/GetFeatureID") : CaptureArgs(1) :
ActionClass('REST') { }

sub getFeatureID_GET {
    my (\$self, \$c, \$uniquename) = \@_;
    if ( !\$uniquename and defined \$c->request->param("uniquename") ) {
        \$uniquename = \$c->request->param("uniquename");
    }
    return standardStatusOk( \$self, \$c,
        \$c->model('SearchDatabaseRepository')->get_feature_id(\$uniquename));
}

sub getPipeline : Path("/SearchDatabase/GetPipeline") : CaptureArgs(0) : ActionClass('REST') { }

sub getPipeline_GET {
    my ( \$self, \$c ) = \@_;
    return standardStatusOk( \$self, \$c, \$c->model('SearchDatabaseRepository')->getPipeline() );
}

sub getRibosomalRNAs : Path("/SearchDatabase/GetRibosomalRNAs") : CaptureArgs(1) : ActionClass('REST') { }

sub getRibosomalRNAs_GET {
    my (\$self, \$c, \$pipeline) = \@_;

    if ( !\$pipeline and defined \$c->request->param("pipeline") ) {
        \$pipeline = \$c->request->param("pipeline");
    }

    my \%hash = ();
    \$hash{pipeline}        = \$pipeline;

    standardStatusOk( \$self, \$c, \$c->model('SearchDatabaseRepository')->getRibosomalRNAs( \\\%hash ) );
}

=head2

Method used to realize search of rRNA

=cut

sub rRNA_search : Path("/SearchDatabase/rRNA_search") : CaptureArgs(5) : ActionClass('REST') { }

sub rRNA_search_GET {
    my (\$self, \$c, \$contig, \$type, \$pageSize, \$offset, \$pipeline) = \@_;

    if ( !\$pipeline and defined \$c->request->param("pipeline") ) {
        \$pipeline = \$c->request->param("pipeline");
    }
    if ( !\$contig and defined \$c->request->param("contig") ) {
        \$contig = \$c->request->param("contig");
    }
    if ( !\$type and defined \$c->request->param("type") ) {
        \$type = \$c->request->param("type");
    }
    if ( !\$pageSize and defined \$c->request->param("pageSize") ) {
        \$pageSize = \$c->request->param("pageSize");
    }
    if ( !\$offset and defined \$c->request->param("offset") ) {
        \$offset = \$c->request->param("offset");
    }

    my \%hash = ();

    \$hash{pipeline} = \$pipeline;
    \$hash{contig} = \$contig;
    \$hash{type} = \$type;
    \$hash{pageSize} = \$pageSize;
    \$hash{offset} = \$offset;

    my \$result = \$c->model('SearchDatabaseRepository')->rRNA_search( \\\%hash );

    my \@resultList = \@{ \$result->{list} };

    standardStatusOk( \$self, \$c, \\\@resultList, \$result->{total}, \$pageSize, \$offset );
}

=head2 searchGene

Method used to search on database genes

=cut

sub searchGene : Path("/SearchDatabase/Gene") : CaptureArgs(6) :
ActionClass('REST') { }

sub searchGene_GET {
    my ( \$self, 	\$c, 	\$pipeline, 	\$geneID, 
        \$geneDescription, 	\$noDescription, \$individually,	\$featureId,
        \$pageSize,        \$offset, \$contig )
    = \@_;

    if ( !\$pipeline and defined \$c->request->param("pipeline") ) {
        \$pipeline = \$c->request->param("pipeline");
    }
    if ( !\$geneID and defined \$c->request->param("geneID") ) {
        \$geneID = \$c->request->param("geneID");
    }
    if ( !\$geneDescription and defined \$c->request->param("geneDesc") ) {
        \$geneDescription = \$c->request->param("geneDesc");
    }
    if ( !\$noDescription and defined \$c->request->param("noDesc") ) {
        \$noDescription = \$c->request->param("noDesc");
    }
    if ( !\$individually and defined \$c->request->param("individually") ) {
        \$individually = \$c->request->param("individually");
    }
    if ( !\$featureId and defined \$c->request->param("featureId") ) {
        \$featureId = \$c->request->param("featureId");
    }
    if ( !\$pageSize and defined \$c->request->param("pageSize") ) {
        \$pageSize = \$c->request->param("pageSize");
    }
    if ( !\$offset and defined \$c->request->param("offset") ) {
        \$offset = \$c->request->param("offset");
    }
    if ( !\$contig and defined \$c->request->param("contig") ) {
        \$contig = \$c->request->param("contig");
    }

    my \@list = ();
    my \%hash = ();
    \$hash{pipeline}        = \$pipeline;
    \$hash{featureId}       = \$featureId;
    \$hash{geneID}          = \$geneID;
    \$hash{geneDescription} = \$geneDescription;
    \$hash{noDescription}   = \$noDescription;
    \$hash{individually}    = \$individually;
    \$hash{pageSize}        = \$pageSize;
    \$hash{offset}          = \$offset;
    \$hash{contig}		    = \$contig if \$contig;

    my \$result     = \$c->model('SearchDatabaseRepository')->searchGene( \\\%hash );
    my \@resultList = \@{ \$result->{list} };

    for ( my \$i = 0 ; \$i < scalar \@resultList ; \$i++ ) {
        push \@list, \$resultList[\$i]->pack();
    }

    standardStatusOk( \$self, \$c, \\\@list, \$result->{total}, \$pageSize, \$offset );
}

=head2 encodingCorrection

Method used to correct encoding strings come from SQLite

=cut

sub encodingCorrection {
    my (\@texts) = \@_;

    use utf8;
    use Encode qw( decode encode );
    foreach my \$text (\@texts) {
        foreach my \$key ( keys \%\$text ) {
            if ( \$text->{\$key} != 1 ) {
                my \$string = decode( 'utf-8', \$text->{\$key}{value} );
                \$string = encode( 'iso-8859-1', \$string );
                \$text->{\$key}{value} = \$string;
            }
        }
    }
    return \@texts;
}

=head2 getGeneBasics
Method used to return basic data of genes from database: the beginning position from sequence, final position from the sequence, type, name
return a list of hash containing the basic data

=cut

sub getGeneBasics : Path("/SearchDatabase/GetGeneBasics") : CaptureArgs(2) :
ActionClass('REST') { }

sub getGeneBasics_GET {
    my ( \$self, \$c, \$id, \$pipeline ) = \@_;

    #verify if the id exist and set
    if ( !\$id and defined \$c->request->param("id") ) {
        \$id = \$c->request->param("id");
    }
    if ( !\$pipeline and defined \$c->request->param("pipeline") ) {
        \$pipeline = \$c->request->param("pipeline");
    }

    my \%hash = ();
    \$hash{pipeline}   = \$pipeline;
    \$hash{feature_id} = \$id;

    my \@resultList = \@{ \$c->model('SearchDatabaseRepository')->geneBasics( \\\%hash ) };
    my \@list       = ();
    for ( my \$i = 0 ; \$i < scalar \@resultList ; \$i++ ) {
        push \@list, \$resultList[\$i]->pack();
    }

    standardStatusOk( \$self, \$c, \\\@list );
}

=head2 getSubsequence

Method used to get subsequence stretch of gene, returning the sequence, had to return in a json!

=cut

sub getSubsequence : Path("/SearchDatabase/GetSubsequence") : CaptureArgs(6) :
ActionClass('REST') { }

sub getSubsequence_GET {
    my ( \$self, \$c, \$type, \$contig, \$sequenceName, \$start, \$end, \$pipeline ) = \@_;
    if ( !\$contig and defined \$c->request->param("contig") ) {
        \$contig = \$c->request->param("contig");
    }
    if ( !\$type and defined \$c->request->param("type") ) {
        \$type = \$c->request->param("type");
    }
    if ( !\$pipeline and defined \$c->request->param("pipeline") ) {
        \$pipeline = \$c->request->param("pipeline");
    }
    if ( !\$sequenceName and defined \$c->request->param("sequenceName") ) {
        \$sequenceName = \$c->request->param("sequenceName");
    }
    if ( !\$start and defined \$c->request->param("start") ) {
        \$start = \$c->request->param("start");
    }
    if ( !\$end and defined \$c->request->param("end") ) {
        \$end = \$c->request->param("end");
    }

    my \$content = "";
    use File::Basename;

    if ( \$type ne "CDS" ) {
        open(
            my \$FILEHANDLER,
            "<",
            \$c->path_to('root') 
            ."/seq/"
            . \$sequenceName
            . ".fasta"
        );

        for my \$line (<\$FILEHANDLER>) {
            if ( \$line !~ /^>[\\w.-_]+\$/g )  {
                \$content .= \$line;
            }
        }

        close(\$FILEHANDLER);

        \$content =~ s/\\n//g;

        if ( \$start && \$end ) {
            \$content = substr( \$content, \$start, ( \$end - ( \$start + 1 ) ) );
        }
        my \$result = "";
        for ( my \$i = 0 ; \$i < length(\$content) ; \$i += 60 ) {
            my \$line = substr( \$content, \$i, 60 );
            \$result .= "\$line<br />";
        }
        \$content = \$result;
    }
    else {
        open(
            my \$FILEHANDLER,
            "<",
            \$c->path_to('root') . "/orfs_aa/" . \$contig . ".fasta"
        );

        for my \$line (<\$FILEHANDLER>) {
            if ( !( \$line =~ /^>\\w+\\n\$/g ) ) {
                \$content .= \$line;
            }
        }
        close(\$FILEHANDLER);
        \$content =~ s/\\n/<br \\/>/g;
    }
    standardStatusOk( \$self, \$c, { "sequence" => \$content } );
}

=head2

Method used to return subevidences based on feature id

=cut

sub subEvidences : Path("/SearchDatabase/subEvidences") : CaptureArgs(2) :
ActionClass('REST') { }

sub subEvidences_GET {
    my ( \$self, \$c, \$feature, \$pipeline ) = \@_;
    if ( !\$feature and defined \$c->request->param("feature") ) {
        \$feature = \$c->request->param("feature");
    }
    if ( !\$pipeline and defined \$c->request->param("pipeline") ) {
        \$pipeline = \$c->request->param("pipeline");
    }
    my \@list       = ();
    my \@resultList = \@{ \$c->model('SearchDatabaseRepository')->subevidences(\$feature) };
    for ( my \$i = 0 ; \$i < scalar \@resultList ; \$i++ ) {
        push \@list, \$resultList[\$i]->pack();
    }
    standardStatusOk( \$self, \$c, \\\@list );
}

=head2

Method used to return properties of evidences that the type is interval and basic data of everything isn't CDS

=cut

sub getIntervalEvidenceProperties :
Path("/SearchDatabase/getIntervalEvidenceProperties") : CaptureArgs(3) :
ActionClass('REST') { }

sub getIntervalEvidenceProperties_GET {
    my ( \$self, \$c, \$feature, \$typeFeature, \$pipeline ) = \@_;
    if ( !\$feature and defined \$c->request->param("feature") ) {
        \$feature = \$c->request->param("feature");
    }
    if ( !\$typeFeature and defined \$c->request->param("typeFeature") ) {
        \$typeFeature = \$c->request->param("typeFeature");
    }
    if ( !\$pipeline and defined \$c->request->param("pipeline") ) {
        \$pipeline = \$c->request->param("pipeline");
    }

    my \%hash = ();
    \$hash{properties} = \$c->model('SearchDatabaseRepository')->intervalEvidenceProperties(\$feature);
    if ( exists \$hash{intron} ) {
        if ( \$hash{intron} eq 'yes' ) {
            \$hash{coordinatesGene} = \$hash{intron_start} - \$hash{intron_end};
            \$hash{coordinatesGenome} =
            \$hash{intron_start_seq} - \$hash{intron_end_seq};
        }
    }
    if ( \$typeFeature eq 'annotation_pathways' ) {
        my \@pathways        = ();
        my \@ids             = ();
        my \@descriptions    = ();
        my \@classifications = ();
        for ( my \$i = 0 ; \$i < scalar \@{ \$hash{properties} } ; \$i++ ) {
            while ( \$hash{properties}[\$i]->{metabolic_pathway_classification} =~
                /([\\w\\s]+)/g )
            {
                push \@classifications, \$1;
            }
            while ( \$hash{properties}[\$i]->{metabolic_pathway_description} =~
                /([\\w\\s]+)/g )
            {
                push \@descriptions, \$1;
            }
            while (
                \$hash{properties}[\$i]->{metabolic_pathway_id} =~ /([\\w\\s]+)/g )
            {
                push \@ids, \$1;
            }
            for ( my \$j = 0 ; \$j < scalar \@ids ; \$j++ ) {
                my \%pathway = ();
                \$pathway{id}            = \$ids[\$j];
                \$pathway{description}   = \$descriptions[\$j];
                \$pathway{classfication} = \$classifications[\$j];
                push \@pathways, \\\%pathway;
            }
        }

        \$hash{pathways} = \\\@pathways;
        \$hash{id}       = \$feature;
    }
    elsif ( \$typeFeature eq 'annotation_orthology' ) {
        my \@orthologous_groups = ();
        my \@groups             = ();
        my \@descriptions       = ();
        my \@classifications    = ();
        for ( my \$i = 0 ; \$i < scalar \@{ \$hash{properties} } ; \$i++ ) {
            while ( \$hash{properties}[\$i]->{orthologous_group} =~
                /([\\w\\s.\\-(),]+)/g )
            {
                push \@groups, \$1;
            }
            while ( \$hash{properties}[\$i]->{orthologous_group_description} =~
                /([\\w\\s.\\-(),]+)/g )
            {
                push \@descriptions, \$1;
            }
            while ( \$hash{properties}[\$i]->{orthologous_group_classification} =~
                /([\\w\\s.\\-(),]+)/g )
            {
                push \@classifications, \$1;
            }
            for ( my \$j = 0 ; \$j < scalar \@groups ; \$j++ ) {
                my \%group = ();
                \$group{group}          = \$groups[\$j];
                \$group{description}    = \$descriptions[\$j];
                \$group{classification} = \$classifications[\$j];
                push \@orthologous_groups, \\\%group;
            }
        }
        \$hash{orthologous_groups} = \\\@orthologous_groups;
        \$hash{id}                 = \$feature;
    }
    if ( !( exists \$hash{id} ) ) {
        \$hash{id} = \$feature;
    }

    standardStatusOk( \$self, \$c, \\\%hash );
}

=head2

Method used to return properties of evidence typed like similarity

=cut

sub getSimilarityEvidenceProperties :
Path("/SearchDatabase/getSimilarityEvidenceProperties") : CaptureArgs(1) :
ActionClass('REST') { }

sub getSimilarityEvidenceProperties_GET {
    my ( \$self, \$c, \$feature ) = \@_;
    if ( !\$feature and defined \$c->request->param("feature") ) {
        \$feature = \$c->request->param("feature");
    }

    standardStatusOk( \$self, \$c,
        \$c->model('SearchDatabaseRepository')->similarityEvidenceProperties(\$feature) );
}

sub getIdentifierAndDescriptionSimilarity :
Path("/SearchDatabase/getIdentifierAndDescriptionSimilarity") : CaptureArgs(1) :
ActionClass('REST') { }

sub getIdentifierAndDescriptionSimilarity_GET {
    my ( \$self, \$c, \$feature_id ) = \@_;
    if ( !\$feature_id and defined \$c->request->param("feature_id") ) {
        \$feature_id = \$c->request->param("feature_id");
    }
    standardStatusOk( \$self, \$c,
        \$c->model('SearchDatabaseRepository')->getIdentifierAndDescriptionSimilarity(\$feature_id) );
}  

=head2 reverseComplement

Method used to return the reverse complement of a sequence

=cut

sub reverseComplement {
    my (\$sequence) = \@_;
    my \$reverseComplement = reverse(\$sequence);
    \$reverseComplement =~ tr/ACGTacgt/TGCAtgca/;
    return \$reverseComplement;
}

=head2 formatSequence

Method used to format sequence

=cut

sub formatSequence {
    my \$seq = shift;
    my \$block = shift || 80;
    \$seq =~ s/.{\$block}/\$&\\n/gs;
    chomp \$seq;
    return \$seq;
}

=head2 analysesCDS

Method used to make search of analyses of protein-coding genes

=cut

sub analysesCDS : Path("/SearchDatabase/analysesCDS") : CaptureArgs(32) :
ActionClass('REST') { }

sub analysesCDS_GET {
    my ( \$self, \$c ) = \@_;

    my \%hash = ();
    my \@list = ();

    foreach my \$key ( keys \%{ \$c->request->params } ) {
        if ( \$key && \$key ne "0" ) {
            \$hash{\$key} = \$c->request->params->{\$key};
        }
    }
    my \$result = \$c->model('SearchDatabaseRepository')->analyses_CDS( \\\%hash );
    foreach my \$value ( \@{ \$result->{list} } ) {
        push \@list, \$value;
    }
    standardStatusOk( \$self, \$c, \\\@list, \$result->{total}, \$hash{pageSize},
        \$hash{offset} );
}

=head2

Method used to realize search of tRNA

=cut

sub trnaSearch : Path("/SearchDatabase/trnaSearch") : CaptureArgs(5) :
ActionClass('REST') { }

sub trnaSearch_GET {
    my ( \$self, \$c ) = \@_;

    my \%hash = ();
    foreach my \$key ( keys \%{ \$c->request->params } ) {
        if ( \$key && \$key ne "0" ) {
            \$hash{\$key} = \$c->request->params->{\$key};
        }
    }
    my \@list       = ();
    my \$result     = \$c->model('SearchDatabaseRepository')->tRNA_search( \\\%hash );
    my \@resultList = \@{ \$result->{list} };

    for ( my \$i = 0 ; \$i < scalar \@resultList ; \$i++ ) {
        push \@list, \$resultList[\$i]->pack();
    }

    standardStatusOk( \$self, \$c, \\\@list, \$result->{total}, \$hash{pageSize},
        \$hash{offset} );
}

=head2

Method used to get data of tandem repeats

=cut

sub tandemRepeatsSearch : Path("/SearchDatabase/tandemRepeatsSearch") :
CaptureArgs(6) : ActionClass('REST') { }

sub tandemRepeatsSearch_GET {
    my ( \$self, \$c ) = \@_;

    my \%hash = ();
    my \@list = ();

    foreach my \$key ( keys \%{ \$c->request->params } ) {
        if ( \$key && \$key ne "0" ) {
            \$hash{\$key} = \$c->request->params->{\$key};
        }
    }
    my \$result = \$c->model('SearchDatabaseRepository')->trf_search( \\\%hash );
    my \@resultList = \@{ \$result->{list} };
    for ( my \$i = 0 ; \$i < scalar \@resultList ; \$i++ ) {
        push \@list, \$resultList[\$i]->pack();
    }

    standardStatusOk( \$self, \$c, \\\@list, \$result->{total}, \$hash{pageSize}, 
        \$hash{offset} );
}

=head2

Method used to get data of non coding RNAs

=cut

sub ncRNASearch : Path("/SearchDatabase/ncRNASearch") : CaptureArgs(8) :
ActionClass('REST') { }

sub ncRNASearch_GET {
    my ( \$self, \$c ) = \@_;

    my \%hash = ();
    my \@list = ();

    foreach my \$key ( keys \%{ \$c->request->params } ) {
        if ( \$key && \$key ne "0" ) {
            \$hash{\$key} = \$c->request->params->{\$key};
        }
    }

    my \$result = \$c->model('SearchDatabaseRepository')->ncRNA_search( \\\%hash );
    my \@resultList = \@{ \$result->{list} };

    for ( my \$i = 0 ; \$i < scalar \@resultList ; \$i++ ) {
        push \@list, \$resultList[\$i]->pack();
    }

    standardStatusOk( \$self, \$c, \\\@list, \$result->{total}, \$hash{pageSize}, 
        \$hash{offset} );
}

=head2

Method used to get data of transcriptional terminators

=cut

sub transcriptionalTerminatorSearch :
Path("/SearchDatabase/transcriptionalTerminatorSearch") : CaptureArgs(7) :
ActionClass('REST') { }

sub transcriptionalTerminatorSearch_GET {
    my ( \$self, \$c ) = \@_;

    my \%hash = ();
    my \@list = ();

    foreach my \$key ( keys \%{ \$c->request->params } ) {
        if ( \$key && \$key ne "0" ) {
            \$hash{\$key} = \$c->request->params->{\$key};
        }
    }

    my \$result = \$c->model('SearchDatabaseRepository')->transcriptional_terminator_search( \\\%hash );
    my \@resultList =
    \@{ \$result->{list} };

    for ( my \$i = 0 ; \$i < scalar \@resultList ; \$i++ ) {
        push \@list, \$resultList[\$i]->pack();
    }

    standardStatusOk( \$self, \$c, \\\@list, \$result->{total},  \$hash{pageSize}, 
        \$hash{offset} );
}

=head2

Method used to get data of ribosomal binding sites

=cut

sub rbsSearch : Path("/SearchDatabase/rbsSearch") : CaptureArgs(5) :
ActionClass('REST') {
}

sub rbsSearch_GET {
    my ( \$self, \$c ) = \@_;

    my \%hash = ();
    my \@list = ();

    foreach my \$key ( keys \%{ \$c->request->params } ) {
        if ( \$key && \$key ne "0" ) {
            \$hash{\$key} = \$c->request->params->{\$key};
        }
    }

    my \$result = \$c->model('SearchDatabaseRepository')->rbs_search( \\\%hash );
    my \@resultList = \@{ \$result->{list} };

    for ( my \$i = 0 ; \$i < scalar \@resultList ; \$i++ ) {
        push \@list, \$resultList[\$i]->pack();
    }

    standardStatusOk( \$self, \$c, \\\@list, \$result->{total}, \$hash{pageSize}, \$hash{offset} );
}

=head2

Method used to get data of horizontal gene transfers

=cut

sub alienhunterSearch : Path("/SearchDatabase/alienhunterSearch") :
CaptureArgs(7) : ActionClass('REST') { }

sub alienhunterSearch_GET {
    my ( \$self, \$c ) = \@_;

    my \%hash = ();
    my \@list = ();

    foreach my \$key ( keys \%{ \$c->request->params } ) {
        if ( \$key && \$key ne "0" ) {
            \$hash{\$key} = \$c->request->params->{\$key};
        }
    }

    my \$result = \$c->model('SearchDatabaseRepository')->alienhunter_search( \\\%hash );
    my \@resultList = \@{ \$result->{list} };

    for ( my \$i = 0 ; \$i < scalar \@resultList ; \$i++ ) {
        my \%object = (
            id     => \$resultList[\$i]->getID,
            contig => \$resultList[\$i]->getContig,
            start  => \$resultList[\$i]->getStart,
            end    => \$resultList[\$i]->getEnd,
        );

        \$object{length} = \$resultList[\$i]->getLength
        if \$resultList[\$i]->getLength;
        \$object{score} = \$resultList[\$i]->getScore
        if \$resultList[\$i]->getScore;
        \$object{threshold} = \$resultList[\$i]->getThreshold
        if \$resultList[\$i]->getThreshold;

        push \@list, \\\%object;
    }

    standardStatusOk( \$self, \$c, \\\@list, \$result->{total}, \$hash{pageSize}, \$hash{offset} );
}

=head2

Method used to get feature by position

=cut

sub geneByPosition : Path("/SearchDatabase/geneByPosition") :
CaptureArgs(6) : ActionClass('REST') { }

sub geneByPosition_GET {
    my ( \$self, \$c, \$start, \$end, \$contig, \$pipeline_id, \$pageSize, \$offset ) = \@_;
    if ( !\$start and defined \$c->request->param("start") ) {
        \$start = \$c->request->param("start");
    }
    if ( !\$end and defined \$c->request->param("end") ) {
        \$end = \$c->request->param("end");
    }
    if ( !\$pipeline_id and defined \$c->request->param("pipeline_id") ) {
        \$pipeline_id = \$c->request->param("pipeline_id");
    }
    if ( !\$pageSize and defined \$c->request->param("pageSize") ) {
        \$pageSize = \$c->request->param("pageSize");
    }
    if ( !\$offset and defined \$c->request->param("offset") ) {
        \$offset = \$c->request->param("offset");
    }
    if ( !\$contig and defined \$c->request->param("contig") ) {
        \$contig = \$c->request->param("contig");   
    }
    my \@list = ();

    my \%hash = ();
    \$hash{pipeline} = \$pipeline_id;
    \$hash{start}    = \$start;
    \$hash{end}      = \$end;
    \$hash{pageSize} = \$pageSize;
    \$hash{offset}	= \$offset;
    \$hash{contig}	= \$contig;
    my \$result = \$c->model('SearchDatabaseRepository')->geneByPosition( \\\%hash );
    my \$total = \$result->{total};
    my \@ids = \@{ \$result->{list} };
    my \$featureId = join( " ", \@ids );
    \%hash            = ();
    \$hash{pipeline}  = \$pipeline_id;
    \$hash{featureId} = \$featureId;

    my \$result = \$c->model('SearchDatabaseRepository')->searchGene( \\\%hash );
    my \@resultList = \@{ \$result->{list} };
    for ( my \$i = 0 ; \$i < scalar \@resultList ; \$i++ ) {
        push \@list, \$resultList[\$i]->pack();
    }

    standardStatusOk( \$self, \$c, \\\@list, \$total, \$pageSize, \$offset );
}

sub targetClass : Path("/SearchDatabase/targetClass") : CaptureArgs(1) : ActionClass('REST') { }

sub targetClass_GET {
    my(\$self, \$c, \$pipeline_id) = \@_;
    if ( !\$pipeline_id and defined \$c->request->param("pipeline_id") ) {
        \$pipeline_id = \$c->request->param("pipeline_id");
    }
    standardStatusOk(\$self, \$c, \$c->model('SearchDatabaseRepository')->get_target_class(\$pipeline_id));
}

sub getGOResultsByFeatureID : Path("/SearchDatabase/getGOResultsByFeatureID") : CaptureArgs(2) : ActionClass('REST') { }

sub getGOResultsByFeatureID_GET {
    my (\$self, \$c, \$feature_id, \$pipeline_id) = \@_;
    if ( !\$pipeline_id and defined \$c->request->param("pipeline_id") ) {
        \$pipeline_id = \$c->request->param("pipeline_id");
    }
    if ( !\$feature_id and defined \$c->request->param("feature_id") ) {
        \$feature_id = \$c->request->param("feature_id");
    }
    standardStatusOk(\$self, \$c, \$c->model('SearchDatabaseRepository')->getGOResultsByFeatureID(\$pipeline_id, \$feature_id));

}

=head2

Method used to make a default return of every ok request using BaseResponse model

=cut

sub standardStatusOk {
    my ( \$self, \$c, \$response, \$total, \$pageSize, \$offset ) = \@_;
    if (   ( defined \$total || \$total )
        && ( defined \$pageSize || \$pageSize )
        && ( defined \$offset   || \$offset ) )
    {
        my \$pagedResponse = \$c->model('PagedResponse')->new(
            status_code => 200,
            message     => "Ok",
            elapsed_ms  => \$c->stats->elapsed,
            response    => \$response,
            total       => \$total,
            pageSize    => \$pageSize,
            offset      => \$offset,
        );
        \$self->status_ok( \$c, entity => \$pagedResponse->pack(), );
    }
    else {
        my \$baseResponse = \$c->model('BaseResponse')->new(
            status_code => 200,
            message     => "Ok",
            elapsed_ms  => \$c->stats->elapsed,
            response    => \$response
        );
        \$self->status_ok( \$c, entity => \$baseResponse->pack(), );
    }
}

=encoding utf8

=head1 AUTHOR

Wendel Hime L. Castro,,,

=head1 LICENSE

This library is free software. You can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

__PACKAGE__->meta->make_immutable;

1;
CONTENT
$temporaryPackage = $packageWebsite . '::Controller::SearchDatabase';
my $searchDBContent = <<SEARCHDBCONTENT;
package $temporaryPackage;
use Moose;
use namespace::autoclean;

BEGIN { extends 'Catalyst::Controller'; }

=head1 NAME

$temporaryPackage - Catalyst Controller

=head1 DESCRIPTION

Catalyst Controller.

=head1 METHODS

=cut

use base 'Catalyst::Controller::REST';
BEGIN { extends 'Catalyst::Controller::REST'; }

sub gene : Path("/SearchDatabase/GetGene") : CaptureArgs(7) :
ActionClass('REST') { }

sub gene_GET {
    my ( 
        \$self,            \$c,             \$pipeline,     \$geneID,
        \$geneDescription, \$noDescription, \$individually, \$featureId,
        \$pageSize,        \$offset, \$contig )
    = \@_;
    if ( !\$geneID and defined \$c->request->param("geneID") ) {
        \$geneID = \$c->request->param("geneID");
    }
    if ( !\$geneDescription and defined \$c->request->param("geneDesc") ) {
        \$geneDescription = \$c->request->param("geneDesc");
    }
    if ( !\$noDescription and defined \$c->request->param("noDesc") ) {
        \$noDescription = \$c->request->param("noDesc");
    }
    if ( !\$individually and defined \$c->request->param("individually") ) {
        \$individually = \$c->request->param("individually");
    }
    if ( !\$featureId and defined \$c->request->param("featureId") ) {
        \$featureId = \$c->request->param("featureId");
    }
    if ( !\$pageSize and defined \$c->request->param("pageSize") ) {
        \$pageSize = \$c->request->param("pageSize");
    }
    if ( !\$offset and defined \$c->request->param("offset") ) {
        \$offset = \$c->request->param("offset");
    }
    if ( !\$contig and defined \$c->request->param("contig") ) {
        \$contig = \$c->request->param("contig");
    }
    my \$searchDBClient =
    Report_HTML_DB::Clients::SearchDBClient->new(
        rest_endpoint => \$c->config->{rest_endpoint} );
    my \$pagedResponse = \$searchDBClient->getGene( \$c->config->{pipeline_id},
        \$geneID, \$geneDescription,
        \$noDescription, \$individually, \$featureId, \$pageSize, \$offset, \$contig );
    standardStatusOk(
        \$self, \$c, \$pagedResponse->{response}, \$pagedResponse->{"total"},
        \$pageSize, \$offset

    );
}

sub gene_basics : Path("/SearchDatabase/GetGeneBasics") : CaptureArgs(1) :
ActionClass('REST') { }

sub gene_basics_GET {
    my ( \$self, \$c, \$id ) = \@_;
    if ( !\$id and defined \$c->request->param("id") ) {
        \$id = \$c->request->param("id");
    }
    my \$searchDBClient =
    Report_HTML_DB::Clients::SearchDBClient->new(
        rest_endpoint => \$c->config->{rest_endpoint} );
    standardStatusOk(
        \$self, \$c,
        \$searchDBClient->getGeneBasics(
            \$id, \$c->config->{pipeline_id}
        )->{response}
    );
}

sub subsequence : Path("/SearchDatabase/GetSubsequence") : CaptureArgs(5) :
ActionClass('REST') { }

sub subsequence_GET {
    my ( \$self, \$c, \$type, \$contig, \$sequenceName, \$start, \$end ) = \@_;
    if ( !\$contig and defined \$c->request->param("contig") ) {
        \$contig = \$c->request->param("contig");
    }
    if ( !\$type and defined \$c->request->param("type") ) {
        \$type = \$c->request->param("type");
    }
    if ( !\$sequenceName and defined \$c->request->param("sequenceName") ) {
        \$sequenceName = \$c->request->param("sequenceName");
    }
    if ( !\$start and defined \$c->request->param("start") ) {
        \$start = \$c->request->param("start");
    }
    if ( !\$end and defined \$c->request->param("end") ) {
        \$end = \$c->request->param("end");
    }
    my \$searchDBClient =
    Report_HTML_DB::Clients::SearchDBClient->new(
        rest_endpoint => \$c->config->{rest_endpoint} );
    standardStatusOk(
        \$self, \$c,
        \$searchDBClient->getSubsequence(
            \$type, \$contig, \$sequenceName, \$start, \$end, \$c->config->{pipeline_id}
        )->{response}
    );
}

sub subEvidences : Path("/SearchDatabase/SubEvidences") : CaptureArgs(1) :
ActionClass('REST') { }

sub subEvidences_GET {
    my ( \$self, \$c, \$feature, \$locus_tag) = \@_;
    if ( !\$feature and defined \$c->request->param("feature") ) {
        \$feature = \$c->request->param("feature");
    }
    if( !\$locus_tag and defined \$c->request->param("locus_tag") ) {
        \$locus_tag = \$c->request->param("locus_tag");
    }
    my \$searchDBClient =
    Report_HTML_DB::Clients::SearchDBClient->new(
        rest_endpoint => \$c->config->{rest_endpoint} );
    my \@subevidences = \@{\$searchDBClient->getSubevidences(
    \$feature, \$c->config->{pipeline_id}
    )->{response}}; 

    my \%components = map { \$_ => 1 }  split(" ", \$c->config->{components_ev});

    exists \$components{\$_->{program}} ? delete \$components{\$_->{program}} : next foreach (\@subevidences);

    unless (exists \$components{"annotation_interpro.pl"}) {                                                   
        my \$subInterpro;
        for my \$i(  0 .. \$#subevidences) {
            \$subInterpro = \$subevidences[\$i] if(\$subevidences[\$i]->{program} eq "annotation_interpro.pl");
        }
        my \%subevidence = (
                id                  => \$subInterpro->{id},
                type                => \$subInterpro->{type},
                number              => "",
                start               => "",
                end                 => "",
                strand              => "",
                is_obsolete         => \$searchDBClient->getGOResultsByFeatureID(\$feature, \$c->config->{pipeline_id})->{response},
                program             => "annotation_go.pl",
                program_description => "GO - Gene Ontology",
        );
        push \@subevidences, \\\%subevidence;
    } else {
        my \$subevidence = Report_HTML_DB::Models::Application::Subevidence->new(
                id                  => "",
                type                => "",
                number              => "",
                start               => "",
                end                 => "",
                strand              => "",
                is_obsolete         => "",
                program             => "annotation_go.pl",
                program_description => "GO - Gene Ontology",
        );
        push \@subevidences, \$subevidence->pack();
    }

    foreach my \$component (keys \%components) {
        \$component =~ s/\\.pl//;
        my \$resultSet = \$c->model('Basic::Component')->search(
            {
                -and => [
                    'locus_tag' => \$locus_tag,
                    'name'      => \$component
                ]
            },
            {
                order_by => {
                    -asc => [qw/ component /]
                },
            }
        );
        my \%hash = ();

        my \%component_name = (
            'annotation_interpro.pl' => 'InterProScan - Domain search',
            'annotation_blast.pl'    => 'BLAST - Similarity search',
            'annotation_rpsblast.pl' => 'RPS-BLAST - Similarity search',
            'annotation_phobius.pl' =>
            'Phobius - Transmembrane domains and signal peptide',
            'annotation_pathways.pl'  => 'KEGG - Pathway mapping',
            'annotation_orthology.pl' => 'eggNOG - Orthology assignment',
            'annotation_tcdb.pl'      => 'TCDB - Transporter classification',
            'annotation_dgpi.pl'      => 'DGPI - GPI anchor',
            'annotation_predgpi.pl'	=> 'PreDGPI',
            'annotation_tmhmm.pl'     => 'TMHMM',
            'annotation_hmmer.pl'	=> 'HMMER',
            "annotation_signalP.pl" => 'SignalP - Signal peptide',
            'annotation_bigpi.pl'   => 'BIGPI',
        );
        while ( my \$result = \$resultSet->next ) {
            my \$subevidence = Report_HTML_DB::Models::Application::Subevidence->new(
                id                  => "",
                type                => "",
                number              => "",
                start               => "",
                end                 => "",
                strand              => "",
                is_obsolete         => "",
                program             => \$component,
                program_description => \$component_name{\$component . ".pl"},
            );
            push \@subevidences, \$subevidence->pack();
        }
    }

    standardStatusOk( \$self, \$c, \\\@subevidences );
}

sub analysesCDS : Path("/SearchDatabase/analysesCDS") : CaptureArgs(31) :
ActionClass('REST') { }

sub analysesCDS_GET {
    my ( \$self, \$c) = \@_;
    my \%hash = ();
    my \$components = "";
    foreach my \$key ( keys \%{ \$c->request->params } ) {
        if ( \$key && \$key ne "0") {
            if(\$c->request->params->{\$key} eq "0" ) {
                \$hash{\$key} = "-0";
            } elsif(\$key eq "components") {
                \$components = \$c->request->params->{\$key};
            } else {
                \$hash{\$key} = \$c->request->params->{\$key};
            }
        }
    }
    \$hash{pipeline} = \$c->config->{pipeline_id};
    if (\$components =~ /ARRAY/) {
       \$hash{components} = join(",", \@{\$components});
    } else {
       \$hash{components} = \$components ;
    }
    my \$searchDBClient =
    Report_HTML_DB::Clients::SearchDBClient->new(
        rest_endpoint => \$c->config->{rest_endpoint} );
    my \$pagedResponse = \$searchDBClient->getAnalysesCDS( \\\%hash );
    standardStatusOk(
        \$self, \$c,
        \$pagedResponse->{response},
        \$pagedResponse->{total},
        \$hash{pageSize}, \$hash{offset}
    );
}

sub trnaSearch : Path("/SearchDatabase/trnaSearch") : CaptureArgs(4) :
ActionClass('REST') { }

sub trnaSearch_GET {
    my ( \$self, \$c ) = \@_;

    my \%hash = ();
    foreach my \$key ( keys \%{ \$c->request->params } ) {
        if ( \$key && \$key ne "0" ) {
            \$hash{\$key} = \$c->request->params->{\$key};
        }
    }
    \$hash{pipeline} = \$c->config->{pipeline_id};
    my \$searchDBClient =
    Report_HTML_DB::Clients::SearchDBClient->new(
        rest_endpoint => \$c->config->{rest_endpoint} );
    my \$response = \$searchDBClient->getTRNA( \\\%hash );
    standardStatusOk(
        \$self, \$c, \$response->{response}, \$response->{total}, \$hash{pageSize},
        \$hash{offset}
    );
}

sub tandemRepeatsSearch : Path("/SearchDatabase/tandemRepeatsSearch") :
CaptureArgs(5) : ActionClass('REST') { }

sub tandemRepeatsSearch_GET {
    my ( \$self, \$c ) = \@_;

    my \%hash = ();
    foreach my \$key ( keys \%{ \$c->request->params } ) {
        if ( \$key && \$key ne "0" ) {
            \$hash{\$key} = \$c->request->params->{\$key};
        }
    }
    \$hash{pipeline} = \$c->config->{pipeline_id};
    my \$searchDBClient =
    Report_HTML_DB::Clients::SearchDBClient->new(
        rest_endpoint => \$c->config->{rest_endpoint} );
    my \$response = \$searchDBClient->getTandemRepeats( \\\%hash ); 
    standardStatusOk(
        \$self, \$c,
        \$response->{response}, \$response->{total}, \$hash{pageSize}, \$hash{offset}
    );
}

sub getrRNASearch : Path("/SearchDatabase/rRNA_search") : CaptureArgs(4) : ActionClass('REST') { }

sub getrRNASearch_GET {
    my ( \$self, \$c ) = \@_;
    my \%hash = ();
    foreach my \$key ( keys \%{ \$c->request->params } ) {
        if ( \$key && \$key ne "0" ) {
            \$hash{\$key} = \$c->request->params->{\$key};
        }
    }
    \$hash{pipeline} = \$c->config->{pipeline_id};

    my \$searchDBClient =
    Report_HTML_DB::Clients::SearchDBClient->new(
        rest_endpoint => \$c->config->{rest_endpoint} );

    my \$response = \$searchDBClient->getrRNASearch(\\\%hash);

    standardStatusOk(
        \$self, \$c, \$response->{response}, \$response->{total},  
        \$hash{pageSize}, \$hash{offset}
    );
}

sub ncRNASearch : Path("/SearchDatabase/ncRNASearch") : CaptureArgs(7) :
ActionClass('REST') { }

sub ncRNASearch_GET {
    my ( \$self, \$c ) = \@_;
    my \%hash = ();
    foreach my \$key ( keys \%{ \$c->request->params } ) {
        if ( \$key && \$key ne "0" ) {
            \$hash{\$key} = \$c->request->params->{\$key};
        }
    }
    \$hash{pipeline} = \$c->config->{pipeline_id};
    my \$searchDBClient =
    Report_HTML_DB::Clients::SearchDBClient->new(
        rest_endpoint => \$c->config->{rest_endpoint} );
    my \$response = \$searchDBClient->getncRNA( \\\%hash );
    standardStatusOk(
        \$self, \$c,
        \$response->{response}, \$response->{total}, \$hash{pageSize}, \$hash{offset}
    );
}

sub transcriptionalTerminatorSearch :
Path("/SearchDatabase/transcriptionalTerminatorSearch") : CaptureArgs(6) :
ActionClass('REST') { }

sub transcriptionalTerminatorSearch_GET {
    my ( \$self, \$c ) = \@_;
    my \%hash = ();
    foreach my \$key ( keys \%{ \$c->request->params } ) {
        if ( \$key && \$key ne "0" ) {
            \$hash{\$key} = \$c->request->params->{\$key};
        }
    }
    \$hash{pipeline} = \$c->config->{pipeline_id};
    my \$searchDBClient =
    Report_HTML_DB::Clients::SearchDBClient->new(
        rest_endpoint => \$c->config->{rest_endpoint} );
    my \$response = \$searchDBClient->getTranscriptionalTerminator( \\\%hash );
    standardStatusOk(
        \$self, \$c,
        \$response->{response}, \$response->{total}, \$hash{pageSize}, \$hash{offset}
    );
}

sub rbsSearch : Path("/SearchDatabase/rbsSearch") : CaptureArgs(4) :
ActionClass('REST') {
}

sub rbsSearch_GET {
    my ( \$self, \$c ) = \@_;
    my \%hash = ();
    foreach my \$key ( keys \%{ \$c->request->params } ) {
        if ( \$key && \$key ne "0" ) {
            \$hash{\$key} = \$c->request->params->{\$key};
        }
    }
    \$hash{pipeline} = \$c->config->{pipeline_id};
    my \$searchDBClient =
    Report_HTML_DB::Clients::SearchDBClient->new(
        rest_endpoint => \$c->config->{rest_endpoint} );
    my \$response = \$searchDBClient->getRBSSearch( \\\%hash );
    standardStatusOk(
        \$self, \$c,
        \$response->{response}, \$response->{total}, \$hash{pageSize}, \$hash{offset}
    );
}

sub alienhunterSearch : Path("/SearchDatabase/alienhunterSearch") :
CaptureArgs(6) : ActionClass('REST') { }

sub alienhunterSearch_GET {
    my ( \$self, \$c ) = \@_;
    my \%hash = ();
    foreach my \$key ( keys \%{ \$c->request->params } ) {
        if ( \$key && \$key ne "0" ) {
            \$hash{\$key} = \$c->request->params->{\$key};
        }
    }
    \$hash{pipeline} = \$c->config->{pipeline_id};
    my \$searchDBClient =
    Report_HTML_DB::Clients::SearchDBClient->new(
        rest_endpoint => \$c->config->{rest_endpoint} );
    my \$response = \$searchDBClient->getAlienHunter( \\\%hash );
    standardStatusOk(
        \$self, \$c,
        \$response->{response}, \$response->{total}, \$hash{pageSize}, \$hash{offset}
    );
}

sub geneByPosition : Path("/SearchDatabase/geneByPosition") :
CaptureArgs(3) : ActionClass('REST') { }

sub geneByPosition_GET {
    my ( \$self, \$c, \$start, \$end, \$contig, \$pageSize, \$offset ) = \@_;
    if ( !\$start and defined \$c->request->param("start") ) {
        \$start = \$c->request->param("start");
    }
    if ( !\$end and defined \$c->request->param("end") ) {
        \$end = \$c->request->param("end");
    }
    if ( !\$pageSize and defined \$c->request->param("pageSize") ) {
        \$pageSize = \$c->request->param("pageSize");
    }
    if ( !\$offset and defined \$c->request->param("offset") ) {
        \$offset = \$c->request->param("offset");
    }
    if ( !\$contig and defined \$c->request->param("contig") ) {
        \$contig = \$c->request->param("contig");
    }

    \$contig = \$c->model('Basic::Sequence')->search({ name => \$contig}, { columns => [ qw/ id / ] })->first()->{_column_data}->{"id"};

    my \$searchDBClient =
    Report_HTML_DB::Clients::SearchDBClient->new(
        rest_endpoint => \$c->config->{rest_endpoint} );
    my \$response = \$searchDBClient->getGeneByPosition(
        \$start, \$end, \$contig, \$c->config->{pipeline_id}, \$pageSize, \$offset
    );
    standardStatusOk(
        \$self, \$c, \$response->{response}, \$response->{total}, \$pageSize, \$offset
    );
}

sub getSimilarityEvidenceProperties :
Path("/SearchDatabase/getSimilarityEvidenceProperties") : CaptureArgs(1) :
ActionClass('REST') { }

sub getSimilarityEvidenceProperties_GET {
    my ( \$self, \$c, \$feature ) = \@_;
    if ( !\$feature and defined \$c->request->param("feature") ) {
        \$feature = \$c->request->param("feature");
    }
    my \$searchDBClient =
    Report_HTML_DB::Clients::SearchDBClient->new(
        rest_endpoint => \$c->config->{rest_endpoint} );

    my \%hash = \%{\$searchDBClient->getSimilarityEvidenceProperties(\$feature)->{response}};
    my \%returnedHash = \%{\$searchDBClient->getIdentifierAndDescriptionSimilarity(\$feature)->{response}};
    foreach my \$key (keys \%returnedHash) {
        \$hash{\$key} = \$returnedHash{\$key};
    }
    standardStatusOk( \$self, \$c, \\\%hash );
}

sub getIntervalEvidenceProperties :
Path("/SearchDatabase/getIntervalEvidenceProperties") : CaptureArgs(3) :
ActionClass('REST') { }

sub getIntervalEvidenceProperties_GET {
    my ( \$self, \$c, \$feature, \$typeFeature, \$pipeline ) = \@_;
    if ( !\$feature and defined \$c->request->param("feature") ) {
        \$feature = \$c->request->param("feature");
    }
    if ( !\$typeFeature and defined \$c->request->param("typeFeature") ) {
        \$typeFeature = \$c->request->param("typeFeature");
    }
    if ( !\$pipeline and defined \$c->request->param("pipeline") ) {
        \$pipeline = \$c->request->param("pipeline");
    }
    my \$searchDBClient =
    Report_HTML_DB::Clients::SearchDBClient->new(
        rest_endpoint => \$c->config->{rest_endpoint} );
    standardStatusOk( \$self, \$c,
        \$searchDBClient->getIntervalEvidenceProperties(\$feature, \$typeFeature, \$pipeline)->{response} );
}


sub getTargetClass :
Path("/SearchDatabase/target_class") : CaptureArgs(0) :
ActionClass('REST') { }

sub getTargetClass_GET {
    my (\$self, \$c) = \@_;
    my \$searchDBClient =
    Report_HTML_DB::Clients::SearchDBClient->new(
        rest_endpoint => \$c->config->{rest_endpoint} );
    standardStatusOk( \$self, \$c,
        \$searchDBClient->getTargetClass(\$c->config->{pipeline_id})->getResponse() );
}

sub getRibosomalRNAs :
Path("/SearchDatabase/getRibosomalRNAs") : CaptureArgs(0) :
ActionClass('REST') { }

sub getRibosomalRNAs_GET {
    my (\$self, \$c) = \@_;
    my \$searchDBClient =
    Report_HTML_DB::Clients::SearchDBClient->new(
        rest_endpoint => \$c->config->{rest_endpoint} );
    standardStatusOk( \$self, \$c,
        [sort { \$a <=> \$b } \@{\$searchDBClient->getRibosomalRNAs(\$c->config->{pipeline_id})->getResponse()}]);
}

=head2
Standard return of status ok
=cut

sub standardStatusOk {
    my ( \$self, \$c, \$response, \$total, \$pageSize, \$offset ) = \@_;
    if (   ( defined \$total || \$total )
        && ( defined \$pageSize || \$pageSize )
        && ( defined \$offset   || \$offset ) )
    {
        my \$pagedResponse = \$c->model('PagedResponse')->new(
            status_code => 200,
            message     => "Ok",
            elapsed_ms  => \$c->stats->elapsed,
            response    => \$response,
            total       => \$total,
            pageSize    => \$pageSize,
            offset      => \$offset,
        );
        \$self->status_ok( \$c, entity => \$pagedResponse->pack(), );
    }
    else {
        my \$baseResponse = \$c->model('BaseResponse')->new(
            status_code => 200,
            message     => "Ok",
            elapsed_ms  => \$c->stats->elapsed,
            response    => \$response
        );
        \$self->status_ok( \$c, entity => \$baseResponse->pack(), );
    }
}

=encoding utf8

=head1 AUTHOR

Wendel Hime L. Castro,,,

=head1 LICENSE

This library is free software. You can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

__PACKAGE__->meta->make_immutable;

1;

SEARCHDBCONTENT
writeFile( "$html_dir/lib/$libDirectoryWebsite/Controller/SearchDatabase.pm",
    $searchDBContent );

$temporaryPackage = $packageWebsite . '::Controller::Blast';
my $blastContent = <<BLAST;
package $temporaryPackage;
use Moose;
use namespace::autoclean;

BEGIN { extends 'Catalyst::Controller'; }

=head1 NAME

$temporaryPackage - Catalyst Controller

=head1 DESCRIPTION

Catalyst Controller.

=head1 METHODS

=cut

use base 'Catalyst::Controller::REST';
BEGIN { extends 'Catalyst::Controller::REST'; }

sub search : Path("/Blast/search") : CaptureArgs(7) : ActionClass('REST') { }

sub search_POST {
    my (
        \$self,                \$c,                  \$blast,
        \$database,            \$fastaSequence,      \$from,
        \$to,                  \$filter,             \$expect,
        \$matrix,              \$ungappedAlignment,  \$geneticCode,
        \$databaseGeneticCode, \$frameShiftPenality, \$otherAdvanced,
        \$graphicalOverview,   \$alignmentView,      \$descriptions,
        \$alignments,          \$colorSchema,        \$fastaFile,
        \$costOpenGap,          \$costToExtendGap,  \$wordSize
    ) = \@_;
    if ( !\$blast and defined \$c->request->param("PROGRAM") ) {
        \$blast = \$c->request->param("PROGRAM");
    }
    if ( !\$database and defined \$c->request->param("DATALIB") ) {
        \$database = \$c->request->param("DATALIB");
    }
    if ( !\$fastaSequence and defined \$c->request->param("SEQUENCE") ) {
        \$fastaSequence = \$c->request->param("SEQUENCE");
    }
    if ( !\$fastaFile and defined \$c->request->param("SEQFILE") ) {
        \$fastaFile = \$c->request->param("SEQFILE");
    }
    if ( !\$from and defined \$c->request->param("QUERY_FROM") ) {
        \$from = \$c->request->param("QUERY_FROM");
    }
    if ( !\$to and defined \$c->request->param("QUERY_TO") ) {
        \$to = \$c->request->param("QUERY_TO");
    }
    if ( !\$filter and defined \$c->request->param("FILTER") ) {
        \$filter = \$c->request->param("FILTER");
    }
    if ( !\$expect and defined \$c->request->param("EXPECT") ) {
        \$expect = \$c->request->param("EXPECT");
    }
    if ( !\$matrix and defined \$c->request->param("MAT_PARAM") ) {
        \$matrix = \$c->request->param("MAT_PARAM");
    }
    if ( !\$ungappedAlignment
            and defined \$c->request->param("UNGAPPED_ALIGNMENT") )
    {
        \$ungappedAlignment = \$c->request->param("UNGAPPED_ALIGNMENT");
    }
    if ( !\$geneticCode and defined \$c->request->param("GENETIC_CODE") ) {
        \$geneticCode = \$c->request->param("GENETIC_CODE");
    }
    if ( !\$databaseGeneticCode
            and defined \$c->request->param("DB_GENETIC_CODE") )
    {
        \$databaseGeneticCode = \$c->request->param("DB_GENETIC_CODE");
    }
    if ( !\$otherAdvanced and defined \$c->request->param("OTHER_ADVANCED") ) {
        \$otherAdvanced = \$c->request->param("OTHER_ADVANCED");
    }
    if ( !\$graphicalOverview
            and defined \$c->request->param("OVERVIEW") )
    {
        \$graphicalOverview = \$c->request->param("OVERVIEW");
    }
    if ( !\$alignmentView and defined \$c->request->param("ALIGNMENT_VIEW") ) {
        \$alignmentView = \$c->request->param("ALIGNMENT_VIEW");
    }
    if ( !\$descriptions and defined \$c->request->param("DESCRIPTIONS") ) {
        \$descriptions = \$c->request->param("DESCRIPTIONS");
    }
    if ( !\$alignments and defined \$c->request->param("ALIGNMENTS") ) {
        \$alignments = \$c->request->param("ALIGNMENTS");
    }
    if ( !\$costOpenGap and defined \$c->request->param("COST_OPEN_GAP") ) {
        \$costOpenGap = \$c->request->param("COST_OPEN_GAP");
    }
    if ( !\$costToExtendGap and defined \$c->request->param("COST_EXTEND_GAP") ) {
        \$costToExtendGap = \$c->request->param("COST_EXTEND_GAP");
    }
    if ( !\$wordSize and defined \$c->request->param("WORD_SIZE") ) {
        \$wordSize = \$c->request->param("WORD_SIZE");
    }

    my \%hash = ();

    foreach my \$key ( keys \%{ \$c->request->params } ) {
        if ( \$key && \$key ne "0" ) {
            \$hash{\$key} = \$c->request->params->{\$key};
            \$hash{\$key} =~ s/['"&.|]//g;
        }
    }

    unless ( exists \$hash{SEQUENCE} ) {
        \$hash{SEQUENCE} = \$hash{SEQFILE};
        delete \$hash{SEQFILE};
    }
    my \$content = "";
    my \@fuckingSequence = split(/\\s+/, \$hash{SEQUENCE});
    \$hash{SEQUENCE} = join('\\n', \@fuckingSequence);
    print "\\n".\$hash{SEQUENCE}."\\n";
    if(\$hash{SEQUENCE} !~ />/) {
        \$hash{SEQUENCE} = ">Sequence\\n" . \$hash{SEQUENCE};
    }
    foreach my \$header (\$hash{SEQUENCE} =~ /^(>[\\w \\-\\(\\)\\[\\];.]*)+\\n/gm) {
        my \$auxHeader = \$header;
        \$header =~ s/ /_/g;
        \$hash{SEQUENCE} =~ s/\$auxHeader/\$header/g;
    }
    my \$blastClient =
    Report_HTML_DB::Clients::BlastClient->new(
        rest_endpoint => \$c->config->{rest_endpoint} );
    my \$baseResponse = \$blastClient->search( \\\%hash );
    \%hash = ();
    \$baseResponse = \$blastClient->fancy( \$baseResponse->{response} );
    my \$returnedHash = \$baseResponse->{response};
    use MIME::Base64;
    foreach my \$key (keys \%\$returnedHash) {
        if(\$key =~ /\.html/ ) {
            \$hash{\$key} = MIME::Base64::decode_base64(\$returnedHash->{\$key});
        } else {
            \$hash{\$key} = \$returnedHash->{\$key};
        }
    }

    standardStatusOk(\$self, \$c, \\\%hash);
}

=head2
Standard return of status ok
=cut

sub standardStatusOk {
    my ( \$self, \$c, \$response, \$total, \$pageSize, \$offset ) = \@_;
    if (   ( defined \$total || \$total )
        && ( defined \$pageSize || \$pageSize )
        && ( defined \$offset   || \$offset ) )
    {
        my \$pagedResponse = \$c->model('PagedResponse')->new(
            status_code => 200,
            message     => "Ok",
            elapsed_ms  => \$c->stats->elapsed,
            response    => \$response,
            total       => \$total,
            pageSize    => \$pageSize,
            offset      => \$offset,
        );
        \$self->status_ok( \$c, entity => \$pagedResponse->pack(), );
    }
    else {
        my \$baseResponse = \$c->model('BaseResponse')->new(
            status_code => 200,
            message     => "Ok",
            elapsed_ms  => \$c->stats->elapsed,
            response    => \$response
        );
        \$self->status_ok( \$c, entity => \$baseResponse->pack(), );
    }
}

=encoding utf8

=head1 AUTHOR

Wendel Hime L. Castro,,,

=head1 LICENSE

This library is free software. You can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

__PACKAGE__->meta->make_immutable;

1;

BLAST

writeFile( "$html_dir/lib/$libDirectoryWebsite/Controller/Blast.pm",
    $blastContent );

$temporaryPackage = $packageWebsite . '::Controller::Root';
my $rootContent = <<ROOT;
package $temporaryPackage;
use Moose;
use namespace::autoclean;

BEGIN { extends 'Catalyst::Controller' }

#
# Sets the actions in this controller to be registered with no prefix
# so they function identically to actions created in MyApp.pm
#
__PACKAGE__->config(namespace => '');

=encoding utf-8

=head1 NAME

$temporaryPackage - Root Controller for $html_dir

=head1 DESCRIPTION

Root where will have the main pages

=head1 METHODS

=cut 

ROOT

#my @controllers = (
#	"Home", "Blast", "Downloads", "Help", "About"
#);
if ($hadGlobal) {
    $rootContent .= <<ROOT;

=head2 globalAnalyses

Global analyses page

=cut

sub globalAnalyses :Path("GlobalAnalyses") :Args(0) {
    my ( \$self, \$c ) = \@_;
    \$c->stash->{titlePage} = 'Global Analyses';
    \$c->stash(currentPage => 'global-analyses');
    \$c->stash(texts => [encodingCorrection (\$c->model('Basic::Text')->search({
                        -or => [
                            tag => {'like', 'header%'},
                            tag => 'menu',
                            tag => 'footer',
                            tag => {'like', 'global-analyses%'}
                        ]
                    }))]);

    \$c->stash(template => '$lowCaseName/global-analyses/index.tt');
    my \$components = resultsetListToHash([\$c->model('Basic::Component')->search({}, { columns => [ qw/component name/ ], group_by => [ qw/component name / ] })], "name", "component");
    \$c->stash(components => \$components);

    \$c->stash->{hadGlobal} = 1;
    \$c->stash->{hadSearchDatabase} = {{valorSearchSubtituir}};


}

ROOT

#	push @controllers, "GlobalAnalyses";
}
if ($hadSearchDatabase) {
    $rootContent .= <<ROOT;

=head2 searchDatabase

Search database page (/SearchDatabase)

=cut
sub searchDatabase :Path("SearchDatabase") :Args(0) {
    my ( \$self, \$c, \$id ) = \@_;
    if(defined \$c->request->param("id")) {
        \$id = \$c->request->param("id");
    }
    \$c->stash->{titlePage} = 'Search Database';
    \$c->stash(currentPage => 'search-database');
    \$c->stash(texts => [encodingCorrection (\$c->model('Basic::Text')->search({
                        -or => [
                            tag => {'like', 'header%'},
                            tag => 'menu',
                            tag => 'footer',
                        ]
                    }))]);

    my \%hash = ();

    my \@texts = encodingCorrection (
        \$c->model('Basic::Text')->search({
                -or => [
                    tag => {'like', 'search-database%'}
                ]
            })
    );

    \$c->stash(searchDBTexts => resultsetListToHash(\\\@texts, "tag", "value"));

    my \$searchDBClient = Report_HTML_DB::Clients::SearchDBClient->new(rest_endpoint => \$c->config->{rest_endpoint});
    my \$pipeline;

    if(!\$c->config->{pipeline_id}) {
        my \$response = \$searchDBClient->getPipeline()->getResponse()->{pipeline_id};
        use File::Basename;
        open( my \$FILEHANDLER,
            ">>", \$c->path_to('.') . "/" . "$lowCaseName.conf");
        print \$FILEHANDLER "\npipeline_id \$response\n";
        close(\$FILEHANDLER);
        \$pipeline = \$response;
    } else {
        \$pipeline = \$c->config->{pipeline_id};
    }

    \$c->stash(id => \$id);

    \$c->stash(
        sequences => [
            \$c->model('Basic::Sequence')->search({}, { columns => [ qw/ id name / ] })
        ]
    );

    \$c->stash(template => '$lowCaseName/search-database/index.tt');
    my \$components = resultsetListToHash([\$c->model('Basic::Component')->search({}, { columns => [ qw/component name/ ], group_by => [ qw/component name / ] })], "name", "component");
    \$c->stash(components => \$components);
    if(\$components->{"annotation_pathways"}) {
        my \$filepath = \$c->model('Basic::Component')->search({ component => { 'like', 'report%kegg'} }, { columns => [ qw/filepath/ ], group_by => [ qw/filepath/ ] })->
        first()->{_column_data}->{"filepath"};
        #\$filepath =~ /(reports[\\w\\/]+\\/)/g;
        \$c->stash->{report_pathways} = \$filepath;
    }
    \$c->stash->{hadGlobal} = {{valorGlobalSubstituir}};
    \$c->stash->{hadSearchDatabase} = 1;

}

ROOT

#	push @controllers, "SearchDatabase";
}

$rootContent .= <<ROOT;

sub resultsetListToHash {
        my (\$list, \$keyColumn, \$valueColumn) = \@_;
        my \@texts = \@{\$list};
        my \%hash = ();
        foreach my \$text (\@texts) {
                if ( exists \$hash{\$text->{_column_data}->{\$keyColumn}}) {
                        my \@list = ();
                        \@list = \@{ \$hash{\$text->{_column_data}->{\$keyColumn}} } if (ref(\$hash{\$text->{_column_data}->{\$keyColumn}}) =~ m/ARRAY/g);
                        push \@list, \$hash{\$text->{_column_data}->{\$keyColumn}} unless (ref(\$hash{\$text->{_column_data}->{\$keyColumn}}) =~ m/ARRAY/g);
                        push \@list, \$text->{_column_data}->{\$valueColumn};
                        \$hash{\$text->{_column_data}->{\$keyColumn}} = \\\@list;

                } else {
                        \$hash{\$text->{_column_data}->{\$keyColumn}} = \$text->{_column_data}->{\$valueColumn};
                }
        }
        return \\\%hash;
}

=head2 about

About page (/About)

=cut

sub about : Path("About") : Args(0) {
    my ( \$self, \$c ) = \@_;
    \$c->stash->{titlePage} = 'About';
    \$c->stash( currentPage => 'about' );
    \$c->stash(
        texts => [
            encodingCorrection(
                \$c->model('Basic::Text')->search(
                    {
                        -or => [
                            tag => { 'like', 'header\%' },
                            tag => 'menu',
                            tag => 'footer',
                            tag => { 'like', 'about\%' }
                        ]
                    }
                )
            )
        ]
    );
    \$c->stash( template => '$lowCaseName/about/index.tt' );
    \$c->stash->{hadGlobal}         = {{valorGlobalSubstituir}};
    \$c->stash->{hadSearchDatabase} = {{valorSearchSubtituir}};

}

=head2 blast

The blast page (/Blast)

=cut

sub blast : Path("Blast") : Args(0) {
    my ( \$self, \$c ) = \@_;
    \$c->stash->{titlePage} = 'Blast';
    \$c->stash( currentPage => 'blast' );
    \$c->stash(
        texts => [
            encodingCorrection(
                \$c->model('Basic::Text')->search(
                    {
                        -or => [
                            tag => { 'like', 'header\%' },
                            tag => 'menu',
                            tag => 'footer',
                            tag => { 'like', 'blast\%' }
                        ]
                    }
                )
            )
        ]
    );

    \$c->stash( template => '$lowCaseName/blast/index.tt' );
    \$c->stash->{hadGlobal}         = {{valorGlobalSubstituir}};
    \$c->stash->{hadSearchDatabase} = {{valorSearchSubtituir}};

}

=head2 downloads

The download page (/Downloads)

=cut

sub downloads : Path("Downloads") : Args(0) {
    my ( \$self, \$c ) = \@_;
    \$c->stash->{titlePage} = 'Downloads';
    \$c->stash( currentPage => 'downloads' );
    \$c->stash(
        texts => [
            encodingCorrection(
                \$c->model('Basic::Text')->search(
                    {
                        -or => [
                            tag => { 'like', 'header\%' },
                            tag => 'menu',
                            tag => 'footer',
                            tag => { 'like', 'downloads\%' }
                        ]
                    }
                )
            )
        ]
    );

    \$c->stash( template => '$lowCaseName/downloads/index.tt' );
    \$c->stash->{hadGlobal}         = {{valorGlobalSubstituir}};
    \$c->stash->{hadSearchDatabase} = {{valorSearchSubtituir}};

}

=head2 encodingCorrection

Method used to correct encoding strings come from SQLite

=cut

sub encodingCorrection {
    my (\@texts) = \@_;

    use utf8;
    use Encode qw( decode encode );
    foreach my \$text (\@texts) {
        foreach my \$key ( keys \%\$text ) {
            if ( \$text->{\$key} != 1 ) {
                my \$string = decode( 'utf-8', \$text->{\$key}{value} );
                \$string = encode( 'iso-8859-1', \$string );
                \$text->{\$key}{value} = \$string;
            }
        }
    }
    return \@texts;
}

=head2

Method used to get feature id

=cut

#sub get_feature_id {
#	my (\$c) = \@_;
#	return \$c->model('SearchDatabaseRepository')->get_feature_id(\$c->config->{uniquename});
#}

=head2 help

The help page (/Help)

=cut

sub help : Path("Help") : Args(0) {
    my ( \$self, \$c ) = \@_;
    \$c->stash->{titlePage} = 'Help';
    \$c->stash( currentPage => 'help' );
    \$c->stash(
        texts => [
            encodingCorrection(
                \$c->model('Basic::Text')->search(
                    {
                        -or => [
                            tag => { 'like', 'header\%' },
                            tag => 'menu',
                            tag => 'footer',
                            tag => { 'like', 'help\%' }
                        ]
                    }
                )
            )
        ]
    );
    #if ( !defined \$feature_id ) {
    #	\$feature_id = get_feature_id(\$c);
    #}
    #\$c->stash( teste    => \$feature_id );
    \$c->stash( template => '$lowCaseName/help/index.tt' );
    \$c->stash->{hadGlobal}         = {{valorGlobalSubstituir}};
    \$c->stash->{hadSearchDatabase} = {{valorSearchSubtituir}};

}

=head2 index

The root page (/)

=cut

sub index : Path : Args(0) {
    my ( \$self, \$c ) = \@_;
    \$c->stash->{titlePage} = 'Home';
    \$c->stash( currentPage => 'home' );
    \$c->stash(
        texts => [
            encodingCorrection(
                \$c->model('Basic::Text')->search(
                    {
                        -or => [
                            tag => { 'like', 'header\%' },
                            tag => 'menu',
                            tag => 'footer',
                            tag => { 'like', 'home\%' }
                        ]
                    }
                )
            )
        ]
    );
    #if ( !defined \$feature_id ) {
    #	\$feature_id = get_feature_id(\$c);
    #}
    \$c->stash( template => '$lowCaseName/home/index.tt' );
    \$c->stash->{hadGlobal}         = {{valorGlobalSubstituir}};
    \$c->stash->{hadSearchDatabase} = {{valorSearchSubtituir}};

}

sub downloadFile : Path("DownloadFile") : CaptureArgs(1) {
    my ( \$self, \$c, \$type ) = \@_;
    if ( !\$type and defined \$c->request->param("type") ) {
        \$type = \$c->request->param("type");
    }
    my \$filepath = (
        \$c->model('Basic::File')->search(
            {
                tag => "\$type"
            },
            {
                columns => qw/filepath/,
                rows    => 1
            }
        )->single->get_column(qw/filepath/)
    );

    open( my \$FILEHANDLER, "<", \$c->path_to('root') . "/" . \$filepath );
    binmode \$FILEHANDLER;
    my \$file;

    local \$/ = \\10240;
    while (<\$FILEHANDLER>) {
        \$file .= \$_;
    }
    \$c->response->body(\$file);
    \$c->response->headers->content_type('application/x-download');
    my \$filename = "";
    if(\$filepath =~ /\\/*([\\w\\s\\-_]*\\.[\\w\\s\\-_]+)/g) {
                    \$filename = \$1;
                }
                \$c->response->body(\$file);
                \$c->response->header('Content-Disposition' => 'attachment; filename='.\$filename);
                close \$FILEHANDLER;
            }

            sub downloadSequence : Path("DownloadSequence") : CaptureArgs(4) {
                my ( \$self, \$c, \$contig, \$start, \$end, \$reverseComplement ) = \@_;
                if ( !\$contig and defined \$c->request->param("contig") ) {
                    \$contig = \$c->request->param("contig");
                }
                if ( !\$start and defined \$c->request->param("start") ) {
                    \$start = \$c->request->param("start");
                }
                if ( !\$end and defined \$c->request->param("end") ) {
                    \$end = \$c->request->param("end");
                }
                if ( !\$reverseComplement
                        and defined \$c->request->param("reverseComplement") )
                {
                    \$reverseComplement = \$c->request->param("reverseComplement");
                }

                my \$sequence = sequenceContig(\$c, \$contig, \$start, \$end, \$reverseComplement);

                use File::Temp ();
                my \$fh    = File::Temp->new();
                my \$fname = \$fh->filename;
                open(my \$FILEHANDLER, ">", \$fname );
                my \$fastaHeader = ">".\$sequence->{gene};
                if(\$start && \$end) {
                    \$fastaHeader .= "_(".\$start."-".\$end.")";
                }
                if(\$reverseComplement) {
                    \$fastaHeader .= "_reverse_complemented";
                }
                print \$FILEHANDLER \$fastaHeader ."\n".\$sequence->{contig};
                close(\$FILEHANDLER);

                open( \$FILEHANDLER, "<", \$fname );
                binmode \$FILEHANDLER;
                my \$file;

                local \$/ = \\10240;
                while (<\$FILEHANDLER>) {
                    \$file .= \$_;
                }
                \$c->response->body(\$file);
                \$c->response->headers->content_type('application/x-download');

                \$c->response->body(\$file);
                \$fastaHeader =~ s/>//g;
                \$c->response->header('Content-Disposition' => 'attachment; filename='.\$fastaHeader . ".fasta");
                close \$FILEHANDLER;
            }

            sub sequenceContig {
                my ( \$c, \$contig, \$start, \$end, \$reverseComplement ) = \@_;
                use File::Basename;
                my \$data     = "";
                my \$sequence = \$c->model('Basic::Sequence')->search({ "name" => \$contig}, {})->first;

                open( my \$FILEHANDLER,
                    "<", \$c->path_to('root') . "/" . \$sequence->filepath );

                my \$content = do { local \$/; <\$FILEHANDLER> };

                my \@lines = \$content =~ /^(\\w+)\\n*\$/mg;
                \$data = join("", \@lines);

                close(\$FILEHANDLER);

                if ( \$start && \$end ) {
                    \$start += -1;
                    \$data = substr( \$data, \$start, ( \$end - \$start ) );
                    \$c->stash->{start}     = \$start;
                    \$c->stash->{end}       = \$end;
                    \$c->stash->{hadLimits} = 1;
                }
                if ( \$reverseComplement ) {
                    \$data = reverseComplement(\$data);
                    \$c->stash->{hadReverseComplement} = 1;
                }
                \$data = formatSequence(\$data);
                my \$result = \$data;

                my \%hash = ();
                \$hash{'geneID'} = \$sequence->id;
                \$hash{'gene'}   = \$sequence->name;
                \$hash{'contig'} = \$result;
                \$hash{'reverseComplement'} = \$reverseComplement ? 1 : 0;
                return \\\%hash;
            }

=head2 reverseComplement

Method used to return the reverse complement of a sequence

=cut

sub reverseComplement {
    my (\$sequence) = \@_;
    my \$reverseComplement = reverse(\$sequence);
    \$reverseComplement =~ tr/ACGTacgt/TGCAtgca/;
    return \$reverseComplement;
}

=head2 formatSequence

Method used to format sequence

=cut

sub formatSequence {
    my \$seq = shift;
    my \$block = shift || 80;
    \$seq =~ s/.{\$block}/\$&\\n/gs;
    chomp \$seq;
    return \$seq;
}

sub reports : Path("reports") : CaptureArgs(3) {
    my ( \$self, \$c, \$type, \@files ) = \@_;
    my \$filepath = "\$type";
    \$filepath .= "/". \$_ foreach (\@files);
    #my \$filepath = "\$type/\$file";
    #\$filepath .= "/\$file2" if \$file2;

    \$self->status_bad_request( \$c, message => "Invalid request" )
    if ( \$filepath =~ m/\\.\\.\\// );

    open( my \$FILEHANDLER,
        "<", \$c->path_to('root') . "/" . \$filepath );
    my \$content = "";
    while ( my \$line = <\$FILEHANDLER> ) {
        #\$line =~ s/href="/href="\\/reports\\/\$type\\//
        #if ( \$line =~ /href="/ && \$line !~ /href="http\\:\\/\\// );
        \$content .= \$line . "\\n";
    }
    close(\$FILEHANDLER);
    if(\$filepath =~ /\\.png/g) {
        use MIME::Base64;
        \$content = MIME::Base64::encode_base64(\$content);
    } elsif(\$filepath =~ /\.html/g) {
        my \$pathname = \$c->req->base; 
        if(!(\$filepath =~ m/pathway/  || \$filepath =~ m/html_image/ )) {
            \$pathname =~ s/\\\/*reports[\\w\\.\\/]*//g;
            if (\$filepath !~ m/kegg_organism_report/) {
                \$content =~ s/src="/src="\$pathname\\/\$type\\//igm;
            } else {
                \$content =~ s/src="/src="\$pathname\\/\$type\\/\$files[0]\\//igm ;
            }
            \$content =~ s/HREF="/HREF="\$pathname\\/\$type\\//g;
        } else {
            \$content =~ s/<link rel="stylesheet" href="/<link rel="stylesheet" href="\$pathname\\/reports\\/\$type\\/pathway_figures/g;
            \$content =~ s/<script language="JavaScript" src="/<script language="JavaScript" src="\$pathname\\/reports\\/\$type\\/pathway_figures/g;
            foreach (\$content =~ /<img[\\w\\s"=]*src="([\\.\\w\\s\\-\\/]*)"/img) {
        if(\$_ =~ m/kegg.gif/) {
        my \$imagePath = \$_;
        \$imagePath =~ s/\\.\\.\\///;
        open( \$FILEHANDLER, "<", \$c->path_to('root') . "/\$type/" . \$imagePath );
        } else {
        open( \$FILEHANDLER, "<", \$c->path_to('root') . "/\$type/\$files[0]" . "/" . \$_ );
        }
        my \$contentFile = do { local(\$/); <\$FILEHANDLER> };
        close(\$FILEHANDLER);
        use MIME::Base64;
        \$contentFile = MIME::Base64::encode_base64(\$contentFile);
        \$content =~ s/<img[\\w\\s"=]*src="\$_/<img src="data:image\\/png;base64,\$contentFile/;
}
#\$content =~ s/HREF="/HREF="\/\$type/igm;
        }
        my \$pathname = \$c->req->base . "SearchDatabase?id"; 
        \$content =~ s/<th( align="center")*>Blast result<\\\/th>/<th\$1>Gene<\\\/th>/g; 
        \$content =~ s/<td><a href="[\\w\\/\\.]*">([\\w\\s]*)/<td><a href="\$pathname=\$1">\$1/g if ((\$content !~ /Class abbreviation/ && \$content !~ /KEGG Code/ ) && \$type ne "kegg_organism_report" );
        \$content =~ s/([\\w]+)+( -[<>\\s|\\w=".\\/]*<br>)/<a href='\$pathname=\$1'>\$1<\\/a>\$2/g if(\$type eq "go_report");
        \$content =~ s/(\\/kegg_organism_report\\/)([\\w.]+)+"/\$1\$files[0]\\/\$2"/;
}
\$c->response->body(\$content);
}

=head2 default


Standard 404 error page

=cut

sub default : Path {
    my ( \$self, \$c ) = \@_;
    \$c->response->body('Oops, page not found');
    \$c->response->status(404);
}

=head2 renderView

Attempt to render a view, if needed.

=cut

sub renderView : ActionClass('RenderView') { }

sub end : Private {
    my ( \$self, \$c ) = \@_;

    if ( scalar \@{ \$c->error } ) {
        \$c->stash->{errors}   = \$c->error;
        for my \$error ( \@{ \$c->error } ) {
            \$c->log->error(\$error);
        }
        \$c->stash(
            texts => [
                encodingCorrection(
                    \$c->model('Basic::Text')->search(
                        {
                            -or => [
                                tag => { 'like', 'header%' },
                                tag => 'menu',
                                tag => 'footer',
                            ]
                        }
                    )
                )
            ]
        );
        \$c->stash->{hadGlobal}         = 1;
        \$c->stash->{hadSearchDatabase} = 1;
        \$c->stash->{template} = '$lowCaseName/errors.tt';
        \$c->forward('$packageWebsite\::View::TT');
        \$c->clear_errors;
    }

    return 1 if \$c->response->status =~ /^3\\d\\d\$/;
    return 1 if \$c->response->body;

    unless ( \$c->response->content_type ) {
        \$c->response->content_type('text/html; charset=utf-8');
    }

    \$c->forward('$packageWebsite\::View::TT');
}

=head1 AUTHOR

Wendel Hime L. Castro,,,

=head1 LICENSE

This library is free software. You can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

__PACKAGE__->meta->make_immutable;

1;


ROOT

if ( $rootContent =~ /\{\{valorGlobalSubstituir\}\}/g && $hadGlobal ) {
    $rootContent =~ s/\{\{valorGlobalSubstituir\}\}/1/g;
}
else {
    $rootContent =~ s/\{\{valorGlobalSubstituir\}\}/0/g;
}

if ( $rootContent =~ /\{\{valorSearchSubtituir\}\}/g && $hadSearchDatabase ) {
    $rootContent =~ s/\{\{valorSearchSubtituir\}\}/1/g;
}
else {
    $rootContent =~ s/\{\{valorSearchSubtituir\}\}/0/g;
}
my %hashDirectories = ();
foreach my $filepathComponent (@filepathsComponents) {
    if ($filepathComponent) {
        print $LOG "\nFilepath component:\t" . $filepathComponent . "\n";
        if ( $filepathComponent =~ /([\.\/\w]+)\//g ) {
            print $LOG "\nDir:\t" . $1 . "\n";
            `mkdir -p $standard_dir/$html_dir/root/`
            if !-e "$standard_dir/$html_dir/root/";
            if ( $1 ne '_dir' ) {
                my $directory = $1;
                print $LOG "\n[6356]\tDirectory:-\t$directory\n";
                if ( $1 !~ m/report/g ) {
                    `ln -f -s $directory $standard_dir/$html_dir/root/` if (!(-e "$standard_dir/$html_dir/root/$directory"));
                }
                else {
                    my $test = "";
                    #\/([\w._]+\/[\w._]*)$
                    $test = $_ foreach($directory =~ /\/([\w._]+)+$/img);
                    print $LOG "\n[7365] - $test\n" ;
                    unless(
                        -d "$standard_dir/$html_dir/root/$test" && 
                        -e "$standard_dir/$html_dir/root/$test" && 
                        exists $hashDirectories{"$standard_dir/$html_dir/root/$test"} && 
                        defined $hashDirectories{"$standard_dir/$html_dir/root/$test"} ) 
                    {

                        `ln -f -s $directory $standard_dir/$html_dir/root/` if !$hashDirectories{"$standard_dir/$html_dir/root/$test"};
                        $hashDirectories{"$standard_dir/$html_dir/root/$test"} = 1;

                    } else { print $LOG "\n[6481]Escapou do ln $test\n"; }
                }
            }
        }
    }
}

#Descompacta assets
print $LOG "Copying files assets\n";
`tar -zxf $filepath_assets`;
`mkdir -p $html_dir/root/` if ( !-e "$html_dir/root/" );
`mv assets $html_dir/root/`;

$color_primary =~ s/"//g;
$color_primary_text =~ s/"//g;
$color_accent =~ s/"//g;
$color_accent_text =~ s/"//g;
$color_menu =~ s/"//g;
$color_background =~ s/"//g;
$color_footer =~ s/"//g;
$color_footer_text =~ s/"//g;
$titlePage =~ s/"//g;

open ($FILEHANDLER, ">>", "$html_dir/root/assets/css/colors-$organism_name.css");
print $FILEHANDLER "\n

:root {
--color_primary: $color_primary;
--color_accent: $color_accent;
--color_primary_text: $color_primary_text;
--color_accent_text: $color_accent_text;
--color_menu: $color_menu;
--color_background: $color_background;
--color_footer: $color_footer;
--color_footer_text: $color_footer_text;
}

";
close($FILEHANDLER);

if ($banner) {
    `cp $banner $html_dir/root/assets/img/logo.png`;
}

my $menu = "<!DOCTYPE html>
<div class='navbar navbar-inverse set-radius-zero'>
<div class='container'>
<div class='navbar-header'>
<button type='button' class='navbar-toggle' data-toggle='collapse' data-target='.navbar-collapse'>
<span class='icon-bar'></span>
<span class='icon-bar'></span>
<span class='icon-bar'></span>
</button>";
;

if($banner)  {
    $menu .= "<a class='navbar-brand' href='[% c.uri_for(\"/\") %]'>
    <img src='/assets/img/logo.png' />
    </a>";
} elsif ($titlePage) {
    $menu .= "<div class='row'>
    <div class='col-md-12'>
    <a class='navbar-brand' href=\"[% c.uri_for('/') %]\">$titlePage</a>                                                                                        
    </div>
    </div>";
}

$menu .=  "</div>
</div>
</div>
<!-- LOGO HEADER END-->
<section class='menu-section'>
<div class='container'>
<div class='row'>
<div class='col-md-12'>
<div class='navbar-collapse collapse '>
<ul id='menu-top' class='nav navbar-nav navbar-right'>
[% FOREACH text IN texts %]
[% IF text.tag.search('menu') %]
[% IF text.value == currentPage %]
<li><a class='menu-top-active' href='[% c.uri_for(text.details) %]'>[% text.value %]</a></li>
[% ELSE %]
[% IF hadSearchDatabase && text.value.match('search database') %]
<li><a  href='[% c.uri_for(\"/SearchDatabase\") %]'>Search database</a></li>
[% ELSIF hadGlobal && text.value.match('global analyses') %]
<li><a	href='[% c.uri_for(\"/GlobalAnalyses\") %]'>Global analyses</a></li>
[% ELSIF !text.value.match('global analyses') && !text.value.match('search database') %]
<li><a href='[% c.uri_for(text.details) %]'>[% text.value %]</a></li>
[% END %]
[% END %]
[% END %]
[% END %]
</ul>
</div>
</div>

</div>
</div>
</section>

";

my $panelInformation = "
<!DOCTYPE html>
<div class='content-wrapper'>
<div class='container'>	
<div class='row'>
<div class='col-md-12'>
<div class='panel panel-info'>
<div class='panel-heading'>
[% FOREACH text IN texts %]
[% IF text.tag.search('home-title') && !text.tag.search('value') %]
[% text.value %]
[% END %]
[% END %]
</div>
<div class='panel-body'>";

unless($homepage_image_organism) {
    $panelInformation .= "
    <div class='row'>
    <div id='informationPanel' class='col-md-12'>
    [% FOREACH text IN texts %]
    [% IF text.tag.search('home-value')%]
    [% text.value %]
    [% END %]
    [% END %]
    </div>
    </div>";
} else {
    `mkdir -p $html_dir/root/assets/img/`;
    `cp $homepage_image_organism $html_dir/root/assets/img/`;
    $homepage_image_organism = getFilenameByFilepath($homepage_image_organism);
    $panelInformation .= "
    <div class='row'>
    <div id='informationPanel' class='col-md-6'>
    [% FOREACH text IN texts %]
    [% IF text.tag.search('home-value')%]
    [% text.value %]
    [% END %]
    [% END %]
    </div> 
    <div class='col-md-6'>
    <img id='organismImage' src='/assets/img/$homepage_image_organism' />

    </div>
    </div>"; 
}
$panelInformation .="</div>
<div class='panel-footer'> 
[% FOREACH text IN texts %]
[% IF text.tag.search('home-sub')%] 
<div class='row'>
<div class='col-md-12'>
<sub>[% text.value %]</sub>
</div>
</div> 
[% END %]
[% END %]  
</div>
</div>
</div>
</div>

</div>
</div> ";


#Conteúdo HTML da pasta root, primeira chave refere-se ao nome do diretório
#O valor do vetor possuí o primeiro valor como nome do arquivo, e os demais como conteúdo do arquivo
my %contentHTML = (
    "about" => {
        "_content.tt" => <<CONTENTABOUT
<!DOCTYPE html>
<div class="row">
    <div class="col-md-12">
        <div class="panel-group" id="accordion">

            [% counter = 1 %]
            [% FOREACH text IN texts %]
                [% IF text.tag == 'about-table-content-'_ counter %]
                    <div class="panel panel-default">
                        <div class="panel-heading">
                            <h4 class="panel-title">
                                <a data-toggle="collapse" data-parent="#accordion" href="#about_[% counter %]" class="collapsed">[% text.value %]</a>
                            </h4>
                        </div>
                        <div id="about_[% counter %]" class="panel-collapse collapse">
                            <div class="panel-body">
                                <div class="notice-board">
                                    [% counterTexts = 0 %]
                                    [% FOREACH content IN texts %]
                                        [% IF content.tag.search("about_" _ counter _"-"_ counterTexts) %]
                                            [% IF content.tag == "about_" _ counter _"-"_ counterTexts _"-title" %]
                                                <h1 id="[% content.details %]" class="page-head-line">[% content.value %]</h1>
                                            [% END %]
                                            [% IF content.tag == "about_" _ counter _"-"_ counterTexts _"-paragraph" %]
                                                <p>[% content.value %]</p>
                                            [% END %]
                                            [% IF content.tag.search("about_" _ counter _"-"_ counterTexts _"-list-") %]
                                                <ul>
                                                    [% FOREACH item IN texts %]
                                                        [% IF item.tag.search("about_" _ counter _"-"_ counterTexts _"-list-") %]
                                                            <li>[% item.value %]</li>
                                                        [% END %]
                                                    [% END %]
                                                </ul>
                                            [% END %]
                                            [% counterTexts = counterTexts + 1 %]
                                        [% END %]
                                    [% END %]
                                </div>
                            </div>
                        </div>
                    </div>
                    [% counter = counter + 1 %]
                 [% END %]
             [% END %]

        </div>
    </div>
</div>
CONTENTABOUT
        ,
        "index.tt" => <<CONTENTABOUTINDEX
<!DOCTYPE html>
<div class="content-wrapper">
    <div class="container">		
        [% INCLUDE '$lowCaseName/about/_content.tt' %]
    </div>
</div>
CONTENTABOUTINDEX
    },
    "blast" => {
        "_forms.tt" => <<CONTENTBLAST
<!DOCTYPE html>
<div class="row">
    <div class="col-md-12">
        <form id="formBlast">
            <div class="panel panel-primary">
                <div class="panel-heading">
                    [% FOREACH text IN texts %]
                        [% IF text.tag.search('blast-form-title') %]
                            [% text.value %]
                        [% END %]
                    [% END %]
                </div>
                <div class="panel-body">
                    <div class="form-group">
                        [% FOREACH text IN texts %]
                            [% IF text.tag.search('blast-program-title') %]
                            <label><a href="[% text.details %]">[% text.value %]</a></label>
                            [% END %]
                        [% END %]
                        <select id="program" class="form-control" name="PROGRAM">
                            [% FOREACH text IN texts %]
                                [% IF text.tag.search('blast-program-option') %]
                                <option> [% text.value %] </option>
                                [% END %]
                            [% END %]
                        </select>
                    </div>
                    <div class="form-group">
                        [% FOREACH text IN texts %]
                            [% IF text.tag.search('blast-database-title') %]
                                <label>[% text.value %]</label>
                            [% END %]
                        [% END %]
                        <select class="form-control" name="DATALIB">
                            [% FOREACH text IN texts %]
                                [% IF text.tag.search('blast-database-option') %]
                                    <option value="[% text.details %]"> [% text.value %]</option>
                                [% END %]
                            [% END %]
                        </select>
                    </div>
                    <div class="form-group">
                        [% FOREACH text IN texts %]
                            [% IF text.tag.search('blast-format-title') %]
                                <label>[% text.value %]</label>
                            [% END %]
                        [% END %]
                        <textarea class="form-control" name="SEQUENCE" id="SEQUENCE" rows="6" cols="60"></textarea>
                    </div>
                    <div class="form-group">
                        [% FOREACH text IN texts %]
                            [% IF text.tag.search('blast-sequence-file-title') %]
                                <label>[% text.value %]</label>
                            [% END %]
                        [% END %]
                        <input id="SEQFILE" type="file">
                    </div>
                    <div class="form-group">
                        [% FOREACH text IN texts %]
                            [% IF text.tag.search('blast-subsequence') %]
                                [% IF text.tag.search('blast-subsequence-title') %]
                                    <label>[% text.value %]</label>
                                [% ELSIF text.tag.search('blast-subsequence-value') %]
                                    <label for="[% text.details %]"> [% text.value %] </label>
                                    <input class="form-control" type="text" id="[% text.details %]" name="[% text.details %]" value="" size="10">
                                [% END %]
                            [% END %]
                        [% END %]
                    </div>

                    <div class="panel-group" id="accordion">
                        <div class="panel panel-info">
                            <div class="panel-heading">
                                <h4 class="panel-title">
                                    [% FOREACH text IN texts %]
                                        [% IF text.tag.search('blast-search-options-title') %]
                                            <a data-toggle="collapse" data-parent="#accordion" href="#collapseOne" class="collapsed">[% text.value %]</a>
                                        [% END %]
                                    [% END %]
                                </h4>
                            </div>
                            <div id="collapseOne" class="panel-collapse collapse">
                                <div class="panel-body">
                                    [% FOREACH text IN texts %]
                                        [% IF text.tag.search('blast-search-options-sequence-title') %]
                                            <label>[% text.value %]</label>
                                        [% END %]
                                    [% END %]
                                    <div class="form-group">
                                        [% FOREACH text IN texts %]
                                            [% IF text.tag.search('blast-search-options-filter-title') %]
                                                <label>[% text.value %]</label>
                                            [% END %]
                                        [% END %]
                                        [% FOREACH text IN texts %]
                                            [% IF text.tag.search('blast-search-options-filter-options') %]
                                                <div class="checkbox">
                                                    <label><input type="checkbox" name="FILTER" [% text.details %]> [% text.value %] </label>
                                                </div>
                                            [% END %]
                                        [% END %]
                                    </div>
                                    <div class="form-group">
                                        [% FOREACH text IN texts %]
                                            [% IF text.tag.search('blast-search-options-expect') %]
                                                <label>[% text.value %]</label>
                                            [% END %]
                                        [% END %]
                                        <input class="form-control" type="number" name="EXPECT" size="3" value="10">
                                    </div>
                                    <div class="form-group">
                                        [% FOREACH text IN texts %]
                                            [% IF text.tag == "blast-search-options-matrix" %]
                                                <label><a href="[% text.details %]">[% text.value %]</a></label>
                                            [% END %]
                                        [% END %]
                                            <select class="form-control" id="matrix" name="MAT_PARAM"> 
                                                [% FOREACH text IN texts %]
                                                    [% IF text.tag.search('blast-search-options-matrix-options') %]
                                                        <option value="[% text.details %]" > [% text.value %]</option>
                                                    [% END %]
                                                [% END %]
                                            </select>
                                    </div>
                                    <div class="form-group">
                                        <div class="checkbox">
                                            [% FOREACH text IN texts %]
                                                [% IF text.tag.search('blast-search-options-alignment') %]
                                                    <label><input type="checkbox" name="UNGAPPED_ALIGNMENT" value="is_set"> [% text.value %]</label>
                                                [% END %]
                                            [% END %]
                                        </div>
                                    </div>
                                    <div class="form-group">
                                        [% FOREACH text IN texts %]
                                            [% IF text.tag == "blast-search-options-query" %]
                                                <label><a href="[% text.details %]">[% text.value %]</a></label>
                                            [% END %]
                                        [% END %]
                                        <select class="form-control" name="GENETIC_CODE">
                                            [% FOREACH text IN texts %]
                                                [% IF text.tag == "blast-search-options-query-options" %]
                                                    <option [% text.details %]>[% text.value %]</option>
                                                [% END %]
                                            [% END %]
                                        </select>
                                    </div>
                                    <div class="form-group">
                                        [% FOREACH text IN texts %]
                                            [% IF text.tag == "blast-search-options-database" %]
                                                <label><a href="[% text.details %]">[% text.value %]</a></label>
                                            [% END %]
                                        [% END %]
                                        <select class="form-control" name="DB_GENETIC_CODE">
                                            [% FOREACH text IN texts %]
                                                [% IF text.tag == "blast-search-options-database-options" %]
                                                    <option [% text.details %]>[% text.value %]</option>
                                                [% END %]
                                            [% END %]
                                        </select>
                                    </div>
                                    <div class="form-group">
                                        <label>Gap Costs </label>
                                        <select class="form-control" id="gapCosts">
                                            <option value="0 0">Linear</option>
                                            <option value="5 2">Existence: 5 Extension: 2</option>
                                            <option value="2 2">Existence: 2 Extension: 2</option>
                                            <option value="1 2">Existence: 1 Extension: 2</option>
                                            <option value="0 2">Existence: 0 Extension: 2</option>
                                            <option value="3 1">Existence: 3 Extension: 1</option>
                                            <option value="2 1">Existence: 2 Extension: 1</option>
                                            <option value="1 1">Existence: 1 Extension: 1</option>
                                        </select>
                                        <input id="COST_OPEN_GAP"  type="hidden" name="COST_OPEN_GAP" />
                                        <input id="COST_EXTEND_GAP"  type="hidden" name="COST_EXTEND_GAP" /> 
                                    </div>
                                    <div class="form-group">
                                        <label>Word size </label>
                                        <select class="form-control" id="wordSize" name="WORD_SIZE">
                                            <option value="16">16</option>
                                            <option value="20">20</option>
                                            <option value="24">24</option>
                                            <option value="28" selected="selected">28</option>
                                            <option value="32">32</option>
                                            <option value="48">48</option>
                                            <option value="64">64</option>
                                            <option value="128">128</option>
                                            <option value="256">256</option>
                                        </select>
                                    </div> 
                                </div>
                            </div>
                        </div>
                        <div class="panel panel-info">
                            <div class="panel-heading">
                                <h4 class="panel-title">
                                    [% FOREACH text IN texts %]
                                        [% IF text.tag == "blast-display-options-title" %]
                                            <a data-toggle="collapse" data-parent="#accordion" href="#collapseTwo" class="collapsed">[% text.value %]</a>
                                        [% END %]
                                    [% END %]
                                </h4>
                            </div>
                            <div id="collapseTwo" class="panel-collapse collapse">
                                <div class="panel-body">
                                    <div class="form-group">
                                        [% FOREACH text IN texts %]
                                            [% IF text.tag == "blast-display-options-alignment-view-title" %]
                                                <label><a href="[% text.details %]">[% text.value %]</a></label>
                                            [% END %]
                                        [% END %]
                                        <select class="form-control" name="ALIGNMENT_VIEW">
                                            [% FOREACH text IN texts %]
                                                [% IF text.tag == "blast-display-options-alignment-view-options" %]
                                                    <option value="[% text.details %]" >[% text.value %]</option>
                                                [% END %]
                                            [% END %]
                                        </select>
                                    </div>
                                    <div class="form-group">
                                        [% FOREACH text IN texts %]
                                            [% IF text.tag == "blast-display-options-descriptions" %]
                                                <label><a href="[% text.details %]">[% text.value %]</a></label>
                                            [% END %]
                                        [% END %]
                                        <select class="form-control" name="DESCRIPTIONS">
                                            [% FOREACH text IN texts %]
                                                [% IF text.tag == "blast-display-options-descriptions-options" %]
                                                    <option [% text.details %]>[% text.value %]</option>
                                                [% END %]
                                            [% END %]
                                        </select>
                                    </div>
                                    <div class="form-group">
                                        [% FOREACH text IN texts %]
                                            [% IF text.tag == "blast-display-options-alignments" %]
                                                <label><a href="[% text.details %]">[% text.value %]</a></label>
                                            [% END %]
                                        [% END %]
                                        <select class="form-control" name="ALIGNMENTS">
                                            [% FOREACH text IN texts %]
                                                [% IF text.tag == "blast-display-options-alignments-options" %]
                                                    <option [% text.details %]>[% text.value %]</option>
                                                [% END %]
                                            [% END %]
                                        </select>
                                    </div>
                                </div>
                            </div>
                        </div>

                    </div>

                    [% FOREACH text IN texts %]
                        [% IF text.tag == "blast-button" %]
                            <input value="[% text.value %]" [% text.details %]>
                        [% END %]
                    [% END %]
                </div>
            </div>
        </form>
    </div>
</div>

CONTENTBLAST
        ,
        "index.tt" => <<CONTENTINDEXBLAST
<!DOCTYPE html>
<div class="content-wrapper">
    <div id="containerBlast" class="container">	
        <div class="row">
            <div class="col-md-12">
                <input type="button" id="back" value="Back" class="btn btn-danger btn-lg" />
            </div>
        </div>
        [% INCLUDE '$lowCaseName/blast/_forms.tt' %]
    </div>
</div>
<script type="text/javascript" src="/assets/js/fileHandler.js"></script>
<script type="text/javascript" src="/assets/js/site-client.js"></script>
<script type="text/javascript" src="/assets/js/blast.js"></script>
CONTENTINDEXBLAST
    },
    "downloads" => {
        "_content.tt" => <<CONTENTDOWNLOADS
<!DOCTYPE html>
<div class="row">
    <div class="col-md-12">
        <div class="panel-group" id="accordion">

            <div class="panel panel-default">
                <div class="panel-heading">
                    <h4 class="panel-title">
                        [% FOREACH text IN texts %]
                            [% IF text.tag == 'downloads-genes' %]
                                <a data-toggle="collapse" data-parent="#accordion" href="#collapseOne" class="collapsed">[% text.value %]</a>
                            [% END %]
                        [% END %]
                    </h4>
                </div>
                <div id="collapseOne" class="panel-collapse collapse">
                    <div class="panel-body">
                        <div class="notice-board">
                            <ul>
                                [% FOREACH text IN texts %]
                                    [% IF text.tag.search('downloads-genes-links-') %]
                    <li><a href="[% c.uri_for(text.details).replace('%3F', '?') %]">[% text.value %]</a></li>
                                    [% END %]
                                [% END %]
                            </ul>
                        </div>
                    </div>
                </div>
            </div>

            <div class="panel panel-default">
                <div class="panel-heading">
                    <h4 class="panel-title">
                        [% FOREACH text IN texts %]
                            [% IF text.tag == 'downloads-other-sequences' %]
                                <a data-toggle="collapse" data-parent="#accordion" href="#collapseTwo" class="collapsed">[% text.value %]</a>
                            [% END %]
                        [% END %]
                    </h4>
                </div>
                <div id="collapseTwo" class="panel-collapse collapse">
                    <div class="panel-body">
                        <div class="notice-board">
                            <ul>
                                [% FOREACH text IN texts %]
                                    [% IF text.tag.search('downloads-other-sequences-links-') %]
                                        <li><a href="[% c.uri_for(text.details).replace('%3F', '?') %]">[% text.value %]</a></li>
                                    [% END %]
                                [% END %]
                            </ul>
                        </div>
                    </div>
                </div>
            </div>

            <div class="panel panel-default">
                <div class="panel-heading">
                    <h4 class="panel-title">
                        [% FOREACH text IN texts %]
                            [% IF text.tag == 'downloads-annotations' %]
                                <a data-toggle="collapse" data-parent="#accordion" href="#collapseThree" class="collapsed">[% text.value %]</a>
                            [% END %]
                        [% END %]
                    </h4>
                </div>
                <div id="collapseThree" class="panel-collapse collapse">
                    <div class="panel-body">
                        <div class="notice-board">
                            <ul>
                                [% FOREACH text IN texts %]
                                    [% IF text.tag.search('downloads-annotations-') %]
                    <li><a href="[% c.uri_for(text.details).replace('%3F', '?') %]">[% text.value %]</a></li>
                                    [% END %]
                                [% END %]
                            </ul>
                        </div>
                    </div>
                </div>
            </div> 

        </div>
    </div>
</div>

CONTENTDOWNLOADS
        ,
        "index.tt" => <<CONTENTINDEXDOWNLOADS
<!DOCTYPE html>
<div class="content-wrapper">
    <div class="container">		
        [% INCLUDE '$lowCaseName/downloads/_content.tt' %]
    </div>
</div>
CONTENTINDEXDOWNLOADS
    },
    "global-analyses" => {
        "_content.tt" => <<CONTENTGLOBALANALYSES
<!DOCTYPE html>
<div class="row">
    <div class="col-md-12">
        <div class="panel-group" id="accordion">
            [% counter = 1 %]
            [% FOREACH text IN texts %]
            [% IF text.tag.search("global-analyses-panel-" _ counter) %]
             <div class="panel panel-default">
                <div class="panel-heading">
                    <h4 class="panel-title">
                        [% FOREACH content IN texts %]
                        [% IF content.tag == "global-analyses-panel-" _ counter _ "-title" %]
                        <a data-toggle="collapse" data-parent="#accordion" href="#collapse[% counter %]" class="collapsed">[% content.value %]</a>
                        [% END %]
                        [% END %]
                    </h4>
                </div>
                <div id="collapse[% counter %]" class="panel-collapse collapse">
                    <div class="panel-body">
                        [% counterTexts = 1 %]

                        [% FOREACH content IN texts %]
                            [% IF content.tag.search("global-analyses-panel-" _ counter _ "-" _ counterTexts _ "-link") %]
                            <div class="form-group"> 
                                <label><a href="[% c.uri_for(content.value) %]">
                                [% FOREACH content2 IN texts %]
                                [% IF content2.tag == "global-analyses-panel-" _ counter _ "-" _ counterTexts _ "-paragraph" %]
                                [% content2.value %] 
                                [% END %]
                                [% END %]
                                </a></label> 
                            </div> 
                            [% counterTexts = counterTexts + 1 %]
                            [% END %]
                        [% END %]

                    </div>
                </div>
            </div>
            [% counter = counter + 1 %]
            [% END %]
            [% END %]

        </div>
    </div>
</div>

CONTENTGLOBALANALYSES
        ,
        "index.tt" => <<CONTENTGLOBALANALYSESINDEX
<!DOCTYPE html>
<div class="content-wrapper">
    <div class="container">
        [% INCLUDE '$lowCaseName/global-analyses/_content.tt' %]
    </div>
</div>
<script type="text/javascript" src="/assets/js/site-client.js"></script>
<script type="text/javascript" src="/assets/js/search-database.js"></script>
CONTENTGLOBALANALYSESINDEX
    },
    "help" => {
        "_content.tt",
        <<CONTENTHELP
<!DOCTYPE html>
<div class="row">
    <div class="col-md-12">
        <div class="panel-group" id="accordion">

            <div class="panel panel-default">
                <div class="panel-heading">
                    <h4 class="panel-title">
                        [% FOREACH text IN texts %]
                            [% IF text.tag == 'help-questions-feedback' %]
                                <a data-toggle="collapse" data-parent="#accordion" href="#collapseOne" class="collapsed">[% text.value %]</a>
                            [% END %]
                        [% END %]
                    </h4>
                </div>
                <div id="collapseOne" class="panel-collapse collapse">
                    <div class="panel-body">
                        <div class="notice-board">
                            [% FOREACH text IN texts %]
                                [% IF text.tag.search('help-questions-feedback-')  %]
                                    [% IF text.tag.search('paragraphe')  %]
                                        <p>[% text.value %]</p>
                                    [% END %]
                                [% END %]
                            [% END %]

                            <ul>
                                [% FOREACH text IN texts %]
                                    [% IF text.tag.search('help-questions-feedback-')  %]
                                        [% IF text.tag.search('list')  %]
                                            <li>[% text.value %]</li>
                                        [% END %]
                                    [% END %]
                                [% END %]
                            </ul>
                        </div>
                    </div>
                </div>
            </div>

            <div class="panel panel-default">
                <div class="panel-heading">
                    <h4 class="panel-title">
                        [% FOREACH text IN texts %]
                            [% IF text.tag == 'help-table-contents' %]
                                <a data-toggle="collapse" data-parent="#accordion" href="#collapseTwo" class="collapsed">[% text.value %]</a>
                            [% END %]
                        [% END %]
                    </h4>
                </div>
                <div id="collapseTwo" class="panel-collapse collapse">
                    <div class="panel-body">
                        <div class="notice-board">
                            <ul>
                                [% FOREACH text IN texts %]
                                    [% IF text.tag.search('help-table-contents-')  %]
                                        <li><a data-toggle="collapse" data-parent="#accordion" class="collapsed" href="#[% text.details %]">[% text.value %]</a></li>
                                    [% END %]
                                [% END %]
                            </ul>
                        </div>
                    </div>
                </div>
            </div>
            [% counter = 1 %]
            [% FOREACH text IN texts %]
                [% IF text.tag == 'help-table-contents-'_ counter %]
                    <div class="panel panel-default">
                        <div class="panel-heading">
                            <h4 class="panel-title">
                                [% id = text.details %]
                                <a data-toggle="collapse" data-parent="#accordion" href="#[% id %]" class="collapsed">[% text.value %]</a>
                            </h4>
                        </div>
                        <div id="[% id %]" class="panel-collapse collapse">
                            <div class="panel-body">
                                <div class="notice-board">
                                    [% counterTexts = 0 %]
                                    [% FOREACH content IN texts %]
                                        [% IF content.tag.search(id _"-"_ counterTexts) %]
                                            [% IF content.tag == id _"-"_ counterTexts _"-title" %]
                                                <h1 id="[% content.details %]" class="page-head-line">[% content.value %]</h1>
                                            [% END %]
                                            [% IF content.tag == id _"-"_ counterTexts _"-paragraph" %]
                                                <p>[% content.value %]</p>
                                            [% END %]
                                            [% IF content.tag.search(id _"-"_ counterTexts _"-list-") %]
                                                <ul>
                                                    [% FOREACH item IN texts %]
                                                        [% IF item.tag.search(id _"-"_ counterTexts _"-list-") %]
                                                            <li>[% item.value %]</li>
                                                        [% END %]
                                                    [% END %]
                                                </ul>
                                            [% END %]
                                            [% counterTexts = counterTexts + 1 %]
                                        [% END %]
                                    [% END %]
                                </div>
                            </div>
                        </div>
                    </div>
                    [% counter = counter + 1 %]
                 [% END %]
             [% END %]

        </div>
    </div>
</div>
CONTENTHELP
        , "index.tt" => <<CONTENTINDEXHELP
<!DOCTYPE html>
<div class="content-wrapper">
    <div class="container">		
        [% INCLUDE '$lowCaseName/help/_content.tt' %]
    </div>
</div>
<script>
\$(".collapsed").click(function() {
    var regex = /\\./g;
    if (regex.exec(\$(this).attr('href')).length > 0) {
        regex = /(#\\w+\\d)+[\\.\\d]+/g;
        var idPanel = regex.exec(\$(this).attr('href'))[1];
        \$("#collapseTwo").collapse("toggle");
        \$(idPanel).collapse("show");
        var id = \$(this).attr('href');
        setTimeout(function() { window.location.hash = id; }, 300);
    }
});
</script>
CONTENTINDEXHELP
    },
    "home" => {
        "_panelInformation.tt" => $panelInformation,
        "index.tt" => <<CONTENTINDEXHOME
<!DOCTYPE html>
<div class="content-wrapper">
    <div class="container">
        [% INCLUDE '$lowCaseName/home/_panelInformation.tt' %]
    </div>
</div>
CONTENTINDEXHOME
    },
    "search-database" => {
        "_forms.tt" => <<CONTENTSEARCHDATABASE
<!DOCTYPE html>
<div class="row">
    <div class="col-md-12">
        <div class="panel panel-default" id="searchPanel">
            <div class="panel-heading">
        [% searchDBTexts.item('search-database-form-title')  %]
            </div>
            <div class="panel-body">
                <div class="panel-group" id="accordion">
                    [% 
                        section_protein_coding = 0 
                        section_dna_based = 0
                        blast = 0
                        interpro = 0 
                        tcdb = 0
                        phobius = 0
                        rpsblast = 0
                        pathways = 0
                        orthology = 0
                        trna = 0
                        trf = 0
                        mreps = 0
                        string = 0
                        infernal = 0
                        rbs = 0
                        transterm = 0
                        alienhunter = 0
                        rnammer = 0
                        tmhmm = 0
                        dgpi = 0
                        bigpi = 0
                        predgpi = 0
                        signalP = 0
                    %]

                    [% IF components.item('annotation_glimmer3') OR  
                        components.item('annotation_glimmerm') OR 
                        components.item('annotation_augustus') OR 
                        components.item('annotation_myop') OR 
                        components.item('annotation_glimmerhmm') OR 
                        components.item('annotation_phat') OR 
                        components.item('annotation_snap') OR 
                        components.item('annotation_orf') OR
                        components.item('upload_gtf') OR
                        components.item('upload_prediction') %]
                        [% section_protein_coding = 1 %]
                    [% END %]
                    [% IF components.item('annotation_trna') OR 
                        components.item('annotation_mreps') OR 
                        components.item('annotation_string') OR 
                        components.item('annotation_infernal') OR 
                        components.item('annotation_rbs') OR 
                        components.item('annotation_transterm') OR 
                        components.item('annotation_alienhunter') OR
                        components.item('annotation_rnammer') %]
                        [% section_dna_based = 1 %]
                    [% END %]
                    [% IF components.item('annotation_blast') %]
                        [% blast = 1 %]
                    [% END %]
                    [% IF components.item('annotation_interpro') %]
                        [% interpro = 1 %]
                    [% END %]
                        [% IF components.item('annotation_tcdb') %]
                            [% tcdb = 1 %]
                        [% END %]
                        [% IF components.item('annotation_phobius') %]
                            [% phobius = 1 %]
                        [% END %]
                        [% IF components.item('annotation_signalP') %]
                            [% signalP = 1 %]
                        [% END %]
                        [% IF components.item('annotation_rpsblast') %]
                            [% rpsblast = 1 %]
                        [% END %]
                        [% IF components.item('annotation_pathways') %]
                            [% pathways = 1 %]
                        [% END %]
                        [% IF components.item('annotation_orthology') %]
                            [% orthology = 1 %]
                        [% END %]
                        [% IF components.item('annotation_trna') %]
                            [% trna = 1 %]
                        [% END %]
                        [% IF components.item('annotation_trf') %]
                            [% trf = 1 %]
                        [% END %]
                        [% IF components.item('annotation_mreps') %]
                            [% mreps = 1 %]
                        [% END %]
                        [% IF components.item('annotation_string') %]
                            [% string = 1 %]
                        [% END %]
                        [% IF components.item('annotation_infernal') %]
                            [% infernal = 1 %]
                        [% END %]
                        [% IF components.item('annotation_rbsfinder') %]
                            [% rbs = 1 %]
                        [% END %]
                        [% IF components.item('annotation_transterm') %]
                            [% transterm = 1 %]
                        [% END %]
                        [% IF components.item('annotation_alienhunter') %]
                            [% alienhunter = 1 %]
                        [% END %]
                        [% IF components.item('annotation_rnammer') %]
                            [% rnammer = 1 %]
                        [% END %]
                        [% IF components.item('annotation_tmhmm') %]
                            [% tmhmm = 1 %]
                        [% END %]
                        [% IF components.item('annotation_dgpi') %]
                            [% dgpi = 1 %]
                        [% END %]
                        [% IF components.item('annotation_predgpi') %]
                            [% predgpi = 1 %]
                        [% END %]
                        [% IF components.item('annotation_bigpi') %]
                            [% bigpi = 1 %]
                        [% END %]
                        [% IF report_pathways %]
                            <input type="hidden" id="report_pathways" value="[% report_pathways %]" />
                        [% END %]

                    [% IF section_protein_coding %]
                     <div id="parentCollapseOne" class="panel panel-default">
                         <div class="panel-heading">
                             <h4 class="panel-title">
                <a data-toggle="collapse" data-parent="#accordion" href="#collapseOne" class="collapsed"> [% searchDBTexts.item('search-database-gene-ids-descriptions-title') %] </a>
                             </h4>
                         </div>
                         <div id="collapseOne" class="panel-collapse collapse">
                             <div class="panel-body">
                                 <div class="tab-content">
                                     <div id="geneIdentifier" class="tab-pane fade active in">
                                         <h4></h4>
                                         <form id="formGeneIdentifier">
                                            <div class="form-group">
                                                <label>Contig: </label>
                                                <select name="contig">
                                                    <option value="">Select</option>
                                                    [% FOREACH sequence IN sequences %]
                                                        <option value="[% sequence.id %]">[% sequence.name %]</option>
                                                    [% END %]
                                                </select>
                                            </div>
                                             <div class="form-group">
                        [% searchDBTexts.item('search-database-gene-ids-descriptions-gene-id') %]
                                                 <input class="form-control" type="text" name="geneID">
                                             </div>
                                             <input class="btn btn-primary btn-sm" type="submit" value="Search">  
                                             <input class="btn btn-default btn-sm" type="button" name="clear" value="Clear Form" onclick="this.form.reset(); \$('.errors').remove();">
                                         </form>
                                     </div>
                                 </div>
                             </div>
                         </div>
                     </div>

                     <div id="parentCollapseTwo" class="panel panel-default">
                         <div class="panel-heading">
                             <h4 class="panel-title">
                <a data-toggle="collapse" data-parent="#accordion" href="#collapseTwo" class="collapsed"> [% searchDBTexts.item('search-database-analyses-protein-code-title') %] </a>
                             </h4>
                         </div>
                         <div id="collapseTwo" class="panel-collapse collapse">
                             <div class="panel-body">
                                 <form id="formAnalysesProteinCodingGenes">
                                    <div class="form-group">
                                        <label>Contig: </label>
                                        <select name="contig">
                                            <option value="">All</option>
                                                [% FOREACH sequence IN sequences %]
                                                    <option value="[% sequence.id %]">[% sequence.name %]</option>
                                                [% END %]
                                            </select>
                                    </div>
                                    [% IF blast %]
                                      <div class="form-group">
                    <label>[% searchDBTexts.item('search-database-analyses-protein-code-limit') %]</label>
                                          <input class="form-control" type="text" name="geneDesc">
                                      </div>
                                      <div class="form-group">
                    <label>[% searchDBTexts.item('search-database-analyses-protein-code-excluding') %]</label>
                                          <input class="form-control" type="text" name="noDesc">
                                      </div>
                                      <div class="form-group">
                                          <div class="checkbox">
                                              <label><input type="checkbox" name="individually" > [% searchDBTexts.item('search-database-analyses-protein-code-match-all') %]</label> 
                                          </div>
                                      </div>
                                      <div class="form-group">
                                          
                                          <select id="components" name="components" multiple="multiple">
                                            [% FOREACH text IN searchDBTexts.item('search-database-analyses-protein-code-tab') %]
                                            <option> [% text %]</option>
                                            [% END %]
                                        [% IF blast %]
                                            <option> BLAST</option>
                                        [% END %]
                                          </select>
                                          <script>
                                                var options = \$('#components option');
                                                var arr = options.map(function(_, o) { return { t: \$(o).text(), v: o.value }; }).get();
                                                arr.sort(function(o1, o2) { 
                                                    var t1 = o1.t.toLowerCase(), t2 = o2.t.toLowerCase();

                                                    return t1 > t2 ? 1 : t1 < t2 ? -1 : 0;
                                                });
                                                options.each(function(i, o) {
                                                    o.value = arr[i].v;
                                                    \$(o).text(arr[i].t);
                                                });
                                                \$("\#components").multipleSelect({
                                                    placeholder: "Require positive results for: ",
                                                    width: 300,
                                                });
                                          </script>
                                      </div>
                                  [% END %]

                                     <ul class="nav nav-pills">
                    [% FOREACH text IN searchDBTexts.item('search-database-analyses-protein-code-tab') %]
                                            <li class="">[% text %]</li>
                    [% END %]
                                        [% IF blast %]
                                            <li class=""><a href="#blast" data-toggle='tab'>BLAST</a></li>
                                        [% END %]
                                     </ul>
                                     <h4></h4>
                                     <div class="tab-content">
                                        [% IF tmhmm %]
                                            <div id="tmhmm" class="tab-pane fade">
                                                <div class="form-group">
                                                    <label>[% searchDBTexts.item('search-database-analyses-protein-code-number-transmembrane-domains') %]</label>
                                                    <input class="form-control" type="number" min="1" name="TMHMMdom">
                            [% FOREACH text IN searchDBTexts.item('search-database-quantity-tmhmmQuant') %]
                            <div class="radio">
                                <label>[% text %]</label>
                            </div>
                            [% END %]
                                                </div>

                                            </div>
                                        [% END %]
                                        [% IF dgpi %]
                                            <div id="dgpi" class="tab-pane fade">
                                                <div class="form-group">
                                                        <label>[% searchDBTexts.item('search-database-analyses-protein-code-cleavage-site-dgpi') %]</label>
                                                    <input class="form-control" type="number" name="cleavageSiteDGPI">
                            [% FOREACH text IN searchDBTexts.item('search-database-quantity-cleavageQuant') %]
                                                        <div class="radio">
                                                                <label>[% text %]</label>
                                                        </div>
                                                        [% END %]
                                                </div>
                                                <div class="form-group">
                            <input class="form-control" type="number" name="scoreDGPI">
                            [% FOREACH text IN searchDBTexts.item('search-database-quantity-scoreQuant') %]
                                                        <div class="radio">
                                                                <label>[% text %]</label>
                                                        </div>
                                                        [% END %]
                                            </div>
                        </div>
                                        [% END %]
                                        [% IF predgpi %]
                                            <div id="predgpi" class="tab-pane fade">
                                                <div class="form-group">
                                                        <div class="checkbox">
                                    <label><input type="checkbox" name="noPreDGPI">[% searchDBTexts.item('search-database-analyses-protein-code-not-containing-predgpi') %]</label>
                                                        </div>
                                                    </div>
                                                    <div class="form-group">
                                                    <label>[% searchDBTexts.item('search-database-analyses-protein-code-name-predgpi') %]</label>
                                                <input class="form-control" type="text" name="namePreDGPI">
                                            </div>
                                                <div class="form-group">
                                <label>[% searchDBTexts.item('search-database-analyses-protein-code-position-predgpi') %]</label>
                                                        <input class="form-control" type="number" name="positionPreDGPI">
                                [% FOREACH text IN searchDBTexts.item('search-database-quantity-positionQuantPreDGPI') %]
                                                            <div class="radio">
                                                                    <label>[% text %]</label>
                                                            </div>
                                                            [% END %]
                                                    </div>
                                                    <div class="form-group">
                                <label>[% searchDBTexts.item('search-database-analyses-protein-code-specificity-predgpi') %]</label>
                                                        <input class="form-control" step="any" min="0.00000000000000000000000000001" type="number" name="specificityPreDGPI">
                                [% FOREACH text IN searchDBTexts.item('search-database-quantity-specificityQuantPreDGPI') %]
                                                                <div class="radio">
                                                                        <label>[% text %]</label>
                                                                </div>
                                                                [% END %]
                                                    </div>
                                                    <div class="form-group">
                                <label>[% searchDBTexts.item('search-database-analyses-protein-code-sequence-predgpi') %]</label>
                                                    <input class="form-control" type="text" name="sequencePreDGPI">
                                                </div>
                                            </div>
                                        [% END %]
                                        [% IF bigpi %]
                                            <div id="bigpi" class="tab-pane fade">
                                                    <div class="form-group">
                                <label>[% searchDBTexts.item('search-database-analyses-protein-code-value-bigpi') %]</label>
                                                        <input class="form-control" step="any" min="0.00000000000000000000000000001" type="number" name="pvalueBigpi">
                                                        [% FOREACH text IN searchDBTexts.item('search-database-quantity-pvalueQuantBigpi') %]
                                    <div class="radio">
                                        <label>[% text %]</label>
                                    </div>
                                [% END %]
                                                    </div>
                                                    <div class="form-group">
                                <label>[% searchDBTexts.item('search-database-analyses-protein-code-position-bigpi') %]</label>
                                                        <input class="form-control" type="number" name="positionBigpi">
                                                        [% FOREACH text IN searchDBTexts.item('search-database-quantity-positionQuantBigpi') %]
                                    <div class="radio">
                                        <label>[% text %]</label>
                                    </div>
                                [% END %]
                                                    </div>
                                                </div>
                                                 <div class="form-group">
                                                    <label>[% searchDBTexts.item('search-database-analyses-protein-code-score-bigpi') %]</label>
                                                    <input class="form-control" step="any" min="0.00000000000000000000000000001"  type="number" name="scoreBigpi">
                                                    [% FOREACH text IN searchDBTexts.item('search-database-quantity-scoreQuantBigpi') %]
                                                    <div class="radio">
                                                        <label>[% text %]</label>
                                                    </div>
                                                    [% END %]
                                                </div>
                                            </div>
                                        [% END %]
                                        [% IF interpro %]
                                            <div id="geneOntology" class="tab-pane fade">
                                                    <div class="form-group">
                                <div class="checkbox">
                                    <label><input type="checkbox" name="noGO">[% searchDBTexts.item('search-database-analyses-protein-code-not-containing-classification') %]</label>
                                </div>
                            </div>
                                                <div class="form-group">
                                <label>[% searchDBTexts.item('search-database-analyses-protein-code-search-by-sequence') %]</label>
                                                        <input class="form-control" type="text" name="goID">
                                                    </div>
                                                    <div class="form-group">
                                <label>[% searchDBTexts.item('search-database-analyses-protein-code-search-by-description') %]</label>
                                                        <input class="form-control" type="text" name="goDesc">
                                                    </div>
                                            </div>
                                      [% END %]
                                      [% IF tcdb %]
                                            <div id="transporterClassification" class="tab-pane fade">
                                                    <div class="form-group">
                                                        <div class="checkbox">
                                    <label><input type="checkbox" name="noTC">[% searchDBTexts.item('search-database-analyses-protein-code-not-containing-classification-tcdb') %]</label>
                                                        </div>
                                                    </div>
                                                    <div class="form-group">
                                <label>[% searchDBTexts.item('search-database-analyses-protein-code-search-by-transporter-identifier') %]</label>
                                                        <input class="form-control" type="text" name="tcdbID">
                                                    </div>
                                                    <div class="form-group">
                                <label>[% searchDBTexts.item('search-database-analyses-protein-code-search-by-transporter-family') %]</label>
                                                        <input class="form-control" type="text" name="tcdbFam">
                                                    </div>
                                                    <div class="form-group">
                                 <label>[% searchDBTexts.item('search-database-analyses-protein-code-search-by-transporter-subclass') %]</label>
                                                        <select class="form-control" name="tcdbSubclass">
                                                                <option value="">All</option>
                                                                [% FOREACH text IN searchDBTexts.item('search-database-analyses-protein-code-search-by-transporter-subclass-option') %]
                                                                    <option value='[% text %]'>[% text %]</option>
                                                                [% END %]
                                                        </select>
                                                    </div>
                                                    <div class="form-group">
                                <label>[% searchDBTexts.item('search-database-analyses-protein-code-search-by-transporter-class') %]</label>
                                                        <select class="form-control" name="tcdbClass">
                                                                <option value="">All</option>
                                                                [% FOREACH text IN searchDBTexts.item('search-database-analyses-protein-code-search-by-transporter-class-option') %]
                                                                    <option value="[% text %]">[% text %]</option>
                                                                [% END %]
                                                        </select>
                                                    </div>
                                                    <div class="form-group">
                                <label>[% searchDBTexts.item('search-database-analyses-protein-code-search-by-description') %]</label>
                                                        <input class="form-control" type="text" name="tcdbDesc">
                                                    </div>
                                            </div>
                                         [% END %]
                                         [% IF phobius %]
                                            <div id="phobius" class="tab-pane fade">
                                                    <div class="form-group">
                                <label>[% searchDBTexts.item('search-database-analyses-protein-code-number-transmembrane-domain') %]</label>
                                                        <input class="form-control" type="number" min="1" name="TMdom">
                                                        [% FOREACH text IN searchDBTexts.item('search-database-quantity-tmQuant') %]
                                                            <div class="radio">
                                                                    <label>[% text %] </label>
                                                            </div>
                                                        [% END %]
                                                    </div>
                                                    <div class="form-group">
                                <label>[% searchDBTexts.item('search-database-analyses-protein-code-signal-peptide') %]</label>
                                                        [% FOREACH text IN searchDBTexts.item('search-database-analyses-protein-code-signal-peptide-option') %]
                                                            <div class="radio">
                                                                    <label>[% text %]</label>
                                                            </div>
                                                        [% END %]
                                                    </div>
                                            </div>
                                        [% END %]
                                        [% IF signalP %]
                                            <div id="signalP" class="tab-pane fade">
                                                    <div class="form-group">
                                <label>[% searchDBTexts.item('search-database-analyses-protein-code-signal-peptide') %]</label>
                                                        [% FOREACH text IN searchDBTexts.item('search-database-analyses-protein-code-signal-peptide-option-signalP') %]
                                                            <div class="radio">
                                                                    <label>[% text %]</label>
                                                            </div>
                                                        [% END %]
                                                    </div>
                                            </div> 
                                        [% END %]
                                        [% IF blast %]
                                            <div id="blast" class="tab-pane fade">
                                                    <div class="form-group">
                                                        <div class="checkbox">
                                    <label><input type="checkbox" name="noBlast">[% searchDBTexts.item('search-database-analyses-protein-code-not-containing-classification-blast') %]</label>
                                                        </div>
                                                    </div>
                                                    <div class="form-group">
                                <label>[% searchDBTexts.item('search-database-analyses-protein-code-search-by-sequence') %]</label>
                                                        <input class="form-control" type="text" name="blastID">
                                                    </div>
                                            </div>
                                      [% END %]
                                      [% IF rpsblast %]
                                            <div id="rpsblast" class="tab-pane fade">
                                                    <div class="form-group">
                                                        <div class="checkbox">
                                    <label><input type="checkbox" name="noRps">[% searchDBTexts.item('search-database-analyses-protein-code-not-containing-classification-rpsblast') %]</label>
                                                        </div>
                                                    </div>
                                                    <div class="form-group">
                                <label>[% searchDBTexts.item('search-database-analyses-protein-code-search-by-sequence') %]</label>
                                                        <input class="form-control" type="text" name="rpsID">
                                                    </div>
                                                    <div class="form-group">
                                <label>[% searchDBTexts.item('search-database-analyses-protein-code-search-by-description') %]</label>
                                                        <input class="form-control" type="text" name="rpsDesc">
                                                    </div>
                                            </div>
                                      [% END %]
                                      [% IF pathways %]
                                            <div id="kegg" class="tab-pane fade">
                                                    <div class="form-group">
                                                        <div class="checkbox">
                                    <label><input type="checkbox" name="noKEGG">[% searchDBTexts.item('search-database-analyses-protein-code-not-containing-classification-kegg') %]</label>
                                                        </div>
                                                    </div>
                                                    <div class="form-group">
                                <label>[% searchDBTexts.item('search-database-analyses-protein-code-by-orthology-identifier-kegg') %]</label>
                                                        <input class="form-control" type="text" name="koID">
                                                    </div>
                                                    <div class="form-group">
                                <label>[% searchDBTexts.item('search-database-analyses-protein-code-by-kegg-pathway') %]</label>
                                                        <select class="form-control" name="keggPath">
                                                                <option value="">All</option>
                                                                [% FOREACH text IN searchDBTexts.item('search-database-analyses-protein-code-by-kegg-pathway-options') %]
                                                                        [% text %]
                                                                [% END %]
                                                        </select>
                                                    </div>
                                                    <div class="form-group">
                                <label>[% searchDBTexts.item('search-database-analyses-protein-code-search-by-description') %]</label>
                                                        <input class="form-control" type="text" name="keggDesc">
                                                    </div>
                                            </div>
                                      [% END %]
                                      [% IF orthology %]
                                            <div id="orthologyAnalysis" class="tab-pane fade">
                                                    <div class="form-group">
                                                        <div class="checkbox">
                                    <label><input type="checkbox" name="noOrth">[% searchDBTexts.item('search-database-analyses-protein-code-not-containing-classification-eggNOG') %]</label>
                                                        </div>
                                                    </div>
                                                    <div class="form-group">
                                <label>[% searchDBTexts.item('search-database-analyses-protein-code-eggNOG') %]</label>
                                                        <input class="form-control" type="text" name="orthID">
                                                    </div>
                                                    <div class="form-group">
                                <label>[% searchDBTexts.item('search-database-analyses-protein-code-search-by-description') %]</label>
                                                        <input class="form-control" type="text" name="orthDesc">
                                                    </div>
                                            </div>
                                      [% END %]
                                      [% IF interpro %]
                                            <div id="interpro" class="tab-pane fade">
                                                    <div class="form-group">
                                                        <div class="checkbox">
                                    <label><input type="checkbox" name="noIP">[% searchDBTexts.item('search-database-analyses-protein-code-not-containing-classification-interpro') %]</label>
                                                        </div>
                                                    </div>
                                                    <div class="form-group">
                                <label>[% searchDBTexts.item('search-database-analyses-protein-code-interpro') %]</label>
                                                        <input class="form-control" type="text" name="interproID">
                                                    </div>
                                                    <div class="form-group">
                                <label>[% searchDBTexts.item('search-database-analyses-protein-code-search-by-description') %]</label>
                                                        <input class="form-control" type="text" name="interproDesc">
                                                    </div>
                                            </div>
                                      [% END %]
                                     </div>
                                     <input class="btn btn-primary btn-sm" type="submit" name="geneIDbutton" value="Search"> 
                                     <input class="btn btn-default btn-sm" type="button" name="clear" value="Clear Form" onclick="this.form.reset(); \$('.errors').remove();\$('\#components').multipleSelect('uncheckAll');\$('input[name=TMHMMdom]').prop('disabled', false);\$('input[name=TMdom]').prop('disabled', false);  ">
                                 </form>
                             </div>
                         </div>
                     </div>
                    [% END %]
                    [% IF section_dna_based %]
                     <div id="parentCollapseThree" class="panel panel-default">
                        <div class="panel-heading">
                            <h4 class="panel-title">
                    <a data-toggle="collapse" data-parent="#accordion" href="#collapseThree" class="collapsed"> [% searchDBTexts.item('search-database-dna-based-analyses-title') %] </a>
                                </h4>
                        </div>
                        <div id="collapseThree" class="panel-collapse collapse">
                            <div class="panel-body">
                    <ul class="nav nav-pills">
                        [% FOREACH text IN searchDBTexts.item('search-database-dna-based-analyses-tab') %]
                        <li class="">[% text %]</li>
                        [% END %]
                    </ul>
                    <h4></h4>
                    <div class="tab-content">
                        <div id="contigs" class="tab-pane fade">
                            <form id="formSearchContig">
                                <div class="form-group">
                                    <label>[% searchDBTexts.item('search-database-dna-based-analyses-only-contig-title') %]</label>
                                    <select class="form-control"  name="contig" required="required">
                                        <option value="">All</option>
                                        [% FOREACH sequence IN sequences %]
                                        <option value="[% sequence.id %]">[% sequence.name %]</option>
                                        [% END %]
                                    </select>
                                </div>
                                <div class="form-group">
                                    <label>[% searchDBTexts.item('search-database-dna-based-analyses-from-base') %]</label>
                                    <input class="form-control" type="number" min="1" name="contigStart">
                                </div>
                                <div class="form-group">
                                    <label>[% searchDBTexts.item('search-database-dna-based-analyses-to') %]</label>
                                    <input class="form-control" type="number" min="1" name="contigEnd">
                                </div>
                                <div class="form-group">
                                    <div class="checkbox">
                                        <label><input type="checkbox" name="revCompContig">[% searchDBTexts.item('search-database-dna-based-analyses-reverse-complement') %]</label>
                                    </div>
                                </div>
                                <input class="btn btn-primary btn-sm" type="submit" value="Search"> 
                                <input class="btn btn-default btn-sm" type="button" value="Clear Form" onclick="this.form.reset(); \$('.errors').remove();">
                            </form>
                        </div>
                    [% IF trna %]
                        <div id="trna" class="tab-pane fade">
                            <form id="trna-form">
                                <div class="form-group">
                                    <label>Contig: </label>
                                    <select name="contig">
                                        <option value="">All</option>
                                        [% FOREACH sequence IN sequences %]
                                                        <option value="[% sequence.id %]">[% sequence.name %]</option>
                                                        [% END %]
                                                    </select>
                                            </div>
                                <div class="form-group">
                                    <label>[% searchDBTexts.item('search-database-dna-based-analyses-get-by-amino-acid') %]</label>
                                    <select class="form-control" name="tRNAaa">
                                        <option value="">All</option>
                                        [% FOREACH text IN searchDBTexts.item('search-database-dna-based-analyses-get-by-amino-acid-options') %]
                                        [% text %]
                                        [% END %]
                                    </select>
                                </div>
                                <div class="form-group">
                                    <label>[% searchDBTexts.item('search-database-dna-based-analyses-get-by-codon') %]</label>
                                    <select class="form-control" name="tRNAcd">
                                        <option value="">All</option>
                                        [% FOREACH text IN searchDBTexts.item('search-database-dna-based-analyses-get-by-codon-options') %]
                                        [% text %]
                                        [% END %]
                                    </select>
                                </div>
                                <input class="btn btn-primary btn-sm" type="submit"  value="Search"> 
                                <input class="btn btn-default btn-sm" type="button" value="Clear Form" onclick="this.form.reset(); \$('.errors').remove();">
                            </form>
                        </div>

                    [% END %]
                    [% IF trf OR mreps OR string %]
                        <div id="tandemRepeats" class="tab-pane fade">
                            <form id="tandemRepeats-form">
                                <div class="alert alert-info">
                                    [% searchDBTexts.item('search-database-dna-based-analyses-tandem-repeats') %]
                                </div>
                                <div class="form-group">
                                    <label>Contig: </label>
                                    <select name="contig">
                                        <option value="">All</option>
                                        [% FOREACH sequence IN sequences %]
                                                        <option value="[% sequence.id %]">[% sequence.name %]</option>
                                                        [% END %]
                                                </select>
                                            </div>
                                <div class="form-group">
                                    <label>[% searchDBTexts.item('search-database-dna-based-analyses-contain-sequence-repetition-unit') %]</label>
                                    <input class="form-control" type="text" name="TRFrepSeq">
                                </div>
                                <div class="form-group">
                                    <label>[% searchDBTexts.item('search-database-dna-based-analyses-repetition-unit-bases') %]</label>
                                    <input class="form-control" type="number" name="TRFrepSize" min="1">
                                    [% FOREACH text IN searchDBTexts.item('search-database-quantity-trf') %]
                                    <div class="radio">
                                        <label>[% text %]</label>
                                    </div>
                                    [% END %]
                                </div>
                                <div class="form-group">
                                    <label>[% searchDBTexts.item('search-database-dna-based-analyses-occours-between') %]</label>
                                    <input class="form-control" type="number" step="any" min="0" name="TRFrepNumMin">
                                    <label>[% searchDBTexts.item('search-database-dna-based-analyses-occours-between-and') %]</label>
                                    <input class="form-control" type="number" step="any" name="TRFrepNumMax">
                                    <label>[% searchDBTexts.item('search-database-dna-based-analyses-occours-between-and-times') %]</label>
                                </div>
                                <div class="alert alert-warning">
                                    [% searchDBTexts.item('search-database-dna-based-analyses-tandem-repeats-note') %]
                                </div>
                                <input class="btn btn-primary btn-sm" type="submit"  value="Search"> 
                                <input class="btn btn-default btn-sm" type="button"  value="Clear Form" onclick="this.form.reset(); \$('.errors').remove();\$('input[name=TRFrepSize]').prop('disabled', false); ">
                            </form>
                        </div>
                    [% END %]
                    [% IF infernal %]
                        <div id="otherNonCodingRNAs" class="tab-pane fade">
                            <form id="otherNonCodingRNAs-form">
                                <div class="form-group">
                                    <label>Contig: </label>
                                    <select name="contig">
                                        <option value="">All</option>
                                        [% FOREACH sequence IN sequences %]
                                                        <option value="[% sequence.id %]">[% sequence.name %]</option>
                                                        [% END %]
                                                </select>
                                            </div>
                                <div class="form-group">
                                    <label>[% searchDBTexts.item('search-database-dna-based-analyses-search-ncrna-by-target-identifier') %]</label>
                                    <input class="form-control" type="text" name="ncRNAtargetID">
                                </div>
                                <div class="form-group">
                                    <label>[% searchDBTexts.item('search-database-dna-based-analyses-or-by-evalue-match') %]</label>
                                    <input class="form-control" type="number" step="any" min="0.00000000000000000000000000001" name="ncRNAevalue">
                                    [% FOREACH text IN searchDBTexts.item('search-database-quantity-ncrna') %]
                                    <div class="radio">
                                        <label>[% text %]</label>
                                    </div>
                                    [% END %]
                                </div>
                                <div class="form-group">
                                    <label>[% searchDBTexts.item('search-database-dna-based-analyses-or-by-target-name') %]</label>
                                    <input class="form-control" type="text" name="ncRNAtargetName">
                                </div>
                                <div class="form-group">
                                    <label>[% searchDBTexts.item('search-database-dna-based-analyses-or-by-target-class') %]</label>
                                    <select class="form-control"  name="ncRNAtargetClass">
                                        <option value=""></option>
                                    </select>
                                </div>
                                <div class="form-group">
                                    <label>[% searchDBTexts.item('search-database-dna-based-analyses-or-by-target-type') %]</label>
                                    <input class="form-control" type="text" name="ncRNAtargetType">
                                </div>
                                <div class="form-group">
                                    <label>[% searchDBTexts.item('search-database-dna-based-analyses-or-by-target-description') %]</label>
                                    <input class="form-control" type="text" name="ncRNAtargetDesc">
                                </div>
                                <input class="btn btn-primary btn-sm" type="submit"  value="Search"> 
                                <input class="btn btn-default btn-sm" type="button"  value="Clear Form" onclick="this.form.reset(); \$('.errors').remove();\$('input[name=ncRNAevalue]').prop('disabled', false);">
                            </form>
                        </div>
                    [% END %]
                    [% IF rbs %]
                        <div id="ribosomalBindingSites" class="tab-pane fade">
                            <form id="ribosomalBindingSites-form">
                                <div class="form-group">
                                    <label>Contig: </label>
                                    <select name="contig">
                                        <option value="">All</option>
                                        [% FOREACH sequence IN sequences %]
                                                        <option value="[% sequence.id %]">[% sequence.name %]</option>
                                                        [% END %]
                                                </select>							
                                </div>
                                <div class="form-group">
                                    <label>[% searchDBTexts.item('search-database-dna-based-analyses-ribosomal-binding') %]</label>
                                    <input class="form-control" type="text" name="RBSpattern">
                                </div>
                                <div class="form-group">
                                    <div class="checkbox">
                                        <label><input type="checkbox" name="RBSshift">[% searchDBTexts.item('search-database-dna-based-analyses-or-search-all-ribosomal-binding-shift') %]</label>
                                    </div>
                                    [% FOREACH text IN searchDBTexts.item('search-database-dna-based-analyses-or-search-all-ribosomal-binding-options') %]
                                    <div class="radio">
                                        <label>[% text %]</label>
                                    </div>
                                    [% END %]
                                </div>
                                <div class="form-group">
                                    <div class="checkbox">
                                        <label><input type="checkbox" name="RBSnewcodon">[% searchDBTexts.item('search-database-dna-based-analyses-or-search-all-ribosomal-binding-start') %]</label>
                                    </div>
                                </div>
                                <input class="btn btn-primary btn-sm" type="submit"  value="Search"> 
                                <input class="btn btn-default btn-sm" type="button"  value="Clear Form" onclick="this.form.reset(); \$('.errors').remove();">
                            </form>
                        </div>
                    [% END %]
                    [% IF transterm %]
                        <div id="transcriptionalTerminators" class="tab-pane fade">
                            <form id="transcriptionalTerminators-form">
                                <div class="form-group">
                                    <label>Contig: </label>
                                    <select name="contig">
                                        <option value="">All</option>
                                        [% FOREACH sequence IN sequences %]
                                                        <option value="[% sequence.id %]">[% sequence.name %]</option>
                                                        [% END %]
                                                </select>
                                </div>
                                <div class="form-group">
                                    <label>[% searchDBTexts.item('search-database-dna-based-analyses-transcriptional-terminators-confidence-score') %]</label>
                                    <input class="form-control" type="number" step="any" min="1" name="TTconf">
                                    [% FOREACH text IN searchDBTexts.item('search-database-analyses-protein-code-TTconfM') %]
                                    <div class="radio">
                                        <label>[% text %]</label>
                                    </div>
                                    [% END %]
                                </div>
                                <div class="form-group">
                                    <label>[% searchDBTexts.item('search-database-dna-based-analyses-or-hairpin-score') %]</label>
                                    <input class="form-control" type="number" step="any" name="TThp">
                                    [% FOREACH text IN searchDBTexts.item('search-database-analyses-protein-code-TThpM') %]
                                    <div class="radio">
                                        <label>[% text %]</label>
                                    </div>
                                    [% END %]
                                </div>
                                <div class="form-group">
                                    <label>[% searchDBTexts.item('search-database-dna-based-analyses-or-tail-score') %]</label>
                                    <input class="form-control" type="number" step="any" name="TTtail">
                                    [% FOREACH text IN searchDBTexts.item('search-database-analyses-protein-code-TTtailM') %]
                                        <div class="radio">
                                            <label>[% text %]</label>
                                        </div>
                                    [% END %]
                                </div>
                                <div class="alert alert-warning">
                                    [% searchDBTexts.item('search-database-dna-based-analyses-hairpin-note') %]
                                </div>
                                <input class="btn btn-primary btn-sm" type="submit"  value="Search"> 
                                <input class="btn btn-default btn-sm" type="button"  value="Clear Form" onclick="this.form.reset(); \$('.errors').remove();\$('input[name=TTconf]').prop('disabled', false);\$('input[name=TThp]').prop('disabled', false);\$('input[name=TTtail]').prop('disabled', false);">
                            </form>
                        </div>
                    [% END %]
                    [% IF alienhunter %]
                        <div id="horizontalGeneTransfers" class="tab-pane fade">
                            <form id="horizontalGeneTransfers-form">
                                <div class="form-group">
                                    <label>Contig: </label>
                                    <select name="contig">
                                        <option value="">All</option>
                                        [% FOREACH sequence IN sequences %]
                                                        <option value="[% sequence.id %]">[% sequence.name %]</option>
                                                        [% END %]
                                                </select>
                                </div>
                                <div class="form-group">
                                    <label>[% searchDBTexts.item('search-database-dna-based-analyses-predicted-alienhunter') %]</label>
                                    <input class="form-control" type="number" min="0.1" step="any" name="AHlen">
                                    [% FOREACH text IN searchDBTexts.item('search-database-analyses-protein-code-AHlenM') %]
                                    <div class="radio">
                                        <label>[% text %]</label>
                                    </div>
                                    [% END %]
                                </div>
                                <div class="form-group">
                                    <label>[% searchDBTexts.item('search-database-dna-based-analyses-or-get-regions-score') %]</label>
                                    <input class="form-control" type="number" min="0.1" step="any" name="AHscore">
                                    [% FOREACH text IN searchDBTexts.item('search-database-analyses-protein-code-AHscM') %]
                                    <div class="radio">
                                        <label>[% text %]</label>
                                    </div>
                                    [% END %]
                                </div>
                                <div class="form-group">
                                    <label>[% searchDBTexts.item('search-database-dna-based-analyses-or-get-regions-threshold') %]</label>
                                    <input class="form-control" type="number" min="0.1" step="any" name="AHthr">
                                    [% FOREACH text IN searchDBTexts.item('search-database-analyses-protein-code-AHthrM') %]
                                    <div class="radio">
                                        <label>[% text %]</label>
                                    </div>
                                    [% END %]
                                </div>
                                <input class="btn btn-primary btn-sm" type="submit" value="Search"> 
                                <input class="btn btn-default btn-sm" type="button"  value="Clear Form" onclick="this.form.reset(); \$('.errors').remove();\$('input[name=AHlen]').prop('disabled', false);\$('input[name=AHscore]').prop('disabled', false);\$('input[name=AHthr]').prop('disabled', false);">
                            </form>
                        </div>
                    [% END %]
                    [% IF rnammer %]
                        <div id="rrna" class="tab-pane fade">
                            <form id="rRNA-form">
                                <div class="form-group">
                                    <label>Contig: </label>
                                    <select name="contig">
                                        <option value="">All</option>
                                        [% FOREACH sequence IN sequences %]
                                                        <option value="[% sequence.id %]">[% sequence.name %]</option>
                                                        [% END %]
                                                </select>
                                </div>
                                <div class="form-group">
                                    <label>[% searchDBTexts.item('search-database-dna-based-analyses-get-by-rrna-type') %]</label>
                                    <select name="type">
                                        <option value="">All</option>
                                        [% FOREACH rrna IN rRNAsAvailable %]
                                                        <option value="[% rrna %]">[% rrna %]</option>
                                                        [% END %]
                                                </select>
                                </div>

                                <input class="btn btn-primary btn-sm" type="submit" value="Search"> 
                                <input class="btn btn-default btn-sm" type="button"  value="Clear Form" onclick="this.form.reset(); $('.errors').remove();">
                            </form>
                        </div>
                    [% END %]
                    </div>
                             </div>
                             <div class="panel-footer">
                                [% searchDBTexts.item('search-database-dna-based-analyses-footer') %]
                             </div>
                         </div>
                     </div>
                 [% END %]
                </div>
            </div>
        </div>
    </div>
</div>
<form id="geneByPosition">
<input type="hidden" name="contig" id="contigGenePosition" />
<input type="hidden" name="start" id="start" />
<input type="hidden" name="end" id="end" />
</form>
<!-- CONTENT-WRAPPER SECTION END-->



CONTENTSEARCHDATABASE
        ,
        "index.tt" => <<CONTENTINDEXSEARCHDATABASE
<!DOCTYPE html>
<input type="hidden" id="id" value="[% id %]" />
<div class="content-wrapper">
    <div class="container">
        <div class="row">
            <div class="col-md-1">
                <input type="button" id="back" value="Back" class="btn btn-danger btn-lg" />
            </div>
            <div class="col-md-11">
                <span id="totalResults"></span>
            </div>
        </div>
        [% INCLUDE '$lowCaseName/search-database/_forms.tt' %]
        <section class="pagination-section">
            <div class="row">
                <div class="col-sm-2">
                    <input type="button" id="begin" value="<<" class="btn btn-info btn-lg" />
                </div>
                <div class="col-sm-2">
                    <input type="button" id="less" value="<" class="btn btn-info btn-lg" />
                </div>
                <form id="skipPagination">
                    <div class="col-sm-2">
                        <div class="row">
                            <div class="col-md-6">
                                <input type="number" id="numberPage" value="1" min="1" class="form-control" />
                            </div>
                            <div class="col-md-6"> 
                                <p>pages of <span id="totalNumberPages" /></p>	
                            </div>
                        </div>
                    </div>
                    <div class="col-sm-2">
                        <input type="submit" id="goPage" value="Go" class="btn btn-info btn-lg" />
                    </div>
                </form>
                <div class="col-sm-2">
                    <input type="button" id="more" value=">" class="btn btn-info btn-lg" />
                </div>
                <div class="col-sm-2">
                    <input type="button" id="last" value=">>" class="btn btn-info btn-lg" />
                </div>
            </div>
        </section>
    </div>
</div>
<script>
    \$("#parentCollapseOne").click(function ()
    {
        \$("#parentCollapseOne").removeClass("panel-default");
        \$("#parentCollapseTwo").removeClass("panel-info");
        \$("#parentCollapseThree").removeClass("panel-info");
        \$("#parentCollapseOne").addClass("panel-info");
        \$("#parentCollapseTwo").addClass("panel-default");
        \$("#parentCollapseThree").addClass("panel-default");
    });
    \$("#parentCollapseTwo").click(function ()
    {
        \$("#parentCollapseTwo").removeClass("panel-default");
        \$("#parentCollapseOne").removeClass("panel-info");
        \$("#parentCollapseThree").removeClass("panel-info");
        \$("#parentCollapseTwo").addClass("panel-info");
        \$("#parentCollapseOne").addClass("panel-default");
        \$("#parentCollapseThree").addClass("panel-default");
    });
    \$("#parentCollapseThree").click(function ()
    {
        \$("#parentCollapseThree").removeClass("panel-default");
        \$("#parentCollapseTwo").removeClass("panel-info");
        \$("#parentCollapseOne").removeClass("panel-info");
        \$("#parentCollapseThree").addClass("panel-info");
        \$("#parentCollapseOne").addClass("panel-default");
        \$("#parentCollapseTwo").addClass("panel-default");
    });
</script> 

<script type="text/javascript" src="/assets/js/site-client.js"></script>
<script type="text/javascript" src="/assets/js/search-database.js"></script>

CONTENTINDEXSEARCHDATABASE
        ,
        "contigs.tt" => <<CONTENT
<!DOCTYPE html>
<div class="panel panel-default result">
    <div class="panel-heading">
        <div class="panel-title">
            <div class='row'>
                <div class='col-md-10'>
                    <a id="title-panel" class="collapsed" data-toggle="collapse" data-parent="#accordion" href="#[% sequence.id %]">Contig search results
                </div>
                <div class='col-md-2'>
                    <a href="[% sequence.path %]/DownloadSequence?contig=[% sequence.name %]&start=[% start %]&end=[% end %]&reverseComplement=[% hadReverseComplement %]">Download FASTA</a>
                </div>
            </div>			
        </div>
    </div>
    <div id="[% sequence.id %]" class="panel-collapse collapse in">
        <div class="panel-body">
            <div class="sequence">
                <div class="row">
                    <div class="col-md-6">
                        [% contig %]
                    </div>
                </div>
            </div>
        </div>
    </div>
</div>

CONTENT
        ,
        "dgpiBasicResult.tt" => <<CONTENT
<!DOCTYPE html>
<div class="panel panel-default">
    <div class="panel-heading">
        <div class="panel-title">
            <a data-toggle="collapse" data-parent="#accordion" href="#[% result.componentName %]-[% result.feature_id %]-[% result.counter %]">[% result.counter %]</a>
        </div>
    </div>
    <div id="[% result.componentName %]-[% result.feature_id %]-[% result.counter %]" class="panel-body collapsed">
        <div class="row">
            <div class="col-md-3">
                <p>Cleavage site:</p>
            </div>
            <div class="col-md-9">
                <p>[% result.cleavage_site %]</p>
            </div>
        </div>
        <div class="row">
            <div class="col-md-3">
                <p>Score:</p>
            </div>
            <div class="col-md-9">
                <p>[% result.score %]</p>
            </div>
        </div>
        <div class="row">
            <div class="col-md-3">
                <p>Start:</p>
            </div>
            <div class="col-md-9">
                <p>[% result.start %]</p>
            </div>
        </div>
        <div class="row">
            <div class="col-md-3">
                <p>End:</p>
            </div>
            <div class="col-md-9">
                <p>[% result.end %]</p>
            </div>
        </div>
        <div class="row">
            <div class="col-md-3">
                <p>Strand:</p>
            </div>
            <div class="col-md-9">
                <p>[% result.strand %]</p>
            </div>
        </div>
    </div>
</div>
CONTENT
        ,
        "bigpiBasicResult.tt" => <<CONTENT
<!DOCTYPE html>
        <div class="row">
            <div class="col-md-3">
                <p>Value:</p>
            </div>
            <div class="col-md-9">
                <p>[% result.pvalue %]</p>
            </div>
        </div>
        <div class="row">
            <div class="col-md-3">
                <p>Position:</p>
            </div>
            <div class="col-md-9">
                <p>[% result.position %]</p>
            </div>
        </div>
        <div class="row">
            <div class="col-md-3">
                <p>Start:</p>
            </div>
            <div class="col-md-9">
                <p>[% result.start %]</p>
            </div>
        </div>
        <div class="row">
            <div class="col-md-3">
                <p>End:</p>
            </div>
            <div class="col-md-9">
                <p>[% result.end %]</p>
            </div>
        </div>
        <div class="row">
            <div class="col-md-3">
                <p>Strand:</p>
            </div>
            <div class="col-md-9">
                <p>[% result.strand %]</p>
            </div>
        </div>
CONTENT
        ,
        "dgpiNoResult.tt" => <<CONTENT
<!DOCTYPE html>
<div class="row">
    <div class="col-md-3">
        <p>Result:</p>
    </div>
    <div class="col-md-9">
        <p>[% result.result %]</p>
    </div>
</div>		
CONTENT
        ,		
        "signalPBasicResult.tt" => <<CONTENT
<!DOCTYPE html>
<div class="row">
        <div class="col-md-3">
                <p>Start residue:</p>
        </div>
        <div class="col-md-9">
                <p>[% result.start_residue %]</p>
        </div>
</div>
<div class="row">
        <div class="col-md-3">
                <p>End residue:</p>
        </div>
        <div class="col-md-9">
                <p>[% result.end_residue %]</p>
        </div>
</div>
<div class="row">
        <div class="col-md-3">
                <p>Peptideo signal:</p>
        </div>
        <div class="col-md-9">
                <p>[% result.pep_sig %]</p>
        </div>
</div>
<div class="row">
        <div class="col-md-3">
                <p>Cutoff:</p>
        </div>
        <div class="col-md-9">
                <p>[% result.cutoff %]</p>
        </div>
</div>
<div class="row">
        <div class="col-md-3">
                <p>Score:</p>
        </div>
        <div class="col-md-9">
                <p>[% result.score %]</p>
        </div>
</div>
CONTENT
        ,
        "evidences.tt" => <<CONTENT
<!DOCTYPE html>
<div class="panel panel-default">
    <div class="panel-heading">
        <div class="panel-title">
            [% result.descriptionComponent %]
        </div>
    </div>
    <div id="evidence-[% result.componentName %]-[% result.id %]" class="panel-body collapse">
    </div>
</div>

CONTENT
        ,
        "hmmerBasicResult.tt" => <<CONTENT
<!DOCTYPE html>
<div class="row">
    <div class="col-md-3">
        <p>Sequence name:</p>
    </div>
    <div class="col-md-9">
        <p>[% result.seq_name %]</p>
    </div>
</div>
<div class="row">
        <div class="col-md-3">
                <p>Score:</p>
        </div>
        <div class="col-md-9">
                <p>[% result.score %]</p>
        </div>
</div>
<div class="row">
        <div class="col-md-3">
                <p>Exon number:</p>
        </div>
        <div class="col-md-9">
                <p>[% result.exon_number %]</p>
        </div>
</div>
<div class="row">
        <div class="col-md-3">
                <p>Length:</p>
        </div>
        <div class="col-md-9">
                <p>[% result.length %]</p>
        </div>
</div>
<div class="row">
        <div class="col-md-3">
                <p>Genetic code:</p>
        </div>
        <div class="col-md-9">
                <p>[% result.genetic_code %]</p>
        </div>
</div>
CONTENT
        ,
        "gene.tt" => <<CONTENT
<!DOCTYPE html>
<div class="panel panel-default result">
    <div class="panel-heading">
        <div class="panel-title">
            <a id="result-panel-title-[% result.feature_id %]" data-toggle="collapse" data-parent="#accordion" href="#[% result.feature_id %]">[% result.name %] - [% result.uniquename %]</a>
        </div>
    </div>
    <div id="[% result.feature_id %]" class="panel-body collapse">
    </div>
</div>
CONTENT
        ,
        "geneBasics.tt" => <<CONTENT
<!DOCTYPE html>
<div class="row">
    <div class="col-md-3">
        <p>Gene predictor:</p>
    </div>
    <div class="col-md-9">
        <p>[% result.type %]</p>
    </div>
</div>
<div class="row">
    <div class="col-md-3">
        <p>Located in:</p>
    </div>
    <div class="col-md-9">
        <p>[% result.uniquename %] (from position [% result.fstart %] to [% result.fend %])</p>
    </div>
</div>
<div class="row">
    <div class="col-md-3">
        <p>Gene length:</p>
    </div>
    <div class="col-md-9">
        <p>[% result.length %]</p>
    </div>
</div>
CONTENT
        ,
        "interproBasicResult.tt" => <<CONTENT
<!DOCTYPE html>
<div class="panel panel-default">
    <div class="panel-heading">
        <div class="panel-title">
            <a data-toggle="collapse" data-parent="#accordion" href="#[% result.componentName %]-[% result.feature_id %]-[% result.counter %]">[% result.counter %]</a>
        </div>
    </div>
    <div id="[% result.componentName %]-[% result.feature_id %]-[% result.counter %]" class="panel-body collapsed">
        <div class="row">
            <div class="col-md-3">
                <p>InterPro identifier:</p>
            </div>
            <div class="col-md-9">
                <p><a href="http://www.ebi.ac.uk/interpro/entry/[% result.interpro_id %]" target='_blank'>[% result.interpro_id %]</a></p>
            </div>
        </div>
        <div class="row">
            <div class="col-md-3">
                <p>InterPro description:</p>
            </div>
            <div class="col-md-9">
                <p>[% result.description_interpro %]</p>
            </div>
        </div>
        <div class="row">
            <div class="col-md-3">
                <p>Database identifier and database:</p>
            </div>
            <div class="col-md-9">
                <p><a href="http://www.ebi.ac.uk/interpro/search?q=[% result.DB_id %]" target='_blank'>[% result.DB_id %]</a> ([% result.DB_name %])</p>
            </div>
        </div>
        <div class="row">
            <div class="col-md-3">
                <p>Database match description:</p>
            </div>
            <div class="col-md-9">
                <p>[% result.description %]</p>
            </div>
        </div>
        <div class="row">
            <div class="col-md-3">
                <p>GO process:</p>
            </div>
            <div class="col-md-9">
                <p>[% result.evidence_process %]</p>
            </div>
        </div>
        <div class="row">
            <div class="col-md-3">
                <p>GO function:</p>
            </div>
            <div class="col-md-9">
                <p>[% result.evidence_function %]</p>
            </div>
        </div>
        <div class="row">
            <div class="col-md-3">
                <p>GO component:</p>
            </div>
            <div class="col-md-9">
                <p>[% result.evidence_component %]</p>
            </div>
        </div>
        <div class="row">
            <div class="col-md-3">
                <p>Match score:</p>
            </div>
            <div class="col-md-9">
                <p>[% result.score %]</p>
            </div>
        </div>
    </div>
</div>
CONTENT
        ,
        "orthologies.tt" => <<CONTENT
<tr>
    <td><a href="http://eggnog.embl.de/version_3.0/cgi/search.py?search_term_0=[% result.orthologous_group %]" target='_blank'>[% result.orthologous_group %]</a> - [% result.orthologous_group_description %]</td>
</tr>
CONTENT
        ,
        "orthologyBasicResult.tt" => <<CONTENT
<!DOCTYPE html>
<div class="row">
    <div class="col-md-3">
        Match identifier:
    </div>
    <div class="col-md-9">
        [% result.orthologous_hit %]
    </div>
</div>
<div class="row">
    <div class="col-md-12">
        <div class="table-responsive">
            <table class="table table-striped table-hover">
                <thead>
                    <tr>
                        <th>Orthologous group:</th>
                    </tr>
                </thead>
                <tbody id="orthology-[% result.id %]">

                </tbody>
            </table>
        </div>
    </div>
</div>
CONTENT
        ,
        "pathways.tt" => <<CONTENT
<tr>
    <td><a href="http://www.genome.jp/dbget-bin/www_bget?[% result.metabolic_pathway_id %]" target='_blank'>[% result.metabolic_pathway_id %]</a> - [% result.metabolic_pathway_description %]</td>
    <td>[% result.viewmap %]</td>
</tr>
CONTENT
        ,
        "pathwaysBasicResult.tt" => <<CONTENT
<!DOCTYPE html>
<div class="row">
    <div class="col-md-3">
        Orthologous group:
    </div>
    <div class="col-md-9">
        <a href="http://www.genome.jp/dbget-bin/www_bget?[% result.orthologous_group_id %]" target='_blank'>[% result.orthologous_group_id %]</a> - [% result.orthologous_group_description %]
    </div>
</div>

CONTENT
        ,
        "predgpiBasicResult.tt" => <<CONTENT
<!DOCTYPE html>
<div class="panel panel-default">
    <div class="panel-heading">
        <div class="panel-title">
            <a data-toggle="collapse" data-parent="#accordion" href="#[% result.componentName %]-[% result.feature_id %]-[% result.counter %]">[% result.counter %]</a>
        </div>
    </div>
    <div id="[% result.componentName %]-[% result.feature_id %]-[% result.counter %]" class="panel-body collapsed">
        <div class="row">
            <div class="col-md-3">
                <p>Name:</p>
            </div>
            <div class="col-md-9">
                <p>[% result.name %]</p>
            </div>
        </div>
        <div class="row">
            <div class="col-md-3">
                <p>Position:</p>
            </div>
            <div class="col-md-9">
                <p>[% result.position %]</p>
            </div>
        </div>
        <div class="row">
            <div class="col-md-3">
                <p>Specificity:</p>
            </div>
            <div class="col-md-9">
                <p>[% result.specificity %]</p>
            </div>
        </div>
        <div class="row">
            <div class="col-md-3">
                <p>Sequence:</p>
            </div>
            <div class="col-md-9">
                <p>[% result.sequence %]</p>
            </div>
        </div>
        <div class="row">
            <div class="col-md-3">
                <p>Start:</p>
            </div>
            <div class="col-md-9">
                <p>[% result.start %]</p>
            </div>
        </div>
        <div class="row">
            <div class="col-md-3">
                <p>End:</p>
            </div>
            <div class="col-md-9">
                <p>[% result.end %]</p>
            </div>
        </div>
        <div class="row">
            <div class="col-md-3">
                <p>Strand:</p>
            </div>
            <div class="col-md-9">
                <p>[% result.strand %]</p>
            </div>
        </div>
    </div>
</div>
CONTENT
        ,
        "properties.tt" => <<CONTENT
<!DOCTYPE html>
<div class="row">
    <div class="col-md-3">
        [% result.key %]
    </div>
    <div class="col-md-9">
        [% result.value %]
    </div>
</div>
CONTENT
        ,
        "rnaPredictionBasicResult.tt" => <<CONTENT
<!DOCTYPE html>
<div class="row">
    <div class="col-md-3">
        <p>Molecule type:</p>
    </div
    <div class="col-md-9">
        <p>[% result.molecule_type %]</p>
    </div
</div>
<div class="row">
    <div class="col-md-3">
        <p>Prediction score:</p>
    </div
    <div class="col-md-9">
        <p>[% result.score %]</p>
    </div
</div>
CONTENT
        ,
        "rnaScanBasicResult.tt" => <<CONTENT
<!DOCTYPE html>
<div class="row">
    <div class="col-md-3">
        <p>Product description:</p>
    </div>
    <div class="col-md-9">
        <p>[% result.target_description %]</p>
    </div>
</div>
<div class="row">
    <div class="col-md-3">
        <p>Prediction score:</p>
    </div>
    <div class="col-md-9">
        <p>[% result.score %]</p>
    </div>
</div>
<div class="row">
    <div class="col-md-3">
        <p>E-value of match:</p>
    </div>
    <div class="col-md-9">
        <p>[% result.evalue %]</p>
    </div>
</div>
<div class="row">
    <div class="col-md-3">
        <p>Identifier of match:</p>
    </div>
    <div class="col-md-9">
        <p>[% result.target_identifier %]</p>
    </div>
</div>
<div class="row">
    <div class="col-md-3">
        <p>Target name:</p>
    </div>
    <div class="col-md-9">
        <p>[% result.target_name %]</p>
    </div>
</div>
<div class="row">
    <div class="col-md-3">
        <p>Target class:</p>
    </div>
    <div class="col-md-9">
        <p>[% result.target_class %]</p>
    </div>
</div>
<div class="row">
    <div class="col-md-3">
        <p>Bias:</p>
    </div>
    <div class="col-md-9">
        <p>[% result.bias %]</p>
    </div>
</div>
<div class="row">
    <div class="col-md-3">
        <p>Truncated:</p>
    </div>
    <div class="col-md-9">
        <p>[% result.truncated %]</p>
    </div>
</div>
<div class="row">
    <div class="col-md-3">
        <p>Component result:</p>
    </div>
    <div class="col-md-9">
        <p>[% result.download %]</p>
    </div>
</div>
CONTENT
        ,
        "rRNAPredictionBasicResult.tt" => <<CONTENT
<!DOCTYPE html>
<div class="row">
    <div class="col-md-3">
        <p>Molecule type:</p>
    </div>
    <div class="col-md-9">
        <p>[% result.molecule_type %]</p>
    </div>
</div>
<div class="row">
    <div class="col-md-3">
        <p>Prediction score:</p>
    </div>
    <div class="col-md-9">
        <p>[% result.score %]</p>
    </div>
</div>
<div class="row">
    <div class="col-md-3">
        <p>Component result:</p>
    </div>
    <div class="col-md-9">
        <p>[% result.download %]</p>
    </div>
</div>
CONTENT
        ,
        "sequence.tt" => <<CONTENT
<!DOCTYPE html>
<div class="panel panel-default sequences">
    <div class="panel-heading">
        <div class="panel-title">
            <div class="row">
                <div class="col-md-10">
                    <a data-toggle="collapse" data-parent="#accordion" href="#sequence-[% result.feature_id %]">Sequence</a> 
                </div>
                <div class="col-md-2">
                    <a href="[% result.pathname %]/DownloadSequence?contig=[% result.contig %]&start=[% result.start %]&end=[% result.end %]&reverseComplement=[% result.reverseComplement %]">Download FASTA</a>
                </div>
            </div>
        </div>
    </div>
    <div id="sequence-[% result.feature_id %]" class="panel-body collapse sequence">
        <div class="row">
            <div class="col-md-12">
                [% result.sequence %]
            </div>
        </div>
    </div>
</div>
CONTENT
        ,
        "similarityBasicResult.tt" => <<CONTENT
<!DOCTYPE html>
<div class="row">
    <div class="col-md-3">
        <p>Identifier</p>
    </div>
    <div class="col-md-9">
        <p>[% result.identifier %]</p>
    </div>
</div>
<div class="row">
    <div class="col-md-3">
        <p>Description</p>
    </div>
    <div class="col-md-9">
        <p>[% result.description %]</p>
    </div>
</div>
<div class="row">
    <div class="col-md-3">
        <p>E-value of match</p>
    </div>
    <div class="col-md-9">
        <p>[% result.evalue %]</p>
    </div>
</div>
<div class="row">
    <div class="col-md-3">
        <p>Percent identity</p>
    </div>
    <div class="col-md-9">
        <p>[% result.percent_id %]</p>
    </div>
</div>
<div class="row">
    <div class="col-md-3">
        <p>Percent similarity</p>
    </div>
    <div class="col-md-9">
        <p>[% result.similarity %]</p>
    </div>
</div>
<div class="row">
    <div class="col-md-3">
        <p>Alignment score</p>
    </div>
    <div class="col-md-9">
        <p>[% result.score %]</p>
    </div>
</div>
<div class="row">
    <div class="col-md-3">
        <p>Alignment length</p>
    </div>
    <div class="col-md-9">
        <p>[% result.block_size %]</p>
    </div>
</div>
CONTENT
        ,
        "subEvidences.tt" => <<CONTENT
<!DOCTYPE html>
<div class="panel panel-default">
    <div class="panel-heading">
        <div class="panel-title">
            <a data-toggle="collapse" data-parent="#accordion" href="#subevidence-[% result.feature_id %]">[% result.feature_id %]</a>
        </div>
    </div>
    <div id="subevidence-[% result.feature_id %]" class="panel-body collapse">
    </div>
</div>
CONTENT
        ,
        "tcdbBasicResult.tt" => <<CONTENT
<!DOCTYPE html>
<div class="row">
    <div class="col-md-3">
        <p>Transporter classification:</p>
    </div>
    <div class="col-md-9">
        <p><a href="http://tcdb.org/search/result.php?tc=[% result.TCDB_ID %]" target='_blank'>[% result.hit_description %]</a></p>
    </div>
</div>
<div class="row">
    <div class="col-md-3">
        <p>Class:</p>
    </div>
    <div class="col-md-9">
        <p>[% result.TCDB_class %]</p>
    </div>
</div>
<div class="row">
    <div class="col-md-3">
        <p>Subclass:</p>
    </div>
    <div class="col-md-9">
        <p>[% result.TCDB_subclass %]</p>
    </div>
</div>
<div class="row">
    <div class="col-md-3">
        <p>Family:</p>
    </div>
    <div class="col-md-9">
        <p>[% result.TCDB_family %]</p>
    </div>
</div>
<div class="row">
    <div class="col-md-3">
        <p>Match identifier:</p>
    </div>
    <div class="col-md-9">
        <p><a href="http://www.uniprot.org/uniprot/[% result.hit_name %]" target='_blank'>[% result.hit_name %]</a></p>
    </div>
</div>
<div class="row">
    <div class="col-md-3">
        <p>E-value of match:</p>
    </div>
    <div class="col-md-9">
        <p>[% result.evalue %]</p>
    </div>
</div>
<div class="row">
    <div class="col-md-3">
        <p>Percent identity:</p>
    </div>
    <div class="col-md-9">
        <p>[% result.percent_id %]</p>
    </div>
</div>
<div class="row">
    <div class="col-md-3">
        <p>Percent similarity:</p>
    </div>
    <div class="col-md-9">
        <p>[% result.similarity %]</p>
    </div>
</div>
CONTENT
        ,
        "tmhmmBasicResult.tt" => <<CONTENT
<!DOCTYPE html>
<div class="row">
    <div class="col-md-3">
        Predicted Transmembrane domains
    </div>
    <div class="col-md-9">
        [% result.predicted_TMHs %]
    </div>
</div>
<div class="row">
    <div class="col-md-3">
        Direction
    </div>
    <div class="col-md-9">
        [% result.direction %]
    </div>
</div>
CONTENT
        ,
        "tRNABasicResult.tt" => <<CONTENT
<!DOCTYPE html>
<div class="row">
    <div class="col-md-3">
        <p>Gene name:</p>
    </div>
    <div class="col-md-9">
        <p>[% result.type %]</p>
    </div>
</div>
<div class="row">
    <div class="col-md-3">
        <p>Amino acid:</p>
    </div>
    <div class="col-md-9">
        <p>[% result.aminoacid %]</p>
    </div>
</div>
<div class="row">
    <div class="col-md-3">
        <p>Anticodon:</p>
    </div>
    <div class="col-md-9">
        <p>[% result.anticodon %] (from position [% result.anticodon_start %] to [% result.anticodon_end %])  </p>
    </div>
</div>
<div class="row">
    <div class="col-md-3">
        <p>Codon:</p>
    </div>
    <div class="col-md-9">
        <p>[% result.codon %]</p>
    </div>
</div>
<div class="row">
    <div class="col-md-3">
        <p>Prediction score:</p>
    </div>
    <div class="col-md-9">
        <p>[% result.score %]</p>
    </div>
</div>
<div class="row">
    <div class="col-md-3">
        <p>Is pseudogene:</p>
    </div>
    <div class="col-md-9">
        <p>[% result.pseudogene %]</p>
    </div>
</div>
<div class="row">
    <div class="col-md-3">
        <p>Component result:</p>
    </div>
    <div class="col-md-9">
        <p>[% result.download %]</p>
    </div>
</div>
CONTENT
        ,
        "tRNABasicResultHasIntron.tt" => <<CONTENT
<!DOCTYPE html>
<div class="row">
    <div class="col-md-3">
        <p>Intron predicted:</p>
    </div>
    <div class="col-md-9">
        <p>[% result.intron %]</p>
    </div>
</div>
<div class="row">
    <div class="col-md-3">
        <p>Coordinates (gene):</p>
    </div>
    <div class="col-md-9">
        <p>[% result.coordinatesGene %]</p>
    </div>
</div>
<div class="row">
    <div class="col-md-3">
        <p>Coordinates (genome):</p>
    </div>
    <div class="col-md-9">
        <p>[% result.coordinatesGenome %]</p>
    </div>
</div>
CONTENT
        ,
        "result.tt" => <<CONTENT
<!DOCTYPE html>
<div class="content-wrapper">
    <div class="container">
        [% SWITCH type_search %]
            [% CASE 0 %]
                [% FOREACH result IN searchResult %]
                    <div class="panel panel-default">
                        <div class="panel-heading">
                            <div class="panel-title">
                                <a class="collapsed" data-toggle="collapse" data-parent="#accordion" href="#[% result.feature_id %]">[% result.name %] - [% result.uniquename %]</a>
                            </div>
                        </div>
                        <div id="[% result.feature_id %]" class="panel-collapse collapse">
                            <div class="panel-body">
                            </div>
                        </div>
                    </div>
                [% END %]
            [% CASE 1 %]
                [% IF contig %]
                    <div class="panel panel-default">
                        <div class="panel-heading">
                            <div class="panel-title">
                                <a class="collapsed" data-toggle="collapse" data-parent="#accordion" href="#[% sequence.id %]">Contig search results - Retrieved sequence(
                                [% IF hadLimits %]
                                    from [% start %] to [% end %] of 
                                [% END %]
                                [% sequence.name %]
                                [% IF hadReverseComplement %]
                                    , reverse complemented
                                [% END %]
                                )</a>
                            </div>
                        </div>
                        <div id="[% sequence.id %]" class="panel-collapse collapse">
                            <div class="panel-body">
                                <div class="sequence">
                                    [% contig %]
                                </div>
                            </div>
                        </div>
                    </div>
                [% ELSE %]
                    <div class="alert alert-danger">
                        [% FOREACH text IN texts %]
                            [% IF text.tag == 'result-warning-contigs' %]
                                [% text.value %]
                            [% END %]
                        [% END %]
                    </div>
                [% END %]
        [% END %]
    </div>
</div>

CONTENT
    },
    shared => {
        "_footer.tt" => <<FOOTER
<footer>
    <div class="container">
        <div class="row">
            <div class="col-md-12">
                [% FOREACH text IN texts %]
                    [% IF text.tag == 'footer' %]
                        <a href="[% c.uri_for(text.details) %]">[% text.value %]</a>
                    [% END %]
                [% END %]

            </div>

        </div>
    </div>
</footer>
FOOTER
        ,
        "_head.tt" => <<HEAD
<!DOCTYPE html>
<meta charset="utf-8" />
<meta name="viewport" content="width=device-width, initial-scale=1, maximum-scale=1" />
<meta name="description" content="" />
<meta name="author" content="" />
<!--[if IE]>
    <meta http-equiv="X-UA-Compatible" content="IE=edge,chrome=1">
    <![endif]-->
<title>[% titlePage %]</title>
<!-- BOOTSTRAP CORE STYLE  -->
<link href="/assets/css/bootstrap.css" rel="stylesheet" />
<!-- FONT AWESOME ICONS  -->
<link href="/assets/css/font-awesome.css" rel="stylesheet" />
<!-- CUSTOM STYLE  -->
<link href="/assets/css/style.css" rel="stylesheet" />
<link href="/assets/css/colors-$organism_name.css" rel="stylesheet"  />
<!-- PACE loader CSS -->
<link href="/assets/css/pace-theme-fill-left.css" rel="stylesheet" />
<link href="/assets/css/multiple-select.css" rel="stylesheet" />
<!-- PACE loader js -->
<script src="/assets/js/pace.min.js"></script>
 <!-- HTML5 Shiv and Respond.js for IE8 support of HTML5 elements and media queries -->
<!-- WARNING: Respond.js doesn''t work if you view the page via file:// -->
<!--[if lt IE 9]>
    <script src="https://oss.maxcdn.com/libs/html5shiv/3.7.0/html5shiv.js"></script>
    <script src="https://oss.maxcdn.com/libs/respond.js/1.4.2/respond.min.js"></script>
<![endif]-->


HEAD
        ,
        "_header.tt" => <<HEADER
<!DOCTYPE html>
<header>
    <div class="container">
        <div class="row">
            <div class="col-md-12">
                [% FOREACH text IN texts %]
                    [% IF text.tag.search('header') %]

                        [% text.value %]
                        &nbsp;&nbsp;

                    [% END %]
                [% END %]
            </div>

        </div>
    </div>
</header>
HEADER
        ,
        "_menu.tt" => $menu

    }
);

unless ($hadGlobal) {
    delete $contentHTML{"global-analyses"};
}
unless ($hadSearchDatabase) {
    delete $contentHTML{"search-database"};
}

#writeFile("log-report-html-db.log", $scriptSQL);

print $LOG "\nCreating html views\n";
foreach my $directory ( keys %contentHTML ) {
    if ( !( -e "$html_dir/root/$lowCaseName/$directory" ) ) {
        print $LOG "\nCriando diretorio $directory\n";
        `mkdir -p "$html_dir/root/$lowCaseName/$directory"`;
    }
    foreach my $file ( keys %{ $contentHTML{$directory} } ) {
        print $LOG "\nCriando arquivo $file\n";
        writeFile( "$html_dir/root/$lowCaseName/$directory/$file",
            $contentHTML{$directory}{$file} );
    }
}

#Create file wrapper
print $LOG "\nCreating wrapper\n";
my $wrapper = <<WRAPPER;
﻿<!DOCTYPE html>
<html xmlns="http://www.w3.org/1999/xhtml">
    <head>
        [% INCLUDE '$lowCaseName/shared/_head.tt' %]
        <!-- import _head from Views/Shared -->
    </head>
    <body>
        <!-- CORE JQUERY SCRIPTS -->
        <script src="/assets/js/jquery-3.2.1.min.js"></script>
        <!-- BOOTSTRAP SCRIPTS  -->
        <script src="/assets/js/bootstrap.js"></script>
        <script src="/assets/js/multiple-select.js"></script>
        [% INCLUDE '$lowCaseName/shared/_header.tt' %]
        <!--import _header from Views/Shared-->
        [% INCLUDE '$lowCaseName/shared/_menu.tt' %]
        <!--import _menu from Views/Shared-->
        [% content %]
        <!--Content page-->
        [% INCLUDE '$lowCaseName/shared/_footer.tt' %]
        <!--import _footer from Views/Shared-->
    </body>
</html>
WRAPPER
writeFile( "$html_dir/root/$lowCaseName/_layout.tt", $wrapper );

my $errorPage = <<ERROR;
<!DOCTYPE html>
<div class="content-wrapper">
    <div class="container">
        <div class="row">
            <div class="col-md-9">
                <div class="row">
                    <div class="col-md-12">
                        <h2>Oops, we're having some troubles.</h2><br />
                    </div>
                </div>
                <div class="row">
                    <div class="col-md-12">
                        <p>Please, comeback later.</p>
                    </div>
                </div>
            </div>
            <div class="col-md-3">
                <img src="/assets/img/platypuslogo.png" style="width:800;height:600px;" />
            </div>
        </div>
    </div>
</div>
ERROR

writeFile( "$html_dir/root/$lowCaseName/errors.tt", $errorPage );

print $LOG "\nEditing root file\n";
writeFile( "$html_dir/lib/$libDirectoryWebsite/Controller/Root.pm", $rootContent );

#inicialize server project
#`./$nameProject/script/"$lowCaseName"_server.pl -r`;
print $LOG "Done\nTurn on the server with this command:\n./$html_dir/script/"
. $lowCaseName
. "_server.pl -r\n"
. "http://localhost:3000\n";
close($LOG);

`cp -r $html_dir "$standard_dir"/`;
`cp -r $services_dir "$standard_dir"/`;
`rm -rf $html_dir`;
`rm -rf $services_dir`;
exit;

###
#   Method used to write files
#   @param $filepath => path with the file to be write or edit
#   @param $content => content to be insert
#
sub writeFile {
    my ( $filepath, $content ) = @_;
    open( my $FILEHANDLER, ">:encoding(UTF-8)", $filepath )
        or die "Error opening file";

    #	binmode($FILEHANDLER, ":utf8");
    print $FILEHANDLER $content;
    close($FILEHANDLER);
}

###
#	Method used to read HTML file with the texts to be used on site
#	@param $file => path of the JSON file to be read
#	return data in SQL
#
sub readJSON {
    my ($file) = @_;
    open( my $FILEHANDLER, "<", $file );
    my $content = do { local $/; <$FILEHANDLER> };
    my $sql = "";
    $sql .= "\nINSERT INTO TEXTS(tag, value) VALUES (\"$1\", \"$2\");\n" while ( $content =~
        /"([\w\-\_]*)"\s*:\s*"([\w\s<>\/@.\-:;?+(),'=&ããàâáéêíóõú#|&~]*)"/gm
    );
    close($FILEHANDLER);
    return $sql;
}

=head2
Method used to get content of TCDB file
@param tcdb_file => filepath
return sql to be used
=cut

sub readTCDBFile {
    my ($tcdb_file) = @_;
    open( my $FILEHANDLER, "<", $tcdb_file );
    my $sql = "";
    while ( my $line = <$FILEHANDLER> ) {
        if ( $line =~ /^(\d\t[\w\/\s\-]*)[^\n]\v/gm ) {
            my $change = $1;
            $change =~ s/\t/\ /;
            $sql .= <<SQL;
            INSERT INTO TEXTS(tag, value) VALUES ("search-database-analyses-protein-code-search-by-transporter-class-option", "$change");
SQL
        }
        elsif ( $line =~ /(\d\.[a-zA-Z]\s[a-zA-Z.\s#&,:;\/\-+()'\[\]]*)\n/ ) {
            my $change = $1;
            $change =~ s/\t/\ /;
            chomp($change);
            $sql .= <<SQL;
            INSERT INTO TEXTS(tag, value) VALUES ("search-database-analyses-protein-code-search-by-transporter-subclass-option", "$change");
SQL
        }
    }
    close($FILEHANDLER);
    return $sql;
}

=head2
Method used to get code number of the product
@param subject_id
return list with code number and product
=cut

sub get_code_number_product {
    my $subject_id = shift;
    my $code_number;
    my $product;

    if ( $subject_id =~ m/\S+\|(\S+)\|(.*)/ ) {
        $code_number = $1;
        $product     = $2;
    }
    elsif ( $subject_id =~ m/(\S+)_(\S+) (.*)/ ) {
        $code_number = $2;
        $product     = $3;
    }
    elsif ( $subject_id =~ m/(\S+)/ ) {
        $code_number = $1;

        if ( $code_number =~ m/(\S+)\_\[(\S+)\_\[/ ) {
            $code_number = $1;
            $product     = "similar to " . $code_number;
        }
    }

    $product =~ s/^ //g;
    $product =~ s/ $//g;

    return ( $code_number, $product );
}

=head2 reverseComplement

Method used to return the reverse complement of a sequence

=cut

sub reverseComplement {
    my ($sequence) = @_;
    my $reverseComplement = reverse($sequence);
    $reverseComplement =~ tr/ACGTacgt/TGCAtgca/;
    return $reverseComplement;
}

=head2 formatSequence

Method used to format sequence

=cut

sub formatSequence {
    my $seq = shift;
    my $block = shift || 80;
    $seq =~ s/.{$block}/$&\n/gs;
    chomp $seq;
    return $seq;
}

=head2 verify_element

Method used to verify if element exists in list reference

=cut

sub verify_element {
    my ($element, $vector) = @_;
    if (scalar @$vector > 0) {
        my @cleanedVector = grep { defined $_ } @$vector;
        if (@cleanedVector) {
            my @array   = grep /\S/, @cleanedVector;
            my %params  = map { $_ => 1 } @array;

            if ( exists( $params{$element} ) ) {
                return 1;
            }
        }
    }
    return 0;

}
=head2

Method used to get filename by filepath

=cut

sub getFilenameByFilepath {
    my ($filepath) = @_;
    my $filename = "";
    if ( $filepath =~ /\/([\w\s\-_]+\.[\w\s\-_.]+)/g ) {
        $filename = $1;
    }
    return $filename;
}
=head1 NAME

report_html_db.pl - Generate a dynamic web page based on EGene2 database results.

=head1 DESCRIPTION

Responsible for generation of applications like website and services that allow users to access dynamic pages with the possibility to realize a complex query with the database of annotations created as a result of execution of pipelines by the platform EGene2, execute BLAST searches, and turn available annotation files and results.

=head1 SYNOPSIS

  $ Report_HTML_DB
  report_html_db.pl

=head1 AUTHOR

Wendel Hime Lino Castro

=head1 LICENSE

GNU General Public License v3.0

=head1 INSTALLATION

Using C<cpan>:

    $ cpan Report_HTML_DB

Manual install:

    $ perl Makefile.PL
    $ make
    $ make install

=cut
