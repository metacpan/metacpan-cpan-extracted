package RPM::Header::PurePerl::Tagtable;

require Exporter;
use vars qw(@ISA @EXPORT);
@ISA = qw(Exporter);
use vars qw(%hdr_tags);
@EXPORT = qw(%hdr_tags);

%hdr_tags = 
(
	63 =>	{
	 	'TAGNAME'	=>	'UNKNOWN1',
		'GROUP'		=>	'UNKNOWN',
		'NAME'		=>	''
	},
	
	620 =>	{
	 	'TAGNAME'	=>	'UNKNOWN2',
		'GROUP'		=>	'UNKNOWN',
		'NAME'		=>	''
	},

	
	2650 =>	{
	 	'TAGNAME'	=>	'SHA1HEADER1',
		'GROUP'		=>	'SIGNATURE',
		'NAME'		=>	'',
		'TYPE'		=>	1
	},	
	
	2670 =>	{
	 	'TAGNAME'	=>	'UNKNOWN3',
		'GROUP'		=>	'UNKNOWN',
		'NAME'		=>	''
	},	
	
	2690 =>	{
	 	'TAGNAME'	=>	'SHA1HEADER',
		'GROUP'		=>	'SIGNATURE',
		'NAME'		=>	'',
		'TYPE'		=>	1
	},
	
	
	
	100 =>	{
	 	'TAGNAME'	=>	'DESCRIPTIONLANGS',
		'GROUP'		=>	'DESCRIPTIONLANGS',
		'NAME'		=>	'',
		'TYPE'		=>	1
	},
	 
	1000 => {
		'TAGNAME'	=>	'NAME',
		'GROUP'		=>	'INFORMATION',
		'NAME'		=>	'Name'
	},
	1001 => {
		'TAGNAME'	=>	'VERSION',
		'GROUP'		=>	'INFORMATION',
		'NAME'		=>	'Version'
	},
	1002 => {
		'TAGNAME'	=>	'RELEASE',
		'GROUP'		=>	'INFORMATION',
		'NAME'		=>	'Release'
	},
	1003 => {
		'TAGNAME'	=>	'EPOCH',
		'GROUP'		=>	'INFORMATION',
		'NAME'		=>	'Epoch do something with me'
	},
	1004 => {
		'TAGNAME'	=>	'SUMMARY',
		'GROUP'		=>	'DESCRIPTION',
		'NAME'		=>	'Summary',
		'TYPE'		=>	1
	},
	1005 => {
		'TAGNAME'	=>	'DESCRIPTION',
		'GROUP'		=>	'DESCRIPTION',
		'NAME'		=>	'Description',
		'TYPE'		=>	1
	},
	1006 => {
		'TAGNAME'	=>	'BUILDTIME',
		'GROUP'		=>	'PACKAGE',
		'NAME'		=>	'BuildTime'
	},
	1007 => {
		'TAGNAME'	=>	'BUILDHOST',
		'GROUP'		=>	'PACKAGE',
		'NAME'		=>	'BuildHost'
	},
	1008 => {
		'TAGNAME'	=>	'INSTALLTIME',
		'GROUP'		=>	'PACKAGE',
		'NAME'		=>	'InstallTime'
	},
	1009 => {
		'TAGNAME'	=>	'SIZE',
		'GROUP'		=>	'PACKAGE',
		'NAME'		=>	'Size'
	},
	1010 => {
		'TAGNAME'	=>	'DISTRIBUTION',
		'GROUP'		=>	'INFORMATION',
		'NAME'		=>	'Distribution'
	},
	1011 => {
		'TAGNAME'	=>	'VENDOR',
		'GROUP'		=>	'INFORMATION',
		'NAME'		=>	'Vendor'
	},
	1012 => {
		'TAGNAME'	=>	'GIF',
		'GROUP'		=>	'BINARY',
		'NAME'		=>	''
	},
	1013 => {
		'TAGNAME'	=>	'XPM',
		'GROUP'		=>	'BINARY',
		'NAME'		=>	''
	},
	1014 => {
		'TAGNAME'	=>	'LICENSE',
		'GROUP'		=>	'INFORMATION',
		'NAME'		=>	'License'
	},
	1015 => {
		'TAGNAME'	=>	'PACKAGER',
		'GROUP'		=>	'INFORMATION',
		'NAME'		=>	'Packager'
	},
	1016 => {
		'TAGNAME'	=>	'GROUP',
		'GROUP'		=>	'INFORMATION',
		'NAME'		=>	'Location'
	},
	1018 => {
		'TAGNAME'	=>	'SOURCE',
		'GROUP'		=>	'OTHER',
		'NAME'		=>	''
	},
	1019 => {
		'TAGNAME'	=>	'PATCH',
		'GROUP'		=>	'OTHER',
		'NAME'		=>	''
	},
	1020 => {
		'TAGNAME'	=>	'URL',
		'GROUP'		=>	'INFORMATION',
		'NAME'		=>	'URL'
	},
	1021 => {
		'TAGNAME'	=>	'OS',
		'GROUP'		=>	'INFORMATION',
		'NAME'		=>	'Os'
	},
	1022 => {
		'TAGNAME'	=>	'ARCH',
		'GROUP'		=>	'INFORMATION',
		'NAME'		=>	'Arch'
	},
	1023 => {
		'TAGNAME'	=>	'PREIN',
		'GROUP'		=>	'TRIGGER',
		'NAME'		=>	'',
		'TYPE'		=>	1
	},
	1024 => {
		'TAGNAME'	=>	'POSTIN',
		'GROUP'		=>	'TRIGGER',
		'NAME'		=>	'',
		'TYPE'		=>	1

	},
	1025 => {
		'TAGNAME'	=>	'PREUN',
		'GROUP'		=>	'TRIGGER',
		'NAME'		=>	'',
		'TYPE'		=>	1
	},
	1026 => {
		'TAGNAME'	=>	'POSTUN',
		'GROUP'		=>	'TRIGGER',
		'NAME'		=>	'',
		'TYPE'		=>	1
	},
	1027 => {
		'TAGNAME'	=>	'FILENAMES',
		'GROUP'		=>	'FILE',
		'NAME'		=>	'',
		'TYPE'		=>	1
	},
	1028 => {
		'TAGNAME'	=>	'FILESIZES',
		'GROUP'		=>	'FILE',
		'NAME'		=>	'',
		'TYPE'		=>	1

	},
	1029 => {
		'TAGNAME'	=>	'FILESTATES',
		'GROUP'		=>	'FILE',
		'NAME'		=>	'',
		'TYPE'		=>	1

	},
	1030 => {
		'TAGNAME'	=>	'FILEMODES',
		'GROUP'		=>	'FILE',
		'NAME'		=>	'',
		'TYPE'		=>	1

	},
	1131 =>	{
	 	'TAGNAME'	=>	'RHNPLATFORM',
		'GROUP'		=>	'INFORMATION',
		'NAME'		=>	'RHN Platform',
		'TYPE'		=>	1
	},
	1132 =>	{
	 	'TAGNAME'	=>	'PLATFORM',
		'GROUP'		=>	'INFORMATION',
		'NAME'		=>	'RHN Platform',
		'TYPE'		=>	1
	},
	1033 => {
		'TAGNAME'	=>	'FILERDEVS',
		'GROUP'		=>	'FILE',
		'NAME'		=>	'',
		'TYPE'		=>	1

	},
	1034 => {
		'TAGNAME'	=>	'FILEMTIMES',
		'GROUP'		=>	'FILE',
		'NAME'		=>	'',
		'TYPE'		=>	1

	},
	1035 => {
		'TAGNAME'	=>	'FILEMD5S',
		'GROUP'		=>	'FILE',
		'NAME'		=>	'',
		'TYPE'		=>	1

	},
	1036 => {
		'TAGNAME'	=>	'FILELINKTOS',
		'GROUP'		=>	'FILE',
		'NAME'		=>	'',
		'TYPE'		=>	1

	},
	1037 => {
		'TAGNAME'	=>	'FILEFLAGS',
		'GROUP'		=>	'FILE',
		'NAME'		=>	'',
		'TYPE'		=>	1

	},
	1038 => {
		'TAGNAME'	=>	'ROOT',
		'GROUP'		=>	'OBSOLETED',
		'NAME'		=>	''
	},
	1039 => {
		'TAGNAME'	=>	'FILEUSERNAME',
		'GROUP'		=>	'FILE',
		'NAME'		=>	'',
		'TYPE'		=>	1

	},
	1040 => {
		'TAGNAME'	=>	'FILEGROUPNAME',
		'GROUP'		=>	'FILE',
		'NAME'		=>	'',
		'TYPE'		=>	1

	},
	1043 => {
		'TAGNAME'	=>	'ICON',
		'GROUP'		=>	'BINARY',
		'NAME'		=>	''
	},
	1044 => {
		'TAGNAME'	=>	'SOURCERPM',
		'GROUP'		=>	'USELESS',
		'NAME'		=>	''
	},
	1045 => {
		'TAGNAME'	=>	'FILEVERIFYFLAGS',
		'GROUP'		=>	'FILE',
		'NAME'		=>	'',
		'TYPE'		=>	1

	},
	1046 => {
		'TAGNAME'	=>	'ARCHIVESIZE',
		'GROUP'		=>	'USELESS',
		'NAME'		=>	'Archive size including SIG'
	},
	1047 => {
		'TAGNAME'	=>	'PROVIDENAME',
		'GROUP'		=>	'PROVIDE',
		'NAME'		=>	'',
		'TYPE'		=>	1

	},
	1048 => {
		'TAGNAME'	=>	'REQUIREFLAGS',
		'GROUP'		=>	'REQUIRE',
		'NAME'		=>	'',
		'TYPE'		=>	1

	},
	1049 => {
		'TAGNAME'	=>	'REQUIRENAME',
		'GROUP'		=>	'REQUIRE',
		'NAME'		=>	'',
		'TYPE'		=>	1

	},
	1050 => {
		'TAGNAME'	=>	'REQUIREVERSION',
		'GROUP'		=>	'REQUIRE',
		'NAME'		=>	'',
		'TYPE'		=>	1

	},
	1053 => {
		'TAGNAME'	=>	'CONFLICTFLAGS',
		'GROUP'		=>	'CONFLICT',
		'NAME'		=>	'',
		'TYPE'		=>	1

	},
	1054 => {
		'TAGNAME'	=>	'CONFLICTNAME',
		'GROUP'		=>	'CONFLICT',
		'NAME'		=>	'',
		'TYPE'		=>	1

	},
	1055 => {
		'TAGNAME'	=>	'CONFLICTVERSION',
		'GROUP'		=>	'CONFLICT',
		'NAME'		=>	'',
		'TYPE'		=>	1

	},
	1057 => {
		'TAGNAME'	=>	'BUILDROOT',
		'GROUP'		=>	'OTHER',
		'NAME'		=>	'',
		'TYPE'		=>	1

	},
	1059 => {
		'TAGNAME'	=>	'EXCLUDEARCH',
		'GROUP'		=>	'OTHER',
		'NAME'		=>	''
	},
	1060 => {
		'TAGNAME'	=>	'EXCLUDEOS',
		'GROUP'		=>	'OTHER',
		'NAME'		=>	''
	},
	1061 => {
		'TAGNAME'	=>	'EXCLUSIVEARCH',
		'GROUP'		=>	'OTHER',
		'NAME'		=>	''
	},
	1062 => {
		'TAGNAME'	=>	'EXCLUSIVEOS',
		'GROUP'		=>	'OTHER',
		'NAME'		=>	''
	},
	1064 => {
		'TAGNAME'	=>	'RPMVERSION',
		'GROUP'		=>	'PAYLOAD',
		'NAME'		=>	''
	},
	1065 => {
		'TAGNAME'	=>	'TRIGGERSCRIPTS',
		'GROUP'		=>	'TRIGGER',
		'NAME'		=>	'',
		'TYPE'		=>	1

	},
	1066 => {
		'TAGNAME'	=>	'TRIGGERNAME',
		'GROUP'		=>	'TRIGGER',
		'NAME'		=>	'',
		'TYPE'		=>	1

	},
	1067 => {
		'TAGNAME'	=>	'TRIGGERVERSION',
		'GROUP'		=>	'TRIGGER',
		'NAME'		=>	'',
		'TYPE'		=>	1

	},
	1068 => {
		'TAGNAME'	=>	'TRIGGERFLAGS',
		'GROUP'		=>	'TRIGGER',
		'NAME'		=>	'',
		'TYPE'		=>	1

	},
	1069 => {
		'TAGNAME'	=>	'TRIGGERINDEX',
		'GROUP'		=>	'TRIGGER',
		'NAME'		=>	'',
		'TYPE'		=>	1

	},
	1079 => {
		'TAGNAME'	=>	'VERIFYSCRIPT',
		'GROUP'		=>	'TRIGGER',
		'NAME'		=>	'',
		'TYPE'		=>	1

	},
	1080 => {
		'TAGNAME'	=>	'CHANGELOGTIME',
		'GROUP'		=>	'CHANGELOG',
		'NAME'		=>	'',
		'TYPE'		=>	1

	},
	1081 => {
		'TAGNAME'	=>	'CHANGELOGNAME',
		'GROUP'		=>	'CHANGELOG',
		'NAME'		=>	'',
		'TYPE'		=>	1

	},
	1082 => {
		'TAGNAME'	=>	'CHANGELOGTEXT',
		'GROUP'		=>	'CHANGELOG',
		'NAME'		=>	'',
		'TYPE'		=>	1

	},
	1085 => {
		'TAGNAME'	=>	'PREINPROG',
		'GROUP'		=>	'TRIGGER',
		'NAME'		=>	'',
		'TYPE'		=>	1

	},
	1086 => {
		'TAGNAME'	=>	'POSTINPROG',
		'GROUP'		=>	'TRIGGER',
		'NAME'		=>	'',
		'TYPE'		=>	1

	},
	1087 => {
		'TAGNAME'	=>	'PREUNPROG',
		'GROUP'		=>	'TRIGGER',
		'NAME'		=>	'',
		'TYPE'		=>	1

	},
	1088 => {
		'TAGNAME'	=>	'POSTUNPROG',
		'GROUP'		=>	'TRIGGER',
		'NAME'		=>	'',
		'TYPE'		=>	1

	},
	1089 => {
		'TAGNAME'	=>	'BUILDARCHS',
		'GROUP'		=>	'OTHER',
		'NAME'		=>	'',
		'TYPE'		=>	1

	},
	1090 => {
		'TAGNAME'	=>	'OBSOLETENAME',
		'GROUP'		=>	'OBSOLETE',
		'NAME'		=>	'',
		'TYPE'		=>	1
	},
	1091 => {
		'TAGNAME'	=>	'VERIFYSCRIPTPROG',
		'GROUP'		=>	'TRIGGER',
		'NAME'		=>	'',
		'TYPE'		=>	1

	},
	1092 => {
		'TAGNAME'	=>	'TRIGGERSCRIPTPROG',
		'GROUP'		=>	'TRIGGER',
		'NAME'		=>	'',
		'TYPE'		=>	1

	},
	1094 => {
		'TAGNAME'	=>	'COOKIE',
		'GROUP'		=>	'USELESS',
		'NAME'		=>	''
	},
	1095 => {
		'TAGNAME'	=>	'FILEDEVICES',
		'GROUP'		=>	'FILE',
		'NAME'		=>	'',
		'TYPE'		=>	1

	},
	1096 => {
		'TAGNAME'	=>	'FILEINODES',
		'GROUP'		=>	'FILE',
		'NAME'		=>	'',
		'TYPE'		=>	1

	},
	1097 => {
		'TAGNAME'	=>	'FILELANGS',
		'GROUP'		=>	'FILE',
		'NAME'		=>	'',
		'TYPE'		=>	1

	},
	1098 => {
		'TAGNAME'	=>	'PREFIXES',
		'GROUP'		=>	'PACKAGE',
		'NAME'		=>	'Prefixes',
		'TYPE'		=>	1
	},
	1099 => {
		'TAGNAME'	=>	'INSTPREFIXES',
		'GROUP'		=>	'OTHER',
		'NAME'		=>	'',
		'TYPE'		=>	1

	},
	1105 => {
		'TAGNAME'	=>	'RPMTAG_CAPABILITY',
		'GROUP'		=>	'OBSOLETED',
		'NAME'		=>	''
	},
	1107 => {
		'TAGNAME'	=>	'OLDORIGFILENAMES',
		'GROUP'		=>	'OTHER',
		'NAME'		=>	''
	},
	1111 => {
		'TAGNAME'	=>	'BUILDMACROS',
		'GROUP'		=>	'OTHER',
		'NAME'		=>	''
	},
	1112 => {
		'TAGNAME'	=>	'PROVIDEFLAGS',
		'GROUP'		=>	'PROVIDE',
		'NAME'		=>	'',
		'TYPE'		=>	1

	},
	1113 => {
		'TAGNAME'	=>	'PROVIDEVERSION',
		'GROUP'		=>	'PROVIDE',
		'NAME'		=>	'',
		'TYPE'		=>	1

	},
	1114 => {
		'TAGNAME'	=>	'OBSOLETEFLAGS',
		'GROUP'		=>	'OBSOLETE',
		'NAME'		=>	'',
		'TYPE'		=>	1

	},
	1115 => {
		'TAGNAME'	=>	'OBSOLETEVERSION',
		'GROUP'		=>	'OBSOLETE',
		'NAME'		=>	'',
		'TYPE'		=>	1

	},
	1116 => {
		'TAGNAME'	=>	'DIRINDEXES',
		'GROUP'		=>	'FILERPM4',
		'NAME'		=>	'',
		'TYPE'		=>	1

	},
	1117 => {
		'TAGNAME'	=>	'BASENAMES',
		'GROUP'		=>	'FILERPM4',
		'NAME'		=>	'',
		'TYPE'		=>	1

	},
	1118 => {
		'TAGNAME'	=>	'DIRNAMES',
		'GROUP'		=>	'FILERPM4',
		'NAME'		=>	'',
		'TYPE'		=>	1

	},
	1122 => {
		'TAGNAME'	=>	'OPTFLAGS',
		'GROUP'		=>	'PACKAGE',
		'NAME'		=>	'BuildFlags',
		'TYPE'		=>	1
	},
	1123 => {
		'TAGNAME'	=>	'DISTURL',
		'GROUP'		=>	'OTHER',
		'NAME'		=>	''
	},
	1124 => {
		'TAGNAME'	=>	'PAYLOADFORMAT',
		'GROUP'		=>	'PAYLOAD',
		'NAME'		=>	'',
		'TYPE'		=>	1
	},
	1125 => {
		'TAGNAME'	=>	'PAYLOADCOMPRESSOR',
		'GROUP'		=>	'PAYLOAD',
		'NAME'		=>	'',
		'TYPE'		=>	1
	},
	1126 => {
		'TAGNAME'	=>	'PAYLOADFLAGS',
		'GROUP'		=>	'PAYLOAD',
		'NAME'		=>	'',
		'TYPE'		=>	1
	},
	1127 => {
		'TAGNAME'	=>	'MULTILIBS',
		'GROUP'		=>	'OTHER',
		'NAME'		=>	''
	},
	1128 => {
		'TAGNAME'	=>	'INSTALLTID',
		'GROUP'		=>	'OTHER',
		'NAME'		=>	''
	},
	1129 => {
		'TAGNAME'	=>	'REMOVETID',
		'GROUP'		=>	'OTHER',
		'NAME'		=>	''
	},
	1177 => {
		'TAGNAME'	=>	'Filedigestalgos',
		'GROUP'		=>	'OTHER',
		'NAME'		=>	'',
		'TYPE'		=>	4,
	},
	1140 => {
		'TAGNAME'	=>	'Sourcepkgid',
		'GROUP'		=>	'OTHER',
		'NAME'		=>	'',
		'TYPE'		=>	4,
	},
	1141 => {
		'TAGNAME'	=>	'Fileclass',
		'GROUP'		=>	'OTHER',
		'NAME'		=>	'',
		'TYPE'		=>	4,
	},
	1142 => {
		'TAGNAME'	=>	'Classdict',
		'GROUP'		=>	'OTHER',
		'NAME'		=>	'',
		'TYPE'		=>	8,
	},
	1143 => {
		'TAGNAME'	=>	'Filedependsx',
		'GROUP'		=>	'OTHER',
		'NAME'		=>	'',
		'TYPE'		=>	4,
	},
	1144 => {
		'TAGNAME'	=>	'Filedependsn',
		'GROUP'		=>	'OTHER',
		'NAME'		=>	'',
		'TYPE'		=>	4,
	},
	1145 => {
		'TAGNAME'	=>	'Dependsdict',
		'GROUP'		=>	'OTHER',
		'NAME'		=>	'',
		'TYPE'		=>	4,
	},
    1146 => {
		'TAGNAME'	=>	'Sourcepkgid',
		'GROUP'		=>	'OTHER',
		'NAME'		=>	'',
		'TYPE'		=>	7,
	},

	# fake tagnumber*10
	10000 => {
		'TAGNAME'	=>	'SIGSIZE',
		'GROUP'		=>	'SIGNATURE',
		'NAME'		=>	'Signature Size',
		'TYPE'		=>	1
	},
		
	10010 => {
		'TAGNAME'	=>	'SIGMD5',
		'GROUP'		=>	'SIGNATURE',
		'NAME'		=>	'MD5 Signature',
		'TYPE'		=>	1
	},
		
	10030 => {
		'TAGNAME'	=>	'SIGGPG',
		'GROUP'		=>	'SIGNATURE',
		'NAME'		=>	'PGP Signature',
		'TYPE'		=>	1
	},
		
	10040 => {
		'TAGNAME'	=>	'SIGMD5',
		'GROUP'		=>	'SIGNATURE',
		'NAME'		=>	'MD5 sum',
		'TYPE'		=>	1
	},
		
	10050 => {
		'TAGNAME'	=>	'SIGGPG',
		'GROUP'		=>	'SIGNATURE',
		'NAME'		=>	'PGP Signature',
		'TYPE'		=>	1,
	},

	10070 => {
		'TAGNAME'	=>	'UNKNOWN4',
		'GROUP'		=>	'OTHER',
		'NAME'		=>	'',
	}
);

