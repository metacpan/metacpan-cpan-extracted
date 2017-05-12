
package PBS::Warp ;
use PBS::Debug ;

use strict ;
use warnings ;

use 5.006 ;
 
require Exporter ;
use AutoLoader qw(AUTOLOAD) ;

our @ISA = qw(Exporter) ;
our %EXPORT_TAGS = ('all' => [ qw() ]) ;
our @EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } ) ;
our @EXPORT = qw() ;
our $VERSION = '0.02' ;

#-------------------------------------------------------------------------------

use PBS::Output ;

use Cwd ;
use Data::TreeDumper ;
use Digest::MD5 qw(md5_hex) ;

#-------------------------------------------------------------------------------

sub WarpPbs
{
my ($targets, $pbs_config, $parent_config) = @_ ;

my $warp_module = $pbs_config->{WARP} ;
$warp_module =~ s/[^0-9a-zA-Z]/_/g ;
$warp_module = "PBS::Warp::Warp" . $warp_module ;

my @warp_results ;

eval <<EOE ;

use $warp_module ;
\@warp_results = ${warp_module}::WarpPbs(\$targets, \$pbs_config, \$parent_config) ;

EOE

die $@ if $@ ;
return(@warp_results) ;
}

#-------------------------------------------------------------------------------

sub GetWarpSignature
{
my ($targets, $pbs_config) = @_ ;

#construct a file name depends on targets and -D and -u switches, etc ...
my $pbs_prf = $pbs_config->{PBS_RESPONSE_FILE} || '' ;
my $pbs_lib_path = $pbs_config->{LIB_PATH} || '' ;

my $warp_signature_source =
		(
		  join('_', @$targets) 
		
		. $pbs_config->{PBSFILE}
		
		. DumpTree($pbs_config->{COMMAND_LINE_DEFINITIONS}, '', USE_ASCII => 1)
		. DumpTree($pbs_config->{USER_OPTIONS}, '', USE_ASCII => 1) 
		
		. $pbs_prf
		. DumpTree($pbs_lib_path, '', USE_ASCII => 1)
		) ;

my $warp_signature = md5_hex($warp_signature_source) ;

return($warp_signature, $warp_signature_source) ;
}

#--------------------------------------------------------------------------------------------------

sub GetWarpConfiguration
{
my $pbs_config = shift ;
my $warp_configuration = shift ;

my $pbs_prf = $pbs_config->{PBS_RESPONSE_FILE} ;

unless(defined $warp_configuration)
	{
	if(defined $pbs_prf)
		{
		my $pbs_prf_md5 = PBS::Digest::GetFileMD5($pbs_prf) ; 
		
		if(defined $pbs_prf_md5)
			{
			$warp_configuration->{$pbs_prf} = $pbs_prf_md5 ;
			}
		else
			{
			PrintError("Warp file generation aborted: Can't compute MD5 for prf file '$pbs_prf'!") ;
			close(DUMP) ;
			return ;
			}
		}
	else
		{
		$warp_configuration = {} ;
		}
		
	my $package_digest = PBS::Digest::GetPackageDigest('__PBS_WARP_DATA') ;
	for my $entry (keys %$package_digest)
		{
		$warp_configuration->{$entry} = $package_digest->{$entry} ;
		}
	}

return($warp_configuration) ;
}

#-------------------------------------------------------------------------------

1;

__END__
=head1 NAME

PBS::Warp  -

=head1 DESCRIPTION

front end to the warp system. Defines base warp functionality.

=head2 EXPORT

None.

=head1 AUTHOR

Khemir Nadim ibn Hamouda. nadim@khemir.net

=cut
