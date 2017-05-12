# WIZARD_GROUP PBS
# WIZARD_NAME  subpbs
# WIZARD_DESCRIPTION template for a subpbs defintion
# WIZARD_ON

print <<'EOP' ;
AddRule 'subpbs_name',
	{
	  NODE_REGEX         => ''
	, PBSFILE            => './Pbsfile.pl'
	, PACKAGE            => ''
	
	#~ , IGNORE_LOCAL_RULES => 1
	} ;
EOP


