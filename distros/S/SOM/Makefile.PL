use ExtUtils::MakeMaker;
use Config;

my @tk = grep /^TOOLKIT=/, @ARGV;
@ARGV = grep {not /^TOOLKIT=/} @ARGV;
my $inc = "";
my $lib = "";

if (!@tk) {
  # Try deducing ourselves...  The only trace I know is the URE entry in the
  # ini file, and the class for OBJUTIL.

  require OS2::PrfDB;
  tie %i, 'OS2::PrfDB::Sub', OS2::PrfDB::UserIni(), 'URE'
    and exists $i{'URE Path'}
    and $i{'URE Path'} =~ / ^ (.*?) \\ ( BETA \\ )? BIN \\? \0? $ /xi
    and (($t = $1) =~ s,\\,/,g),  -e "$t/H/WPFOLDER.H"
    and push @tk, "TOOLKIT=$t";
  not @tk and eval {
    require OS2::WinObject;
    my %dlls = OS2::WinObject::ObjectClasses();
    my $dll  = $dlls{ObjectUtility};
    # print "ObjectUtility => $dll\n";
    my $dir = '';
    $dir = $1 if $dll and $dll =~ /(.*)\\DLL\\OBJUTIL\.DLL$/i;
    $dir =~ s,\\,/,g;
    push @tk, "TOOLKIT=$dir" if $dir and -e "$dir/H/WPFOLDER.H";
  };
  # Same with direct parsing of .ini...
  not @tk and tie %i, 'OS2::PrfDB::Sub', OS2::PrfDB::SystemIni(), 'PM_Objects'
    and exists $i{'ClassTable'}
    and $i{'ClassTable'} 
	  =~ / (^|\0) ObjectUtility \0 ( [^\0]+ ) \\DLL\\OBJUTIL\.DLL \0 /x
    and (($t = $2) =~ s,\\,/,g), -e "$t/H/WPFOLDER.H"
    and push @tk, "TOOLKIT=$t";
  not @tk and push @tk, map { s,\\,/,g; "TOOLKIT=$_" } grep $_, map {
        /(.*)\\SOM\\COMMON\\ETC\\SOM\.IR$/i and -e "$1/H/WPFOLDER.H" and $1
    } split /;/, $ENV{SOMIR};
}

if (@tk) {
    die "Multiple @tk arguments not allowed.\n" if @tk > 1;
    $tk[0] =~ /TOOLKIT=(.*)/;
    $inc = "-I$1/h -I$1/som/include";
    $lib = "-L$1/som/lib ";
}

my @opt;
unless(grep /^OPTIMIZE=/, @ARGV) {
  my $opt = $Config{optimize};
  $opt =~ s/-fomit-frame-pointer\b//;
  @opt = ( OPTIMIZE => $opt );
}

my $def = '';
if ($] < 5.006) {		# xsubpp will not handle ANSI C declarations
  push @opt, (	macro =>	{XSUBPP => './utils/xsubpp'},
		XSOPT =>	'-nooptimize');		# Custom xsubpp
  $def .= ' -DCUSTOM_XSUBPP';
}

# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    'NAME'	=> 'SOM',
    'VERSION_FROM' => 'SOM.pm', # finds $VERSION
    'LIBS'	=> ["$lib-lsomtk"],   # e.g., '-lm' 
    'DEFINE'	=> "$def -DPERL_POLLUTE=1",     # e.g., '-DHAVE_SOMETHING' 
    'INC'	=> $inc,     # e.g., '-I/usr/include/other' 
    OBJECT	=> '$(O_FILES)',	# Several .xs files
    dist	=> {TARFLAGS => 'WILL-RUIN-ANIMAL.DLL....USE-zipdist',
		    DIST_DEFAULT => 'zipdist'},
    @opt,
);
