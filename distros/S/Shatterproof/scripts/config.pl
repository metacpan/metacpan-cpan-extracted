our $bin_size 			= 1000;		#number of bases pairs to comprise one region in the arrays below
our $localization_window_size 	= 10000;	#number of regions to sum together. Each entry in the arrays below is the sum of this many regions

our $expected_mutation_density = 0.0000005;

our $collapse_regions = 1;

our $outlier_deviation = 2;

our $translocation_cut_off_count = 8;

#Hallmark Weightings
our $genome_localization_weight			= 0.1145;
our $chromosome_localization_weight		= 0.1697;
our $cnv_weight					= 0.2724;
our $translocation_weight 			= 0.2724;
our $insertion_breakpoint_weight		= 0.0657;
our $loh_weight					= 0.0648;
our $tp53_mutated_weight			= 0.0406;
