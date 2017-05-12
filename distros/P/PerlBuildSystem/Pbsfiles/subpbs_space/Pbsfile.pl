AddRule [VIRTUAL], 'all_lib',['all' => 'something'], BuildOk() ;

#~ AddRule 'sub_pbsfile',
	#~ {
	  #~ NODE_REGEX => 'something'
	#~ , PBSFILE => './subpbs.pl'
	#~ , PACKAGE => 'name with spaces'
	#~ } ;

AddSubpbsRule 'sub_pbsfile', 'something', './subpbs.pl', 'name with spaces' ;
