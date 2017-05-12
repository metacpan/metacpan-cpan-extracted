#
# This file is part of Pod-Spell-CommonMistakes
#
# This software is copyright (c) 2014 by Apocalypse.
#
# This is free software; you can redistribute it and/or modify it under
# the same terms as the Perl 5 programming language system itself.
#
use strict; use warnings;
package Pod::Spell::CommonMistakes::WordList;
$Pod::Spell::CommonMistakes::WordList::VERSION = '1.002';
our $AUTHORITY = 'cpan:APOCAL';

# ABSTRACT: Holds the wordlist data for Pod::Spell::CommonMistakes

# auto-export our 2 subs
use parent qw( Exporter );
our @EXPORT = qw( _check_case _check_common );

# TODO Figure out an autoimporter?
# apoc@box:~/lintian/data/spelling$ cat corrections-case | perl -e 'print "my \%case = (\n"; while ( <STDIN> ) { next if $_ =~ /^#/; if ( $_ =~ /^(.+)\|\|(.+)$/ ) { print " \"$1\" => \"$2\",\n" } }; print ");\n"'

# CASE LIST

#apoc@blackhole:~/othergit/lintian/data/spelling$ cat corrections-case
# Picky corrections, applied before lowercasing the word.  These are only
# applied to things known to be entirely English text, such as package
# descriptions, and should not be applied to files that may contain
# configuration fragments or more informal files such as debian/copyright.
#
# The format of each line is:
# mistake||correction

my %case = (
 "apache" => "Apache",
 "api" => "API",
 "Api" => "API",
 "D-BUS" => "D-Bus",
 "d-bus" => "D-Bus",
 "dbus" => "D-Bus",
 "debian" => "Debian",
 "Debian-Edu" => "Debian Edu",
 "debian-edu" => "Debian Edu",
 "Docbook" => "DocBook",
 "docbook" => "DocBook",
 "english" => "English",
 "french" => "French",
 "EMacs" => "Emacs",
 "Gconf" => "GConf",
 "gconf" => "GConf",
 "german" => "German",
 "Gnome" => "GNOME",
 "gnome" => "GNOME",
 "Gnome-VFS" => "GnomeVFS",
 "Gnome-Vfs" => "GnomeVFS",
 "GnomeVfs" => "GnomeVFS",
 "gnome-vfs" => "GnomeVFS",
 "gnomevfs" => "GnomeVFS",
 "gnu" => "GNU",
 "Gnu" => "GNU",
 "Gobject" => "GObject",
 "gobject" => "GObject",
 "Gstreamer" => "GStreamer",
 "gstreamer" => "GStreamer",
 "GTK" => "GTK+",
 "gtk+" => "GTK+",
 "Http" => "HTTP",
 "kde" => "KDE",
 "meta-package" => "metapackage",
 "MYSQL" => "MySQL",
 "Mysql" => "MySQL",
 "mysql" => "MySQL",
 "linux" => "Linux",
 "Latex" => "LaTeX",
 "latex" => "LaTeX",
 "oAuth" => "OAuth",
 "OCAML" => "OCaml",
 "Ocaml" => "OCaml",
 "ocaml" => "OCaml",
 "OpenLdap" => "OpenLDAP",
 "Openldap" => "OpenLDAP",
 "openldap" => "OpenLDAP",
 "openstreetmap" => "OpenStreetMap",
 "Openstreetmap" => "OpenStreetMap",
 "OpenStreetmap" => "OpenStreetMap",
 "Postgresql" => "PostgreSQL",
 "postgresql" => "PostgreSQL",
 "python" => "Python",
 "russian" => "Russian",
 "SkoleLinux" => "Skolelinux",
 "skolelinux" => "Skolelinux",
 "SLang" => "S-Lang",
 "S-lang" => "S-Lang",
 "s-lang" => "S-Lang",
 "spanish" => "Spanish",
 "subversion" => "Subversion",
 "TCL" => "Tcl",
 "tcl" => "Tcl",
 "TEX" => "TeX",
 "Tex" => "TeX",
 "TeTeX" => "teTeX",
 "Tetex" => "teTeX",
 "tetex" => "teTeX",
 "TeXLive" => "TeX Live",
 "TeX-Live" => "TeX Live",
 "TeXlive" => "TeX Live",
 "TeX-live" => "TeX Live",
 "texlive" => "TeX Live",
 "tex-live" => "TeX Live",
 "TK" => "Tk",
 "tk" => "Tk",
 "Xemacs" => "XEmacs",
 "XEMacs" => "XEmacs",
 "XFCE" => "Xfce",
 "XFce" => "Xfce",
 "xfce" => "Xfce",
);

sub _check_case {
	my $words = shift;

	# Holds the failures we saw
	my %err;

	foreach my $w ( @$words ) {
		if ( exists $case{ $w } ) {
			$err{ $w } = $case{ $w };
		}
	}

	return \%err;
}

# COMMON LIST

#apoc@blackhole:~/othergit/lintian/data/spelling$ cat corrections
# All spelling errors that have been observed "in the wild" in package
# descriptions are added here, on the grounds that if they occurred once they
# are more likely to occur again.
#
# Misspellings of "compatibility", "separate", and "similar" are particularly
# common.
#
# Be careful with corrections that involve punctuation, since the check is a
# bit rough with punctuation.  For example, I had to delete the correction of
# "builtin" to "built-in".
#
# The format of each line is:
# mistake||correction
#
# Note that corrections involving multiple word mistakes or case errors
# should be included in the appropriate data file, rather than here.

# TODO Figure out an autoimporter?
# apoc@box:~/lintian/data/spelling$ cat corrections | perl -e 'print "my \%common = (\n"; while ( <STDIN> ) { next if $_ =~ /^#/; if ( $_ =~ /^(.+)\|\|(.+)$/ ) { print " \"$1\" => \"$2\",\n" } }; print ");\n"'

# TODO ARGH Perl::Critic!@#$
# Perl::Critic found these violations in "blib/lib/Pod/Spell/CommonMistakes/WordList.pm":
# [ValuesAndExpressions::ProhibitDuplicateHashKeys] Duplicate hash key "availble" at line 257, near '"availble" => "available",'
# [ValuesAndExpressions::ProhibitDuplicateHashKeys] Duplicate hash key "avaliable" at line 260, near '"avaliable" => "available",'
my %common = ( ## no critic (ValuesAndExpressions::ProhibitDuplicateHashKeys)
 "abandonning" => "abandoning",
 "abigious" => "ambiguous",
 "abitrate" => "arbitrate",
 "abov" => "above",
 "absense" => "absence",
 "absolut" => "absolute",
 "absoulte" => "absolute",
 "acceleratoin" => "acceleration",
 "accelleration" => "acceleration",
 "accesing" => "accessing",
 "accesnt" => "accent",
 "accessable" => "accessible",
 "accesss" => "access",
 "accidentaly" => "accidentally",
 "accidentually" => "accidentally",
 "accomodate" => "accommodate",
 "accomodates" => "accommodates",
 "accout" => "account",
 "acessable" => "accessible",
 "acess" => "access",
 "acient" => "ancient",
 "acknowldegement" => "acknowldegement",
 "ackowledge" => "acknowledge",
 "ackowledged" => "acknowledged",
 "acording" => "according",
 "activete" => "activate",
 "acumulating" => "accumulating",
 "addional" => "additional",
 "additionaly" => "additionally",
 "addreses" => "addresses",
 "aditional" => "additional",
 "aditionally" => "additionally",
 "aditionaly" => "additionally",
 "adress" => "address",
 "adresses" => "addresses",
 "adviced" => "advised",
 "afecting" => "affecting",
 "albumns" => "albums",
 "alegorical" => "allegorical",
 "algorith" => "algorithm",
 "algorithmical" => "algorithmically",
 "algoritm" => "algorithm",
 "algoritms" => "algorithms",
 "algorrithm" => "algorithm",
 "algorritm" => "algorithm",
 "allpication" => "application",
 "alogirhtms" => "algorithms",
 "alot" => "a lot",
 "alow" => "allow",
 "alows" => "allows",
 "altough" => "although",
 "ambigious" => "ambiguous",
 "amoung" => "among",
 "amout" => "amount",
 "analysator" => "analyzer",
 "ang" => "and",
 "anniversery" => "anniversary",
 "annoucement" => "announcement",
 "anomolies" => "anomalies",
 "anomoly" => "anomaly",
 "aplication" => "application",
 "appearence" => "appearance",
 "appliction" => "application",
 "applictions" => "applications",
 "appropiate" => "appropriate",
 "appropriatly" => "appropriately",
 "aquired" => "acquired",
 "arbitary" => "arbitrary",
 "architechture" => "architecture",
 "arguement" => "argument",
 "arguements" => "arguments",
 "aritmetic" => "arithmetic",
 "arne't" => "aren't",
 "arraival" => "arrival",
 "artifical" => "artificial",
 "artillary" => "artillery",
 "assigment" => "assignment",
 "assigments" => "assignments",
 "assistent" => "assistant",
 "asuming" => "assuming",
 "asycronous" => "asynchronous",
 "atomatically" => "automatically",
 "attachement" => "attachment",
 "attemps" => "attempts",
 "attruibutes" => "attributes",
 "authentification" => "authentication",
 "automaticaly" => "automatically",
 "automaticly" => "automatically",
 "automatize" => "automate",
 "automatized" => "automated",
 "automatizes" => "automates",
 "autonymous" => "autonomous",
 "auxilliary" => "auxiliary",
 "avaiable" => "available",
 "availabled" => "available",
 "availablity" => "availability",
 "availale" => "available",
 "availavility" => "availability",
 "availble" => "available",
 "availble" => "available",
 "availiable" => "available",
 "avaliable" => "available",
 "avaliable" => "available",
 "backgroud" => "background",
 "bahavior" => "behavior",
 "baloon" => "balloon",
 "baloons" => "balloons",
 "bandwith" => "bandwidth",
 "batery" => "battery",
 "becomming" => "becoming",
 "becuase" => "because",
 "begining" => "beginning",
 "bianries" => "binaries",
 "calender" => "calendar",
 "cancelation" => "cancellation",
 "capabilites" => "capabilities",
 "capatibilities" => "capabilities",
 "cariage" => "carriage",
 "challange" => "challenge",
 "challanges" => "challenges",
 "changable" => "changeable",
 "charachter" => "character",
 "charachters" => "characters",
 "charater" => "character",
 "charaters" => "characters",
 "charcter" => "character",
 "childs" => "children",
 "chnage" => "change",
 "chnages" => "changes",
 "choosen" => "chosen",
 "collapsable" => "collapsible",
 "colorfull" => "colorful",
 "comand" => "command",
 "comit" => "commit",
 "commerical" => "commercial",
 "comminucation" => "communication",
 "commited" => "committed",
 "commiting" => "committing",
 "committ" => "commit",
 "commoditiy" => "commodity",
 "compability" => "compatibility",
 "compatability" => "compatibility",
 "compatable" => "compatible",
 "compatibiliy" => "compatibility",
 "compatibilty" => "compatibility",
 "compilant" => "compliant",
 "compleatly" => "completely",
 "completly" => "completely",
 "complient" => "compliant",
 "compres" => "compress",
 "compresion" => "compression",
 "comression" => "compression",
 "conditionaly" => "conditionally",
 "configuratoin" => "configuration",
 "conjuction" => "conjunction",
 "connectinos" => "connections",
 "connnection" => "connection",
 "connnections" => "connections",
 "consistancy" => "consistency",
 "consistant" => "consistent",
 "containes" => "contains",
 "containts" => "contains",
 "contaisn" => "contains",
 "contence" => "contents",
 "continous" => "continuous",
 "continously" => "continuously",
 "continueing" => "continuing",
 "contraints" => "constraints",
 "convertor" => "converter",
 "convinient" => "convenient",
 "corected" => "corrected",
 "correponding" => "corresponding",
 "correponds" => "corresponds",
 "correspoding" => "corresponding",
 "cryptocraphic" => "cryptographic",
 "curently" => "currently",
 "dafault" => "default",
 "deafult" => "default",
 "deamon" => "daemon",
 "debain" => "Debian",
 "debians" => "Debian's",
 "decompres" => "decompress",
 "definate" => "definite",
 "definately" => "definitely",
 "delared" => "declared",
 "delare" => "declare",
 "delares" => "declares",
 "delaring" => "declaring",
 "delemiter" => "delimiter",
 "dependancies" => "dependencies",
 "dependancy" => "dependency",
 "dependant" => "dependent",
 "depreacted" => "deprecated",
 "depreacte" => "deprecate",
 "desactivate" => "deactivate",
 "detabase" => "database",
 "developement" => "development",
 "developped" => "developed",
 "developpement" => "development",
 "developper" => "developer",
 "developpment" => "development",
 "deveolpment" => "development",
 "devided" => "divided",
 "dictionnary" => "dictionary",
 "diplay" => "display",
 "disapeared" => "disappeared",
 "dispertion" => "dispersion",
 "dissapears" => "disappears",
 "docuentation" => "documentation",
 "documantation" => "documentation",
 "documentaion" => "documentation",
 "dont" => "don't",
 "downlad" => "download",
 "downlads" => "downloads",
 "easilly" => "easily",
 "ecspecially" => "especially",
 "edditable" => "editable",
 "editting" => "editing",
 "efficently" => "efficiently",
 "eletronic" => "electronic",
 "enchanced" => "enhanced",
 "encorporating" => "incorporating",
 "endianess" => "endianness",
 "enhaced" => "enhanced",
 "enlightnment" => "enlightenment",
 "enocded" => "encoded",
 "enterily" => "entirely",
 "envireonment" => "environment",
 "enviroiment" => "environment",
 "enviroment" => "environment",
 "environement" => "environment",
 "environent" => "environment",
 "equiped" => "equipped",
 "equivelant" => "equivalent",
 "equivilant" => "equivalent",
 "estbalishment" => "establishment",
 "etsablishment" => "establishment",
 "etsbalishment" => "establishment",
 "excecutable" => "executable",
 "exceded" => "exceeded",
 "excellant" => "excellent",
 "exlcude" => "exclude",
 "exlcusive" => "exclusive",
 "expecially" => "especially",
 "explicitely" => "explicitly",
 "explict" => "explicit",
 "explictly" => "explicitly",
 "expresion" => "expression",
 "exprimental" => "experimental",
 "extensability" => "extensibility",
 "extention" => "extension",
 "extracter" => "extractor",
 "failuer" => "failure",
 "familar" => "familiar",
 "fatser" => "faster",
 "feauture" => "feature",
 "feautures" => "features",
 "fetaure" => "feature",
 "fetaures" => "features",
 "forse" => "force",
 "fortan" => "fortran",
 "forwardig" => "forwarding",
 "framwork" => "framework",
 "fuction" => "function",
 "fuctions" => "functions",
 "functionallity" => "functionality",
 "functionaly" => "functionally",
 "functionnality" => "functionality",
 "functiosn" => "functions",
 "functonality" => "functionality",
 "futhermore" => "furthermore",
 "generiously" => "generously",
 "grabing" => "grabbing",
 "grahical" => "graphical",
 "grahpical" => "graphical",
 "grapic" => "graphic",
 "guage" => "gauge",
 "halfs" => "halves",
 "handfull" => "handful",
 "heirarchically" => "hierarchically",
 "helpfull" => "helpful",
 "hierachy" => "hierarchy",
 "hierarchie" => "hierarchy",
 "howver" => "however",
 "immeadiately" => "immediately",
 "implemantation" => "implementation",
 "implemention" => "implementation",
 "incomming" => "incoming",
 "incompatabilities" => "incompatibilities",
 "incompatable" => "incompatible",
 "inconsistant" => "inconsistent",
 "indendation" => "indentation",
 "indended" => "intended",
 "independant" => "independent",
 "independed" => "independent",
 "informatiom" => "information",
 "informations" => "information",
 "infromation" => "information",
 "initalize" => "initialize",
 "initators" => "initiators",
 "initializiation" => "initialization",
 "inofficial" => "unofficial",
 "integreated" => "integrated",
 "integrety" => "integrity",
 "integrey" => "integrity",
 "intendet" => "intended",
 "interchangable" => "interchangeable",
 "intermittant" => "intermittent",
 "interupted" => "interrupted",
 "intial" => "initial",
 "intregral" => "integral",
 "intuative" => "intuitive",
 "invokation" => "invocation",
 "invokations" => "invocations",
 "jave" => "java",
 "langage" => "language",
 "langauage" => "language",
 "langauge" => "language",
 "langugage" => "language",
 "lauch" => "launch",
 "leightweight" => "lightweight",
 "lenght" => "length",
 "lesstiff" => "lesstif",
 "libaries" => "libraries",
 "libary" => "library",
 "librairies" => "libraries",
 "libraris" => "libraries",
 "licenceing" => "licencing",
 "loggging" => "logging",
 "loggin" => "login",
 "logile" => "logfile",
 "machinary" => "machinery",
 "maintainance" => "maintenance",
 "maintainence" => "maintenance",
 "maintan" => "maintain",
 "makeing" => "making",
 "malplaced" => "misplaced",
 "malplace" => "misplace",
 "managable" => "manageable",
 "managment" => "management",
 "manoeuvering" => "maneuvering",
 "mathimatical" => "mathematical",
 "mathimatic" => "mathematic",
 "mathimatics" => "mathematics",
 "ment" => "meant",
 "messsage" => "message",
 "messsages" => "messages",
 "microprocesspr" => "microprocessor",
 "milliseonds" => "milliseconds",
 "miscelleneous" => "miscellaneous",
 "misformed" => "malformed",
 "mispelled" => "misspelled",
 "mispelt" => "misspelt",
 "mmnemonic" => "mnemonic",
 "modulues" => "modules",
 "monochorome" => "monochrome",
 "monochromo" => "monochrome",
 "monocrome" => "monochrome",
 "mroe" => "more",
 "mulitplied" => "multiplied",
 "multidimensionnal" => "multidimensional",
 "mutiple" => "multiple",
 "nam" => "name",
 "nams" => "names",
 "navagating" => "navigating",
 "nead" => "need",
 "neccesary" => "necessary",
 "neccessary" => "necessary",
 "necesary" => "necessary",
 "negotation" => "negotiation",
 "nescessary" => "necessary",
 "nessessary" => "necessary",
 "noticable" => "noticeable",
 "notications" => "notifications",
 "o'caml" => "OCaml",
 "occationally" => "occasionally",
 "omitt" => "omit",
 "ommitted" => "omitted",
 "onself" => "oneself",
 "optionnal" => "optional",
 "optmizations" => "optimizations",
 "orientatied" => "orientated",
 "orientied" => "oriented",
 "ouput" => "output",
 "overaall" => "overall",
 "overriden" => "overridden",
 "pacakge" => "package",
 "pachage" => "package",
 "packacge" => "package",
 "packege" => "package",
 "packge" => "package",
 "pakage" => "package",
 "pallette" => "palette",
 "paramameters" => "parameters",
 "paramater" => "parameter",
 "parametes" => "parameters",
 "parametised" => "parametrised",
 "paramter" => "parameter",
 "paramters" => "parameters",
 "particularily" => "particularly",
 "pased" => "passed",
 "pendantic" => "pedantic",
 "peprocessor" => "preprocessor",
 "perfoming" => "performing",
 "permissons" => "permissions",
 "persistant" => "persistent",
 "plattform" => "platform",
 "pleaes" => "please",
 "ploting" => "plotting",
 "poinnter" => "pointer",
 "posible" => "possible",
 "possibilites" => "possibilities",
 "postgressql" => "PostgreSQL",
 "powerfull" => "powerful",
 "preceeded" => "preceded",
 "preceeding" => "preceding",
 "precendence" => "precedence",
 "precission" => "precision",
 "prefered" => "preferred",
 "prefferably" => "preferably",
 "prepaired" => "prepared",
 "primative" => "primitive",
 "princliple" => "principle",
 "priorty" => "priority",
 "priviledge" => "privilege",
 "priviledges" => "privileges",
 "procceed" => "proceed",
 "proccesors" => "processors",
 "proces" => "process",
 "processessing" => "processing",
 "processess" => "processes",
 "processpr" => "processor",
 "processsing" => "processing",
 "progams" => "programs",
 "programers" => "programmers",
 "programm" => "program",
 "programms" => "programs",
 "promps" => "prompts",
 "pronnounced" => "pronounced",
 "prononciation" => "pronunciation",
 "pronouce" => "pronounce",
 "pronunce" => "pronounce",
 "propery" => "property",
 "propigate" => "propagate",
 "propigation" => "propagation",
 "prosess" => "process",
 "protable" => "portable",
 "protcol" => "protocol",
 "protecion" => "protection",
 "protocoll" => "protocol",
 "psychadelic" => "psychedelic",
 "quering" => "querying",
 "reasearcher" => "researcher",
 "reasearchers" => "researchers",
 "reasearch" => "research",
 "recieved" => "received",
 "recieve" => "receive",
 "reciever" => "receiver",
 "recogniced" => "recognised",
 "recognizeable" => "recognizable",
 "recommanded" => "recommended",
 "redircet" => "redirect",
 "redirectrion" => "redirection",
 "reenabled" => "re-enabled",
 "reenable" => "re-enable",
 "reencode" => "re-encode",
 "refence" => "reference",
 "registerd" => "registered",
 "registraration" => "registration",
 "regulamentations" => "regulations",
 "remoote" => "remote",
 "removeable" => "removable",
 "repectively" => "respectively",
 "replacments" => "replacements",
 "replys" => "replies",
 "requiere" => "require",
 "requred" => "required",
 "requried" => "required",
 "resizeable" => "resizable",
 "ressize" => "resize",
 "ressource" => "resource",
 "ressources" => "resources",
 "retransmited" => "retransmitted",
 "retreive" => "retrieve",
 "retreived" => "retrieved",
 "rmeoved" => "removed",
 "rmeove" => "remove",
 "rmeoves" => "removes",
 "runned" => "ran",
 "runnning" => "running",
 "sacrifying" => "sacrificing",
 "safly" => "safely",
 "savable" => "saveable",
 "searchs" => "searches",
 "secund" => "second",
 "separatly" => "separately",
 "sepcify" => "specify",
 "seperated" => "separated",
 "seperately" => "separately",
 "seperate" => "separate",
 "seperatly" => "separately",
 "seperator" => "separator",
 "sepperate" => "separate",
 "sequencial" => "sequential",
 "serveral" => "several",
 "setts" => "sets",
 "similiar" => "similar",
 "simliar" => "similar",
 "softwares" => "software",
 "speach" => "speech",
 "speciefied" => "specified",
 "specifed" => "specified",
 "specificatin" => "specification",
 "specificaton" => "specification",
 "specifing" => "specifying",
 "speficied" => "specified",
 "speling" => "spelling",
 "splitted" => "split",
 "spreaded" => "spread",
 "staically" => "statically",
 "standardss" => "standards",
 "standart" => "standard",
 "staticly" => "statically",
 "subdirectoires" => "subdirectories",
 "suble" => "subtle",
 "succesfully" => "successfully",
 "succesful" => "successful",
 "sucessfully" => "successfully",
 "superflous" => "superfluous",
 "superseeded" => "superseded",
 "suplied" => "supplied",
 "suport" => "support",
 "suppored" => "supported",
 "supportin" => "supporting",
 "suppoted" => "supported",
 "suppported" => "supported",
 "suppport" => "support",
 "supress" => "suppress",
 "surpresses" => "suppresses",
 "suspicously" => "suspiciously",
 "synax" => "syntax",
 "synchonized" => "synchronized",
 "syncronize" => "synchronize",
 "syncronizing" => "synchronizing",
 "syncronus" => "synchronous",
 "syste" => "system",
 "sytem" => "system",
 "sythesis" => "synthesis",
 "taht" => "that",
 "targetted" => "targeted",
 "targetting" => "targeting",
 "teh" => "the",
 "throught" => "through",
 "transfered" => "transferred",
 "transfering" => "transferring",
 "trasmission" => "transmission",
 "treshold" => "threshold",
 "trigerring" => "triggering",
 "unconditionaly" => "unconditionally",
 "unecessary" => "unnecessary",
 "unexecpted" => "unexpected",
 "unfortunatelly" => "unfortunately",
 "unknonw" => "unknown",
 "unkown" => "unknown",
 "unneedingly" => "unnecessarily",
 "unuseful" => "useless",
 "usefule" => "useful",
 "usefull" => "useful",
 "usege" => "usage",
 "usera" => "users",
 "usetnet" => "Usenet",
 "usualy" => "usually",
 "utilites" => "utilities",
 "utillities" => "utilities",
 "utilties" => "utilities",
 "utiltity" => "utility",
 "utitlty" => "utility",
 "variantions" => "variations",
 "varient" => "variant",
 "verbse" => "verbose",
 "verisons" => "versions",
 "verison" => "version",
 "verson" => "version",
 "vicefersa" => "vice-versa",
 "visiters" => "visitors",
 "vitual" => "virtual",
 "whataver" => "whatever",
 "wheter" => "whether",
 "wierd" => "weird",
 "writting" => "writing",
 "xwindows" => "X",
 "yur" => "your",
);

# extra words contributed by CPAN users, thanks!
# split it up for easier maintenance of Lintian data
my %common_cpan = (
 "refering" => "referring",
 "writeable" => "writable",
 "nineth" => "ninth",
 "ommited" => "omitted",
 "omited" => "omitted",
 "requrie" => "require",
 "existant" => "existent",
 "explict" => "explicit",
 "agument" => "augument",
 "destionation" => "destination",
);

%common = ( %common, %common_cpan );

sub _check_common {
	my $words = shift;

	# Holds the failures we saw
	my %err;

	# Logic taken from Lintian::Check::check_spelling(), thanks!
	foreach my $w ( @$words ) {
		my $lcw = lc( $w );
		if ( exists $common{ $lcw } ) {
			# Determine what kind of correction we need
			if ( $w =~ /^[[:upper:]]+$/ ) {
				$err{ $w } = uc( $common{ $lcw } );
			} elsif ( $w =~ /^[[:upper:]]/ ) {
				$err{ $w } = ucfirst( $common{ $lcw } );
			} else {
				$err{ $w } = $common{ $lcw };
			}
		}
	}

	return \%err;
}

1;

__END__

=pod

=encoding UTF-8

=for :stopwords Apocalypse wordlist Lintian git repo

=head1 NAME

Pod::Spell::CommonMistakes::WordList - Holds the wordlist data for Pod::Spell::CommonMistakes

=head1 VERSION

  This document describes v1.002 of Pod::Spell::CommonMistakes::WordList - released November 04, 2014 as part of Pod-Spell-CommonMistakes.

=head1 SYNOPSIS

	die "Don't use this module directly. Please use Pod::Spell::CommonMistakes instead.";

=head1 DESCRIPTION

Holds the wordlist used in L<Pod::Spell::CommonMistakes>. Big thanks goes out to the Debian Lintian team for the wordlist!

	# Data taken from: http://wiki.debian.org/Teams/Lintian ( git://git.debian.org/git/lintian/lintian.git )
	# lintian/data/spelling/corrections
	# lintian/data/spelling/corrections-case

	# Data was synced on Fri Oct 31 11:04:39 2014
	# The git HEAD was 93cdfcaf1a7bad36da72263e2212d8f9bd7846a2

=head1 SEE ALSO

Please see those modules/websites for more information related to this module.

=over 4

=item *

L<Pod::Spell::CommonMistakes|Pod::Spell::CommonMistakes>

=back

=head1 AUTHOR

Apocalypse <APOCAL@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2014 by Apocalypse.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

The full text of the license can be found in the
F<LICENSE> file included with this distribution.

=head1 DISCLAIMER OF WARRANTY

THERE IS NO WARRANTY FOR THE PROGRAM, TO THE EXTENT PERMITTED BY
APPLICABLE LAW.  EXCEPT WHEN OTHERWISE STATED IN WRITING THE COPYRIGHT
HOLDERS AND/OR OTHER PARTIES PROVIDE THE PROGRAM "AS IS" WITHOUT WARRANTY
OF ANY KIND, EITHER EXPRESSED OR IMPLIED, INCLUDING, BUT NOT LIMITED TO,
THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR
PURPOSE.  THE ENTIRE RISK AS TO THE QUALITY AND PERFORMANCE OF THE PROGRAM
IS WITH YOU.  SHOULD THE PROGRAM PROVE DEFECTIVE, YOU ASSUME THE COST OF
ALL NECESSARY SERVICING, REPAIR OR CORRECTION.

IN NO EVENT UNLESS REQUIRED BY APPLICABLE LAW OR AGREED TO IN WRITING
WILL ANY COPYRIGHT HOLDER, OR ANY OTHER PARTY WHO MODIFIES AND/OR CONVEYS
THE PROGRAM AS PERMITTED ABOVE, BE LIABLE TO YOU FOR DAMAGES, INCLUDING ANY
GENERAL, SPECIAL, INCIDENTAL OR CONSEQUENTIAL DAMAGES ARISING OUT OF THE
USE OR INABILITY TO USE THE PROGRAM (INCLUDING BUT NOT LIMITED TO LOSS OF
DATA OR DATA BEING RENDERED INACCURATE OR LOSSES SUSTAINED BY YOU OR THIRD
PARTIES OR A FAILURE OF THE PROGRAM TO OPERATE WITH ANY OTHER PROGRAMS),
EVEN IF SUCH HOLDER OR OTHER PARTY HAS BEEN ADVISED OF THE POSSIBILITY OF
SUCH DAMAGES.

=cut
