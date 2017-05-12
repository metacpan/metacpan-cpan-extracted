use ExtUtils::MakeMaker;
use File::Basename;

eval { require 5.6.0 } or die <<EOD;
###############################################################
### Your perl is WAY too ancient, you must upgrade to 5.6.0 ###
### Consider going to 5.6.1 while you are at it             ###
###############################################################
EOD

my $ovpath = '/opt/OV' ;
foreach my $arg ( @ARGV )
{
   my ( $arg,$val ) = split( /=/ ,$arg );
   if ( $arg eq 'OV' )
   {
      $ovpath = $val;
      last;
   }
}
if ( ! -d "$ovpath/include" )
{
   my $a = '';
   print "Could not find $ovpath/include; where is the OV directory: " ; 
   $ovpath = <STDIN>; 
   chomp $ovpath;
   if ( not -d $ovpath )
   {
      die <<'EOM';

We cannot build opcmsg without a path to the OV include and
and OV lib directory.  (Send mail to the author if you are
interested in a fake opcmsg library for test purposes).

EOM
   }
}

my $incpath = "$ovpath/include" ;
my $libpath = "$ovpath/lib";
die "could not find $libpath" if not -d $incpath;
die "could not find $libpath" if not -d $libpath;


use Config;
use File::Basename;
my $libstr = '';
my $so = $Config{'so'};
foreach my $lib ( glob( "$libpath/*.$so" ) )
{
   #next if ! -x $lib;
   next if -l $lib;
   my ( $name ,$path ,$ext ) = fileparse( $lib ); 
   $name =~ s/lib(\w+)\.$so$/$1/;
   $libstr .= "-l$name ";
}
$libstr = "-L$libpath " .$libstr;

WriteMakefile(
     DISTNAME      => 'Openview-Message'
    ,NAME		    => 'Openview::Message::opcmsg'
    ,VERSION_FROM  => 'lib/Openview/Message/opcmsg.pm' 
    ,PREREQ_PM	    => {} 
    ,ABSTRACT      => 'Perl extension for sending OpenView messages' 
    ,AUTHOR        => 'Lincoln A Baxter <lab@lincolnbaxter.com>'
    ,XS            => { 'opsmsg.xs' => 'opcmsg.c' }
    ,LIBS		    => [ $libstr ]
    ,DEFINE	       => ''
    ,INC		       => "-I$incpath"
);

print <<"EVM" if not defined $ENV{'OVO_MSG_GROUP'};

NOTE:

If you want to see the results of 'make test' in your Openview
monitor, you must set the OVO_MSG_GROUP environment
variable to a valid message group prior to running make test.  
For example:
 
   export OVO_MSG_GROUP='aValidMsgGroupForYourSite'

If compile fails (like on HP-UX) you can still use the 
CLI implementation of this module

EVM


