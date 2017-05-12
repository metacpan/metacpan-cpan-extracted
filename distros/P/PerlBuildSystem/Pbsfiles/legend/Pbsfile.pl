
ExcludeFromDigestGeneration('Legend Pbsfiles' => qr/\.pl$/) ;
#AddFileDependencies('/usr/local/lib/perl5/site_perl/5.8.0/PBS/Graph.pm') ;


AddRule [VIRTUAL], 'all'
	, 	[ 
		'all' => 
		  'graphs/legend.png'
		, 'graphs/config_legend_1.png'
		, 'graphs/config_legend_2.png'
		, 'graphs/config_legend_3.png'
		, 'graphs/cyclic_legend.png'
		]
	, BuildOk("Done") ;


#--------------------------------------------------------------------------------------------------------

AddRule 'legend', ['graphs/legend.png' => '../legend.pl', '../subpbs.pl']
	, "pbs -no_build -p legend.pl --gtg %FILE_TO_BUILD -gtg_tn -gtg_cn clustered all" ;

#--------------------------------------------------------------------------------------------------------

AddRule 'cyclic_legend', ['graphs/cyclic_legend.png' => '../cyclic_legend.pl']
	, "pbs -no_build -p cyclic_legend.pl --gtg %FILE_TO_BUILD all ; true" ;

#--------------------------------------------------------------------------------------------------------

my @config_legend_dependencies = qw(../config_legend.pl ../subpbs2.pl ../subpbs3.pl) ;
my $cmd = "pbs -no_build -p config_legend.pl --gtg %FILE_TO_BUILD" ;

AddRule 'config_legend_1', ['graphs/config_legend_1.png' => @config_legend_dependencies]
	, "$cmd -gtg_config -gtg_config_edge -gtg_pbs_config -gtg_pbs_config_edge all" ;
	
AddRule 'config_legend_2', ['graphs/config_legend_2.png' => @config_legend_dependencies]
	, "$cmd -gtg_config -gtg_config_edge -gtg_pbs_config all" ;
	
AddRule 'config_legend_3', ['graphs/config_legend_3.png' => @config_legend_dependencies]
	, "$cmd -gtg_config -gtg_pbs_config all" ;

