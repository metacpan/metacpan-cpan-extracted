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
	component VARCHAR(2000),
	filepath VARCHAR(2000)
);

CREATE TABLE SEQUENCES(
	id INTEGER PRIMARY KEY NOT NULL,
	name VARCHAR(2000),
	filepath VARCHAR(2000)
);

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
        ("blast-database-option", "All genes", "PMN_genome_1"),
        ("blast-database-option", "Contigs", "PMN_genes_1"),
        ("blast-database-option", "Protein code", "PMN_prot_1"),
        ("blast-format-title", "Enter sequence below in <a href='http://puma.icb.usp.br/blast/docs/fasta.html'>FASTA</a> format", ""),
        ("blast-sequence-file-title", "Or load it from disk ", ""),
        ("blast-subsequence-title", "Set subsequence ", ""),
        ("blast-subsequence-value", "From:", "QUERY_FROM"),
        ("blast-subsequence-value", "To:", "QUERY_TO"),
        ("blast-search-options-title", "Search options", ""),
        ("blast-search-options-sequence-title", "The query sequence is <a href='http://puma.icb.usp.br/blast/docs/filtered.html'>filtered</a> for low complexity regions by default.", ""),
        ("blast-search-options-filter-title", "Filter:", "http://puma.icb.usp.br/blast/docs/newoptions.html#filter"),
        ("blast-search-options-filter-options", "Low complexity", "value='L' checked=''"),
        ("blast-search-options-filter-options", "Mask for lookup table only", "value='m'"),
        ("blast-search-options-expect", "<a href='http://puma.icb.usp.br/blast/docs/newoptions.html#expect'>Expect</a> (e.g. 1e-6)", ""),
        ("blast-search-options-matrix", "Matrix", "http://puma.icb.usp.br/blast/docs/matrix_info.html"),
        ("blast-search-options-matrix-options", "PAM30", "PAM30	 9	 1"),
        ("blast-search-options-matrix-options", "PAM70", "PAM70	 10	 1"),
        ("blast-search-options-matrix-options", "BLOSUM80", "BLOSUM80	 10	 1"),
        ("blast-search-options-matrix-options", "BLOSUM62", "BLOSUM62	 11	 1"),
        ("blast-search-options-matrix-options", "BLOSUM45", "BLOSUM45	 14	 2"),
        ("blast-search-options-alignment", "Perform ungapped alignment", ""),
        ("blast-search-options-query", "Query Genetic Codes (blastx only)", "http://puma.icb.usp.br/blast/docs/newoptions.html#gencodes"),
        ("blast-search-options-query-options", "Standard (1)", ""),
        ("blast-search-options-query-options", "Vertebrate Mitochondrial (2)", ""),
        ("blast-search-options-query-options", "Yeast Mitochondrial (3)", ""),
        ("blast-search-options-query-options", "Mold Mitochondrial; ... (4)", ""),
        ("blast-search-options-query-options", "Invertebrate Mitochondrial (5)", ""),
        ("blast-search-options-query-options", "Ciliate Nuclear; ... (6)", ""),
        ("blast-search-options-query-options", "Echinoderm Mitochondrial (9)", ""),
        ("blast-search-options-query-options", "Euplotid Nuclear (10)", ""),
        ("blast-search-options-query-options", "Bacterial (11)", ""),
        ("blast-search-options-query-options", "Alternative Yeast Nuclear (12)", ""),
        ("blast-search-options-query-options", "Ascidian Mitochondrial (13)", ""),
        ("blast-search-options-query-options", "Flatworm Mitochondrial (14)", ""),
        ("blast-search-options-query-options", "Blepharisma Macronuclear (15)", ""),
        ("blast-search-options-database", "Database Genetic Codes (tblast[nx] only)", "http://puma.icb.usp.br/blast/docs/newoptions.html#gencodes"),
        ("blast-search-options-database-options", "Standard (1)", ""),
        ("blast-search-options-database-options", "Vertebrate Mitochondrial (2)", ""),
        ("blast-search-options-database-options", "Yeast Mitochondrial (3)", ""),
        ("blast-search-options-database-options", "Mold Mitochondrial; ... (4)", ""),
        ("blast-search-options-database-options", "Invertebrate Mitochondrial (5)", ""),
        ("blast-search-options-database-options", "Ciliate Nuclear; ... (6)", ""),
        ("blast-search-options-database-options", "Echinoderm Mitochondrial (9)", ""),
        ("blast-search-options-database-options", "Euplotid Nuclear (10)", ""),
        ("blast-search-options-database-options", "Bacterial (11)", ""),
        ("blast-search-options-database-options", "Alternative Yeast Nuclear (12)", ""),
        ("blast-search-options-database-options", "Ascidian Mitochondrial (13)", ""),
        ("blast-search-options-database-options", "Flatworm Mitochondrial (14)", ""),
        ("blast-search-options-database-options", "Blepharisma Macronuclear (15)", ""),
        ("blast-search-options-frame-shift-penalty", "<a href='http://puma.icb.usp.br/blast/docs/oof_notation.html'>Frame shift penalty</a> for blastx ", ""),
        ("blast-search-options-frame-shift-penalty-options", "6", ""),
        ("blast-search-options-frame-shift-penalty-options", "7", ""),
        ("blast-search-options-frame-shift-penalty-options", "8", ""),
        ("blast-search-options-frame-shift-penalty-options", "9", ""),
        ("blast-search-options-frame-shift-penalty-options", "10", ""),
        ("blast-search-options-frame-shift-penalty-options", "11", ""),
        ("blast-search-options-frame-shift-penalty-options", "12", ""),
        ("blast-search-options-frame-shift-penalty-options", "13", ""),
        ("blast-search-options-frame-shift-penalty-options", "14", ""),
        ("blast-search-options-frame-shift-penalty-options", "15", ""),
        ("blast-search-options-frame-shift-penalty-options", "16", ""),
        ("blast-search-options-frame-shift-penalty-options", "17", ""),
        ("blast-search-options-frame-shift-penalty-options", "18", ""),
        ("blast-search-options-frame-shift-penalty-options", "19", ""),
        ("blast-search-options-frame-shift-penalty-options", "20", ""),
        ("blast-search-options-frame-shift-penalty-options", "25", ""),
        ("blast-search-options-frame-shift-penalty-options", "30", ""),
        ("blast-search-options-frame-shift-penalty-options", "50", ""),
        ("blast-search-options-frame-shift-penalty-options", "1000", ""),
        ("blast-search-options-other-advanced-options", "Other advanced options:", "http://puma.icb.usp.br/blast/docs/full_options.html"),
        ("blast-display-options-title", "Display options", ""),
        ("blast-display-options-graphical-overview", "Graphical Overview", "http://puma.icb.usp.br/blast/docs/newoptions.html#graphical-overview"),
        ("blast-display-options-alignment-view-title", "Alignment view", "http://puma.icb.usp.br/blast/docs/options.html#alignmentviews"),
        ("blast-display-options-alignment-view-options", "Pairwise", "0"),
        ("blast-display-options-alignment-view-options", "master-slave with identities", "1"),
        ("blast-display-options-alignment-view-options", "master-slave without identities", "2"),
        ("blast-display-options-alignment-view-options", "flat master-slave with identities", "3"),
        ("blast-display-options-alignment-view-options", "flat master-slave without identities", "4"),
        ("blast-display-options-alignment-view-options", "BLAST XML", "7"),
        ("blast-display-options-alignment-view-options", "Hit Table", "9"),
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
        ("blast-display-options-color-schema", "Color schema", "http://puma.icb.usp.br/blast/docs/color_schema.html"),
        ("blast-display-options-color-schema-options", "No color schema", "selected value='0'"),
        ("blast-display-options-color-schema-options", "Color schema 1", "value='1'"),
        ("blast-display-options-color-schema-options", "Color schema 2", "value='2'"),
        ("blast-display-options-color-schema-options", "Color schema 3", "value='3'"),
        ("blast-display-options-color-schema-options", "Color schema 4", "value='4'"),
        ("blast-display-options-color-schema-options", "Color schema 5", "value='5'"),
        ("blast-display-options-color-schema-options", "Color schema 6", "value='6'"),
        ("blast-button", "Clear sequence", "onclick=""MainBlastForm.SEQUENCE.value = '';MainBlastForm.QUERY_FROM.value = '';MainBlastForm.QUERY_TO.value = '';MainBlastForm.SEQUENCE.focus();"" type=""button"" class='btn btn-default' "),
        ("blast-button", "Search", "type='submit' class='btn btn-primary' "),
        ("search-database-form-title", "Search based on sequences or annotations", ""),
        ("search-database-gene-ids-descriptions-title", "Protein-sequence and gene IDs", ""),
        ("search-database-gene-ids-descriptions-tab", "<a href='#geneIdentifier' data-toggle='tab'>Gene identifier</a>", "class='active'"),
        ("search-database-gene-ids-descriptions-tab", "<a href='#geneDescription' data-toggle='tab'>Gene description</a>", ""),
        ("search-database-gene-ids-descriptions-gene-id", "Gene ID: ", ""),
        ("search-database-gene-ids-descriptions-gene-description", "Description: ", ""),
        ("search-database-gene-ids-descriptions-gene-excluding", "Excluding: ", ""),
        ("search-database-gene-ids-descriptions-gene-match-all", "Match all terms", ""),
        ("search-database-analyses-protein-code-title", "Analyses of protein-coding genes", ""),
        ("search-database-analyses-protein-code-limit", "Limit by term(s) in gene description(optional): ", ""),
        ("search-database-analyses-protein-code-excluding", "Excluding: ", ""),
        ("search-database-analyses-protein-code-tab", "RPSBLAST", "#rpsBlast"),
        ("search-database-analyses-protein-code-tab", "KEGG", "#kegg"),
        ("search-database-analyses-protein-code-tab", "Orthology analysis (eggNOG)", "#orthologyAnalysis"),
        ("search-database-analyses-protein-code-tab", "Interpro", "#interpro"),
        
        
        ("search-database-analyses-protein-code-search-by-sequence", "Search by sequence identifier of match:", ""),
        ("search-database-analyses-protein-code-search-by-description", "Or by description of match:", ""),
        
        ("search-database-analyses-protein-code-not-containing-classification-rpsblast", " not containing RPSBLAST matches", ""),
        
        ("search-database-dna-based-analyses-title", "DNA-based analyses", ""),
        ("search-database-dna-based-analyses-tab", "Contigs", "#contigs"),
        ("search-database-dna-based-analyses-tab", "Tandem repeats", "#tandemRepeats"),
        ("search-database-dna-based-analyses-tab", "Other non-coding RNAs", "#otherNonCodingRNAs"),
        ("search-database-dna-based-analyses-tab", "Transcriptional terminators", "#transcriptionalTerminators"),
        ("search-database-dna-based-analyses-tab", "Horizontal gene transfers", "#horizontalGeneTransfers"),
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
        ("global-analyses-go-terms-mapping", "GO terms mapping", ""),
        ("global-analyses-expansible-tree", "Expansible tree", "data/GO_mapping.xml"),
        ("global-analyses-table-ontologies", "Table of ontologies", "data/GO_mapping.html"),
        ("global-analyses-go-terms-mapping-footer", "NOTE: Please use Mozilla Firefox, Safari or Opera browser to visualize the expansible trees. If you are using Internet Explorer, please use the links to ""Table of ontologies"" to visualize the results.", ""),
        ("global-analyses-eggNOG", "eggNOG", ""),
        ("global-analyses-orthology-analysis-classes", "Orthology analysis by evolutionary genealogy of genes: Non-supervised Orthologous Groups", "data/MN7_eggnog_report/classes.html"),
        ("global-analyses-kegg-pathways", "KEGG Pathways", ""),
        ("global-analyses-kegg-report", "Enzyme by enzyme report of KEGG results", "data/MN7_kegg_report/classes.html"),
        ("global-analyses-kegg-report-page", "Map by map report of KEGG results", "data/MN7_kegg_global/html_page/classes.html"),
        ("global-analyses-comparative-metabolic-reconstruction", "Comparative Metabolic Reconstruction", ""),
        ("global-analyses-comparative-metabolic-reconstruction-topics", "<i>P. luminescens</i> MN7 versus <i>P. asymbiotica</i> ATCC43949</a><br /> (in yellow or red, enzymes found only in either MN7 or <i>P. asymbiotica</i>, respectively; in green, those found in both)", "data/MN7_X_Pasym/html_page/classes.html"),
        ("global-analyses-comparative-metabolic-reconstruction-topics", "<i>P. luminescens</i> MN7 versus <i>P. luminescens</i> TT01</a><br /> (in yellow or dark blue, enzymes found only in either MN7 or TT01, respectively; in green, those found in both)", "data/MN7_X_TT01/html_page/classes.html"),
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
        
			INSERT INTO TEXTS(tag, value) VALUES ("_comment", "This is a example of the texts that will be used on site,
					the first value inside of pair of quotes is the tag name to be referenced,
					after the first value, comes colon(:) to separate the tag name of value,
					the second value inside of pair of quotes is the value to be used,
					and in the end use comma to separate the pair of tag and value");
			INSERT INTO TEXTS(tag, value) VALUES ("_commentHeader1", "Content of the header");
			INSERT INTO TEXTS(tag, value) VALUES ("header-email", "<strong>Email:</strong> example@example.com");
			INSERT INTO TEXTS(tag, value) VALUES ("header-support", "<strong>Support:</strong> +11 (11) 11111-1111");
			INSERT INTO TEXTS(tag, value) VALUES ("_commentHeader2", "End header");
			INSERT INTO TEXTS(tag, value) VALUES ("_commentHome1", "Content of the home page");
			INSERT INTO TEXTS(tag, value) VALUES ("home-title", "Information title");
			INSERT INTO TEXTS(tag, value) VALUES ("home-value", "Lorem ipsum dolor sit amet, consectetur adipiscing elit. Vestibulum sodales quis enim nec vehicula. Nunc cursus sem sem. Maecenas vitae euismod leo. Sed tristique, nisl et mollis laoreet, eros orci tincidunt neque, vulputate convallis quam velit in mauris. Nulla ut dapibus nisl. Ut placerat, arcu et convallis ultrices, metus metus tempus tortor, vel aliquam sem neque sed quam. Mauris vel accumsan ante.");
			INSERT INTO TEXTS(tag, value) VALUES ("_commentHome2", "End home");
			INSERT INTO TEXTS(tag, value) VALUES ("_commentHelp1", "Content of the help page");
			INSERT INTO TEXTS(tag, value) VALUES ("help-questions-feedback", "Questions and feedback");
			INSERT INTO TEXTS(tag, value) VALUES ("help-questions-feedback-1-paragraphe", "If you have any question or would like to communicate any error, please contact us: ");
			INSERT INTO TEXTS(tag, value) VALUES ("help-questions-feedback-2-list-1", "Carlos E. Winter - <a href='mailto:cewinter@usp.br'>cewinter@usp.br</a>");
			INSERT INTO TEXTS(tag, value) VALUES ("help-questions-feedback-2-list-2", "Arthur Gruber - <a href='mailto:argruber@usp.br'>argruber@usp.br</a>");
			INSERT INTO TEXTS(tag, value) VALUES ("_commentHelp2", "End Help");
			INSERT INTO TEXTS(tag, value) VALUES ("_commentAbout1", "Content of the about page");
			INSERT INTO TEXTS(tag, value) VALUES ("about-table-content-1", "Project");
			INSERT INTO TEXTS(tag, value) VALUES ("about_1-0-paragraph", "Entomopathogenic nematodes (EPNs) live in symbiosis with specific enterobacteria. EPNs have been used for decades to control agricultural pests in the United States and Europe. Bacteria of the genus <i>Photorhabdus</i> are symbionts of EPNs of the genus <i>Heterorhabditis</i>. Recently, <i>Heterorhabditis bacteriophora</i> and its symbiont, <i>Photorhabdus luminescens laumondii</i>, were considered models for the study of host-pathogen interactions. The genome of <i>P. luminescens laumondii</i> TT01 was completely sequenced a few years ago, and it was discovered that six percent of its genes encode enzymes involved in production of secondary metabolites.");
			INSERT INTO TEXTS(tag, value) VALUES ("about_1-1-paragraph", "One of the aims of our laboratory is the study of molecular aspects of Brazilian EPN isolates and their bacterial symbionts. Strains of two species of <i>Heterorhabditis</i> (<i>H. baujardi</i> and <i>H. indica</i>), obtained from the Amazon region, were molecularly characterized by us. The bacteria of <i>H. baujardi</i> (strain LPP7) were grown in isolation. Phylogenetic analysis of the 16 S rRNA sequence of this isolate (called MN7) shows that it can be part of the same clade as <i>P. asymbiotica</i>, a species isolated from wounds in humans in Australia and the United States. Recent data from our laboratory showed that MN7 secretes secondary metabolites of biotechnological interest, plus a protease similar to that found in other species of the genus.");
			INSERT INTO TEXTS(tag, value) VALUES ("about_1-2-paragraph", "The aim of this project is the construction of a genome scaffold of <i>Photorhabdus luminescens</i> MN7 through next generation sequencing. This project aims to better understand the biology and evolution of bacteria of the genus <i>Photorhabdus</i> and make an inventory, as complete as possible, of the genes involved in the production of secondary metabolites and toxins that mediate symbiotic relationships with the nematode, the insect, and other species of nematodes. This project will be integrated with other projects of the laboratory studying entomopathogenic nematodes and their bacteria and will generate important data for researchers working on these bacteria in other countries.");
			INSERT INTO TEXTS(tag, value) VALUES ("about-table-content-2", "Project members");
			INSERT INTO TEXTS(tag, value) VALUES ("about_0-title", "Project coordinators");
			INSERT INTO TEXTS(tag, value) VALUES ("about_1-list-1", "<a href='mailto:cewinter@usp.br'>Carlos E. Winter</a>, Ph.D. - Associate Professor, University of São Paulo");
			INSERT INTO TEXTS(tag, value) VALUES ("about_1-list-2", "<a href='mailto:argruber@usp.br'>Arthur Gruber</a>, D.V.M., Ph.D. - Associate Professor, University of São Paulo");
			INSERT INTO TEXTS(tag, value) VALUES ("about_2-0-title", "Project coordinators");
			INSERT INTO TEXTS(tag, value) VALUES ("about_2-1-list-1", "<a href='mailto:cewinter@usp.br'>Carlos E. Winter</a>, Ph.D. - Associate Professor, University of São Paulo");
			INSERT INTO TEXTS(tag, value) VALUES ("about_2-1-list-2", "<a href='mailto:argruber@usp.br'>Arthur Gruber</a>, D.V.M., Ph.D. - Associate Professor, University of São Paulo");
			INSERT INTO TEXTS(tag, value) VALUES ("about_2-2-title", "Collaborator");
			INSERT INTO TEXTS(tag, value) VALUES ("about_2-3-list-1", "<a href='mailto:alan@ime.usp.br'>Alan M. Durham</a>, Ph.D., Assistant Professor, University of São Paulo");
			INSERT INTO TEXTS(tag, value) VALUES ("about_2-4-title", "Members");
			INSERT INTO TEXTS(tag, value) VALUES ("about_2-5-list-1", "João Marcelo P. Alves, Ph.D.");
			INSERT INTO TEXTS(tag, value) VALUES ("about_2-5-list-2", "Liliane Santana, MSc student");
			INSERT INTO TEXTS(tag, value) VALUES ("about_2-5-list-3", "Maira Rodrigues C. Neves, MSc student");
			INSERT INTO TEXTS(tag, value) VALUES ("about_2-5-list-4", "Carolina Rossi, MSc student");
			INSERT INTO TEXTS(tag, value) VALUES ("about_2-5-list-5", "Rodrigo Hashimoto, undergraduate student");
			INSERT INTO TEXTS(tag, value) VALUES ("about-table-content-3", "Organism");
			INSERT INTO TEXTS(tag, value) VALUES ("about_3-0-title", "<i>Photorhabdus</i> biology");
			INSERT INTO TEXTS(tag, value) VALUES ("about_3-1-paragraph", "Enterobacteria of the genus <i>Photorhabdus</i> are symbiotic partners of entomopathogenic nematodes belonging to the genus <i>Heterorhabditis</i>. Both members of this unusual symbiosis are able to efficiently kill any soil dwelling arthropod and are used for agronomic insect pest control. The bacteria serve two purposes after the infective juvenile of <i>Heterorhabditis</i> sp. invades the insect hemolymph; turning off the insect immune response and serving as food for the nematode partner development. The insect killing is attained by a series of mechanisms that go from the secretion of hydrolytic enzymes and very sophisticated protein toxins to the production of secondary metabolites. Both insect killing and nematode symbiosis are dependent on the bacterial colonization through the production of fimbria and adhesin molecules that mediate the production of a biofilm inside their hosts.");
			INSERT INTO TEXTS(tag, value) VALUES ("about_3-2-title", "The genomes");
			INSERT INTO TEXTS(tag, value) VALUES ("about_3-3-paragraph", "<i>P. luminescens luminescens</i> MN7 is the first Neotropical entomopathogenic bacterium to have had its genome sequenced and annotated. Its nematode is <i>H. baujardi</i> strain LPP7, previously isolated from the soil of the Amazon forest in Monte Negro (RO), Brazil.");
			INSERT INTO TEXTS(tag, value) VALUES ("about_3-4-paragraph", "The genomes of two <i>Photorhabdus</i> have been completely sequenced and annotated: <a href='http://www.ncbi.nlm.nih.gov/genome/1123'><i>P. luminescens laumondii</i> strain TTO1</a> and <a href='http://www.ncbi.nlm.nih.gov/genome/1768'><i>P. asymbiotica</i> strain ATCC43949</a>. Their genomes are roughly 5 to 5.6 Mb long and contain approximately 4,400 to 4,700 ORFs. <i>Steinernema</i>, another genus of entomopathogenic nematode, also contains an enterobacterial partner belonging to the genus <i>Xenorhabdus</i>. The genomes of <a href='http://www.ncbi.nlm.nih.gov/genome/1227'><i>X. nematophila</i> ATCC19061</a> and <a href='http://www.ncbi.nlm.nih.gov/genome/1226'><i>X. bovienii</i> SS-2004</a> have also been sequenced. ");
			INSERT INTO TEXTS(tag, value) VALUES ("about-table-content-4", "Funding");
			INSERT INTO TEXTS(tag, value) VALUES ("about_4-0-title", "Funding");
			INSERT INTO TEXTS(tag, value) VALUES ("about_4-1-paragraph", "<b>PhotoBase</b> has been developed with support from <a href='http://www.fapesp.br/en/'>FAPESP</a> (São Paulo Research Foundation, grants <b>#2010/51973-0</b> and <b>#2012/20945-7</b>) and <a href='http://www.cnpq.br/english/cnpq/index.htm'>CNPq</a> (National Council for Scientific and Technological Development).");
			INSERT INTO TEXTS(tag, value) VALUES ("about_4-2-paragraph", "The opinions, hypotheses, and conclusions or recommendations present in this website are the sole responsibility of its authors and do not necessarily reflect the views of FAPESP.");
			INSERT INTO TEXTS(tag, value) VALUES ("about_4-3-title", "Reference");
			INSERT INTO TEXTS(tag, value) VALUES ("about_4-4-paragraph", "If you use this database, please cite this page as follows:");
			INSERT INTO TEXTS(tag, value) VALUES ("about_4-5-list-1", "Winter, C.E. &amp; Gruber, A. (2013) The <i>Photorhabdus luminescens</i> MN7 genome database, version 1.0: http://www.coccidia.icb.usp.br/PMN.");
			INSERT INTO TEXTS(tag, value) VALUES ("_commentAbout2", "End about page");
			INSERT INTO TEXTS(tag, value) VALUES ("_commentFooter1", "Content of the footer");
			INSERT INTO TEXTS(tag, value) VALUES ("footer", "&copy; 2016 YourCompany | By : Name");
			INSERT INTO TEXTS(tag, value) VALUES ("_commentFooter2", "End footer");
			INSERT INTO TEXTS(tag, value) VALUES ("_COMMENT-HOW-TO-ADD-FILE-DOWNLOADS", "All file download, starts in the key with 'files-' after that, comes the tag and like value the filepath. 
	The links should be represented with the difference on the value anchor");
			INSERT INTO TEXTS(tag, value) VALUES ("downloads-genes-links-1", "<a href='/DownloadFile?type=ag'>All genes (protein-coding, ribosomal RNA, transfer RNA, and non-coding RNA)</a>");
			INSERT INTO FILES(tag, filepath) VALUES ("ag", "/home/wendelhlc/git/report_html_db/report_html_db/TESTE/root/orfs_nt/Bacteria_upload_CDS_NT.fasta");
			INSERT INTO TEXTS(tag, value) VALUES ("downloads-genes-links-2", "<a href='/DownloadFile?type=pro'>Protein-coding genes only</a>");
			INSERT INTO FILES(tag, filepath) VALUES ("pro", "/home/wendelhlc/git/report_html_db/report_html_db/TESTE/root/orfs_aa/Bacteria_upload_CDS_AA.fasta");
			INSERT INTO TEXTS(tag, value) VALUES ("downloads-genes-links-3", "<a href='/DownloadFile?type=rrg'>Ribosomal RNA genes only</a>");
			INSERT INTO FILES(tag, filepath) VALUES ("rrg", "/home/wendelhlc/git/report_html_db/report_html_db/TESTE/root/rnammer_dir/Bacteria_rnammer.fasta");
			INSERT INTO TEXTS(tag, value) VALUES ("downloads-genes-links-4", "<a href='/DownloadFile?type=trg'>Transfer RNA genes only</a>");
			INSERT INTO FILES(tag, filepath) VALUES ("trg", "/home/wendelhlc/git/report_html_db/report_html_db/TESTE/root/trna_dir/Bacteria_trna.txt");
			INSERT INTO TEXTS(tag, value) VALUES ("downloads-genes-links-5", "<a href='/DownloadFile?type=oncg'>Other non-coding RNA genes only table</a>");
			INSERT INTO FILES(tag, filepath) VALUES ("oncg", "/home/wendelhlc/git/report_html_db/report_html_db/TESTE/root/infernal_dir/infernal.txt_Bacteria");
			INSERT INTO TEXTS(tag, value) VALUES ("downloads-other-sequences-links-1", "<a href='/DownloadFile?type=ac'>Get all contigs</a>");
			INSERT INTO FILES(tag, filepath) VALUES ("ac", "/home/wendelhlc/git/report_html_db/report_html_db/TESTE/root/seq/Bacteria_upload.fasta");
			INSERT INTO TEXTS(tag, value) VALUES ("downloads-other-sequences-links-2", "<a href='/DownloadFile?type=tt'>All transcriptional terminators (predicted by TransTermHP)</a>");
			INSERT INTO FILES(tag, filepath) VALUES ("tt", "/home/wendelhlc/git/report_html_db/report_html_db/TESTE/root/transterm_dir/Bacteria.txt");
			INSERT INTO TEXTS(tag, value) VALUES ("search-database-analyses-protein-code-search-by-transporter-class-option", "1	Channels/Pore");
			INSERT INTO TEXTS(tag, value) VALUES ("search-database-analyses-protein-code-search-by-transporter-subclass-option", "1.A	&#945;-Type Channels
");
			INSERT INTO TEXTS(tag, value) VALUES ("search-database-analyses-protein-code-search-by-transporter-subclass-option", "1.A.1	The Voltage-gated Ion Channel (VIC) Superfamily 
");
			INSERT INTO TEXTS(tag, value) VALUES ("search-database-analyses-protein-code-search-by-transporter-subclass-option", "1.A.2	Inward Rectifier K+ Channel (IRK-C) Family
");
			INSERT INTO TEXTS(tag, value) VALUES ("search-database-analyses-protein-code-search-by-transporter-subclass-option", "1.A.3	The Ryanodine-Inositol 1,4,5-triphosphate Receptor Ca2+ Channel (RIR-CaC) Family
");
			INSERT INTO TEXTS(tag, value) VALUES ("search-database-analyses-protein-code-search-by-transporter-subclass-option", "1.A.4	The Transient Receptor Potential Ca2+ Channel (TRP-CC) Family
");
			INSERT INTO TEXTS(tag, value) VALUES ("search-database-analyses-protein-code-search-by-transporter-subclass-option", "1.A.5	The Polycystin Cation Channel (PCC) Family
");
			INSERT INTO TEXTS(tag, value) VALUES ("search-database-analyses-protein-code-search-by-transporter-subclass-option", "1.A.6	The Epithelial Na+ Channel (ENaC) Family
");
			INSERT INTO TEXTS(tag, value) VALUES ("search-database-analyses-protein-code-search-by-transporter-subclass-option", "1.A.7	The ATP-gated P2X Receptor Cation Channel (P2X Receptor) Family
");
			INSERT INTO TEXTS(tag, value) VALUES ("search-database-analyses-protein-code-search-by-transporter-subclass-option", "1.A.8	The Major Intrinsic Protein (MIP) Family
");
			INSERT INTO TEXTS(tag, value) VALUES ("search-database-analyses-protein-code-search-by-transporter-subclass-option", "1.A.9	The Neurotransmitter Receptor, Cys loop, Ligand-gated Ion Channel (LIC) Family
");
			INSERT INTO TEXTS(tag, value) VALUES ("search-database-analyses-protein-code-search-by-transporter-subclass-option", "1.A.10	The Glutamate-gated Ion Channel (GIC) Family of Neurotransmitter Receptors
");
			INSERT INTO TEXTS(tag, value) VALUES ("search-database-analyses-protein-code-search-by-transporter-subclass-option", "1.A.11	The Ammonia Transporter Channel (Amt) Family
");
			INSERT INTO TEXTS(tag, value) VALUES ("search-database-analyses-protein-code-search-by-transporter-subclass-option", "1.A.12	The Intracellular Chloride Channel (CLIC) Family
");
			INSERT INTO TEXTS(tag, value) VALUES ("search-database-analyses-protein-code-search-by-transporter-subclass-option", "1.A.13	The Epithelial Chloride Channel (E-ClC) Family
");
			INSERT INTO TEXTS(tag, value) VALUES ("search-database-analyses-protein-code-search-by-transporter-subclass-option", "1.A.14	The Testis-Enhanced Gene Transfer (TEGT) Family
");
			INSERT INTO TEXTS(tag, value) VALUES ("search-database-analyses-protein-code-search-by-transporter-subclass-option", "1.A.15	The Non-selective Cation Channel-2 (NSCC2) Family
");
			INSERT INTO TEXTS(tag, value) VALUES ("search-database-analyses-protein-code-search-by-transporter-subclass-option", "1.A.16	The Formate-Nitrite Transporter (FNT) Family
");
			INSERT INTO TEXTS(tag, value) VALUES ("search-database-analyses-protein-code-search-by-transporter-subclass-option", "1.A.17	The Calcium-Dependent Chloride Channel (Ca-ClC) Family
");
			INSERT INTO TEXTS(tag, value) VALUES ("search-database-analyses-protein-code-search-by-transporter-subclass-option", "1.A.18	The Chloroplast Envelope Anion Channel-forming Tic110 (Tic110) Family
");
			INSERT INTO TEXTS(tag, value) VALUES ("search-database-analyses-protein-code-search-by-transporter-subclass-option", "1.A.19	The Type A Influenza Virus Matrix-2 Channel (M2-C) Family
");
			INSERT INTO TEXTS(tag, value) VALUES ("search-database-analyses-protein-code-search-by-transporter-subclass-option", "1.A.20	The BCL2/Adenovirus E1B-interacting Protein 3 (BNip3) Family
");
			INSERT INTO TEXTS(tag, value) VALUES ("search-database-analyses-protein-code-search-by-transporter-subclass-option", "1.A.21	The Bcl-2 (Bcl-2) Family
");
			INSERT INTO TEXTS(tag, value) VALUES ("search-database-analyses-protein-code-search-by-transporter-subclass-option", "1.A.22	The Large Conductance Mechanosensitive Ion Channel (MscL) Family
");
			INSERT INTO TEXTS(tag, value) VALUES ("search-database-analyses-protein-code-search-by-transporter-subclass-option", "1.A.23	The Small Conductance Mechanosensitive Ion Channel (MscS) Family
");
			INSERT INTO TEXTS(tag, value) VALUES ("search-database-analyses-protein-code-search-by-transporter-subclass-option", "1.A.24	The Gap Junction-forming Connexin (Connexin) Family
");
			INSERT INTO TEXTS(tag, value) VALUES ("search-database-analyses-protein-code-search-by-transporter-subclass-option", "1.A.25	The Gap Junction-forming Innexin (Innexin) Family
");
			INSERT INTO TEXTS(tag, value) VALUES ("search-database-analyses-protein-code-search-by-transporter-subclass-option", "1.A.26	The Mg2+ Transporter-E (MgtE) Family
");
			INSERT INTO TEXTS(tag, value) VALUES ("search-database-analyses-protein-code-search-by-transporter-subclass-option", "1.A.27	The Phospholemman (PLM) Family
");
			INSERT INTO TEXTS(tag, value) VALUES ("search-database-analyses-protein-code-search-by-transporter-subclass-option", "1.A.28	The Urea Transporter (UT) Family
");
			INSERT INTO TEXTS(tag, value) VALUES ("search-database-analyses-protein-code-search-by-transporter-subclass-option", "1.A.29	The Urea/Amide Channel (UAC) Family
");
			INSERT INTO TEXTS(tag, value) VALUES ("search-database-analyses-protein-code-search-by-transporter-subclass-option", "1.A.30	The H+- or Na+-translocating Bacterial Flagellar Motor/ExbBD Outer Membrane Transport Energizer (Mot/Exb) Superfamily
");
			INSERT INTO TEXTS(tag, value) VALUES ("search-database-analyses-protein-code-search-by-transporter-subclass-option", "1.A.31	The Annexin (Annexin) Family
");
			INSERT INTO TEXTS(tag, value) VALUES ("search-database-analyses-protein-code-search-by-transporter-subclass-option", "1.A.32	The Type B Influenza Virus NB Channel (NB-C) Family
");
			INSERT INTO TEXTS(tag, value) VALUES ("search-database-analyses-protein-code-search-by-transporter-subclass-option", "1.A.33	The Cation Channel-forming Heat Shock Protein-70 (Hsp70) Family
");
			INSERT INTO TEXTS(tag, value) VALUES ("search-database-analyses-protein-code-search-by-transporter-subclass-option", "1.A.34	1.A.34 The Bacillus Gap Junction-like Channel-forming Complex (GJ-CC) Family
");
			INSERT INTO TEXTS(tag, value) VALUES ("search-database-analyses-protein-code-search-by-transporter-subclass-option", "1.A.35	The CorA Metal Ion Transporter (MIT) Family
");
			INSERT INTO TEXTS(tag, value) VALUES ("search-database-analyses-protein-code-search-by-transporter-subclass-option", "1.A.36	The Intracellular Chloride Channel (ICC) Family
");
			INSERT INTO TEXTS(tag, value) VALUES ("search-database-analyses-protein-code-search-by-transporter-subclass-option", "1.A.37	The CD20 Ca2+ Channel (CD20) Family
");
			INSERT INTO TEXTS(tag, value) VALUES ("search-database-analyses-protein-code-search-by-transporter-subclass-option", "1.A.38	The Golgi pH Regulator (GPHR) Family
");
			INSERT INTO TEXTS(tag, value) VALUES ("search-database-analyses-protein-code-search-by-transporter-subclass-option", "1.A.39	The Type C Influenza Virus CM2 Channel (CM2-C) Family
");
			INSERT INTO TEXTS(tag, value) VALUES ("search-database-analyses-protein-code-search-by-transporter-subclass-option", "1.A.40	The Human Immunodeficiency Virus Type I, HIV-1 (Retrovirdiac) Vpu Channel (Vpu-C) Family
");
			INSERT INTO TEXTS(tag, value) VALUES ("search-database-analyses-protein-code-search-by-transporter-subclass-option", "1.A.41	The Avian Reovirus p10 Viroporin (p10) Family
");
			INSERT INTO TEXTS(tag, value) VALUES ("search-database-analyses-protein-code-search-by-transporter-subclass-option", "1.A.42	The HIV Viral Protein R (Vpr) Family
");
			INSERT INTO TEXTS(tag, value) VALUES ("search-database-analyses-protein-code-search-by-transporter-subclass-option", "1.A.43	The PRD1 Phage DNA Delivery (PRD1-DD)  Family
");
			INSERT INTO TEXTS(tag, value) VALUES ("search-database-analyses-protein-code-search-by-transporter-subclass-option", "1.A.44	The Pore-forming Tail Tip pb2 Protein of Phage T5 (T5-pb2) Family
");
			INSERT INTO TEXTS(tag, value) VALUES ("search-database-analyses-protein-code-search-by-transporter-subclass-option", "1.A.45	The Phage P22 Injectisome (P22 Injectisome) Family
");
			INSERT INTO TEXTS(tag, value) VALUES ("search-database-analyses-protein-code-search-by-transporter-subclass-option", "1.A.46	The Anion Channel-forming Bestrophin (Bestrophin) Family
");
			INSERT INTO TEXTS(tag, value) VALUES ("search-database-analyses-protein-code-search-by-transporter-subclass-option", "1.A.47	The Nucleotide-sensitive Anion-selective Channel, ICln (ICln) Family
");
			INSERT INTO TEXTS(tag, value) VALUES ("search-database-analyses-protein-code-search-by-transporter-subclass-option", "1.A.48	The Anion Channel Tweety (Tweety) Family
");
			INSERT INTO TEXTS(tag, value) VALUES ("search-database-analyses-protein-code-search-by-transporter-subclass-option", "1.A.49	The Mitochondrial Ca2+ Uniport Channel (MICC) Family
");
			INSERT INTO TEXTS(tag, value) VALUES ("search-database-analyses-protein-code-search-by-transporter-subclass-option", "1.A.50	The Phospholamban (Ca2+-channel and Ca2+-ATPase Regulator) (PLB) Family
");
			INSERT INTO TEXTS(tag, value) VALUES ("search-database-analyses-protein-code-search-by-transporter-subclass-option", "1.A.51	The Voltage-gated Proton Channel (VPC) Family
");
			INSERT INTO TEXTS(tag, value) VALUES ("search-database-analyses-protein-code-search-by-transporter-subclass-option", "1.A.52	The Ca2+ Release-activated Ca2+ (CRAC) Channel (CRAC-C) Family
");
			INSERT INTO TEXTS(tag, value) VALUES ("search-database-analyses-protein-code-search-by-transporter-subclass-option", "1.A.53	The Hepatitis C Virus P7 Viroporin Cation-selective Channel (HCV-P7) Family
");
			INSERT INTO TEXTS(tag, value) VALUES ("search-database-analyses-protein-code-search-by-transporter-subclass-option", "1.A.54	The Presenilin ER Ca2+ Leak Channel (Presenilin) Family
");
			INSERT INTO TEXTS(tag, value) VALUES ("search-database-analyses-protein-code-search-by-transporter-subclass-option", "1.A.55	The Synaptic Vesicle-Associated Ca2+ Channel, Flower (Flower or Cg6151-p) Family
");
			INSERT INTO TEXTS(tag, value) VALUES ("search-database-analyses-protein-code-search-by-transporter-subclass-option", "1.A.56	The Copper Transporter (Ctr) Family
");
			INSERT INTO TEXTS(tag, value) VALUES ("search-database-analyses-protein-code-search-by-transporter-subclass-option", "1.A.57	The Human SARS Caronavirus Viroporin (SARS-VP)
");
			INSERT INTO TEXTS(tag, value) VALUES ("search-database-analyses-protein-code-search-by-transporter-subclass-option", "1.A.58	The Type B Influenza Virus Matrix Protein 2 (BM2-C) Family
");
			INSERT INTO TEXTS(tag, value) VALUES ("search-database-analyses-protein-code-search-by-transporter-subclass-option", "1.A.59	The Bursal Disease Virus Pore-Forming Peptide, Pep46 (Pep46) Family
");
			INSERT INTO TEXTS(tag, value) VALUES ("search-database-analyses-protein-code-search-by-transporter-subclass-option", "1.A.60	The Mammalian Reovirus Pre-forming Peptide, Mu-1 (Mu-1) Family
");
			INSERT INTO TEXTS(tag, value) VALUES ("search-database-analyses-protein-code-search-by-transporter-subclass-option", "1.A.61	The Insect Nodavirus Channel-forming Chain F (Gamma-Peptide) Family
");
			INSERT INTO TEXTS(tag, value) VALUES ("search-database-analyses-protein-code-search-by-transporter-subclass-option", "1.A.62	The Homotrimeric Cation Channel (TRIC) Family
");
			INSERT INTO TEXTS(tag, value) VALUES ("search-database-analyses-protein-code-search-by-transporter-subclass-option", "1.A.63	The Ignicoccus Outer Membrane &#945;-helical Porin Family
");
			INSERT INTO TEXTS(tag, value) VALUES ("search-database-analyses-protein-code-search-by-transporter-subclass-option", "1.A.64	The Plasmolipin (Plasmolipin) Family
");
			INSERT INTO TEXTS(tag, value) VALUES ("search-database-analyses-protein-code-search-by-transporter-subclass-option", "1.A.65	The Coronavirus Viroporin E Protein (Viroporin E) Family
");
			INSERT INTO TEXTS(tag, value) VALUES ("search-database-analyses-protein-code-search-by-transporter-subclass-option", "1.A.66	The Pardaxin (Pardaxin) Family
");
			INSERT INTO TEXTS(tag, value) VALUES ("search-database-analyses-protein-code-search-by-transporter-subclass-option", "1.A.67	The Membrane Mg2+ Transporter (MMgT) Family 
");
			INSERT INTO TEXTS(tag, value) VALUES ("search-database-analyses-protein-code-search-by-transporter-subclass-option", "1.A.68	The Viral Small Hydrophobic Protein (V-SHP) Family
");
			INSERT INTO TEXTS(tag, value) VALUES ("search-database-analyses-protein-code-search-by-transporter-subclass-option", "1.A.69	The Heteromeric Odorant Receptor Channel (HORC) Family
");
			INSERT INTO TEXTS(tag, value) VALUES ("search-database-analyses-protein-code-search-by-transporter-subclass-option", "1.A.70	The Molecule Against Microbes A (MamA) Family 
");
			INSERT INTO TEXTS(tag, value) VALUES ("search-database-analyses-protein-code-search-by-transporter-subclass-option", "1.A.71	The Brain Acid-soluble Protein Channel (BASP1 Channel) Family 
");
			INSERT INTO TEXTS(tag, value) VALUES ("search-database-analyses-protein-code-search-by-transporter-subclass-option", "1.A.72	The Mer Superfamily
");
			INSERT INTO TEXTS(tag, value) VALUES ("search-database-analyses-protein-code-search-by-transporter-subclass-option", "1.A.73	The Colicin Lysis Protein (CLP) Family 
");
			INSERT INTO TEXTS(tag, value) VALUES ("search-database-analyses-protein-code-search-by-transporter-subclass-option", "1.A.74	The Mitsugumin 23 (MG23) Family
");
			INSERT INTO TEXTS(tag, value) VALUES ("search-database-analyses-protein-code-search-by-transporter-subclass-option", "1.A.75	The Mechanical Nociceptor, Piezo (Piezo) Family
");
			INSERT INTO TEXTS(tag, value) VALUES ("search-database-analyses-protein-code-search-by-transporter-subclass-option", "1.A.76	The Mitochondrial EF Hand Ca2+ Uptake Porter/Regulator (MICU) Family
");
			INSERT INTO TEXTS(tag, value) VALUES ("search-database-analyses-protein-code-search-by-transporter-subclass-option", "1.A.77	The Mg2+/Ca2+ Uniporter (MCU) Family
");
			INSERT INTO TEXTS(tag, value) VALUES ("search-database-analyses-protein-code-search-by-transporter-subclass-option", "1.A.78	Classical Swine Fever Virus p7 Viroporin (CSFV-P7 Viroporin) Family
");
			INSERT INTO TEXTS(tag, value) VALUES ("search-database-analyses-protein-code-search-by-transporter-subclass-option", "1.A.79	The Cholesterol Uptake Protein (CUP) or Double Stranded RNA Uptake Family
");
			INSERT INTO TEXTS(tag, value) VALUES ("search-database-analyses-protein-code-search-by-transporter-subclass-option", "1.A.80	The NS4a Viroportin (NS4a) Family
");
			INSERT INTO TEXTS(tag, value) VALUES ("search-database-analyses-protein-code-search-by-transporter-subclass-option", "1.A.81	The Low Affinity Ca2+ Channel (LACC) Family
");
			INSERT INTO TEXTS(tag, value) VALUES ("search-database-analyses-protein-code-search-by-transporter-subclass-option", "1.A.82	The Hair Cell Mechanotransduction Channel (HCMC) Family
");
			INSERT INTO TEXTS(tag, value) VALUES ("search-database-analyses-protein-code-search-by-transporter-subclass-option", "1.A.83	The SV40 Virus Viroporin VP2 (SV40 VP2) Family
");
			INSERT INTO TEXTS(tag, value) VALUES ("search-database-analyses-protein-code-search-by-transporter-subclass-option", "1.A.84	The Calcium Homeostasis Modulator Ca2+ Channel (CALHM-c) Family
");
			INSERT INTO TEXTS(tag, value) VALUES ("search-database-analyses-protein-code-search-by-transporter-subclass-option", "1.A.85	The Poliovirus 2B Viroporin (2B Viroporin) Family
");
			INSERT INTO TEXTS(tag, value) VALUES ("search-database-analyses-protein-code-search-by-transporter-subclass-option", "1.B	&#946;-Barrel Porins
");
			INSERT INTO TEXTS(tag, value) VALUES ("search-database-analyses-protein-code-search-by-transporter-subclass-option", "1.B.1	The General Bacterial Porin (GBP) Family
");
			INSERT INTO TEXTS(tag, value) VALUES ("search-database-analyses-protein-code-search-by-transporter-subclass-option", "1.B.2	The Chlamydial Porin (CP) Family
");
			INSERT INTO TEXTS(tag, value) VALUES ("search-database-analyses-protein-code-search-by-transporter-subclass-option", "1.B.3	The Sugar Porin (SP) Family
");
			INSERT INTO TEXTS(tag, value) VALUES ("search-database-analyses-protein-code-search-by-transporter-subclass-option", "1.B.4	The Brucella-Rhizobium Porin (BRP) Family
");
			INSERT INTO TEXTS(tag, value) VALUES ("search-database-analyses-protein-code-search-by-transporter-subclass-option", "1.B.5	The Pseudomonas OprP Porin (POP) Family
");
			INSERT INTO TEXTS(tag, value) VALUES ("search-database-analyses-protein-code-search-by-transporter-subclass-option", "1.B.6	The OmpA-OmpF Porin (OOP) Family
");
			INSERT INTO TEXTS(tag, value) VALUES ("search-database-analyses-protein-code-search-by-transporter-subclass-option", "1.B.7	The Rhodobacter PorCa Porin (RPP) Family
");
			INSERT INTO TEXTS(tag, value) VALUES ("search-database-analyses-protein-code-search-by-transporter-subclass-option", "1.B.8	The Mitochondrial and Plastid Porin (MPP) Family
");
			INSERT INTO TEXTS(tag, value) VALUES ("search-database-analyses-protein-code-search-by-transporter-subclass-option", "1.B.9	The FadL Outer Membrane Protein (FadL) Family
");
			INSERT INTO TEXTS(tag, value) VALUES ("search-database-analyses-protein-code-search-by-transporter-subclass-option", "1.B.10	The Nucleoside-specific Channel-forming Outer Membrane Porin (Tsx) Family
");
			INSERT INTO TEXTS(tag, value) VALUES ("search-database-analyses-protein-code-search-by-transporter-subclass-option", "1.B.11	The Outer Membrane Fimbrial Usher Porin (FUP) Family
");
			INSERT INTO TEXTS(tag, value) VALUES ("search-database-analyses-protein-code-search-by-transporter-subclass-option", "1.B.12	The Autotransporter-1 (AT-1) Family
");
			INSERT INTO TEXTS(tag, value) VALUES ("search-database-analyses-protein-code-search-by-transporter-subclass-option", "1.B.13	The Alginate Export Porin (AEP) Family
");
			INSERT INTO TEXTS(tag, value) VALUES ("search-database-analyses-protein-code-search-by-transporter-subclass-option", "1.B.14	The Outer Membrane Receptor (OMR) Family
");
			INSERT INTO TEXTS(tag, value) VALUES ("search-database-analyses-protein-code-search-by-transporter-subclass-option", "1.B.15	The Raffinose Porin (RafY) Family
");
			INSERT INTO TEXTS(tag, value) VALUES ("search-database-analyses-protein-code-search-by-transporter-subclass-option", "1.B.16	The Short Chain Amide and Urea Porin (SAP) Family
");
			INSERT INTO TEXTS(tag, value) VALUES ("search-database-analyses-protein-code-search-by-transporter-subclass-option", "1.B.17	The Outer Membrane Factor (OMF) Family
");
			INSERT INTO TEXTS(tag, value) VALUES ("search-database-analyses-protein-code-search-by-transporter-subclass-option", "1.B.18	The Outer Membrane Auxiliary (OMA) Protein Family
");
			INSERT INTO TEXTS(tag, value) VALUES ("search-database-analyses-protein-code-search-by-transporter-subclass-option", "1.B.19	The Glucose-selective OprB Porin (OprB) Family
");
			INSERT INTO TEXTS(tag, value) VALUES ("search-database-analyses-protein-code-search-by-transporter-subclass-option", "1.B.20	The Two-Partner Secretion (TPS) Family
");
			INSERT INTO TEXTS(tag, value) VALUES ("search-database-analyses-protein-code-search-by-transporter-subclass-option", "1.B.21	The OmpG Porin (OmpG) Family
");
			INSERT INTO TEXTS(tag, value) VALUES ("search-database-analyses-protein-code-search-by-transporter-subclass-option", "1.B.22	The Outer Bacterial Membrane Secretin (Secretin) Family
");
			INSERT INTO TEXTS(tag, value) VALUES ("search-database-analyses-protein-code-search-by-transporter-subclass-option", "1.B.23	The Cyanobacterial Porin (CBP) Family
");
			INSERT INTO TEXTS(tag, value) VALUES ("search-database-analyses-protein-code-search-by-transporter-subclass-option", "1.B.24	The Mycobacterial Porin (MBP) Family
");
			INSERT INTO TEXTS(tag, value) VALUES ("search-database-analyses-protein-code-search-by-transporter-subclass-option", "1.B.25	The Outer Membrane Porin (Opr) Family
");
			INSERT INTO TEXTS(tag, value) VALUES ("search-database-analyses-protein-code-search-by-transporter-subclass-option", "1.B.26	The Cyclodextrin Porin (CDP) Family
");
			INSERT INTO TEXTS(tag, value) VALUES ("search-database-analyses-protein-code-search-by-transporter-subclass-option", "1.B.27	The Helicobacter Outer Membrane Porin (HOP) Family
");
			INSERT INTO TEXTS(tag, value) VALUES ("search-database-analyses-protein-code-search-by-transporter-subclass-option", "1.B.28	The Plastid Outer Envelope Porin of 24 kDa (OEP24) Family
");
			INSERT INTO TEXTS(tag, value) VALUES ("search-database-analyses-protein-code-search-by-transporter-subclass-option", "1.B.29	The Plastid Outer Envelope Porin of 21 kDa (OEP21) Family
");
			INSERT INTO TEXTS(tag, value) VALUES ("search-database-analyses-protein-code-search-by-transporter-subclass-option", "1.B.30	The Plastid Outer Envelope Porin of 16 kDa (OEP16) Family
");
			INSERT INTO TEXTS(tag, value) VALUES ("search-database-analyses-protein-code-search-by-transporter-subclass-option", "1.B.31	The Campylobacter jejuni Major Outer Membrane Porin (MomP) Family
");
			INSERT INTO TEXTS(tag, value) VALUES ("search-database-analyses-protein-code-search-by-transporter-subclass-option", "1.B.32	The Fusobacterial Outer Membrane Porin (FomP) Family
");
			INSERT INTO TEXTS(tag, value) VALUES ("search-database-analyses-protein-code-search-by-transporter-subclass-option", "1.B.33	The Outer Membrane Protein Insertion Porin (Bam Complex) (OmpIP) Family
");
			INSERT INTO TEXTS(tag, value) VALUES ("search-database-analyses-protein-code-search-by-transporter-subclass-option", "1.B.34	The Corynebacterial Porin A (PorA) Family
");
			INSERT INTO TEXTS(tag, value) VALUES ("search-database-analyses-protein-code-search-by-transporter-subclass-option", "1.B.35	The Oligogalacturonate-specific Porin (KdgM) Family
");
			INSERT INTO TEXTS(tag, value) VALUES ("search-database-analyses-protein-code-search-by-transporter-subclass-option", "1.B.36	The Borrelia Porin p13 (BP-p13) Family
");
			INSERT INTO TEXTS(tag, value) VALUES ("search-database-analyses-protein-code-search-by-transporter-subclass-option", "1.B.37	The Leptospira Porin OmpL1 (LP-OmpL1) Family
");
			INSERT INTO TEXTS(tag, value) VALUES ("search-database-analyses-protein-code-search-by-transporter-subclass-option", "1.B.38	The Treponema Porin Major Surface Protein (TP-MSP) Family
");
			INSERT INTO TEXTS(tag, value) VALUES ("search-database-analyses-protein-code-search-by-transporter-subclass-option", "1.B.39	The Bacterial Porin, OmpW (OmpW) Family
");
			INSERT INTO TEXTS(tag, value) VALUES ("search-database-analyses-protein-code-search-by-transporter-subclass-option", "1.B.40	The Autotransporter-2 (AT-2) Family
");
			INSERT INTO TEXTS(tag, value) VALUES ("search-database-analyses-protein-code-search-by-transporter-subclass-option", "1.B.41	The Corynebacterial Porin B (PorB) Family
");
			INSERT INTO TEXTS(tag, value) VALUES ("search-database-analyses-protein-code-search-by-transporter-subclass-option", "1.B.42	The Outer Membrane Lipopolysaccharide Export Porin (LPS-EP) Family
");
			INSERT INTO TEXTS(tag, value) VALUES ("search-database-analyses-protein-code-search-by-transporter-subclass-option", "1.B.43	The Coxiella Porin P1 (CPP1) Family
");
			INSERT INTO TEXTS(tag, value) VALUES ("search-database-analyses-protein-code-search-by-transporter-subclass-option", "1.B.44	The Probable Protein Translocating Porphyromonas gingivalis Porin (PorT) Family
");
			INSERT INTO TEXTS(tag, value) VALUES ("search-database-analyses-protein-code-search-by-transporter-subclass-option", "1.B.45	The Treponema Porin (T-por) Family
");
			INSERT INTO TEXTS(tag, value) VALUES ("search-database-analyses-protein-code-search-by-transporter-subclass-option", "1.B.46	The Outer Membrane LolAB Lipoprotein Insertion Apparatus (LolAB) Family
");
			INSERT INTO TEXTS(tag, value) VALUES ("search-database-analyses-protein-code-search-by-transporter-subclass-option", "1.B.47	The Plastid Outer Envelope Porin of 37 kDa (OEP37) Family
");
			INSERT INTO TEXTS(tag, value) VALUES ("search-database-analyses-protein-code-search-by-transporter-subclass-option", "1.B.48	The Curli Fiber Subunit, CsgA, Porin, CsgG (GsgG) Family
");
			INSERT INTO TEXTS(tag, value) VALUES ("search-database-analyses-protein-code-search-by-transporter-subclass-option", "1.B.49	The Anaplasma P44 (A-P44) Porin Family
");
			INSERT INTO TEXTS(tag, value) VALUES ("search-database-analyses-protein-code-search-by-transporter-subclass-option", "1.B.50	The Acid-fast Bacterial, Outer Membrane Porin (AFB-OMP) Family
");
			INSERT INTO TEXTS(tag, value) VALUES ("search-database-analyses-protein-code-search-by-transporter-subclass-option", "1.B.51	The Oms66 Porin (Oms66P) Family
");
			INSERT INTO TEXTS(tag, value) VALUES ("search-database-analyses-protein-code-search-by-transporter-subclass-option", "1.B.52	The Oms28 Porin (Oms28P) Family
");
			INSERT INTO TEXTS(tag, value) VALUES ("search-database-analyses-protein-code-search-by-transporter-subclass-option", "1.B.53	The Filamentous Phage gp3 Channel-Forming Protein (FP-gp3) Family
");
			INSERT INTO TEXTS(tag, value) VALUES ("search-database-analyses-protein-code-search-by-transporter-subclass-option", "1.B.54	The Intimin/Invasin (Int/Inv) or Autotransporter-3 (AT-3) Family 
");
			INSERT INTO TEXTS(tag, value) VALUES ("search-database-analyses-protein-code-search-by-transporter-subclass-option", "1.B.55	The Poly Acetyl Glucosamine Porin (PgaA) Family
");
			INSERT INTO TEXTS(tag, value) VALUES ("search-database-analyses-protein-code-search-by-transporter-subclass-option", "1.B.56	The Spirochete Outer Membrane Porin (S-OMP) Family
");
			INSERT INTO TEXTS(tag, value) VALUES ("search-database-analyses-protein-code-search-by-transporter-subclass-option", "1.B.57	The Legionella Major-Outer Membrane Protein (LM-OMP) Family
");
			INSERT INTO TEXTS(tag, value) VALUES ("search-database-analyses-protein-code-search-by-transporter-subclass-option", "1.B.58	Nocardial Hetero-oligomeric Cell Wall Channel (NfpA/B) Family
");
			INSERT INTO TEXTS(tag, value) VALUES ("search-database-analyses-protein-code-search-by-transporter-subclass-option", "1.B.59	The Outer Membrane Porin, PorH (PorH) Family
");
			INSERT INTO TEXTS(tag, value) VALUES ("search-database-analyses-protein-code-search-by-transporter-subclass-option", "1.B.60	The Omp50 Porin (Omp50 Porin) Family
");
			INSERT INTO TEXTS(tag, value) VALUES ("search-database-analyses-protein-code-search-by-transporter-subclass-option", "1.B.61	The Delta-Proteobacterial Porin (Delta-Porin) Family
");
			INSERT INTO TEXTS(tag, value) VALUES ("search-database-analyses-protein-code-search-by-transporter-subclass-option", "1.B.62	The Putative Bacterial Porin (PBP) Family
");
			INSERT INTO TEXTS(tag, value) VALUES ("search-database-analyses-protein-code-search-by-transporter-subclass-option", "1.C	Pore-Forming Toxins (Proteins and Peptides)
");
			INSERT INTO TEXTS(tag, value) VALUES ("search-database-analyses-protein-code-search-by-transporter-subclass-option", "1.C.1	The Channel-forming Colicin (Colicin) Family
");
			INSERT INTO TEXTS(tag, value) VALUES ("search-database-analyses-protein-code-search-by-transporter-subclass-option", "1.C.2	The Channel-forming &#948;-Endotoxin Insecticidal Crystal Protein (ICP) Family
");
			INSERT INTO TEXTS(tag, value) VALUES ("search-database-analyses-protein-code-search-by-transporter-subclass-option", "1.C.3	The &#945;-Hemolysin Channel-forming Toxin (&#945;HL) Family
");
			INSERT INTO TEXTS(tag, value) VALUES ("search-database-analyses-protein-code-search-by-transporter-subclass-option", "1.C.4	The Aerolysin Channel-forming Toxin (Aerolysin) Family
");
			INSERT INTO TEXTS(tag, value) VALUES ("search-database-analyses-protein-code-search-by-transporter-subclass-option", "1.C.5	The Channel-forming &#949;-toxin (&#949;-toxin) Family
");
			INSERT INTO TEXTS(tag, value) VALUES ("search-database-analyses-protein-code-search-by-transporter-subclass-option", "1.C.6	The Yeast Killer Toxin K1 (YKT-K1) Family
");
			INSERT INTO TEXTS(tag, value) VALUES ("search-database-analyses-protein-code-search-by-transporter-subclass-option", "1.C.7	The Diphtheria Toxin (DT) Family
");
			INSERT INTO TEXTS(tag, value) VALUES ("search-database-analyses-protein-code-search-by-transporter-subclass-option", "1.C.8	The Botulinum and Tetanus Toxin (BTT) Family
");
			INSERT INTO TEXTS(tag, value) VALUES ("search-database-analyses-protein-code-search-by-transporter-subclass-option", "1.C.9	The Vacuolating Cytotoxin (VacA) Family
");
			INSERT INTO TEXTS(tag, value) VALUES ("search-database-analyses-protein-code-search-by-transporter-subclass-option", "1.C.10	The Pore-forming Haemolysin E (HlyE) Family
");
			INSERT INTO TEXTS(tag, value) VALUES ("search-database-analyses-protein-code-search-by-transporter-subclass-option", "1.C.11	The Pore-forming RTX Toxin (RTX-toxin) Family
");
			INSERT INTO TEXTS(tag, value) VALUES ("search-database-analyses-protein-code-search-by-transporter-subclass-option", "1.C.12	Thiol-activated Cholesterol-dependent Cytolysin (CDC) Family
");
			INSERT INTO TEXTS(tag, value) VALUES ("search-database-analyses-protein-code-search-by-transporter-subclass-option", "1.C.13	The Channel-forming Leukocidin Cytotoxin (Ctx) Family
");
			INSERT INTO TEXTS(tag, value) VALUES ("search-database-analyses-protein-code-search-by-transporter-subclass-option", "1.C.14	The Cytohemolysin (CHL) Family
");
			INSERT INTO TEXTS(tag, value) VALUES ("search-database-analyses-protein-code-search-by-transporter-subclass-option", "1.C.15	The Whipworm Stichosome Porin (WSP) Family
");
			INSERT INTO TEXTS(tag, value) VALUES ("search-database-analyses-protein-code-search-by-transporter-subclass-option", "1.C.16	The Magainin (Magainin) Family
");
			INSERT INTO TEXTS(tag, value) VALUES ("search-database-analyses-protein-code-search-by-transporter-subclass-option", "1.C.17	The Cecropin (Cecropin) Family
");
			INSERT INTO TEXTS(tag, value) VALUES ("search-database-analyses-protein-code-search-by-transporter-subclass-option", "1.C.18	The Melittin (Melittin) Family
");
			INSERT INTO TEXTS(tag, value) VALUES ("search-database-analyses-protein-code-search-by-transporter-subclass-option", "1.C.19	The Defensin (Defensin) Family
");
			INSERT INTO TEXTS(tag, value) VALUES ("search-database-analyses-protein-code-search-by-transporter-subclass-option", "1.C.20	The Nisin (Nisin) Family
");
			INSERT INTO TEXTS(tag, value) VALUES ("search-database-analyses-protein-code-search-by-transporter-subclass-option", "1.C.21	The Lacticin 481 (Lacticin 481) Family
");
			INSERT INTO TEXTS(tag, value) VALUES ("search-database-analyses-protein-code-search-by-transporter-subclass-option", "1.C.22	The Lactococcin A (Lactococcin A) Family
");
			INSERT INTO TEXTS(tag, value) VALUES ("search-database-analyses-protein-code-search-by-transporter-subclass-option", "1.C.23	The Lactocin S (Lactocin S) Family
");
			INSERT INTO TEXTS(tag, value) VALUES ("search-database-analyses-protein-code-search-by-transporter-subclass-option", "1.C.24	The Pediocin (Pediocin) Family
");
			INSERT INTO TEXTS(tag, value) VALUES ("search-database-analyses-protein-code-search-by-transporter-subclass-option", "1.C.25	The Lactococcin G (Lactococcin G) Family
");
			INSERT INTO TEXTS(tag, value) VALUES ("search-database-analyses-protein-code-search-by-transporter-subclass-option", "1.C.26	The Lactacin X (Lactacin X) Family
");
			INSERT INTO TEXTS(tag, value) VALUES ("search-database-analyses-protein-code-search-by-transporter-subclass-option", "1.C.27	The Divergicin A (Divergicin A) Family
");
			INSERT INTO TEXTS(tag, value) VALUES ("search-database-analyses-protein-code-search-by-transporter-subclass-option", "1.C.28	The Bacteriocin AS-48 Cyclic Polypeptide (Bacteriocin AS-48) Family
");
			INSERT INTO TEXTS(tag, value) VALUES ("search-database-analyses-protein-code-search-by-transporter-subclass-option", "1.C.29	The Plantaricin EF (Plantaricin EF) Family
");
			INSERT INTO TEXTS(tag, value) VALUES ("search-database-analyses-protein-code-search-by-transporter-subclass-option", "1.C.30	The Plantaricin JK (Plantaricin JK) Family
");
			INSERT INTO TEXTS(tag, value) VALUES ("search-database-analyses-protein-code-search-by-transporter-subclass-option", "1.C.31	The Channel-forming Colicin V (Colicin V) Family
");
			INSERT INTO TEXTS(tag, value) VALUES ("search-database-analyses-protein-code-search-by-transporter-subclass-option", "1.C.32	The Amphipathic Peptide Mastoparan (Mastoparan) Family
");
			INSERT INTO TEXTS(tag, value) VALUES ("search-database-analyses-protein-code-search-by-transporter-subclass-option", "1.C.33	The Cathelicidin (Cathelicidin) Family
");
			INSERT INTO TEXTS(tag, value) VALUES ("search-database-analyses-protein-code-search-by-transporter-subclass-option", "1.C.34	The Tachyplesin (Tachyplesin) Family
");
			INSERT INTO TEXTS(tag, value) VALUES ("search-database-analyses-protein-code-search-by-transporter-subclass-option", "1.C.35	The Amoebapore (Amoebapore) Family
");
			INSERT INTO TEXTS(tag, value) VALUES ("search-database-analyses-protein-code-search-by-transporter-subclass-option", "1.C.36	The Bacterial Type III-Target Cell Pore (IIITCP) Family
");
			INSERT INTO TEXTS(tag, value) VALUES ("search-database-analyses-protein-code-search-by-transporter-subclass-option", "1.C.37	The Lactococcin 972 (Lactococcin 972) Family
");
			INSERT INTO TEXTS(tag, value) VALUES ("search-database-analyses-protein-code-search-by-transporter-subclass-option", "1.C.38	The Pore-forming Equinatoxin (Equinatoxin) Family
");
			INSERT INTO TEXTS(tag, value) VALUES ("search-database-analyses-protein-code-search-by-transporter-subclass-option", "1.C.39	The Membrane Attack Complex/Perforin (MACPF) Family
");
			INSERT INTO TEXTS(tag, value) VALUES ("search-database-analyses-protein-code-search-by-transporter-subclass-option", "1.C.40	The Bactericidal Permeability Increasing Protein (BPIP) Family
");
			INSERT INTO TEXTS(tag, value) VALUES ("search-database-analyses-protein-code-search-by-transporter-subclass-option", "1.C.41	The Tripartite Haemolysin BL (HBL) Family
");
			INSERT INTO TEXTS(tag, value) VALUES ("search-database-analyses-protein-code-search-by-transporter-subclass-option", "1.C.42	The Channel-forming Bacillus anthracis Protective Antigen (BAPA) Family
");
			INSERT INTO TEXTS(tag, value) VALUES ("search-database-analyses-protein-code-search-by-transporter-subclass-option", "1.C.43	The Earthworm Lysenin Toxin (Lysenin) Family
");
			INSERT INTO TEXTS(tag, value) VALUES ("search-database-analyses-protein-code-search-by-transporter-subclass-option", "1.C.44	The Plant Thionine (PT) Family
");
			INSERT INTO TEXTS(tag, value) VALUES ("search-database-analyses-protein-code-search-by-transporter-subclass-option", "1.C.45	The Plant Defensin (Plant Defensin) Family
");
			INSERT INTO TEXTS(tag, value) VALUES ("search-database-analyses-protein-code-search-by-transporter-subclass-option", "1.C.46	The C-type Natriuretic Peptide (CNP) Family
");
			INSERT INTO TEXTS(tag, value) VALUES ("search-database-analyses-protein-code-search-by-transporter-subclass-option", "1.C.47	The Insect/Fungal Defensin (Insect/Fungal Defensin) Family
");
			INSERT INTO TEXTS(tag, value) VALUES ("search-database-analyses-protein-code-search-by-transporter-subclass-option", "1.C.48	The Prion Peptide Fragment (PrP-F) Family
");
			INSERT INTO TEXTS(tag, value) VALUES ("search-database-analyses-protein-code-search-by-transporter-subclass-option", "1.C.49	The Cytotoxic Amylin (Amylin) Family
");
			INSERT INTO TEXTS(tag, value) VALUES ("search-database-analyses-protein-code-search-by-transporter-subclass-option", "1.C.50	The Amyloid &#946;-Protein Peptide (A&#946;PP) Family
");
			INSERT INTO TEXTS(tag, value) VALUES ("search-database-analyses-protein-code-search-by-transporter-subclass-option", "1.C.51	The Pilosulin (Pilosulin) Family
");
			INSERT INTO TEXTS(tag, value) VALUES ("search-database-analyses-protein-code-search-by-transporter-subclass-option", "1.C.52	The Dermaseptin (Dermaseptin) Family
");
			INSERT INTO TEXTS(tag, value) VALUES ("search-database-analyses-protein-code-search-by-transporter-subclass-option", "1.C.53	The Lactocyclicin Q (Lactocyclicin Q) Family
");
			INSERT INTO TEXTS(tag, value) VALUES ("search-database-analyses-protein-code-search-by-transporter-subclass-option", "1.C.54	The Shiga Toxin B-Chain (ST-B) Family
");
			INSERT INTO TEXTS(tag, value) VALUES ("search-database-analyses-protein-code-search-by-transporter-subclass-option", "1.C.55	The Agrobacterial VirE2 Target Host Cell Membrane Anion Channel (VirE2) Family
");
			INSERT INTO TEXTS(tag, value) VALUES ("search-database-analyses-protein-code-search-by-transporter-subclass-option", "1.C.56	The Pseudomanas syringae HrpZ Target Host Cell Membrane Cation Channel (HrpZ) Family
");
			INSERT INTO TEXTS(tag, value) VALUES ("search-database-analyses-protein-code-search-by-transporter-subclass-option", "1.C.57	The Clostridial Cytotoxin (CCT) Family
");
			INSERT INTO TEXTS(tag, value) VALUES ("search-database-analyses-protein-code-search-by-transporter-subclass-option", "1.C.58	The Microcin E492/C24 (Microcin E492) Family
");
			INSERT INTO TEXTS(tag, value) VALUES ("search-database-analyses-protein-code-search-by-transporter-subclass-option", "1.C.59	The Clostridium perfringens Enterotoxin (CPE) Family
");
			INSERT INTO TEXTS(tag, value) VALUES ("search-database-analyses-protein-code-search-by-transporter-subclass-option", "1.C.60	The Two-component Enterococcus faecalis Cytolysin (EFC) Family
");
			INSERT INTO TEXTS(tag, value) VALUES ("search-database-analyses-protein-code-search-by-transporter-subclass-option", "1.C.61	The Streptococcus pyogenes Streptolysin S (Streptolysin S) Family
");
			INSERT INTO TEXTS(tag, value) VALUES ("search-database-analyses-protein-code-search-by-transporter-subclass-option", "1.C.62	The Pseudopleuronectes americanus (flounder) Pleurocidin (Pleurocidin) Family
");
			INSERT INTO TEXTS(tag, value) VALUES ("search-database-analyses-protein-code-search-by-transporter-subclass-option", "1.C.63	The &#945;-Latrotoxin (Latrotoxin) Family
");
			INSERT INTO TEXTS(tag, value) VALUES ("search-database-analyses-protein-code-search-by-transporter-subclass-option", "1.C.64	The Fst Toxin (Fst) Family
");
			INSERT INTO TEXTS(tag, value) VALUES ("search-database-analyses-protein-code-search-by-transporter-subclass-option", "1.C.65	The Type III Secretion System Plant Host Cell Membrane Pore-forming HrpF (HrpF) Family
");
			INSERT INTO TEXTS(tag, value) VALUES ("search-database-analyses-protein-code-search-by-transporter-subclass-option", "1.C.66	The Puroindoline (Puroindoline) Family
");
			INSERT INTO TEXTS(tag, value) VALUES ("search-database-analyses-protein-code-search-by-transporter-subclass-option", "1.C.67	The SphH Hemolysin (SphH) Family
");
			INSERT INTO TEXTS(tag, value) VALUES ("search-database-analyses-protein-code-search-by-transporter-subclass-option", "1.C.68	The Channel-forming Oxyopinin Peptide (Oxyopinin) Family
");
			INSERT INTO TEXTS(tag, value) VALUES ("search-database-analyses-protein-code-search-by-transporter-subclass-option", "1.C.69	The Clostridium perfringens Beta-2 Toxin (Beta-2) Family
");
			INSERT INTO TEXTS(tag, value) VALUES ("search-database-analyses-protein-code-search-by-transporter-subclass-option", "1.C.70	The Streptococcal Pore-forming CAMP Factor (CAMP-F) Family
");
			INSERT INTO TEXTS(tag, value) VALUES ("search-database-analyses-protein-code-search-by-transporter-subclass-option", "1.C.71	The Cytolytic Delta Endotoxin (Cyt1/2) Family
");
			INSERT INTO TEXTS(tag, value) VALUES ("search-database-analyses-protein-code-search-by-transporter-subclass-option", "1.C.72	The Pertussis Toxin (PTX) Family
");
			INSERT INTO TEXTS(tag, value) VALUES ("search-database-analyses-protein-code-search-by-transporter-subclass-option", "1.C.73	The Pseudomonas Exotoxin A (P-ExoA) Family
");
			INSERT INTO TEXTS(tag, value) VALUES ("search-database-analyses-protein-code-search-by-transporter-subclass-option", "1.C.74	The Snake Cytotoxin (SCT) Family
");
			INSERT INTO TEXTS(tag, value) VALUES ("search-database-analyses-protein-code-search-by-transporter-subclass-option", "1.C.75	The Serratia-type Pore-forming Toxin (S-PFT) Family
");
			INSERT INTO TEXTS(tag, value) VALUES ("search-database-analyses-protein-code-search-by-transporter-subclass-option", "1.C.76	The Pore-forming Maculatin Peptide (Maculatin) Family
");
			INSERT INTO TEXTS(tag, value) VALUES ("search-database-analyses-protein-code-search-by-transporter-subclass-option", "1.C.77	The Synuclein (Synuclein) Family
");
			INSERT INTO TEXTS(tag, value) VALUES ("search-database-analyses-protein-code-search-by-transporter-subclass-option", "1.C.78	The Crystal Protein (Cry) Family
");
			INSERT INTO TEXTS(tag, value) VALUES ("search-database-analyses-protein-code-search-by-transporter-subclass-option", "1.C.79	The Channel-forming Histatin Antimicrobial Peptide (Histatin) Family
");
			INSERT INTO TEXTS(tag, value) VALUES ("search-database-analyses-protein-code-search-by-transporter-subclass-option", "1.C.80	The Cytotoxic Major Fimbrial Subunit (MrxA) Family
");
			INSERT INTO TEXTS(tag, value) VALUES ("search-database-analyses-protein-code-search-by-transporter-subclass-option", "1.C.81	The Arenicin (Arenicin) Family 
");
			INSERT INTO TEXTS(tag, value) VALUES ("search-database-analyses-protein-code-search-by-transporter-subclass-option", "1.C.82	The Pore-forming Amphipathic Helical Peptide HP(2-20) (HP2-20) Family
");
			INSERT INTO TEXTS(tag, value) VALUES ("search-database-analyses-protein-code-search-by-transporter-subclass-option", "1.C.83	The Gassericin (Gassericin) Family
");
			INSERT INTO TEXTS(tag, value) VALUES ("search-database-analyses-protein-code-search-by-transporter-subclass-option", "1.C.84	The Subtilosin (Subtilosin) Family
");
			INSERT INTO TEXTS(tag, value) VALUES ("search-database-analyses-protein-code-search-by-transporter-subclass-option", "1.C.85	The Pore-Forming &#946;-Defensin (&#946;-Defensin) Family
");
			INSERT INTO TEXTS(tag, value) VALUES ("search-database-analyses-protein-code-search-by-transporter-subclass-option", "1.C.86	The Pore-forming Trialysin (Trialysin) Family
");
			INSERT INTO TEXTS(tag, value) VALUES ("search-database-analyses-protein-code-search-by-transporter-subclass-option", "1.C.87	The Phage P22 Cell Envelope-penetrating Needle (P22-CEN) Family
");
			INSERT INTO TEXTS(tag, value) VALUES ("search-database-analyses-protein-code-search-by-transporter-subclass-option", "1.C.88	The Chrysophsin (Chrysophsin) Family
");
			INSERT INTO TEXTS(tag, value) VALUES ("search-database-analyses-protein-code-search-by-transporter-subclass-option", "1.C.89	The Dynorphin Channel-forming Neuropeptide (Dynorphin) Family
");
			INSERT INTO TEXTS(tag, value) VALUES ("search-database-analyses-protein-code-search-by-transporter-subclass-option", "1.C.90	The Carnocyclin A (Carnocyclin) Family
");
			INSERT INTO TEXTS(tag, value) VALUES ("search-database-analyses-protein-code-search-by-transporter-subclass-option", "1.C.91	The Stefin B Pore-forming Protein (Stefin B) Family
");
			INSERT INTO TEXTS(tag, value) VALUES ("search-database-analyses-protein-code-search-by-transporter-subclass-option", "1.C.92	The Pentraxin (Pentraxin) Family
");
			INSERT INTO TEXTS(tag, value) VALUES ("search-database-analyses-protein-code-search-by-transporter-subclass-option", "1.C.93	The Lacticin Q (Lacticin Q) Family
");
			INSERT INTO TEXTS(tag, value) VALUES ("search-database-analyses-protein-code-search-by-transporter-subclass-option", "1.C.94	The Thuricin S (Thuricin S) Family
");
			INSERT INTO TEXTS(tag, value) VALUES ("search-database-analyses-protein-code-search-by-transporter-subclass-option", "1.C.95	The Pore-forming ESAT-6 Protein  (ESAT-6) Family
");
			INSERT INTO TEXTS(tag, value) VALUES ("search-database-analyses-protein-code-search-by-transporter-subclass-option", "1.C.96	The Haemolytic Lectin, CEL-III (CEL-III) Family
");
			INSERT INTO TEXTS(tag, value) VALUES ("search-database-analyses-protein-code-search-by-transporter-subclass-option", "1.C.97	The Pleurotolysin pore-forming (Pleurotolysin) Family
");
			INSERT INTO TEXTS(tag, value) VALUES ("search-database-analyses-protein-code-search-by-transporter-subclass-option", "1.C.98	The Cytolethal Distending Toxin (CDT) Family
");
			INSERT INTO TEXTS(tag, value) VALUES ("search-database-analyses-protein-code-search-by-transporter-subclass-option", "1.C.99	The Pore-forming Corona Viral Orf8a (Orf8a) Family
");
			INSERT INTO TEXTS(tag, value) VALUES ("search-database-analyses-protein-code-search-by-transporter-subclass-option", "1.C.100	The Thermostable Direct Hemolysin (TDH) Family
");
			INSERT INTO TEXTS(tag, value) VALUES ("search-database-analyses-protein-code-search-by-transporter-subclass-option", "1.C.101	The HIV-1 TAT Peptide Translocator (HIV-TAT1) Family
");
			INSERT INTO TEXTS(tag, value) VALUES ("search-database-analyses-protein-code-search-by-transporter-subclass-option", "1.C.102	The Cerein (Cerein) Family
");
			INSERT INTO TEXTS(tag, value) VALUES ("search-database-analyses-protein-code-search-by-transporter-subclass-option", "1.C.103	The Pore-forming Toxin, TisB (TisB) Family
");
			INSERT INTO TEXTS(tag, value) VALUES ("search-database-analyses-protein-code-search-by-transporter-subclass-option", "1.C.104	The Heterokaryon Incompatibility Prion/Amyloid Protein (HET-s) Family
");
			INSERT INTO TEXTS(tag, value) VALUES ("search-database-analyses-protein-code-search-by-transporter-subclass-option", "1.C.105	The Bacillus thuringiensis Vegetative Insecticidal Protein-3 (Vip3) Family
");
			INSERT INTO TEXTS(tag, value) VALUES ("search-database-analyses-protein-code-search-by-transporter-subclass-option", "1.C.106	The Bacillus thuringiensis Vegetative Insecticidal Protein-2 (Vip2) Family
");
			INSERT INTO TEXTS(tag, value) VALUES ("search-database-analyses-protein-code-search-by-transporter-subclass-option", "1.C.107	Import Subunit A of the Insecticidal Toxin Complex (ITC-A) Family
");
			INSERT INTO TEXTS(tag, value) VALUES ("search-database-analyses-protein-code-search-by-transporter-subclass-option", "1.C.108	The Pore-forming Dermcidin (Dermcidin) Family
");
			INSERT INTO TEXTS(tag, value) VALUES ("search-database-analyses-protein-code-search-by-transporter-subclass-option", "1.D	Non-Ribosomally Synthesized Channels
");
			INSERT INTO TEXTS(tag, value) VALUES ("search-database-analyses-protein-code-search-by-transporter-subclass-option", "1.D.1	The Gramicidin A (Gramicidin A) Channel Family
");
			INSERT INTO TEXTS(tag, value) VALUES ("search-database-analyses-protein-code-search-by-transporter-subclass-option", "1.D.2	The Channel-forming Syringomycin (Syringomycin) Family
");
			INSERT INTO TEXTS(tag, value) VALUES ("search-database-analyses-protein-code-search-by-transporter-subclass-option", "1.D.3	The Channel-Forming Syringopeptin (Syringopeptin) Family
");
			INSERT INTO TEXTS(tag, value) VALUES ("search-database-analyses-protein-code-search-by-transporter-subclass-option", "1.D.4	The Tolaasin Channel-forming (Tolaasin) Family
");
			INSERT INTO TEXTS(tag, value) VALUES ("search-database-analyses-protein-code-search-by-transporter-subclass-option", "1.D.5	The Alamethicin or Peptaibol Antibiotic Channel-forming (Alamethicin) Family
");
			INSERT INTO TEXTS(tag, value) VALUES ("search-database-analyses-protein-code-search-by-transporter-subclass-option", "1.D.6	The Complexed Poly 3-Hydroxybutyrate Ca2+ Channel (cPHB-CC) Family
");
			INSERT INTO TEXTS(tag, value) VALUES ("search-database-analyses-protein-code-search-by-transporter-subclass-option", "1.D.7	The Beticolin (Beticolin) Family
");
			INSERT INTO TEXTS(tag, value) VALUES ("search-database-analyses-protein-code-search-by-transporter-subclass-option", "1.D.8	The Saponin (Saponin) Family
");
			INSERT INTO TEXTS(tag, value) VALUES ("search-database-analyses-protein-code-search-by-transporter-subclass-option", "1.D.9	The Polyglutamine Ion Channel (PG-IC) Family
");
			INSERT INTO TEXTS(tag, value) VALUES ("search-database-analyses-protein-code-search-by-transporter-subclass-option", "1.D.10	The Ceramide-forming Channel (Ceramide) Family
");
			INSERT INTO TEXTS(tag, value) VALUES ("search-database-analyses-protein-code-search-by-transporter-subclass-option", "1.D.11	The Surfactin (Surfactin) Family
");
			INSERT INTO TEXTS(tag, value) VALUES ("search-database-analyses-protein-code-search-by-transporter-subclass-option", "1.D.12	The Beauvericin (Beauvericin) Family
");
			INSERT INTO TEXTS(tag, value) VALUES ("search-database-analyses-protein-code-search-by-transporter-subclass-option", "1.D.13	DNA-delivery Amphipathic Peptide Antibiotics (DAPA)
");
			INSERT INTO TEXTS(tag, value) VALUES ("search-database-analyses-protein-code-search-by-transporter-subclass-option", "1.D.14	The Synthetic Leu/Ser Amphipathic Channel-forming Peptide (l/S-SCP) Family
");
			INSERT INTO TEXTS(tag, value) VALUES ("search-database-analyses-protein-code-search-by-transporter-subclass-option", "1.D.15	The Daptomycin (Daptomycin) Family
");
			INSERT INTO TEXTS(tag, value) VALUES ("search-database-analyses-protein-code-search-by-transporter-subclass-option", "1.D.16	The Synthetic Amphipathic Pore-forming Heptapeptide (SAPH) Family
");
			INSERT INTO TEXTS(tag, value) VALUES ("search-database-analyses-protein-code-search-by-transporter-subclass-option", "1.D.17	Combinatorially-designed, Pore-forming, &#946;-sheet Peptide (CP&#946;-Peptide) Family
");
			INSERT INTO TEXTS(tag, value) VALUES ("search-database-analyses-protein-code-search-by-transporter-subclass-option", "1.D.18	The Pore-forming Guanosine-Bile Acid Conjugate (GBC) Family
");
			INSERT INTO TEXTS(tag, value) VALUES ("search-database-analyses-protein-code-search-by-transporter-subclass-option", "1.D.19	Ca2+ Channel-forming Drug, Digitoxin (Digitoxin) Family
");
			INSERT INTO TEXTS(tag, value) VALUES ("search-database-analyses-protein-code-search-by-transporter-subclass-option", "1.D.20	The Pore-forming Polyene Macrolide Antibiotic/fungal Agent (PMAA) Family
");
			INSERT INTO TEXTS(tag, value) VALUES ("search-database-analyses-protein-code-search-by-transporter-subclass-option", "1.D.21	The Lipid NanoPore (LNP) Family 
");
			INSERT INTO TEXTS(tag, value) VALUES ("search-database-analyses-protein-code-search-by-transporter-subclass-option", "1.D.22	The Proton-Translocating Carotenoid Pigment, Zeaxanthin (Zeaxanthin) Family
");
			INSERT INTO TEXTS(tag, value) VALUES ("search-database-analyses-protein-code-search-by-transporter-subclass-option", "1.D.23	Phenylene Ethynylene Pore-forming Antimicrobial (PEPA) Family
");
			INSERT INTO TEXTS(tag, value) VALUES ("search-database-analyses-protein-code-search-by-transporter-subclass-option", "1.D.24	The Marine Sponge Polytheonamide B (pTB) Family 
");
			INSERT INTO TEXTS(tag, value) VALUES ("search-database-analyses-protein-code-search-by-transporter-subclass-option", "1.D.25	The Arylamine Foldamer (AAF) Family
");
			INSERT INTO TEXTS(tag, value) VALUES ("search-database-analyses-protein-code-search-by-transporter-subclass-option", "1.D.26	The Dihydrodehydrodiconiferyl alcohol 9'-O-&#946;-D-glucoside (DDDC9G) Family
");
			INSERT INTO TEXTS(tag, value) VALUES ("search-database-analyses-protein-code-search-by-transporter-subclass-option", "1.D.27	The Thiourea isosteres Family
");
			INSERT INTO TEXTS(tag, value) VALUES ("search-database-analyses-protein-code-search-by-transporter-subclass-option", "1.D.28	The Lipopeptaibol (Lipopeptaibol) Family
");
			INSERT INTO TEXTS(tag, value) VALUES ("search-database-analyses-protein-code-search-by-transporter-subclass-option", "1.D.29	The Macrocyclic Oligocholate (Oligocholate) Family
");
			INSERT INTO TEXTS(tag, value) VALUES ("search-database-analyses-protein-code-search-by-transporter-subclass-option", "1.D.30	The Artificial Hydrazide-appended pillar[5]arene Channels (HAPA-C) Family
");
			INSERT INTO TEXTS(tag, value) VALUES ("search-database-analyses-protein-code-search-by-transporter-subclass-option", "1.D.31	The Amphotericin B (Amphotericin) Family
");
			INSERT INTO TEXTS(tag, value) VALUES ("search-database-analyses-protein-code-search-by-transporter-subclass-option", "1.D.32	The Pore-forming Novicidin (Novicidin) Family
");
			INSERT INTO TEXTS(tag, value) VALUES ("search-database-analyses-protein-code-search-by-transporter-subclass-option", "1.E	Holins
");
			INSERT INTO TEXTS(tag, value) VALUES ("search-database-analyses-protein-code-search-by-transporter-subclass-option", "1.E.1	The P21 Holin S (P21 Holin) Family
");
			INSERT INTO TEXTS(tag, value) VALUES ("search-database-analyses-protein-code-search-by-transporter-subclass-option", "1.E.2	The &#955; Holin S (&#955; Holin) Family
");
			INSERT INTO TEXTS(tag, value) VALUES ("search-database-analyses-protein-code-search-by-transporter-subclass-option", "1.E.3	The P2 Holin TM (P2 Holin) Family
");
			INSERT INTO TEXTS(tag, value) VALUES ("search-database-analyses-protein-code-search-by-transporter-subclass-option", "1.E.4	The LydA Holin (LydA Holin) Family
");
			INSERT INTO TEXTS(tag, value) VALUES ("search-database-analyses-protein-code-search-by-transporter-subclass-option", "1.E.5	The PRD1 Phage P35 Holin (P35 Holin) Family
");
			INSERT INTO TEXTS(tag, value) VALUES ("search-database-analyses-protein-code-search-by-transporter-subclass-option", "1.E.6	The T7 Holin (T7 Holin) Family
");
			INSERT INTO TEXTS(tag, value) VALUES ("search-database-analyses-protein-code-search-by-transporter-subclass-option", "1.E.7	The HP1 Holin (HP1 Holin) Family
");
			INSERT INTO TEXTS(tag, value) VALUES ("search-database-analyses-protein-code-search-by-transporter-subclass-option", "1.E.8	The T4 Holin (T4 Holin) Family
");
			INSERT INTO TEXTS(tag, value) VALUES ("search-database-analyses-protein-code-search-by-transporter-subclass-option", "1.E.9	The T4 Immunity (T4 Imm) Family
");
			INSERT INTO TEXTS(tag, value) VALUES ("search-database-analyses-protein-code-search-by-transporter-subclass-option", "1.E.10	The Bacillus subtilis  &#966;29 Holin (&#966;29 Holin) Family
");
			INSERT INTO TEXTS(tag, value) VALUES ("search-database-analyses-protein-code-search-by-transporter-subclass-option", "1.E.11	The &#966;11 Holin (&#966;11 Holin) Family
");
			INSERT INTO TEXTS(tag, value) VALUES ("search-database-analyses-protein-code-search-by-transporter-subclass-option", "1.E.12	The &#966;Adh Holin (&#966;Adh Holin) Family
");
			INSERT INTO TEXTS(tag, value) VALUES ("search-database-analyses-protein-code-search-by-transporter-subclass-option", "1.E.13	The Firmicute phage &#966;U53 Holin (&#966;U53 Holin) Family
");
			INSERT INTO TEXTS(tag, value) VALUES ("search-database-analyses-protein-code-search-by-transporter-subclass-option", "1.E.14	The LrgA Holin (LrgA Holin) Family
");
			INSERT INTO TEXTS(tag, value) VALUES ("search-database-analyses-protein-code-search-by-transporter-subclass-option", "1.E.15	The ArpQ Holin (ArpQ Holin) Family
");
			INSERT INTO TEXTS(tag, value) VALUES ("search-database-analyses-protein-code-search-by-transporter-subclass-option", "1.E.16	The Cph1 Holin (Cph1 Holin) Family
");
			INSERT INTO TEXTS(tag, value) VALUES ("search-database-analyses-protein-code-search-by-transporter-subclass-option", "1.E.17	The BlyA Holin (BlyA Holin) Family
");
			INSERT INTO TEXTS(tag, value) VALUES ("search-database-analyses-protein-code-search-by-transporter-subclass-option", "1.E.18	The Lactococcus lactis Phage r1t Holin (r1t Holin) Family
");
			INSERT INTO TEXTS(tag, value) VALUES ("search-database-analyses-protein-code-search-by-transporter-subclass-option", "1.E.19	The Clostridium difficile TcdE Holin (TcdE Holin) Family
");
			INSERT INTO TEXTS(tag, value) VALUES ("search-database-analyses-protein-code-search-by-transporter-subclass-option", "1.E.20	The Pseudomonas aeruginosa Hol Holin (Hol Holin) Family
");
			INSERT INTO TEXTS(tag, value) VALUES ("search-database-analyses-protein-code-search-by-transporter-subclass-option", "1.E.21	The Listeria Phage A118 Holin (Hol118) Family
");
			INSERT INTO TEXTS(tag, value) VALUES ("search-database-analyses-protein-code-search-by-transporter-subclass-option", "1.E.22	The Neisserial Phage-associated Holin (NP-Holin) Family
");
			INSERT INTO TEXTS(tag, value) VALUES ("search-database-analyses-protein-code-search-by-transporter-subclass-option", "1.E.23	The Bacillus Spore Morphogenesis and Germination Holin (BSH) Family
");
			INSERT INTO TEXTS(tag, value) VALUES ("search-database-analyses-protein-code-search-by-transporter-subclass-option", "1.E.24	The Bacterophase Dp-1 Holin (Dp-1 Holin) Family
");
			INSERT INTO TEXTS(tag, value) VALUES ("search-database-analyses-protein-code-search-by-transporter-subclass-option", "1.E.25	The Pseudomonas phage F116 Holin (F116 Holin) Family
");
			INSERT INTO TEXTS(tag, value) VALUES ("search-database-analyses-protein-code-search-by-transporter-subclass-option", "1.E.26	The Holin LLH (Holin LLH) Family
");
			INSERT INTO TEXTS(tag, value) VALUES ("search-database-analyses-protein-code-search-by-transporter-subclass-option", "1.E.27	The BlhA Holin (BlhA Holin) Family 
");
			INSERT INTO TEXTS(tag, value) VALUES ("search-database-analyses-protein-code-search-by-transporter-subclass-option", "1.E.28	The Streptomyces aureofaciens Phage Mu1/6 Holin (Mu1/6 Holin) Family
");
			INSERT INTO TEXTS(tag, value) VALUES ("search-database-analyses-protein-code-search-by-transporter-subclass-option", "1.E.29	The Holin Hol44 (Hol44) Family
");
			INSERT INTO TEXTS(tag, value) VALUES ("search-database-analyses-protein-code-search-by-transporter-subclass-option", "1.E.30	The Vibrio Holin (Vibrio Holin) Family
");
			INSERT INTO TEXTS(tag, value) VALUES ("search-database-analyses-protein-code-search-by-transporter-subclass-option", "1.E.31	The SPP1 Holin (SPP1 Holin) Family
");
			INSERT INTO TEXTS(tag, value) VALUES ("search-database-analyses-protein-code-search-by-transporter-subclass-option", "1.E.32	Actinobacterial 1 TMS Holin (A-1 Holin) Family
");
			INSERT INTO TEXTS(tag, value) VALUES ("search-database-analyses-protein-code-search-by-transporter-subclass-option", "1.E.33	The 2 or 3 TMS Putative Holin (2/3 Holin) Family
");
			INSERT INTO TEXTS(tag, value) VALUES ("search-database-analyses-protein-code-search-by-transporter-subclass-option", "1.E.34	The Putative Actinobacterial Holin-X (Hol-X) Family
");
			INSERT INTO TEXTS(tag, value) VALUES ("search-database-analyses-protein-code-search-by-transporter-subclass-option", "1.E.35	The Mycobacterial 1 TMS Phage Holin (M1 Hol) Family
");
			INSERT INTO TEXTS(tag, value) VALUES ("search-database-analyses-protein-code-search-by-transporter-subclass-option", "1.E.36	The Mycobacterial 2 TMS Phage Holin (M2 Hol) Family
");
			INSERT INTO TEXTS(tag, value) VALUES ("search-database-analyses-protein-code-search-by-transporter-subclass-option", "1.E.37	The Phage T1 Holin (T1 Holin) Family
");
			INSERT INTO TEXTS(tag, value) VALUES ("search-database-analyses-protein-code-search-by-transporter-subclass-option", "1.E.38	The Staphylococcus phage P68 Putative Holin (P68 Hol) Family
");
			INSERT INTO TEXTS(tag, value) VALUES ("search-database-analyses-protein-code-search-by-transporter-subclass-option", "1.E.39	Mycobacterial Phage PBI1 Gp36 Holin (Gp36 Hol) Family
");
			INSERT INTO TEXTS(tag, value) VALUES ("search-database-analyses-protein-code-search-by-transporter-subclass-option", "1.E.40	The Mycobacterial 4 TMS Phage Holin (MP4 Holin) Family
");
			INSERT INTO TEXTS(tag, value) VALUES ("search-database-analyses-protein-code-search-by-transporter-subclass-option", "1.E.41	The Deinococcus/Thermus Holin (D/T-Hol) Family
");
			INSERT INTO TEXTS(tag, value) VALUES ("search-database-analyses-protein-code-search-by-transporter-subclass-option", "1.E.42	The Putative Holin-like Toxin (Hol-Tox) Family
");
			INSERT INTO TEXTS(tag, value) VALUES ("search-database-analyses-protein-code-search-by-transporter-subclass-option", "1.E.43	Putative Transglycosylase-associated Holin (T-A Hol) Family
");
			INSERT INTO TEXTS(tag, value) VALUES ("search-database-analyses-protein-code-search-by-transporter-subclass-option", "1.E.44	The Putative Lactococcus lactis Holin (LLHol) Family
");
			INSERT INTO TEXTS(tag, value) VALUES ("search-database-analyses-protein-code-search-by-transporter-subclass-option", "1.E.45	The Xanthomonas Phage Holin (XanPHol) Family
");
			INSERT INTO TEXTS(tag, value) VALUES ("search-database-analyses-protein-code-search-by-transporter-subclass-option", "1.E.46	The Prophage Hp1 Holin (Hp1Hol) Family 
");
			INSERT INTO TEXTS(tag, value) VALUES ("search-database-analyses-protein-code-search-by-transporter-subclass-option", "1.E.47	The Caulobacter Phage Holin (CauHol) Family 
");
			INSERT INTO TEXTS(tag, value) VALUES ("search-database-analyses-protein-code-search-by-transporter-subclass-option", "1.E.48	The Enterobacterial Holin (EBHol) Family
");
			INSERT INTO TEXTS(tag, value) VALUES ("search-database-analyses-protein-code-search-by-transporter-subclass-option", "1.E.49	The Putative Treponema 4 TMS Holin (Tre4Hol) Family
");
			INSERT INTO TEXTS(tag, value) VALUES ("search-database-analyses-protein-code-search-by-transporter-subclass-option", "1.E.50	The Beta-Proteobacterial Holin (BP-Hol) Family
");
			INSERT INTO TEXTS(tag, value) VALUES ("search-database-analyses-protein-code-search-by-transporter-subclass-option", "1.E.51	The Putative Listeria Phage Holin (LP-Hol) Family
");
			INSERT INTO TEXTS(tag, value) VALUES ("search-database-analyses-protein-code-search-by-transporter-subclass-option", "1.E.52	The Flp/Fap Pilin Putative Holin (FFPP-Hol) Family
");
			INSERT INTO TEXTS(tag, value) VALUES ("search-database-analyses-protein-code-search-by-transporter-subclass-option", "1.F	Vesicle Fusion Pores
");
			INSERT INTO TEXTS(tag, value) VALUES ("search-database-analyses-protein-code-search-by-transporter-subclass-option", "1.F.1	The Synaptosomal Vesicle Fusion Pore (SVF-Pore) Family
");
			INSERT INTO TEXTS(tag, value) VALUES ("search-database-analyses-protein-code-search-by-transporter-subclass-option", "1.G	Viral Fusion Pores
");
			INSERT INTO TEXTS(tag, value) VALUES ("search-database-analyses-protein-code-search-by-transporter-subclass-option", "1.G.1	The Viral Pore-forming Membrane Fusion Protein-1 (VMFP1) Family
");
			INSERT INTO TEXTS(tag, value) VALUES ("search-database-analyses-protein-code-search-by-transporter-subclass-option", "1.G.2	The Viral Pore-forming Membrane Fusion Protein-2 (VMFP2) Family
");
			INSERT INTO TEXTS(tag, value) VALUES ("search-database-analyses-protein-code-search-by-transporter-subclass-option", "1.G.3	The Viral Pore-forming Membrane Fusion Protein-3 (VMFP3) Family
");
			INSERT INTO TEXTS(tag, value) VALUES ("search-database-analyses-protein-code-search-by-transporter-subclass-option", "1.G.4	The Viral Pore-forming Membrane Fusion Protein-4 (VMFP4) Family
");
			INSERT INTO TEXTS(tag, value) VALUES ("search-database-analyses-protein-code-search-by-transporter-subclass-option", "1.G.5	The Viral Pore-forming Membrane Fusion Protein-5 (VMFP5) Family
");
			INSERT INTO TEXTS(tag, value) VALUES ("search-database-analyses-protein-code-search-by-transporter-subclass-option", "1.G.6	The Hepadnaviral S Fusion Protein (HBV-S Protein) Family
");
			INSERT INTO TEXTS(tag, value) VALUES ("search-database-analyses-protein-code-search-by-transporter-subclass-option", "1.G.7	The Reovirus FAST Fusion Protein (R-FAST) Famly
");
			INSERT INTO TEXTS(tag, value) VALUES ("search-database-analyses-protein-code-search-by-transporter-subclass-option", "1.G.8	The Arenavirus Fusion Protein (AV-FP) Family
");
			INSERT INTO TEXTS(tag, value) VALUES ("search-database-analyses-protein-code-search-by-transporter-subclass-option", "1.G.9	The Syncytin (Syncytin) Family
");
			INSERT INTO TEXTS(tag, value) VALUES ("search-database-analyses-protein-code-search-by-transporter-subclass-option", "1.G.10	The Herpes Simplex Virus Membrane Fusion Complex (HSV-MFC) Family
");
			INSERT INTO TEXTS(tag, value) VALUES ("search-database-analyses-protein-code-search-by-transporter-subclass-option", "1.G.11	Poxvirus Cell Entry Protein Complex (PEP-C) Family
");
			INSERT INTO TEXTS(tag, value) VALUES ("search-database-analyses-protein-code-search-by-transporter-subclass-option", "1.G.12	The Avian Leukosis Virus gp95 Fusion Protein (ALV-gp95) Family
");
			INSERT INTO TEXTS(tag, value) VALUES ("search-database-analyses-protein-code-search-by-transporter-subclass-option", "1.H	Paracellular Channels
");
			INSERT INTO TEXTS(tag, value) VALUES ("search-database-analyses-protein-code-search-by-transporter-subclass-option", "1.H.1	The Claudin Tight Junction (Claudin) Family
");
			INSERT INTO TEXTS(tag, value) VALUES ("search-database-analyses-protein-code-search-by-transporter-subclass-option", "1.H.2	The Invertebrate PMP22-Claudin (Claudin2) Family
");
			INSERT INTO TEXTS(tag, value) VALUES ("search-database-analyses-protein-code-search-by-transporter-subclass-option", "1.I	Membrane-bounded Channels
");
			INSERT INTO TEXTS(tag, value) VALUES ("search-database-analyses-protein-code-search-by-transporter-subclass-option", "1.I.1	The Nuclear Pore Complex (NPC) Family
");
			INSERT INTO TEXTS(tag, value) VALUES ("search-database-analyses-protein-code-search-by-transporter-subclass-option", "1.I.2	The Plant Plasmodesmata (PPD) Family
");
			INSERT INTO TEXTS(tag, value) VALUES ("search-database-analyses-protein-code-search-by-transporter-subclass-option", "1.J	Virion Egress Pyramidal Apertures
");
			INSERT INTO TEXTS(tag, value) VALUES ("search-database-analyses-protein-code-search-by-transporter-subclass-option", "1.J.1	The Archaeal Virus-Associated Pyramid (A-VAP) Family
");
			INSERT INTO TEXTS(tag, value) VALUES ("search-database-analyses-protein-code-search-by-transporter-class-option", "2	Electrochemical Potential-driven Transporter");
			INSERT INTO TEXTS(tag, value) VALUES ("search-database-analyses-protein-code-search-by-transporter-subclass-option", "2.A	Porters (uniporters, symporters, antiporters)
");
			INSERT INTO TEXTS(tag, value) VALUES ("search-database-analyses-protein-code-search-by-transporter-subclass-option", "2.A.1	The Major Facilitator Superfamily (MFS)
");
			INSERT INTO TEXTS(tag, value) VALUES ("search-database-analyses-protein-code-search-by-transporter-subclass-option", "2.A.2	The Glycoside-Pentoside-Hexuronide (GPH):Cation Symporter Family
");
			INSERT INTO TEXTS(tag, value) VALUES ("search-database-analyses-protein-code-search-by-transporter-subclass-option", "2.A.3	The Amino Acid-Polyamine-Organocation (APC) Family
");
			INSERT INTO TEXTS(tag, value) VALUES ("search-database-analyses-protein-code-search-by-transporter-subclass-option", "2.A.4	The Cation Diffusion Facilitator (CDF) Family
");
			INSERT INTO TEXTS(tag, value) VALUES ("search-database-analyses-protein-code-search-by-transporter-subclass-option", "2.A.5	The Zinc (Zn2+)-Iron (Fe2+) Permease (ZIP) Family
");
			INSERT INTO TEXTS(tag, value) VALUES ("search-database-analyses-protein-code-search-by-transporter-subclass-option", "2.A.6	The Resistance-Nodulation-Cell Division (RND) Superfamily
");
			INSERT INTO TEXTS(tag, value) VALUES ("search-database-analyses-protein-code-search-by-transporter-subclass-option", "2.A.7	The Drug/Metabolite Transporter (DMT) Superfamily
");
			INSERT INTO TEXTS(tag, value) VALUES ("search-database-analyses-protein-code-search-by-transporter-subclass-option", "2.A.8	The Gluconate:H+ Symporter (GntP) Family
");
			INSERT INTO TEXTS(tag, value) VALUES ("search-database-analyses-protein-code-search-by-transporter-subclass-option", "2.A.9	The Cytochrome Oxidase Biogenesis (Oxa1) Family
");
			INSERT INTO TEXTS(tag, value) VALUES ("search-database-analyses-protein-code-search-by-transporter-subclass-option", "2.A.10	The 2-Keto-3-Deoxygluconate Transporter (KDGT) Family
");
			INSERT INTO TEXTS(tag, value) VALUES ("search-database-analyses-protein-code-search-by-transporter-subclass-option", "2.A.11	The Citrate-Mg2+:H+ (CitM) Citrate-Ca2+:H+ (CitH) Symporter (CitMHS) Family
");
			INSERT INTO TEXTS(tag, value) VALUES ("search-database-analyses-protein-code-search-by-transporter-subclass-option", "2.A.12	The ATP:ADP Antiporter (AAA) Family
");
			INSERT INTO TEXTS(tag, value) VALUES ("search-database-analyses-protein-code-search-by-transporter-subclass-option", "2.A.13	The C4-Dicarboxylate Uptake (Dcu) Family
");
			INSERT INTO TEXTS(tag, value) VALUES ("search-database-analyses-protein-code-search-by-transporter-subclass-option", "2.A.14	The Lactate Permease (LctP) Family
");
			INSERT INTO TEXTS(tag, value) VALUES ("search-database-analyses-protein-code-search-by-transporter-subclass-option", "2.A.15	The Betaine/Carnitine/Choline Transporter (BCCT) Family
");
			INSERT INTO TEXTS(tag, value) VALUES ("search-database-analyses-protein-code-search-by-transporter-subclass-option", "2.A.16	The Telurite-resistance/Dicarboxylate Transporter (TDT) Family
");
			INSERT INTO TEXTS(tag, value) VALUES ("search-database-analyses-protein-code-search-by-transporter-subclass-option", "2.A.17	The Proton-dependent Oligopeptide Transporter (POT) Family
");
			INSERT INTO TEXTS(tag, value) VALUES ("search-database-analyses-protein-code-search-by-transporter-subclass-option", "2.A.18	The Amino Acid/Auxin Permease (AAAP) Family
");
			INSERT INTO TEXTS(tag, value) VALUES ("search-database-analyses-protein-code-search-by-transporter-subclass-option", "2.A.19	The Ca2+:Cation Antiporter (CaCA) Family
");
			INSERT INTO TEXTS(tag, value) VALUES ("search-database-analyses-protein-code-search-by-transporter-subclass-option", "2.A.20	The Inorganic Phosphate Transporter (PiT) Family
");
			INSERT INTO TEXTS(tag, value) VALUES ("search-database-analyses-protein-code-search-by-transporter-subclass-option", "2.A.21	The Solute:Sodium Symporter (SSS) Family
");
			INSERT INTO TEXTS(tag, value) VALUES ("search-database-analyses-protein-code-search-by-transporter-subclass-option", "2.A.22	The Neurotransmitter:Sodium Symporter (NSS) Family
");
			INSERT INTO TEXTS(tag, value) VALUES ("search-database-analyses-protein-code-search-by-transporter-subclass-option", "2.A.23	The Dicarboxylate/Amino Acid:Cation (Na+ or H+) Symporter (DAACS) Family
");
			INSERT INTO TEXTS(tag, value) VALUES ("search-database-analyses-protein-code-search-by-transporter-subclass-option", "2.A.24	The 2-Hydroxycarboxylate Transporter (2-HCT) Family
");
			INSERT INTO TEXTS(tag, value) VALUES ("search-database-analyses-protein-code-search-by-transporter-subclass-option", "2.A.25	The Alanine or Glycine:Cation Symporter (AGCS) Family
");
			INSERT INTO TEXTS(tag, value) VALUES ("search-database-analyses-protein-code-search-by-transporter-subclass-option", "2.A.26	The Branched Chain Amino Acid:Cation Symporter (LIVCS) Family
");
			INSERT INTO TEXTS(tag, value) VALUES ("search-database-analyses-protein-code-search-by-transporter-subclass-option", "2.A.27	The Glutamate:Na+ Symporter (ESS) Family
");
			INSERT INTO TEXTS(tag, value) VALUES ("search-database-analyses-protein-code-search-by-transporter-subclass-option", "2.A.28	The Bile Acid:Na+ Symporter (BASS) Family
");
			INSERT INTO TEXTS(tag, value) VALUES ("search-database-analyses-protein-code-search-by-transporter-subclass-option", "2.A.29	The Mitochondrial Carrier (MC) Family 
");
			INSERT INTO TEXTS(tag, value) VALUES ("search-database-analyses-protein-code-search-by-transporter-subclass-option", "2.A.30	The Cation-Chloride Cotransporter (CCC) Family
");
			INSERT INTO TEXTS(tag, value) VALUES ("search-database-analyses-protein-code-search-by-transporter-subclass-option", "2.A.31	The Anion Exchanger (AE) Family
");
			INSERT INTO TEXTS(tag, value) VALUES ("search-database-analyses-protein-code-search-by-transporter-subclass-option", "2.A.32	The Silicon Transporter (Sit) Family
");
			INSERT INTO TEXTS(tag, value) VALUES ("search-database-analyses-protein-code-search-by-transporter-subclass-option", "2.A.33	The NhaA Na+:H+ Antiporter (NhaA) Family
");
			INSERT INTO TEXTS(tag, value) VALUES ("search-database-analyses-protein-code-search-by-transporter-subclass-option", "2.A.34	The NhaB Na+:H+ Antiporter (NhaB) Family
");
			INSERT INTO TEXTS(tag, value) VALUES ("search-database-analyses-protein-code-search-by-transporter-subclass-option", "2.A.35	The NhaC Na+:H+ Antiporter (NhaC) Family
");
			INSERT INTO TEXTS(tag, value) VALUES ("search-database-analyses-protein-code-search-by-transporter-subclass-option", "2.A.36	The Monovalent Cation:Proton Antiporter-1 (CPA1) Family
");
			INSERT INTO TEXTS(tag, value) VALUES ("search-database-analyses-protein-code-search-by-transporter-subclass-option", "2.A.37	The Monovalent Cation:Proton Antiporter-2 (CPA2) Family
");
			INSERT INTO TEXTS(tag, value) VALUES ("search-database-analyses-protein-code-search-by-transporter-subclass-option", "2.A.38	The K+ Transporter (Trk) Family
");
			INSERT INTO TEXTS(tag, value) VALUES ("search-database-analyses-protein-code-search-by-transporter-subclass-option", "2.A.39	The Nucleobase:Cation Symporter-1 (NCS1) Family
");
			INSERT INTO TEXTS(tag, value) VALUES ("search-database-analyses-protein-code-search-by-transporter-subclass-option", "2.A.40	The Nucleobase:Cation Symporter-2 (NCS2) Family
");
			INSERT INTO TEXTS(tag, value) VALUES ("search-database-analyses-protein-code-search-by-transporter-subclass-option", "2.A.41	The Concentrative Nucleoside Transporter (CNT) Family
");
			INSERT INTO TEXTS(tag, value) VALUES ("search-database-analyses-protein-code-search-by-transporter-subclass-option", "2.A.42	The Hydroxy/Aromatic Amino Acid Permease (HAAAP) Family
");
			INSERT INTO TEXTS(tag, value) VALUES ("search-database-analyses-protein-code-search-by-transporter-subclass-option", "2.A.43	The Lysosomal Cystine Transporter (LCT) Family
");
			INSERT INTO TEXTS(tag, value) VALUES ("search-database-analyses-protein-code-search-by-transporter-subclass-option", "2.A.45	The Arsenite-Antimonite (ArsB) Efflux Family
");
			INSERT INTO TEXTS(tag, value) VALUES ("search-database-analyses-protein-code-search-by-transporter-subclass-option", "2.A.46	The Benzoate:H+ Symporter (BenE) Family
");
			INSERT INTO TEXTS(tag, value) VALUES ("search-database-analyses-protein-code-search-by-transporter-subclass-option", "2.A.47	The Divalent Anion:Na+ Symporter (DASS) Family
");
			INSERT INTO TEXTS(tag, value) VALUES ("search-database-analyses-protein-code-search-by-transporter-subclass-option", "2.A.48	The Reduced Folate Carrier (RFC) Family 
");
			INSERT INTO TEXTS(tag, value) VALUES ("search-database-analyses-protein-code-search-by-transporter-subclass-option", "2.A.49	The Chloride Carrier/Channel (ClC) Family
");
			INSERT INTO TEXTS(tag, value) VALUES ("search-database-analyses-protein-code-search-by-transporter-subclass-option", "2.A.50	The Glycerol Uptake (GUP) Family
");
			INSERT INTO TEXTS(tag, value) VALUES ("search-database-analyses-protein-code-search-by-transporter-subclass-option", "2.A.51	The Chromate Ion Transporter (CHR) Family
");
			INSERT INTO TEXTS(tag, value) VALUES ("search-database-analyses-protein-code-search-by-transporter-subclass-option", "2.A.52	The Ni2+-Co2+ Transporter (NiCoT) Family
");
			INSERT INTO TEXTS(tag, value) VALUES ("search-database-analyses-protein-code-search-by-transporter-subclass-option", "2.A.53	The Sulfate Permease (SulP) Family
");
			INSERT INTO TEXTS(tag, value) VALUES ("search-database-analyses-protein-code-search-by-transporter-subclass-option", "2.A.54	The Mitochondrial Tricarboxylate Carrier (MTC) Family
");
			INSERT INTO TEXTS(tag, value) VALUES ("search-database-analyses-protein-code-search-by-transporter-subclass-option", "2.A.55	The Metal Ion (Mn2+-iron) Transporter (Nramp) Family
");
			INSERT INTO TEXTS(tag, value) VALUES ("search-database-analyses-protein-code-search-by-transporter-subclass-option", "2.A.56	The Tripartite ATP-independent Periplasmic Transporter (TRAP-T) Family
");
			INSERT INTO TEXTS(tag, value) VALUES ("search-database-analyses-protein-code-search-by-transporter-subclass-option", "2.A.57	The Equilibrative Nucleoside Transporter (ENT) Family
");
			INSERT INTO TEXTS(tag, value) VALUES ("search-database-analyses-protein-code-search-by-transporter-subclass-option", "2.A.58	The Phosphate:Na+ Symporter (PNaS) Family
");
			INSERT INTO TEXTS(tag, value) VALUES ("search-database-analyses-protein-code-search-by-transporter-subclass-option", "2.A.59	The Arsenical Resistance-3 (ACR3) Family
");
			INSERT INTO TEXTS(tag, value) VALUES ("search-database-analyses-protein-code-search-by-transporter-subclass-option", "2.A.60	The Organo Anion Transporter (OAT) Family
");
			INSERT INTO TEXTS(tag, value) VALUES ("search-database-analyses-protein-code-search-by-transporter-subclass-option", "2.A.61	The C4-dicarboxylate Uptake C (DcuC) Family
");
			INSERT INTO TEXTS(tag, value) VALUES ("search-database-analyses-protein-code-search-by-transporter-subclass-option", "2.A.62	The NhaD Na+:H+ Antiporter (NhaD) Family
");
			INSERT INTO TEXTS(tag, value) VALUES ("search-database-analyses-protein-code-search-by-transporter-subclass-option", "2.A.63	The Monovalent Cation (K+ or Na+):Proton Antiporter-3 (CPA3) Family
");
			INSERT INTO TEXTS(tag, value) VALUES ("search-database-analyses-protein-code-search-by-transporter-subclass-option", "2.A.64	The Twin Arginine Targeting (Tat) Family
");
			INSERT INTO TEXTS(tag, value) VALUES ("search-database-analyses-protein-code-search-by-transporter-subclass-option", "2.A.65	The Bilirubin Transporter (BRT) Family
");
			INSERT INTO TEXTS(tag, value) VALUES ("search-database-analyses-protein-code-search-by-transporter-subclass-option", "2.A.66	The Multidrug/Oligosaccharidyl-lipid/Polysaccharide (MOP) Flippase Superfamily
");
			INSERT INTO TEXTS(tag, value) VALUES ("search-database-analyses-protein-code-search-by-transporter-subclass-option", "2.A.67	The Oligopeptide Transporter (OPT) Family
");
			INSERT INTO TEXTS(tag, value) VALUES ("search-database-analyses-protein-code-search-by-transporter-subclass-option", "2.A.68	The p-Aminobenzoyl-glutamate Transporter (AbgT) Family
");
			INSERT INTO TEXTS(tag, value) VALUES ("search-database-analyses-protein-code-search-by-transporter-subclass-option", "2.A.69	The Auxin Efflux Carrier (AEC) Family
");
			INSERT INTO TEXTS(tag, value) VALUES ("search-database-analyses-protein-code-search-by-transporter-subclass-option", "2.A.70	The Malonate:Na+ Symporter (MSS) Family
");
			INSERT INTO TEXTS(tag, value) VALUES ("search-database-analyses-protein-code-search-by-transporter-subclass-option", "2.A.71	The Folate-Biopterin Transporter (FBT) Family
");
			INSERT INTO TEXTS(tag, value) VALUES ("search-database-analyses-protein-code-search-by-transporter-subclass-option", "2.A.72	The K+ Uptake Permease (KUP) Family
");
			INSERT INTO TEXTS(tag, value) VALUES ("search-database-analyses-protein-code-search-by-transporter-subclass-option", "2.A.73	The Short Chain Fatty Acid Uptake (AtoE) Family
");
			INSERT INTO TEXTS(tag, value) VALUES ("search-database-analyses-protein-code-search-by-transporter-subclass-option", "2.A.74	The 4 TMS Multidrug Endosomal Transporter (MET) Family
");
			INSERT INTO TEXTS(tag, value) VALUES ("search-database-analyses-protein-code-search-by-transporter-subclass-option", "2.A.75	The L-Lysine Exporter (LysE) Family
");
			INSERT INTO TEXTS(tag, value) VALUES ("search-database-analyses-protein-code-search-by-transporter-subclass-option", "2.A.76	The Resistance to Homoserine/Threonine (RhtB) Family 
");
			INSERT INTO TEXTS(tag, value) VALUES ("search-database-analyses-protein-code-search-by-transporter-subclass-option", "2.A.77	The Cadmium Resistance (CadD) Family
");
			INSERT INTO TEXTS(tag, value) VALUES ("search-database-analyses-protein-code-search-by-transporter-subclass-option", "2.A.78	The Branched Chain Amino Acid Exporter (LIV-E) Family
");
			INSERT INTO TEXTS(tag, value) VALUES ("search-database-analyses-protein-code-search-by-transporter-subclass-option", "2.A.79	The Threonine/Serine Exporter (ThrE) Family
");
			INSERT INTO TEXTS(tag, value) VALUES ("search-database-analyses-protein-code-search-by-transporter-subclass-option", "2.A.80	The Tricarboxylate Transporter (TTT) Family
");
			INSERT INTO TEXTS(tag, value) VALUES ("search-database-analyses-protein-code-search-by-transporter-subclass-option", "2.A.81	The Aspartate:Alanine Exchanger (AAEx) Family
");
			INSERT INTO TEXTS(tag, value) VALUES ("search-database-analyses-protein-code-search-by-transporter-subclass-option", "2.A.82	The Organic Solute Transporter (OST) Family
");
			INSERT INTO TEXTS(tag, value) VALUES ("search-database-analyses-protein-code-search-by-transporter-subclass-option", "2.A.83	The Na+-dependent Bicarbonate Transporter (SBT) Family
");
			INSERT INTO TEXTS(tag, value) VALUES ("search-database-analyses-protein-code-search-by-transporter-subclass-option", "2.A.84	The Chloroplast Maltose Exporter (MEX) Family
");
			INSERT INTO TEXTS(tag, value) VALUES ("search-database-analyses-protein-code-search-by-transporter-subclass-option", "2.A.85	The Aromatic Acid Exporter (ArAE) Family
");
			INSERT INTO TEXTS(tag, value) VALUES ("search-database-analyses-protein-code-search-by-transporter-subclass-option", "2.A.86	The Autoinducer-2 Exporter (AI-2E) Family (Formerly the PerM Family, TC #9.B.22)
");
			INSERT INTO TEXTS(tag, value) VALUES ("search-database-analyses-protein-code-search-by-transporter-subclass-option", "2.A.87	The Prokaryotic Riboflavin Transporter (P-RFT) Family
");
			INSERT INTO TEXTS(tag, value) VALUES ("search-database-analyses-protein-code-search-by-transporter-subclass-option", "2.A.88	Vitamin Uptake Transporter (VUT or ECF) Family
");
			INSERT INTO TEXTS(tag, value) VALUES ("search-database-analyses-protein-code-search-by-transporter-subclass-option", "2.A.89	The Vacuolar Iron Transporter (VIT) Family
");
			INSERT INTO TEXTS(tag, value) VALUES ("search-database-analyses-protein-code-search-by-transporter-subclass-option", "2.A.90	The Vitamin A Receptor/Transporter (STRA6) Family
");
			INSERT INTO TEXTS(tag, value) VALUES ("search-database-analyses-protein-code-search-by-transporter-subclass-option", "2.A.91	Mitochondrial tRNA Import Complex (M-RIC) (Formerly 9.C.8)
");
			INSERT INTO TEXTS(tag, value) VALUES ("search-database-analyses-protein-code-search-by-transporter-subclass-option", "2.A.92	The Choline Transporter-like (CTL) Family
");
			INSERT INTO TEXTS(tag, value) VALUES ("search-database-analyses-protein-code-search-by-transporter-subclass-option", "2.A.93	The Unknown BART Superfamily-1 (UBS1) Family
");
			INSERT INTO TEXTS(tag, value) VALUES ("search-database-analyses-protein-code-search-by-transporter-subclass-option", "2.A.94	The Phosphate Permease (Pho1) Family
");
			INSERT INTO TEXTS(tag, value) VALUES ("search-database-analyses-protein-code-search-by-transporter-subclass-option", "2.A.95	The 6TMS Neutral Amino Acid Transporter (NAAT) Family
");
			INSERT INTO TEXTS(tag, value) VALUES ("search-database-analyses-protein-code-search-by-transporter-subclass-option", "2.A.96	The YaaH (YaaH) Family
");
			INSERT INTO TEXTS(tag, value) VALUES ("search-database-analyses-protein-code-search-by-transporter-subclass-option", "2.A.97	The Mitochondrial Inner Membrane K+/H+ and Ca2+/H+ Exchanger (LetM1) Family
");
			INSERT INTO TEXTS(tag, value) VALUES ("search-database-analyses-protein-code-search-by-transporter-subclass-option", "2.A.98	The Putative Sulfate Exporter (PSE) Family
");
			INSERT INTO TEXTS(tag, value) VALUES ("search-database-analyses-protein-code-search-by-transporter-subclass-option", "2.A.99	The 6TMS Ni2+ uptake transporter (HupE-UreJ) Family 
");
			INSERT INTO TEXTS(tag, value) VALUES ("search-database-analyses-protein-code-search-by-transporter-subclass-option", "2.A.100	The Ferroportin (Fpn) Family
");
			INSERT INTO TEXTS(tag, value) VALUES ("search-database-analyses-protein-code-search-by-transporter-subclass-option", "2.A.101	The Malonate Uptake (MatC) Family (Formerly UIT1)
");
			INSERT INTO TEXTS(tag, value) VALUES ("search-database-analyses-protein-code-search-by-transporter-subclass-option", "2.A.102	The Putative 4-Toluene Sulfonate Uptake Permease (TSUP) Family
");
			INSERT INTO TEXTS(tag, value) VALUES ("search-database-analyses-protein-code-search-by-transporter-subclass-option", "2.A.103	The Bacterial Murein Precursor Exporter (MPE) Family
");
			INSERT INTO TEXTS(tag, value) VALUES ("search-database-analyses-protein-code-search-by-transporter-subclass-option", "2.A.104	The L-Alanine Exporter (AlaE) Family
");
			INSERT INTO TEXTS(tag, value) VALUES ("search-database-analyses-protein-code-search-by-transporter-subclass-option", "2.A.105	The Mitochondrial Pyruvate Carrier (MPC) Family
");
			INSERT INTO TEXTS(tag, value) VALUES ("search-database-analyses-protein-code-search-by-transporter-subclass-option", "2.A.106	The Ca2+:H+ Antiporter-2 (CaCA2) Family
");
			INSERT INTO TEXTS(tag, value) VALUES ("search-database-analyses-protein-code-search-by-transporter-subclass-option", "2.A.110	The heme transporter, heme-responsive gene protein (HRG) Family
");
			INSERT INTO TEXTS(tag, value) VALUES ("search-database-analyses-protein-code-search-by-transporter-subclass-option", "2.A.207	2.A.207 The MntP Mn2+ exporter (MntP) Family
");
			INSERT INTO TEXTS(tag, value) VALUES ("search-database-analyses-protein-code-search-by-transporter-subclass-option", "2.A.208	The Iron/Lead Transporter (ILT) Superfamily
");
			INSERT INTO TEXTS(tag, value) VALUES ("search-database-analyses-protein-code-search-by-transporter-subclass-option", "2.B	Nonribosomally synthesized porters
");
			INSERT INTO TEXTS(tag, value) VALUES ("search-database-analyses-protein-code-search-by-transporter-subclass-option", "2.B.1	The Valinomycin Carrier (Valinomycin) Family
");
			INSERT INTO TEXTS(tag, value) VALUES ("search-database-analyses-protein-code-search-by-transporter-subclass-option", "2.B.2	The Monensin (Monensin) Family
");
			INSERT INTO TEXTS(tag, value) VALUES ("search-database-analyses-protein-code-search-by-transporter-subclass-option", "2.B.3	The Nigericin (Nigericin) Family
");
			INSERT INTO TEXTS(tag, value) VALUES ("search-database-analyses-protein-code-search-by-transporter-subclass-option", "2.B.4	The Macrotetrolide Antibiotic (MA) Family
");
			INSERT INTO TEXTS(tag, value) VALUES ("search-database-analyses-protein-code-search-by-transporter-subclass-option", "2.B.5	The Macrocyclic Polyether (MP) Family
");
			INSERT INTO TEXTS(tag, value) VALUES ("search-database-analyses-protein-code-search-by-transporter-subclass-option", "2.B.6	The Ionomycin (Ionomycin) Family
");
			INSERT INTO TEXTS(tag, value) VALUES ("search-database-analyses-protein-code-search-by-transporter-subclass-option", "2.B.7	The Transmembrane &#945;-helical Peptide Phospholipid Translocation (TMP-PLT) Family
");
			INSERT INTO TEXTS(tag, value) VALUES ("search-database-analyses-protein-code-search-by-transporter-subclass-option", "2.B.8	The Bafilomycin A1 (Bafilomycin) Family
");
			INSERT INTO TEXTS(tag, value) VALUES ("search-database-analyses-protein-code-search-by-transporter-subclass-option", "2.B.9	The Cell Penetrating Peptide (CPP) Family
");
			INSERT INTO TEXTS(tag, value) VALUES ("search-database-analyses-protein-code-search-by-transporter-subclass-option", "2.B.10	The Synthetic CPP, Transportan (Transportan) Family 
");
			INSERT INTO TEXTS(tag, value) VALUES ("search-database-analyses-protein-code-search-by-transporter-subclass-option", "2.B.12	The Salinomycin (Salinomycin) Family
");
			INSERT INTO TEXTS(tag, value) VALUES ("search-database-analyses-protein-code-search-by-transporter-subclass-option", "2.C	Ion-gradient-driven energizers
");
			INSERT INTO TEXTS(tag, value) VALUES ("search-database-analyses-protein-code-search-by-transporter-subclass-option", "2.C.1	The TonB-ExbB-ExbD/TolA-TolQ-TolR (TonB) Family of Auxiliary Proteins for Energization of Outer Membrane Receptor (OMR)-mediated Active Transport
");
			INSERT INTO TEXTS(tag, value) VALUES ("search-database-analyses-protein-code-search-by-transporter-class-option", "3	Primary Active Transporter");
			INSERT INTO TEXTS(tag, value) VALUES ("search-database-analyses-protein-code-search-by-transporter-subclass-option", "3.A	P-P-bond-hydrolysis-driven transporters
");
			INSERT INTO TEXTS(tag, value) VALUES ("search-database-analyses-protein-code-search-by-transporter-subclass-option", "3.A.1	The ATP-binding Cassette (ABC) Superfamily
");
			INSERT INTO TEXTS(tag, value) VALUES ("search-database-analyses-protein-code-search-by-transporter-subclass-option", "3.A.2	The H+- or Na+-translocating F-type, V-type and A-type ATPase (F-ATPase) Superfamily
");
			INSERT INTO TEXTS(tag, value) VALUES ("search-database-analyses-protein-code-search-by-transporter-subclass-option", "3.A.3	The P-type ATPase (P-ATPase) Superfamily
");
			INSERT INTO TEXTS(tag, value) VALUES ("search-database-analyses-protein-code-search-by-transporter-subclass-option", "3.A.4	The Arsenite-Antimonite (ArsAB) Efflux Family
");
			INSERT INTO TEXTS(tag, value) VALUES ("search-database-analyses-protein-code-search-by-transporter-subclass-option", "3.A.5	The General Secretory Pathway (Sec) Family
");
			INSERT INTO TEXTS(tag, value) VALUES ("search-database-analyses-protein-code-search-by-transporter-subclass-option", "3.A.6	The Type III (Virulence-related) Secretory Pathway (IIISP) Family
");
			INSERT INTO TEXTS(tag, value) VALUES ("search-database-analyses-protein-code-search-by-transporter-subclass-option", "3.A.7	The Type IV (Conjugal DNA-Protein Transfer or VirB) Secretory Pathway (IVSP) Family
");
			INSERT INTO TEXTS(tag, value) VALUES ("search-database-analyses-protein-code-search-by-transporter-subclass-option", "3.A.8	The Mitochondrial Protein Translocase (MPT) Family
");
			INSERT INTO TEXTS(tag, value) VALUES ("search-database-analyses-protein-code-search-by-transporter-subclass-option", "3.A.9	The Chloroplast Envelope Protein Translocase (CEPT or Tic-Toc) Family
");
			INSERT INTO TEXTS(tag, value) VALUES ("search-database-analyses-protein-code-search-by-transporter-subclass-option", "3.A.10	The H+, Na+ or H+, Na+-translocating Pyrophosphatase (M+-PPase) Family
");
			INSERT INTO TEXTS(tag, value) VALUES ("search-database-analyses-protein-code-search-by-transporter-subclass-option", "3.A.11	The Bacterial Competence-related DNA Transformation Transporter (DNA-T) Family
");
			INSERT INTO TEXTS(tag, value) VALUES ("search-database-analyses-protein-code-search-by-transporter-subclass-option", "3.A.12	The Septal DNA Translocator (S-DNA-T) Family
");
			INSERT INTO TEXTS(tag, value) VALUES ("search-database-analyses-protein-code-search-by-transporter-subclass-option", "3.A.13	The Filamentous Phage Exporter (FPhE) Family
");
			INSERT INTO TEXTS(tag, value) VALUES ("search-database-analyses-protein-code-search-by-transporter-subclass-option", "3.A.14	The Fimbrilin/Protein Exporter (FPE) Family
");
			INSERT INTO TEXTS(tag, value) VALUES ("search-database-analyses-protein-code-search-by-transporter-subclass-option", "3.A.15	The Outer Membrane Protein Secreting Main Terminal Branch (MTB) Family
");
			INSERT INTO TEXTS(tag, value) VALUES ("search-database-analyses-protein-code-search-by-transporter-subclass-option", "3.A.16	The Endoplasmic Reticular Retrotranslocon (ER-RT) Family
");
			INSERT INTO TEXTS(tag, value) VALUES ("search-database-analyses-protein-code-search-by-transporter-subclass-option", "3.A.17	The Phage T7 Injectisome (T7 Injectisome) Family
");
			INSERT INTO TEXTS(tag, value) VALUES ("search-database-analyses-protein-code-search-by-transporter-subclass-option", "3.A.18	The Nuclear mRNA Exporter (mRNA-E) Family
");
			INSERT INTO TEXTS(tag, value) VALUES ("search-database-analyses-protein-code-search-by-transporter-subclass-option", "3.A.19	The TMS Recognition/Insertion Complex (TRC) Family
");
			INSERT INTO TEXTS(tag, value) VALUES ("search-database-analyses-protein-code-search-by-transporter-subclass-option", "3.A.20	The Peroxisomal Protein Importer (PPI) Family
");
			INSERT INTO TEXTS(tag, value) VALUES ("search-database-analyses-protein-code-search-by-transporter-subclass-option", "3.A.21	The C-terminal Tail-Anchored Membrane Protein Biogenesis/ Insertion Complex (TAMP-B) Family
");
			INSERT INTO TEXTS(tag, value) VALUES ("search-database-analyses-protein-code-search-by-transporter-subclass-option", "3.A.22	The Transcription-coupled TREX/TAP Nuclear mRNA Export Complex (TREX) Family
");
			INSERT INTO TEXTS(tag, value) VALUES ("search-database-analyses-protein-code-search-by-transporter-subclass-option", "3.A.23	The Type VI Symbiosis/Virulence Secretory Pathway (VISP) Family
");
			INSERT INTO TEXTS(tag, value) VALUES ("search-database-analyses-protein-code-search-by-transporter-subclass-option", "3.A.24	Type VII or ESX Protein Secretion System (T7SS) Family
");
			INSERT INTO TEXTS(tag, value) VALUES ("search-database-analyses-protein-code-search-by-transporter-subclass-option", "3.A.25	The Symbiont-specific ERAD-like Machinery (SELMA) Family
");
			INSERT INTO TEXTS(tag, value) VALUES ("search-database-analyses-protein-code-search-by-transporter-subclass-option", "3.A.144	The Functionally Uncharacterized ABC2-1 (U-ABC2-1) Family
");
			INSERT INTO TEXTS(tag, value) VALUES ("search-database-analyses-protein-code-search-by-transporter-subclass-option", "3.B	Decarboxylation-driven transporters
");
			INSERT INTO TEXTS(tag, value) VALUES ("search-database-analyses-protein-code-search-by-transporter-subclass-option", "3.B.1	The Na+-transporting Carboxylic Acid Decarboxylase (NaT-DC) Family
");
			INSERT INTO TEXTS(tag, value) VALUES ("search-database-analyses-protein-code-search-by-transporter-subclass-option", "3.C	Methyltransfer-driven transporters
");
			INSERT INTO TEXTS(tag, value) VALUES ("search-database-analyses-protein-code-search-by-transporter-subclass-option", "3.C.1	The Na+ Transporting Methyltetrahydromethanopterin:Coenzyme M Methyltransferase (NaT-MMM) Family
");
			INSERT INTO TEXTS(tag, value) VALUES ("search-database-analyses-protein-code-search-by-transporter-subclass-option", "3.D	Oxidoreduction-driven transporters
");
			INSERT INTO TEXTS(tag, value) VALUES ("search-database-analyses-protein-code-search-by-transporter-subclass-option", "3.D.1	The H+ or Na+-translocating NADH Dehydrogenase (NDH) Family
");
			INSERT INTO TEXTS(tag, value) VALUES ("search-database-analyses-protein-code-search-by-transporter-subclass-option", "3.D.2	The Proton-translocating Transhydrogenase (PTH) Family
");
			INSERT INTO TEXTS(tag, value) VALUES ("search-database-analyses-protein-code-search-by-transporter-subclass-option", "3.D.3	The Proton-translocating Quinol:Cytochrome c Reductase (QCR) Superfamily
");
			INSERT INTO TEXTS(tag, value) VALUES ("search-database-analyses-protein-code-search-by-transporter-subclass-option", "3.D.4	The Proton-translocating Cytochrome Oxidase (COX) Superfamily
");
			INSERT INTO TEXTS(tag, value) VALUES ("search-database-analyses-protein-code-search-by-transporter-subclass-option", "3.D.5	The Na+-translocating NADH:Quinone Dehydrogenase (Na-NDH) Family
");
			INSERT INTO TEXTS(tag, value) VALUES ("search-database-analyses-protein-code-search-by-transporter-subclass-option", "3.D.6	The Putative Ion (H+ or Na+)-translocating NADH:Ferredoxin Oxidoreductase (NFO) Family
");
			INSERT INTO TEXTS(tag, value) VALUES ("search-database-analyses-protein-code-search-by-transporter-subclass-option", "3.D.7	The H2:Heterodisulfide Oxidoreductase (HHO) Family
");
			INSERT INTO TEXTS(tag, value) VALUES ("search-database-analyses-protein-code-search-by-transporter-subclass-option", "3.D.8	The Na+- or H+-Pumping Formyl Methanofuran Dehydrogenase (FMF-DH) Family
");
			INSERT INTO TEXTS(tag, value) VALUES ("search-database-analyses-protein-code-search-by-transporter-subclass-option", "3.D.9	The H+-translocating F420H2 Dehydrogenase (F420H2DH) Family
");
			INSERT INTO TEXTS(tag, value) VALUES ("search-database-analyses-protein-code-search-by-transporter-subclass-option", "3.D.10	The Prokaryotic Succinate Dehydrogenase (SDH) Family
");
			INSERT INTO TEXTS(tag, value) VALUES ("search-database-analyses-protein-code-search-by-transporter-subclass-option", "3.E	Light absorption-driven transporters
");
			INSERT INTO TEXTS(tag, value) VALUES ("search-database-analyses-protein-code-search-by-transporter-subclass-option", "3.E.1	The Ion-translocating Microbial Rhodopsin (MR) Family
");
			INSERT INTO TEXTS(tag, value) VALUES ("search-database-analyses-protein-code-search-by-transporter-subclass-option", "3.E.2	The Photosynthetic Reaction Center (PRC) Family
");
			INSERT INTO TEXTS(tag, value) VALUES ("search-database-analyses-protein-code-search-by-transporter-class-option", "4	Group Translocator");
			INSERT INTO TEXTS(tag, value) VALUES ("search-database-analyses-protein-code-search-by-transporter-subclass-option", "4.A	Phosphotransfer-driven Group Translocators
");
			INSERT INTO TEXTS(tag, value) VALUES ("search-database-analyses-protein-code-search-by-transporter-subclass-option", "4.A.1	The PTS Glucose-Glucoside (Glc) Family
");
			INSERT INTO TEXTS(tag, value) VALUES ("search-database-analyses-protein-code-search-by-transporter-subclass-option", "4.A.2	The PTS Fructose-Mannitol (Fru) Family
");
			INSERT INTO TEXTS(tag, value) VALUES ("search-database-analyses-protein-code-search-by-transporter-subclass-option", "4.A.3	The PTS Lactose-N,N'-Diacetylchitobiose-&#946;-glucoside (Lac) Family
");
			INSERT INTO TEXTS(tag, value) VALUES ("search-database-analyses-protein-code-search-by-transporter-subclass-option", "4.A.4	The PTS Glucitol (Gut) Family
");
			INSERT INTO TEXTS(tag, value) VALUES ("search-database-analyses-protein-code-search-by-transporter-subclass-option", "4.A.5	The PTS Galactitol (Gat) Family
");
			INSERT INTO TEXTS(tag, value) VALUES ("search-database-analyses-protein-code-search-by-transporter-subclass-option", "4.A.6	The PTS Mannose-Fructose-Sorbose (Man) Family
");
			INSERT INTO TEXTS(tag, value) VALUES ("search-database-analyses-protein-code-search-by-transporter-subclass-option", "4.A.7	The PTS L-Ascorbate (L-Asc) Family
");
			INSERT INTO TEXTS(tag, value) VALUES ("search-database-analyses-protein-code-search-by-transporter-subclass-option", "4.B	Nicotinamide ribonucleoside uptake transporters
");
			INSERT INTO TEXTS(tag, value) VALUES ("search-database-analyses-protein-code-search-by-transporter-subclass-option", "4.B.1	The Nicotinamide Ribonucleoside (NR) Uptake Permease (PnuC) Family
");
			INSERT INTO TEXTS(tag, value) VALUES ("search-database-analyses-protein-code-search-by-transporter-subclass-option", "4.C	Acyl CoA ligase-coupled transporters
");
			INSERT INTO TEXTS(tag, value) VALUES ("search-database-analyses-protein-code-search-by-transporter-subclass-option", "4.C.1	The Proposed Fatty Acid Transporter (FAT) Family
");
			INSERT INTO TEXTS(tag, value) VALUES ("search-database-analyses-protein-code-search-by-transporter-subclass-option", "4.C.2	The Carnitine O-Acyl Transferase (CrAT) Family
");
			INSERT INTO TEXTS(tag, value) VALUES ("search-database-analyses-protein-code-search-by-transporter-subclass-option", "4.C.3	The Acyl-CoA Thioesterase (AcoT) Family
");
			INSERT INTO TEXTS(tag, value) VALUES ("search-database-analyses-protein-code-search-by-transporter-subclass-option", "4.D	Polysaccharide Synthase/Exporters
");
			INSERT INTO TEXTS(tag, value) VALUES ("search-database-analyses-protein-code-search-by-transporter-subclass-option", "4.D.1	The Putative Vectorial Glycosyl Polymerization (VGP) Family
");
			INSERT INTO TEXTS(tag, value) VALUES ("search-database-analyses-protein-code-search-by-transporter-subclass-option", "4.D.2	The COG0392; UPF0104 Putative Transporter (COG0392) Family
");
			INSERT INTO TEXTS(tag, value) VALUES ("search-database-analyses-protein-code-search-by-transporter-class-option", "5	Transmembrane Electron Carrier");
			INSERT INTO TEXTS(tag, value) VALUES ("search-database-analyses-protein-code-search-by-transporter-subclass-option", "5.A	Transmembrane 2-electron transfer carriers
");
			INSERT INTO TEXTS(tag, value) VALUES ("search-database-analyses-protein-code-search-by-transporter-subclass-option", "5.A.1	The Disulfide Bond Oxidoreductase D (DsbD) Family
");
			INSERT INTO TEXTS(tag, value) VALUES ("search-database-analyses-protein-code-search-by-transporter-subclass-option", "5.A.2	The Disulfide Bond Oxidoreductase B (DsbB) Family
");
			INSERT INTO TEXTS(tag, value) VALUES ("search-database-analyses-protein-code-search-by-transporter-subclass-option", "5.A.3	The Prokaryotic Molybdopterin-containing Oxidoreductase (PMO) Family
");
			INSERT INTO TEXTS(tag, value) VALUES ("search-database-analyses-protein-code-search-by-transporter-subclass-option", "5.B	Transmembrane 1-electron transfer carriers
");
			INSERT INTO TEXTS(tag, value) VALUES ("search-database-analyses-protein-code-search-by-transporter-subclass-option", "5.B.1	The Phagocyte (gp91phox) NADPH Oxidase Family
");
			INSERT INTO TEXTS(tag, value) VALUES ("search-database-analyses-protein-code-search-by-transporter-subclass-option", "5.B.2	The Eukaryotic Cytochrome b561 (Cytb561) Family
");
			INSERT INTO TEXTS(tag, value) VALUES ("search-database-analyses-protein-code-search-by-transporter-subclass-option", "5.B.3	The Geobacter Nanowire Electron Transfer (G-NET) Family
");
			INSERT INTO TEXTS(tag, value) VALUES ("search-database-analyses-protein-code-search-by-transporter-subclass-option", "5.B.4	The Plant Photosystem I Supercomplex (PSI) Family
");
			INSERT INTO TEXTS(tag, value) VALUES ("search-database-analyses-protein-code-search-by-transporter-subclass-option", "5.B.5	The Extracellular Metal Oxido-Reductase (EMOR) Family
");
			INSERT INTO TEXTS(tag, value) VALUES ("search-database-analyses-protein-code-search-by-transporter-class-option", "8	Accessory Factors Involved in Transpor");
			INSERT INTO TEXTS(tag, value) VALUES ("search-database-analyses-protein-code-search-by-transporter-subclass-option", "8.A	Auxiliary transport proteins
");
			INSERT INTO TEXTS(tag, value) VALUES ("search-database-analyses-protein-code-search-by-transporter-subclass-option", "8.A.1	The Membrane Fusion Protein (MFP) Family
");
			INSERT INTO TEXTS(tag, value) VALUES ("search-database-analyses-protein-code-search-by-transporter-subclass-option", "8.A.2	The Secretin Auxiliary Lipoprotein (SAL) Family
");
			INSERT INTO TEXTS(tag, value) VALUES ("search-database-analyses-protein-code-search-by-transporter-subclass-option", "8.A.3	The Cytoplasmic Membrane-Periplasmic Auxiliary-1 (MPA1) Protein with Cytoplasmic (C) Domain (MPA1-C or MPA1+C) Family
");
			INSERT INTO TEXTS(tag, value) VALUES ("search-database-analyses-protein-code-search-by-transporter-subclass-option", "8.A.4	The Cytoplasmic Membrane-Periplasmic Auxiliary-2 (MPA2) Family
");
			INSERT INTO TEXTS(tag, value) VALUES ("search-database-analyses-protein-code-search-by-transporter-subclass-option", "8.A.5	The Voltage-gated K+ Channel &#946;-subunit (Kv&#946;) Family
");
			INSERT INTO TEXTS(tag, value) VALUES ("search-database-analyses-protein-code-search-by-transporter-subclass-option", "8.A.6	The Auxiliary Nutrient Transporter (ANT) Family
");
			INSERT INTO TEXTS(tag, value) VALUES ("search-database-analyses-protein-code-search-by-transporter-subclass-option", "8.A.7	The Phosphotransferase System Enzyme I (EI) Family
");
			INSERT INTO TEXTS(tag, value) VALUES ("search-database-analyses-protein-code-search-by-transporter-subclass-option", "8.A.8	The Phosphotransferase System HPr (HPr) Family
");
			INSERT INTO TEXTS(tag, value) VALUES ("search-database-analyses-protein-code-search-by-transporter-subclass-option", "8.A.9	The rBAT Transport Accessory Protein (rBAT) Family
");
			INSERT INTO TEXTS(tag, value) VALUES ("search-database-analyses-protein-code-search-by-transporter-subclass-option", "8.A.10	The Slow Voltage-gated K+ Channel Accessory Protein (MinK) Family
");
			INSERT INTO TEXTS(tag, value) VALUES ("search-database-analyses-protein-code-search-by-transporter-subclass-option", "8.A.11	The Immunophilin-like Prolyl:peptidyl Isomerase Regulator (I-PPI) Family
");
			INSERT INTO TEXTS(tag, value) VALUES ("search-database-analyses-protein-code-search-by-transporter-subclass-option", "8.A.12	ABC Bacteriocin Exporter Accessory Protein (BEA) Family
");
			INSERT INTO TEXTS(tag, value) VALUES ("search-database-analyses-protein-code-search-by-transporter-subclass-option", "8.A.13	The Tetratricopeptide Repeat (Tpr1) Family
");
			INSERT INTO TEXTS(tag, value) VALUES ("search-database-analyses-protein-code-search-by-transporter-subclass-option", "8.A.14	The Ca2+-activated K+ Channel Auxiliary Subunit Slowpoke-&#946; (Slo&#946;) Family
");
			INSERT INTO TEXTS(tag, value) VALUES ("search-database-analyses-protein-code-search-by-transporter-subclass-option", "8.A.15	The K+ Channel Accessory Protein (KChAP) Family
");
			INSERT INTO TEXTS(tag, value) VALUES ("search-database-analyses-protein-code-search-by-transporter-subclass-option", "8.A.16	The Ca+ Channel Auxiliary Subunit &#947;1-&#947;8 (CCA&#947;) Family
");
			INSERT INTO TEXTS(tag, value) VALUES ("search-database-analyses-protein-code-search-by-transporter-subclass-option", "8.A.17	The Na+ Channel Auxiliary Subunit &#946;1-&#946;4 (SCA-&#946;) Family
");
			INSERT INTO TEXTS(tag, value) VALUES ("search-database-analyses-protein-code-search-by-transporter-subclass-option", "8.A.18	The Ca2+ Channel Auxiliary Subunit &#945;2&#948; Types 1-4 (CCA-&#945;2&#948;) Family
");
			INSERT INTO TEXTS(tag, value) VALUES ("search-database-analyses-protein-code-search-by-transporter-subclass-option", "8.A.19	The Sodium Channel Auxiliary Subunit TipE (SCAT) Family
");
			INSERT INTO TEXTS(tag, value) VALUES ("search-database-analyses-protein-code-search-by-transporter-subclass-option", "8.A.20	The Plant/Algal/Chlorella Nitrate Transporter Accessory Protein
");
			INSERT INTO TEXTS(tag, value) VALUES ("search-database-analyses-protein-code-search-by-transporter-subclass-option", "8.A.21	The Stomatin/Podocin/Band 7/Nephrosis.2/SPFH (Stomatin) Family
");
			INSERT INTO TEXTS(tag, value) VALUES ("search-database-analyses-protein-code-search-by-transporter-subclass-option", "8.A.22	The Ca2+ Channel Auxiliary Subunit &#946; Types 1-4 (CCA-&#946;) Family
");
			INSERT INTO TEXTS(tag, value) VALUES ("search-database-analyses-protein-code-search-by-transporter-subclass-option", "8.A.23	The Basigin (Basigin) Family
");
			INSERT INTO TEXTS(tag, value) VALUES ("search-database-analyses-protein-code-search-by-transporter-subclass-option", "8.A.24	The Ezrin/Radixin/Moesin-binding Phosphoprotein 50 (EBP50) Family
");
			INSERT INTO TEXTS(tag, value) VALUES ("search-database-analyses-protein-code-search-by-transporter-subclass-option", "8.A.25	The Ezrin/Radixin/Moesin (Ezrin) Family
");
			INSERT INTO TEXTS(tag, value) VALUES ("search-database-analyses-protein-code-search-by-transporter-subclass-option", "8.A.26	The Caveolin (Caveolin) Family
");
			INSERT INTO TEXTS(tag, value) VALUES ("search-database-analyses-protein-code-search-by-transporter-subclass-option", "8.A.27	The Phospholipid Importer &#946;-subunit (PLI-&#946;) Family
");
			INSERT INTO TEXTS(tag, value) VALUES ("search-database-analyses-protein-code-search-by-transporter-subclass-option", "8.A.28	The Ankyrin (Ankyrin) Family
");
			INSERT INTO TEXTS(tag, value) VALUES ("search-database-analyses-protein-code-search-by-transporter-subclass-option", "8.A.29	The Homer1 (Homer1) Family of Excitation-Contraction Coupling Proteins 
");
			INSERT INTO TEXTS(tag, value) VALUES ("search-database-analyses-protein-code-search-by-transporter-subclass-option", "8.A.30	The Nedd4-Family Interacting Protein-2 (Nedd4) Family
");
			INSERT INTO TEXTS(tag, value) VALUES ("search-database-analyses-protein-code-search-by-transporter-subclass-option", "8.A.31	The Ly-6 Neurotoxin-like Protein1 Precursor (Lynx1) Family 
");
			INSERT INTO TEXTS(tag, value) VALUES ("search-database-analyses-protein-code-search-by-transporter-subclass-option", "8.A.32	The &#946;-Amyloid Cleaving Enzyme (BACE1) Family
");
			INSERT INTO TEXTS(tag, value) VALUES ("search-database-analyses-protein-code-search-by-transporter-subclass-option", "8.A.33	The Fatty Acid Binding Protein (FABP) Family
");
			INSERT INTO TEXTS(tag, value) VALUES ("search-database-analyses-protein-code-search-by-transporter-subclass-option", "8.A.34	The Endophilin (Endophilin) Family
");
			INSERT INTO TEXTS(tag, value) VALUES ("search-database-analyses-protein-code-search-by-transporter-subclass-option", "8.A.35	The Mycobacterial Membrane Protein Small (MmpS) Family
");
			INSERT INTO TEXTS(tag, value) VALUES ("search-database-analyses-protein-code-search-by-transporter-subclass-option", "8.A.36	The Trp-3 (SPE-41) Interaction Protein (SPE-38) Family
");
			INSERT INTO TEXTS(tag, value) VALUES ("search-database-analyses-protein-code-search-by-transporter-subclass-option", "8.A.37	The Hepcidin (Hepcidin) Family
");
			INSERT INTO TEXTS(tag, value) VALUES ("search-database-analyses-protein-code-search-by-transporter-subclass-option", "8.A.38	The Animal Macoilin Regulator of ion Channels (Macoilin) Family
");
			INSERT INTO TEXTS(tag, value) VALUES ("search-database-analyses-protein-code-search-by-transporter-subclass-option", "8.A.39	The Homeobox; Penetratin (Penetratin) Family
");
			INSERT INTO TEXTS(tag, value) VALUES ("search-database-analyses-protein-code-search-by-transporter-subclass-option", "8.B	Ribosomally synthesized protein/peptide toxins/agonists that target channels and carriers
");
			INSERT INTO TEXTS(tag, value) VALUES ("search-database-analyses-protein-code-search-by-transporter-subclass-option", "8.B.1	The Long (4C-C) Scorpion Toxin (L-ST) Superfamily
");
			INSERT INTO TEXTS(tag, value) VALUES ("search-database-analyses-protein-code-search-by-transporter-subclass-option", "8.B.2	The Short Scorpion Toxin (SST) Superfamily
");
			INSERT INTO TEXTS(tag, value) VALUES ("search-database-analyses-protein-code-search-by-transporter-subclass-option", "8.B.3	The Huwentoxin-1 (Huwentoxin-1) Family
");
			INSERT INTO TEXTS(tag, value) VALUES ("search-database-analyses-protein-code-search-by-transporter-subclass-option", "8.B.4	The Conotoxin T (Conotoxin) Family
");
			INSERT INTO TEXTS(tag, value) VALUES ("search-database-analyses-protein-code-search-by-transporter-subclass-option", "8.B.5	The Na+/K+/Ca2+ Channel Targeting Tarantula Huwentoxin (THT) Family
");
			INSERT INTO TEXTS(tag, value) VALUES ("search-database-analyses-protein-code-search-by-transporter-subclass-option", "8.B.6	The Ca2+ Channel-targeting Spider Toxin (CST) Family
");
			INSERT INTO TEXTS(tag, value) VALUES ("search-database-analyses-protein-code-search-by-transporter-subclass-option", "8.B.7	The Cl- Channel Peptide Inhibitor (GaTx1) Family
");
			INSERT INTO TEXTS(tag, value) VALUES ("search-database-analyses-protein-code-search-by-transporter-subclass-option", "8.B.8	The &#945;-KTx15 scorpion toxin (&#945;-KTx15) Family
");
			INSERT INTO TEXTS(tag, value) VALUES ("search-database-analyses-protein-code-search-by-transporter-subclass-option", "8.B.9	The Triflin Toxin (Triflin or CRISP) Family
");
			INSERT INTO TEXTS(tag, value) VALUES ("search-database-analyses-protein-code-search-by-transporter-subclass-option", "8.B.10	The Psalmotoxin-1 (PcTx1) Family
");
			INSERT INTO TEXTS(tag, value) VALUES ("search-database-analyses-protein-code-search-by-transporter-subclass-option", "8.B.11	The Sea Anemone Peptide Toxin (APETx) Family
");
			INSERT INTO TEXTS(tag, value) VALUES ("search-database-analyses-protein-code-search-by-transporter-subclass-option", "8.B.12	The Spider Toxin (STx2) Family
");
			INSERT INTO TEXTS(tag, value) VALUES ("search-database-analyses-protein-code-search-by-transporter-subclass-option", "8.B.13	The Sea Anemone Peptide Toxin Class 2 (Kalicludine) Family
");
			INSERT INTO TEXTS(tag, value) VALUES ("search-database-analyses-protein-code-search-by-transporter-subclass-option", "8.B.14	The Sea Anemone Peptide Toxin, Class 1 (BgK) Family
");
			INSERT INTO TEXTS(tag, value) VALUES ("search-database-analyses-protein-code-search-by-transporter-subclass-option", "8.B.15	The Sea Anenome Peptide Toxin Class 4 (SHTX) Family
");
			INSERT INTO TEXTS(tag, value) VALUES ("search-database-analyses-protein-code-search-by-transporter-subclass-option", "8.B.16	The Maurocalcine Family
");
			INSERT INTO TEXTS(tag, value) VALUES ("search-database-analyses-protein-code-search-by-transporter-subclass-option", "8.B.17	The Sea Anemone Peptide Toxin Class III (ShI) Family
");
			INSERT INTO TEXTS(tag, value) VALUES ("search-database-analyses-protein-code-search-by-transporter-subclass-option", "8.B.18	The Glucose PTS Inhibitor Dysgalacticin (Dysgalacticin) Family
");
			INSERT INTO TEXTS(tag, value) VALUES ("search-database-analyses-protein-code-search-by-transporter-subclass-option", "8.C	Non-ribosomally synthesized toxins that target channels and carriers
");
			INSERT INTO TEXTS(tag, value) VALUES ("search-database-analyses-protein-code-search-by-transporter-subclass-option", "8.C.1	The Picrotoxin (Picrotoxin) Family
");
			INSERT INTO TEXTS(tag, value) VALUES ("search-database-analyses-protein-code-search-by-transporter-subclass-option", "8.C.2	The Talatisamine (Talatisamine) Family
");
			INSERT INTO TEXTS(tag, value) VALUES ("search-database-analyses-protein-code-search-by-transporter-subclass-option", "8.C.3	The Bilastine (Bilastine) Family
");
			INSERT INTO TEXTS(tag, value) VALUES ("search-database-analyses-protein-code-search-by-transporter-class-option", "9	Incompletely Characterized Transport System");
			INSERT INTO TEXTS(tag, value) VALUES ("search-database-analyses-protein-code-search-by-transporter-subclass-option", "9.A	Recognized transporters of unknown biochemical mechanism
");
			INSERT INTO TEXTS(tag, value) VALUES ("search-database-analyses-protein-code-search-by-transporter-subclass-option", "9.A.1	The Non ABC Multidrug Exporter (N-MDE) Family
");
			INSERT INTO TEXTS(tag, value) VALUES ("search-database-analyses-protein-code-search-by-transporter-subclass-option", "9.A.2	The Endomembrane protein-70 (EMP70) Family
");
			INSERT INTO TEXTS(tag, value) VALUES ("search-database-analyses-protein-code-search-by-transporter-subclass-option", "9.A.4	The YggT or Fanciful K+ Uptake-B (FkuB; YggT) Family
");
			INSERT INTO TEXTS(tag, value) VALUES ("search-database-analyses-protein-code-search-by-transporter-subclass-option", "9.A.5	The Putative Arginine Transporter (ArgW) Family
");
			INSERT INTO TEXTS(tag, value) VALUES ("search-database-analyses-protein-code-search-by-transporter-subclass-option", "9.A.6	The ATP Exporter (ATP-E)  Family
");
			INSERT INTO TEXTS(tag, value) VALUES ("search-database-analyses-protein-code-search-by-transporter-subclass-option", "9.A.7	Lactoloccin 972 Immunity Protein (LactococcinIP) Family
");
			INSERT INTO TEXTS(tag, value) VALUES ("search-database-analyses-protein-code-search-by-transporter-subclass-option", "9.A.8	The Ferrous Iron Uptake (FeoB) Family
");
			INSERT INTO TEXTS(tag, value) VALUES ("search-database-analyses-protein-code-search-by-transporter-subclass-option", "9.A.9	The Low Affinity Fe2+ Transporter (FeT) Family
");
			INSERT INTO TEXTS(tag, value) VALUES ("search-database-analyses-protein-code-search-by-transporter-subclass-option", "9.A.10	The Iron/Lead Transporter (ILT) Superfamily
");
			INSERT INTO TEXTS(tag, value) VALUES ("search-database-analyses-protein-code-search-by-transporter-subclass-option", "9.A.11	The Dipicolinic Acid Transporter (DPA-T) Family
");
			INSERT INTO TEXTS(tag, value) VALUES ("search-database-analyses-protein-code-search-by-transporter-subclass-option", "9.A.12	The Peptidoglycolipid Addressing Protein (GAP) Family
");
			INSERT INTO TEXTS(tag, value) VALUES ("search-database-analyses-protein-code-search-by-transporter-subclass-option", "9.A.13	The Colicin J Lysis (Cjl) Family
");
			INSERT INTO TEXTS(tag, value) VALUES ("search-database-analyses-protein-code-search-by-transporter-subclass-option", "9.A.14	The G-protein-coupled receptor (GPCR) Family
");
			INSERT INTO TEXTS(tag, value) VALUES ("search-database-analyses-protein-code-search-by-transporter-subclass-option", "9.A.15	The Autophagy-related Phagophore-formation Transporter (APT) Family
");
			INSERT INTO TEXTS(tag, value) VALUES ("search-database-analyses-protein-code-search-by-transporter-subclass-option", "9.A.16	The Lysosomal Protein Import (LPI) Family
");
			INSERT INTO TEXTS(tag, value) VALUES ("search-database-analyses-protein-code-search-by-transporter-subclass-option", "9.A.17	The Integral Membrane Peroxisomal Protein Importer-2 (PPI2) Family
");
			INSERT INTO TEXTS(tag, value) VALUES ("search-database-analyses-protein-code-search-by-transporter-subclass-option", "9.A.18	The Peptide Uptake Permease (PUP) Family
");
			INSERT INTO TEXTS(tag, value) VALUES ("search-database-analyses-protein-code-search-by-transporter-subclass-option", "9.A.19	The Lipid Intermediate Transporter (Arv1) Family
");
			INSERT INTO TEXTS(tag, value) VALUES ("search-database-analyses-protein-code-search-by-transporter-subclass-option", "9.A.20	The Low Affinity Cation Transporter (LACatT) Family
");
			INSERT INTO TEXTS(tag, value) VALUES ("search-database-analyses-protein-code-search-by-transporter-subclass-option", "9.A.21	The ComC DNA Uptake Competence (ComC) Family
");
			INSERT INTO TEXTS(tag, value) VALUES ("search-database-analyses-protein-code-search-by-transporter-subclass-option", "9.A.22	The NhaE Na+(K+):H+ Antiporter (NhaE) Family
");
			INSERT INTO TEXTS(tag, value) VALUES ("search-database-analyses-protein-code-search-by-transporter-subclass-option", "9.A.23	The Niacin/Nicotinamide Transporter (NNT) Family
");
			INSERT INTO TEXTS(tag, value) VALUES ("search-database-analyses-protein-code-search-by-transporter-subclass-option", "9.A.24	The Mitochondrial Outer Membrane Insertion Pathway (MOM-IP) Family
");
			INSERT INTO TEXTS(tag, value) VALUES ("search-database-analyses-protein-code-search-by-transporter-subclass-option", "9.A.25	The Por Protein Secretin System (PorSS) Family
");
			INSERT INTO TEXTS(tag, value) VALUES ("search-database-analyses-protein-code-search-by-transporter-subclass-option", "9.A.26	The Lipid-translocating Exporter (LTE) Family
");
			INSERT INTO TEXTS(tag, value) VALUES ("search-database-analyses-protein-code-search-by-transporter-subclass-option", "9.A.27	The Non-Classical Protein Exporter (NCPE) Family
");
			INSERT INTO TEXTS(tag, value) VALUES ("search-database-analyses-protein-code-search-by-transporter-subclass-option", "9.A.28	The Ethanolamine Facilitator (EAF) Family
");
			INSERT INTO TEXTS(tag, value) VALUES ("search-database-analyses-protein-code-search-by-transporter-subclass-option", "9.A.29	The Lantibiotic Immunity Protein (LIP) Family
");
			INSERT INTO TEXTS(tag, value) VALUES ("search-database-analyses-protein-code-search-by-transporter-subclass-option", "9.A.30	The Tellurium Ion Resistance (TerC) Family
");
			INSERT INTO TEXTS(tag, value) VALUES ("search-database-analyses-protein-code-search-by-transporter-subclass-option", "9.A.31	The Putative SdpAB Peptide Antibiotic-like Killing Factor Exporter (SdpAB) Family
");
			INSERT INTO TEXTS(tag, value) VALUES ("search-database-analyses-protein-code-search-by-transporter-subclass-option", "9.A.32	The SdpC (Peptide-Antibiotic Killer Factor) Immunity Protein, SdpI (SdpI) Family
");
			INSERT INTO TEXTS(tag, value) VALUES ("search-database-analyses-protein-code-search-by-transporter-subclass-option", "9.A.33	The Pyocin R2 Phage P2 Tail Fiber Protein (Pyocin R2) Family
");
			INSERT INTO TEXTS(tag, value) VALUES ("search-database-analyses-protein-code-search-by-transporter-subclass-option", "9.A.35	The Peptide Translocating Syndecan (Syndecan) Family
");
			INSERT INTO TEXTS(tag, value) VALUES ("search-database-analyses-protein-code-search-by-transporter-subclass-option", "9.A.36	The Ca2+-dependent Phospholipid Scramblase (Scramblase) Family
");
			INSERT INTO TEXTS(tag, value) VALUES ("search-database-analyses-protein-code-search-by-transporter-subclass-option", "9.A.37	The Nuclear Import Tax Protein (Tax) Family
");
			INSERT INTO TEXTS(tag, value) VALUES ("search-database-analyses-protein-code-search-by-transporter-subclass-option", "9.A.38	The Bacteriocin Immunity Protein (BIP) Family
");
			INSERT INTO TEXTS(tag, value) VALUES ("search-database-analyses-protein-code-search-by-transporter-subclass-option", "9.A.39	The Gram-positive Bacterial Hemoglobin Receptor (Isd) Family
");
			INSERT INTO TEXTS(tag, value) VALUES ("search-database-analyses-protein-code-search-by-transporter-subclass-option", "9.A.40	The HlyC/CorC (HCC) Family
");
			INSERT INTO TEXTS(tag, value) VALUES ("search-database-analyses-protein-code-search-by-transporter-subclass-option", "9.A.41	The Capsular Polysaccharide Exporter (CPS-E) Family
");
			INSERT INTO TEXTS(tag, value) VALUES ("search-database-analyses-protein-code-search-by-transporter-subclass-option", "9.A.42	The Mycobacterial PPE41 Protein Secretion System (MPSS) Family
");
			INSERT INTO TEXTS(tag, value) VALUES ("search-database-analyses-protein-code-search-by-transporter-subclass-option", "9.A.43	The Cadmium tolerance Efflux Pump (CTEP) Family
");
			INSERT INTO TEXTS(tag, value) VALUES ("search-database-analyses-protein-code-search-by-transporter-subclass-option", "9.A.45	The Magnesium Transporter1 (MagT1) Family
");
			INSERT INTO TEXTS(tag, value) VALUES ("search-database-analyses-protein-code-search-by-transporter-subclass-option", "9.A.46	The Clarin (CLRN) Family
");
			INSERT INTO TEXTS(tag, value) VALUES ("search-database-analyses-protein-code-search-by-transporter-subclass-option", "9.A.47	The Tight Adherence (Pilus) Biogenesis Apparatus (TABA) Family
");
			INSERT INTO TEXTS(tag, value) VALUES ("search-database-analyses-protein-code-search-by-transporter-subclass-option", "9.A.48	The Unconventional Protein Secretion (UPS) System
");
			INSERT INTO TEXTS(tag, value) VALUES ("search-database-analyses-protein-code-search-by-transporter-subclass-option", "9.A.50	The Nuclear t-RNA exporter (t-Exporter) Family
");
			INSERT INTO TEXTS(tag, value) VALUES ("search-database-analyses-protein-code-search-by-transporter-subclass-option", "9.A.51	The Francisella Siderophore Transporter (FST) Family
");
			INSERT INTO TEXTS(tag, value) VALUES ("search-database-analyses-protein-code-search-by-transporter-subclass-option", "9.A.52	The Microcin J25 (Microsin J25) Family
");
			INSERT INTO TEXTS(tag, value) VALUES ("search-database-analyses-protein-code-search-by-transporter-subclass-option", "9.A.53	The Eukaryotic Riboflavin Transporter (E-RFT) Family
");
			INSERT INTO TEXTS(tag, value) VALUES ("search-database-analyses-protein-code-search-by-transporter-subclass-option", "9.A.54	The Lysosomal Cobalamin (B12) Transporter (L-B12T) Family
");
			INSERT INTO TEXTS(tag, value) VALUES ("search-database-analyses-protein-code-search-by-transporter-subclass-option", "9.A.55	The TMEM205 (TMEM205) Family
");
			INSERT INTO TEXTS(tag, value) VALUES ("search-database-analyses-protein-code-search-by-transporter-subclass-option", "9.A.56	The Outer Membrane Anion Porin, TsaT (TsaT) Family
");
			INSERT INTO TEXTS(tag, value) VALUES ("search-database-analyses-protein-code-search-by-transporter-subclass-option", "9.A.57	The RegIII&gamma (RegIII&gamma) Family
");
			INSERT INTO TEXTS(tag, value) VALUES ("search-database-analyses-protein-code-search-by-transporter-subclass-option", "9.A.58	The Sweet; PQ-loop; Saliva; MtN3 (Sweet) Family 
");
			INSERT INTO TEXTS(tag, value) VALUES ("search-database-analyses-protein-code-search-by-transporter-subclass-option", "9.A.59	The Bacteriocin : Enterocin/Pediocin (BEP) Family
");
			INSERT INTO TEXTS(tag, value) VALUES ("search-database-analyses-protein-code-search-by-transporter-subclass-option", "9.A.60	The Small Nuclear RNA Exporter (snRNA-E)
");
			INSERT INTO TEXTS(tag, value) VALUES ("search-database-analyses-protein-code-search-by-transporter-subclass-option", "9.A.62	The AAA-ATPase, Bcs1 (Bcs1) Family
");
			INSERT INTO TEXTS(tag, value) VALUES ("search-database-analyses-protein-code-search-by-transporter-subclass-option", "9.A.63	The NEAT-domain containing methaemoglobin heme sequestration (N-MHS) Family
");
			INSERT INTO TEXTS(tag, value) VALUES ("search-database-analyses-protein-code-search-by-transporter-subclass-option", "9.B	Putative transport proteins
");
			INSERT INTO TEXTS(tag, value) VALUES ("search-database-analyses-protein-code-search-by-transporter-subclass-option", "9.B.1	The Integral Membrane CAAX Protease (CAAX Protease) Family
");
			INSERT INTO TEXTS(tag, value) VALUES ("search-database-analyses-protein-code-search-by-transporter-subclass-option", "9.B.2	The Integral Membrane CAAX Protease-2 (CAAX Protease2) Family
");
			INSERT INTO TEXTS(tag, value) VALUES ("search-database-analyses-protein-code-search-by-transporter-subclass-option", "9.B.3	The Cysteine Protease Binding Protein-8 (CPBP8) Family
");
			INSERT INTO TEXTS(tag, value) VALUES ("search-database-analyses-protein-code-search-by-transporter-subclass-option", "9.B.4	The Universal Stress Protein-B (UspB) Family
");
			INSERT INTO TEXTS(tag, value) VALUES ("search-database-analyses-protein-code-search-by-transporter-subclass-option", "9.B.5	The KX Blood-group Antigen (KXA) Family
");
			INSERT INTO TEXTS(tag, value) VALUES ("search-database-analyses-protein-code-search-by-transporter-subclass-option", "9.B.6	The Toxic Hok/Gef Protein (Hok/Gef) Family
");
			INSERT INTO TEXTS(tag, value) VALUES ("search-database-analyses-protein-code-search-by-transporter-subclass-option", "9.B.7	The Putative Sulfate Transporter (CysZ) Family
");
			INSERT INTO TEXTS(tag, value) VALUES ("search-database-analyses-protein-code-search-by-transporter-subclass-option", "9.B.9	The Urate Transporter (UAT) Family
");
			INSERT INTO TEXTS(tag, value) VALUES ("search-database-analyses-protein-code-search-by-transporter-subclass-option", "9.B.10	The Putative Tripartite Zn2+ Transporter (TZT) Family
");
			INSERT INTO TEXTS(tag, value) VALUES ("search-database-analyses-protein-code-search-by-transporter-subclass-option", "9.B.11	The Gp27/5 T4-baseplate (T4-BP) Family
");
			INSERT INTO TEXTS(tag, value) VALUES ("search-database-analyses-protein-code-search-by-transporter-subclass-option", "9.B.12	The (Salt or Low Temperature) Stress-induced Hydrophobic Peptide (SHP) Family
");
			INSERT INTO TEXTS(tag, value) VALUES ("search-database-analyses-protein-code-search-by-transporter-subclass-option", "9.B.13	The Putative Pore-forming Entericidin (ECN) Family
");
			INSERT INTO TEXTS(tag, value) VALUES ("search-database-analyses-protein-code-search-by-transporter-subclass-option", "9.B.14	The Putative Heme Handling Protein (HHP) Family
");
			INSERT INTO TEXTS(tag, value) VALUES ("search-database-analyses-protein-code-search-by-transporter-subclass-option", "9.B.15	The 4 TMS YbhQ (YbhQ) Family
");
			INSERT INTO TEXTS(tag, value) VALUES ("search-database-analyses-protein-code-search-by-transporter-subclass-option", "9.B.16	The Putative Ductin Channel (Ductin) Family
");
			INSERT INTO TEXTS(tag, value) VALUES ("search-database-analyses-protein-code-search-by-transporter-subclass-option", "9.B.17	The VAMP-associated protein (VAP) Family
");
			INSERT INTO TEXTS(tag, value) VALUES ("search-database-analyses-protein-code-search-by-transporter-subclass-option", "9.B.18	The SecDF-associated Single Transmembrane Protein, YajC (YajC) Family
");
			INSERT INTO TEXTS(tag, value) VALUES ("search-database-analyses-protein-code-search-by-transporter-subclass-option", "9.B.19	The Mn2+ Homeostasis Protein (MnHP) Family
");
			INSERT INTO TEXTS(tag, value) VALUES ("search-database-analyses-protein-code-search-by-transporter-subclass-option", "9.B.20	The Putative Mg2+ Transporter-C (MgtC) Family
");
			INSERT INTO TEXTS(tag, value) VALUES ("search-database-analyses-protein-code-search-by-transporter-subclass-option", "9.B.21	The Frataxin (Frataxin) Family
");
			INSERT INTO TEXTS(tag, value) VALUES ("search-database-analyses-protein-code-search-by-transporter-subclass-option", "9.B.22	The Leukotoxin Secretion Morphogenesis Protein C (MorC) Family
");
			INSERT INTO TEXTS(tag, value) VALUES ("search-database-analyses-protein-code-search-by-transporter-subclass-option", "9.B.23	The Mistic (Mistic) Family
");
			INSERT INTO TEXTS(tag, value) VALUES ("search-database-analyses-protein-code-search-by-transporter-subclass-option", "9.B.24	The DUF805 or PF05656 (DUF805) Family
");
			INSERT INTO TEXTS(tag, value) VALUES ("search-database-analyses-protein-code-search-by-transporter-subclass-option", "9.B.25	The Mitochondrial Inner/Outer Membrane Fusion (MMF) Family
");
			INSERT INTO TEXTS(tag, value) VALUES ("search-database-analyses-protein-code-search-by-transporter-subclass-option", "9.B.27	The DedA or YdjX-Z (DedA) Family
");
			INSERT INTO TEXTS(tag, value) VALUES ("search-database-analyses-protein-code-search-by-transporter-subclass-option", "9.B.28	The Putative Permease Duf318 (Duf318) Family
");
			INSERT INTO TEXTS(tag, value) VALUES ("search-database-analyses-protein-code-search-by-transporter-subclass-option", "9.B.30	The Hly III (Hly III) Family
");
			INSERT INTO TEXTS(tag, value) VALUES ("search-database-analyses-protein-code-search-by-transporter-subclass-option", "9.B.31	The YqiH (YqiH) Family
");
			INSERT INTO TEXTS(tag, value) VALUES ("search-database-analyses-protein-code-search-by-transporter-subclass-option", "9.B.32	The DUF3302 or Pfam11742 (YibI) Family
");
			INSERT INTO TEXTS(tag, value) VALUES ("search-database-analyses-protein-code-search-by-transporter-subclass-option", "9.B.33	The Sensor Histidine Kinase (SHK) Family
");
			INSERT INTO TEXTS(tag, value) VALUES ("search-database-analyses-protein-code-search-by-transporter-subclass-option", "9.B.34	The Kinase/Phosphatase/Cyclic-GMP Synthase/Cyclic di-GMP Hydrolase (KPSH) Family
");
			INSERT INTO TEXTS(tag, value) VALUES ("search-database-analyses-protein-code-search-by-transporter-subclass-option", "9.B.35	The Putative Thyronine-Transporting Transthyretin (Transthyretin) Family
");
			INSERT INTO TEXTS(tag, value) VALUES ("search-database-analyses-protein-code-search-by-transporter-subclass-option", "9.B.36	The Acid Resistance Membrane Protein (HdeD) Family
");
			INSERT INTO TEXTS(tag, value) VALUES ("search-database-analyses-protein-code-search-by-transporter-subclass-option", "9.B.37	The Huntington-interacting Protein 14 (HIP14) Family
");
			INSERT INTO TEXTS(tag, value) VALUES ("search-database-analyses-protein-code-search-by-transporter-subclass-option", "9.B.38	The Myelin Proteolipid Protein (MPLP) Family
");
			INSERT INTO TEXTS(tag, value) VALUES ("search-database-analyses-protein-code-search-by-transporter-subclass-option", "9.B.39	The Long Chain Fatty Acid Translocase (lcFAT) Family
");
			INSERT INTO TEXTS(tag, value) VALUES ("search-database-analyses-protein-code-search-by-transporter-subclass-option", "9.B.40	The DotA/TraY (DotA/TraY) Family
");
			INSERT INTO TEXTS(tag, value) VALUES ("search-database-analyses-protein-code-search-by-transporter-subclass-option", "9.B.41	The Occludin (Occludin) Family
");
			INSERT INTO TEXTS(tag, value) VALUES ("search-database-analyses-protein-code-search-by-transporter-subclass-option", "9.B.42	The ExeAB (ExeAB) Secretin Assembly/Export Complex
");
			INSERT INTO TEXTS(tag, value) VALUES ("search-database-analyses-protein-code-search-by-transporter-subclass-option", "9.B.43	The YedZ (YedZ) Family
");
			INSERT INTO TEXTS(tag, value) VALUES ("search-database-analyses-protein-code-search-by-transporter-subclass-option", "9.B.44	The YiaA-YiaB (YiaAB) Family
");
			INSERT INTO TEXTS(tag, value) VALUES ("search-database-analyses-protein-code-search-by-transporter-subclass-option", "9.B.45	The Arg/Asp/Asp (RDD) Family
");
			INSERT INTO TEXTS(tag, value) VALUES ("search-database-analyses-protein-code-search-by-transporter-subclass-option", "9.B.46	The Staphylococcus aureus Putative Quorum Sensing Peptide Exporter, AgrB (AgrB) Family
");
			INSERT INTO TEXTS(tag, value) VALUES ("search-database-analyses-protein-code-search-by-transporter-subclass-option", "9.B.47	 The &#947;-Secretase (&#947;-Secretase) Family
");
			INSERT INTO TEXTS(tag, value) VALUES ("search-database-analyses-protein-code-search-by-transporter-subclass-option", "9.B.48	The Cyclotide (Cyclotide) Family
");
			INSERT INTO TEXTS(tag, value) VALUES ("search-database-analyses-protein-code-search-by-transporter-subclass-option", "9.B.49	The Unknown IT-2 (UIT2) Family
");
			INSERT INTO TEXTS(tag, value) VALUES ("search-database-analyses-protein-code-search-by-transporter-subclass-option", "9.B.50	The Unknown IT-3 (UIT3) Family
");
			INSERT INTO TEXTS(tag, value) VALUES ("search-database-analyses-protein-code-search-by-transporter-subclass-option", "9.B.51	The Unknown IT-4 (UIT4) Family
");
			INSERT INTO TEXTS(tag, value) VALUES ("search-database-analyses-protein-code-search-by-transporter-subclass-option", "9.B.52	The Unknown IT-5 (UIT5) Family
");
			INSERT INTO TEXTS(tag, value) VALUES ("search-database-analyses-protein-code-search-by-transporter-subclass-option", "9.B.53	The Unknown IT-6 (UIT6) Family
");
			INSERT INTO TEXTS(tag, value) VALUES ("search-database-analyses-protein-code-search-by-transporter-subclass-option", "9.B.54	The Unknown IT-7 (UIT7) Family
");
			INSERT INTO TEXTS(tag, value) VALUES ("search-database-analyses-protein-code-search-by-transporter-subclass-option", "9.B.55	The Unknown IT-8 (UIT8) Family
");
			INSERT INTO TEXTS(tag, value) VALUES ("search-database-analyses-protein-code-search-by-transporter-subclass-option", "9.B.56	The Unknown IT-9 (UIT9) Family
");
			INSERT INTO TEXTS(tag, value) VALUES ("search-database-analyses-protein-code-search-by-transporter-subclass-option", "9.B.57	The Unknown IT-10 (UIT10) Family
");
			INSERT INTO TEXTS(tag, value) VALUES ("search-database-analyses-protein-code-search-by-transporter-subclass-option", "9.B.58	The Unknown IT-11 (UIT11) Family
");
			INSERT INTO TEXTS(tag, value) VALUES ("search-database-analyses-protein-code-search-by-transporter-subclass-option", "9.B.59	The Putative Peptide Transporter Carbon Starvation CstA (CstA) Family
");
			INSERT INTO TEXTS(tag, value) VALUES ("search-database-analyses-protein-code-search-by-transporter-subclass-option", "9.B.60	The Glutamine Dumper 1 (GDU1) Family
");
			INSERT INTO TEXTS(tag, value) VALUES ("search-database-analyses-protein-code-search-by-transporter-subclass-option", "9.B.61	The Putative Pore-forming Hydrogenosomal Membrane Protein Hmp35 (Hmp35 ) Family
");
			INSERT INTO TEXTS(tag, value) VALUES ("search-database-analyses-protein-code-search-by-transporter-subclass-option", "9.B.62	The Copper Resistance (CopD) Family
");
			INSERT INTO TEXTS(tag, value) VALUES ("search-database-analyses-protein-code-search-by-transporter-subclass-option", "9.B.63	Human T-Lymphotropic Virus I P13 protein (HTLV1-P13) Family
");
			INSERT INTO TEXTS(tag, value) VALUES ("search-database-analyses-protein-code-search-by-transporter-subclass-option", "9.B.64	The Putative Cholesterol Transporter (Start1) Family
");
			INSERT INTO TEXTS(tag, value) VALUES ("search-database-analyses-protein-code-search-by-transporter-subclass-option", "9.B.65	The Putative Transporter (YhgE) Family
");
			INSERT INTO TEXTS(tag, value) VALUES ("search-database-analyses-protein-code-search-by-transporter-subclass-option", "9.B.66	The Animal Nonclassical Protein Secretion (NPS) Family
");
			INSERT INTO TEXTS(tag, value) VALUES ("search-database-analyses-protein-code-search-by-transporter-subclass-option", "9.B.67	The Putative Inorganic Carbon (HCO3-) Transporter/O-antigen Polymerase (ICT/OAP) Family
");
			INSERT INTO TEXTS(tag, value) VALUES ("search-database-analyses-protein-code-search-by-transporter-subclass-option", "9.B.68	The Putative Na-independent Organic Solute Carrier Protein (OSCP1) Family
");
			INSERT INTO TEXTS(tag, value) VALUES ("search-database-analyses-protein-code-search-by-transporter-subclass-option", "9.B.69	The Putative Cobalt Transporter (CbtAB) Family
");
			INSERT INTO TEXTS(tag, value) VALUES ("search-database-analyses-protein-code-search-by-transporter-subclass-option", "9.B.70	The Multicomponent Putative SpoIIIAE Exporter (SpoIIIA-E) Family
");
			INSERT INTO TEXTS(tag, value) VALUES ("search-database-analyses-protein-code-search-by-transporter-subclass-option", "9.B.71	The Camphor Resistance (CrcB) Family
");
			INSERT INTO TEXTS(tag, value) VALUES ("search-database-analyses-protein-code-search-by-transporter-subclass-option", "9.B.72	The 4 TMS GlpM (GlpM) Family
");
			INSERT INTO TEXTS(tag, value) VALUES ("search-database-analyses-protein-code-search-by-transporter-subclass-option", "9.B.73	Chloroplast Envelope/Cyanobacterial Membrane Protein (CemA) Family
");
			INSERT INTO TEXTS(tag, value) VALUES ("search-database-analyses-protein-code-search-by-transporter-subclass-option", "9.B.74	The Phage Infection Protein (PIP) Family
");
			INSERT INTO TEXTS(tag, value) VALUES ("search-database-analyses-protein-code-search-by-transporter-subclass-option", "9.B.75	The Ethanol Utilization/Transport (Eut) Protein Family
");
			INSERT INTO TEXTS(tag, value) VALUES ("search-database-analyses-protein-code-search-by-transporter-subclass-option", "9.B.76	The Goadsporin Immunity Protein, GodI (GodI) Family
");
			INSERT INTO TEXTS(tag, value) VALUES ("search-database-analyses-protein-code-search-by-transporter-subclass-option", "9.B.77	The Meckel Syndrome Protein (Meckelin) Family 
");
			INSERT INTO TEXTS(tag, value) VALUES ("search-database-analyses-protein-code-search-by-transporter-subclass-option", "9.B.78	The Minor Capsid Protein, gp7 of Baccilus subtilis Phage SPP1 (gp7) Family 
");
			INSERT INTO TEXTS(tag, value) VALUES ("search-database-analyses-protein-code-search-by-transporter-subclass-option", "9.B.79	The Putative Metal Transporter (PmtA) Family
");
			INSERT INTO TEXTS(tag, value) VALUES ("search-database-analyses-protein-code-search-by-transporter-subclass-option", "9.B.80	The Bacillus Phage &#966;29 (a Podovirus) DNA Ejection System (&#966;29-E) Family
");
			INSERT INTO TEXTS(tag, value) VALUES ("search-database-analyses-protein-code-search-by-transporter-subclass-option", "9.B.81	The MceB Immunity Protein (MceB) Family
");
			INSERT INTO TEXTS(tag, value) VALUES ("search-database-analyses-protein-code-search-by-transporter-subclass-option", "9.B.82	Endoplasmic Reticulum Retrieval Protein1 (Putative Heavy Metal Transporter) (Rer1) Family
");
			INSERT INTO TEXTS(tag, value) VALUES ("search-database-analyses-protein-code-search-by-transporter-subclass-option", "9.B.83	The Possible Outer Membrane Secretory Protein LeoA (LeoA) Family
");
			INSERT INTO TEXTS(tag, value) VALUES ("search-database-analyses-protein-code-search-by-transporter-subclass-option", "9.B.84	The Hepatic Selenoprotein-P (SelP or SePP) Family
");
			INSERT INTO TEXTS(tag, value) VALUES ("search-database-analyses-protein-code-search-by-transporter-subclass-option", "9.B.85	The Outer Membrane Lipoprotein-A (OmlA) Family
");
			INSERT INTO TEXTS(tag, value) VALUES ("search-database-analyses-protein-code-search-by-transporter-subclass-option", "9.B.86	The Propionicin (Propionicin) Family
");
			INSERT INTO TEXTS(tag, value) VALUES ("search-database-analyses-protein-code-search-by-transporter-subclass-option", "9.B.87	The Selenoprotein P Receptor (SelP-receptor) Family
");
			INSERT INTO TEXTS(tag, value) VALUES ("search-database-analyses-protein-code-search-by-transporter-subclass-option", "9.B.88	The Selenoprotein P Hydrogen Selenide Uptake Protein (SelP) Family
");
			INSERT INTO TEXTS(tag, value) VALUES ("search-database-analyses-protein-code-search-by-transporter-subclass-option", "9.B.89	The Putative Channel-forming 3TMSs MamF (MamF) Family
");
			INSERT INTO TEXTS(tag, value) VALUES ("search-database-analyses-protein-code-search-by-transporter-subclass-option", "9.B.90	The Putative Channel Forming 2MTSs MamC (MamC) Family
");
			INSERT INTO TEXTS(tag, value) VALUES ("search-database-analyses-protein-code-search-by-transporter-subclass-option", "9.B.91	The Bacteriocin 41 Immunity Protein (Bac41IP) Family 
");
			INSERT INTO TEXTS(tag, value) VALUES ("search-database-analyses-protein-code-search-by-transporter-subclass-option", "9.B.92	The Folate Receptor (FR) Family
");
			INSERT INTO TEXTS(tag, value) VALUES ("search-database-analyses-protein-code-search-by-transporter-subclass-option", "9.B.93	The Spanin (Spanin) Family
");
			INSERT INTO TEXTS(tag, value) VALUES ("search-database-analyses-protein-code-search-by-transporter-subclass-option", "9.B.94	The Male Sterility-Associated Mitochondrial Protein (MSMP) Family
");
			INSERT INTO TEXTS(tag, value) VALUES ("search-database-analyses-protein-code-search-by-transporter-subclass-option", "9.B.95	The MamG (LG)4 repeat (MamG) Family
");
			INSERT INTO TEXTS(tag, value) VALUES ("search-database-analyses-protein-code-search-by-transporter-subclass-option", "9.B.96	The PE-PGRS Protein Family
");
			INSERT INTO TEXTS(tag, value) VALUES ("search-database-analyses-protein-code-search-by-transporter-subclass-option", "9.B.97	The Acyltransferase-3/Putative Acetyl-CoA Transporter (ATAT) Family
");
			INSERT INTO TEXTS(tag, value) VALUES ("search-database-analyses-protein-code-search-by-transporter-subclass-option", "9.B.98	The DUF95 (DUF95) Family
");
			INSERT INTO TEXTS(tag, value) VALUES ("search-database-analyses-protein-code-search-by-transporter-subclass-option", "9.B.99	The MltA-interacting Protein (MipA) Family
");
			INSERT INTO TEXTS(tag, value) VALUES ("search-database-analyses-protein-code-search-by-transporter-subclass-option", "9.B.100	The Phage Shock Protein (Psp) Family
");
			INSERT INTO TEXTS(tag, value) VALUES ("search-database-analyses-protein-code-search-by-transporter-subclass-option", "9.B.101	The Cytotoxin-associated Gene Product (CagA) Family
");
			INSERT INTO TEXTS(tag, value) VALUES ("search-database-analyses-protein-code-search-by-transporter-subclass-option", "9.B.102	The YedE/YeeE (YedE/YeeE) Family 
");
			INSERT INTO TEXTS(tag, value) VALUES ("search-database-analyses-protein-code-search-by-transporter-subclass-option", "9.B.103	The Putative Ca2+ Uniporter (GC1qR) Family
");
			INSERT INTO TEXTS(tag, value) VALUES ("search-database-analyses-protein-code-search-by-transporter-subclass-option", "9.B.104	The Rhomboid Protease Family
");
			INSERT INTO TEXTS(tag, value) VALUES ("search-database-analyses-protein-code-search-by-transporter-subclass-option", "9.B.105	The Lead Resistance Fusion Protein (PbrBC) Family
");
			INSERT INTO TEXTS(tag, value) VALUES ("search-database-analyses-protein-code-search-by-transporter-subclass-option", "9.B.106	The Pock Size-determining Protein (PSDP) Family
");
			INSERT INTO TEXTS(tag, value) VALUES ("search-database-analyses-protein-code-search-by-transporter-subclass-option", "9.B.107	The 8TMS Putative Permease (8-PP) Family
");
			INSERT INTO TEXTS(tag, value) VALUES ("search-database-analyses-protein-code-search-by-transporter-subclass-option", "9.B.108	The Tetraspanin (Tetraspanin) Family
");
			INSERT INTO TEXTS(tag, value) VALUES ("search-database-analyses-protein-code-search-by-transporter-subclass-option", "9.B.110	The Putative Polyketide Antibiotic Exporter (PPAE) Family
");
			INSERT INTO TEXTS(tag, value) VALUES ("search-database-analyses-protein-code-search-by-transporter-subclass-option", "9.B.111	The 6TMS Lysyl tRNA synthetase (LysS) Family
");
			INSERT INTO TEXTS(tag, value) VALUES ("search-database-analyses-protein-code-search-by-transporter-subclass-option", "9.B.112	The Stress-inducible Transmembrane Protein (TMPIT1) Family
");
			INSERT INTO TEXTS(tag, value) VALUES ("search-database-analyses-protein-code-search-by-transporter-subclass-option", "9.B.113	The Collagen Secretory Protein, Mia3 (Mia3) Family
");
			INSERT INTO TEXTS(tag, value) VALUES ("search-database-analyses-protein-code-search-by-transporter-subclass-option", "9.B.114	The Vanomycin-sensitivity protein (SanA) Family
");
			INSERT INTO TEXTS(tag, value) VALUES ("search-database-analyses-protein-code-search-by-transporter-subclass-option", "9.B.115	The DUF161 or YitT (YitT) Family
");
			INSERT INTO TEXTS(tag, value) VALUES ("search-database-analyses-protein-code-search-by-transporter-subclass-option", "9.B.116	The Transporter, YvqF (YvqF) Family
");
			INSERT INTO TEXTS(tag, value) VALUES ("search-database-analyses-protein-code-search-by-transporter-subclass-option", "9.B.117	The LrgB/CidB holin-auxilary protein (LrgB/CidB) Family
");
			INSERT INTO TEXTS(tag, value) VALUES ("search-database-analyses-protein-code-search-by-transporter-subclass-option", "9.B.118	The 11 or 12 TMS YhfT (YhfT) Family
");
			INSERT INTO TEXTS(tag, value) VALUES ("search-database-analyses-protein-code-search-by-transporter-subclass-option", "9.B.119	The Glycan Synthase, Fks1 (Fks1) Family
");
			INSERT INTO TEXTS(tag, value) VALUES ("search-database-analyses-protein-code-search-by-transporter-subclass-option", "9.B.120	The DUF554 (DUF554) Family
");
			INSERT INTO TEXTS(tag, value) VALUES ("search-database-analyses-protein-code-search-by-transporter-subclass-option", "9.B.121	The AsmA (AsmA) Family
");
			INSERT INTO TEXTS(tag, value) VALUES ("search-database-analyses-protein-code-search-by-transporter-subclass-option", "9.B.122	The DUF3592 or PF12158 (DUF3592) Family
");
			INSERT INTO TEXTS(tag, value) VALUES ("search-database-analyses-protein-code-search-by-transporter-subclass-option", "9.B.123	The Lysosomal 7-TMS (TM7SF1) Family 
");
			INSERT INTO TEXTS(tag, value) VALUES ("search-database-analyses-protein-code-search-by-transporter-subclass-option", "9.B.124	The DUF805 or PF05656 (DUF805) Family
");
			INSERT INTO TEXTS(tag, value) VALUES ("search-database-analyses-protein-code-search-by-transporter-subclass-option", "9.B.125	The AmpE/CobD (AmpE/CobD) Family
");
			INSERT INTO TEXTS(tag, value) VALUES ("search-database-analyses-protein-code-search-by-transporter-subclass-option", "9.B.126	The Putative Lipid Exporter (YhjD) Family
");
			INSERT INTO TEXTS(tag, value) VALUES ("search-database-analyses-protein-code-search-by-transporter-subclass-option", "9.B.127	The DUF2919 (PF11143) Family
");
			INSERT INTO TEXTS(tag, value) VALUES ("search-database-analyses-protein-code-search-by-transporter-subclass-option", "9.B.128	The O-antigen Polymerase, WzyE (WzyE) Family
");
			INSERT INTO TEXTS(tag, value) VALUES ("search-database-analyses-protein-code-search-by-transporter-subclass-option", "9.B.129	The Membrane Protein MLC1 Family
");
			INSERT INTO TEXTS(tag, value) VALUES ("search-database-analyses-protein-code-search-by-transporter-subclass-option", "9.B.130	The Synaptoporin Family
");
			INSERT INTO TEXTS(tag, value) VALUES ("search-database-analyses-protein-code-search-by-transporter-subclass-option", "9.B.131	The Post-GPI Attachment Protein (P-GAP2) Family
");
			INSERT INTO TEXTS(tag, value) VALUES ("search-database-analyses-protein-code-search-by-transporter-subclass-option", "9.B.132	 9.B.132.   The Post-GPI Attachment Protein-3 (P-GAP3) Family
");
			INSERT INTO TEXTS(tag, value) VALUES ("search-database-analyses-protein-code-search-by-transporter-subclass-option", "9.B.133	The Ice Nucleation Protein Secretion System (INP-SS) Family
");
			INSERT INTO TEXTS(tag, value) VALUES ("search-database-analyses-protein-code-search-by-transporter-subclass-option", "9.B.134	The Lysosomal Autophagy and Apoptosis-related Protein, TMEM192 (TMEM192) Family
");
			INSERT INTO TEXTS(tag, value) VALUES ("search-database-analyses-protein-code-search-by-transporter-subclass-option", "9.B.135	The Membrane Trafficking Yip (Yip) Family
");
			INSERT INTO TEXTS(tag, value) VALUES ("search-database-analyses-protein-code-search-by-transporter-subclass-option", "9.B.136	The 2TMS Membrane Protein, YjcH (YjcH) Family
");
			INSERT INTO TEXTS(tag, value) VALUES ("search-database-analyses-protein-code-search-by-transporter-subclass-option", "9.B.137	The Putative Cobalt Transporter (CbtC) Family 
");
			INSERT INTO TEXTS(tag, value) VALUES ("search-database-analyses-protein-code-search-by-transporter-subclass-option", "9.B.138	The Putative Mycobacterial Outer Membrane Porin, LprG (LprG; P27) Family
");
			INSERT INTO TEXTS(tag, value) VALUES ("search-database-analyses-protein-code-search-by-transporter-subclass-option", "9.B.139	The Cannabalism Toxin SdpC (SdpC) Family
");
			INSERT INTO TEXTS(tag, value) VALUES ("search-database-analyses-protein-code-search-by-transporter-subclass-option", "9.B.140	The 6 TMS (2 TMS x 3) DUF1206 (DUF1206) Family
");
			INSERT INTO TEXTS(tag, value) VALUES ("search-database-analyses-protein-code-search-by-transporter-subclass-option", "9.B.141	The YibE/F (YibE/F) Family
");
			INSERT INTO TEXTS(tag, value) VALUES ("search-database-analyses-protein-code-search-by-transporter-subclass-option", "9.B.142	The Integral membrane Glycosyltransferase family 39 (GT39) Family
");
			INSERT INTO TEXTS(tag, value) VALUES ("search-database-analyses-protein-code-search-by-transporter-subclass-option", "9.B.143	The 6 TMS DUF1275/Pf06912 (DUF1275) Family
");
			INSERT INTO TEXTS(tag, value) VALUES ("search-database-analyses-protein-code-search-by-transporter-subclass-option", "9.B.144	The DUF3367 (DUF3367) Family
");
			INSERT INTO TEXTS(tag, value) VALUES ("search-database-analyses-protein-code-search-by-transporter-subclass-option", "9.B.145	The DUF389/PF04087 (DUF389) Family
");
			INSERT INTO TEXTS(tag, value) VALUES ("search-database-analyses-protein-code-search-by-transporter-subclass-option", "9.B.146	The Putative Undecaprenyl-phosphate N-Acetylglucosaminyl Transferase (MurG) Family
");
			INSERT INTO TEXTS(tag, value) VALUES ("search-database-analyses-protein-code-search-by-transporter-subclass-option", "9.B.147	The 10 TMS Integral Membrane Protein (10-IMP) Family
");
			INSERT INTO TEXTS(tag, value) VALUES ("search-database-analyses-protein-code-search-by-transporter-subclass-option", "9.B.148	The 4 TMS Putative DMT (4-DMT) Family
");
			INSERT INTO TEXTS(tag, value) VALUES ("search-database-analyses-protein-code-search-by-transporter-subclass-option", "9.B.149	The M50 Peptidase (M50-P) Family
");
			INSERT INTO TEXTS(tag, value) VALUES ("search-database-analyses-protein-code-search-by-transporter-subclass-option", "9.C	Functionally characterized transporters lacking identified sequences
");
			INSERT INTO TEXTS(tag, value) VALUES ("search-database-analyses-protein-code-search-by-transporter-subclass-option", "9.C.1	The Endosomal Oligosaccharide Transporter (EOT)
");
			INSERT INTO TEXTS(tag, value) VALUES ("search-database-analyses-protein-code-search-by-transporter-subclass-option", "9.C.2	Volume-sensitive Anion Channels (VAC)
");
			INSERT INTO TEXTS(tag, value) VALUES ("search-database-analyses-protein-code-search-by-transporter-subclass-option", "9.C.3	The Rhodococcus erythropolis Porin (REP) Family
");
			INSERT INTO TEXTS(tag, value) VALUES ("search-database-analyses-protein-code-search-by-transporter-subclass-option", "9.C.4	 The Dolichol-linked Oligosaccharide (DO-ERF) Family
");
			INSERT INTO TEXTS(tag, value) VALUES ("search-database-analyses-protein-code-search-by-transporter-subclass-option", "9.C.5	The Endoplasmic Reticulum/Golgi ATP/ADP or AMP Antiport Transporters  (ATP-T)
");
			INSERT INTO TEXTS(tag, value) VALUES ("search-database-analyses-protein-code-search-by-transporter-subclass-option", "9.C.7	The Low-affinity, Calcium-blocked, Nonspecific Cation Channel (NSC1) of Saccharomyces cerevisiae
");
			INSERT INTO TEXTS(tag, value) VALUES ("search-database-analyses-protein-code-search-by-transporter-subclass-option", "9.C.8	The ABC Lignin Precursor Transporters (ALPT) Family
");
			INSERT INTO TEXTS(tag, value) VALUES ("search-database-analyses-protein-code-search-by-transporter-subclass-option", "9.C.9	The Acetobacter aceti Acetate Exporter (AAAE)
");
			INSERT INTO TEXTS(tag, value) VALUES ("search-database-analyses-protein-code-search-by-transporter-subclass-option", "9.C.10	The Liver Nicotinic/Nicotinamide Transporter
");
			INSERT INTO TEXTS(tag, value) VALUES ("search-database-analyses-protein-code-search-by-transporter-subclass-option", "9.C.11	The Tunneling Nanotube (TNT) Family
");
			INSERT INTO TEXTS(tag, value) VALUES ("search-database-analyses-protein-code-search-by-transporter-subclass-option", "9.C.12	The Water Permeable Channels in Frog Auditory Papillar Hair Cells (APHC-C) Family
");
			INSERT INTO TEXTS(tag, value) VALUES ("search-database-analyses-protein-code-search-by-transporter-subclass-option", "9.C.13	The Bacterial Endocytosis (BEC) Family
");
			INSERT INTO TEXTS(tag, value) VALUES ("search-database-analyses-protein-code-search-by-transporter-subclass-option", "9.C.14	The Intercellular Bacterial Nanotube (IBN) Family
");
			INSERT INTO TEXTS(tag, value) VALUES ("search-database-analyses-protein-code-search-by-transporter-subclass-option", "9.C.15	The Animal Calmodulin-dependent E.R. Secretion Pathway (CSP) Family
");
			INSERT INTO TEXTS(tag, value) VALUES ("search-database-analyses-protein-code-search-by-transporter-subclass-option", "9.C.16	The Proton-pumping H2:Sulfur Oxidoreductase (H+-HSO) Family
");
			INSERT INTO TEXTS(tag, value) VALUES ("search-database-analyses-protein-code-search-by-transporter-subclass-option", "9.C.99	
");
	INSERT INTO TEXTS(tag, value, details) VALUES
		("search-database-analyses-protein-code-tab", "Transporter classification", "#transporterClassification"),
        ("search-database-analyses-protein-code-not-containing-classification-tcdb", " not containing TCDB classification", ""),
        ("search-database-analyses-protein-code-search-by-transporter-identifier", "Search by transporter identifier(e.g. 1.A.3.1.1):", ""),
        ("search-database-analyses-protein-code-search-by-transporter-family", "Or by transporter family(e.g. 3.A.17):", ""),
        ("search-database-analyses-protein-code-search-by-transporter-subclass", "Or by transporter subclass:", ""),
        ("search-database-analyses-protein-code-search-by-transporter-class", "Or by transporter class:", ""),
        ("search-database-dna-based-analyses-search-ncrna-by-target-identifier", "Search ncRNA by target identifier: ", ""),
        ("search-database-dna-based-analyses-or-by-evalue-match", "Or by E-value of match: ", ""),
        ("search-database-dna-based-analyses-or-by-target-name", "Or by target name: ", ""),
        ("search-database-dna-based-analyses-or-by-target-class", "Or by target class: ", ""),
        ("search-database-dna-based-analyses-or-by-target-type", "Or by target type: ", ""),
        ("search-database-dna-based-analyses-or-by-target-description", "Or by target description: ", "");

INSERT INTO SEQUENCES(id, name, filepath) VALUES (6057173, 'Bacteria', 'seq/Bacteria.fasta');
	INSERT INTO TEXTS(tag, value, details) VALUES 
		("search-database-dna-based-analyses-predicted-alienhunter", "Get predicted AlienHunter regions of length: ", ""),
        ("search-database-dna-based-analyses-or-get-regions-score", "Or get regions of score: ", ""),
        ("search-database-dna-based-analyses-or-get-regions-threshold", "Or get regions of threshold: ", "");

INSERT INTO COMPONENTS(name, component, filepath) VALUES('alienhunter', 'annotation_alienhunter.pl', '/home/wendelhlc/git/report_html_db/report_html_db/alienhunter_dir/alienhunter.txt_Bacteria');

INSERT INTO COMPONENTS(name, component, filepath) VALUES('bigpi', 'annotation_bigpi.pl', '');
	INSERT INTO TEXTS(tag, value, details) VALUES 
		("search-database-analyses-protein-code-tab", "BLAST", "#blast"),
        ("search-database-analyses-protein-code-not-containing-classification-blast", " not containing BLAST matches", "");

INSERT INTO COMPONENTS(name, component, filepath) VALUES('blast', 'annotation_blast.pl', '');

INSERT INTO COMPONENTS(name, component, filepath) VALUES('dgpi', 'annotation_dgpi.pl', '');

INSERT INTO COMPONENTS(name, component, filepath) VALUES('glimmer3', 'annotation_glimmer3.pl', '');

INSERT INTO COMPONENTS(name, component, filepath) VALUES('infernal', 'annotation_infernal.pl', '/home/wendelhlc/git/report_html_db/report_html_db/infernal_dir/infernal.txt_Bacteria');
	INSERT INTO TEXTS(tag, value, details) VALUES 
		("search-database-analyses-protein-code-tab", "Gene ontology", "#geneOntology"),
        ("search-database-analyses-protein-code-not-containing-classification", " not containing Gene Ontology classification", ""),
        ("search-database-analyses-protein-code-not-containing-classification-interpro", " not containing InterProScan matches", ""),
        ("search-database-analyses-protein-code-interpro", "Search by InterPro identifier: ", "");

INSERT INTO COMPONENTS(name, component, filepath) VALUES('interpro', 'annotation_interpro.pl', '');

INSERT INTO COMPONENTS(name, component, filepath) VALUES('mreps', 'annotation_mreps.pl', '/Bacteria_mreps.txt');
	INSERT INTO TEXTS(tag, value, details) VALUES
		("search-database-analyses-protein-code-not-containing-classification-eggNOG", " not containing eggNOG matches", ""),
        ("search-database-analyses-protein-code-eggNOG", "Search by eggNOG identifier: ", "");

INSERT INTO COMPONENTS(name, component, filepath) VALUES('orthology', 'annotation_orthology.pl', '');
	INSERT INTO TEXTS(tag, value, details) VALUES
		("search-database-analyses-protein-code-not-containing-classification-kegg", " not containing KEGG pathway matches", ""),
        ("search-database-analyses-protein-code-by-orthology-identifier-kegg", "Search by KEGG orthology identifier:", ""),
        ("search-database-analyses-protein-code-by-kegg-pathway", "Or by KEGG pathway:", "");
						INSERT INTO TEXTS(tag, value, details) VALUES ("search-database-analyses-protein-code-by-kegg-pathway-options", "2-Oxocarboxylic acid metabolism", "01210");
						INSERT INTO TEXTS(tag, value, details) VALUES ("search-database-analyses-protein-code-by-kegg-pathway-options", "ABC transporters", "02010");
						INSERT INTO TEXTS(tag, value, details) VALUES ("search-database-analyses-protein-code-by-kegg-pathway-options", "AMPK signaling pathway", "04152");
						INSERT INTO TEXTS(tag, value, details) VALUES ("search-database-analyses-protein-code-by-kegg-pathway-options", "Acridone alkaloid biosynthesis", "01058");
						INSERT INTO TEXTS(tag, value, details) VALUES ("search-database-analyses-protein-code-by-kegg-pathway-options", "Acute myeloid leukemia", "05221");
						INSERT INTO TEXTS(tag, value, details) VALUES ("search-database-analyses-protein-code-by-kegg-pathway-options", "Adherens junction", "04520");
						INSERT INTO TEXTS(tag, value, details) VALUES ("search-database-analyses-protein-code-by-kegg-pathway-options", "Adipocytokine signaling pathway", "04920");
						INSERT INTO TEXTS(tag, value, details) VALUES ("search-database-analyses-protein-code-by-kegg-pathway-options", "Adrenergic signaling in cardiomyocytes", "04261");
						INSERT INTO TEXTS(tag, value, details) VALUES ("search-database-analyses-protein-code-by-kegg-pathway-options", "Aflatoxin biosynthesis", "00254");
						INSERT INTO TEXTS(tag, value, details) VALUES ("search-database-analyses-protein-code-by-kegg-pathway-options", "African trypanosomiasis", "05143");
						INSERT INTO TEXTS(tag, value, details) VALUES ("search-database-analyses-protein-code-by-kegg-pathway-options", "Alanine, aspartate and glutamate metabolism", "00250");
						INSERT INTO TEXTS(tag, value, details) VALUES ("search-database-analyses-protein-code-by-kegg-pathway-options", "Alcoholism", "05034");
						INSERT INTO TEXTS(tag, value, details) VALUES ("search-database-analyses-protein-code-by-kegg-pathway-options", "Aldosterone-regulated sodium reabsorption", "04960");
						INSERT INTO TEXTS(tag, value, details) VALUES ("search-database-analyses-protein-code-by-kegg-pathway-options", "Allograft rejection", "05330");
						INSERT INTO TEXTS(tag, value, details) VALUES ("search-database-analyses-protein-code-by-kegg-pathway-options", "Alzheimer's disease", "05010");
						INSERT INTO TEXTS(tag, value, details) VALUES ("search-database-analyses-protein-code-by-kegg-pathway-options", "Amino sugar and nucleotide sugar metabolism", "00520");
						INSERT INTO TEXTS(tag, value, details) VALUES ("search-database-analyses-protein-code-by-kegg-pathway-options", "Aminoacyl-tRNA biosynthesis", "00970");
						INSERT INTO TEXTS(tag, value, details) VALUES ("search-database-analyses-protein-code-by-kegg-pathway-options", "Aminobenzoate degradation", "00627");
						INSERT INTO TEXTS(tag, value, details) VALUES ("search-database-analyses-protein-code-by-kegg-pathway-options", "Amoebiasis", "05146");
						INSERT INTO TEXTS(tag, value, details) VALUES ("search-database-analyses-protein-code-by-kegg-pathway-options", "Amphetamine addiction", "05031");
						INSERT INTO TEXTS(tag, value, details) VALUES ("search-database-analyses-protein-code-by-kegg-pathway-options", "Amyotrophic lateral sclerosis (ALS)", "05014");
						INSERT INTO TEXTS(tag, value, details) VALUES ("search-database-analyses-protein-code-by-kegg-pathway-options", "Anthocyanin biosynthesis", "00942");
						INSERT INTO TEXTS(tag, value, details) VALUES ("search-database-analyses-protein-code-by-kegg-pathway-options", "Antigen processing and presentation", "04612");
						INSERT INTO TEXTS(tag, value, details) VALUES ("search-database-analyses-protein-code-by-kegg-pathway-options", "Apoptosis", "04210");
						INSERT INTO TEXTS(tag, value, details) VALUES ("search-database-analyses-protein-code-by-kegg-pathway-options", "Arachidonic acid metabolism", "00590");
						INSERT INTO TEXTS(tag, value, details) VALUES ("search-database-analyses-protein-code-by-kegg-pathway-options", "Arginine and proline metabolism", "00330");
						INSERT INTO TEXTS(tag, value, details) VALUES ("search-database-analyses-protein-code-by-kegg-pathway-options", "Arrhythmogenic right ventricular cardiomyopathy (ARVC)", "05412");
						INSERT INTO TEXTS(tag, value, details) VALUES ("search-database-analyses-protein-code-by-kegg-pathway-options", "Ascorbate and aldarate metabolism", "00053");
						INSERT INTO TEXTS(tag, value, details) VALUES ("search-database-analyses-protein-code-by-kegg-pathway-options", "Asthma", "05310");
						INSERT INTO TEXTS(tag, value, details) VALUES ("search-database-analyses-protein-code-by-kegg-pathway-options", "Atrazine degradation", "00791");
						INSERT INTO TEXTS(tag, value, details) VALUES ("search-database-analyses-protein-code-by-kegg-pathway-options", "Autoimmune thyroid disease", "05320");
						INSERT INTO TEXTS(tag, value, details) VALUES ("search-database-analyses-protein-code-by-kegg-pathway-options", "Axon guidance", "04360");
						INSERT INTO TEXTS(tag, value, details) VALUES ("search-database-analyses-protein-code-by-kegg-pathway-options", "B cell receptor signaling pathway", "04662");
						INSERT INTO TEXTS(tag, value, details) VALUES ("search-database-analyses-protein-code-by-kegg-pathway-options", "Bacterial chemotaxis", "02030");
						INSERT INTO TEXTS(tag, value, details) VALUES ("search-database-analyses-protein-code-by-kegg-pathway-options", "Bacterial invasion of epithelial cells", "05100");
						INSERT INTO TEXTS(tag, value, details) VALUES ("search-database-analyses-protein-code-by-kegg-pathway-options", "Bacterial secretion system", "03070");
						INSERT INTO TEXTS(tag, value, details) VALUES ("search-database-analyses-protein-code-by-kegg-pathway-options", "Basal cell carcinoma", "05217");
						INSERT INTO TEXTS(tag, value, details) VALUES ("search-database-analyses-protein-code-by-kegg-pathway-options", "Basal transcription factors", "03022");
						INSERT INTO TEXTS(tag, value, details) VALUES ("search-database-analyses-protein-code-by-kegg-pathway-options", "Base excision repair", "03410");
						INSERT INTO TEXTS(tag, value, details) VALUES ("search-database-analyses-protein-code-by-kegg-pathway-options", "Benzoate degradation", "00362");
						INSERT INTO TEXTS(tag, value, details) VALUES ("search-database-analyses-protein-code-by-kegg-pathway-options", "Benzoxazinoid biosynthesis", "00402");
						INSERT INTO TEXTS(tag, value, details) VALUES ("search-database-analyses-protein-code-by-kegg-pathway-options", "Betalain biosynthesis", "00965");
						INSERT INTO TEXTS(tag, value, details) VALUES ("search-database-analyses-protein-code-by-kegg-pathway-options", "Bile secretion", "04976");
						INSERT INTO TEXTS(tag, value, details) VALUES ("search-database-analyses-protein-code-by-kegg-pathway-options", "Biosynthesis of 12-, 14- and 16-membered macrolides", "00522");
						INSERT INTO TEXTS(tag, value, details) VALUES ("search-database-analyses-protein-code-by-kegg-pathway-options", "Biosynthesis of amino acids", "01230");
						INSERT INTO TEXTS(tag, value, details) VALUES ("search-database-analyses-protein-code-by-kegg-pathway-options", "Biosynthesis of ansamycins", "01051");
						INSERT INTO TEXTS(tag, value, details) VALUES ("search-database-analyses-protein-code-by-kegg-pathway-options", "Biosynthesis of siderophore group nonribosomal peptides", "01053");
						INSERT INTO TEXTS(tag, value, details) VALUES ("search-database-analyses-protein-code-by-kegg-pathway-options", "Biosynthesis of type II polyketide backbone", "01056");
						INSERT INTO TEXTS(tag, value, details) VALUES ("search-database-analyses-protein-code-by-kegg-pathway-options", "Biosynthesis of type II polyketide products", "01057");
						INSERT INTO TEXTS(tag, value, details) VALUES ("search-database-analyses-protein-code-by-kegg-pathway-options", "Biosynthesis of unsaturated fatty acids", "01040");
						INSERT INTO TEXTS(tag, value, details) VALUES ("search-database-analyses-protein-code-by-kegg-pathway-options", "Biosynthesis of vancomycin group antibiotics", "01055");
						INSERT INTO TEXTS(tag, value, details) VALUES ("search-database-analyses-protein-code-by-kegg-pathway-options", "Biotin metabolism", "00780");
						INSERT INTO TEXTS(tag, value, details) VALUES ("search-database-analyses-protein-code-by-kegg-pathway-options", "Bisphenol degradation", "00363");
						INSERT INTO TEXTS(tag, value, details) VALUES ("search-database-analyses-protein-code-by-kegg-pathway-options", "Bladder cancer", "05219");
						INSERT INTO TEXTS(tag, value, details) VALUES ("search-database-analyses-protein-code-by-kegg-pathway-options", "Brassinosteroid biosynthesis", "00905");
						INSERT INTO TEXTS(tag, value, details) VALUES ("search-database-analyses-protein-code-by-kegg-pathway-options", "Butanoate metabolism", "00650");
						INSERT INTO TEXTS(tag, value, details) VALUES ("search-database-analyses-protein-code-by-kegg-pathway-options", "Butirosin and neomycin biosynthesis", "00524");
						INSERT INTO TEXTS(tag, value, details) VALUES ("search-database-analyses-protein-code-by-kegg-pathway-options", "C5-Branched dibasic acid metabolism", "00660");
						INSERT INTO TEXTS(tag, value, details) VALUES ("search-database-analyses-protein-code-by-kegg-pathway-options", "Caffeine metabolism", "00232");
						INSERT INTO TEXTS(tag, value, details) VALUES ("search-database-analyses-protein-code-by-kegg-pathway-options", "Calcium signaling pathway", "04020");
						INSERT INTO TEXTS(tag, value, details) VALUES ("search-database-analyses-protein-code-by-kegg-pathway-options", "Caprolactam degradation", "00930");
						INSERT INTO TEXTS(tag, value, details) VALUES ("search-database-analyses-protein-code-by-kegg-pathway-options", "Carbapenem biosynthesis", "00332");
						INSERT INTO TEXTS(tag, value, details) VALUES ("search-database-analyses-protein-code-by-kegg-pathway-options", "Carbohydrate digestion and absorption", "04973");
						INSERT INTO TEXTS(tag, value, details) VALUES ("search-database-analyses-protein-code-by-kegg-pathway-options", "Carbon fixation in photosynthetic organisms", "00710");
						INSERT INTO TEXTS(tag, value, details) VALUES ("search-database-analyses-protein-code-by-kegg-pathway-options", "Carbon fixation pathways in prokaryotes", "00720");
						INSERT INTO TEXTS(tag, value, details) VALUES ("search-database-analyses-protein-code-by-kegg-pathway-options", "Carbon metabolism", "01200");
						INSERT INTO TEXTS(tag, value, details) VALUES ("search-database-analyses-protein-code-by-kegg-pathway-options", "Cardiac muscle contraction", "04260");
						INSERT INTO TEXTS(tag, value, details) VALUES ("search-database-analyses-protein-code-by-kegg-pathway-options", "Carotenoid biosynthesis", "00906");
						INSERT INTO TEXTS(tag, value, details) VALUES ("search-database-analyses-protein-code-by-kegg-pathway-options", "Cell adhesion molecules (CAMs)", "04514");
						INSERT INTO TEXTS(tag, value, details) VALUES ("search-database-analyses-protein-code-by-kegg-pathway-options", "Cell cycle", "04110");
						INSERT INTO TEXTS(tag, value, details) VALUES ("search-database-analyses-protein-code-by-kegg-pathway-options", "Cell cycle - Caulobacter", "04112");
						INSERT INTO TEXTS(tag, value, details) VALUES ("search-database-analyses-protein-code-by-kegg-pathway-options", "Cell cycle - yeast", "04111");
						INSERT INTO TEXTS(tag, value, details) VALUES ("search-database-analyses-protein-code-by-kegg-pathway-options", "Central carbon metabolism in cancer", "05230");
						INSERT INTO TEXTS(tag, value, details) VALUES ("search-database-analyses-protein-code-by-kegg-pathway-options", "Chagas disease (American trypanosomiasis)", "05142");
						INSERT INTO TEXTS(tag, value, details) VALUES ("search-database-analyses-protein-code-by-kegg-pathway-options", "Chemical carcinogenesis", "05204");
						INSERT INTO TEXTS(tag, value, details) VALUES ("search-database-analyses-protein-code-by-kegg-pathway-options", "Chemokine signaling pathway", "04062");
						INSERT INTO TEXTS(tag, value, details) VALUES ("search-database-analyses-protein-code-by-kegg-pathway-options", "Chloroalkane and chloroalkene degradation", "00625");
						INSERT INTO TEXTS(tag, value, details) VALUES ("search-database-analyses-protein-code-by-kegg-pathway-options", "Chlorocyclohexane and chlorobenzene degradation", "00361");
						INSERT INTO TEXTS(tag, value, details) VALUES ("search-database-analyses-protein-code-by-kegg-pathway-options", "Cholinergic synapse", "04725");
						INSERT INTO TEXTS(tag, value, details) VALUES ("search-database-analyses-protein-code-by-kegg-pathway-options", "Chronic myeloid leukemia", "05220");
						INSERT INTO TEXTS(tag, value, details) VALUES ("search-database-analyses-protein-code-by-kegg-pathway-options", "Circadian entrainment", "04713");
						INSERT INTO TEXTS(tag, value, details) VALUES ("search-database-analyses-protein-code-by-kegg-pathway-options", "Circadian rhythm", "04710");
						INSERT INTO TEXTS(tag, value, details) VALUES ("search-database-analyses-protein-code-by-kegg-pathway-options", "Circadian rhythm - fly", "04711");
						INSERT INTO TEXTS(tag, value, details) VALUES ("search-database-analyses-protein-code-by-kegg-pathway-options", "Circadian rhythm - plant", "04712");
						INSERT INTO TEXTS(tag, value, details) VALUES ("search-database-analyses-protein-code-by-kegg-pathway-options", "Citrate cycle (TCA cycle)", "00020");
						INSERT INTO TEXTS(tag, value, details) VALUES ("search-database-analyses-protein-code-by-kegg-pathway-options", "Clavulanic acid biosynthesis", "00331");
						INSERT INTO TEXTS(tag, value, details) VALUES ("search-database-analyses-protein-code-by-kegg-pathway-options", "Cocaine addiction", "05030");
						INSERT INTO TEXTS(tag, value, details) VALUES ("search-database-analyses-protein-code-by-kegg-pathway-options", "Collecting duct acid secretion", "04966");
						INSERT INTO TEXTS(tag, value, details) VALUES ("search-database-analyses-protein-code-by-kegg-pathway-options", "Colorectal cancer", "05210");
						INSERT INTO TEXTS(tag, value, details) VALUES ("search-database-analyses-protein-code-by-kegg-pathway-options", "Complement and coagulation cascades", "04610");
						INSERT INTO TEXTS(tag, value, details) VALUES ("search-database-analyses-protein-code-by-kegg-pathway-options", "Cutin, suberine and wax biosynthesis", "00073");
						INSERT INTO TEXTS(tag, value, details) VALUES ("search-database-analyses-protein-code-by-kegg-pathway-options", "Cyanoamino acid metabolism", "00460");
						INSERT INTO TEXTS(tag, value, details) VALUES ("search-database-analyses-protein-code-by-kegg-pathway-options", "Cysteine and methionine metabolism", "00270");
						INSERT INTO TEXTS(tag, value, details) VALUES ("search-database-analyses-protein-code-by-kegg-pathway-options", "Cytokine-cytokine receptor interaction", "04060");
						INSERT INTO TEXTS(tag, value, details) VALUES ("search-database-analyses-protein-code-by-kegg-pathway-options", "Cytosolic DNA-sensing pathway", "04623");
						INSERT INTO TEXTS(tag, value, details) VALUES ("search-database-analyses-protein-code-by-kegg-pathway-options", "D-Alanine metabolism", "00473");
						INSERT INTO TEXTS(tag, value, details) VALUES ("search-database-analyses-protein-code-by-kegg-pathway-options", "D-Arginine and D-ornithine metabolism", "00472");
						INSERT INTO TEXTS(tag, value, details) VALUES ("search-database-analyses-protein-code-by-kegg-pathway-options", "D-Glutamine and D-glutamate metabolism", "00471");
						INSERT INTO TEXTS(tag, value, details) VALUES ("search-database-analyses-protein-code-by-kegg-pathway-options", "DDT degradation", "00351");
						INSERT INTO TEXTS(tag, value, details) VALUES ("search-database-analyses-protein-code-by-kegg-pathway-options", "DNA replication", "03030");
						INSERT INTO TEXTS(tag, value, details) VALUES ("search-database-analyses-protein-code-by-kegg-pathway-options", "Degradation of aromatic compounds", "01220");
						INSERT INTO TEXTS(tag, value, details) VALUES ("search-database-analyses-protein-code-by-kegg-pathway-options", "Dilated cardiomyopathy", "05414");
						INSERT INTO TEXTS(tag, value, details) VALUES ("search-database-analyses-protein-code-by-kegg-pathway-options", "Dioxin degradation", "00621");
						INSERT INTO TEXTS(tag, value, details) VALUES ("search-database-analyses-protein-code-by-kegg-pathway-options", "Diterpenoid biosynthesis", "00904");
						INSERT INTO TEXTS(tag, value, details) VALUES ("search-database-analyses-protein-code-by-kegg-pathway-options", "Dopaminergic synapse", "04728");
						INSERT INTO TEXTS(tag, value, details) VALUES ("search-database-analyses-protein-code-by-kegg-pathway-options", "Dorso-ventral axis formation", "04320");
						INSERT INTO TEXTS(tag, value, details) VALUES ("search-database-analyses-protein-code-by-kegg-pathway-options", "Drug metabolism - cytochrome P450", "00982");
						INSERT INTO TEXTS(tag, value, details) VALUES ("search-database-analyses-protein-code-by-kegg-pathway-options", "Drug metabolism - other enzymes", "00983");
						INSERT INTO TEXTS(tag, value, details) VALUES ("search-database-analyses-protein-code-by-kegg-pathway-options", "ECM-receptor interaction", "04512");
						INSERT INTO TEXTS(tag, value, details) VALUES ("search-database-analyses-protein-code-by-kegg-pathway-options", "Endocrine and other factor-regulated calcium reabsorption", "04961");
						INSERT INTO TEXTS(tag, value, details) VALUES ("search-database-analyses-protein-code-by-kegg-pathway-options", "Endocytosis", "04144");
						INSERT INTO TEXTS(tag, value, details) VALUES ("search-database-analyses-protein-code-by-kegg-pathway-options", "Endometrial cancer", "05213");
						INSERT INTO TEXTS(tag, value, details) VALUES ("search-database-analyses-protein-code-by-kegg-pathway-options", "Epithelial cell signaling in Helicobacter pylori infection", "05120");
						INSERT INTO TEXTS(tag, value, details) VALUES ("search-database-analyses-protein-code-by-kegg-pathway-options", "Epstein-Barr virus infection", "05169");
						INSERT INTO TEXTS(tag, value, details) VALUES ("search-database-analyses-protein-code-by-kegg-pathway-options", "ErbB signaling pathway", "04012");
						INSERT INTO TEXTS(tag, value, details) VALUES ("search-database-analyses-protein-code-by-kegg-pathway-options", "Estrogen signaling pathway", "04915");
						INSERT INTO TEXTS(tag, value, details) VALUES ("search-database-analyses-protein-code-by-kegg-pathway-options", "Ether lipid metabolism", "00565");
						INSERT INTO TEXTS(tag, value, details) VALUES ("search-database-analyses-protein-code-by-kegg-pathway-options", "Ethylbenzene degradation", "00642");
						INSERT INTO TEXTS(tag, value, details) VALUES ("search-database-analyses-protein-code-by-kegg-pathway-options", "Fanconi anemia pathway", "03460");
						INSERT INTO TEXTS(tag, value, details) VALUES ("search-database-analyses-protein-code-by-kegg-pathway-options", "Fat digestion and absorption", "04975");
						INSERT INTO TEXTS(tag, value, details) VALUES ("search-database-analyses-protein-code-by-kegg-pathway-options", "Fatty acid biosynthesis", "00061");
						INSERT INTO TEXTS(tag, value, details) VALUES ("search-database-analyses-protein-code-by-kegg-pathway-options", "Fatty acid degradation", "00071");
						INSERT INTO TEXTS(tag, value, details) VALUES ("search-database-analyses-protein-code-by-kegg-pathway-options", "Fatty acid elongation", "00062");
						INSERT INTO TEXTS(tag, value, details) VALUES ("search-database-analyses-protein-code-by-kegg-pathway-options", "Fatty acid metabolism", "01212");
						INSERT INTO TEXTS(tag, value, details) VALUES ("search-database-analyses-protein-code-by-kegg-pathway-options", "Fc epsilon RI signaling pathway", "04664");
						INSERT INTO TEXTS(tag, value, details) VALUES ("search-database-analyses-protein-code-by-kegg-pathway-options", "Fc gamma R-mediated phagocytosis", "04666");
						INSERT INTO TEXTS(tag, value, details) VALUES ("search-database-analyses-protein-code-by-kegg-pathway-options", "Flagellar assembly", "02040");
						INSERT INTO TEXTS(tag, value, details) VALUES ("search-database-analyses-protein-code-by-kegg-pathway-options", "Flavone and flavonol biosynthesis", "00944");
						INSERT INTO TEXTS(tag, value, details) VALUES ("search-database-analyses-protein-code-by-kegg-pathway-options", "Flavonoid biosynthesis", "00941");
						INSERT INTO TEXTS(tag, value, details) VALUES ("search-database-analyses-protein-code-by-kegg-pathway-options", "Fluorobenzoate degradation", "00364");
						INSERT INTO TEXTS(tag, value, details) VALUES ("search-database-analyses-protein-code-by-kegg-pathway-options", "Focal adhesion", "04510");
						INSERT INTO TEXTS(tag, value, details) VALUES ("search-database-analyses-protein-code-by-kegg-pathway-options", "Folate biosynthesis", "00790");
						INSERT INTO TEXTS(tag, value, details) VALUES ("search-database-analyses-protein-code-by-kegg-pathway-options", "FoxO signaling pathway", "04068");
						INSERT INTO TEXTS(tag, value, details) VALUES ("search-database-analyses-protein-code-by-kegg-pathway-options", "Fructose and mannose metabolism", "00051");
						INSERT INTO TEXTS(tag, value, details) VALUES ("search-database-analyses-protein-code-by-kegg-pathway-options", "Furfural degradation", "00365");
						INSERT INTO TEXTS(tag, value, details) VALUES ("search-database-analyses-protein-code-by-kegg-pathway-options", "GABAergic synapse", "04727");
						INSERT INTO TEXTS(tag, value, details) VALUES ("search-database-analyses-protein-code-by-kegg-pathway-options", "Galactose metabolism", "00052");
						INSERT INTO TEXTS(tag, value, details) VALUES ("search-database-analyses-protein-code-by-kegg-pathway-options", "Gap junction", "04540");
						INSERT INTO TEXTS(tag, value, details) VALUES ("search-database-analyses-protein-code-by-kegg-pathway-options", "Gastric acid secretion", "04971");
						INSERT INTO TEXTS(tag, value, details) VALUES ("search-database-analyses-protein-code-by-kegg-pathway-options", "Geraniol degradation", "00281");
						INSERT INTO TEXTS(tag, value, details) VALUES ("search-database-analyses-protein-code-by-kegg-pathway-options", "Glioma", "05214");
						INSERT INTO TEXTS(tag, value, details) VALUES ("search-database-analyses-protein-code-by-kegg-pathway-options", "Glucosinolate biosynthesis", "00966");
						INSERT INTO TEXTS(tag, value, details) VALUES ("search-database-analyses-protein-code-by-kegg-pathway-options", "Glutamatergic synapse", "04724");
						INSERT INTO TEXTS(tag, value, details) VALUES ("search-database-analyses-protein-code-by-kegg-pathway-options", "Glutathione metabolism", "00480");
						INSERT INTO TEXTS(tag, value, details) VALUES ("search-database-analyses-protein-code-by-kegg-pathway-options", "Glycerolipid metabolism", "00561");
						INSERT INTO TEXTS(tag, value, details) VALUES ("search-database-analyses-protein-code-by-kegg-pathway-options", "Glycerophospholipid metabolism", "00564");
						INSERT INTO TEXTS(tag, value, details) VALUES ("search-database-analyses-protein-code-by-kegg-pathway-options", "Glycine, serine and threonine metabolism", "00260");
						INSERT INTO TEXTS(tag, value, details) VALUES ("search-database-analyses-protein-code-by-kegg-pathway-options", "Glycolysis / Gluconeogenesis", "00010");
						INSERT INTO TEXTS(tag, value, details) VALUES ("search-database-analyses-protein-code-by-kegg-pathway-options", "Glycosaminoglycan biosynthesis - chondroitin sulfate / dermatan sulfate", "00532");
						INSERT INTO TEXTS(tag, value, details) VALUES ("search-database-analyses-protein-code-by-kegg-pathway-options", "Glycosaminoglycan biosynthesis - heparan sulfate / heparin", "00534");
						INSERT INTO TEXTS(tag, value, details) VALUES ("search-database-analyses-protein-code-by-kegg-pathway-options", "Glycosaminoglycan biosynthesis - keratan sulfate", "00533");
						INSERT INTO TEXTS(tag, value, details) VALUES ("search-database-analyses-protein-code-by-kegg-pathway-options", "Glycosaminoglycan degradation", "00531");
						INSERT INTO TEXTS(tag, value, details) VALUES ("search-database-analyses-protein-code-by-kegg-pathway-options", "Glycosphingolipid biosynthesis - ganglio series", "00604");
						INSERT INTO TEXTS(tag, value, details) VALUES ("search-database-analyses-protein-code-by-kegg-pathway-options", "Glycosphingolipid biosynthesis - globo series", "00603");
						INSERT INTO TEXTS(tag, value, details) VALUES ("search-database-analyses-protein-code-by-kegg-pathway-options", "Glycosphingolipid biosynthesis - lacto and neolacto series", "00601");
						INSERT INTO TEXTS(tag, value, details) VALUES ("search-database-analyses-protein-code-by-kegg-pathway-options", "Glycosylphosphatidylinositol(GPI)-anchor biosynthesis", "00563");
						INSERT INTO TEXTS(tag, value, details) VALUES ("search-database-analyses-protein-code-by-kegg-pathway-options", "Glyoxylate and dicarboxylate metabolism", "00630");
						INSERT INTO TEXTS(tag, value, details) VALUES ("search-database-analyses-protein-code-by-kegg-pathway-options", "GnRH signaling pathway", "04912");
						INSERT INTO TEXTS(tag, value, details) VALUES ("search-database-analyses-protein-code-by-kegg-pathway-options", "Graft-versus-host disease", "05332");
						INSERT INTO TEXTS(tag, value, details) VALUES ("search-database-analyses-protein-code-by-kegg-pathway-options", "HIF-1 signaling pathway", "04066");
						INSERT INTO TEXTS(tag, value, details) VALUES ("search-database-analyses-protein-code-by-kegg-pathway-options", "HTLV-I infection", "05166");
						INSERT INTO TEXTS(tag, value, details) VALUES ("search-database-analyses-protein-code-by-kegg-pathway-options", "Hedgehog signaling pathway", "04340");
						INSERT INTO TEXTS(tag, value, details) VALUES ("search-database-analyses-protein-code-by-kegg-pathway-options", "Hematopoietic cell lineage", "04640");
						INSERT INTO TEXTS(tag, value, details) VALUES ("search-database-analyses-protein-code-by-kegg-pathway-options", "Hepatitis B", "05161");
						INSERT INTO TEXTS(tag, value, details) VALUES ("search-database-analyses-protein-code-by-kegg-pathway-options", "Hepatitis C", "05160");
						INSERT INTO TEXTS(tag, value, details) VALUES ("search-database-analyses-protein-code-by-kegg-pathway-options", "Herpes simplex infection", "05168");
						INSERT INTO TEXTS(tag, value, details) VALUES ("search-database-analyses-protein-code-by-kegg-pathway-options", "Hippo signaling pathway", "04390");
						INSERT INTO TEXTS(tag, value, details) VALUES ("search-database-analyses-protein-code-by-kegg-pathway-options", "Hippo signaling pathway - fly", "04391");
						INSERT INTO TEXTS(tag, value, details) VALUES ("search-database-analyses-protein-code-by-kegg-pathway-options", "Histidine metabolism", "00340");
						INSERT INTO TEXTS(tag, value, details) VALUES ("search-database-analyses-protein-code-by-kegg-pathway-options", "Homologous recombination", "03440");
						INSERT INTO TEXTS(tag, value, details) VALUES ("search-database-analyses-protein-code-by-kegg-pathway-options", "Huntington's disease", "05016");
						INSERT INTO TEXTS(tag, value, details) VALUES ("search-database-analyses-protein-code-by-kegg-pathway-options", "Hypertrophic cardiomyopathy (HCM)", "05410");
						INSERT INTO TEXTS(tag, value, details) VALUES ("search-database-analyses-protein-code-by-kegg-pathway-options", "Indole alkaloid biosynthesis", "00901");
						INSERT INTO TEXTS(tag, value, details) VALUES ("search-database-analyses-protein-code-by-kegg-pathway-options", "Indole diterpene alkaloid biosynthesis", "00403");
						INSERT INTO TEXTS(tag, value, details) VALUES ("search-database-analyses-protein-code-by-kegg-pathway-options", "Inflammatory bowel disease (IBD)", "05321");
						INSERT INTO TEXTS(tag, value, details) VALUES ("search-database-analyses-protein-code-by-kegg-pathway-options", "Inflammatory mediator regulation of TRP channels", "04750");
						INSERT INTO TEXTS(tag, value, details) VALUES ("search-database-analyses-protein-code-by-kegg-pathway-options", "Influenza A", "05164");
						INSERT INTO TEXTS(tag, value, details) VALUES ("search-database-analyses-protein-code-by-kegg-pathway-options", "Inositol phosphate metabolism", "00562");
						INSERT INTO TEXTS(tag, value, details) VALUES ("search-database-analyses-protein-code-by-kegg-pathway-options", "Insect hormone biosynthesis", "00981");
						INSERT INTO TEXTS(tag, value, details) VALUES ("search-database-analyses-protein-code-by-kegg-pathway-options", "Insulin secretion", "04911");
						INSERT INTO TEXTS(tag, value, details) VALUES ("search-database-analyses-protein-code-by-kegg-pathway-options", "Insulin signaling pathway", "04910");
						INSERT INTO TEXTS(tag, value, details) VALUES ("search-database-analyses-protein-code-by-kegg-pathway-options", "Intestinal immune network for IgA production", "04672");
						INSERT INTO TEXTS(tag, value, details) VALUES ("search-database-analyses-protein-code-by-kegg-pathway-options", "Isoflavonoid biosynthesis", "00943");
						INSERT INTO TEXTS(tag, value, details) VALUES ("search-database-analyses-protein-code-by-kegg-pathway-options", "Isoquinoline alkaloid biosynthesis", "00950");
						INSERT INTO TEXTS(tag, value, details) VALUES ("search-database-analyses-protein-code-by-kegg-pathway-options", "Jak-STAT signaling pathway", "04630");
						INSERT INTO TEXTS(tag, value, details) VALUES ("search-database-analyses-protein-code-by-kegg-pathway-options", "Legionellosis", "05134");
						INSERT INTO TEXTS(tag, value, details) VALUES ("search-database-analyses-protein-code-by-kegg-pathway-options", "Leishmaniasis", "05140");
						INSERT INTO TEXTS(tag, value, details) VALUES ("search-database-analyses-protein-code-by-kegg-pathway-options", "Leukocyte transendothelial migration", "04670");
						INSERT INTO TEXTS(tag, value, details) VALUES ("search-database-analyses-protein-code-by-kegg-pathway-options", "Limonene and pinene degradation", "00903");
						INSERT INTO TEXTS(tag, value, details) VALUES ("search-database-analyses-protein-code-by-kegg-pathway-options", "Linoleic acid metabolism", "00591");
						INSERT INTO TEXTS(tag, value, details) VALUES ("search-database-analyses-protein-code-by-kegg-pathway-options", "Lipoic acid metabolism", "00785");
						INSERT INTO TEXTS(tag, value, details) VALUES ("search-database-analyses-protein-code-by-kegg-pathway-options", "Lipopolysaccharide biosynthesis", "00540");
						INSERT INTO TEXTS(tag, value, details) VALUES ("search-database-analyses-protein-code-by-kegg-pathway-options", "Long-term depression", "04730");
						INSERT INTO TEXTS(tag, value, details) VALUES ("search-database-analyses-protein-code-by-kegg-pathway-options", "Long-term potentiation", "04720");
						INSERT INTO TEXTS(tag, value, details) VALUES ("search-database-analyses-protein-code-by-kegg-pathway-options", "Lysine biosynthesis", "00300");
						INSERT INTO TEXTS(tag, value, details) VALUES ("search-database-analyses-protein-code-by-kegg-pathway-options", "Lysine degradation", "00310");
						INSERT INTO TEXTS(tag, value, details) VALUES ("search-database-analyses-protein-code-by-kegg-pathway-options", "Lysosome", "04142");
						INSERT INTO TEXTS(tag, value, details) VALUES ("search-database-analyses-protein-code-by-kegg-pathway-options", "MAPK signaling pathway", "04010");
						INSERT INTO TEXTS(tag, value, details) VALUES ("search-database-analyses-protein-code-by-kegg-pathway-options", "MAPK signaling pathway - fly", "04013");
						INSERT INTO TEXTS(tag, value, details) VALUES ("search-database-analyses-protein-code-by-kegg-pathway-options", "MAPK signaling pathway - yeast", "04011");
						INSERT INTO TEXTS(tag, value, details) VALUES ("search-database-analyses-protein-code-by-kegg-pathway-options", "Malaria", "05144");
						INSERT INTO TEXTS(tag, value, details) VALUES ("search-database-analyses-protein-code-by-kegg-pathway-options", "Maturity onset diabetes of the young", "04950");
						INSERT INTO TEXTS(tag, value, details) VALUES ("search-database-analyses-protein-code-by-kegg-pathway-options", "Measles", "05162");
						INSERT INTO TEXTS(tag, value, details) VALUES ("search-database-analyses-protein-code-by-kegg-pathway-options", "Meiosis - yeast", "04113");
						INSERT INTO TEXTS(tag, value, details) VALUES ("search-database-analyses-protein-code-by-kegg-pathway-options", "Melanogenesis", "04916");
						INSERT INTO TEXTS(tag, value, details) VALUES ("search-database-analyses-protein-code-by-kegg-pathway-options", "Melanoma", "05218");
						INSERT INTO TEXTS(tag, value, details) VALUES ("search-database-analyses-protein-code-by-kegg-pathway-options", "Metabolism of xenobiotics by cytochrome P450", "00980");
						INSERT INTO TEXTS(tag, value, details) VALUES ("search-database-analyses-protein-code-by-kegg-pathway-options", "Methane metabolism", "00680");
						INSERT INTO TEXTS(tag, value, details) VALUES ("search-database-analyses-protein-code-by-kegg-pathway-options", "MicroRNAs in cancer", "05206");
						INSERT INTO TEXTS(tag, value, details) VALUES ("search-database-analyses-protein-code-by-kegg-pathway-options", "Mineral absorption", "04978");
						INSERT INTO TEXTS(tag, value, details) VALUES ("search-database-analyses-protein-code-by-kegg-pathway-options", "Mismatch repair", "03430");
						INSERT INTO TEXTS(tag, value, details) VALUES ("search-database-analyses-protein-code-by-kegg-pathway-options", "Monoterpenoid biosynthesis", "00902");
						INSERT INTO TEXTS(tag, value, details) VALUES ("search-database-analyses-protein-code-by-kegg-pathway-options", "Morphine addiction", "05032");
						INSERT INTO TEXTS(tag, value, details) VALUES ("search-database-analyses-protein-code-by-kegg-pathway-options", "Mucin type O-Glycan biosynthesis", "00512");
						INSERT INTO TEXTS(tag, value, details) VALUES ("search-database-analyses-protein-code-by-kegg-pathway-options", "N-Glycan biosynthesis", "00510");
						INSERT INTO TEXTS(tag, value, details) VALUES ("search-database-analyses-protein-code-by-kegg-pathway-options", "NF-kappa B signaling pathway", "04064");
						INSERT INTO TEXTS(tag, value, details) VALUES ("search-database-analyses-protein-code-by-kegg-pathway-options", "NOD-like receptor signaling pathway", "04621");
						INSERT INTO TEXTS(tag, value, details) VALUES ("search-database-analyses-protein-code-by-kegg-pathway-options", "Naphthalene degradation", "00626");
						INSERT INTO TEXTS(tag, value, details) VALUES ("search-database-analyses-protein-code-by-kegg-pathway-options", "Natural killer cell mediated cytotoxicity", "04650");
						INSERT INTO TEXTS(tag, value, details) VALUES ("search-database-analyses-protein-code-by-kegg-pathway-options", "Neuroactive ligand-receptor interaction", "04080");
						INSERT INTO TEXTS(tag, value, details) VALUES ("search-database-analyses-protein-code-by-kegg-pathway-options", "Neurotrophin signaling pathway", "04722");
						INSERT INTO TEXTS(tag, value, details) VALUES ("search-database-analyses-protein-code-by-kegg-pathway-options", "Nicotinate and nicotinamide metabolism", "00760");
						INSERT INTO TEXTS(tag, value, details) VALUES ("search-database-analyses-protein-code-by-kegg-pathway-options", "Nicotine addiction", "05033");
						INSERT INTO TEXTS(tag, value, details) VALUES ("search-database-analyses-protein-code-by-kegg-pathway-options", "Nitrogen metabolism", "00910");
						INSERT INTO TEXTS(tag, value, details) VALUES ("search-database-analyses-protein-code-by-kegg-pathway-options", "Nitrotoluene degradation", "00633");
						INSERT INTO TEXTS(tag, value, details) VALUES ("search-database-analyses-protein-code-by-kegg-pathway-options", "Non-alcoholic fatty liver disease (NAFLD)", "04932");
						INSERT INTO TEXTS(tag, value, details) VALUES ("search-database-analyses-protein-code-by-kegg-pathway-options", "Non-homologous end-joining", "03450");
						INSERT INTO TEXTS(tag, value, details) VALUES ("search-database-analyses-protein-code-by-kegg-pathway-options", "Non-small cell lung cancer", "05223");
						INSERT INTO TEXTS(tag, value, details) VALUES ("search-database-analyses-protein-code-by-kegg-pathway-options", "Nonribosomal peptide structures", "01054");
						INSERT INTO TEXTS(tag, value, details) VALUES ("search-database-analyses-protein-code-by-kegg-pathway-options", "Notch signaling pathway", "04330");
						INSERT INTO TEXTS(tag, value, details) VALUES ("search-database-analyses-protein-code-by-kegg-pathway-options", "Novobiocin biosynthesis", "00401");
						INSERT INTO TEXTS(tag, value, details) VALUES ("search-database-analyses-protein-code-by-kegg-pathway-options", "Nucleotide excision repair", "03420");
						INSERT INTO TEXTS(tag, value, details) VALUES ("search-database-analyses-protein-code-by-kegg-pathway-options", "Olfactory transduction", "04740");
						INSERT INTO TEXTS(tag, value, details) VALUES ("search-database-analyses-protein-code-by-kegg-pathway-options", "One carbon pool by folate", "00670");
						INSERT INTO TEXTS(tag, value, details) VALUES ("search-database-analyses-protein-code-by-kegg-pathway-options", "Oocyte meiosis", "04114");
						INSERT INTO TEXTS(tag, value, details) VALUES ("search-database-analyses-protein-code-by-kegg-pathway-options", "Osteoclast differentiation", "04380");
						INSERT INTO TEXTS(tag, value, details) VALUES ("search-database-analyses-protein-code-by-kegg-pathway-options", "Other glycan degradation", "00511");
						INSERT INTO TEXTS(tag, value, details) VALUES ("search-database-analyses-protein-code-by-kegg-pathway-options", "Other types of O-glycan biosynthesis", "00514");
						INSERT INTO TEXTS(tag, value, details) VALUES ("search-database-analyses-protein-code-by-kegg-pathway-options", "Ovarian steroidogenesis", "04913");
						INSERT INTO TEXTS(tag, value, details) VALUES ("search-database-analyses-protein-code-by-kegg-pathway-options", "Oxidative phosphorylation", "00190");
						INSERT INTO TEXTS(tag, value, details) VALUES ("search-database-analyses-protein-code-by-kegg-pathway-options", "Oxytocin signaling pathway", "04921");
						INSERT INTO TEXTS(tag, value, details) VALUES ("search-database-analyses-protein-code-by-kegg-pathway-options", "PI3K-Akt signaling pathway", "04151");
						INSERT INTO TEXTS(tag, value, details) VALUES ("search-database-analyses-protein-code-by-kegg-pathway-options", "PPAR signaling pathway", "03320");
						INSERT INTO TEXTS(tag, value, details) VALUES ("search-database-analyses-protein-code-by-kegg-pathway-options", "Pancreatic cancer", "05212");
						INSERT INTO TEXTS(tag, value, details) VALUES ("search-database-analyses-protein-code-by-kegg-pathway-options", "Pancreatic secretion", "04972");
						INSERT INTO TEXTS(tag, value, details) VALUES ("search-database-analyses-protein-code-by-kegg-pathway-options", "Pantothenate and CoA biosynthesis", "00770");
						INSERT INTO TEXTS(tag, value, details) VALUES ("search-database-analyses-protein-code-by-kegg-pathway-options", "Parkinson's disease", "05012");
						INSERT INTO TEXTS(tag, value, details) VALUES ("search-database-analyses-protein-code-by-kegg-pathway-options", "Pathogenic Escherichia coli infection", "05130");
						INSERT INTO TEXTS(tag, value, details) VALUES ("search-database-analyses-protein-code-by-kegg-pathway-options", "Pathways in cancer", "05200");
						INSERT INTO TEXTS(tag, value, details) VALUES ("search-database-analyses-protein-code-by-kegg-pathway-options", "Penicillin and cephalosporin biosynthesis", "00311");
						INSERT INTO TEXTS(tag, value, details) VALUES ("search-database-analyses-protein-code-by-kegg-pathway-options", "Pentose and glucuronate interconversions", "00040");
						INSERT INTO TEXTS(tag, value, details) VALUES ("search-database-analyses-protein-code-by-kegg-pathway-options", "Pentose phosphate pathway", "00030");
						INSERT INTO TEXTS(tag, value, details) VALUES ("search-database-analyses-protein-code-by-kegg-pathway-options", "Peptidoglycan biosynthesis", "00550");
						INSERT INTO TEXTS(tag, value, details) VALUES ("search-database-analyses-protein-code-by-kegg-pathway-options", "Peroxisome", "04146");
						INSERT INTO TEXTS(tag, value, details) VALUES ("search-database-analyses-protein-code-by-kegg-pathway-options", "Pertussis", "05133");
						INSERT INTO TEXTS(tag, value, details) VALUES ("search-database-analyses-protein-code-by-kegg-pathway-options", "Phagosome", "04145");
						INSERT INTO TEXTS(tag, value, details) VALUES ("search-database-analyses-protein-code-by-kegg-pathway-options", "Phenylalanine metabolism", "00360");
						INSERT INTO TEXTS(tag, value, details) VALUES ("search-database-analyses-protein-code-by-kegg-pathway-options", "Phenylalanine, tyrosine and tryptophan biosynthesis", "00400");
						INSERT INTO TEXTS(tag, value, details) VALUES ("search-database-analyses-protein-code-by-kegg-pathway-options", "Phenylpropanoid biosynthesis", "00940");
						INSERT INTO TEXTS(tag, value, details) VALUES ("search-database-analyses-protein-code-by-kegg-pathway-options", "Phosphatidylinositol signaling system", "04070");
						INSERT INTO TEXTS(tag, value, details) VALUES ("search-database-analyses-protein-code-by-kegg-pathway-options", "Phosphonate and phosphinate metabolism", "00440");
						INSERT INTO TEXTS(tag, value, details) VALUES ("search-database-analyses-protein-code-by-kegg-pathway-options", "Phosphotransferase system (PTS)", "02060");
						INSERT INTO TEXTS(tag, value, details) VALUES ("search-database-analyses-protein-code-by-kegg-pathway-options", "Photosynthesis", "00195");
						INSERT INTO TEXTS(tag, value, details) VALUES ("search-database-analyses-protein-code-by-kegg-pathway-options", "Photosynthesis - antenna proteins", "00196");
						INSERT INTO TEXTS(tag, value, details) VALUES ("search-database-analyses-protein-code-by-kegg-pathway-options", "Phototransduction", "04744");
						INSERT INTO TEXTS(tag, value, details) VALUES ("search-database-analyses-protein-code-by-kegg-pathway-options", "Phototransduction - fly", "04745");
						INSERT INTO TEXTS(tag, value, details) VALUES ("search-database-analyses-protein-code-by-kegg-pathway-options", "Plant hormone signal transduction", "04075");
						INSERT INTO TEXTS(tag, value, details) VALUES ("search-database-analyses-protein-code-by-kegg-pathway-options", "Plant-pathogen interaction", "04626");
						INSERT INTO TEXTS(tag, value, details) VALUES ("search-database-analyses-protein-code-by-kegg-pathway-options", "Platelet activation", "04611");
						INSERT INTO TEXTS(tag, value, details) VALUES ("search-database-analyses-protein-code-by-kegg-pathway-options", "Polycyclic aromatic hydrocarbon degradation", "00624");
						INSERT INTO TEXTS(tag, value, details) VALUES ("search-database-analyses-protein-code-by-kegg-pathway-options", "Polyketide sugar unit biosynthesis", "00523");
						INSERT INTO TEXTS(tag, value, details) VALUES ("search-database-analyses-protein-code-by-kegg-pathway-options", "Porphyrin and chlorophyll metabolism", "00860");
						INSERT INTO TEXTS(tag, value, details) VALUES ("search-database-analyses-protein-code-by-kegg-pathway-options", "Primary bile acid biosynthesis", "00120");
						INSERT INTO TEXTS(tag, value, details) VALUES ("search-database-analyses-protein-code-by-kegg-pathway-options", "Primary immunodeficiency", "05340");
						INSERT INTO TEXTS(tag, value, details) VALUES ("search-database-analyses-protein-code-by-kegg-pathway-options", "Prion diseases", "05020");
						INSERT INTO TEXTS(tag, value, details) VALUES ("search-database-analyses-protein-code-by-kegg-pathway-options", "Progesterone-mediated oocyte maturation", "04914");
						INSERT INTO TEXTS(tag, value, details) VALUES ("search-database-analyses-protein-code-by-kegg-pathway-options", "Prolactin signaling pathway", "04917");
						INSERT INTO TEXTS(tag, value, details) VALUES ("search-database-analyses-protein-code-by-kegg-pathway-options", "Propanoate metabolism", "00640");
						INSERT INTO TEXTS(tag, value, details) VALUES ("search-database-analyses-protein-code-by-kegg-pathway-options", "Prostate cancer", "05215");
						INSERT INTO TEXTS(tag, value, details) VALUES ("search-database-analyses-protein-code-by-kegg-pathway-options", "Proteasome", "03050");
						INSERT INTO TEXTS(tag, value, details) VALUES ("search-database-analyses-protein-code-by-kegg-pathway-options", "Protein digestion and absorption", "04974");
						INSERT INTO TEXTS(tag, value, details) VALUES ("search-database-analyses-protein-code-by-kegg-pathway-options", "Protein export", "03060");
						INSERT INTO TEXTS(tag, value, details) VALUES ("search-database-analyses-protein-code-by-kegg-pathway-options", "Protein processing in endoplasmic reticulum", "04141");
						INSERT INTO TEXTS(tag, value, details) VALUES ("search-database-analyses-protein-code-by-kegg-pathway-options", "Proteoglycans in cancer", "05205");
						INSERT INTO TEXTS(tag, value, details) VALUES ("search-database-analyses-protein-code-by-kegg-pathway-options", "Proximal tubule bicarbonate reclamation", "04964");
						INSERT INTO TEXTS(tag, value, details) VALUES ("search-database-analyses-protein-code-by-kegg-pathway-options", "Purine metabolism", "00230");
						INSERT INTO TEXTS(tag, value, details) VALUES ("search-database-analyses-protein-code-by-kegg-pathway-options", "Puromycin biosynthesis", "00231");
						INSERT INTO TEXTS(tag, value, details) VALUES ("search-database-analyses-protein-code-by-kegg-pathway-options", "Pyrimidine metabolism", "00240");
						INSERT INTO TEXTS(tag, value, details) VALUES ("search-database-analyses-protein-code-by-kegg-pathway-options", "Pyruvate metabolism", "00620");
						INSERT INTO TEXTS(tag, value, details) VALUES ("search-database-analyses-protein-code-by-kegg-pathway-options", "RIG-I-like receptor signaling pathway", "04622");
						INSERT INTO TEXTS(tag, value, details) VALUES ("search-database-analyses-protein-code-by-kegg-pathway-options", "RNA degradation", "03018");
						INSERT INTO TEXTS(tag, value, details) VALUES ("search-database-analyses-protein-code-by-kegg-pathway-options", "RNA polymerase", "03020");
						INSERT INTO TEXTS(tag, value, details) VALUES ("search-database-analyses-protein-code-by-kegg-pathway-options", "RNA transport", "03013");
						INSERT INTO TEXTS(tag, value, details) VALUES ("search-database-analyses-protein-code-by-kegg-pathway-options", "Rap1 signaling pathway", "04015");
						INSERT INTO TEXTS(tag, value, details) VALUES ("search-database-analyses-protein-code-by-kegg-pathway-options", "Ras signaling pathway", "04014");
						INSERT INTO TEXTS(tag, value, details) VALUES ("search-database-analyses-protein-code-by-kegg-pathway-options", "Regulation of actin cytoskeleton", "04810");
						INSERT INTO TEXTS(tag, value, details) VALUES ("search-database-analyses-protein-code-by-kegg-pathway-options", "Regulation of autophagy", "04140");
						INSERT INTO TEXTS(tag, value, details) VALUES ("search-database-analyses-protein-code-by-kegg-pathway-options", "Renal cell carcinoma", "05211");
						INSERT INTO TEXTS(tag, value, details) VALUES ("search-database-analyses-protein-code-by-kegg-pathway-options", "Renin-angiotensin system", "04614");
						INSERT INTO TEXTS(tag, value, details) VALUES ("search-database-analyses-protein-code-by-kegg-pathway-options", "Retinol metabolism", "00830");
						INSERT INTO TEXTS(tag, value, details) VALUES ("search-database-analyses-protein-code-by-kegg-pathway-options", "Retrograde endocannabinoid signaling", "04723");
						INSERT INTO TEXTS(tag, value, details) VALUES ("search-database-analyses-protein-code-by-kegg-pathway-options", "Rheumatoid arthritis", "05323");
						INSERT INTO TEXTS(tag, value, details) VALUES ("search-database-analyses-protein-code-by-kegg-pathway-options", "Riboflavin metabolism", "00740");
						INSERT INTO TEXTS(tag, value, details) VALUES ("search-database-analyses-protein-code-by-kegg-pathway-options", "Ribosome", "03010");
						INSERT INTO TEXTS(tag, value, details) VALUES ("search-database-analyses-protein-code-by-kegg-pathway-options", "Ribosome biogenesis in eukaryotes", "03008");
						INSERT INTO TEXTS(tag, value, details) VALUES ("search-database-analyses-protein-code-by-kegg-pathway-options", "SNARE interactions in vesicular transport", "04130");
						INSERT INTO TEXTS(tag, value, details) VALUES ("search-database-analyses-protein-code-by-kegg-pathway-options", "Salivary secretion", "04970");
						INSERT INTO TEXTS(tag, value, details) VALUES ("search-database-analyses-protein-code-by-kegg-pathway-options", "Salmonella infection", "05132");
						INSERT INTO TEXTS(tag, value, details) VALUES ("search-database-analyses-protein-code-by-kegg-pathway-options", "Secondary bile acid biosynthesis", "00121");
						INSERT INTO TEXTS(tag, value, details) VALUES ("search-database-analyses-protein-code-by-kegg-pathway-options", "Selenocompound metabolism", "00450");
						INSERT INTO TEXTS(tag, value, details) VALUES ("search-database-analyses-protein-code-by-kegg-pathway-options", "Serotonergic synapse", "04726");
						INSERT INTO TEXTS(tag, value, details) VALUES ("search-database-analyses-protein-code-by-kegg-pathway-options", "Sesquiterpenoid and triterpenoid biosynthesis", "00909");
						INSERT INTO TEXTS(tag, value, details) VALUES ("search-database-analyses-protein-code-by-kegg-pathway-options", "Shigellosis", "05131");
						INSERT INTO TEXTS(tag, value, details) VALUES ("search-database-analyses-protein-code-by-kegg-pathway-options", "Signaling pathways regulating pluripotency of stem cells", "04550");
						INSERT INTO TEXTS(tag, value, details) VALUES ("search-database-analyses-protein-code-by-kegg-pathway-options", "Small cell lung cancer", "05222");
						INSERT INTO TEXTS(tag, value, details) VALUES ("search-database-analyses-protein-code-by-kegg-pathway-options", "Sphingolipid metabolism", "00600");
						INSERT INTO TEXTS(tag, value, details) VALUES ("search-database-analyses-protein-code-by-kegg-pathway-options", "Spliceosome", "03040");
						INSERT INTO TEXTS(tag, value, details) VALUES ("search-database-analyses-protein-code-by-kegg-pathway-options", "Staphylococcus aureus infection", "05150");
						INSERT INTO TEXTS(tag, value, details) VALUES ("search-database-analyses-protein-code-by-kegg-pathway-options", "Starch and sucrose metabolism", "00500");
						INSERT INTO TEXTS(tag, value, details) VALUES ("search-database-analyses-protein-code-by-kegg-pathway-options", "Steroid biosynthesis", "00100");
						INSERT INTO TEXTS(tag, value, details) VALUES ("search-database-analyses-protein-code-by-kegg-pathway-options", "Steroid degradation", "00984");
						INSERT INTO TEXTS(tag, value, details) VALUES ("search-database-analyses-protein-code-by-kegg-pathway-options", "Steroid hormone biosynthesis", "00140");
						INSERT INTO TEXTS(tag, value, details) VALUES ("search-database-analyses-protein-code-by-kegg-pathway-options", "Stilbenoid, diarylheptanoid and gingerol biosynthesis", "00945");
						INSERT INTO TEXTS(tag, value, details) VALUES ("search-database-analyses-protein-code-by-kegg-pathway-options", "Streptomycin biosynthesis", "00521");
						INSERT INTO TEXTS(tag, value, details) VALUES ("search-database-analyses-protein-code-by-kegg-pathway-options", "Styrene degradation", "00643");
						INSERT INTO TEXTS(tag, value, details) VALUES ("search-database-analyses-protein-code-by-kegg-pathway-options", "Sulfur metabolism", "00920");
						INSERT INTO TEXTS(tag, value, details) VALUES ("search-database-analyses-protein-code-by-kegg-pathway-options", "Sulfur relay system", "04122");
						INSERT INTO TEXTS(tag, value, details) VALUES ("search-database-analyses-protein-code-by-kegg-pathway-options", "Synaptic vesicle cycle", "04721");
						INSERT INTO TEXTS(tag, value, details) VALUES ("search-database-analyses-protein-code-by-kegg-pathway-options", "Synthesis and degradation of ketone bodies", "00072");
						INSERT INTO TEXTS(tag, value, details) VALUES ("search-database-analyses-protein-code-by-kegg-pathway-options", "Systemic lupus erythematosus", "05322");
						INSERT INTO TEXTS(tag, value, details) VALUES ("search-database-analyses-protein-code-by-kegg-pathway-options", "T cell receptor signaling pathway", "04660");
						INSERT INTO TEXTS(tag, value, details) VALUES ("search-database-analyses-protein-code-by-kegg-pathway-options", "TGF-beta signaling pathway", "04350");
						INSERT INTO TEXTS(tag, value, details) VALUES ("search-database-analyses-protein-code-by-kegg-pathway-options", "TNF signaling pathway", "04668");
						INSERT INTO TEXTS(tag, value, details) VALUES ("search-database-analyses-protein-code-by-kegg-pathway-options", "Taste transduction", "04742");
						INSERT INTO TEXTS(tag, value, details) VALUES ("search-database-analyses-protein-code-by-kegg-pathway-options", "Taurine and hypotaurine metabolism", "00430");
						INSERT INTO TEXTS(tag, value, details) VALUES ("search-database-analyses-protein-code-by-kegg-pathway-options", "Terpenoid backbone biosynthesis", "00900");
						INSERT INTO TEXTS(tag, value, details) VALUES ("search-database-analyses-protein-code-by-kegg-pathway-options", "Tetracycline biosynthesis", "00253");
						INSERT INTO TEXTS(tag, value, details) VALUES ("search-database-analyses-protein-code-by-kegg-pathway-options", "Thiamine metabolism", "00730");
						INSERT INTO TEXTS(tag, value, details) VALUES ("search-database-analyses-protein-code-by-kegg-pathway-options", "Thyroid cancer", "05216");
						INSERT INTO TEXTS(tag, value, details) VALUES ("search-database-analyses-protein-code-by-kegg-pathway-options", "Thyroid hormone signaling pathway", "04919");
						INSERT INTO TEXTS(tag, value, details) VALUES ("search-database-analyses-protein-code-by-kegg-pathway-options", "Thyroid hormone synthesis", "04918");
						INSERT INTO TEXTS(tag, value, details) VALUES ("search-database-analyses-protein-code-by-kegg-pathway-options", "Tight junction", "04530");
						INSERT INTO TEXTS(tag, value, details) VALUES ("search-database-analyses-protein-code-by-kegg-pathway-options", "Toll-like receptor signaling pathway", "04620");
						INSERT INTO TEXTS(tag, value, details) VALUES ("search-database-analyses-protein-code-by-kegg-pathway-options", "Toluene degradation", "00623");
						INSERT INTO TEXTS(tag, value, details) VALUES ("search-database-analyses-protein-code-by-kegg-pathway-options", "Toxoplasmosis", "05145");
						INSERT INTO TEXTS(tag, value, details) VALUES ("search-database-analyses-protein-code-by-kegg-pathway-options", "Transcriptional misregulation in cancer", "05202");
						INSERT INTO TEXTS(tag, value, details) VALUES ("search-database-analyses-protein-code-by-kegg-pathway-options", "Tropane, piperidine and pyridine alkaloid biosynthesis", "00960");
						INSERT INTO TEXTS(tag, value, details) VALUES ("search-database-analyses-protein-code-by-kegg-pathway-options", "Tryptophan metabolism", "00380");
						INSERT INTO TEXTS(tag, value, details) VALUES ("search-database-analyses-protein-code-by-kegg-pathway-options", "Tuberculosis", "05152");
						INSERT INTO TEXTS(tag, value, details) VALUES ("search-database-analyses-protein-code-by-kegg-pathway-options", "Two-component system", "02020");
						INSERT INTO TEXTS(tag, value, details) VALUES ("search-database-analyses-protein-code-by-kegg-pathway-options", "Type I diabetes mellitus", "04940");
						INSERT INTO TEXTS(tag, value, details) VALUES ("search-database-analyses-protein-code-by-kegg-pathway-options", "Type I polyketide structures", "01052");
						INSERT INTO TEXTS(tag, value, details) VALUES ("search-database-analyses-protein-code-by-kegg-pathway-options", "Type II diabetes mellitus", "04930");
						INSERT INTO TEXTS(tag, value, details) VALUES ("search-database-analyses-protein-code-by-kegg-pathway-options", "Tyrosine metabolism", "00350");
						INSERT INTO TEXTS(tag, value, details) VALUES ("search-database-analyses-protein-code-by-kegg-pathway-options", "Ubiquinone and other terpenoid-quinone biosynthesis", "00130");
						INSERT INTO TEXTS(tag, value, details) VALUES ("search-database-analyses-protein-code-by-kegg-pathway-options", "Ubiquitin mediated proteolysis", "04120");
						INSERT INTO TEXTS(tag, value, details) VALUES ("search-database-analyses-protein-code-by-kegg-pathway-options", "VEGF signaling pathway", "04370");
						INSERT INTO TEXTS(tag, value, details) VALUES ("search-database-analyses-protein-code-by-kegg-pathway-options", "Valine, leucine and isoleucine biosynthesis", "00290");
						INSERT INTO TEXTS(tag, value, details) VALUES ("search-database-analyses-protein-code-by-kegg-pathway-options", "Valine, leucine and isoleucine degradation", "00280");
						INSERT INTO TEXTS(tag, value, details) VALUES ("search-database-analyses-protein-code-by-kegg-pathway-options", "Various types of N-glycan biosynthesis", "00513");
						INSERT INTO TEXTS(tag, value, details) VALUES ("search-database-analyses-protein-code-by-kegg-pathway-options", "Vascular smooth muscle contraction", "04270");
						INSERT INTO TEXTS(tag, value, details) VALUES ("search-database-analyses-protein-code-by-kegg-pathway-options", "Vasopressin-regulated water reabsorption", "04962");
						INSERT INTO TEXTS(tag, value, details) VALUES ("search-database-analyses-protein-code-by-kegg-pathway-options", "Vibrio cholerae infection", "05110");
						INSERT INTO TEXTS(tag, value, details) VALUES ("search-database-analyses-protein-code-by-kegg-pathway-options", "Vibrio cholerae pathogenic cycle", "05111");
						INSERT INTO TEXTS(tag, value, details) VALUES ("search-database-analyses-protein-code-by-kegg-pathway-options", "Viral carcinogenesis", "05203");
						INSERT INTO TEXTS(tag, value, details) VALUES ("search-database-analyses-protein-code-by-kegg-pathway-options", "Viral myocarditis", "05416");
						INSERT INTO TEXTS(tag, value, details) VALUES ("search-database-analyses-protein-code-by-kegg-pathway-options", "Vitamin B6 metabolism", "00750");
						INSERT INTO TEXTS(tag, value, details) VALUES ("search-database-analyses-protein-code-by-kegg-pathway-options", "Vitamin digestion and absorption", "04977");
						INSERT INTO TEXTS(tag, value, details) VALUES ("search-database-analyses-protein-code-by-kegg-pathway-options", "Wnt signaling pathway", "04310");
						INSERT INTO TEXTS(tag, value, details) VALUES ("search-database-analyses-protein-code-by-kegg-pathway-options", "Xylene degradation", "00622");
						INSERT INTO TEXTS(tag, value, details) VALUES ("search-database-analyses-protein-code-by-kegg-pathway-options", "Zeatin biosynthesis", "00908");
						INSERT INTO TEXTS(tag, value, details) VALUES ("search-database-analyses-protein-code-by-kegg-pathway-options", "alpha-Linolenic acid metabolism", "00592");
						INSERT INTO TEXTS(tag, value, details) VALUES ("search-database-analyses-protein-code-by-kegg-pathway-options", "beta-Alanine metabolism", "00410");
						INSERT INTO TEXTS(tag, value, details) VALUES ("search-database-analyses-protein-code-by-kegg-pathway-options", "beta-Lactam resistance", "00312");
						INSERT INTO TEXTS(tag, value, details) VALUES ("search-database-analyses-protein-code-by-kegg-pathway-options", "cAMP signaling pathway", "04024");
						INSERT INTO TEXTS(tag, value, details) VALUES ("search-database-analyses-protein-code-by-kegg-pathway-options", "cGMP-PKG signaling pathway", "04022");
						INSERT INTO TEXTS(tag, value, details) VALUES ("search-database-analyses-protein-code-by-kegg-pathway-options", "mRNA surveillance pathway", "03015");
						INSERT INTO TEXTS(tag, value, details) VALUES ("search-database-analyses-protein-code-by-kegg-pathway-options", "mTOR signaling pathway", "04150");
						INSERT INTO TEXTS(tag, value, details) VALUES ("search-database-analyses-protein-code-by-kegg-pathway-options", "p53 signaling pathway", "04115");

INSERT INTO COMPONENTS(name, component, filepath) VALUES('pathways', 'annotation_pathways.pl', '');
	INSERT INTO TEXTS(tag, value, details) VALUES 
		("search-database-analyses-protein-code-tab", "Phobius", "#phobius"),
        ("search-database-analyses-protein-code-not-containing-phobius", " not containing Phobius results", ""),
        ("search-database-analyses-protein-code-number-transmembrane-domain", "Number of transmembrane domains:", ""),
        ("search-database-analyses-protein-code-number-transmembrane-domain-quantity-or-less", " or less", "value='orLess'"),
        ("search-database-analyses-protein-code-number-transmembrane-domain-quantity-or-more", " or more", "value='orMore'"),
        ("search-database-analyses-protein-code-number-transmembrane-domain-quantity-exactly", " exactly", "value='exact' checked"),
        ("search-database-analyses-protein-code-signal-peptide", "With signal peptide?", ""),
        ("search-database-analyses-protein-code-signal-peptide-option", "yes", "value='sigPyes'"),
        ("search-database-analyses-protein-code-signal-peptide-option", "no", "value='sigPno'"),
        ("search-database-analyses-protein-code-signal-peptide-option", "do not care", "value='sigPwhatever' checked=''");

INSERT INTO COMPONENTS(name, component, filepath) VALUES('phobius', 'annotation_phobius.pl', '');

INSERT INTO COMPONENTS(name, component, filepath) VALUES('predgpi', 'annotation_predgpi.pl', '');
	INSERT INTO TEXTS(tag, value, details) VALUES 
		("search-database-dna-based-analyses-tab", "Ribosomal binding sites", "#ribosomalBindingSites"),
        ("search-database-dna-based-analyses-ribosomal-binding", "Search ribosomal binding sites containing sequence pattern: ", ""),
        ("search-database-dna-based-analyses-or-search-all-ribosomal-binding-shift", " Or search for all ribosomal binding site predictions that recommend a shift in start codon position", ""),
        ("search-database-dna-based-analyses-or-search-all-ribosomal-binding-options", " upstream", "value='neg' checked"),
        ("search-database-dna-based-analyses-or-search-all-ribosomal-binding-options", " downstream", "value='pos'"),
        ("search-database-dna-based-analyses-or-search-all-ribosomal-binding-options", " either", "value='both'"),
        ("search-database-dna-based-analyses-or-search-all-ribosomal-binding-start", "Or search for all ribosomal binding site predictions that recommend a change of  start codon", "");

INSERT INTO COMPONENTS(name, component, filepath) VALUES('rbsfinder', 'annotation_rbsfinder.pl', '/home/wendelhlc/git/report_html_db/report_html_db/rbsfinder_dir/Bacteria.txt');

INSERT INTO COMPONENTS(name, component, filepath) VALUES('rnammer', 'annotation_rnammer.pl', '/home/wendelhlc/git/report_html_db/report_html_db/rnammer_dir/Bacteria_rnammer.gff');

INSERT INTO COMPONENTS(name, component, filepath) VALUES('rpsblast', 'annotation_rpsblast.pl', '');

INSERT INTO COMPONENTS(name, component, filepath) VALUES('signalP', 'annotation_signalP.pl', '');

INSERT INTO COMPONENTS(name, component, filepath) VALUES('skews', 'annotation_skews.pl', '');

INSERT INTO COMPONENTS(name, component, filepath) VALUES('string', 'annotation_string.pl', '/Bacteria_string.txt');

INSERT INTO COMPONENTS(name, component, filepath) VALUES('tcdb', 'annotation_tcdb.pl', '');

INSERT INTO COMPONENTS(name, component, filepath) VALUES('tmhmm', 'annotation_tmhmm.pl', '');
	INSERT INTO TEXTS(tag, value, details) VALUES 
		("search-database-dna-based-analyses-transcriptional-terminators-confidence-score", "Get transcriptional terminators with confidence score: ", ""),
        ("search-database-dna-based-analyses-or-hairpin-score", "Or with hairpin score: ", ""),
        ("search-database-dna-based-analyses-or-tail-score", "Or with tail score: ", ""),
        ("search-database-dna-based-analyses-hairpin-note", "NOTE: hairpin and tail scores are negative.", "");

INSERT INTO COMPONENTS(name, component, filepath) VALUES('transterm', 'annotation_transterm.pl', '/home/wendelhlc/git/report_html_db/report_html_db/transterm_dir/Bacteria.txt');

INSERT INTO COMPONENTS(name, component, filepath) VALUES('trf', 'annotation_trf.pl', '/home/wendelhlc/git/report_html_db/report_html_db/trf_dir/Bacteria_trf.txt');
	INSERT INTO TEXTS(tag, value, details) VALUES 
		("search-database-dna-based-analyses-tab", "tRNA", "#trna"),
        ("search-database-dna-based-analyses-get-by-amino-acid", "Or get tRNAs by amino acid: ", ""),
        ("search-database-dna-based-analyses-get-by-amino-acid-options", "Alanine (A)", "Ala"),                                                                                                
        ("search-database-dna-based-analyses-get-by-amino-acid-options", "Arginine (R)", "Arg"),                                                                                               
        ("search-database-dna-based-analyses-get-by-amino-acid-options", "Asparagine (N)", "Asp"),                                                                                             
        ("search-database-dna-based-analyses-get-by-amino-acid-options", "Aspartic acid (D)", "Ala"),                                                                                          
        ("search-database-dna-based-analyses-get-by-amino-acid-options", "Cysteine (C)", "Cys"),                                                                                               
        ("search-database-dna-based-analyses-get-by-amino-acid-options", "Glutamic acid (E)", "Glu"),                                                                                          
        ("search-database-dna-based-analyses-get-by-amino-acid-options", "Glutamine (Q)", "Gln"),                                                                                              
        ("search-database-dna-based-analyses-get-by-amino-acid-options", "Glycine (G)", "Gly"),                                                                                                
        ("search-database-dna-based-analyses-get-by-amino-acid-options", "Histidine (H)", "His"),                                                                                              
        ("search-database-dna-based-analyses-get-by-amino-acid-options", "Isoleucine (I)", "Ile"),
        ("search-database-dna-based-analyses-get-by-amino-acid-options", "Leucine (L)", "Leu"),
        ("search-database-dna-based-analyses-get-by-amino-acid-options", "Lysine (K)", "Lys"),
        ("search-database-dna-based-analyses-get-by-amino-acid-options", "Methionine (M)", "Met"),
        ("search-database-dna-based-analyses-get-by-amino-acid-options", "Phenylalanine (F)", "Phe"),
        ("search-database-dna-based-analyses-get-by-amino-acid-options", "Proline (P)", "Pro"),
        ("search-database-dna-based-analyses-get-by-amino-acid-options", "Serine (S)", "Ser"),
        ("search-database-dna-based-analyses-get-by-amino-acid-options", "Threonine (T)", "Thr"),
        ("search-database-dna-based-analyses-get-by-amino-acid-options", "Tryptophan (W)", "Trp"),
        ("search-database-dna-based-analyses-get-by-amino-acid-options", "Tyrosine (Y)", "Tyr"),
        ("search-database-dna-based-analyses-get-by-amino-acid-options", "Valine (V)", "Val"),
        ("search-database-dna-based-analyses-get-by-codon", "Or get tRNAs by codon: ", ""),
        ("search-database-dna-based-analyses-get-by-codon-options", "AAA", "AAA"),                                                                                                             
        ("search-database-dna-based-analyses-get-by-codon-options", "AAC", "AAC"),                                                                                                             
        ("search-database-dna-based-analyses-get-by-codon-options", "AAG", "AAG"),                                                                                                             
        ("search-database-dna-based-analyses-get-by-codon-options", "AAT", "AAT"),                                                                                                             
        ("search-database-dna-based-analyses-get-by-codon-options", "ACA", "ACA"),                                                                                                             
        ("search-database-dna-based-analyses-get-by-codon-options", "ACC", "ACC"),                                                                                                             
        ("search-database-dna-based-analyses-get-by-codon-options", "ACG", "ACG"),                                                                                                             
        ("search-database-dna-based-analyses-get-by-codon-options", "ACT", "ACT"),                                                                                                             
        ("search-database-dna-based-analyses-get-by-codon-options", "AGA", "AGA"),                                                                                                             
        ("search-database-dna-based-analyses-get-by-codon-options", "AGC", "AGC"),
        ("search-database-dna-based-analyses-get-by-codon-options", "AGG", "AGG"),
        ("search-database-dna-based-analyses-get-by-codon-options", "AGT", "AGT"),
        ("search-database-dna-based-analyses-get-by-codon-options", "ATA", "ATA"),
        ("search-database-dna-based-analyses-get-by-codon-options", "ATC", "ATC"),
        ("search-database-dna-based-analyses-get-by-codon-options", "ATG", "ATG"),
        ("search-database-dna-based-analyses-get-by-codon-options", "ATT", "ATT"),
        ("search-database-dna-based-analyses-get-by-codon-options", "CAA", "CAA"),
        ("search-database-dna-based-analyses-get-by-codon-options", "CAC", "CAC"),
        ("search-database-dna-based-analyses-get-by-codon-options", "CAG", "CAG"),
        ("search-database-dna-based-analyses-get-by-codon-options", "CAT", "CAT"),
        ("search-database-dna-based-analyses-get-by-codon-options", "CCA", "CCA"),
        ("search-database-dna-based-analyses-get-by-codon-options", "CCC", "CCC"),
        ("search-database-dna-based-analyses-get-by-codon-options", "CCG", "CCG"),
        ("search-database-dna-based-analyses-get-by-codon-options", "CCT", "CCT"),
        ("search-database-dna-based-analyses-get-by-codon-options", "CGA", "CGA"),
        ("search-database-dna-based-analyses-get-by-codon-options", "CGC", "CGC"),
        ("search-database-dna-based-analyses-get-by-codon-options", "CGG", "CGG"),
        ("search-database-dna-based-analyses-get-by-codon-options", "CGT", "CGT"),
        ("search-database-dna-based-analyses-get-by-codon-options", "CTA", "CTA"),
        ("search-database-dna-based-analyses-get-by-codon-options", "CTC", "CTC"),
        ("search-database-dna-based-analyses-get-by-codon-options", "CTG", "CTG"),
        ("search-database-dna-based-analyses-get-by-codon-options", "CTT", "CTT"),
        ("search-database-dna-based-analyses-get-by-codon-options", "GAA", "GAA"),
        ("search-database-dna-based-analyses-get-by-codon-options", "GAC", "GAC"),
        ("search-database-dna-based-analyses-get-by-codon-options", "GAG", "GAG"),
        ("search-database-dna-based-analyses-get-by-codon-options", "GAT", "GAT"),
        ("search-database-dna-based-analyses-get-by-codon-options", "GCA", "GCA"),
        ("search-database-dna-based-analyses-get-by-codon-options", "GCC", "GCC"),
        ("search-database-dna-based-analyses-get-by-codon-options", "GCG", "GCG"),
        ("search-database-dna-based-analyses-get-by-codon-options", "GCT", "GCT"),
        ("search-database-dna-based-analyses-get-by-codon-options", "GGA", "GGA"),
        ("search-database-dna-based-analyses-get-by-codon-options", "GGC", "GGC"),
        ("search-database-dna-based-analyses-get-by-codon-options", "GGG", "GGG"),
        ("search-database-dna-based-analyses-get-by-codon-options", "GGT", "GGT"),
        ("search-database-dna-based-analyses-get-by-codon-options", "GTA", "GTA"),
        ("search-database-dna-based-analyses-get-by-codon-options", "GTC", "GTC"),
        ("search-database-dna-based-analyses-get-by-codon-options", "GTG", "GTG"),
        ("search-database-dna-based-analyses-get-by-codon-options", "GTT", "GTT"),
        ("search-database-dna-based-analyses-get-by-codon-options", "TAC", "TAC"),
        ("search-database-dna-based-analyses-get-by-codon-options", "TAT", "TAT"),
        ("search-database-dna-based-analyses-get-by-codon-options", "TCA", "TCA"),
        ("search-database-dna-based-analyses-get-by-codon-options", "TCC", "TCC"),
        ("search-database-dna-based-analyses-get-by-codon-options", "TCG", "TCG"),
        ("search-database-dna-based-analyses-get-by-codon-options", "TCT", "TCT"),
        ("search-database-dna-based-analyses-get-by-codon-options", "TGC", "TGC"),
        ("search-database-dna-based-analyses-get-by-codon-options", "TGG", "TGG"),
        ("search-database-dna-based-analyses-get-by-codon-options", "TGT", "TGT"),
        ("search-database-dna-based-analyses-get-by-codon-options", "TTA", "TTA"),
        ("search-database-dna-based-analyses-get-by-codon-options", "TTC", "TTC"),
        ("search-database-dna-based-analyses-get-by-codon-options", "TTG", "TTG"),
        ("search-database-dna-based-analyses-get-by-codon-options", "TTT", "TTT");

INSERT INTO COMPONENTS(name, component, filepath) VALUES('trna', 'annotation_trna.pl', '/home/wendelhlc/git/report_html_db/report_html_db/trna_dir/Bacteria_trna.txt');

INSERT INTO COMPONENTS(name, component, filepath) VALUES('conclusion', 'report_conclusion.pl', '');

INSERT INTO COMPONENTS(name, component, filepath) VALUES('go', 'report_go.pl', '/home/wendelhlc/git/report_html_db/report_html_db/go_report/go_mapping.html;');

INSERT INTO COMPONENTS(name, component, filepath) VALUES('orthology', 'report_orthology.pl', '');

INSERT INTO COMPONENTS(name, component, filepath) VALUES('pathways', 'report_pathways.pl', '/home/wendelhlc/git/report_html_db/report_html_db/kegg_report/classes.html;');

INSERT INTO COMPONENTS(name, component, filepath) VALUES('oad_fasta', 'upload_fasta.pl', '');
