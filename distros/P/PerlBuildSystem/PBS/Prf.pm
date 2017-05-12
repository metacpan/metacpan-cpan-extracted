
package PBS::Prf ;
use PBS::Debug ;

use 5.006 ;
use strict ;
use warnings ;
use Data::TreeDumper ;

require Exporter ;
use AutoLoader qw(AUTOLOAD) ;

our @ISA = qw(Exporter) ;
our %EXPORT_TAGS = ('all' => [ qw() ]) ;
our @EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } ) ;
our @EXPORT = qw(AddTargets AddCommandLineDefinitions AddCommandLineSwitches) ;
our $VERSION = '0.01' ;

#-------------------------------------------------------------------------------

use PBS::Config ;
use PBS::PBSConfig ;
use PBS::Output ;

#-------------------------------------------------------------------------------

sub AddTargets
{
my $pbs_config = GetPbsConfig(caller) ;
push @{$pbs_config->{TARGETS}}, @_ ;
}

#-------------------------------------------------------------------------------


sub AddCommandLineSwitches
{
my $caller = caller() ;
my @switches = @_ ;

local @ARGV = map
		{
		my $key_value = $_ ;
		
		$key_value =~ s/^\s*// ; $key_value =~ s/\s*$// ;
		if ($key_value =~ /([^ ]+)\ (.*)/)
			{
			("$1", $2) ;
			}
		else
			{
			"$key_value" ; 
			}
		} @switches ;

my $pbs_config = GetPbsConfig($caller) ;
my @flags = PBS::PBSConfigSwitches::Get_GetoptLong_Data($pbs_config) ;

my $ignore_error = $pbs_config->{'PRF_IGNORE_ERROR'} ;

local $SIG{__WARN__} 
	= sub 
		{
		PrintWarning $_[0] unless $ignore_error ;
		} ;
		
use Getopt::Long ;
Getopt::Long::Configure('no_auto_abbrev', 'no_ignore_case', 'require_order') ;
unless(GetOptions(@flags))
	{
	die ERROR "Error parsing switches" unless $ignore_error ;
	}
}

#------------------------------------------------------------------------

1 ;

#-------------------------------------------------------------------------------

__END__
=head1 NAME

PBS::Prf - Support functions for pure perl prf files

=head1 DESCRIPTION

Prf file contain the definition of command line switches and target. PBS 0.36 introduces
pure perl prfs. All perl functionality is accessible in the prfs but only a limited subset
of PBS functionality is available.

  AddTargets('1', '2') ;
  
  #~ AddCommandLineSwitches('-unknown_switch') ; # will generate an error and stop
  AddCommandLineSwitches('-sd /') ;
  AddCommandLineSwitches('-ndpb') ;
  
  AddCommandLineSwitches
  	(
  	  '-dc'
  	, '-dsd'
	, '-ppp /devel/perl_modules/PerlBuildSystem/Plugins'
  	) ;
  
  AddCommandLineDefinitions(DEBUG => 1) ;
  AddCommandLineDefinitions(SOMETHING => 'a string with spaces') ;
  
  AddCommandLineDefinitions
  	(
  	  DEBUG2 => 1
  	, SOMETHING2 => 'a string with spaces again'
  	) ;

=head1 AUTHOR

Khemir Nadim ibn Hamouda. nadim@khemir.net

=cut
